extends CharacterBody2D
class_name PoacherEnemy2D

signal died(enemy: PoacherEnemy2D)
signal fruit_stolen(fruit_data: Dictionary)

enum EnemyType {
	POACHER,
	GNAWER,
	REAPING_ELITE
}

@export var enemy_type: int = EnemyType.POACHER
@export var max_health: float = 75.0
@export var speed: float = 95.0
@export var attack_damage: float = 16.0

var current_health: float = 75.0
var target_node: Node2D = null

# Fruit stealing & eating mechanic
var carried_fruit: Dictionary = {}
var has_eaten_fruit: bool = false
var eaten_skill_id: StringName = &""
var eaten_family: int = WindfallTypes.Family.STORM
var _skill_timer: float = 2.0
var _attack_timer: float = 0.0

# Status effects
var is_wet: bool = false
var wet_timer: float = 0.0
var chill_timer: float = 0.0
var burn_timer: float = 0.0
var shock_timer: float = 0.0

var _anim_time: float = 0.0
var _flash_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	_tick_statuses(delta)

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	if shock_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	_update_targeting()

	# Move towards target
	var cur_speed := speed
	if chill_timer > 0.0:
		cur_speed *= 0.5

	if target_node != null and is_instance_valid(target_node):
		var to_target := (target_node.global_position - global_position).normalized()
		velocity = to_target * cur_speed

		# Check if reached target
		var dist := global_position.distance_to(target_node.global_position)
		if target_node is OrchardPlot2D and dist <= 38.0:
			_attempt_steal_fruit(target_node as OrchardPlot2D)
		elif target_node is RootbornPlayer and dist <= 28.0:
			_melee_attack_player(target_node as RootbornPlayer, delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Cast stolen fruit skill if poacher has eaten one!
	if has_eaten_fruit:
		_tick_stolen_skill(delta)

	queue_redraw()


func _update_targeting() -> void:
	# If hasn't eaten fruit, search for nearest ripe orchard tree!
	if not has_eaten_fruit and carried_fruit.is_empty():
		var plots := get_tree().get_nodes_in_group("orchard_plots")
		var closest_plot: OrchardPlot2D = null
		var min_dist := 9999.0

		for p in plots:
			if p is OrchardPlot2D and p.tree_stage >= WindfallTypes.TreeStage.MATURE and p.fruit_count > 0:
				var d := global_position.distance_to(p.global_position)
				if d < min_dist:
					min_dist = d
					closest_plot = p

		if closest_plot != null:
			target_node = closest_plot
			return

	# Otherwise, target player
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target_node = players[0] as Node2D


func _attempt_steal_fruit(plot: OrchardPlot2D) -> void:
	if plot.fruit_count > 0:
		var sp_id := plot.planted_species_id
		carried_fruit = FruitRegistry.create_fruit_instance(sp_id, plot.current_ripeness)
		plot.fruit_count -= 1

		# Poacher immediately eats the fruit to turn skills against you!
		_eat_stolen_fruit()


func _eat_stolen_fruit() -> void:
	has_eaten_fruit = true
	eaten_skill_id = carried_fruit.get("species_id", &"voltberry")
	eaten_family = int(carried_fruit.get("family", WindfallTypes.Family.STORM))
	WindfallSound.play_bite(eaten_family)
	# Health boost from eating
	current_health = minf(current_health + 30.0, max_health * 1.4)
	# Now targets player aggressively!
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target_node = players[0] as Node2D


func _tick_stolen_skill(delta: float) -> void:
	_skill_timer -= delta
	if _skill_timer <= 0.0:
		_skill_timer = 2.4
		if target_node != null and is_instance_valid(target_node):
			var dir := (target_node.global_position - global_position).normalized()
			WindfallSound.play_spell(eaten_family)

			# Launch elemental projectile toward player
			var proj := ElementalProjectile.new()
			proj.position = global_position + dir * 16.0
			proj.setup(dir, attack_damage * 1.5, eaten_family, 360.0)
			# Flag so it hits player, not enemies
			proj.remove_from_group("player_attacks")
			get_parent().add_child(proj)


func _melee_attack_player(player: RootbornPlayer, delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 1.0
		player.take_damage(attack_damage)
		WindfallSound.play_hit()


func take_damage(amount: float) -> void:
	current_health -= amount
	modulate = Color(2.0, 0.3, 0.3)
	_flash_timer = 0.1

	if current_health <= 0.0:
		_die()


func apply_status(status_name: String, dur: float) -> void:
	match status_name:
		"wet":
			is_wet = true
			wet_timer = dur
		"chill":
			chill_timer = dur
		"burn":
			burn_timer = dur
		"shock":
			shock_timer = dur


func _tick_statuses(delta: float) -> void:
	if wet_timer > 0.0:
		wet_timer -= delta
		if wet_timer <= 0.0: is_wet = false

	if chill_timer > 0.0:
		chill_timer -= delta

	if shock_timer > 0.0:
		shock_timer -= delta

	if burn_timer > 0.0:
		burn_timer -= delta
		current_health -= 12.0 * delta
		if current_health <= 0.0:
			_die()


func _die() -> void:
	# Drop carried fruit and seeds for player
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p: RootbornPlayer = players[0]
		if not carried_fruit.is_empty():
			p.satchel_fruits.append(carried_fruit)
		# 60% chance to drop a random seed
		if randf() < 0.6:
			var s_pool := [&"voltberry", &"cinderapple", &"rimepear", &"briarcherry", &"zephyr_kiwi"]
			var drop_sid: StringName = s_pool[randi() % s_pool.size()]
			p.satchel_seeds[drop_sid] = p.satchel_seeds.get(drop_sid, 0) + 1
		p.satchel_changed.emit()

	died.emit(self)
	queue_free()


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(0, 6), 9.0, Color(0, 0, 0, 0.25))

	# Elemental stolen aura
	if has_eaten_fruit:
		var aura_col: Color = WindfallTypes.FAMILY_COLORS.get(eaten_family, Color.YELLOW)
		draw_arc(Vector2.ZERO, 15.0 + sin(_anim_time * 8.0) * 2.0, 0.0, TAU, 16, aura_col, 2.5)

	# Body by type
	match enemy_type:
		EnemyType.GNAWER:
			# Beetle shape
			draw_circle(Vector2.ZERO, 9.0, Color(0.45, 0.25, 0.1))
			draw_circle(Vector2(6, 0), 4.0, Color(0.2, 0.1, 0.05)) # Pincers
		_:
			# Poacher cloaked rogue
			draw_circle(Vector2.ZERO, 11.0, Color(0.22, 0.2, 0.25)) # Dark cloak
			draw_circle(Vector2(0, -4), 6.5, Color(0.15, 0.14, 0.16)) # Masked hood
			draw_circle(Vector2(2, -4), 2.0, Color(0.9, 0.2, 0.2)) # Glowing red eyes

	# Floating health bar
	if current_health < max_health:
		var bar_w := 24.0
		var bar_h := 3.5
		var bar_y := -18.0
		draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8))
		var pct := clampf(current_health / max_health, 0.0, 1.0)
		draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * pct, bar_h), Color(0.9, 0.2, 0.2))
