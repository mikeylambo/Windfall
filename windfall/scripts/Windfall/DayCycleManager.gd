extends Node
class_name DayCycleManager

signal time_changed(phase: int, day_number: int, season: int)
signal raid_started(wave_number: int)
signal raid_cleared(day_number: int)
signal new_day_started(day_number: int)

@export var day_number: int = 1
@export var current_phase: int = WindfallTypes.TimeOfDay.MORNING
@export var current_season: int = WindfallTypes.Season.SPRING

# Raid settings
var active_raid_enemies: Array[PoacherEnemy2D] = []
var is_raid_active: bool = false
var enemies_left_to_spawn: int = 0
var _spawn_timer: float = 0.0

@onready var night_overlay: CanvasModulate = get_node_or_null("../NightModulate") as CanvasModulate


func _ready() -> void:
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

	# Raid scales with day number
	var count := 3 + int(day_number * 1.5)
	enemies_left_to_spawn = count
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
			# Auto advance to next morning
			get_tree().create_timer(3.0).timeout.connect(start_next_day)


func _spawn_raid_enemy() -> void:
	var enemy := PoacherEnemy2D.new()
	# Random spawn location around edges of orchard
	var spawn_points := [
		Vector2(100, 200),
		Vector2(850, 200),
		Vector2(100, 600),
		Vector2(850, 600),
		Vector2(450, 50)
	]
	enemy.position = spawn_points[randi() % spawn_points.size()]

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
	get_parent().add_child(enemy)


func _on_enemy_died(enemy: PoacherEnemy2D) -> void:
	active_raid_enemies.erase(enemy)


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
							if hybrid_id != &"" and randf() < 0.35:
								# Hybrid fruit born on parent!
								p1.grafted_species_id = hybrid_id
								break


func _update_lighting() -> void:
	if night_overlay == null:
		return
	match current_phase:
		WindfallTypes.TimeOfDay.MORNING:
			# Warm morning golden sunlight
			night_overlay.color = Color(1.0, 0.98, 0.92)
		WindfallTypes.TimeOfDay.EXPEDITION:
			# Crisp afternoon light
			night_overlay.color = Color(1.0, 1.0, 1.0)
		WindfallTypes.TimeOfDay.NIGHT_RAID:
			# Dark dramatic twilight navy
			night_overlay.color = Color(0.35, 0.38, 0.6)
