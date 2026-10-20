extends CharacterBody2D

const RuntimeStatsScript := preload("res://scripts/Resources/RuntimeStats.gd")

signal health_changed(current_health: float, max_health: float)
signal died(unit: Node)

@export var max_health: float = 100.0
@export var move_speed: float = 120.0
@export var team_id: int = 0

var runtime_stats: Resource
var _has_died: bool = false


func _ready() -> void:
	_ensure_runtime_stats()
	_has_died = not is_alive()
	_emit_health_changed()


func is_alive() -> bool:
	if runtime_stats != null and runtime_stats.has_method("is_alive"):
		return bool(runtime_stats.call("is_alive")) and not _has_died

	return not _has_died


func take_damage(amount: float) -> void:
	_ensure_runtime_stats()
	if amount <= 0.0 or not is_alive():
		return

	if runtime_stats.has_method("take_damage"):
		runtime_stats.call("take_damage", amount)

	_emit_health_changed()
	if _get_current_health() <= 0.0:
		die()


func heal(amount: float) -> void:
	_ensure_runtime_stats()
	if amount <= 0.0 or not is_alive():
		return

	if runtime_stats.has_method("heal"):
		runtime_stats.call("heal", amount)

	_emit_health_changed()


func die() -> void:
	if _has_died:
		return

	_has_died = true
	if runtime_stats != null:
		runtime_stats.set("current_health", 0.0)
	velocity = Vector2.ZERO
	_emit_health_changed()
	died.emit(self)


func _ensure_runtime_stats() -> void:
	if runtime_stats != null and is_instance_valid(runtime_stats):
		return

	runtime_stats = RuntimeStatsScript.new()
	runtime_stats.set("max_health", maxf(max_health, 1.0))
	runtime_stats.set("current_health", maxf(max_health, 1.0))
	runtime_stats.set("move_speed", move_speed)
	runtime_stats.set("team_id", team_id)


func _get_current_health() -> float:
	if runtime_stats != null:
		return float(runtime_stats.get("current_health"))
	return 0.0


func _get_max_health() -> float:
	if runtime_stats != null:
		return float(runtime_stats.get("max_health"))
	return maxf(max_health, 1.0)


func _emit_health_changed() -> void:
	health_changed.emit(_get_current_health(), _get_max_health())
