extends Node

signal accessibility_changed

var high_contrast_enabled: bool = false
var reduced_motion_enabled: bool = false
var screen_shake_enabled: bool = true
var large_text_enabled: bool = false
var colorblind_mode: StringName = &"none"


func _ready() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("register_save_provider"):
		save_manager.call("register_save_provider", &"accessibility", self)


func set_high_contrast(enabled: bool) -> void:
	if high_contrast_enabled == enabled:
		return
	high_contrast_enabled = enabled
	accessibility_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	if reduced_motion_enabled == enabled:
		return
	reduced_motion_enabled = enabled
	accessibility_changed.emit()


func set_screen_shake(enabled: bool) -> void:
	if screen_shake_enabled == enabled:
		return
	screen_shake_enabled = enabled
	accessibility_changed.emit()


func set_large_text(enabled: bool) -> void:
	if large_text_enabled == enabled:
		return
	large_text_enabled = enabled
	accessibility_changed.emit()


func set_colorblind_mode(mode: StringName) -> void:
	if colorblind_mode == mode:
		return
	colorblind_mode = mode
	accessibility_changed.emit()


func get_save_data() -> Dictionary:
	return {
		"high_contrast_enabled": high_contrast_enabled,
		"reduced_motion_enabled": reduced_motion_enabled,
		"screen_shake_enabled": screen_shake_enabled,
		"large_text_enabled": large_text_enabled,
		"colorblind_mode": String(colorblind_mode)
	}


func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	high_contrast_enabled = bool(data.get("high_contrast_enabled", high_contrast_enabled))
	reduced_motion_enabled = bool(data.get("reduced_motion_enabled", reduced_motion_enabled))
	screen_shake_enabled = bool(data.get("screen_shake_enabled", screen_shake_enabled))
	large_text_enabled = bool(data.get("large_text_enabled", large_text_enabled))
	colorblind_mode = StringName(data.get("colorblind_mode", String(colorblind_mode)))
	accessibility_changed.emit()
