extends RefCounted
class_name UITheme

## Builds the single shared WINDFALL Theme from the baked UI textures.
## tools/bake_art.gd saves it to res://assets/ui/windfall_theme.tres, which is
## set as the project-wide custom theme so every Control uses it.

const FONT_PATH := "res://assets/fonts/PixelifySans-Regular.woff2"
const FONT_BOLD_PATH := "res://assets/fonts/PixelifySans-Bold.woff2"
const FONT_TITLE_PATH := "res://assets/fonts/Silkscreen-Regular.woff2"

const CREAM := Color("fff2d6")
const CREAM_DIM := Color("cdb48c")
const GOLD := Color("f2c94e")
const OUTLINE := Color("2a1d27")


static func _tex(p: String) -> Texture2D:
	return load("res://assets/art/" + p + ".png")


static func box(p: String, margin: int, content: int = -1) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = _tex(p)
	s.texture_margin_left = margin
	s.texture_margin_top = margin
	s.texture_margin_right = margin
	s.texture_margin_bottom = margin
	var c := content if content >= 0 else margin
	s.content_margin_left = c
	s.content_margin_top = c
	s.content_margin_right = c
	s.content_margin_bottom = c
	return s


static func build() -> Theme:
	var t := Theme.new()
	var font: FontFile = load(FONT_PATH)
	t.default_font = font
	t.default_font_size = 20

	# panels: 3x baked, 7-texel margins on the wood frame
	var wood := box("ui/panel_wood", 21, 24)
	t.set_stylebox("panel", "PanelContainer", wood)
	t.set_stylebox("panel", "Panel", wood)
	t.set_stylebox("panel", "PopupPanel", wood)
	t.set_stylebox("panel", "TooltipPanel", box("ui/panel_dark", 12, 10))

	t.set_type_variation("VinePanel", "PanelContainer")
	t.set_stylebox("panel", "VinePanel", box("ui/panel_vine", 21, 24))
	t.set_type_variation("PaperPanel", "PanelContainer")
	t.set_stylebox("panel", "PaperPanel", box("ui/panel_paper", 12, 10))
	t.set_type_variation("DarkPanel", "PanelContainer")
	t.set_stylebox("panel", "DarkPanel", box("ui/panel_dark", 12, 8))

	# buttons: 0 normal, 1 hover/focus, 2 pressed, 3 disabled
	var b := ["normal", "hover", "pressed", "disabled"]
	for i in 4:
		var sb := box("ui/button_%d" % i, 12, 10)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		t.set_stylebox(b[i], "Button", sb)
	t.set_stylebox("focus", "Button", box("ui/button_1", 12, 10))
	t.set_stylebox("hover_pressed", "Button", box("ui/button_2", 12, 10))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", OUTLINE)
	t.set_color("font_focus_color", "Button", OUTLINE)
	t.set_color("font_pressed_color", "Button", CREAM)
	t.set_color("font_disabled_color", "Button", Color("3d3f4e"))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 0)
	t.set_constant("h_separation", "Button", 8)

	# slot buttons (icon grids)
	t.set_type_variation("SlotButton", "Button")
	for i in 3:
		var names: Array = [["normal", "disabled"], ["hover", "focus", "hover_pressed"], ["pressed"]][i]
		for n in names:
			var sb := box("ui/slot_%d" % (i if i < 2 else 1), 15, 6)
			t.set_stylebox(n, "SlotButton", sb)

	# labels
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_constant("outline_size", "Label", 4)
	t.set_color("font_color", "RichTextLabel", CREAM)
	t.set_color("default_color", "RichTextLabel", CREAM)
	t.set_color("font_outline_color", "RichTextLabel", OUTLINE)
	t.set_constant("outline_size", "RichTextLabel", 4)
	t.set_font("bold_font", "RichTextLabel", load(FONT_BOLD_PATH))
	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", load(FONT_TITLE_PATH))
	t.set_font_size("font_size", "HeaderLabel", 24)
	t.set_color("font_color", "HeaderLabel", GOLD)
	t.set_constant("outline_size", "HeaderLabel", 6)
	t.set_type_variation("DimLabel", "Label")
	t.set_color("font_color", "DimLabel", CREAM_DIM)
	t.set_font_size("font_size", "DimLabel", 14)
	t.set_type_variation("InkLabel", "Label")
	t.set_color("font_color", "InkLabel", OUTLINE)
	t.set_constant("outline_size", "InkLabel", 0)

	# tooltip text
	t.set_color("font_color", "TooltipLabel", CREAM)
	t.set_font_size("font_size", "TooltipLabel", 14)

	# sliders
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color("1e1418")
	groove.border_color = OUTLINE
	groove.set_border_width_all(3)
	groove.content_margin_top = 6
	groove.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", groove)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _tex("ui/keycap"))
	t.set_icon("grabber_highlight", "HSlider", _tex("ui/keycap"))
	var fsl := StyleBoxFlat.new()
	fsl.bg_color = Color(0, 0, 0, 0)
	fsl.border_color = GOLD
	fsl.set_border_width_all(3)
	t.set_stylebox("focus", "HSlider", fsl)

	# scrollbars
	var sbar := StyleBoxFlat.new()
	sbar.bg_color = Color("1e1418")
	sbar.content_margin_left = 4
	sbar.content_margin_right = 4
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("b57d4e")
	t.set_stylebox("scroll", "VScrollBar", sbar)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)

	# tab bar
	t.set_stylebox("tab_selected", "TabBar", box("ui/button_1", 12, 8))
	t.set_stylebox("tab_unselected", "TabBar", box("ui/button_0", 12, 8))
	t.set_stylebox("tab_hovered", "TabBar", box("ui/button_1", 12, 8))
	t.set_stylebox("tab_focus", "TabBar", fsl)
	t.set_color("font_selected_color", "TabBar", OUTLINE)
	t.set_color("font_unselected_color", "TabBar", CREAM)
	t.set_color("font_hovered_color", "TabBar", OUTLINE)
	return t
