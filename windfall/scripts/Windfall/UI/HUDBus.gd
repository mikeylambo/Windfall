extends RefCounted
class_name HUDBus

## Static helpers so world objects can talk to the HUD without node paths.


static func _hud() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("hud") if tree else null


static func toast(text: String, color: Color = Color.WHITE) -> void:
	var h := _hud()
	if h: h.call("toast", text, color)


static func open_menu(menu: String) -> void:
	var h := _hud()
	if h: h.call("open_menu", menu)


static func sleep_transition(on_black: Callable) -> void:
	var h := _hud()
	if h:
		h.call("sleep_transition", on_black)
	else:
		on_black.call()


static func say(speaker: String, lines: Array, on_done: Callable = Callable()) -> void:
	var h := _hud()
	if h: h.call("say", speaker, lines, on_done)


static func ask(speaker: String, lines: Array, choices: Array, on_choice: Callable) -> void:
	var h := _hud()
	if h: h.call("ask", speaker, lines, choices, on_choice)


static func open_gift(villager: Node) -> void:
	var h := _hud()
	if h: h.call("open_gift", villager)
