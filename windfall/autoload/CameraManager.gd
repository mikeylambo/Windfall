extends Node

signal camera_changed(camera)
signal target_changed(target)
signal camera_shake_started(strength: float)

var current_camera: Camera2D = null
var target_node: Node2D = null
var follow_enabled: bool = false
var follow_smoothing: float = 8.0
var shake_strength: float = 0.0
var shake_decay: float = 6.0

var _base_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if current_camera == null or not is_instance_valid(current_camera):
		return

	if follow_enabled and target_node != null and is_instance_valid(target_node):
		var weight := clampf(delta * follow_smoothing, 0.0, 1.0)
		current_camera.global_position = current_camera.global_position.lerp(target_node.global_position, weight)

	if shake_strength > 0.0:
		var shake_offset := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		current_camera.offset = _base_offset + shake_offset
		shake_strength = maxf(shake_strength - (shake_decay * delta), 0.0)
		if shake_strength <= 0.0:
			current_camera.offset = _base_offset


func set_camera(camera: Camera2D) -> void:
	current_camera = camera
	if current_camera != null and is_instance_valid(current_camera):
		current_camera.make_current()
		_base_offset = current_camera.offset
	camera_changed.emit(current_camera)


func get_camera() -> Camera2D:
	return current_camera


func set_target(target: Node2D) -> void:
	target_node = target
	target_changed.emit(target_node)


func clear_target() -> void:
	target_node = null
	target_changed.emit(target_node)


func enable_follow(enabled: bool = true) -> void:
	follow_enabled = enabled


func set_zoom(zoom: Vector2) -> void:
	if current_camera == null or not is_instance_valid(current_camera):
		return
	current_camera.zoom = zoom


func shake(strength: float, decay: float = 6.0) -> void:
	if current_camera == null or not is_instance_valid(current_camera):
		return

	var accessibility_manager := get_node_or_null("/root/AccessibilityManager")
	if accessibility_manager != null:
		if accessibility_manager.get("screen_shake_enabled") == false or accessibility_manager.get("reduced_motion_enabled") == true:
			return

	shake_strength = maxf(strength, 0.0)
	shake_decay = maxf(decay, 0.0)
	_base_offset = current_camera.offset
	camera_shake_started.emit(shake_strength)


func snap_to_target() -> void:
	if current_camera == null or not is_instance_valid(current_camera):
		return
	if target_node == null or not is_instance_valid(target_node):
		return
	current_camera.global_position = target_node.global_position
