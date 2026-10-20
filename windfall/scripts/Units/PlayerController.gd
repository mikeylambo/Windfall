extends "res://scripts/Units/Unit.gd"


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if is_alive():
		velocity = input_direction * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
