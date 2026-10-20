extends Node

var save_path: String = "user://save_data.json"
var save_version: int = 1
var registered_save_providers: Dictionary = {}


func _ready() -> void:
	_auto_register_global_save_providers()


func register_save_provider(section_id: StringName, provider: Object) -> void:
	if section_id == &"" or provider == null or not is_instance_valid(provider):
		return

	registered_save_providers[section_id] = provider


func unregister_save_provider(section_id: StringName) -> void:
	registered_save_providers.erase(section_id)


func get_registered_save_providers() -> Dictionary:
	return registered_save_providers.duplicate()


func save_data(data: Dictionary) -> bool:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_save_requested"):
		event_bus.call("emit_save_requested")

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(data))
	if event_bus != null and event_bus.has_method("emit_save_completed"):
		event_bus.call("emit_save_completed")
	return true


func load_data() -> Dictionary:
	if not has_save():
		return {}

	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_load_requested"):
		event_bus.call("emit_load_requested")

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		if event_bus != null and event_bus.has_method("emit_load_completed"):
			event_bus.call("emit_load_completed")
		return parsed

	return {}


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> bool:
	if not has_save():
		return true

	return DirAccess.remove_absolute(save_path) == OK


func create_save_snapshot() -> Dictionary:
	var snapshot := {
		"version": save_version,
		"timestamp_unix": Time.get_unix_time_from_system(),
		"current_scene": _get_current_scene_path(),
		"nodes": [],
		"global": {}
	}

	for node in get_saveable_nodes():
		var saveable: Object = _get_saveable_provider(node)
		if saveable != null and saveable.has_method("get_save_data"):
			snapshot["nodes"].append(saveable.call("get_save_data"))

	for section_id in registered_save_providers.keys():
		var provider: Object = registered_save_providers[section_id]
		if provider != null and is_instance_valid(provider) and provider.has_method("get_save_data"):
			snapshot["global"][section_id] = provider.call("get_save_data")

	return snapshot


func save_game() -> bool:
	return save_data(create_save_snapshot())


func load_game() -> Dictionary:
	var data := load_data()
	if not data.is_empty():
		apply_save_snapshot(data)
	return data


func apply_save_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return

	_apply_global_save_data(snapshot)

	if not snapshot.has("nodes") or not snapshot["nodes"] is Array:
		return

	var saveable_lookup := {}
	for node in get_saveable_nodes():
		var saveable: Object = _get_saveable_provider(node)
		if saveable != null and saveable.has_method("get_save_id") and saveable.has_method("load_save_data"):
			var save_id := StringName(saveable.call("get_save_id"))
			if save_id != &"":
				saveable_lookup[save_id] = saveable

	for record in snapshot["nodes"]:
		if not record is Dictionary:
			continue
		var save_id := StringName(record.get("save_id", &""))
		if save_id == &"" or not saveable_lookup.has(save_id):
			continue
		var saveable: Object = saveable_lookup[save_id]
		saveable.call("load_save_data", record)


func get_saveable_nodes() -> Array:
	return get_tree().get_nodes_in_group("saveable")


func _auto_register_global_save_providers() -> void:
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_method("get_save_data") and achievement_manager.has_method("load_save_data"):
		register_save_provider(&"achievements", achievement_manager)


func _apply_global_save_data(snapshot: Dictionary) -> void:
	if not snapshot.has("global") or not snapshot["global"] is Dictionary:
		return

	var global_data: Dictionary = snapshot["global"]
	for section_id in registered_save_providers.keys():
		if not global_data.has(section_id):
			continue

		var provider: Object = registered_save_providers[section_id]
		if provider != null and is_instance_valid(provider) and provider.has_method("load_save_data"):
			provider.call("load_save_data", global_data[section_id])


func _get_current_scene_path() -> String:
	var current_scene := get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		return current_scene.scene_file_path
	return ""


func _get_saveable_provider(node) -> Object:
	if node == null or not is_instance_valid(node):
		return null

	if node is Node:
		var component := (node as Node).get_node_or_null("SaveableComponent")
		if component != null:
			return component

	if node.has_method("get_save_data"):
		return node

	return null
