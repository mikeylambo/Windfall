extends Interactable2D
class_name Chest

signal chest_opened(item_id: StringName, amount: int)

@export var is_opened: bool = false:
	set(val):
		is_opened = val
		is_interactable = not is_opened
		queue_redraw()

@export var reward_item_id: StringName = &"gold_key"
@export var reward_amount: int = 1


func _ready() -> void:
	super._ready()
	is_interactable = not is_opened
	prompt_text = "Open Chest"


func _on_interacted(player: Node2D) -> void:
	if is_opened:
		return
	is_opened = true
	var inv := player.get_node_or_null("InventoryComponent")
	if inv != null and inv.has_method("add_item"):
		inv.call("add_item", reward_item_id, reward_amount)

	chest_opened.emit(reward_item_id, reward_amount)
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.call("play_sfx", "chest_open")


func _draw() -> void:
	super._draw()
	var col := Color(0.65, 0.45, 0.2) if not is_opened else Color(0.45, 0.32, 0.15)
	# Chest body
	draw_rect(Rect2(-16, -16, 32, 24), col)
	draw_rect(Rect2(-16, -16, 32, 24), Color(0.2, 0.15, 0.1), false, 2.0)
	# Lock / rim
	if not is_opened:
		draw_rect(Rect2(-3, -8, 6, 8), Color.GOLD)
	else:
		draw_rect(Rect2(-14, -22, 28, 8), Color(0.55, 0.38, 0.18))
