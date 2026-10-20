extends Area2D
class_name Interactable2D

signal interacted(player: Node2D)
signal focused
signal unfocused

@export var prompt_text: String = "Interact"
@export var is_interactable: bool = true

var _is_focused: bool = false


func _ready() -> void:
	add_to_group("interactables")
	monitoring = true
	monitorable = true


func set_focused(val: bool) -> void:
	if _is_focused == val:
		return
	_is_focused = val
	if _is_focused:
		focused.emit()
	else:
		unfocused.emit()
	queue_redraw()


func interact(player: Node2D) -> void:
	if not is_interactable:
		return
	interacted.emit(player)
	_on_interacted(player)


func _on_interacted(_player: Node2D) -> void:
	pass


func _draw() -> void:
	if _is_focused and is_interactable:
		# Draw a small prompt indicator
		draw_rect(Rect2(-24, -36, 48, 18), Color(0.1, 0.1, 0.1, 0.8))
		draw_rect(Rect2(-24, -36, 48, 18), Color(0.9, 0.9, 0.9, 0.8), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-16, -22), "[E]", HORIZONTAL_ALIGNMENT_CENTER, 32, 12, Color.YELLOW)
