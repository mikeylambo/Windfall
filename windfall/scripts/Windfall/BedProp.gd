extends Area2D
class_name BedProp

@export var day_manager: DayCycleManager
var is_focused: bool = false


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 36)
	col.shape = shape
	add_child(col)


func interact(player: RootbornPlayer) -> void:
	if day_manager != null:
		day_manager.advance_phase()
		WindfallSound.play_harvest()


func set_focused(val: bool) -> void:
	is_focused = val
	queue_redraw()


func _draw() -> void:
	# Wooden bed frame
	draw_rect(Rect2(-18, -16, 36, 32), Color(0.4, 0.25, 0.14))
	# White mattress & pillow
	draw_rect(Rect2(-15, -13, 30, 26), Color(0.88, 0.88, 0.9))
	draw_rect(Rect2(-13, -11, 26, 8), Color(1.0, 1.0, 1.0))
	# Cozy blanket
	draw_rect(Rect2(-15, -2, 30, 15), Color(0.25, 0.5, 0.65))

	if is_focused:
		draw_rect(Rect2(-18, -16, 36, 32), Color(1, 0.9, 0.4), false, 2.0)
