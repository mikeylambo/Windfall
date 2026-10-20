extends WMenu
class_name CodexMenu

## The Windfall Codex: every species as a collection grid (undiscovered ones
## silhouetted) and the hybrid tree showing which families cross into what.

var _grid: GridContainer
var _detail: RichTextLabel
var _tree_view: VBoxContainer
var _species_view: HBoxContainer
var _count: Label
var _tab_species: Button
var _tab_tree: Button


func _panel_variation() -> String:
	return "VinePanel"


func _icon() -> String:
	return "icons/codex"


func _title_text() -> String:
	return "THE CODEX"


func build() -> void:
	var tabs := UIKit.hbox(6)
	_tab_species = UIKit.button("Species", func(): _show_tab(0))
	_tab_tree = UIKit.button("Hybrid Tree", func(): _show_tab(1))
	tabs.add_child(_tab_species)
	tabs.add_child(_tab_tree)
	tabs.add_child(UIKit.spacer(0, 0, true))
	_count = UIKit.bold("", 15, UITheme.GOLD)
	tabs.add_child(_count)
	body.add_child(tabs)

	_species_view = UIKit.hbox(16)
	body.add_child(_species_view)
	_grid = GridContainer.new()
	_grid.columns = 8
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	_species_view.add_child(_grid)
	var right := UIKit.panel("PaperPanel")
	right.custom_minimum_size = Vector2(300, 0)
	_species_view.add_child(right)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.custom_minimum_size = Vector2(280, 300)
	_detail.add_theme_color_override("default_color", UITheme.OUTLINE)
	_detail.add_theme_constant_override("outline_size", 0)
	right.add_child(_detail)

	_tree_view = UIKit.vbox(10)
	_tree_view.visible = false
	body.add_child(_tree_view)
	_build_grid()
	_build_tree()


func _discovered() -> Dictionary:
	var m: Node = hud.get("main") if hud else null
	return m.get("discovered") if m else {}


func _build_grid() -> void:
	var disc := _discovered()
	var items: Array = []
	var ids: Array = FruitRegistry.species.keys()
	var found := 0
	for sid in ids:
		var sp: Dictionary = FruitRegistry.species[sid]
		var fam := int(sp.get("family", 0))
		var known := disc.has(sid)
		if known:
			found += 1
		var b := UIKit.slot_button("icons/fruit_%d" % fam, "", 56)
		var ic: TextureRect = b.get_child(0)
		if not known:
			ic.modulate = Color(0.08, 0.06, 0.1, 0.85)   # silhouette
			var q := UIKit.bold("?", 18, UITheme.CREAM_DIM)
			q.position = Vector2(22, 14)
			b.add_child(q)
		var s_id: StringName = sid
		b.focus_entered.connect(func(): _show(s_id, known))
		b.mouse_entered.connect(func(): _show(s_id, known))
		_grid.add_child(b)
		items.append(b)
	WMenu.link_grid(items, 8)
	_count.text = "%d / %d discovered" % [found, ids.size()]
	set_first_focus(items[0])


func _show(sid: StringName, known: bool) -> void:
	var sp := FruitRegistry.get_species(sid)
	var fam := int(sp.get("family", 0))
	if not known:
		_detail.text = "[b]???[/b]\n[color=#6b4430]%s family[/color]\n\nUndiscovered. Forage the wilds, buy seeds, or cross-pollinate in spring." % UIKit.FAMILY_NAMES[fam]
		return
	_detail.text = "[b][color=#%s]%s[/color][/b]\n[color=#6b4430]%s · %s · prefers %s[/color]\n\n[b]%s[/b] (%s)\n%s\n\nDamage %d · Cooldown %.1fs\nDigests %ds · %d slot(s)\n\n[color=#6b4430]Quickroot: %s[/color]" % [
		WPal.element(fam, 1).to_html(false), sp.get("name"), UIKit.FAMILY_NAMES[fam], sp.get("flavor", ""),
		UIKit.SOIL_NAMES[int(sp.get("soil_pref", 0))], sp.get("skill_name"), UIKit.SKILL_TYPES[int(sp.get("skill_type", 0))],
		sp.get("skill_desc", ""), int(sp.get("base_damage", 0)), float(sp.get("cooldown", 0)),
		int(sp.get("digestion_duration", 0)), int(sp.get("slots", 1)), sp.get("quickroot_desc", "")]


func _build_tree() -> void:
	_tree_view.add_child(UIKit.bold("Plant two families side by side. In spring, pollen mingles and hybrids are born.", 15, UITheme.CREAM_DIM))
	var disc := _discovered()
	for key in FruitRegistry.hybrid_recipes.keys():
		var parts: PackedStringArray = String(key).split("_")
		var a := int(parts[0])
		var b := int(parts[1])
		var hid: StringName = FruitRegistry.hybrid_recipes[key]
		var hsp := FruitRegistry.get_species(hid)
		var row := UIKit.hbox(10)
		row.add_child(UIKit.icon("icons/element_%d" % a, 36))
		row.add_child(UIKit.bold(UIKit.FAMILY_NAMES[a], 16, WPal.element(a, 3)))
		row.add_child(UIKit.bold("+", 18, UITheme.CREAM_DIM))
		row.add_child(UIKit.icon("icons/element_%d" % b, 36))
		row.add_child(UIKit.bold(UIKit.FAMILY_NAMES[b], 16, WPal.element(b, 3)))
		row.add_child(UIKit.bold("→", 18, UITheme.GOLD))
		var known := disc.has(hid)
		var hf := int(hsp.get("family", a))
		row.add_child(UIKit.icon("icons/fruit_%d" % hf, 36, Color.WHITE if known else Color(0.08, 0.06, 0.1, 0.85)))
		row.add_child(UIKit.bold(String(hsp.get("name", "?")) if known else "???", 16, UITheme.GOLD if known else UITheme.CREAM_DIM))
		_tree_view.add_child(row)


func _show_tab(i: int) -> void:
	_species_view.visible = i == 0
	_tree_view.visible = i == 1
	if i == 0:
		focus_first()
