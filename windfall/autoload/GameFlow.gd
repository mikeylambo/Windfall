extends Node

signal mode_changed(old_mode: StringName, new_mode: StringName)

var main_menu_scene: String = ""
var gameplay_scene: String = ""
var game_over_scene: String = ""
var current_mode: StringName = &"boot"


func set_mode(new_mode: StringName) -> void:
	if current_mode == new_mode:
		return

	var old_mode := current_mode
	current_mode = new_mode
	mode_changed.emit(old_mode, current_mode)


func get_mode() -> StringName:
	return current_mode


func start_game() -> void:
	set_mode(&"gameplay")
	_set_game_state(&"PLAYING")
	_change_scene_if_available(gameplay_scene)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_game_started"):
		event_bus.call("emit_game_started")


func go_to_main_menu() -> void:
	set_mode(&"main_menu")
	_set_game_state(&"MAIN_MENU")
	_change_scene_if_available(main_menu_scene)


func restart_game() -> void:
	set_mode(&"gameplay")
	_set_game_state(&"PLAYING")
	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("reload_current_scene"):
		scene_loader.call("reload_current_scene")


func game_over() -> void:
	set_mode(&"game_over")
	_set_game_state(&"GAME_OVER")
	_change_scene_if_available(game_over_scene)


func _change_scene_if_available(scene_path: String) -> void:
	if scene_path.is_empty():
		return

	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("change_scene"):
		scene_loader.call("change_scene", scene_path)


func _set_game_state(state_name: StringName) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("set_state"):
		return

	var state_value: Variant = null
	match state_name:
		&"MAIN_MENU":
			state_value = game_state.State.MAIN_MENU
		&"PLAYING":
			state_value = game_state.State.PLAYING
		&"GAME_OVER":
			state_value = game_state.State.GAME_OVER
		&"LOADING":
			state_value = game_state.State.LOADING
		&"PAUSED":
			state_value = game_state.State.PAUSED
		_:
			state_value = game_state.State.BOOT

	game_state.call("set_state", state_value)
