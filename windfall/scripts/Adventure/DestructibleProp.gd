extends StaticBody2D
class_name DestructibleProp

signal destroyed

@export var max_health: float = 1.0
@export var drop_chance: float = 0.5
@export var prop_color: Color = Color(0.35, 0.7, 0.3)

var _health: float = 1.0


func _ready() -> void:
	_health = max_health
	add_to_group("destructibles")


func take_damage(amount: float) -> void:
	_health -= amount
	if _health <= 0.0:
		_break_prop()
	else:
		modulate = Color(1.5, 1.2, 1.2)
		await get_tree().create_timer(0.08).timeout
		modulate = Color.WHITE


func _break_prop() -> void:
	destroyed.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, prop_color)
	draw_circle(Vector2(4, -4), 8.0, prop_color.lightened(0.2))
