extends WMenu
class_name CodexMenu

## The Windfall Codex: every species as a collection grid (undiscovered ones
## silhouetted) and the hybrid tree showing which families cross into what.

var _grid: GridContainer
var _detail: RichTextLabel
var _art: TextureRect
var _head: RichTextLabel
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
	var col := UIKit.vbox(4)
	right.add_child(col)
	var head := UIKit.hbox(10)
	col.add_child(head)
	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(84, 84)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_art)
	_head = _rich(Vector2(186, 0))
	_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_head)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.custom_minimum_size = Vector2(280, 230)
	_detail.add_theme_color_override("default_color", UITheme.OUTLINE)
	_detail.add_theme_constant_override("outline_size", 0)
	col.add_child(_detail)

	_tree_view = UIKit.vbox(10)
	_tree_view.visible = false
	body.add_child(_tree_view)
	_build_grid()
	_build_tree()


func _discovered() -> Dictionary:
	var m: Node = hud.get("main") if hud else null
	return m.get("discovered") if m else {}


const SILHOUETTE := preload("res://assets/shaders/silhouette.gdshader")


func _rich(min_size: Vector2) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size = min_size
	r.add_theme_color_override("default_color", UITheme.OUTLINE)
	r.add_theme_constant_override("outline_size", 0)
	return r


func _silhouette(c: CanvasItem) -> void:
	var m := ShaderMaterial.new()
	m.shader = SILHOUETTE
	c.material = m


## First base species of a family, used to picture a hybrid's parents.
func _family_rep(fam: int) -> StringName:
	for sid in FruitRegistry.species.keys():
		if int(FruitRegistry.species[sid].get("family", -1)) == fam and not FruitRegistry.hybrid_recipes.values().has(sid):
			return sid
	return &"voltberry"


func _hybrid_parents(sid: StringName) -> Array:
	for key in FruitRegistry.hybrid_recipes.keys():
		if FruitRegistry.hybrid_recipes[key] == sid:
			var parts: PackedStringArray = String(key).split("_")
			return [int(parts[0]), int(parts[1])]
	return []


func _build_grid() -> void:
	var disc := _discovered()
	var items: Array = []
	var ids: Array = FruitRegistry.species.keys()
	var found := 0
	for sid in ids:
		var known := disc.has(sid)
		if known:
			found += 1
		var parents := _hybrid_parents(sid)
		var b: Button
		if known or parents.is_empty():
			b = UIKit.slot_button(Art.species_icon(sid), "", 56)
			if not known:
				_silhouette(b.get_child(0))
		else:
			# undiscovered hybrid: parent A ? parent B
			b = UIKit.slot_button("", "", 56)
			var h := UIKit.hbox(0)
			h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			h.alignment = BoxContainer.ALIGNMENT_CENTER
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(UIKit.icon(Art.species_icon(_family_rep(parents[0])), 18))
			var q := UIKit.bold("?", 20, UITheme.GOLD)
			q.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(q)
			h.add_child(UIKit.icon(Art.species_icon(_family_rep(parents[1])), 18))
			b.add_child(h)
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
	_art.texture = Art.tex(Art.species_icon(sid))
	UIKit.smooth_if_hires(_art)
	if known:
		_art.material = null
	else:
		_silhouette(_art)
	if not known:
		var par := _hybrid_parents(sid)
		if not par.is_empty():
			_head.text = "[b]??? Hybrid[/b]\n[color=#6b4430]%s + %s[/color]" % [UIKit.FAMILY_NAMES[par[0]], UIKit.FAMILY_NAMES[par[1]]]
			_detail.text = "Plant these two families side by side and let spring pollen do the rest."
		else:
			_head.text = "[b]???[/b]\n[color=#6b4430]%s family[/color]" % UIKit.FAMILY_NAMES[fam]
			_detail.text = "Undiscovered. Forage the wilds, buy seeds, or cross-pollinate in spring."
		return
	_head.text = "[b][color=#%s]%s[/color][/b]\n[color=#6b4430]%s · %s\nprefers %s[/color]" % [
		WPal.element(fam, 1).to_html(false), sp.get("name"), UIKit.FAMILY_NAMES[fam], sp.get("flavor", ""),
		UIKit.SOIL_NAMES[int(sp.get("soil_pref", 0))]]
	_detail.text = "[b]%s[/b] (%s)\n%s\n\nDamage %d · Cooldown %.1fs\nDigests %ds · %d slot(s)\n\n[color=#6b4430]Quickroot: %s[/color]" % [
		sp.get("skill_name"), UIKit.SKILL_TYPES[int(sp.get("skill_type", 0))],
		sp.get("skill_desc", ""), int(sp.get("base_damage", 0)), float(sp.get("cooldown", 0)),
		int(sp.get("digestion_duration", 0)), int(sp.get("slots", 1)), sp.get("quickroot_desc", "")]
	var pl: RootbornPlayer = hud.get("player") if hud else null
	if pl:
		var m := float(pl.mastery_xp.get(sid, 0.0))
		_detail.text += "\n\n[b]Mastery %d%%[/b]%s" % [int(m), "  [color=#a86a1a]ROOTED[/color]" if pl.rooted_skills.has(sid) else ""]


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
		var hic := UIKit.icon(Art.species_icon(hid), 36)
		if not known:
			_silhouette(hic)
		row.add_child(hic)
		row.add_child(UIKit.bold(String(hsp.get("name", "?")) if known else "???", 16, UITheme.GOLD if known else UITheme.CREAM_DIM))
		_tree_view.add_child(row)


func _show_tab(i: int) -> void:
	_species_view.visible = i == 0
	_tree_view.visible = i == 1
	if i == 0:
		focus_first()
