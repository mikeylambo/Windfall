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

# Presentation
var body_sprite: Sprite2D
var _hp_bar: Sprite2D
var _hp_fill: Sprite2D
var _knock: Vector2 = Vector2.ZERO
var _eat_timer: float = 0.0
var _hurt_timer: float = 0.0
var _attack_anim: float = 0.0
var _dying: bool = false
var _next_crit: bool = false
var _aura: Sprite2D
var _status_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)
	_setup_visuals()


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _dying:
		return
	_tick_statuses(delta)
	if _flash_timer > 0.0:
		_flash_timer -= delta
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)

	if shock_timer > 0.0 or _eat_timer > 0.0:
		velocity = _knock
		move_and_slide()
		_update_visuals(delta)
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

	velocity += _knock
	move_and_slide()

	# Cast stolen fruit skill if poacher has eaten one!
	if has_eaten_fruit:
		_tick_stolen_skill(delta)

	_update_visuals(delta)


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
	target_node = _nearest_player()


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
	_eat_timer = 0.9
	var c := WPal.element(eaten_family, 3)
	FX.element_burst(eaten_family, global_position + Vector2(0, -18), 1.2)
	FX.popup("STOLEN!", global_position + Vector2(0, -48), c, 16)
	_aura = FX.glow(self, c, 30.0, Vector2(0, -14), 0.3, 0.5)
	var mat := body_sprite.material as ShaderMaterial
	mat.set_shader_parameter("rim_count", 1)
	mat.set_shader_parameter("rim_a", c)
	mat.set_shader_parameter("rim_strength", 0.9)
	fruit_stolen.emit(carried_fruit)
	# Health boost from eating
	current_health = minf(current_health + 30.0, max_health * 1.4)
	# Now targets player aggressively!
	target_node = _nearest_player()


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
			proj.hostile = true
			get_parent().add_child(proj)
			_attack_anim = 0.25


func _melee_attack_player(player: RootbornPlayer, delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 1.0
		player.take_damage(attack_damage)
		WindfallSound.play_hit()
		_attack_anim = 0.25


func take_damage(amount: float) -> void:
	if _dying:
		return
	current_health -= amount
	_flash_timer = 0.12
	_hurt_timer = 0.18
	FX.damage_number(amount, global_position + Vector2(0, -26), -1, _next_crit)
	_next_crit = false
	var np := _nearest_player()
	if np:
		_knock = (global_position - np.global_position).normalized() * 170.0

	if current_health <= 0.0:
		_die()


func set_next_hit_crit(v: bool) -> void:
	_next_crit = v


func knockback(v: Vector2) -> void:
	_knock = v


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
	var p: RootbornPlayer = _nearest_player()
	if p:
		if not carried_fruit.is_empty():
			p.satchel_fruits.append(carried_fruit)
		# 60% chance to drop a random seed
		if randf() < 0.6:
			var s_pool := [&"voltberry", &"cinderapple", &"rimepear", &"briarcherry", &"zephyr_kiwi"]
			var drop_sid: StringName = s_pool[randi() % s_pool.size()]
			p.satchel_seeds[drop_sid] = p.satchel_seeds.get(drop_sid, 0) + 1
		p.satchel_changed.emit()

	_dying = true
	died.emit(self)
	EventBus.emit_unit_defeated(self, null)
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	if _hp_bar: _hp_bar.visible = false
	WindfallSound.play_poof()
	FX.shake(0.25)
	if has_eaten_fruit:
		FX.element_burst(eaten_family, global_position + Vector2(0, -14), 1.4)
	body_sprite.frame = Art.ROWS["collapse"] * 4
	var t := create_tween()
	t.tween_interval(0.16)
	t.tween_callback(func(): body_sprite.frame = Art.ROWS["collapse"] * 4 + 1)
	t.tween_interval(0.35)
	t.tween_callback(func(): FX.poof(global_position + Vector2(0, -10)))
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)


# ── Presentation ───────────────────────────────────────────────────────────

func _setup_visuals() -> void:
	var gnawer := enemy_type == EnemyType.GNAWER
	add_child(Art.shadow("small" if gnawer else "small"))
	body_sprite = Art.actor_sprite("gnawer" if gnawer else "poacher")
	add_child(body_sprite)
	(body_sprite.material as ShaderMaterial).set_shader_parameter("outline_color", Color("ffcf4a") if gnawer else Color("ff8a4a"))
	_hp_bar = Art.sprite("ui/hp_world_frame")
	_hp_bar.centered = true
	_hp_bar.offset = Vector2.ZERO
	_hp_bar.position = Vector2(0, -52 if not gnawer else -38)
	_hp_bar.z_index = 30
	add_child(_hp_bar)
	_hp_fill = Art.sprite("ui/hp_world_fill")
	_hp_fill.offset = Vector2.ZERO
	_hp_fill.region_enabled = true
	_hp_fill.position = Vector2(-12, -2)
	_hp_bar.add_child(_hp_fill)
	_hp_bar.visible = false


func _update_visuals(delta: float) -> void:
	if _eat_timer > 0.0: _eat_timer -= delta
	if _hurt_timer > 0.0: _hurt_timer -= delta
	if _attack_anim > 0.0: _attack_anim -= delta
	var v := velocity - _knock
	var face := v if v.length() > 5.0 else (target_node.global_position - global_position if target_node and is_instance_valid(target_node) else Vector2.DOWN)
	var dir := 2 if absf(face.x) > absf(face.y) * 1.1 else (1 if face.y < 0.0 else 0)
	var anim := "walk" if v.length() > 10.0 else "idle"
	if _eat_timer > 0.0: anim = "eat"
	elif _hurt_timer > 0.0: anim = "hurt"
	elif _attack_anim > 0.0: anim = "attack"
	var fps := 10.0 if anim == "walk" else (8.0 if anim != "idle" else 3.0)
	var count: int = Art.ROW_FRAMES[anim]
	var f := int(_anim_time * fps) % count
	body_sprite.frame = (Art.ROWS[anim] + dir) * 4 + f
	body_sprite.flip_h = dir == 2 and face.x < 0.0
	var mat := body_sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash", clampf(_flash_timer / 0.12, 0.0, 1.0))
	# warm rim keeps raiders readable against dark night grass
	mat.set_shader_parameter("outline_alpha", 0.25 + 0.7 * FX.night)
	# status tints
	var tint := Color.WHITE
	if chill_timer > 0.0: tint = Color(0.7, 0.92, 1.0)
	if burn_timer > 0.0: tint = Color(1.0, 0.8, 0.65)
	if shock_timer > 0.0 and int(_anim_time * 20.0) % 2 == 0: tint = Color(0.85, 0.75, 1.0)
	body_sprite.self_modulate = tint
	_status_timer -= delta
	if _status_timer <= 0.0:
		_status_timer = 0.3
		if burn_timer > 0.0:
			FX.burst(global_position + Vector2(0, -20), "fx/dot", WPal.element(1, 4), 3, 30.0, 0.6, Vector2(0, -60), 40.0, Vector2.UP, Vector2(1, 2), "overlay", Color(0, 0, 0, 0), true)
		if is_wet:
			FX.burst(global_position + Vector2(0, -16), "fx/dot", WPal.WATER[4], 2, 10.0, 0.5, Vector2(0, 80), 20.0, Vector2.DOWN, Vector2(1, 1), "world")
		if shock_timer > 0.0:
			FX.burst(global_position + Vector2(0, -18), "fx/spark", WPal.element(0, 4), 2, 60.0, 0.2, Vector2.ZERO, 180.0, Vector2.UP, Vector2(1, 1), "overlay", Color(0, 0, 0, 0), true)
	_hp_bar.visible = current_health < max_health
	if _hp_bar.visible:
		var tex_w := float(_hp_fill.texture.get_width())
		_hp_fill.region_rect = Rect2(0, 0, ceilf(tex_w * clampf(current_health / max_health, 0.0, 1.0) / 2.0) * 2.0, _hp_fill.texture.get_height())


func _nearest_player() -> RootbornPlayer:
	var best: RootbornPlayer = null
	var bd := INF
	for p in get_tree().get_nodes_in_group("player"):
		var d := global_position.distance_to((p as Node2D).global_position)
		if d < bd:
			bd = d
			best = p
	return best
