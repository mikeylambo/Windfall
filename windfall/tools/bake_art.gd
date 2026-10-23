extends SceneTree

## Bakes every WINDFALL sprite into res://assets/art as PNG sheets.
##   godot --headless --path windfall -s res://tools/bake_art.gd
## Pass `-- only=<group>` to rebake a single group (characters, trees, world, props, icons, ui, fx).
## The output is plain PNG, so any sprite can later be hand-edited in Aseprite.

const OUT := "res://assets/art/"
const K := 2  # world sprites: 1 texel = 2 world px


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	var t0 := Time.get_ticks_msec()
	var groups := ["characters", "trees", "world", "props", "icons", "ui", "fx", "theme"]
	for g in groups:
		if only != "" and g != only:
			continue
		var t := Time.get_ticks_msec()
		call("bake_" + g)
		print("baked %-10s %5d ms" % [g, Time.get_ticks_msec() - t])
	print("bake complete in %d ms" % (Time.get_ticks_msec() - t0))
	quit()


func _save(c: PixelCanvas, name: String, k: int = K) -> void:
	c.save(ProjectSettings.globalize_path(OUT + name + ".png"), k)


# ── characters ──────────────────────────────────────────────────────────────

func bake_characters() -> void:
	var specs := {
		"rootborn": CharacterPainter.spec_rootborn(),
		"wren": CharacterPainter.spec_wren(),
		"hesper": CharacterPainter.spec_hesper(),
		"poacher": CharacterPainter.spec_poacher(),
		"reaper": CharacterPainter.spec_reaper(),
	}
	var p2 := CharacterPainter.spec_rootborn()
	p2["coat"] = WPal.CLOTH_TEAL
	specs["rootborn_p2"] = p2
	var p3 := CharacterPainter.spec_rootborn()
	p3["coat"] = WPal.CLOTH_ROSE
	specs["rootborn_p3"] = p3
	for key in specs:
		_save(_humanoid_sheet(specs[key]), "characters/" + key)
	_save(CreaturePainter.gnawer_sheet(), "characters/gnawer")


func _humanoid_sheet(s: Dictionary) -> PixelCanvas:
	var D := CharacterPainter.Dir
	var frames: Array = []
	var dirs := [D.DOWN, D.UP, D.SIDE]
	var blank := PixelCanvas.new(CharacterPainter.FW, CharacterPainter.FH)

	# rows 0-2: idle (2 frames)
	for d in dirs:
		frames += _row([{"dir": d}, {"dir": d, "bob": 1}], blank)
	# rows 3-5: walk (4)
	for d in dirs:
		frames += _row([
			{"dir": d, "step": -1, "arm": 1.0},
			{"dir": d, "step": 0, "bob": -1},
			{"dir": d, "step": 1, "arm": -1.0},
			{"dir": d, "step": 0, "bob": -1},
		], blank)
	# rows 6-8: attack (3) anticipation / strike / follow-through
	for d in dirs:
		var reach := Vector2i(0, 2) if d == D.DOWN else (Vector2i(0, -3) if d == D.UP else Vector2i(3, -1))
		var lean := 1 if d == D.SIDE else 0
		frames += _row([
			{"dir": d, "bob": 1, "arm": -1.0, "lean": -lean},
			{"dir": d, "reach": reach, "lean": lean, "step": 1},
			{"dir": d, "reach": reach / 2, "bob": 1},
		], blank)
	# row 9: roll (4)
	var roll: Array = []
	for f in 4:
		roll.append(CharacterPainter.paint_roll(s, f))
	frames += roll
	# rows 10-12: eat (2)
	for d in dirs:
		frames += _row([{"dir": d, "eat": true}, {"dir": d, "eat": true, "bob": 1}], blank)
	# rows 13-15: cast (2)
	for d in dirs:
		frames += _row([{"dir": d, "arms_up": true}, {"dir": d, "arms_up": true, "bob": -1}], blank)
	# rows 16-18: hurt (1)
	for d in dirs:
		frames += _row([{"dir": d, "hurt": true, "lean": -1 if d == D.SIDE else 0}], blank)
	# row 19: collapse (2)
	frames += [CharacterPainter.paint_collapse(s, 0), CharacterPainter.paint_collapse(s, 1), blank, blank]

	return PixelCanvas.pack(_painted(frames, s), 4)


func _row(poses: Array, blank: PixelCanvas) -> Array:
	var out: Array = poses.duplicate()
	while out.size() < 4:
		out.append(blank)
	return out


func _painted(frames: Array, s: Dictionary) -> Array:
	var out: Array = []
	for f in frames:
		if f is Dictionary:
			out.append(CharacterPainter.paint(s, f))
		else:
			out.append(f)
	return out


func bake_trees() -> void:
	for st in [3, 4, 5, 6]:
		_save(TreePainter.trunk(st), "trees/trunk_%d" % st)
	for fam in 8:
		for st in range(1, 7):
			_save(TreePainter.canopy(st, fam), "trees/canopy_%d_%d" % [st, fam])
		_save(PixelCanvas.pack(TreePainter.fruit_frames(fam), 4), "trees/fruit_%d" % fam)


func bake_world() -> void:
	_save(WorldPainter.ground(), "world/ground", 1)
	for soil in 6:
		_save(WorldPainter.soil_bed(soil, false), "world/soil_%d" % soil)
		_save(WorldPainter.soil_bed(soil, true), "world/soil_%d_wet" % soil)


func bake_props() -> void:
	_save(PropPainter.farmhouse(), "props/farmhouse")
	_save(PropPainter.farmhouse_windows(), "props/farmhouse_windows")
	_save(PropPainter.market_stall(), "props/market_stall")
	_save(PropPainter.crate_prop(), "props/crate")
	_save(PropPainter.barrel(), "props/barrel")
	_save(PropPainter.fence_h(), "props/fence_h")
	_save(PropPainter.fence_post(), "props/fence_post")
	for v in 4:
		_save(PropPainter.hedge(v), "props/hedge_%d" % v)
		_save(PropPainter.border_tree(v), "props/border_tree_%d" % v)
		_save(PropPainter.bush(v), "props/bush_%d" % v)
		_save(PropPainter.rock(v), "props/rock_%d" % v)
	_save(PropPainter.lantern(), "props/lantern")
	_save(PropPainter.gate(), "props/gate")
	_save(PropPainter.beehive(), "props/beehive")
	_save(PropPainter.reeds(), "props/reeds")
	_save(PropPainter.stump(), "props/stump")
	_save(PropPainter.scarecrow(), "props/scarecrow")
	_save(PropPainter.overgrown_plot(), "props/overgrown_plot")
	_save(PropPainter.compost_bin(), "props/compost_bin")
	_save(PropPainter.waystation_ring(), "props/waystation_ring")
	_save(PropPainter.waystation_shrine(), "props/waystation_shrine")
	_save(PropPainter.well(), "props/well")
	for v in 4:
		_save(PropPainter.flower_patch(v), "props/flowers_%d" % v)
	_save(PropPainter.blob_shadow(7, 3), "props/shadow_small")
	_save(PropPainter.blob_shadow(12, 5), "props/shadow_medium")
	_save(PropPainter.blob_shadow(22, 8), "props/shadow_large")


func bake_icons() -> void:
	var k := 3
	_save(IconPainter.heart(), "icons/heart", k)
	_save(IconPainter.bolt(), "icons/bolt", k)
	_save(IconPainter.coin(), "icons/coin", k)
	_save(IconPainter.sun(), "icons/sun", k)
	_save(IconPainter.sunset(), "icons/sunset", k)
	_save(IconPainter.moon(), "icons/moon", k)
	_save(IconPainter.satchel(), "icons/satchel", k)
	_save(IconPainter.codex(), "icons/codex", k)
	_save(IconPainter.skull(), "icons/skull", k)
	_save(IconPainter.stomach(), "icons/stomach", k)
	_save(IconPainter.star(), "icons/star", k)
	_save(IconPainter.lock(), "icons/lock", k)
	for s in 4:
		_save(IconPainter.season(s), "icons/season_%d" % s, k)
	for t in 5:
		_save(IconPainter.tool_icon(t), "icons/tool_%d" % t, k)
	for fam in 8:
		_save(IconPainter.element_sigil(fam), "icons/element_%d" % fam, k)
		_save(IconPainter.fruit_icon(fam), "icons/fruit_%d" % fam, k)
		_save(IconPainter.seed_icon(fam), "icons/seed_%d" % fam, k)
	var registry: Node = load("res://scripts/Windfall/FruitRegistry.gd").new()
	for sid in registry.species.keys():
		var fam2 := int(registry.species[sid].get("family", 0))
		_save(SpeciesIconPainter.icon(sid, fam2), "icons/species/%s" % sid, k)


func bake_ui() -> void:
	var k := 3
	_save(UIPainter.panel_wood(), "ui/panel_wood", k)
	_save(UIPainter.panel_vine(), "ui/panel_vine", k)
	_save(UIPainter.panel_paper(), "ui/panel_paper", k)
	_save(UIPainter.panel_dark(), "ui/panel_dark", k)
	for st in 4:
		_save(UIPainter.slot(st), "ui/slot_%d" % st, k)
		_save(UIPainter.button(st), "ui/button_%d" % st, k)
	_save(UIPainter.bar_frame(), "ui/bar_frame", k)
	_save(UIPainter.bar_fill(WPal.RED.slice(1, 5)), "ui/bar_hp", k)
	_save(UIPainter.bar_fill(WPal.ELEMENT[4].slice(0, 4)), "ui/bar_stamina", k)
	_save(UIPainter.bar_fill(WPal.GOLD.slice(1, 5)), "ui/bar_gold", k)
	_save(UIPainter.ring(Color(1, 1, 1, 1)), "ui/ring", k)
	_save(UIPainter.ring(Color(1, 1, 1, 0.18)), "ui/ring_bg", k)
	_save(UIPainter.jar(), "ui/jar", k)
	_save(UIPainter.keycap(), "ui/keycap", k)
	_save(UIPainter.chip(), "ui/chip", k)
	_save(UIPainter.bubble(), "ui/bubble")
	_save(UIPainter.harvest_bar(), "ui/harvest_bar")
	_save(UIPainter.harvest_cursor(), "ui/harvest_cursor")
	_save(UIPainter.focus_brackets(), "ui/focus")
	_save(UIPainter.world_hp_frame(), "ui/hp_world_frame")
	_save(UIPainter.world_hp_fill(), "ui/hp_world_fill")
	UIPainter.vignette().save_png(ProjectSettings.globalize_path(OUT + "ui/vignette.png"))


func bake_fx() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "fx"))
	var glow := FxPainter.soft_glow(64)
	glow.save_png(ProjectSettings.globalize_path(OUT + "fx/glow.png"))
	_save(FxPainter.pixel_glow(16), "fx/pixel_glow")
	_save(FxPainter.dot(2), "fx/dot")
	_save(FxPainter.dot(4), "fx/dot4")
	_save(FxPainter.spark(), "fx/spark")
	_save(FxPainter.shard(), "fx/shard")
	_save(FxPainter.leaf(), "fx/leaf")
	_save(FxPainter.dust_frames(), "fx/dust")
	_save(FxPainter.smoke_frames(), "fx/smoke")
	_save(FxPainter.poof_frames(), "fx/poof")
	_save(FxPainter.sparkle_frames(), "fx/sparkle")
	_save(FxPainter.slash_frames(3, 1.6), "fx/slash_0")
	_save(FxPainter.slash_frames(5, 2.6), "fx/slash_1")
	_save(FxPainter.slash_frames(4, 1.2), "fx/slash_2")
	_save(FxPainter.shock_ring(), "fx/ring")
	_save(FxPainter.butterfly_frames(), "fx/butterfly")
	_save(FxPainter.ground_ring(), "fx/ground_ring")
	_save(FxPainter.blight_overlay(), "fx/blight")
	_save(FxPainter.petal(), "fx/petal")
	_save(FxPainter.snowflake(), "fx/snowflake")
	for fam in 8:
		_save(FxPainter.projectile(fam), "fx/proj_%d" % fam)
		_save(FxPainter.quickroot(fam), "fx/quickroot_%d" % fam)


## Theme references the baked PNGs, so run after an import pass:
##   godot --headless --import && godot --headless -s res://tools/bake_art.gd -- only=theme
func bake_theme() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui"))
	var err := ResourceSaver.save(UITheme.build(), "res://assets/ui/windfall_theme.tres")
	print("theme saved: ", error_string(err))
