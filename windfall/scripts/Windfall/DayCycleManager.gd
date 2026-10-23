extends Node
class_name DayCycleManager

signal time_changed(phase: int, day_number: int, season: int)
signal raid_started(wave_number: int)
signal raid_cleared(day_number: int)
signal new_day_started(day_number: int)
signal raid_progress(remaining: int, total: int)
signal boss_spawned(enemy: PoacherEnemy2D)

## A Reaping Elite leads the raid every 7th night.
const ELITE_EVERY := 7
var _elite_pending: bool = false

@export var day_number: int = 1
@export var current_phase: int = WindfallTypes.TimeOfDay.MORNING
@export var current_season: int = WindfallTypes.Season.SPRING

# Raid settings
var active_raid_enemies: Array[PoacherEnemy2D] = []
var is_raid_active: bool = false
var enemies_left_to_spawn: int = 0
var _spawn_timer: float = 0.0

@onready var night_overlay: CanvasModulate = get_node_or_null("../NightModulate") as CanvasModulate
@onready var lighting: DayLighting = get_node_or_null("../DayLighting") as DayLighting
var raid_total: int = 0


func _ready() -> void:
	add_to_group("day_manager")
	time_changed.emit(current_phase, day_number, current_season)


func _process(delta: float) -> void:
	if is_raid_active:
		_process_raid_spawning(delta)


func advance_phase() -> void:
	match current_phase:
		WindfallTypes.TimeOfDay.MORNING:
			current_phase = WindfallTypes.TimeOfDay.EXPEDITION
			_update_lighting()
			time_changed.emit(current_phase, day_number, current_season)
		WindfallTypes.TimeOfDay.EXPEDITION:
			start_night_raid()
		WindfallTypes.TimeOfDay.NIGHT_RAID:
			if not is_raid_active:
				start_next_day()


func start_night_raid() -> void:
	current_phase = WindfallTypes.TimeOfDay.NIGHT_RAID
	is_raid_active = true
	_update_lighting()
	time_changed.emit(current_phase, day_number, current_season)

	WindfallSound.play_raid_horn()
	# Wren on watch calls out the raid's direction
	for v in get_tree().get_nodes_in_group("villagers"):
		if v.call("is_guard") and not v.get("is_in_party"):
			HUDBus.toast("Wren: Raiders in the treeline! I'll hold the orchard.", WPal.CLOTH_BLUE[4])

	# Raid scales with day number
	var count := 3 + int(day_number * 1.5)
	enemies_left_to_spawn = count
	_elite_pending = day_number % ELITE_EVERY == 0
	if _elite_pending:
		count += 1
	raid_total = count
	raid_progress.emit(count, count)
	_spawn_timer = 1.0
	raid_started.emit(day_number)


func _process_raid_spawning(delta: float) -> void:
	if enemies_left_to_spawn > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 2.0
			enemies_left_to_spawn -= 1
			_spawn_raid_enemy()
	else:
		# Check if all raid enemies are dead
		if active_raid_enemies.is_empty():
			is_raid_active = false
			raid_cleared.emit(day_number)


## Spawn a specific raider (used by the Elite's summon and tests).
func spawn_enemy(kind: int, pos: Vector2) -> PoacherEnemy2D:
	var e := PoacherEnemy2D.new()
	e.enemy_type = kind
	match kind:
		PoacherEnemy2D.EnemyType.GNAWER:
			e.speed = 130.0
			e.max_health = 45.0
		PoacherEnemy2D.EnemyType.REAPING_ELITE:
			e.speed = 80.0
			e.max_health = 420.0 + day_number * 20.0
			e.attack_damage = 22.0
		_:
			e.max_health = 70.0 + day_number * 5.0
	e.position = pos
	e.died.connect(_on_enemy_died)
	active_raid_enemies.append(e)
	var parent: Node = FX.world if FX.world else get_parent()
	parent.add_child(e)
	FX.poof(e.global_position + Vector2(0, -10), WPal.CLOTH_PLUM[3])
	if kind == PoacherEnemy2D.EnemyType.REAPING_ELITE:
		boss_spawned.emit(e)
	raid_progress.emit(active_raid_enemies.size() + enemies_left_to_spawn, raid_total)
	return e


func _spawn_raid_enemy() -> void:
	if _elite_pending and enemies_left_to_spawn <= raid_total / 2:
		_elite_pending = false
		var sp: Array = WorldLayout.RAID_SPAWNS
		spawn_enemy(PoacherEnemy2D.EnemyType.REAPING_ELITE, sp[randi() % sp.size()])
		return
	var enemy := PoacherEnemy2D.new()
	# Random spawn location around edges of orchard
	var spawn_points: Array = WorldLayout.RAID_SPAWNS
	enemy.position = spawn_points[randi() % spawn_points.size()] + Vector2(randf_range(-30, 30), randf_range(-20, 20))

	# Mix poachers and gnawers
	if randf() < 0.4:
		enemy.enemy_type = PoacherEnemy2D.EnemyType.GNAWER
		enemy.speed = 130.0
		enemy.max_health = 45.0
	else:
		enemy.enemy_type = PoacherEnemy2D.EnemyType.POACHER
		enemy.speed = 95.0
		enemy.max_health = 70.0 + (day_number * 5.0)

	enemy.died.connect(_on_enemy_died)
	active_raid_enemies.append(enemy)
	var parent: Node = FX.world if FX.world else get_parent()
	parent.add_child(enemy)
	FX.poof(enemy.global_position + Vector2(0, -10), WPal.CLOTH_PLUM[3])


func _on_enemy_died(enemy: PoacherEnemy2D) -> void:
	active_raid_enemies.erase(enemy)
	raid_progress.emit(active_raid_enemies.size() + enemies_left_to_spawn, raid_total)


func start_next_day() -> void:
	day_number += 1
	current_phase = WindfallTypes.TimeOfDay.MORNING

	# 7 days per season
	current_season = int((day_number - 1) / 7) % 4

	_update_lighting()

	# Orchard daily tick: grow trees, roll cross-pollination
	_tick_orchard_daily()

	new_day_started.emit(day_number)
	time_changed.emit(current_phase, day_number, current_season)


func _tick_orchard_daily() -> void:
	var plots := get_tree().get_nodes_in_group("orchard_plots")
	for pl in plots:
		pl.call("roll_blight")
	var hybrid_chance := 0.35
	for v in get_tree().get_nodes_in_group("villagers"):
		hybrid_chance += float(v.call("hive_bonus"))
	# Cross-pollination check in Spring
	if current_season == WindfallTypes.Season.SPRING:
		for i in plots.size():
			var p1 = plots[i] as OrchardPlot2D
			if p1 and p1.tree_stage >= WindfallTypes.TreeStage.MATURE:
				for j in range(i + 1, plots.size()):
					var p2 = plots[j] as OrchardPlot2D
					if p2 and p2.tree_stage >= WindfallTypes.TreeStage.MATURE:
						if p1.planted_species_id != p2.planted_species_id:
							var fam1 = FruitRegistry.get_species(p1.planted_species_id).get("family", 0)
							var fam2 = FruitRegistry.get_species(p2.planted_species_id).get("family", 0)
							var hybrid_id := FruitRegistry.get_hybrid_for_families(fam1, fam2)
							if hybrid_id != &"" and randf() < hybrid_chance:
								# Hybrid fruit born on parent!
								p1.grafted_species_id = hybrid_id
								break


func _update_lighting() -> void:
	if lighting:
		lighting.set_phase(current_phase)
		return
	if night_overlay == null:
		return
	match current_phase:
		WindfallTypes.TimeOfDay.MORNING:
			night_overlay.color = Color(1.0, 0.98, 0.92)
		WindfallTypes.TimeOfDay.EXPEDITION:
			night_overlay.color = Color(1.0, 1.0, 1.0)
		WindfallTypes.TimeOfDay.NIGHT_RAID:
			night_overlay.color = Color(0.35, 0.38, 0.6)


## Restore from a save without replaying transitions.
func restore(day: int, phase: int, season: int) -> void:
	day_number = day
	current_phase = phase
	current_season = season
	if lighting:
		lighting.set_phase(phase, true)
	time_changed.emit(current_phase, day_number, current_season)
