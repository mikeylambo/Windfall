extends Node

signal database_scanned
signal resource_registered(resource_id: StringName, resource: Resource)

@export var auto_scan_on_ready: bool = true
@export var scan_paths: Array[String] = ["res://data", "res://resources"]

var resources_by_id: Dictionary = {}
var resources_by_path: Dictionary = {}
var resources_by_tag: Dictionary = {}


func _ready() -> void:
	if auto_scan_on_ready:
		scan_database()


func scan_database() -> void:
	clear_database()
	for scan_path in scan_paths:
		_scan_path(scan_path)
	database_scanned.emit()
	_emit_database_scanned_event()
	_register_achievements_from_database()


func register_resource(resource: Resource, path: String = "") -> void:
	if resource == null or not is_instance_valid(resource):
		return

	var resource_id := _get_resource_id(resource, path)
	if resource_id != &"":
		resources_by_id[resource_id] = resource

	if not path.is_empty():
		resources_by_path[path] = resource

	_index_resource_tags(resource)

	if resource_id != &"":
		resource_registered.emit(resource_id, resource)
		_emit_resource_registered_event(resource_id, resource)


func get_resource_by_id(resource_id: StringName) -> Resource:
	return resources_by_id.get(resource_id, null)


func get_resource_by_path(path: String) -> Resource:
	return resources_by_path.get(path, null)


func get_resources_by_tag(tag: StringName) -> Array:
	return resources_by_tag.get(tag, [])


func clear_database() -> void:
	resources_by_id.clear()
	resources_by_path.clear()
	resources_by_tag.clear()


func _scan_path(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			_scan_path(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var loaded := ResourceLoader.load(full_path)
			if loaded is Resource:
				register_resource(loaded, full_path)

		file_name = dir.get_next()
	dir.list_dir_end()


func _get_resource_id(resource: Resource, path: String = "") -> StringName:
	var id_fields := [
		&"entity_id",
		&"ability_id",
		&"effect_id",
		&"item_id",
		&"achievement_id",
		&"quest_id",
		&"recipe_id",
		&"pool_id",
		&"menu_id",
		&"resource_id"
	]
	for field_name in id_fields:
		var value: Variant = resource.get(String(field_name))
		var id := _variant_to_string_name(value)
		if id != &"":
			return id

	if not path.is_empty():
		return StringName(path.get_file().get_basename())

	return &""


func _register_achievements_from_database() -> void:
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_method("register_from_database"):
		achievement_manager.call("register_from_database")


func _emit_database_scanned_event() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_database_scanned"):
		event_bus.call("emit_database_scanned")


func _emit_resource_registered_event(resource_id: StringName, resource: Resource) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_resource_registered"):
		event_bus.call("emit_resource_registered", resource_id, resource)


func _variant_to_string_name(value: Variant) -> StringName:
	if value is StringName:
		return value
	if value is String:
		return StringName(value)
	return &""


func _index_resource_tags(resource: Resource) -> void:
	var tags_value: Variant = resource.get("tags")
	if not tags_value is Array:
		return

	for tag_value in tags_value:
		var tag := _variant_to_string_name(tag_value)
		if tag == &"":
			continue

		if not resources_by_tag.has(tag):
			resources_by_tag[tag] = []
		resources_by_tag[tag].append(resource)
