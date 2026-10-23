extends Control

@export var credits: Array[String] = [
	"Created with Godot Game OS",
	"Design, Art, Audio, Engineering"
]

@onready var credits_list: VBoxContainer = $CreditsList
@onready var back_button: Button = $BackButton


func _ready() -> void:
	if back_button != null and not back_button.pressed.is_connected(go_back):
		back_button.pressed.connect(go_back)
	populate_credits()


func populate_credits() -> void:
	if credits_list == null:
		return
	for child in credits_list.get_children():
		child.queue_free()
	for credit in credits:
		var label := Label.new()
		label.text = credit
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		credits_list.add_child(label)


func set_credits(new_credits: Array[String]) -> void:
	credits = new_credits.duplicate()
	populate_credits()


func go_back() -> void:
	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("go_to_main_menu"):
		scene_loader.call("go_to_main_menu")
		return
	hide()
