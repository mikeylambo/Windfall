extends Area2D
class_name ElementalProjectile

@export var speed: float = 420.0
@export var damage: float = 35.0
@export var family: int = WindfallTypes.Family.STORM
@export var is_piercing: bool = false
@export var splash_radius: float = 0.0
@export var lifetime: float = 1.8
@export var chain_count: int = 0

## Fired by an enemy that ate stolen fruit: hits the player instead of enemies.
var hostile: bool = false
## Set by stomach pairings on launch (see RootbornPlayer._launch).
var conductive: bool = false
## Online client copy: drawn only, never deals damage.
var visual_only: bool = false
var fanned: bool = false

var direction: Vector2 = Vector2.RIGHT
var targets_hit: Array[Node2D] = []
var _anim_time: float = 0.0
var _sprite: Sprite2D
var _trail: CPUParticles2D
var _dead: bool = false

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
	z_index = 8
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

	if not visual_only:
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
		Net.broadcast_projectile(global_position, direction, family, speed, hostile)
	else:
		lifetime = minf(lifetime, 0.9)
	_build_visuals()


func _build_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex("fx/proj_%d" % family)
	_sprite.position = Vector2(0, -12).rotated(-rotation)
	add_child(_sprite)
	if hostile:
		_sprite.modulate = Color(1.0, 0.85, 0.85)
	# element trail
	_trail = CPUParticles2D.new()
	_trail.local_coords = false
	_trail.amount = 10
	_trail.lifetime = 0.35
	_trail.position = _sprite.position
	_trail.gravity = Vector2.ZERO
	_trail.initial_velocity_min = 5.0
	_trail.initial_velocity_max = 20.0
	_trail.spread = 180.0
	var tex := "fx/dot4"
	var grav := Vector2.ZERO
	match family:
		WindfallTypes.Family.STORM: tex = "fx/spark"
		WindfallTypes.Family.EMBER: grav = Vector2(0, -80)
		WindfallTypes.Family.FROST: tex = "fx/shard"
		WindfallTypes.Family.VERDANT: tex = "fx/leaf"
		WindfallTypes.Family.LUMEN: tex = "fx/spark"
	_trail.texture = Art.tex(tex)
	_trail.gravity = grav
	var g := Gradient.new()
	g.set_color(0, Color(WPal.element(family, 3), 0.6))
	g.set_color(1, Color(WPal.element(family, 2), 0.0))
	_trail.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail.material = m
	add_child(_trail)
	FX.glow(self, WPal.element(family, 3), 20.0, Vector2(0, -12), 0.25, 0.4)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_anim_time += delta
	position += direction * speed * delta
	lifetime -= delta
	if _sprite and family == WindfallTypes.Family.STORM:
		_sprite.scale = Vector2.ONE * (1.0 + sin(_anim_time * 40.0) * 0.15)
	if lifetime <= 0.0:
		_finish()


func _can_hit(body: Node) -> bool:
	if hostile:
		return body.is_in_group("player")
	return not body.is_in_group("player") and not body.is_in_group("allies")


func _on_body_entered(body: Node2D) -> void:
	if _dead or not _can_hit(body) or targets_hit.has(body):
		return

	if body.has_method("take_damage"):
		targets_hit.append(body)
		_hit_target(body)

		if chain_count > 0 and not hostile:
			_chain_to_next(body)

		if splash_radius > 0.0:
			_explode_splash()

		if not is_piercing:
			_finish()


func _on_area_entered(area: Area2D) -> void:
	if _dead or hostile:
		return
	var p := area.get_parent()
	if p != null and not p.is_in_group("player") and not targets_hit.has(p):
		if p.has_method("take_damage") and p.is_in_group("enemies"):
			targets_hit.append(p)
			_hit_target(p)
			if not is_piercing:
				_finish()


func _hit_target(target: Node2D) -> void:
	var final_damage := damage
	# Elemental interaction: Storm conducts through wet targets
	var is_conductive := family == WindfallTypes.Family.STORM and (conductive or bool(target.get("is_wet")))
	if is_conductive:
		final_damage *= 1.5
		FX.popup("CONDUCTIVE!", target.global_position + Vector2(0, -56), WPal.element(family, 4), 13)
	if target.has_method("set_next_hit_crit"):
		target.call("set_next_hit_crit", is_conductive)
	target.call("take_damage", final_damage)
	EventBus.emit_damage_dealt(self, target, final_damage)

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

	FX.element_burst(family, target.global_position + Vector2(0, -14), 0.6)
	FX.shake(0.12)
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
		# the arc visibly leaps between targets, then a fresh bolt carries on
		FX.lightning(last_target.global_position + Vector2(0, -14), closest.global_position + Vector2(0, -14), WPal.element(family, 3))
		var chain_proj := ElementalProjectile.new()
		chain_proj.position = closest.global_position - (closest.global_position - last_target.global_position).normalized() * 10.0
		chain_proj.setup((closest.global_position - last_target.global_position).normalized(), damage * 0.85, family, speed, 0.0, false, chain_count - 1)
		chain_proj.targets_hit = targets_hit.duplicate()
		# spawned from a collision callback: add after the physics flush
		get_parent().add_child.call_deferred(chain_proj)
		WindfallSound.play_spell(WindfallTypes.Family.STORM)


func _explode_splash() -> void:
	FX.ring(global_position, WPal.element(family, 3), splash_radius, 0.35)
	if fanned:
		FX.popup("FANNED!", global_position + Vector2(0, -30), WPal.element(WindfallTypes.Family.GALE, 4), 12)
	FX.element_burst(family, global_position, 1.1)
	FX.shake(0.28)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D and not targets_hit.has(enemy):
			if global_position.distance_to(enemy.global_position) <= splash_radius:
				if enemy.has_method("take_damage"):
					enemy.call("take_damage", damage * 0.6)
				if fanned and enemy.has_method("apply_status"):
					enemy.call("apply_status", "burn", 4.0)


func _finish() -> void:
	if _dead:
		return
	_dead = true
	set_deferred("monitoring", false)
	if _sprite:
		_sprite.visible = false
	if _trail:
		_trail.emitting = false
	FX.burst(global_position + Vector2(0, -12), "fx/dot", WPal.element(family, 4), 5, 50.0, 0.25)
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_callback(queue_free)
