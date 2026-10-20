extends Node

signal object_spawned(pool_id: StringName, object)
signal object_despawned(pool_id: StringName, object)

var pools: Dictionary = {}


func create_pool(pool_id: StringName, scene: PackedScene, initial_size: int = 0) -> void:
	if scene == null:
		return

	pools[pool_id] = {
		"scene": scene,
		"available": [],
		"active": []
	}

	var pool: Dictionary = pools[pool_id]
	var safe_initial_size: int = max(initial_size, 0)
	for index in safe_initial_size:
		var object: Node = scene.instantiate()
		if object == null:
			continue

		add_child(object)
		_deactivate_object(object)
		pool["available"].append(object)


func spawn(pool_id: StringName, parent: Node = null) -> Node:
	if not pools.has(pool_id):
		return null

	var pool: Dictionary = pools[pool_id]
	var object: Node = null

	if not pool["available"].is_empty():
		object = pool["available"].pop_back()
	else:
		var scene: PackedScene = pool["scene"]
		if scene == null:
			return null
		object = scene.instantiate()

	if object == null:
		return null

	var target_parent: Node = parent if parent != null else self
	_reparent_object(object, target_parent)
	_activate_object(object)

	if not pool["active"].has(object):
		pool["active"].append(object)

	object_spawned.emit(pool_id, object)
	return object


func despawn(pool_id: StringName, object: Node) -> void:
	if object == null or not is_instance_valid(object):
		return
	if not pools.has(pool_id):
		return

	var pool: Dictionary = pools[pool_id]
	if not pool["active"].has(object):
		return

	pool["active"].erase(object)
	_deactivate_object(object)
	_reparent_object(object, self)

	if not pool["available"].has(object):
		pool["available"].append(object)

	object_despawned.emit(pool_id, object)


func clear_pool(pool_id: StringName) -> void:
	if not pools.has(pool_id):
		return

	var pool: Dictionary = pools[pool_id]
	for object in pool["active"]:
		_queue_free_object(object)
	for object in pool["available"]:
		_queue_free_object(object)

	pools.erase(pool_id)


func clear_all_pools() -> void:
	for pool_id in pools.keys():
		clear_pool(pool_id)


func has_pool(pool_id: StringName) -> bool:
	return pools.has(pool_id)


func get_pool_size(pool_id: StringName) -> int:
	if not pools.has(pool_id):
		return 0

	var pool: Dictionary = pools[pool_id]
	return pool["available"].size() + pool["active"].size()


func _activate_object(object: Node) -> void:
	if object.has_method("show"):
		object.show()
	if object.has_method("set_process"):
		object.set_process(true)
	if object.has_method("set_physics_process"):
		object.set_physics_process(true)


func _deactivate_object(object: Node) -> void:
	if object.has_method("hide"):
		object.hide()
	if object.has_method("set_process"):
		object.set_process(false)
	if object.has_method("set_physics_process"):
		object.set_physics_process(false)


func _reparent_object(object: Node, parent: Node) -> void:
	if object.get_parent() == parent:
		return
	if object.get_parent() == null:
		parent.add_child(object)
	else:
		object.reparent(parent)


func _queue_free_object(object: Node) -> void:
	if object != null and is_instance_valid(object):
		object.queue_free()
