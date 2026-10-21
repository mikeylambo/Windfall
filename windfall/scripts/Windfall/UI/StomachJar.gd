extends VBoxContainer
class_name StomachJar

## The Stomach Terrarium: a glass jar where digesting fruit floats, each with
## a radial digestion timer in its element colour, plus pairing/clash chips.

const PAIRINGS := {
	WindfallTypes.PairingEffect.CONDUCTIVE: ["CONDUCTIVE ×1.5", 3],
	WindfallTypes.PairingEffect.FANNED_FLAME: ["FANNED FLAME", 1],
	WindfallTypes.PairingEffect.INDIGESTION: ["INDIGESTION −25%", -1],
	WindfallTypes.PairingEffect.SANCTUARY: ["SANCTUARY REGEN", 4],
	WindfallTypes.PairingEffect.PHANTOM_MIST: ["PHANTOM MIST", 6],
}
const KEYS := ["Q", "R", "T"]

var _chips: HBoxContainer
var _jar: PanelContainer
var _row: HBoxContainer
var _slots: Array[Dictionary] = []
var _time: float = 0.0


func _init() -> void:
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chips = UIKit.hbox(4)
	add_child(_chips)
	_jar = PanelContainer.new()
	var sb := UITheme.box("ui/jar", 30, 0)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 20
	sb.content_margin_bottom = 26
	_jar.add_theme_stylebox_override("panel", sb)
	add_child(_jar)
	var v := UIKit.vbox(0)
	_jar.add_child(v)
	var title := UIKit.hbox(6)
	title.add_child(UIKit.icon("icons/stomach", 24))
	title.add_child(UIKit.bold("STOMACH", 13, Color("a8f2e4")))
	v.add_child(title)
	_row = UIKit.hbox(6)
	v.add_child(_row)


func rebuild(player: RootbornPlayer) -> void:
	for c in _row.get_children():
		c.queue_free()
	_slots.clear()
	for i in player.max_stomach_slots:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(56, 84)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glow := TextureRect.new()
		glow.texture = Art.glow_texture()
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.size = Vector2(84, 84)
		glow.position = Vector2(-14, -14)
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = add
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(glow)
		var bg := UIKit.icon("ui/ring_bg", 56)
		slot.add_child(bg)
		var ring := TextureProgressBar.new()
		ring.texture_progress = Art.tex("ui/ring")
		ring.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		ring.nine_patch_stretch = false
		ring.size = Vector2(72, 72)
		ring.scale = Vector2(56.0 / 72.0, 56.0 / 72.0)
		ring.max_value = 1.0
		ring.step = 0.001
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(ring)
		var ic := UIKit.icon("icons/fruit_0", 32)
		ic.position = Vector2(12, 12)
		ic.pivot_offset = Vector2(16, 16)
		slot.add_child(ic)
		var key := UIKit.keycap(KEYS[i] if i < KEYS.size() else "+", 20)
		key.position = Vector2(14, 54)
		slot.add_child(key)
		_row.add_child(slot)
		var filled := i < player.digesting_fruits.size()
		if filled:
			var f := player.digesting_fruits[i]
			var fam := int(f.get("family", 0))
			var col := WPal.element(fam, 3)
			ic.texture = Art.tex(Art.species_icon(f.get("species_id", &"")))
			ring.tint_progress = col
			glow.modulate = Color(col, 0.55)
			key.self_modulate = col.lightened(0.45)
			slot.tooltip_text = "%s → %s" % [f.get("name", ""), f.get("skill_name", "")]
		else:
			ic.visible = false
			glow.visible = false
			ring.visible = false
			key.modulate.a = 0.45
		_slots.append({"ring": ring, "icon": ic, "glow": glow, "filled": filled})

	for c in _chips.get_children():
		c.queue_free()
	for p in player.active_pairings:
		if PAIRINGS.has(p):
			var d: Array = PAIRINGS[p]
			var col := WPal.RED[3] if int(d[1]) < 0 else WPal.element(int(d[1]), 3)
			var chip := UIKit.chip(d[0], col)
			_chips.add_child(chip)
			chip.pivot_offset = Vector2(40, 10)
			chip.scale = Vector2(1.3, 1.3)
			chip.create_tween().tween_property(chip, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func update_timers(player: RootbornPlayer) -> void:
	_time += get_process_delta_time()
	for i in mini(_slots.size(), player.digesting_fruits.size()):
		var s: Dictionary = _slots[i]
		if not s.filled:
			continue
		var f := player.digesting_fruits[i]
		var pct := clampf(float(f.get("remaining_duration", 0.0)) / maxf(float(f.get("digestion_duration", 1.0)), 0.01), 0.0, 1.0)
		var ring: TextureProgressBar = s.ring
		ring.value = pct
		var ic: TextureRect = s.icon
		ic.position.y = 12 + sin(_time * 2.0 + i) * 2.0   # floating in the jar
		# blink when nearly digested
		ic.modulate.a = 0.4 if pct < 0.12 and int(_time * 6.0) % 2 == 0 else 1.0


## The skill "blooms" into its slot: scale + glow pulse on the newest fruit.
func bloom_last(col: Color) -> void:
	await get_tree().process_frame
	for i in range(_slots.size() - 1, -1, -1):
		var s: Dictionary = _slots[i]
		if s.filled:
			var ic: TextureRect = s.icon
			var glow: TextureRect = s.glow
			ic.scale = Vector2(2.2, 2.2)
			var t := ic.create_tween()
			t.tween_property(ic, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			glow.modulate = Color(col, 1.0)
			glow.scale = Vector2(1.6, 1.6)
			glow.pivot_offset = Vector2(42, 42)
			var g := glow.create_tween().set_parallel(true)
			g.tween_property(glow, "modulate:a", 0.55, 0.6)
			g.tween_property(glow, "scale", Vector2.ONE, 0.6)
			return
