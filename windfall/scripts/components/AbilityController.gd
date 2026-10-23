extends Node

signal ability_added(ability)
signal ability_removed(ability)
signal ability_used(user, target, ability)
signal ability_failed(user, target, ability, reason: String)

@export var abilities: Array[Resource] = []
@export var auto_process_cooldowns: bool = true

var cooldowns: Dictionary = {}


func _ready() -> void:
	_duplicate_runtime_abilities()


func _process(delta: float) -> void:
	if not auto_process_cooldowns:
		return

	var safe_delta := maxf(delta, 0.0)
	for ability_id in cooldowns.keys():
		var remaining := maxf(float(cooldowns.get(ability_id, 0.0)) - safe_delta, 0.0)
		if remaining <= 0.0:
			cooldowns.erase(ability_id)
		else:
			cooldowns[ability_id] = remaining


func add_ability(ability: Resource) -> void:
	if ability == null or not is_instance_valid(ability):
		return

	var runtime_ability := ability.duplicate(true) as Resource
	if runtime_ability == null:
		return

	abilities.append(runtime_ability)
	ability_added.emit(runtime_ability)


func remove_ability(ability_id: StringName) -> void:
	for index in range(abilities.size() - 1, -1, -1):
		var ability := abilities[index]
		if ability == null or not is_instance_valid(ability):
			abilities.remove_at(index)
			continue

		if _get_ability_id(ability) == ability_id:
			abilities.remove_at(index)
			cooldowns.erase(ability_id)
			ability_removed.emit(ability)
			return


func has_ability(ability_id: StringName) -> bool:
	return get_ability(ability_id) != null


func get_ability(ability_id: StringName) -> Resource:
	for ability in abilities:
		if ability == null or not is_instance_valid(ability):
			continue

		if _get_ability_id(ability) == ability_id:
			return ability

	return null


func can_use_ability(ability_id: StringName, target = null) -> bool:
	var ability := get_ability(ability_id)
	if ability == null:
		return false

	if get_cooldown_remaining(ability_id) > 0.0:
		return false

	var user := get_parent()
	if ability.has_method("can_use"):
		return bool(ability.call("can_use", user, target))

	return true


func use_ability(ability_id: StringName, target = null) -> bool:
	var ability := get_ability(ability_id)
	var user := get_parent()

	if ability == null:
		ability_failed.emit(user, target, ability, "missing")
		return false

	if get_cooldown_remaining(ability_id) > 0.0:
		ability_failed.emit(user, target, ability, "cooldown")
		return false

	if ability.has_method("can_use") and not bool(ability.call("can_use", user, target)):
		ability_failed.emit(user, target, ability, "cannot_use")
		return false

	if ability.has_method("use"):
		ability.call("use", user, target)

	var cooldown_duration := _get_ability_cooldown(ability)
	if cooldown_duration > 0.0:
		set_cooldown(ability_id, cooldown_duration)

	ability_used.emit(user, target, ability)
	_emit_event_bus_ability_used(user, target, ability)
	return true


func get_cooldown_remaining(ability_id: StringName) -> float:
	return maxf(float(cooldowns.get(ability_id, 0.0)), 0.0)


func set_cooldown(ability_id: StringName, duration: float) -> void:
	var safe_duration := maxf(duration, 0.0)
	if safe_duration <= 0.0:
		cooldowns.erase(ability_id)
		return

	cooldowns[ability_id] = safe_duration


func clear_cooldowns() -> void:
	cooldowns.clear()


func _duplicate_runtime_abilities() -> void:
	var runtime_abilities: Array[Resource] = []
	for ability in abilities:
		if ability == null or not is_instance_valid(ability):
			continue

		var runtime_ability := ability.duplicate(true) as Resource
		if runtime_ability != null:
			runtime_abilities.append(runtime_ability)

	abilities = runtime_abilities


func _get_ability_id(ability: Resource) -> StringName:
	if ability == null or not is_instance_valid(ability):
		return &""

	var value: Variant = ability.get("ability_id")
	if value is StringName:
		return value
	if value is String:
		return StringName(value)

	return &""


func _get_ability_cooldown(ability: Resource) -> float:
	if ability == null or not is_instance_valid(ability):
		return 0.0

	var value: Variant = ability.get("cooldown")
	if value == null:
		return 0.0

	return maxf(float(value), 0.0)


func _emit_event_bus_ability_used(user, target, ability) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_ability_used"):
		event_bus.call("emit_ability_used", user, target, ability)
