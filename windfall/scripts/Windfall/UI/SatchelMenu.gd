extends WMenu
class_name SatchelMenu

## Satchel: carried fruit (select to eat) and the seed pouch (select to arm
## for Quickroot). Detail pane follows keyboard/gamepad focus.

var _fruit_grid: GridContainer
var _seed_grid: GridContainer
var _detail: RichTextLabel
var _player: RootbornPlayer


func _icon() -> String:
	return "icons/satchel"


func _title_text() -> String:
	return "SATCHEL"


func build() -> void:
	_player = hud.get("player")
	var cols := UIKit.hbox(18)
	body.add_child(cols)
	var left := UIKit.vbox(8)
	cols.add_child(left)
	left.add_child(UIKit.bold("Provisions  ·  Accept to eat", 15, UITheme.CREAM_DIM))
	_fruit_grid = GridContainer.new()
	_fruit_grid.columns = 6
	_fruit_grid.add_theme_constant_override("h_separation", 4)
	_fruit_grid.add_theme_constant_override("v_separation", 4)
	left.add_child(_fruit_grid)
	left.add_child(UIKit.spacer(0, 6))
	left.add_child(UIKit.bold("Seed Pouch  ·  Accept to arm Quickroot [F]", 15, UITheme.CREAM_DIM))
	_seed_grid = GridContainer.new()
	_seed_grid.columns = 6
	_seed_grid.add_theme_constant_override("h_separation", 4)
	_seed_grid.add_theme_constant_override("v_separation", 4)
	left.add_child(_seed_grid)
	var right := UIKit.panel("PaperPanel")
	right.custom_minimum_size = Vector2(300, 300)
	cols.add_child(right)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.custom_minimum_size = Vector2(280, 280)
	_detail.add_theme_color_override("default_color", UITheme.OUTLINE)
	_detail.add_theme_constant_override("outline_size", 0)
	right.add_child(_detail)
	refresh()


func refresh() -> void:
	if _fruit_grid == null:
		return
	for c in _fruit_grid.get_children():
		c.queue_free()
	for c in _seed_grid.get_children():
		c.queue_free()
	var items: Array = []
	for i in maxi(12, _player.satchel_fruits.size()):
		var b: Button
		if i < _player.satchel_fruits.size():
			var f := _player.satchel_fruits[i]
			b = UIKit.slot_button(Art.species_icon(f.get("species_id", &"")), "")
			var stars := UIKit.bold(UIKit.stars(int(f.get("ripeness", 2))), 11, UITheme.GOLD)
			stars.position = Vector2(6, 40)
			b.add_child(stars)
			var idx := i
			b.pressed.connect(func(): _eat(idx))
			b.focus_entered.connect(func(): _show_fruit(f))
			b.mouse_entered.connect(func(): _show_fruit(f))
		else:
			b = UIKit.slot_button("", "")
			b.focus_entered.connect(func(): _detail.text = "[color=#6b4430]Empty pocket. Harvest or forage to fill it.[/color]")
		_fruit_grid.add_child(b)
		items.append(b)
	WMenu.link_grid(items, 6)
	var seeds: Array = []
	for sid in _player.satchel_seeds.keys():
		var count: int = _player.satchel_seeds[sid]
		if count <= 0:
			continue
		var sp := FruitRegistry.get_species(sid)
		var b := UIKit.slot_button("icons/seed_%d" % int(sp.get("family", 0)), "")
		var n := UIKit.bold("x%d" % count, 12)
		n.position = Vector2(30, 38)
		b.add_child(n)
		if sid == _player.selected_seed_id:
			b.add_theme_stylebox_override("normal", UITheme.box("ui/slot_1", 15, 6))
		var s_id: StringName = sid
		b.pressed.connect(func(): _select_seed(s_id))
		b.focus_entered.connect(func(): _show_seed(s_id, count))
		b.mouse_entered.connect(func(): _show_seed(s_id, count))
		_seed_grid.add_child(b)
		seeds.append(b)
	WMenu.link_grid(seeds, 6)
	if not seeds.is_empty() and items.size() >= 6:
		for k in mini(6, seeds.size()):
			(items[items.size() - 6 + k] as Control).focus_neighbor_bottom = (items[items.size() - 6 + k] as Control).get_path_to(seeds[k])
			(seeds[k] as Control).focus_neighbor_top = (seeds[k] as Control).get_path_to(items[items.size() - 6 + k])
	set_first_focus(items[0])
	call_deferred("focus_first")


func _show_fruit(f: Dictionary) -> void:
	var fam := int(f.get("family", 0))
	_detail.text = "[b][color=#%s]%s[/color][/b]\n[color=#6b4430]%s · %s · %s[/color]\n\nGrants [b]%s[/b] (%s)\n%s\n\nDamage %d · Cooldown %.1fs\nDigests %ds · Uses %d slot(s)\nSells for %dg" % [
		WPal.element(fam, 1).to_html(false), f.get("name"), f.get("ripeness_name"), UIKit.FAMILY_NAMES[fam], f.get("flavor"),
		f.get("skill_name"), UIKit.SKILL_TYPES[int(f.get("skill_type", 0))], FruitRegistry.get_species(f.get("species_id")).get("skill_desc", ""),
		int(f.get("base_damage", 0)), float(f.get("cooldown", 0)), int(f.get("digestion_duration", 0)), int(f.get("slots", 1)), int(f.get("market_value", 0))]
	var traits: Array = f.get("traits", [])
	if not traits.is_empty():
		_detail.text += "\nTraits: " + ", ".join(traits)


func _show_seed(sid: StringName, count: int) -> void:
	var sp := FruitRegistry.get_species(sid)
	var fam := int(sp.get("family", 0))
	_detail.text = "[b][color=#%s]%s Seed[/color][/b]  x%d\n[color=#6b4430]%s · prefers %s soil[/color]\n\nPlant in an empty plot, or sling into battle:\n%s" % [
		WPal.element(fam, 1).to_html(false), sp.get("name"), count, UIKit.FAMILY_NAMES[fam],
		UIKit.SOIL_NAMES[int(sp.get("soil_pref", 0))], sp.get("quickroot_desc", "")]


func _eat(idx: int) -> void:
	if _player.eat_satchel_fruit_at(idx):
		close()
	else:
		HUDBus.toast("Stomach is full!", WPal.RED[4])


func _select_seed(sid: StringName) -> void:
	_player.selected_seed_id = sid
	_player.satchel_changed.emit()
	HUDBus.toast("Quickroot armed: %s" % FruitRegistry.get_species(sid).get("name"), WPal.LEAF[5])
