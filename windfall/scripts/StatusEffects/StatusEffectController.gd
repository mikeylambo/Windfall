extends Node

signal effect_added(effect: Resource)
signal effect_removed(effect: Resource)
signal effect_expired(effect: Resource)

@export var auto_process: bool = true

var active_effects: Array = []


func _process(delta: float) -> void:
	if not auto_process:
		return

	for index in range(active_effects.size() - 1, -1, -1):
		var effect: Resource = active_effects[index]
		if effect == null or not is_instance_valid(effect):
			active_effects.remove_at(index)
			continue

		if effect.has_method("tick"):
			effect.call("tick", _get_effect_target(), delta)

		if effect.has_method("is_expired") and bool(effect.call("is_expired")):
			active_effects.remove_at(index)
			effect_expired.emit(effect)
			effect_removed.emit(effect)


func add_effect(effect: Resource) -> void:
	if effect == null or not is_instance_valid(effect):
		return

	var effect_id := _get_effect_id(effect)
	var existing_effect := get_effect(effect_id)
	if existing_effect != null:
		if existing_effect.has_method("can_stack") and bool(existing_effect.call("can_stack")):
			existing_effect.call("add_stack", 1)
			if existing_effect.has_method("apply"):
				existing_effect.call("apply", _get_effect_target())
		return

	var effect_instance := effect.duplicate(true) as Resource
	if effect_instance == null:
		return

	if effect_instance.has_method("apply"):
		effect_instance.call("apply", _get_effect_target())

	active_effects.append(effect_instance)
	effect_added.emit(effect_instance)


func remove_effect(effect_id: StringName) -> void:
	for index in range(active_effects.size() - 1, -1, -1):
		var effect: Resource = active_effects[index]
		if effect == null or not is_instance_valid(effect):
			active_effects.remove_at(index)
			continue

		if _get_effect_id(effect) == effect_id:
			active_effects.remove_at(index)
			if effect.has_method("remove"):
				effect.call("remove", _get_effect_target())
			effect_removed.emit(effect)


func has_effect(effect_id: StringName) -> bool:
	return get_effect(effect_id) != null


func get_effect(effect_id: StringName) -> Resource:
	for effect in active_effects:
		if effect == null or not is_instance_valid(effect):
			continue

		if _get_effect_id(effect) == effect_id:
			return effect

	return null


func clear_effects() -> void:
	for index in range(active_effects.size() - 1, -1, -1):
		var effect: Resource = active_effects[index]
		active_effects.remove_at(index)
		if effect != null and is_instance_valid(effect):
			if effect.has_method("remove"):
				effect.call("remove", _get_effect_target())
			effect_removed.emit(effect)


func _get_effect_id(effect: Resource) -> StringName:
	if effect == null or not is_instance_valid(effect):
		return &""

	var value = effect.get("effect_id")
	if value is StringName:
		return value
	if value is String:
		return StringName(value)

	return &""


func _get_effect_target() -> Object:
	var parent := get_parent()
	if parent != null and is_instance_valid(parent):
		return parent

	if owner != null and is_instance_valid(owner):
		return owner

	return self
