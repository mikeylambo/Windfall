extends Area2D
class_name ElementalProjectile

@export var speed: float = 420.0
@export var damage: float = 35.0
@export var family: int = WindfallTypes.Family.STORM
@export var is_piercing: bool = false
@export var splash_radius: float = 0.0
@export var lifetime: float = 1.8
@export var chain_count: int = 0

var direction: Vector2 = Vector2.RIGHT
var targets_hit: Array[Node2D] = []
var _anim_time: float = 0.0

func setup(p_dir: Vector2, p_damage: float, p_family: int, p_speed: float = 420.0, p_splash: float = 0.0, p_pierce: bool = false, p_chains: int = 0) -> void:
	direction = p_dir.normalized()
	damage = p_damage
	family = p_family
	speed = p_speed
	splash_radius = p_splash
	is_piercing = p_pierce
	chain_count = p_chains
	rotation = direction.angle()


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or targets_hit.has(body):
		return

	if body.has_method("take_damage"):
		targets_hit.append(body)
		_hit_target(body)

		if chain_count > 0:
			_chain_to_next(body)

		if splash_radius > 0.0:
			_explode_splash()

		if not is_piercing:
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	var p := area.get_parent()
	if p != null and not p.is_in_group("player") and not targets_hit.has(p):
		if p.has_method("take_damage"):
			targets_hit.append(p)
			_hit_target(p)
			if not is_piercing:
				queue_free()


func _hit_target(target: Node2D) -> void:
	var final_damage := damage
	# Elemental interaction check
	if target.has_method("is_wet") and target.call("is_wet") and family == WindfallTypes.Family.STORM:
		final_damage *= 1.5 # Conductive bonus!
	target.call("take_damage", final_damage)

	if target.has_method("apply_status"):
		match family:
			WindfallTypes.Family.STORM:
				target.call("apply_status", "shock", 2.5)
			WindfallTypes.Family.EMBER:
				target.call("apply_status", "burn", 3.5)
			WindfallTypes.Family.FROST:
				target.call("apply_status", "chill", 3.5)
			WindfallTypes.Family.TIDE:
				target.call("apply_status", "wet", 5.0)

	WindfallSound.play_hit()


func _chain_to_next(last_target: Node2D) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist := 200.0

	for enemy in enemies:
		if enemy is Node2D and enemy != last_target and not targets_hit.has(enemy):
			var dist := last_target.global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy

	if closest != null:
		var chain_proj: ElementalProjectile = duplicate()
		chain_proj.position = last_target.global_position
		chain_proj.setup((closest.global_position - last_target.global_position).normalized(), damage * 0.85, family, speed, 0.0, false, chain_count - 1)
		get_parent().add_child(chain_proj)
		WindfallSound.play_spell(WindfallTypes.Family.STORM)


func _explode_splash() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D and not targets_hit.has(enemy):
			if global_position.distance_to(enemy.global_position) <= splash_radius:
				if enemy.has_method("take_damage"):
					enemy.call("take_damage", damage * 0.6)


func _draw() -> void:
	var col: Color = WindfallTypes.FAMILY_COLORS.get(family, Color.YELLOW)
	match family:
		WindfallTypes.Family.STORM:
			# Jagged lightning bolt
			var pts := PackedVector2Array([
				Vector2(-12, 0),
				Vector2(-4, -5 + sin(_anim_time * 30.0) * 4.0),
				Vector2(4, 5 + cos(_anim_time * 30.0) * 4.0),
				Vector2(14, 0)
			])
			draw_polyline(pts, col, 3.5)
			draw_circle(Vector2(14, 0), 4.0, Color.WHITE)
		WindfallTypes.Family.EMBER:
			# Molten fireball with flare
			draw_circle(Vector2.ZERO, 9.0, col)
			draw_circle(Vector2(-4, 0), 6.0, Color(1, 0.8, 0.2))
			draw_circle(Vector2(2, 0), 4.0, Color.WHITE)
		WindfallTypes.Family.FROST:
			# Sharp diamond ice shard
			var pts := PackedVector2Array([
				Vector2(-10, 0),
				Vector2(0, -6),
				Vector2(14, 0),
				Vector2(0, 6)
			])
			draw_colored_polygon(pts, col)
			draw_polyline(pts, Color.WHITE, 1.5)
		WindfallTypes.Family.TIDE:
			# Water orb
			draw_circle(Vector2.ZERO, 8.0, col)
			draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 12, Color.WHITE, 2.0)
		WindfallTypes.Family.LUMEN:
			# Radiant beam projectile
			draw_line(Vector2(-18, 0), Vector2(18, 0), Color.WHITE, 5.0)
			draw_line(Vector2(-18, 0), Vector2(18, 0), col, 9.0)
		_:
			# Generic elemental bullet
			draw_circle(Vector2.ZERO, 8.0, col)
			draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
