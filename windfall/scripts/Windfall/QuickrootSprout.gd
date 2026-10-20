extends Area2D
class_name QuickrootSprout

@export var species_id: StringName = &"voltberry"
@export var family: int = WindfallTypes.Family.STORM
@export var duration: float = 12.0
@export var power: float = 30.0

var _timer: float = 0.0
var _pulse_timer: float = 0.0
var _anim_time: float = 0.0

func setup(p_species_id: StringName, p_family: int, p_power: float = 30.0, p_duration: float = 12.0) -> void:
	species_id = p_species_id
	family = p_family
	power = p_power
	duration = p_duration
	_timer = duration


func _ready() -> void:
	add_to_group("sprouts")
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 45.0
	col.shape = shape
	add_child(col)


func _process(delta: float) -> void:
	_anim_time += delta
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
		return

	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_pulse_timer = 1.4
		_trigger_effect()

	queue_redraw()


func _trigger_effect() -> void:
	WindfallSound.play_spell(family)
	var targets := get_overlapping_bodies()
	for body in targets:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.call("take_damage", power)
			if body.has_method("apply_status"):
				match family:
					WindfallTypes.Family.STORM:
						body.call("apply_status", "shock", 3.0)
					WindfallTypes.Family.EMBER:
						body.call("apply_status", "burn", 4.0)
					WindfallTypes.Family.FROST:
						body.call("apply_status", "chill", 4.0)
					WindfallTypes.Family.TIDE:
						body.call("apply_status", "wet", 6.0)
					WindfallTypes.Family.VERDANT:
						body.call("apply_status", "snare", 2.5)

		# Healing sprouts heal player
		if (family == WindfallTypes.Family.LUMEN or species_id == &"mistlime") and body.is_in_group("player"):
			if body.has_method("heal"):
				body.call("heal", power * 0.5)


func _draw() -> void:
	var color: Color = WindfallTypes.FAMILY_COLORS.get(family, Color.GREEN)
	var wobble: float = sin(_anim_time * 6.0) * 3.0

	# Ground stem & base
	draw_circle(Vector2.ZERO, 10.0, Color(0.2, 0.4, 0.15))
	draw_line(Vector2.ZERO, Vector2(wobble, -18.0), Color(0.25, 0.65, 0.2), 4.0)

	# Glowing flower / fruit bloom
	var bloom_radius: float = 9.0 + sin(_anim_time * 8.0) * 2.0
	draw_circle(Vector2(wobble, -18.0), bloom_radius, color)
	draw_circle(Vector2(wobble, -18.0), bloom_radius * 0.5, Color.WHITE)

	# Pulse ring
	var pulse_radius: float = 40.0 * (1.0 - (_pulse_timer / 1.4))
	var alpha: float = (_pulse_timer / 1.4) * 0.4
	draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, alpha), 2.0)
