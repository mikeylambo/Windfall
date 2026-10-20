extends Node

signal team_changed(old_team_id: int, new_team_id: int)
signal faction_changed(old_faction_id: StringName, new_faction_id: StringName)

@export var team_id: int = 0
@export var faction_id: StringName = &"neutral"
@export var can_target_self: bool = false
@export var can_target_allies: bool = true
@export var can_target_enemies: bool = true


func set_team_id(new_team_id: int) -> void:
	if team_id == new_team_id:
		return

	var old_team_id := team_id
	team_id = new_team_id
	team_changed.emit(old_team_id, team_id)


func set_faction_id(new_faction_id: StringName) -> void:
	if faction_id == new_faction_id:
		return

	var old_faction_id := faction_id
	faction_id = new_faction_id
	faction_changed.emit(old_faction_id, faction_id)


func is_same_team(other) -> bool:
	var other_team_id: Variant = _get_other_team_id(other)
	if other_team_id == null:
		return false

	return int(other_team_id) == team_id


func is_enemy(other) -> bool:
	if other == null or not is_instance_valid(other):
		return false

	var other_team_id: Variant = _get_other_team_id(other)
	if other_team_id == null:
		return false

	return int(other_team_id) != team_id


func can_target(other) -> bool:
	if other == null or not is_instance_valid(other):
		return false

	if _is_self_target(other):
		return can_target_self

	if is_same_team(other):
		return can_target_allies

	if is_enemy(other):
		return can_target_enemies

	return false


func get_team_id() -> int:
	return team_id


func get_faction_id() -> StringName:
	return faction_id


func _get_other_team_id(other):
	if other == null or not is_instance_valid(other):
		return null

	if other.has_method("get_team_id"):
		return other.call("get_team_id")

	if other is Node:
		var team_component := (other as Node).get_node_or_null("TeamComponent")
		if team_component != null:
			if team_component.has_method("get_team_id"):
				return team_component.call("get_team_id")
			var component_team_id = team_component.get("team_id")
			if component_team_id != null:
				return component_team_id

	var property_team_id = other.get("team_id")
	if property_team_id != null:
		return property_team_id

	return null


func _is_self_target(other) -> bool:
	if other == self:
		return true

	var parent := get_parent()
	return parent != null and is_instance_valid(parent) and other == parent
