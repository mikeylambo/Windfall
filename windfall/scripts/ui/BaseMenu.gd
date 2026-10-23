extends Control

signal menu_opened(menu)
signal menu_closed(menu)

@export var default_focus_path: NodePath
@export var close_on_cancel: bool = true


func open_menu() -> void:
	show()
	focus_default()
	menu_opened.emit(self)


func close_menu() -> void:
	hide()
	menu_closed.emit(self)


func focus_default() -> void:
	if default_focus_path.is_empty():
		return

	var focus_target: Node = get_node_or_null(default_focus_path)
	if focus_target is Control:
		var focus_control: Control = focus_target
		if focus_control.is_visible_in_tree():
			focus_control.grab_focus()


func handle_cancel() -> void:
	close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if close_on_cancel and event.is_action_pressed("ui_cancel"):
		handle_cancel()
		accept_event()
