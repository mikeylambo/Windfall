extends Node
class_name StatsComponent

const RuntimeStatsScript := preload("res://scripts/Resources/RuntimeStats.gd")
const EntityDataScript := preload("res://scripts/Resources/EntityData.gd")

signal health_changed(current_health: float, max_health: float)
signal shield_changed(shield: float)
signal energy_changed(energy: float)
signal died(owner_node)

@export var entity_data: Resource:
	set(val):
		entity_data = val
		if is_node_ready():
			setup_from_entity_data(val)

@export var max_health: float = 100.0:
	set(val):
		max_health = maxf(val, 1.0)
		if runtime_stats != null:
			runtime_stats.set("max_health", max_health)
			health_changed.emit(_get_current_health(), max_health)

@export var current_health: float = 100.0:
	set(val):
		current_health = clampf(val, 0.0, max_health)
		if runtime_stats != null:
			runtime_stats.set("current_health", current_health)
			health_changed.emit(current_health, max_health)
		if current_health <= 0.0 and not _has_died:
			_has_died = true
			died.emit(_get_owner_node())
		elif current_health > 0.0:
			_has_died = false

@export var move_speed: float = 120.0:
	set(val):
		move_speed = val
		if runtime_stats != null:
			runtime_stats.set("move_speed", move_speed)

@export var team_id: int = 0:
	set(val):
		team_id = val
		if runtime_stats != null:
			runtime_stats.set("team_id", team_id)

@export var shield: float = 0.0:
	set(val):
		shield = maxf(val, 0.0)
		if runtime_stats != null:
			runtime_stats.set("shield", shield)
			shield_changed.emit(shield)

@export var energy: float = 0.0:
	set(val):
		energy = val
		if runtime_stats != null:
			runtime_stats.set("energy", energy)
			energy_changed.emit(energy)

var runtime_stats: Resource
var _has_died: bool = false


func _ready() -> void:
	_create_runtime_stats()
	if entity_data != null and entity_data.has_method("create_runtime_stats"):
		_setup_from_dictionary(entity_data.call("create_runtime_stats"))
	else:
		_setup_from_exported_values()

	_emit_all_changed()


func reset_stats() -> void:
	_has_died = false
	if entity_data != null and entity_data.has_method("create_runtime_stats"):
		_setup_from_dictionary(entity_data.call("create_runtime_stats"))
	else:
		_setup_from_exported_values()
	_emit_all_changed()


func setup_from_entity_data(data: Resource) -> void:
	entity_data = data
	_create_runtime_stats()
	if entity_data != null and entity_data.has_method("create_runtime_stats"):
		_setup_from_dictionary(entity_data.call("create_runtime_stats"))
	else:
		_setup_from_exported_values()

	_has_died = not is_alive()
	_emit_all_changed()


func is_alive() -> bool:
	if runtime_stats != null and runtime_stats.has_method("is_alive"):
		return bool(runtime_stats.call("is_alive")) and not _has_died

	return false


func take_damage(amount: float) -> float:
	_ensure_runtime_stats()
	if amount <= 0.0 or not is_alive():
		return 0.0

	var health_damage := 0.0
	if runtime_stats.has_method("take_damage"):
		health_damage = float(runtime_stats.call("take_damage", amount))

	health_changed.emit(_get_current_health(), _get_max_health())
	shield_changed.emit(_get_shield())

	if _get_current_health() <= 0.0 and not _has_died:
		_has_died = true
		died.emit(_get_owner_node())

	return health_damage


func heal(amount: float) -> float:
	_ensure_runtime_stats()
	if amount <= 0.0 or not is_alive():
		return 0.0

	var healing_done := 0.0
	if runtime_stats.has_method("heal"):
		healing_done = float(runtime_stats.call("heal", amount))

	health_changed.emit(_get_current_health(), _get_max_health())
	return healing_done


func add_shield(amount: float) -> void:
	_ensure_runtime_stats()
	if runtime_stats.has_method("add_shield"):
		runtime_stats.call("add_shield", amount)
	else:
		runtime_stats.set("shield", _get_shield() + maxf(amount, 0.0))

	shield_changed.emit(_get_shield())


func set_energy(value: float) -> void:
	_ensure_runtime_stats()
	runtime_stats.set("energy", value)
	energy_changed.emit(_get_energy())


func get_move_speed() -> float:
	_ensure_runtime_stats()
	return float(runtime_stats.get("move_speed"))


func get_team_id() -> int:
	_ensure_runtime_stats()
	return int(runtime_stats.get("team_id"))


func get_runtime_stats() -> Resource:
	_ensure_runtime_stats()
	return runtime_stats


func _create_runtime_stats() -> void:
	runtime_stats = RuntimeStatsScript.new()
	_has_died = false


func _ensure_runtime_stats() -> void:
	if runtime_stats == null or not is_instance_valid(runtime_stats):
		_create_runtime_stats()
		_setup_from_exported_values()


func _setup_from_dictionary(data: Dictionary) -> void:
	if runtime_stats == null:
		_create_runtime_stats()

	if runtime_stats.has_method("setup_from_dictionary"):
		runtime_stats.call("setup_from_dictionary", data)
	else:
		for key in data.keys():
			runtime_stats.set(str(key), data[key])

	if not data.has("shield"):
		runtime_stats.set("shield", shield)
	if not data.has("energy"):
		runtime_stats.set("energy", energy)


func _setup_from_exported_values() -> void:
	if runtime_stats == null:
		_create_runtime_stats()

	runtime_stats.set("max_health", maxf(max_health, 1.0))
	runtime_stats.set("current_health", clampf(current_health, 0.0, maxf(max_health, 1.0)))
	runtime_stats.set("move_speed", move_speed)
	runtime_stats.set("team_id", team_id)
	runtime_stats.set("shield", maxf(shield, 0.0))
	runtime_stats.set("energy", energy)


func _emit_all_changed() -> void:
	health_changed.emit(_get_current_health(), _get_max_health())
	shield_changed.emit(_get_shield())
	energy_changed.emit(_get_energy())


func _get_current_health() -> float:
	_ensure_runtime_stats()
	return float(runtime_stats.get("current_health"))


func _get_max_health() -> float:
	_ensure_runtime_stats()
	return float(runtime_stats.get("max_health"))


func _get_shield() -> float:
	_ensure_runtime_stats()
	return float(runtime_stats.get("shield"))


func _get_energy() -> float:
	_ensure_runtime_stats()
	return float(runtime_stats.get("energy"))


func _get_owner_node():
	var parent := get_parent()
	if parent != null and is_instance_valid(parent):
		return parent

	if owner != null and is_instance_valid(owner):
		return owner

	return self
