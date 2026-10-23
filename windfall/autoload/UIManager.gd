extends Node

signal menu_pushed(menu)
signal menu_popped(menu)
signal menu_stack_cleared

var menu_stack: Array = []


func push_menu(menu: Control) -> void:
	if menu == null or not is_instance_valid(menu):
		return

	var current_menu: Control = get_top_menu()
	if current_menu != null:
		_hide_menu(current_menu)

	if menu_stack.has(menu):
		menu_stack.erase(menu)
	menu_stack.append(menu)
	_open_menu(menu)
	menu_pushed.emit(menu)


func pop_menu() -> Control:
	if menu_stack.is_empty():
		return null

	var popped_menu: Control = menu_stack.pop_back()
	_close_menu(popped_menu)
	menu_popped.emit(popped_menu)

	var previous_menu: Control = get_top_menu()
	if previous_menu != null:
		_open_menu(previous_menu)

	return popped_menu


func clear_menus() -> void:
	if menu_stack.is_empty():
		return

	while not menu_stack.is_empty():
		var menu: Control = menu_stack.pop_back()
		_close_menu(menu)

	menu_stack_cleared.emit()


func get_top_menu() -> Control:
	if menu_stack.is_empty():
		return null

	var menu: Control = menu_stack[menu_stack.size() - 1]
	if menu == null or not is_instance_valid(menu):
		menu_stack.pop_back()
		return get_top_menu()

	return menu


func has_open_menu() -> bool:
	return get_top_menu() != null


func _open_menu(menu: Control) -> void:
	if menu == null or not is_instance_valid(menu):
		return
	if menu.has_method("open_menu"):
		menu.open_menu()
	else:
		menu.show()


func _close_menu(menu: Control) -> void:
	if menu == null or not is_instance_valid(menu):
		return
	if menu.has_method("close_menu"):
		menu.close_menu()
	else:
		menu.hide()


func _hide_menu(menu: Control) -> void:
	if menu == null or not is_instance_valid(menu):
		return
	menu.hide()
