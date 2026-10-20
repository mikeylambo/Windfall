extends Node2D
class_name WindfallMain

const SAVE_SECTION := &"windfall"

@onready var world: Node2D = $World
@onready var player: RootbornPlayer = $World/Player
@onready var day_manager: DayCycleManager = $DayCycleManager
@onready var market_manager: MarketManager = $MarketManager
@onready var hud: WindfallHUD = $HUDLayer/WindfallHUD
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var lighting: DayLighting = $DayLighting

var initial_plots: Array[OrchardPlot2D] = []
var dresser := WorldDresser.new()

## Codex discovery: species the player has seen, harvested or eaten.
var discovered: Dictionary = {}
var tutorial: QuestData


func _enter_tree() -> void:
	# FX must know the world before any child's _ready spawns glows
	FX.bind($World, $FXOverlay)


func _ready() -> void:
	add_child(dresser)
	dresser.dress(world, $Ground)
	lighting.dresser = dresser

	for child in $World/OrchardGrid.get_children():
		if child is OrchardPlot2D:
			child.add_to_group("orchard_plots")
			initial_plots.append(child)
			child.plot_harvested.connect(_on_plot_harvested)
			child.plot_tended.connect(_on_plot_tended)

	# Connect day cycle events
	day_manager.raid_started.connect(_on_raid_started)
	day_manager.raid_cleared.connect(_on_raid_cleared)
	day_manager.new_day_started.connect(_on_new_day)
	day_manager.time_changed.connect(_on_time_changed)

	player.bite_taken.connect(_on_bite)
	player.skill_cast.connect(func(_f): _tutorial_hit(3))

	# HUD wiring
	hud.player = player
	hud.day_manager = day_manager
	hud.market = market_manager
	hud.lighting = lighting
	hud.main = self
	hud.bind()

	CameraFX.init(camera)
	SaveManager.register_save_provider(SAVE_SECTION, self)
	lighting.set_phase(day_manager.current_phase, true)
	WindfallSound.start_ambience()

	for sid in [&"voltberry", &"cinderapple", &"rimepear", &"briarcherry"]:
		discovered[sid] = true

	if GameFlow.get_meta("pending_load", false):
		GameFlow.set_meta("pending_load", false)
		SaveManager.load_game()
	else:
		call_deferred("_start_tutorial")
	GameFlow.set_mode(&"gameplay")
	call_deferred("_run_system_diagnostics")


func _exit_tree() -> void:
	SaveManager.unregister_save_provider(SAVE_SECTION)
	Engine.time_scale = 1.0


func _run_system_diagnostics() -> void:
	print("--- WINDFALL ENGINE READY ---")
	print("• Species Registered: %d base + hybrid species" % FruitRegistry.species.size())
	print("• Orchard Plots Active: %d | Day %d (%s, %s) | Gold %d" % [initial_plots.size(), day_manager.day_number,
		WindfallTypes.Season.keys()[day_manager.current_season], WindfallTypes.TimeOfDay.keys()[day_manager.current_phase], market_manager.gold])


# ── Day loop ────────────────────────────────────────────────────────────────

func _on_plot_harvested(_plot: OrchardPlot2D, fruit_instance: Dictionary) -> void:
	_discover(fruit_instance.get("species_id", &""))
	_tutorial_hit(1)


func _on_bite(f: Dictionary) -> void:
	_discover(f.get("species_id", &""))
	_tutorial_hit(2)


func _on_plot_tended(_plot: OrchardPlot2D, action_name: String) -> void:
	if action_name.begins_with("Watered"):
		_tutorial_hit(0)


func _on_raid_started(day_num: int) -> void:
	FX.shake(0.6)
	WindfallSound.play_raid_sting()
	hud.banner("NIGHT RAID", "Poachers are after your ripe fruit!", WPal.RED[4])


func _on_raid_cleared(day_num: int) -> void:
	# Reward player with bonus gold for defending the orchard!
	var bonus_gold := 50 + (day_num * 20)
	market_manager.gold += bonus_gold
	market_manager.gold_changed.emit(market_manager.gold)
	WindfallSound.play_prime_timing()
	hud.banner("ORCHARD DEFENDED", "+%d Gold  ·  Rest at the farmhouse" % bonus_gold, WPal.GOLD[4])
	_tutorial_hit(4)


func _on_new_day(day_num: int) -> void:
	# Heal player slightly each morning, and wake at the door
	player.heal(40.0)
	player.global_position = WorldLayout.DOOR + Vector2(0, 40)
	hud.banner("DAY %d" % day_num, WindfallTypes.Season.keys()[day_manager.current_season].capitalize(), WPal.CREAM[3])
	SaveManager.save_game()
	hud.toast("Game saved", WPal.LEAF[5])


func _on_time_changed(phase: int, _day: int, _season: int) -> void:
	WindfallSound.set_ambience_night(phase == WindfallTypes.TimeOfDay.NIGHT_RAID)
	if phase == WindfallTypes.TimeOfDay.EXPEDITION:
		hud.banner("EXPEDITION", "Forage the eastern wilds for seeds and fruit", WPal.GOLD[3])
		player.global_position = WorldLayout.GATE + Vector2(120, 10)
	elif phase == WindfallTypes.TimeOfDay.NIGHT_RAID:
		player.global_position = WorldLayout.GATE + Vector2(-110, 0)


func _discover(sid: StringName) -> void:
	if sid == &"" or discovered.has(sid):
		return
	discovered[sid] = true
	if is_inside_tree() and hud and hud.is_bound:
		var sp := FruitRegistry.get_species(sid)
		hud.toast("Codex: %s discovered" % sp.get("name", "?"), WPal.element(int(sp.get("family", 0)), 4))


# ── Onboarding (QuestManager + DialogueManager via the HUD) ─────────────────

func _start_tutorial() -> void:
	if QuestManager.is_quest_completed(&"first_day"):
		return
	tutorial = QuestData.new()
	tutorial.quest_id = &"first_day"
	tutorial.title = "Roots of the Orchard"
	tutorial.objectives = [
		"Water a plot  [E with Watering Can]",
		"Harvest fruit: tap [E] in the gold zone",
		"Eat a fruit  [1] [2] [3]",
		"Cast its skill  [Q] [R] [T]",
		"Head out the east gate, return at dusk and survive the raid",
	]
	tutorial.reward_gold = 100
	hud.say("Grandmother's Letter", [
		"Little sprout, the orchard is yours now. It is tired, but it remembers.",
		"Every tree here grows a skill. Eat the fruit and you'll wield what it knows.",
		"Tend them by day. By night, poachers come for the ripe ones. Don't let them bite.",
	], func(): QuestManager.accept_quest(tutorial))


func _tutorial_hit(step: int) -> void:
	if tutorial == null or not QuestManager.is_quest_active(&"first_day"):
		return
	if tutorial.current_objective_idx == step:
		QuestManager.advance_quest(&"first_day")
		WindfallSound.play_prime_timing()
		if QuestManager.is_quest_completed(&"first_day"):
			market_manager.gold += tutorial.reward_gold
			market_manager.gold_changed.emit(market_manager.gold)
			hud.toast("Tutorial complete! +%d Gold" % tutorial.reward_gold, WPal.GOLD[4])


# ── Save / Continue (template SaveManager provider) ─────────────────────────

func get_save_data() -> Dictionary:
	var plots: Array = []
	for p in initial_plots:
		plots.append({
			"stage": p.tree_stage, "species": String(p.planted_species_id), "graft": String(p.grafted_species_id),
			"growth": p.growth_timer, "water": p.water_level, "pruned": p.is_pruned,
			"fruit": p.fruit_count, "ripe": p.current_ripeness, "progress": p.ripeness_progress,
		})
	var fruits: Array = []
	for f in player.satchel_fruits:
		fruits.append(_pack_fruit(f))
	var seeds := {}
	for k in player.satchel_seeds:
		seeds[String(k)] = player.satchel_seeds[k]
	var mastery := {}
	for k in player.mastery_xp:
		mastery[String(k)] = player.mastery_xp[k]
	return {
		"day": day_manager.day_number, "season": day_manager.current_season,
		"gold": market_manager.gold, "tool_level": market_manager.tool_level,
		"hp": player.current_health, "stomach_slots": player.max_stomach_slots,
		"fruits": fruits, "seeds": seeds, "selected_seed": String(player.selected_seed_id),
		"mastery": mastery, "plots": plots, "discovered": discovered.keys().map(func(k): return String(k)),
		"tutorial_done": QuestManager.is_quest_completed(&"first_day") or tutorial == null,
		"party": {"Wren": $World/Wren.is_in_party, "Hesper": $World/Hesper.is_in_party},
	}


func load_save_data(d: Dictionary) -> void:
	day_manager.restore(int(d.get("day", 1)), WindfallTypes.TimeOfDay.MORNING, int(d.get("season", 0)))
	market_manager.gold = int(d.get("gold", 150))
	market_manager.tool_level = int(d.get("tool_level", 1))
	player.tool_level = market_manager.tool_level
	market_manager.gold_changed.emit(market_manager.gold)
	player.max_stomach_slots = int(d.get("stomach_slots", 4))
	player.current_health = float(d.get("hp", player.max_health))
	player.health_updated.emit(player.current_health, player.max_health)
	player.satchel_fruits.clear()
	for f in d.get("fruits", []):
		player.satchel_fruits.append(_unpack_fruit(f))
	player.satchel_seeds.clear()
	var seeds: Dictionary = d.get("seeds", {})
	for k in seeds:
		player.satchel_seeds[StringName(k)] = int(seeds[k])
	player.selected_seed_id = StringName(d.get("selected_seed", "voltberry"))
	var mastery: Dictionary = d.get("mastery", {})
	for k in mastery:
		player.mastery_xp[StringName(k)] = float(mastery[k])
	var plots: Array = d.get("plots", [])
	for i in mini(plots.size(), initial_plots.size()):
		var p := initial_plots[i]
		var pd: Dictionary = plots[i]
		p.tree_stage = int(pd.get("stage", 0))
		p.planted_species_id = StringName(pd.get("species", ""))
		p.grafted_species_id = StringName(pd.get("graft", ""))
		p.growth_timer = float(pd.get("growth", 0.0))
		p.water_level = float(pd.get("water", 60.0))
		p.is_pruned = bool(pd.get("pruned", false))
		p.fruit_count = int(pd.get("fruit", 0))
		p.current_ripeness = int(pd.get("ripe", 1))
		p.ripeness_progress = float(pd.get("progress", 0.0))
	discovered.clear()
	for k in d.get("discovered", []):
		discovered[StringName(k)] = true
	if bool(d.get("tutorial_done", true)) and not QuestManager.is_quest_completed(&"first_day"):
		QuestManager.completed_quests.append(&"first_day")
	var party: Dictionary = d.get("party", {})
	$World/Wren.is_in_party = bool(party.get("Wren", false))
	$World/Hesper.is_in_party = bool(party.get("Hesper", false))
	player.global_position = WorldLayout.DOOR + Vector2(0, 40)
	player.satchel_changed.emit()
	player.stomach_changed.emit()
	hud.banner("DAY %d" % day_manager.day_number, "Welcome back to the orchard", WPal.CREAM[3])


static func _pack_fruit(f: Dictionary) -> Dictionary:
	return {"id": String(f.get("species_id", "voltberry")), "rip": int(f.get("ripeness", 2)), "traits": f.get("traits", []), "form": int(f.get("form", 0))}


static func _unpack_fruit(d: Dictionary) -> Dictionary:
	return FruitRegistry.create_fruit_instance(StringName(d.get("id", "voltberry")), int(d.get("rip", 2)), d.get("traits", []), int(d.get("form", 0)))
