extends Node

var current_scene_path: String = ""


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		return

	get_tree().change_scene_to_file(scene_path)
	current_scene_path = scene_path
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_scene_changed"):
		event_bus.call("emit_scene_changed", scene_path)


func reload_current_scene() -> void:
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func get_current_scene_path() -> String:
	return current_scene_path
