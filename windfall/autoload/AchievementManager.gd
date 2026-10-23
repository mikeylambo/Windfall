extends Node

signal achievement_registered(achievement_id: StringName)
signal achievement_progressed(achievement_id: StringName, current_value: float, target_value: float)
signal achievement_unlocked(achievement_id: StringName)

var achievements: Dictionary = {}
var progress: Dictionary = {}
var unlocked: Dictionary = {}


func register_achievement(data: Resource) -> void:
	if data == null or not is_instance_valid(data):
		return

	var achievement_id := _get_achievement_id(data)
	if achievement_id == &"":
		return

	achievements[achievement_id] = data
	if not progress.has(achievement_id):
		progress[achievement_id] = 0.0
	if not unlocked.has(achievement_id):
		unlocked[achievement_id] = false

	achievement_registered.emit(achievement_id)


func register_from_database() -> void:
	var database := get_node_or_null("/root/ResourceDatabase")
	if database == null:
		return

	var registered: Array[Resource] = []
	if database.has_method("get_resources_by_tag"):
		for resource in database.get_resources_by_tag(&"achievement"):
			if resource is Resource:
				register_achievement(resource)
				registered.append(resource)

	_register_achievement_resources_from_dictionary(database.get("resources_by_id"), registered)
	_register_achievement_resources_from_dictionary(database.get("resources_by_path"), registered)


func add_progress(achievement_id: StringName, amount: float = 1.0) -> void:
	if not achievements.has(achievement_id):
		return
	if is_unlocked(achievement_id):
		return

	set_progress(achievement_id, get_progress(achievement_id) + amount)


func set_progress(achievement_id: StringName, value: float) -> void:
	if not achievements.has(achievement_id):
		return
	if is_unlocked(achievement_id):
		return

	var target_value: float = _get_target_value(achievement_id)
	var current_value: float = value
	if current_value < 0.0:
		current_value = 0.0
	progress[achievement_id] = current_value
	achievement_progressed.emit(achievement_id, current_value, target_value)

	if current_value >= target_value:
		unlock(achievement_id)


func unlock(achievement_id: StringName) -> void:
	if not achievements.has(achievement_id):
		return
	if is_unlocked(achievement_id):
		return

	unlocked[achievement_id] = true
	var target_value := _get_target_value(achievement_id)
	if get_progress(achievement_id) < target_value:
		progress[achievement_id] = target_value

	achievement_unlocked.emit(achievement_id)


func is_unlocked(achievement_id: StringName) -> bool:
	return bool(unlocked.get(achievement_id, false))


func get_progress(achievement_id: StringName) -> float:
	return float(progress.get(achievement_id, 0.0))


func get_achievement_data(achievement_id: StringName) -> Resource:
	return achievements.get(achievement_id, null)


func get_save_data() -> Dictionary:
	return {
		"progress": progress.duplicate(true),
		"unlocked": unlocked.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var saved_progress: Variant = data.get("progress", {})
	if saved_progress is Dictionary:
		for achievement_id in saved_progress.keys():
			var typed_id := StringName(achievement_id)
			progress[typed_id] = float(saved_progress[achievement_id])

	var saved_unlocked: Variant = data.get("unlocked", {})
	if saved_unlocked is Dictionary:
		for achievement_id in saved_unlocked.keys():
			var typed_id := StringName(achievement_id)
			unlocked[typed_id] = bool(saved_unlocked[achievement_id])


func _register_achievement_resources_from_dictionary(resources: Variant, registered: Array[Resource]) -> void:
	if not resources is Dictionary:
		return

	for resource in resources.values():
		if not resource is Resource:
			continue
		if registered.has(resource):
			continue
		if _has_achievement_id(resource):
			register_achievement(resource)
			registered.append(resource)


func _get_achievement_id(data: Resource) -> StringName:
	var value: Variant = data.get("achievement_id")
	if value is StringName:
		return value
	if value is String:
		return StringName(value)
	return &""


func _has_achievement_id(data: Resource) -> bool:
	return _get_achievement_id(data) != &""


func _get_target_value(achievement_id: StringName) -> float:
	var data: Resource = get_achievement_data(achievement_id)
	if data == null:
		return 1.0

	var value: Variant = data.get("target_value")
	if value is float or value is int:
		return max(float(value), 0.0)
	return 1.0
