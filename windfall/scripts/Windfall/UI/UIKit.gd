extends RefCounted
class_name UIKit

## Tiny builder helpers so every WINDFALL menu is assembled the same way.

const BOLD := preload("res://assets/fonts/PixelifySans-Bold.woff2")
const TITLE := preload("res://assets/fonts/Silkscreen-Regular.woff2")

const TOOL_NAMES := ["Pruning Shears", "Scythe", "Hoe-Staff", "Seed Sling", "Watering Can"]
const TOOL_DESC := ["Fast twin snips. Prunes trees for better fruit.", "Wide sweeping arc.", "Heavy ground slam with shockwave.", "Ranged seed pellets.", "Waters plots; soaks enemies (Wet)."]
const FAMILY_NAMES := ["Storm", "Ember", "Frost", "Tide", "Verdant", "Gale", "Umbra", "Lumen"]
const SKILL_TYPES := ["Strike", "Burst", "Motion", "Ward", "Sprout", "Aura"]
const SOIL_NAMES := ["Loam", "Ash", "Rime", "Silt", "Stormglass", "Ley"]


static func label(text: String, size: int = 16, color: Color = UITheme.CREAM, variation: String = "") -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	l.add_theme_font_size_override("font_size", size)
	if color != UITheme.CREAM:
		l.add_theme_color_override("font_color", color)
	return l


static func bold(text: String, size: int = 16, color: Color = UITheme.CREAM) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", BOLD)
	return l


static func header(text: String, size: int = 24, color: Color = UITheme.GOLD) -> Label:
	var l := label(text, size, color, "HeaderLabel")
	l.add_theme_font_size_override("font_size", size)
	return l


static func icon(path: String, px: int = 48, tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Art.tex(path)
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func panel(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


static func hbox(sep: int = 8) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func vbox(sep: int = 6) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func button(text: String, cb: Callable = Callable(), icon_path: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	if icon_path != "":
		b.icon = Art.tex(icon_path)
		b.expand_icon = false
	if cb.is_valid():
		b.pressed.connect(cb)
	b.pressed.connect(WindfallSound.play_ui_confirm)
	b.focus_entered.connect(WindfallSound.play_ui_move)
	return b


static func slot_button(icon_path: String, tip: String = "", size: int = 60) -> Button:
	var b := Button.new()
	b.theme_type_variation = "SlotButton"
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = tip
	if icon_path != "":
		var ic := icon(icon_path, size - 18)
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 9
		ic.offset_top = 9
		ic.offset_right = -9
		ic.offset_bottom = -9
		b.add_child(ic)
	b.focus_entered.connect(WindfallSound.play_ui_move)
	return b


static func keycap(key: String, size: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UITheme.box("ui/keycap", 9, 4)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 1
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	var l := label(key, size, UITheme.OUTLINE, "InkLabel")
	l.add_theme_font_override("font", BOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func chip(text: String, color: Color, size: int = 13) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UITheme.box("ui/chip", 9, 3)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.modulate_color = color
	p.add_theme_stylebox_override("panel", sb)
	var l := bold(text, size, UITheme.OUTLINE)
	l.add_theme_constant_override("outline_size", 0)
	p.add_child(l)
	return p


static func spacer(w: int = 0, h: int = 0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func stars(ripeness: int) -> String:
	return ["◌", "◔", "★", "★★", "★★★"][clampi(ripeness, 0, 4)]


static func fruit_tip(f: Dictionary) -> String:
	var traits: Array = f.get("traits", [])
	var t := "%s  (%s)\n%s · %s\nGrants: %s\nDamage %d · Digests %ds · %d slot%s" % [
		f.get("name", "?"), f.get("ripeness_name", "Ripe"),
		FAMILY_NAMES[int(f.get("family", 0))], f.get("flavor", ""),
		f.get("skill_name", "?"), int(f.get("base_damage", 0)), int(f.get("digestion_duration", 0)),
		int(f.get("slots", 1)), "" if int(f.get("slots", 1)) == 1 else "s"]
	if not traits.is_empty():
		t += "\nTraits: " + ", ".join(traits)
	return t


## Pin a control to a screen corner/edge with a margin, growing inward.
static func pin(c: Control, preset: Control.LayoutPreset, margin: Vector2 = Vector2(16, 14)) -> void:
	c.set_anchors_preset(preset)
	var right := preset in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_RIGHT]
	var bottom := preset in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_BOTTOM]
	var hcenter := preset in [Control.PRESET_CENTER_TOP, Control.PRESET_CENTER_BOTTOM, Control.PRESET_CENTER]
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH if hcenter else (Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END)
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	c.offset_left = 0.0 if hcenter else (-margin.x if right else margin.x)
	c.offset_right = c.offset_left
	c.offset_top = -margin.y if bottom else margin.y
	c.offset_bottom = c.offset_top
