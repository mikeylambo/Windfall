extends Control
class_name WindfallHUD

## The in-game HUD: vitals, clock & gold, the Stomach Terrarium, tools &
## quickroot, prompts, toasts, banners, the bite moment, dialogue and menus.
## Built in code on top of the shared Theme so it stays one cohesive kit.

signal advance_phase_requested
signal open_market_requested
signal open_codex_requested
signal open_satchel_requested

@export var player: RootbornPlayer
@export var day_manager: DayCycleManager
@export var market: MarketManager
var lighting: DayLighting
var main: Node
var is_bound: bool = false

# kept for API compatibility with the original HUD
var is_market_open: bool = false
var is_codex_open: bool = false
var is_satchel_open: bool = false

var _hp_bar: PixelBar
var _hp_label: Label
var _st_bar: PixelBar
var _clock_icon: TextureRect
var _clock_label: Label
var _season_icon: TextureRect
var _season_label: Label
var _phase_label: Label
var _gold_label: Label
var _raid_chip: PanelContainer
var _raid_label: Label
var _quest_box: PanelContainer
var _quest_title: Label
var _quest_label: Label
var _stomach: StomachJar
var _snacks: HBoxContainer
var _tool_slots: Array[Button] = []
var _seed_icon: TextureRect
var _seed_label: Label
var _prompt: HBoxContainer
var _prompt_label: Label
var _toasts: VBoxContainer
var _banner: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween
var _splash: TextureRect
var _fade: ColorRect
var _dialogue: DialogueBoxW
var _menu_root: Control
var _menu: Control = null
var _menu_name: String = ""
var _displayed_gold: float = 0.0
var _coop_box: VBoxContainer
var _coop_chips: Dictionary = {}   # RootbornPlayer -> {bar, fruits}
var _party_box: HBoxContainer
var _boss_box: VBoxContainer
var _boss_bar: PixelBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = load("res://assets/ui/windfall_theme.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func bind() -> void:
	is_bound = true
	player.stomach_changed.connect(_refresh_stomach)
	player.satchel_changed.connect(_refresh_satchel)
	player.health_updated.connect(_on_health)
	player.energy_updated.connect(func(c, m): _st_bar.max_value = m; _st_bar.value = c)
	player.tool_changed.connect(func(_t): _refresh_tools())
	player.bite_taken.connect(_on_player_bite)
	day_manager.time_changed.connect(func(_p, _d, _s): _refresh_clock())
	day_manager.raid_started.connect(func(_w): _raid_chip.visible = true)
	day_manager.raid_cleared.connect(func(_d): _raid_chip.visible = false)
	day_manager.boss_spawned.connect(_on_boss)
	day_manager.raid_progress.connect(func(r, _t): _raid_label.text = "%d left" % r)
	QuestManager.quest_accepted.connect(func(_q): _refresh_quest())
	QuestManager.quest_objective_updated.connect(func(_q, _i): _refresh_quest(true))
	QuestManager.quest_completed.connect(func(_q): _refresh_quest(true))
	_displayed_gold = market.gold
	_on_health(player.current_health, player.max_health)
	_refresh_stomach()
	_refresh_satchel()
	_refresh_tools()
	_refresh_clock()
	_refresh_quest()
	for v in get_tree().get_nodes_in_group("villagers"):
		v.spoken.connect(func(_v): call_deferred("_refresh_party"))
	_refresh_party()


# ── layout ──────────────────────────────────────────────────────────────────

func _build() -> void:
	# juice splash sits under everything
	_splash = TextureRect.new()
	_splash.texture = Art.glow_texture()
	_splash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_splash.material = add
	_splash.modulate.a = 0.0
	add_child(_splash)

	# top-left vitals
	var vit := UIKit.panel("DarkPanel")
	vit.position = Vector2(16, 14)
	add_child(vit)
	var vb := UIKit.vbox(4)
	vit.add_child(vb)
	var hp_row := UIKit.hbox(6)
	hp_row.add_child(UIKit.icon("icons/heart", 30))
	_hp_bar = _make_bar("ui/bar_hp", 210)
	hp_row.add_child(_hp_bar)
	_hp_label = UIKit.bold("120", 15)
	_hp_label.custom_minimum_size.x = 40
	hp_row.add_child(_hp_label)
	vb.add_child(hp_row)
	var st_row := UIKit.hbox(6)
	st_row.add_child(UIKit.icon("icons/bolt", 30))
	_st_bar = _make_bar("ui/bar_stamina", 160)
	st_row.add_child(_st_bar)
	vb.add_child(st_row)

	# co-op vitals (P2/P3) and village party roster under P1's vitals
	_coop_box = UIKit.vbox(4)
	_coop_box.position = Vector2(16, 104)
	add_child(_coop_box)
	_party_box = UIKit.hbox(6)
	_coop_box.add_child(_party_box)

	# top-right clock / season / phase / gold
	var tr := UIKit.hbox(8)
	add_child(tr)
	UIKit.pin(tr, Control.PRESET_TOP_RIGHT)
	_raid_chip = _chip_box("icons/skull")
	_raid_label = _raid_chip.get_meta("label")
	_raid_chip.visible = false
	tr.add_child(_raid_chip)
	var clock := _chip_box("icons/sun")
	_clock_icon = clock.get_meta("icon")
	_clock_label = clock.get_meta("label")
	tr.add_child(clock)
	var season := _chip_box("icons/season_0")
	_season_icon = season.get_meta("icon")
	_season_label = season.get_meta("label")
	tr.add_child(season)
	var gold := _chip_box("icons/coin")
	_gold_label = gold.get_meta("label")
	_gold_label.add_theme_color_override("font_color", UITheme.GOLD)
	tr.add_child(gold)
	_phase_label = UIKit.label("", 14, UITheme.CREAM_DIM)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_phase_label)
	UIKit.pin(_phase_label, Control.PRESET_TOP_RIGHT, Vector2(20, 66))

	# quest tracker under the clock
	_quest_box = UIKit.panel("DarkPanel")
	_quest_box.custom_minimum_size.x = 300
	var qv := UIKit.vbox(2)
	_quest_title = UIKit.bold("", 14, UITheme.GOLD)
	_quest_label = UIKit.label("", 14)
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_label.custom_minimum_size.x = 280
	qv.add_child(_quest_title)
	qv.add_child(_quest_label)
	_quest_box.add_child(qv)
	_quest_box.visible = false
	add_child(_quest_box)
	UIKit.pin(_quest_box, Control.PRESET_TOP_RIGHT, Vector2(16, 96))

	# bottom-left stomach terrarium + snacks
	var bl := UIKit.vbox(4)
	add_child(bl)
	UIKit.pin(bl, Control.PRESET_BOTTOM_LEFT)
	_stomach = StomachJar.new()
	bl.add_child(_stomach)

	# bottom-right tools + quickroot + snacks
	var br := UIKit.panel("DarkPanel")
	add_child(br)
	UIKit.pin(br, Control.PRESET_BOTTOM_RIGHT)
	var brv := UIKit.vbox(6)
	br.add_child(brv)
	var snack_row := UIKit.hbox(6)
	snack_row.add_child(UIKit.icon("icons/satchel", 30))
	_snacks = UIKit.hbox(4)
	snack_row.add_child(_snacks)
	snack_row.add_child(UIKit.spacer(0, 0, true))
	snack_row.add_child(UIKit.keycap("I"))
	brv.add_child(snack_row)
	var tools := UIKit.hbox(4)
	for i in 5:
		var b := UIKit.slot_button("icons/tool_%d" % i, UIKit.TOOL_NAMES[i], 44)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tool_slots.append(b)
		tools.add_child(b)
	brv.add_child(tools)
	var tool_hint := UIKit.hbox(6)
	tool_hint.add_child(UIKit.keycap("Tab"))
	tool_hint.add_child(UIKit.label("Tool", 14, UITheme.CREAM_DIM))
	tool_hint.add_child(UIKit.spacer(0, 0, true))
	_seed_icon = UIKit.icon("icons/seed_0", 30)
	tool_hint.add_child(_seed_icon)
	_seed_label = UIKit.bold("x0", 14)
	tool_hint.add_child(_seed_label)
	tool_hint.add_child(UIKit.keycap("F"))
	brv.add_child(tool_hint)

	# interaction prompt (bottom centre)
	_prompt = UIKit.hbox(8)
	_prompt.add_child(UIKit.keycap("E", 16))
	_prompt_label = UIKit.bold("", 17)
	_prompt.add_child(_prompt_label)
	_prompt.visible = false
	add_child(_prompt)
	UIKit.pin(_prompt, Control.PRESET_CENTER_BOTTOM, Vector2(0, 170))

	# toasts (left middle)
	_toasts = UIKit.vbox(4)
	_toasts.position = Vector2(18, 250)
	add_child(_toasts)

	# banners (top centre)
	_banner = UIKit.vbox(0)
	_banner.custom_minimum_size = Vector2(700, 0)
	var plate := TextureRect.new()
	plate.texture = Art.glow_texture()
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.modulate = Color(0.06, 0.03, 0.08, 0.75)
	plate.position = Vector2(50, -40)
	plate.size = Vector2(600, 170)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.show_behind_parent = true
	_banner_title = UIKit.header("", 40)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub = UIKit.bold("", 18)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner.add_child(_banner_sub)
	_banner.add_child(plate)
	plate.top_level = false
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	UIKit.pin(_banner, Control.PRESET_CENTER_TOP, Vector2(0, 130))

	# boss bar (top centre, under the banner area)
	_boss_box = UIKit.vbox(2)
	var boss_name := UIKit.header("REAPING ELITE", 30, WPal.RED[4])
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(boss_name)
	_boss_bar = PixelBar.new("ui/bar_hp", 420)
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false
	add_child(_boss_box)
	UIKit.pin(_boss_box, Control.PRESET_CENTER_TOP, Vector2(0, 70))

	_dialogue = DialogueBoxW.new()
	_dialogue.closed.connect(_on_dialogue_closed)
	add_child(_dialogue)
	UIKit.pin(_dialogue, Control.PRESET_CENTER_BOTTOM, Vector2(0, 24))

	_menu_root = Control.new()
	_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_root)

	_fade = ColorRect.new()
	_fade.color = Color("0e0a14")
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func _make_bar(fill: String, w: int) -> PixelBar:
	return PixelBar.new(fill, w)


func _chip_box(icon_path: String) -> PanelContainer:
	var p := UIKit.panel("DarkPanel")
	var h := UIKit.hbox(6)
	var ic := UIKit.icon(icon_path, 30)
	var l := UIKit.bold("", 16)
	h.add_child(ic)
	h.add_child(l)
	p.add_child(h)
	p.set_meta("icon", ic)
	p.set_meta("label", l)
	return p


# ── refresh ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not is_bound:
		return
	# rolling gold counter
	if absf(_displayed_gold - market.gold) > 0.5:
		_displayed_gold = lerpf(_displayed_gold, market.gold, minf(delta * 8.0, 1.0))
	else:
		_displayed_gold = market.gold
	_set_text(_gold_label, str(int(round(_displayed_gold))))
	if lighting:
		_set_text(_clock_label, "Day %d · %s" % [day_manager.day_number, lighting.hour_string()])
	_stomach.update_timers(player)
	_update_prompt()


func _on_health(c: float, m: float) -> void:
	var dropped := c < _hp_bar.value
	_hp_bar.max_value = m
	_hp_bar.value = c
	_hp_label.text = str(int(ceil(c)))
	if dropped:
		var t := _hp_bar.create_tween()
		_hp_bar.modulate = Color(2, 1.2, 1.2)
		t.tween_property(_hp_bar, "modulate", Color.WHITE, 0.25)


func _refresh_clock() -> void:
	var phase := day_manager.current_phase
	_clock_icon.texture = Art.tex(["icons/sun", "icons/sunset", "icons/moon"][phase])
	_season_icon.texture = Art.tex("icons/season_%d" % day_manager.current_season)
	_season_label.text = WindfallTypes.Season.keys()[day_manager.current_season].capitalize()
	_phase_label.text = ["Morning Tending", "Expedition", "Night Raid"][phase]
	_phase_label.add_theme_color_override("font_color", [UITheme.CREAM_DIM, UITheme.GOLD, WPal.RED[4]][phase])


func _refresh_stomach() -> void:
	_stomach.rebuild(player)


func _refresh_satchel() -> void:
	for c in _snacks.get_children():
		c.queue_free()
	for i in 3:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(36, 36)
		var bg := UIKit.icon("ui/slot_0", 36)
		slot.add_child(bg)
		if i < player.satchel_fruits.size():
			var f := player.satchel_fruits[i]
			var ic := UIKit.icon(Art.species_icon(f.get("species_id", &"")), 24)
			ic.position = Vector2(6, 5)
			slot.add_child(ic)
		var k := UIKit.bold(str(i + 1), 12, UITheme.CREAM_DIM)
		k.position = Vector2(2, 22)
		slot.add_child(k)
		_snacks.add_child(slot)
	var fam := int(FruitRegistry.get_species(player.selected_seed_id).get("family", 0))
	_seed_icon.texture = Art.tex("icons/seed_%d" % fam)
	_seed_label.text = "x%d" % int(player.satchel_seeds.get(player.selected_seed_id, 0))
	if _menu and _menu.has_method("refresh"):
		_menu.call("refresh")


func _refresh_tools() -> void:
	for i in _tool_slots.size():
		var sel := i == player.current_tool
		var b := _tool_slots[i]
		b.add_theme_stylebox_override("normal", UITheme.box("ui/slot_1" if sel else "ui/slot_0", 15, 6))
		b.modulate = Color.WHITE if sel else Color(0.75, 0.72, 0.7)
		if sel:
			b.pivot_offset = b.size * 0.5
			var t := b.create_tween()
			b.scale = Vector2(1.18, 1.18)
			t.tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		else:
			b.scale = Vector2.ONE


func _refresh_quest(pulse: bool = false) -> void:
	var q: QuestData = null
	for aq in QuestManager.active_quests:
		q = aq
	_quest_box.visible = q != null
	if q == null:
		return
	_quest_title.text = "%s  (%d/%d)" % [q.title, q.current_objective_idx, q.objectives.size()]
	_quest_label.text = "▸ " + q.objectives[mini(q.current_objective_idx, q.objectives.size() - 1)]
	if pulse:
		_quest_box.pivot_offset = _quest_box.size * 0.5
		_quest_box.modulate = Color(1.4, 1.3, 0.9)
		var t := _quest_box.create_tween()
		t.tween_property(_quest_box, "modulate", Color.WHITE, 0.5)


func _update_prompt() -> void:
	var target: Node = player.get_interactable() if player else null
	var text := ""
	if target != null and is_instance_valid(target) and _menu == null and not _dialogue.visible:
		if target.has_method("get_prompt"):
			text = target.call("get_prompt")
	if _prompt.visible != (text != ""):
		_prompt.visible = text != ""
	_set_text(_prompt_label, text)


## Only touch Label.text when it changes (avoids per-frame relayout).
func _set_text(l: Label, t: String) -> void:
	if l.text != t:
		l.text = t


# ── the bite moment ─────────────────────────────────────────────────────────

func _on_player_bite(fruit_data: Dictionary) -> void:
	var fam: int = int(fruit_data.get("family", WindfallTypes.Family.STORM))
	var col := WPal.element(fam, 3)
	# radial juice splash across the screen
	_splash.modulate = Color(col.r, col.g, col.b, 0.0)
	var t := _splash.create_tween()
	t.tween_property(_splash, "modulate:a", 0.45, 0.05)
	t.tween_property(_splash, "modulate:a", 0.0, 0.45)
	var drops := CPUParticles2D.new()
	drops.texture = Art.tex("fx/dot4")
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = 28
	drops.lifetime = 0.8
	drops.spread = 180.0
	drops.initial_velocity_min = 300.0
	drops.initial_velocity_max = 700.0
	drops.gravity = Vector2(0, 900)
	drops.scale_amount_min = 3.0
	drops.scale_amount_max = 6.0
	drops.color = col
	drops.position = size * 0.5
	add_child(drops)
	move_child(drops, 1)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
	banner(String(fruit_data.get("name", "Fruit")).to_upper(), "%s bloomed!" % fruit_data.get("skill_name", "Skill"), WPal.element(fam, 4), 1.6)
	_stomach.bloom_last(col)


# ── toasts & banners ────────────────────────────────────────────────────────

func toast(text: String, color: Color = Color.WHITE) -> void:
	var p := UIKit.panel("DarkPanel")
	var l := UIKit.bold(text, 15, color)
	p.add_child(l)
	_toasts.add_child(p)
	p.modulate.a = 0.0
	var t := p.create_tween()
	t.tween_property(p, "modulate:a", 1.0, 0.15)
	t.tween_interval(2.6)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(p.queue_free)
	while _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
		break


func banner(title: String, sub: String, color: Color, hold: float = 2.2) -> void:
	_banner_title.text = title
	_banner_title.add_theme_color_override("font_color", color)
	_banner_sub.text = sub
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.pivot_offset = Vector2(_banner.size.x * 0.5, 30)
	_banner.scale = Vector2(1.25, 1.25)
	_banner_tween = _banner.create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.18)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(hold)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.5)


# ── dialogue ────────────────────────────────────────────────────────────────

func say(speaker: String, lines: Array, on_done: Callable = Callable()) -> void:
	var d := DialogueData.new()
	d.speaker_name = speaker
	var typed: Array[String] = []
	for l in lines:
		typed.append(String(l))
	d.lines = typed
	_dialogue.open(d, on_done)
	set_world_paused(true)


## Dialogue with choices; on_choice(index) runs after the player picks.
func ask(speaker: String, lines: Array, choices: Array, on_choice: Callable) -> void:
	var d := DialogueData.new()
	d.speaker_name = speaker
	var typed: Array[String] = []
	for l in lines:
		typed.append(String(l))
	d.lines = typed
	var ch: Array[String] = []
	for c in choices:
		ch.append(String(c))
	d.choices = ch
	_dialogue.open_with_choices(d, on_choice)
	set_world_paused(true)


func open_gift(villager: Node) -> void:
	open_menu("satchel")
	if _menu is SatchelMenu:
		(_menu as SatchelMenu).gift_target = villager
		(_menu as SatchelMenu).refresh()


func _on_dialogue_closed() -> void:
	if _menu == null:
		set_world_paused(false)


# ── menus ───────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not is_bound or _dialogue.visible:
		return
	if event.is_action_pressed("pause"):
		if _menu != null:
			close_menu()
		else:
			open_menu("pause")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_satchel"):
		_toggle("satchel")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_codex"):
		_toggle("codex")
		get_viewport().set_input_as_handled()
	elif _menu != null and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()


func _toggle(menu_name: String) -> void:
	if _menu_name == menu_name:
		close_menu()
	else:
		open_menu(menu_name)


func open_menu(menu_name: String) -> void:
	if _menu != null:
		_menu.queue_free()
	var m: Control
	match menu_name:
		"satchel": m = SatchelMenu.new()
		"codex": m = CodexMenu.new()
		"market": m = MarketMenu.new()
		"pause": m = PauseMenuW.new()
		_: return
	m.set("hud", self)
	_menu = m
	_menu_name = menu_name
	is_satchel_open = menu_name == "satchel"
	is_codex_open = menu_name == "codex"
	is_market_open = menu_name == "market"
	_menu_root.add_child(m)
	m.modulate.a = 0.0
	m.scale = Vector2(0.96, 0.96)
	var t := m.create_tween().set_parallel(true)
	t.tween_property(m, "modulate:a", 1.0, 0.12)
	t.tween_property(m, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	set_world_paused(true)
	WindfallSound.play_ui_confirm()


func close_menu() -> void:
	if _menu != null:
		_menu.queue_free()
	_menu = null
	_menu_name = ""
	is_satchel_open = false
	is_codex_open = false
	is_market_open = false
	set_world_paused(false)
	WindfallSound.play_ui_back()


func _on_boss(e: PoacherEnemy2D) -> void:
	_boss_box.visible = true
	_boss_bar.max_value = e.max_health
	_boss_bar.value = e.current_health
	toast("The Reaping Elite hungers for two fruits at once...", WPal.RED[4])
	FX.shake(0.6)
	WindfallSound.play_raid_sting()
	e.boss_hp.connect(func(c, m): _boss_bar.max_value = m; _boss_bar.value = c)
	e.died.connect(func(_x): _boss_box.visible = false)


## Offline, menus and dialogue pause the world. Online the world must keep
## running for everyone else, so only this machine's player is locked.
func set_world_paused(v: bool) -> void:
	if Net.online():
		if player:
			player.input_locked = v
			player.velocity = Vector2.ZERO
	else:
		get_tree().paused = v


func menu_blocked() -> bool:
	return _dialogue.visible


func add_coop_player(p: RootbornPlayer) -> void:
	var chip := UIKit.panel("DarkPanel")
	var h := UIKit.hbox(6)
	chip.add_child(h)
	var tag := UIKit.bold("P%d" % (p.player_index + 1), 20, CoopManager.TINTS[p.player_index])
	h.add_child(tag)
	var bar := PixelBar.new("ui/bar_hp", 120)
	h.add_child(bar)
	var fruits := UIKit.hbox(2)
	h.add_child(fruits)
	_coop_box.add_child(chip)
	_coop_chips[p] = {"chip": chip, "bar": bar, "fruits": fruits}
	p.health_updated.connect(func(c, m): bar.max_value = m; bar.value = c)
	p.stomach_changed.connect(func(): _refresh_coop_fruits(p))
	p.bite_taken.connect(_on_player_bite)
	bar.max_value = p.max_health
	bar.value = p.current_health


func remove_coop_player(p: RootbornPlayer) -> void:
	if _coop_chips.has(p):
		(_coop_chips[p].chip as Node).queue_free()
		_coop_chips.erase(p)


func _refresh_coop_fruits(p: RootbornPlayer) -> void:
	if not _coop_chips.has(p):
		return
	var box: HBoxContainer = _coop_chips[p].fruits
	for c in box.get_children():
		c.queue_free()
	for f in p.digesting_fruits.slice(0, 3):
		box.add_child(UIKit.icon(Art.species_icon(f.get("species_id", &"")), 24))


func _refresh_party() -> void:
	for c in _party_box.get_children():
		c.queue_free()
	for v in get_tree().get_nodes_in_group("villagers"):
		var chip := UIKit.panel("DarkPanel")
		var in_party: bool = v.get("is_in_party")
		var role: String = ("Party" if in_party else ("Watch" if v.call("is_guard") else "Hives"))
		chip.add_child(UIKit.bold("%s · %s" % [v.get("villager_name"), role], 20, WPal.LEAF[5] if in_party else UITheme.CREAM_DIM))
		_party_box.add_child(chip)


func menu_open() -> bool:
	return _menu != null or _dialogue.visible


# ── sleep transition ────────────────────────────────────────────────────────

func sleep_transition(on_black: Callable) -> void:
	set_world_paused(true)
	var zz := UIKit.header("z z z", 32, UITheme.CREAM_DIM)
	zz.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	zz.modulate.a = 0.0
	_fade.add_child(zz)
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(zz, "modulate:a", 1.0, 0.8)
	t.tween_callback(on_black)
	t.tween_interval(0.9)
	t.tween_property(zz, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): set_world_paused(false))
	t.tween_property(_fade, "modulate:a", 0.0, 0.9)
	t.tween_callback(zz.queue_free)
