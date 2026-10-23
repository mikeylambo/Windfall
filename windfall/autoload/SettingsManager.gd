extends Node

var settings_path: String = "user://settings.json"
var settings: Dictionary = {}

const DEFAULT_SETTINGS := {
	"master_volume_db": 0.0,
	"music_volume_db": 0.0,
	"sfx_volume_db": 0.0,
	"ui_volume_db": 0.0,
	"master_muted": false,
	"music_muted": false,
	"sfx_muted": false,
	"ui_muted": false,
	"fullscreen": false
}


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		reset_settings()
		save_settings()
		return

	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		reset_settings()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	settings = DEFAULT_SETTINGS.duplicate(true)
	if parsed is Dictionary:
		for key in parsed.keys():
			settings[key] = parsed[key]


func save_settings() -> bool:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(settings))
	return true


func reset_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)


func get_setting(key: String, default_value = null):
	return settings.get(key, default_value)


func set_setting(key: String, value) -> void:
	settings[key] = value


func apply_settings() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		if audio_manager.has_method("set_bus_volume"):
			audio_manager.call("set_bus_volume", &"Master", float(settings.get("master_volume_db", 0.0)))
			audio_manager.call("set_bus_volume", &"Music", float(settings.get("music_volume_db", 0.0)))
			audio_manager.call("set_bus_volume", &"SFX", float(settings.get("sfx_volume_db", 0.0)))
			audio_manager.call("set_bus_volume", &"UI", float(settings.get("ui_volume_db", 0.0)))
		if audio_manager.has_method("mute_bus"):
			audio_manager.call("mute_bus", &"Master", bool(settings.get("master_muted", false)))
			audio_manager.call("mute_bus", &"Music", bool(settings.get("music_muted", false)))
			audio_manager.call("mute_bus", &"SFX", bool(settings.get("sfx_muted", false)))
			audio_manager.call("mute_bus", &"UI", bool(settings.get("ui_muted", false)))

	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
