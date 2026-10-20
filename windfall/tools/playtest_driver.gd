extends Node

## Automated smoke playtest: drives a full day loop through the real systems
## and captures screenshots. Used by tools/playtest.sh (needs a display, e.g. xvfb).
##   godot -s res://tools/playtest_runner.gd -- out=<dir>

var tree: SceneTree
var out_dir := "res://screenshots/"
var log_lines: PackedStringArray = []
var failures: int = 0


func log_line(s: String) -> void:
	print("[playtest] " + s)
	log_lines.append(s)


func check(cond: bool, what: String) -> void:
	if cond:
		log_line("PASS  " + what)
	else:
		failures += 1
		log_line("FAIL  " + what)


func frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func secs(t: float) -> void:
	await tree.create_timer(t, true, false, true).timeout


func shot(name: String) -> void:
	await frames(2)
	var img := tree.root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out_dir + name + ".png"))
	log_line("screenshot " + name)


func finish_dialogue() -> void:
	var guard := 0
	while DialogueManager.is_active and guard < 20:
		DialogueManager.advance_dialogue()
		guard += 1
		await frames(2)


func run(main: WindfallMain, t: SceneTree) -> void:
	tree = t
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var p := main.player
	var hud := main.hud
	var dm := main.day_manager
	await secs(1.0)
	await finish_dialogue()
	check(QuestManager.is_quest_active(&"first_day"), "tutorial quest accepted")

	# ── morning: water, harvest PRIME, eat, cast ───────────────────────────
	var plots := main.initial_plots
	p.current_tool = WindfallTypes.ToolType.WATERING_CAN
	p.tool_changed.emit(p.current_tool)
	p.global_position = plots[4].global_position + Vector2(0, 40)
	plots[4].water_plot()
	main._on_plot_tended(plots[4], "Watered Plot")
	await secs(0.4)
	p.current_tool = WindfallTypes.ToolType.PRUNING_SHEARS
	p.tool_changed.emit(p.current_tool)

	var tree_plot: OrchardPlot2D = plots[0]
	p.global_position = tree_plot.global_position + Vector2(0, 46)
	p.facing_direction = Vector2.UP
	await secs(0.5)
	var before := p.satchel_fruits.size()
	tree_plot.interact(p)
	check(tree_plot.is_timing_harvest, "harvest timing bar opened")
	var guard := 0
	while not (tree_plot.timing_cursor > 0.45 and tree_plot.timing_cursor < 0.55) and guard < 600:
		await frames(1)
		guard += 1
	await shot("_harvest_bar")
	tree_plot.interact(p)
	await secs(0.15)
	await shot("03_prime_harvest")
	check(p.satchel_fruits.size() == before + 1, "fruit harvested into satchel")
	check(int(p.satchel_fruits[-1].get("ripeness", 0)) == WindfallTypes.Ripeness.PRIME, "PRIME quality awarded")

	# orchard by day, wide view
	p.global_position = Vector2(940, 600)
	await secs(1.6)
	await shot("01_orchard_day")

	# eat a three-fruit combo (Storm + Tide => Conductive)
	p.satchel_fruits.insert(0, FruitRegistry.create_fruit_instance(&"brinemelon", WindfallTypes.Ripeness.PRIME))
	check(p.eat_satchel_fruit_at(0), "ate Brinemelon")
	await secs(0.5)
	check(p.eat_satchel_fruit_at(0), "ate a second fruit")
	await secs(0.5)
	p.eat_satchel_fruit_at(p.satchel_fruits.size() - 1)
	await secs(0.6)
	check(p.digesting_fruits.size() >= 2, "stomach digesting %d fruits" % p.digesting_fruits.size())
	p._cast_fruit_skill(0, 1)
	await secs(0.5)
	check(QuestManager.is_quest_active(&"first_day") and main.tutorial.current_objective_idx >= 4, "tutorial advanced to raid step (idx %d)" % main.tutorial.current_objective_idx)

	# codex + satchel menus
	hud.open_menu("codex")
	await secs(0.5)
	await shot("05_codex")
	hud.close_menu()
	hud.open_menu("satchel")
	await secs(0.4)
	await shot("06_satchel")
	hud.close_menu()
	hud.open_menu("market")
	await secs(0.4)
	await shot("07_market")
	hud.close_menu()

	# ── expedition ─────────────────────────────────────────────────────────
	var gate: ExpeditionGate = main.get_node("World/Gate")
	gate.interact(p)
	await secs(1.0)
	check(dm.current_phase == WindfallTypes.TimeOfDay.EXPEDITION, "gate starts expedition")
	await secs(2.0)
	await shot("08_expedition")

	# ── night raid ─────────────────────────────────────────────────────────
	gate.interact(p)
	await secs(0.5)
	check(dm.current_phase == WindfallTypes.TimeOfDay.NIGHT_RAID and dm.is_raid_active, "dusk return starts night raid")
	p.global_position = Vector2(940, 560)
	# refresh the stomach so the combo is visible mid-raid
	p.digesting_fruits.clear()
	for sid in [&"voltberry", &"brinemelon", &"cinderapple"]:
		p.eat_fruit(FruitRegistry.create_fruit_instance(sid, WindfallTypes.Ripeness.PRIME))
		await secs(0.35)
	# let raiders arrive, fight with skills
	var t0 := Time.get_ticks_msec()
	var min_fps := 999.0
	var fps_samples: Array = []
	var cpu_samples: Array = []
	var shots_taken := 0
	while (dm.is_raid_active) and Time.get_ticks_msec() - t0 < 70000:
		await secs(0.6)
		fps_samples.append(Engine.get_frames_per_second())
		cpu_samples.append((Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
		var enemies := tree.get_nodes_in_group("enemies")
		if not enemies.is_empty():
			var e: Node2D = enemies[0]
			var to := (e.global_position - p.global_position)
			if to.length() > 150.0:
				p.global_position = e.global_position - to.normalized() * 120.0
			p.facing_direction = (e.global_position - p.global_position).normalized()
			p._skill_cooldowns = {1: 0.0, 2: 0.0, 3: 0.0}
			p._cast_fruit_skill(0, 1)
			p._cast_fruit_skill(2, 3)
			p._start_tool_attack()
			if shots_taken == 0 and Time.get_ticks_msec() - t0 > 5000:
				await secs(0.12)
				await shot("02_night_raid")
				await shot("04_stomach_combo")
				shots_taken = 1
			if Time.get_ticks_msec() - t0 > 7000:
				for en in enemies:
					if (en as Node2D).global_position.distance_to(p.global_position) < 200.0:
						en.take_damage(18.0)
		p.heal(50.0)
	fps_samples.sort()
	cpu_samples.sort()
	if not cpu_samples.is_empty():
		log_line("raid CPU script+physics per frame: median %.2f ms, worst %.2f ms (budget 16.6 ms)" % [cpu_samples[cpu_samples.size() / 2], cpu_samples[-1]])
	log_line("raid fps (software GL in CI): median %.0f, min %.0f" % [fps_samples[fps_samples.size() / 2] if not fps_samples.is_empty() else 0.0, fps_samples[0] if not fps_samples.is_empty() else 0.0])
	check(not dm.is_raid_active, "raid cleared")
	await secs(1.0)
	check(not QuestManager.is_quest_active(&"first_day"), "tutorial completed")

	# ── sleep → next day (autosave) ────────────────────────────────────────
	SaveManager.delete_save()
	var door: BedProp = main.get_node("World/Bed")
	door.interact(p)
	await secs(3.5)
	check(dm.day_number == 2 and dm.current_phase == WindfallTypes.TimeOfDay.MORNING, "slept into Day 2 morning")
	check(SaveManager.has_save(), "autosave written on new day")
	await shot("09_new_day")
	log_line("gold at save: %d" % main.market_manager.gold)


## Second boot: Continue path restores state.
func run_continue(main: WindfallMain, t: SceneTree, expect_gold: int) -> void:
	tree = t
	await secs(1.0)
	check(main.day_manager.day_number == 2, "continue restores day (got %d)" % main.day_manager.day_number)
	check(main.market_manager.gold == expect_gold, "continue restores gold (%d)" % main.market_manager.gold)
