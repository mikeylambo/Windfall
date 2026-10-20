extends Node

## SaveableComponent convention:
## Attach this component as a child of any node that should participate in saving.
## The parent node is added to the "saveable" group automatically when possible.
## Future save registries can collect nodes in the "saveable" group and call:
## - get_save_data() -> Dictionary
## - load_save_data(data: Dictionary) -> void

signal save_data_requested(data: Dictionary)
signal load_data_received(data: Dictionary)

@export var save_id: StringName
@export var include_position: bool = true
@export var include_rotation: bool = false
@export var include_scale: bool = false
@export var include_groups: bool = false
@export var include_inventory: bool = true
@export var include_team: bool = true
@export var include_abilities: bool = true


func _ready() -> void:
	var target := _get_target_node()
	if target != null:
		target.add_to_group("saveable")
		if save_id == &"":
			save_id = StringName("%s_%s" % [target.name, str(target.get_instance_id())])
	elif save_id == &"":
		save_id = StringName("Saveable_%s" % str(get_instance_id()))


func get_save_id() -> StringName:
	return save_id


func get_save_data() -> Dictionary:
	var target := _get_target_node()
	var data := {
		"save_id": save_id
	}

	if target != null:
		if not target.scene_file_path.is_empty():
			data["scene_path"] = target.scene_file_path
		data["node_path"] = str(target.get_path())

		if include_position:
			var position_data: Variant = _get_position_data(target)
			if position_data != null:
				data["position"] = position_data

		if include_rotation:
			var rotation_data: Variant = _get_rotation_data(target)
			if rotation_data != null:
				data["rotation"] = rotation_data

		if include_scale:
			var scale_data: Variant = _get_scale_data(target)
			if scale_data != null:
				data["scale"] = scale_data

		if include_groups:
			data["groups"] = target.get_groups()

	var stats_component := _get_stats_component(target)
	if stats_component != null:
		var runtime_stats := _get_runtime_stats(stats_component)
		if runtime_stats != null:
			data["runtime_stats"] = _get_runtime_stats_data(runtime_stats)

	if include_inventory:
		var inventory_data := _get_inventory_save_data()
		if not inventory_data.is_empty():
			data["inventory"] = inventory_data

	if include_team:
		var team_data := _get_team_save_data()
		if not team_data.is_empty():
			data["team"] = team_data

	if include_abilities:
		var ability_data := _get_ability_save_data()
		if not ability_data.is_empty():
			data["abilities"] = ability_data

	save_data_requested.emit(data)
	return data


func load_save_data(data: Dictionary) -> void:
	var target := _get_target_node()
	if target != null:
		if data.has("position"):
			_apply_position_data(target, data["position"])
		if data.has("rotation"):
			_apply_rotation_data(target, data["rotation"])
		if data.has("scale"):
			_apply_scale_data(target, data["scale"])

		var stats_component := _get_stats_component(target)
		if stats_component != null and data.has("runtime_stats") and data["runtime_stats"] is Dictionary:
			_restore_runtime_stats(stats_component, data["runtime_stats"])

	if include_inventory and data.has("inventory") and data["inventory"] is Dictionary:
		_load_inventory_save_data(data["inventory"])

	if include_team and data.has("team") and data["team"] is Dictionary:
		_load_team_save_data(data["team"])

	if include_abilities and data.has("abilities") and data["abilities"] is Dictionary:
		_load_ability_save_data(data["abilities"])

	load_data_received.emit(data)


func _get_target_node() -> Node:
	var parent := get_parent()
	if parent != null and is_instance_valid(parent):
		return parent

	if owner != null and is_instance_valid(owner):
		return owner

	return null


func _get_position_data(target: Node) -> Variant:
	if target is Node2D:
		var node_2d := target as Node2D
		return {"x": node_2d.position.x, "y": node_2d.position.y}
	if target is Node3D:
		var node_3d := target as Node3D
		return {"x": node_3d.position.x, "y": node_3d.position.y, "z": node_3d.position.z}
	return null


func _get_rotation_data(target: Node) -> Variant:
	if target is Node2D:
		return (target as Node2D).rotation
	if target is Node3D:
		var node_3d := target as Node3D
		return {"x": node_3d.rotation.x, "y": node_3d.rotation.y, "z": node_3d.rotation.z}
	return null


func _get_scale_data(target: Node) -> Variant:
	if target is Node2D:
		var node_2d := target as Node2D
		return {"x": node_2d.scale.x, "y": node_2d.scale.y}
	if target is Node3D:
		var node_3d := target as Node3D
		return {"x": node_3d.scale.x, "y": node_3d.scale.y, "z": node_3d.scale.z}
	return null


func _apply_position_data(target: Node, value: Variant) -> void:
	if not value is Dictionary:
		return
	var data := value as Dictionary
	if target is Node2D:
		(target as Node2D).position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	elif target is Node3D:
		(target as Node3D).position = Vector3(float(data.get("x", 0.0)), float(data.get("y", 0.0)), float(data.get("z", 0.0)))


func _apply_rotation_data(target: Node, value: Variant) -> void:
	if target is Node2D:
		(target as Node2D).rotation = float(value)
	elif target is Node3D and value is Dictionary:
		var data := value as Dictionary
		(target as Node3D).rotation = Vector3(float(data.get("x", 0.0)), float(data.get("y", 0.0)), float(data.get("z", 0.0)))


func _apply_scale_data(target: Node, value: Variant) -> void:
	if not value is Dictionary:
		return
	var data := value as Dictionary
	if target is Node2D:
		(target as Node2D).scale = Vector2(float(data.get("x", 1.0)), float(data.get("y", 1.0)))
	elif target is Node3D:
		(target as Node3D).scale = Vector3(float(data.get("x", 1.0)), float(data.get("y", 1.0)), float(data.get("z", 1.0)))


func _get_stats_component(target: Node) -> Node:
	if target == null:
		return null
	return target.get_node_or_null("StatsComponent")


func _get_child_component(component_name: String) -> Node:
	var target := _get_target_node()
	if target == null:
		return null
	return target.get_node_or_null(component_name)


func _get_inventory_save_data() -> Dictionary:
	var inventory_component := _get_child_component("InventoryComponent")
	if inventory_component != null and inventory_component.has_method("get_save_data"):
		var data: Variant = inventory_component.call("get_save_data")
		if data is Dictionary:
			return data
	return {}


func _get_team_save_data() -> Dictionary:
	var team_component := _get_child_component("TeamComponent")
	if team_component == null:
		return {}

	return {
		"team_id": team_component.get("team_id"),
		"faction_id": team_component.get("faction_id"),
		"can_target_self": team_component.get("can_target_self"),
		"can_target_allies": team_component.get("can_target_allies"),
		"can_target_enemies": team_component.get("can_target_enemies")
	}


func _get_ability_save_data() -> Dictionary:
	var ability_controller := _get_child_component("AbilityController")
	if ability_controller != null and ability_controller.has_method("get_save_data"):
		var data: Variant = ability_controller.call("get_save_data")
		if data is Dictionary:
			return data
	return {}


func _load_inventory_save_data(data: Dictionary) -> void:
	var inventory_component := _get_child_component("InventoryComponent")
	if inventory_component != null and inventory_component.has_method("load_save_data"):
		inventory_component.call("load_save_data", data)


func _load_team_save_data(data: Dictionary) -> void:
	var team_component := _get_child_component("TeamComponent")
	if team_component == null:
		return

	var fields := ["team_id", "faction_id", "can_target_self", "can_target_allies", "can_target_enemies"]
	for field in fields:
		if data.has(field):
			team_component.set(field, data[field])


func _load_ability_save_data(data: Dictionary) -> void:
	var ability_controller := _get_child_component("AbilityController")
	if ability_controller != null and ability_controller.has_method("load_save_data"):
		ability_controller.call("load_save_data", data)


func _get_runtime_stats(stats_component: Node) -> Resource:
	if stats_component.has_method("get_runtime_stats"):
		var stats: Variant = stats_component.call("get_runtime_stats")
		if stats is Resource:
			return stats
	return null


func _get_runtime_stats_data(runtime_stats: Resource) -> Dictionary:
	return {
		"current_health": runtime_stats.get("current_health"),
		"max_health": runtime_stats.get("max_health"),
		"shield": runtime_stats.get("shield"),
		"energy": runtime_stats.get("energy"),
		"team_id": runtime_stats.get("team_id")
	}


func _restore_runtime_stats(stats_component: Node, data: Dictionary) -> void:
	var runtime_stats := _get_runtime_stats(stats_component)
	if runtime_stats == null:
		return

	var keys := ["current_health", "max_health", "shield", "energy", "team_id"]
	for key in keys:
		if data.has(key):
			runtime_stats.set(key, data[key])
