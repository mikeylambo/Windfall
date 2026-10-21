extends WMenu
class_name MarketMenu

## Market stall: sell provisions, buy seeds, buy upgrades.

var _market: MarketManager
var _player: RootbornPlayer
var _list: VBoxContainer
var _gold: Label
var _tab: int = 0


func _icon() -> String:
	return "icons/coin"


func _title_text() -> String:
	return "MARKET STALL"


func build() -> void:
	_market = hud.get("market")
	_player = hud.get("player")
	var tabs := UIKit.hbox(6)
	tabs.add_child(UIKit.button("Sell", func(): _set_tab(0)))
	tabs.add_child(UIKit.button("Seeds", func(): _set_tab(1)))
	tabs.add_child(UIKit.button("Upgrades", func(): _set_tab(2)))
	tabs.add_child(UIKit.button("Pantry", func(): _set_tab(3)))
	tabs.add_child(UIKit.spacer(0, 0, true))
	tabs.add_child(UIKit.icon("icons/coin", 30))
	_gold = UIKit.bold("", 18, UITheme.GOLD)
	tabs.add_child(_gold)
	body.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = UIKit.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_market.transaction_completed.connect(_on_tx)
	refresh()


func _on_tx(msg: String) -> void:
	HUDBus.toast(msg, UITheme.GOLD)
	refresh()


func _set_tab(i: int) -> void:
	_tab = i
	refresh()


func _row(icon_path: String, title: String, sub: String, price: String, cb: Callable, enabled: bool = true) -> Button:
	var b := UIKit.button("", cb)
	b.custom_minimum_size = Vector2(600, 56)
	b.disabled = not enabled
	var h := UIKit.hbox(10)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -14
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UIKit.icon(icon_path, 36))
	var v := UIKit.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UIKit.bold(title, 16))
	v.add_child(UIKit.label(sub, 13, UITheme.CREAM_DIM))
	h.add_child(v)
	h.add_child(UIKit.spacer(0, 0, true))
	var p := UIKit.bold(price, 16, UITheme.GOLD)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(p)
	b.add_child(h)
	return b


func refresh() -> void:
	if _list == null:
		return
	_gold.text = str(_market.gold)
	for c in _list.get_children():
		c.queue_free()
	var rows: Array = []
	match _tab:
		0:
			if _player.satchel_fruits.is_empty():
				_list.add_child(UIKit.label("Nothing to sell. Harvest your orchard first!", 15, UITheme.CREAM_DIM))
			else:
				var total := 0
				for f in _player.satchel_fruits:
					total += _price(f)
				rows.append(_row("icons/satchel", "Sell everything", "%d items" % _player.satchel_fruits.size(), "+%dg" % total, _sell_all))
				for i in _player.satchel_fruits.size():
					var f := _player.satchel_fruits[i]
					var idx := i
					rows.append(_row(Art.species_icon(f.get("species_id", &"")), "%s  %s" % [f.get("name"), UIKit.stars(int(f.get("ripeness", 2)))], "%s · %s" % [f.get("ripeness_name"), f.get("skill_name")], "+%dg" % _price(f), func(): _sell(idx)))
		1:
			for sid in _market.seed_shop.keys():
				var sp := FruitRegistry.get_species(sid)
				var price: int = _market.seed_shop[sid]
				var s_id: StringName = sid
				rows.append(_row("icons/seed_%d" % int(sp.get("family", 0)), "%s Seed" % sp.get("name"), "%s · owned x%d" % [sp.get("skill_name"), int(_player.satchel_seeds.get(sid, 0))], "%dg" % price, func(): _market.buy_seed(s_id, _player), _market.gold >= price))
		2:
			var sc := 150 + _player.max_stomach_slots * 50
			rows.append(_row("icons/stomach", "Stomach Expansion", "%d → %d slots" % [_player.max_stomach_slots, mini(_player.max_stomach_slots + 1, 8)], "%dg" % sc, func(): _market.buy_stomach_upgrade(_player), _market.gold >= sc and _player.max_stomach_slots < 8))
			var tc := 100 * _market.tool_level
			rows.append(_row("icons/tool_1", "Tool Upgrade", "Tier %d → %d · +20%% damage" % [_market.tool_level, _market.tool_level + 1], "%dg" % tc, _buy_tool, _market.gold >= tc))
		3:
			if _player.satchel_fruits.is_empty():
				_list.add_child(UIKit.label("Bring fruit to preserve: juice, dried fruit or jam.", 15, UITheme.CREAM_DIM))
			for i in _player.satchel_fruits.size():
				var f := _player.satchel_fruits[i]
				var idx := i
				var ic := Art.species_icon(f.get("species_id", &""))
				if int(f.get("form", 0)) == WindfallTypes.FruitForm.FRESH:
					rows.append(_row(ic, "Juice %s" % f.get("name"), "Digests in half the time", "free", func(): _preserve(idx, "juice")))
					rows.append(_row(ic, "Dry %s" % f.get("name"), "One tier lower, but Hardy", "free", func(): _preserve(idx, "dry")))
			# jams: blend fruit of two different elements into one stomach slot
			var made := 0
			for a in _player.satchel_fruits.size():
				for b in range(a + 1, _player.satchel_fruits.size()):
					var fa := _player.satchel_fruits[a]
					var fb := _player.satchel_fruits[b]
					if made < 4 and int(fa.get("family")) != int(fb.get("family")) and int(fa.get("form", 0)) == 0 and int(fb.get("form", 0)) == 0:
						var ia := a
						var ib := b
						rows.append(_row("icons/stomach", "Jam: %s + %s" % [fa.get("name"), fb.get("name")], "Both elements in 1 slot (pairs itself!)", "free", func(): _jam(ia, ib)))
						made += 1
	for r in rows:
		_list.add_child(r)
	for i in rows.size():
		var c: Control = rows[i]
		if i > 0: c.focus_neighbor_top = c.get_path_to(rows[i - 1])
		if i < rows.size() - 1: c.focus_neighbor_bottom = c.get_path_to(rows[i + 1])
	if not rows.is_empty():
		set_first_focus(rows[0])
		call_deferred("focus_first")


func _price(f: Dictionary) -> int:
	var val := int(int(f.get("market_value", 20)) * float(WindfallTypes.RIPENESS_MULTIPLIERS.get(int(f.get("ripeness", 2)), 1.0)))
	return val * 2 if "Sweet" in f.get("traits", []) else val


func _sell(idx: int) -> void:
	if idx < _player.satchel_fruits.size():
		_market.sell_fruit(_player.satchel_fruits[idx])
		_player.satchel_fruits.remove_at(idx)
		_player.satchel_changed.emit()
		refresh()


func _sell_all() -> void:
	for f in _player.satchel_fruits:
		_market.sell_fruit(f)
	_player.satchel_fruits.clear()
	_player.satchel_changed.emit()
	refresh()


func _buy_tool() -> void:
	if _market.buy_tool_upgrade(_player):
		_player.tool_level = _market.tool_level


func _preserve(idx: int, kind: String) -> void:
	if idx >= _player.satchel_fruits.size():
		return
	var f := _player.satchel_fruits[idx]
	_player.satchel_fruits[idx] = _market.make_juice(f) if kind == "juice" else _market.make_dried_fruit(f)
	_player.satchel_changed.emit()
	WindfallSound.play_harvest()
	HUDBus.toast("Made %s" % _player.satchel_fruits[idx].get("name"), UITheme.GOLD)
	refresh()


func _jam(a: int, b: int) -> void:
	if b >= _player.satchel_fruits.size():
		return
	var jam := _market.make_jam(_player.satchel_fruits[a], _player.satchel_fruits[b])
	_player.satchel_fruits.remove_at(b)
	_player.satchel_fruits[a] = jam
	_player.satchel_changed.emit()
	WindfallSound.play_prime_timing()
	HUDBus.toast("Made %s" % jam.get("name"), UITheme.GOLD)
	refresh()
