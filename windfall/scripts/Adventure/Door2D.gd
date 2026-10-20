extends Area2D
class_name Door2D

signal entered_door(target_scene: String, target_spawn: String)

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_id: String = "default"


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is AdventurePlayer2D or body.is_in_group("player")):
		return
	if target_scene_path.is_empty():
		return

	entered_door.emit(target_scene_path, target_spawn_id)
	var sl := get_node_or_null("/root/SceneLoader")
	if sl != null and sl.has_method("change_scene"):
		sl.call("change_scene", target_scene_path)
	else:
		get_tree().change_scene_to_file(target_scene_path)
