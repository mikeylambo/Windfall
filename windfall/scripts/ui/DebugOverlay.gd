extends CanvasLayer

@export var enabled_by_default: bool = true

@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	visible = enabled_by_default


func _process(_delta: float) -> void:
	if InputMap.has_action("debug_reset") and Input.is_action_just_pressed("debug_reset"):
		visible = not visible

	if not visible or debug_label == null:
		return

	debug_label.text = _build_debug_text()


func _build_debug_text() -> String:
	return "FPS: %s\nCurrent Scene: %s\nEventBus: %s\nSaveManager: %s\nAudioManager: %s\nSettingsManager: %s\nCombatManager: %s" % [
		str(Engine.get_frames_per_second()),
		_get_current_scene_path(),
		str(_autoload_exists("EventBus")),
		str(_autoload_exists("SaveManager")),
		str(_autoload_exists("AudioManager")),
		str(_autoload_exists("SettingsManager")),
		str(_autoload_exists("CombatManager"))
	]


func _get_current_scene_path() -> String:
	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("get_current_scene_path"):
		var scene_path := str(scene_loader.call("get_current_scene_path"))
		if not scene_path.is_empty():
			return scene_path

	var current_scene := get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		return current_scene.scene_file_path

	return "Unavailable"


func _autoload_exists(autoload_name: String) -> bool:
	return get_node_or_null("/root/%s" % autoload_name) != null
