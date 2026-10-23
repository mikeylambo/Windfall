extends Control
class_name WMenu

## Base for modal menus: dimmed backdrop, centred wood panel, header with icon,
## and a footer of key hints. Subclasses fill `body` and call focus_first().

var hud: Node
var panel: PanelContainer
var body: VBoxContainer
var _title: Label
var _first_focus: Control


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.08, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = UIKit.panel(_panel_variation())
	center.add_child(panel)
	var v := UIKit.vbox(10)
	panel.add_child(v)
	var head := UIKit.hbox(10)
	head.add_child(UIKit.icon(_icon(), 42))
	_title = UIKit.header(_title_text(), 26)
	head.add_child(_title)
	head.add_child(UIKit.spacer(0, 0, true))
	var esc := UIKit.hbox(6)
	esc.add_child(UIKit.keycap("Esc"))
	esc.add_child(UIKit.label("Close", 14, UITheme.CREAM_DIM))
	head.add_child(esc)
	v.add_child(head)
	body = UIKit.vbox(8)
	v.add_child(body)


func _ready() -> void:
	pivot_offset = get_viewport_rect().size * 0.5
	build()
	call_deferred("focus_first")


func _panel_variation() -> String:
	return ""


func _icon() -> String:
	return "icons/satchel"


func _title_text() -> String:
	return ""


func build() -> void:
	pass


func refresh() -> void:
	pass


func set_first_focus(c: Control) -> void:
	_first_focus = c


func focus_first() -> void:
	if _first_focus and is_instance_valid(_first_focus) and _first_focus.is_visible_in_tree():
		_first_focus.grab_focus()


func close() -> void:
	if hud:
		hud.call("close_menu")


## Wire 4-way focus neighbours for a grid of controls.
static func link_grid(items: Array, cols: int) -> void:
	for i in items.size():
		var c: Control = items[i]
		if i % cols > 0: c.focus_neighbor_left = c.get_path_to(items[i - 1])
		if i % cols < cols - 1 and i + 1 < items.size(): c.focus_neighbor_right = c.get_path_to(items[i + 1])
		if i - cols >= 0: c.focus_neighbor_top = c.get_path_to(items[i - cols])
		if i + cols < items.size(): c.focus_neighbor_bottom = c.get_path_to(items[i + cols])
