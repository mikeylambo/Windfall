extends Resource

@export var entity_id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var max_health: float = 100.0
@export var move_speed: float = 120.0
@export var team_id: int = 0
@export var abilities: Array[Resource]
@export var tags: Array[StringName]


func create_runtime_stats() -> Dictionary:
	return {
		"entity_id": entity_id,
		"display_name": display_name,
		"max_health": max_health,
		"current_health": max_health,
		"move_speed": move_speed,
		"team_id": team_id,
		"tags": tags.duplicate()
	}
