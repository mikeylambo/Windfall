extends Resource

@export var entity_id: StringName
@export var display_name: String
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var move_speed: float = 120.0
@export var team_id: int = 0
@export var shield: float = 0.0
@export var energy: float = 0.0
@export var tags: Array[StringName]


func setup_from_dictionary(data: Dictionary) -> void:
	entity_id = data.get("entity_id", entity_id)
	display_name = data.get("display_name", display_name)
	max_health = float(data.get("max_health", max_health))
	current_health = float(data.get("current_health", max_health))
	move_speed = float(data.get("move_speed", move_speed))
	team_id = int(data.get("team_id", team_id))
	if data.has("tags"):
		tags = data.get("tags", []).duplicate()


func is_alive() -> bool:
	return current_health > 0.0


func take_damage(amount: float) -> float:
	var safe_amount := maxf(amount, 0.0)
	var absorbed_by_shield := minf(shield, safe_amount)
	shield -= absorbed_by_shield

	var health_damage := safe_amount - absorbed_by_shield
	var previous_health := current_health
	current_health = maxf(current_health - health_damage, 0.0)
	return previous_health - current_health


func heal(amount: float) -> float:
	var safe_amount := maxf(amount, 0.0)
	var previous_health := current_health
	current_health = minf(current_health + safe_amount, max_health)
	return current_health - previous_health


func add_shield(amount: float) -> void:
	shield += maxf(amount, 0.0)
