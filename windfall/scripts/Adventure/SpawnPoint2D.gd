extends Marker2D
class_name SpawnPoint2D

@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group("spawn_points")
