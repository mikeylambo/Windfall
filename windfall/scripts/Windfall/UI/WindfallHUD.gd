extends Control
class_name WindfallHUD

signal advance_phase_requested
signal open_market_requested
signal open_codex_requested
signal open_satchel_requested

@export var player: RootbornPlayer
@export var day_manager: DayCycleManager
@export var market: MarketManager

var _juice_splash_timer: float = 0.0
var _splash_color: Color = Color.TRANSPARENT
var _splash_text: String = ""
var _splash_text_timer: float = 0.0

# Panels
var is_market_open: bool = false
var is_codex_open: bool = false
var is_satchel_open: bool = false


func _ready() -> void:
	if player != null:
		player.stomach_changed.connect(queue_redraw)
		player.satchel_changed.connect(queue_redraw)
		player.health_updated.connect(func(_c, _m): queue_redraw())
		player.energy_updated.connect(func(_c, _m): queue_redraw())
		player.tool_changed.connect(func(_t): queue_redraw())
		player.bite_taken.connect(_on_player_bite)

	if day_manager != null:
		day_manager.time_changed.connect(func(_p, _d, _s): queue_redraw())
		day_manager.raid_started.connect(func(_w): queue_redraw())
		day_manager.raid_cleared.connect(func(_d): queue_redraw())

	if market != null:
		market.gold_changed.connect(func(_g): queue_redraw())


func _process(delta: float) -> void:
	if _juice_splash_timer > 0.0:
		_juice_splash_timer -= delta
		queue_redraw()

	if _splash_text_timer > 0.0:
		_splash_text_timer -= delta
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_satchel"):
		is_satchel_open = not is_satchel_open
		is_market_open = false
		is_codex_open = false
		queue_redraw()
	elif event.is_action_pressed("open_codex"):
		is_codex_open = not is_codex_open
		is_market_open = false
		is_satchel_open = false
		queue_redraw()


func _on_player_bite(fruit_data: Dictionary) -> void:
	var fam: int = int(fruit_data.get("family", WindfallTypes.Family.STORM))
	_splash_color = WindfallTypes.FAMILY_COLORS.get(fam, Color.YELLOW)
	_juice_splash_timer = 0.38
	_splash_text = "%s EATEN!\n%s BLOOMED ON HUD" % [fruit_data.get("name", "Fruit").to_upper(), fruit_data.get("skill_name", "SKILL").to_upper()]
	_splash_text_timer = 2.0
	queue_redraw()


func _draw() -> void:
	if player == null:
		return

	# 1. Health & Stamina (Top-Left)
	_draw_bars()

	# 2. Time, Season & Gold (Top-Right)
	_draw_header()

	# 3. Stomach Terrarium (Bottom-Left)
	_draw_stomach_terrarium()

	# 4. Tool & Quickroot Seed Wheel (Bottom-Right)
	_draw_tool_and_quickroot()

	# 5. Hero Bite Juice Splash Overlay
	if _juice_splash_timer > 0.0:
		_draw_juice_splash()

	# 6. Hero Bite Text Banner
	if _splash_text_timer > 0.0:
		_draw_splash_text()

	# 7. Modals (if toggled open)
	if is_satchel_open:
		_draw_satchel_modal()
	elif is_market_open:
		_draw_market_modal()
	elif is_codex_open:
		_draw_codex_modal()


func _draw_bars() -> void:
	var hp_w := 200.0
	var hp_h := 14.0
	var hp_pct := clampf(player.current_health / player.max_health, 0.0, 1.0)

	# Health Background & Fill
	draw_rect(Rect2(20, 20, hp_w, hp_h), Color(0.12, 0.12, 0.12, 0.85))
	draw_rect(Rect2(20, 20, hp_w * hp_pct, hp_h), Color(0.85, 0.22, 0.22))
	draw_rect(Rect2(20, 20, hp_w, hp_h), Color(0.3, 0.3, 0.3), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(25, 31), "HP: %d/%d" % [int(player.current_health), int(player.max_health)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

	# Energy / Stamina Bar
	var en_w := 150.0
	var en_h := 9.0
	var en_pct := clampf(player.current_energy / player.max_energy, 0.0, 1.0)
	draw_rect(Rect2(20, 38, en_w, en_h), Color(0.12, 0.12, 0.12, 0.85))
	draw_rect(Rect2(20, 38, en_w * en_pct, en_h), Color(0.2, 0.8, 0.35))
	draw_rect(Rect2(20, 38, en_w, en_h), Color(0.3, 0.3, 0.3), false, 1.5)


func _draw_header() -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	var header_x := vp_w - 320.0

	draw_rect(Rect2(header_x, 15, 305, 55), Color(0.1, 0.12, 0.14, 0.85))
	draw_rect(Rect2(header_x, 15, 305, 55), Color(0.4, 0.35, 0.25), false, 1.5)

	var season_name := "Spring"
	if day_manager != null:
		match day_manager.current_season:
			WindfallTypes.Season.SUMMER: season_name = "Summer"
			WindfallTypes.Season.AUTUMN: season_name = "Autumn"
			WindfallTypes.Season.WINTER: season_name = "Winter"

	var phase_str := "Morning Tending"
	if day_manager != null:
		match day_manager.current_phase:
			WindfallTypes.TimeOfDay.EXPEDITION: phase_str = "Expedition"
			WindfallTypes.TimeOfDay.NIGHT_RAID: phase_str = "NIGHT RAID!"

	var day_num := day_manager.day_number if day_manager else 1
	var gold_val := market.gold if market else 0

	draw_string(ThemeDB.fallback_font, Vector2(header_x + 10, 34), "Day %d — %s (%s)" % [day_num, season_name, phase_str], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(header_x + 10, 56), "Gold: %d G  |  [I] Satchel  [C] Codex" % [gold_val], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.85, 0.7))


# ── The Stomach Terrarium ──────────────────────────────────────────────────────

func _draw_stomach_terrarium() -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	var base_x := 25.0
	var base_y := vp_h - 110.0

	# Terrarium Glass Vessel
	var box_w := 290.0
	var box_h := 88.0
	draw_rect(Rect2(base_x, base_y, box_w, box_h), Color(0.08, 0.1, 0.12, 0.88))
	draw_rect(Rect2(base_x, base_y, box_w, box_h), Color(0.25, 0.55, 0.5, 0.9), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y - 6), "STOMACH (YOU ARE WHAT YOU EAT)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.8, 0.75))

	var key_labels := ["[Q] Strike", "[R] Burst", "[T] Ward"]
	var cur_x := base_x + 22.0

	for slot_idx in player.max_stomach_slots:
		# Slot bubble background
		var slot_center := Vector2(cur_x + 18.0, base_y + 40.0)
		draw_circle(slot_center, 22.0, Color(0.14, 0.16, 0.2, 0.9))
		draw_arc(slot_center, 22.0, 0.0, TAU, 18, Color(0.3, 0.35, 0.4), 1.5)

		if slot_idx < player.digesting_fruits.size():
			var f := player.digesting_fruits[slot_idx]
			var fam: int = int(f.get("family", 0))
			var col: Color = WindfallTypes.FAMILY_COLORS.get(fam, Color.WHITE)

			# Digestion progress arc (leaf curling)
			var total_dur: float = float(f.get("digestion_duration", 50.0))
			var rem_dur: float = float(f.get("remaining_duration", 10.0))
			var pct := clampf(rem_dur / total_dur, 0.0, 1.0)
			draw_arc(slot_center, 22.0, -PI * 0.5, -PI * 0.5 + (pct * TAU), 24, col, 3.5)

			# Fruit icon circle inside
			draw_circle(slot_center, 12.0, col)
			draw_circle(slot_center, 6.0, Color.WHITE)

			# Skill & key label
			var key_name: String = key_labels[slot_idx] if slot_idx < key_labels.size() else "Passive"
			draw_string(ThemeDB.fallback_font, Vector2(cur_x - 8, base_y + 75), key_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
			draw_string(ThemeDB.fallback_font, Vector2(cur_x - 8, base_y + 85), f.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
		else:
			draw_string(ThemeDB.fallback_font, Vector2(cur_x + 6, base_y + 44), "Empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.5, 0.5))

		cur_x += 64.0

	# Pairings indicator banner
	if not player.active_pairings.is_empty():
		var pair_text := "PAIRING: "
		for p in player.active_pairings:
			match p:
				WindfallTypes.PairingEffect.CONDUCTIVE: pair_text += "[CONDUCTIVE: 1.5x SHOCK] "
				WindfallTypes.PairingEffect.FANNED_FLAME: pair_text += "[FANNED FLAME: SPREADING FIRE] "
				WindfallTypes.PairingEffect.INDIGESTION: pair_text += "[INDIGESTION: -25% POWER CLASH] "
				WindfallTypes.PairingEffect.SANCTUARY: pair_text += "[SANCTUARY BLOOM: REGEN] "
		draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y + 102), pair_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.85, 0.3))


func _draw_tool_and_quickroot() -> void:
	var vp := get_viewport().get_visible_rect().size
	var base_x := vp.x - 220.0
	var base_y := vp.y - 110.0

	draw_rect(Rect2(base_x, base_y, 200, 88), Color(0.08, 0.1, 0.12, 0.88))
	draw_rect(Rect2(base_x, base_y, 200, 88), Color(0.4, 0.35, 0.25), false, 1.5)

	# Equipped Tool
	var tool_names := ["Pruning Shears", "Scythe", "Hoe-Staff", "Seed Sling", "Watering Can"]
	var t_name: String = tool_names[player.current_tool]
	draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y + 22), "TOOL [Tab]:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.75, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y + 40), t_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.4))

	# Quickroot seed
	var seed_name: String = FruitRegistry.get_species(player.selected_seed_id).get("name", "Seed")
	var seed_count: int = player.satchel_seeds.get(player.selected_seed_id, 0)
	draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y + 62), "QUICKROOT [F]:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.85, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(base_x + 10, base_y + 78), "%s (x%d)" % [seed_name, seed_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.95, 0.9))


func _draw_juice_splash() -> void:
	var vp := get_viewport().get_visible_rect().size
	var alpha: float = (_juice_splash_timer / 0.38) * 0.4
	# Radial juice vignette
	draw_circle(vp * 0.5, 340.0, Color(_splash_color.r, _splash_color.g, _splash_color.b, alpha))
	# Splatter particles
	for i in 12:
		var angle: float = (float(i) / 12.0) * TAU
		var s_pos := (vp * 0.5) + Vector2(cos(angle), sin(angle)) * (180.0 + sin(i * 3.0) * 80.0)
		draw_circle(s_pos, 16.0, Color(_splash_color.r, _splash_color.g, _splash_color.b, alpha * 1.5))


func _draw_splash_text() -> void:
	var vp := get_viewport().get_visible_rect().size
	var alpha: float = minf(_splash_text_timer / 0.5, 1.0)
	var banner_w := 460.0
	var banner_h := 60.0
	var b_x := (vp.x - banner_w) * 0.5
	var b_y := 120.0

	draw_rect(Rect2(b_x, b_y, banner_w, banner_h), Color(0.05, 0.05, 0.08, 0.88 * alpha))
	draw_rect(Rect2(b_x, b_y, banner_w, banner_h), Color(_splash_color.r, _splash_color.g, _splash_color.b, alpha), false, 2.5)

	var lines := _splash_text.split("\n")
	draw_string(ThemeDB.fallback_font, Vector2(b_x + 20, b_y + 26), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.9, 0.2, alpha))
	if lines.size() > 1:
		draw_string(ThemeDB.fallback_font, Vector2(b_x + 20, b_y + 48), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(_splash_color.r, _splash_color.g, _splash_color.b, alpha))


# ── Modals: Satchel, Market, Codex ─────────────────────────────────────────────

func _draw_satchel_modal() -> void:
	var vp := get_viewport().get_visible_rect().size
	var m_w := 540.0
	var m_h := 400.0
	var m_x := (vp.x - m_w) * 0.5
	var m_y := (vp.y - m_h) * 0.5

	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.1, 0.12, 0.14, 0.95))
	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.5, 0.4, 0.3), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, m_y + 30), "SATCHEL PROVISIONS (Press [1], [2], [3] to Eat)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.4))

	# Fresh fruit list
	var y := m_y + 60.0
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, y), "Carried Fruit:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.8))
	y += 24.0

	if player.satchel_fruits.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(m_x + 30, y), "(Satchel is empty — harvest your orchard or forage wild trees)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.5))
		y += 24.0
	else:
		for i in mini(player.satchel_fruits.size(), 6):
			var f := player.satchel_fruits[i]
			var fam: int = int(f.get("family", 0))
			var col: Color = WindfallTypes.FAMILY_COLORS.get(fam, Color.WHITE)
			var rip_name: String = f.get("ripeness_name", "Ripe")
			var trait_str := ""
			if not f.get("traits", []).is_empty():
				trait_str = " (" + ", ".join(f.get("traits")) + ")"
			draw_string(ThemeDB.fallback_font, Vector2(m_x + 30, y), "[%d] %s (%s)%s — Grants: %s (%s)" % [i + 1, f.get("name"), rip_name, trait_str, f.get("skill_name"), f.get("flavor")], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
			y += 24.0

	# Seed stock list
	y += 20.0
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, y), "Carried Seeds (For Planting or [F] Quickroot):", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.8))
	y += 24.0

	for sid in player.satchel_seeds.keys():
		var count: int = player.satchel_seeds[sid]
		if count > 0:
			var s_data := FruitRegistry.get_species(sid)
			var selected_tag := " [SELECTED]" if sid == player.selected_seed_id else ""
			draw_string(ThemeDB.fallback_font, Vector2(m_x + 30, y), "• %s Seed x%d%s" % [s_data.get("name"), count, selected_tag], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.9, 0.7))
			y += 22.0


func _draw_market_modal() -> void:
	var vp := get_viewport().get_visible_rect().size
	var m_w := 540.0
	var m_h := 380.0
	var m_x := (vp.x - m_w) * 0.5
	var m_y := (vp.y - m_h) * 0.5

	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.1, 0.12, 0.14, 0.95))
	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.9, 0.75, 0.2), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, m_y + 30), "HOMESTEAD MARKET STALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.3))

	var y := m_y + 65.0
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, y), "Your Gold: %d G" % [market.gold if market else 0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	y += 28.0

	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, y), "Available Seed Stock & Upgrades:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
	y += 24.0

	var items := [
		"Voltberry Seed — 25 G",
		"Cinderapple Seed — 25 G",
		"Rimepear Seed — 25 G",
		"Briarcherry Seed — 22 G",
		"Stomach Expansion (+1 Slot) — 200 G",
		"Tool Upgrades (+Damage & Reach) — 100 G"
	]
	for it in items:
		draw_string(ThemeDB.fallback_font, Vector2(m_x + 30, y), "• " + it, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.9, 0.95))
		y += 24.0


func _draw_codex_modal() -> void:
	var vp := get_viewport().get_visible_rect().size
	var m_w := 640.0
	var m_h := 440.0
	var m_x := (vp.x - m_w) * 0.5
	var m_y := (vp.y - m_h) * 0.5

	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.08, 0.1, 0.12, 0.96))
	draw_rect(Rect2(m_x, m_y, m_w, m_h), Color(0.4, 0.75, 0.8), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(m_x + 20, m_y + 30), "THE WINDFALL CODEX (32 SPECIES + HYBRIDS)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.9, 0.85))

	var y := m_y + 60.0
	var count := 0
	for sid in FruitRegistry.species.keys():
		if count >= 12: break # Display sample set
		var sp: Dictionary = FruitRegistry.species[sid]
		var fam: int = int(sp.get("family", 0))
		var col: Color = WindfallTypes.FAMILY_COLORS.get(fam, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(m_x + 25, y), "%s (%s) — Skill: %s | Flavor: %s" % [sp.get("name"), sp.get("skill_type"), sp.get("skill_name"), sp.get("flavor")], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
		y += 24.0
		count += 1

	draw_string(ThemeDB.fallback_font, Vector2(m_x + 25, m_y + m_h - 20), "Hybrids discoverable via adjacent cross-pollination in Spring!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.85, 0.3))
