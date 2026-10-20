extends Area2D
class_name QuickrootSprout

@export var species_id: StringName = &"voltberry"
@export var family: int = WindfallTypes.Family.STORM
@export var duration: float = 12.0
@export var power: float = 30.0

var _timer: float = 0.0
var _pulse_timer: float = 0.0
var _anim_time: float = 0.0
var _sprite: Sprite2D

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
	add_child(Art.shadow("small"))
	_sprite = Art.sprite("fx/quickroot_%d" % family, 1, 1, Vector2(24, 52))
	_sprite.scale = Vector2(0.2, 0.0)
	add_child(_sprite)
	var t := _sprite.create_tween()
	t.tween_property(_sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.dust(global_position, 8)
	FX.element_burst(family, global_position + Vector2(0, -10), 0.8)
	FX.glow(self, WPal.element(family, 3), 34.0, Vector2(0, -32), 0.3, 0.8)


func _process(delta: float) -> void:
	_anim_time += delta
	_timer -= delta
	if _timer <= 0.0:
		set_process(false)
		FX.poof(global_position + Vector2(0, -10), WPal.element(family, 4))
		var t := create_tween()
		t.tween_property(_sprite, "scale", Vector2(1.2, 0.0), 0.2)
		t.tween_callback(queue_free)
		return
	_sprite.skew = sin(_anim_time * 3.0) * 0.06

	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_pulse_timer = 1.4
		_trigger_effect()



func _trigger_effect() -> void:
	WindfallSound.play_spell(family)
	FX.ring(global_position, WPal.element(family, 3), 45.0, 0.4)
	var squash := _sprite.create_tween()
	squash.tween_property(_sprite, "scale", Vector2(1.15, 0.85), 0.06)
	squash.tween_property(_sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	var targets := get_overlapping_bodies()
	for body in targets:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.call("take_damage", power)
			if family == WindfallTypes.Family.STORM:
				FX.lightning(global_position + Vector2(0, -44), (body as Node2D).global_position + Vector2(0, -14), WPal.element(family, 3), 2.0)
			else:
				FX.element_burst(family, (body as Node2D).global_position + Vector2(0, -14), 0.5)
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


