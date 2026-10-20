extends Area2D
class_name OrchardPlot2D

signal plot_harvested(plot: OrchardPlot2D, fruit_instance: Dictionary)
signal plot_tended(plot: OrchardPlot2D, action_name: String)

@export var plot_index: int = 0
@export var soil_type: int = WindfallTypes.SoilType.LOAM

var tree_stage: int = WindfallTypes.TreeStage.EMPTY
var planted_species_id: StringName = &""
var grafted_species_id: StringName = &""

var growth_timer: float = 0.0
var stage_duration: float = 24.0 # Time per stage in real/day seconds
var water_level: float = 60.0
var is_pruned: bool = false
var has_blight: bool = false

# Fruit on tree
var current_ripeness: int = WindfallTypes.Ripeness.UNRIPE
var fruit_count: int = 0
var ripeness_progress: float = 0.0 # 0.0 to 1.0
var windfall_compost_value: int = 0

var is_focused: bool = false
var _anim_time: float = 0.0
var is_wild: bool = false

# Presentation
const FRUIT_SPOTS := {
	4: [Vector2(-10, -50), Vector2(9, -56), Vector2(0, -42)],
	5: [Vector2(-22, -76), Vector2(18, -84), Vector2(-4, -92), Vector2(10, -64), Vector2(-14, -60)],
	6: [Vector2(-26, -84), Vector2(22, -92), Vector2(-4, -104), Vector2(14, -70), Vector2(-16, -66)],
}
var _soil: Sprite2D
var _trunk: Sprite2D
var _crown: Node2D
var _canopy: Sprite2D
var _fruits: Array[Sprite2D] = []
var _focus: NinePatchRect
var _bar: Node2D
var _cursor: Sprite2D
var _glow: Sprite2D
var _trunk_body: StaticBody2D
var _shown_stage: int = -1
var _shown_fruit: int = -1
var _shown_ripe: int = -1
var _shown_wet: int = -1
var _sparkle_timer: float = 0.0

# Timing tap mini-game for Prime harvest
var is_timing_harvest: bool = false
var timing_cursor: float = 0.0 # 0.0 to 1.0 oscillating
var timing_dir: float = 1.0


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	col.shape = shape
	add_child(col)
	_build_visuals()


func _process(delta: float) -> void:
	_anim_time += delta

	# Process tree growth and ripening
	if tree_stage != WindfallTypes.TreeStage.EMPTY:
		_process_growth(delta)

	if is_timing_harvest:
		timing_cursor += timing_dir * 2.2 * delta
		if timing_cursor >= 1.0:
			timing_cursor = 1.0
			timing_dir = -1.0
		elif timing_cursor <= 0.0:
			timing_cursor = 0.0
			timing_dir = 1.0

	_update_visuals(delta)


func _process_growth(delta: float) -> void:
	# Soil affinity multiplier
	var sp := FruitRegistry.get_species(planted_species_id)
	var pref_soil: int = int(sp.get("soil_pref", WindfallTypes.SoilType.LOAM))
	var growth_speed := 1.0
	if pref_soil == soil_type:
		growth_speed = 1.4
	if water_level > 20.0:
		growth_speed *= 1.2
		water_level = maxf(water_level - delta * 0.4, 0.0)

	if tree_stage < WindfallTypes.TreeStage.MATURE:
		growth_timer += delta * growth_speed
		if growth_timer >= stage_duration:
			growth_timer = 0.0
			tree_stage += 1
			if tree_stage == WindfallTypes.TreeStage.MATURE:
				_bear_fruit()
	else:
		# Ripening cycle on mature / ancient trees
		if fruit_count > 0:
			ripeness_progress += (delta * 0.035 * growth_speed)
			if ripeness_progress < 0.35:
				current_ripeness = WindfallTypes.Ripeness.UNRIPE
			elif ripeness_progress < 0.75:
				current_ripeness = WindfallTypes.Ripeness.RIPE
			elif ripeness_progress < 0.95:
				current_ripeness = WindfallTypes.Ripeness.PRIME
			else:
				# Falls as Windfall
				current_ripeness = WindfallTypes.Ripeness.WINDFALL


func plant_seed(species_id: StringName) -> bool:
	if tree_stage != WindfallTypes.TreeStage.EMPTY:
		return false

	planted_species_id = species_id
	tree_stage = WindfallTypes.TreeStage.SEED
	growth_timer = 0.0
	water_level = 80.0
	is_pruned = false
	has_blight = false
	fruit_count = 0
	WindfallSound.play_plant()
	plot_tended.emit(self, "Planted " + FruitRegistry.get_species(species_id).get("name", "Seed"))
	return true


func water_plot() -> void:
	water_level = minf(water_level + 50.0, 100.0)
	FX.burst(global_position + Vector2(0, -6), "fx/dot4", WPal.WATER[4], 16, 90.0, 0.5, Vector2(0, 220), 60.0, Vector2.UP, Vector2(0.8, 1.5), "world")
	FX.popup("WATERED", global_position + Vector2(0, -40), WPal.WATER[4], 13)
	WindfallSound.play_spell(WindfallTypes.Family.TIDE)
	plot_tended.emit(self, "Watered Plot")


func prune_tree() -> void:
	if tree_stage >= WindfallTypes.TreeStage.SAPLING and not is_pruned:
		is_pruned = true
		WindfallSound.play_swing()
		FX.burst(global_position + Vector2(0, -60), "fx/leaf", Color.WHITE, 12, 90.0, 0.9, Vector2(0, 90), 180.0, Vector2.UP, Vector2(1, 1.5), "world")
		FX.popup("PRUNED +QUALITY", global_position + Vector2(0, -40), WPal.LEAF[5], 13)
		plot_tended.emit(self, "Pruned Branches (+Quality)")


func interact(player: RootbornPlayer) -> void:
	# If timing harvest is active, player presses E / Interact to tap the sweet spot!
	if is_timing_harvest:
		_complete_timing_harvest(player)
		return

	# If tree has ripe fruit, start harvest
	if tree_stage >= WindfallTypes.TreeStage.MATURE and fruit_count > 0:
		if current_ripeness == WindfallTypes.Ripeness.WINDFALL:
			# Gather windfall directly
			_harvest_fruit(player, WindfallTypes.Ripeness.WINDFALL)
		else:
			# Start timing tap mini-game!
			is_timing_harvest = true
			timing_cursor = 0.0
			timing_dir = 1.0
		return

	# If empty, plant selected seed from player satchel
	if tree_stage == WindfallTypes.TreeStage.EMPTY:
		if player.satchel_seeds.get(player.selected_seed_id, 0) > 0:
			player.satchel_seeds[player.selected_seed_id] -= 1
			player.satchel_changed.emit()
			plant_seed(player.selected_seed_id)
		return

	# If holding Watering Can, water plot
	if player.current_tool == WindfallTypes.ToolType.WATERING_CAN:
		water_plot()
	# If holding Pruning Shears, prune tree
	elif player.current_tool == WindfallTypes.ToolType.PRUNING_SHEARS and not is_pruned:
		prune_tree()
	else:
		# Default water
		water_plot()


func _complete_timing_harvest(player: RootbornPlayer) -> void:
	is_timing_harvest = false
	var final_ripeness: int = current_ripeness

	# Sweet spot is center 0.40 to 0.60
	var bar_pos := global_position + Vector2(0, _bar.position.y)
	if timing_cursor >= 0.38 and timing_cursor <= 0.62:
		final_ripeness = WindfallTypes.Ripeness.PRIME
		WindfallSound.play_prime_timing()
		FX.popup("PRIME!", bar_pos + Vector2(0, -14), WPal.GOLD[4], 26, 34.0, 1.0)
		FX.burst(bar_pos, "fx/spark", WPal.GOLD[4], 26, 180.0, 0.6, Vector2(0, 120), 180.0, Vector2.UP, Vector2(1, 2.5), "overlay", Color(0, 0, 0, 0), true)
		FX.ring(bar_pos, WPal.GOLD[3], 60.0, 0.4)
		FX.flash_light(bar_pos, WPal.GOLD[3], 90.0, 0.5)
		FX.punch(0.06)
		FX.shake(0.15)
	else:
		final_ripeness = WindfallTypes.Ripeness.RIPE
		WindfallSound.play_harvest()
		FX.popup("Ripe", bar_pos + Vector2(0, -10), WPal.CREAM[3], 15)

	_harvest_fruit(player, final_ripeness)


func _harvest_fruit(player: RootbornPlayer, ripeness: int) -> void:
	var traits: Array = []
	if is_pruned and randf() < 0.4:
		traits.append(FruitRegistry.roll_random_trait())

	var fruit_inst := FruitRegistry.create_fruit_instance(planted_species_id, ripeness, traits)
	player.satchel_fruits.append(fruit_inst)
	player.satchel_changed.emit()

	fruit_count -= 1
	if fruit_count <= 0:
		# Reset ripening cycle for next crop
		ripeness_progress = 0.0
		fruit_count = 3
		is_pruned = false

	_fly_fruit_to(player)
	plot_harvested.emit(self, fruit_inst)


func _bear_fruit() -> void:
	fruit_count = 4 if tree_stage == WindfallTypes.TreeStage.ANCIENT else 3
	ripeness_progress = 0.45 # Starts at early ripe
	current_ripeness = WindfallTypes.Ripeness.RIPE


func set_focused(val: bool) -> void:
	is_focused = val


# ── Presentation ───────────────────────────────────────────────────────────

func _build_visuals() -> void:
	_soil = Sprite2D.new()
	_soil.z_index = -5
	_soil.position = Vector2(0, 6)
	add_child(_soil)
	_trunk = Art.sprite("trees/trunk_5", 1, 1, Vector2(48, 120))
	add_child(_trunk)
	_crown = Node2D.new()
	add_child(_crown)
	_canopy = Art.sprite("trees/canopy_5_0", 1, 1, Vector2(48, 120))
	_crown.add_child(_canopy)
	_focus = NinePatchRect.new()
	_focus.texture = Art.tex("ui/focus")
	_focus.patch_margin_left = 12
	_focus.patch_margin_top = 12
	_focus.patch_margin_right = 12
	_focus.patch_margin_bottom = 12
	_focus.size = Vector2(92, 76)
	_focus.position = Vector2(-46, -32)
	_focus.z_index = -4
	_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus.visible = false
	add_child(_focus)
	_bar = Node2D.new()
	_bar.z_index = 40
	_bar.visible = false
	add_child(_bar)
	var bar_bg := Art.sprite("ui/harvest_bar")
	bar_bg.centered = true
	bar_bg.offset = Vector2.ZERO
	_bar.add_child(bar_bg)
	_cursor = Art.sprite("ui/harvest_cursor")
	_cursor.centered = true
	_cursor.offset = Vector2.ZERO
	_bar.add_child(_cursor)


func _update_visuals(delta: float) -> void:
	var fam: int = int(FruitRegistry.get_species(planted_species_id).get("family", 0)) if planted_species_id != &"" else 0
	var wet := 1 if water_level > 20.0 else 0
	if is_wild:
		_soil.visible = false
	elif wet != _shown_wet:
		_shown_wet = wet
		_soil.texture = Art.tex("world/soil_%d%s" % [soil_type, "_wet" if wet else ""])

	if tree_stage != _shown_stage:
		var grew := _shown_stage >= 0 and tree_stage > _shown_stage
		_shown_stage = tree_stage
		_shown_fruit = -1
		_apply_stage(fam)
		if grew:
			FX.burst(global_position + Vector2(0, -30), "fx/leaf", Color.WHITE, 10, 80.0, 0.8, Vector2(0, 60), 180.0, Vector2.UP, Vector2(1, 1.5), "world")
			FX.sparkle(global_position + Vector2(0, -40), WPal.LEAF[5])
			var t := _crown.create_tween()
			_crown.scale = Vector2(0.85, 0.85)
			t.tween_property(_crown, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var shown_fruit := fruit_count if tree_stage >= WindfallTypes.TreeStage.MATURE else 0
	if shown_fruit != _shown_fruit or current_ripeness != _shown_ripe:
		_shown_fruit = shown_fruit
		_shown_ripe = current_ripeness
		_rebuild_fruit(fam)

	# gentle wind sway on the crown; fruit rides along
	_crown.skew = sin(_anim_time * 1.4 + plot_index * 1.3 + global_position.x * 0.01) * 0.035
	_crown.position.x = sin(_anim_time * 1.4 + plot_index * 1.3) * 0.8

	# ripe fruit glints occasionally
	for f in _fruits:
		if f.frame > 0:
			f.set_meta("gt", float(f.get_meta("gt", 0.0)) + delta)
			if f.get_meta("gt") > 0.07:
				f.set_meta("gt", 0.0)
				f.frame = (f.frame + 1) % 4
		elif current_ripeness >= WindfallTypes.Ripeness.RIPE and current_ripeness != WindfallTypes.Ripeness.WINDFALL and randf() < delta * 0.35:
			f.frame = 1

	# watered sparkle
	_sparkle_timer -= delta
	if water_level > 40.0 and _sparkle_timer <= 0.0 and not is_wild:
		_sparkle_timer = randf_range(0.8, 1.8)
		FX.sparkle(global_position + Vector2(randf_range(-30, 30), randf_range(-10, 24)), WPal.WATER[5])

	# focus brackets & harvest bar
	if _focus.visible != is_focused:
		_focus.visible = is_focused
	if _focus.visible:
		_focus.modulate.a = 0.6 + sin(_anim_time * 6.0) * 0.4
	if _bar.visible != is_timing_harvest:
		_bar.visible = is_timing_harvest
	if is_timing_harvest:
		var top := -60.0 if tree_stage < WindfallTypes.TreeStage.MATURE else (-150.0 if tree_stage == WindfallTypes.TreeStage.MATURE else -170.0)
		_bar.position = Vector2(0, top)
		_cursor.position = Vector2(lerpf(-46.0, 46.0, timing_cursor), 0)


func _apply_stage(fam: int) -> void:
	var st := tree_stage
	_trunk.visible = st >= WindfallTypes.TreeStage.SAPLING
	if _trunk.visible:
		_trunk.texture = Art.tex("trees/trunk_%d" % st)
	_canopy.visible = st != WindfallTypes.TreeStage.EMPTY
	if _canopy.visible:
		_canopy.texture = Art.tex("trees/canopy_%d_%d" % [st, fam])
	# trunk blocks movement once the tree is substantial
	if st >= WindfallTypes.TreeStage.YOUNG and _trunk_body == null:
		_trunk_body = StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 9.0 if st < WindfallTypes.TreeStage.ANCIENT else 13.0
		cs.shape = circ
		_trunk_body.add_child(cs)
		add_child(_trunk_body)
	if st == WindfallTypes.TreeStage.ANCIENT and _glow == null:
		_glow = FX.glow(self, WPal.element(fam, 3), 90.0, Vector2(0, -80), 0.3, 0.55)


func _rebuild_fruit(fam: int) -> void:
	for f in _fruits:
		f.queue_free()
	_fruits.clear()
	if _shown_fruit <= 0:
		return
	var spots: Array = FRUIT_SPOTS.get(mini(tree_stage, 6), FRUIT_SPOTS[5])
	var tint := Color.WHITE
	match current_ripeness:
		WindfallTypes.Ripeness.UNRIPE: tint = Color(0.75, 0.95, 0.6)
		WindfallTypes.Ripeness.PRIME: tint = Color(1.12, 1.08, 1.0)
		WindfallTypes.Ripeness.WINDFALL: tint = Color(0.7, 0.6, 0.55)
	for i in mini(_shown_fruit, spots.size()):
		var f := Art.sprite("trees/fruit_%d" % fam, 4, 1)
		f.centered = true
		f.offset = Vector2.ZERO
		f.self_modulate = tint
		if current_ripeness == WindfallTypes.Ripeness.WINDFALL:
			# dropped fruit lies on the ground around the trunk
			add_child(f)
			f.position = Vector2(-22 + i * 15, 18 + (i % 2) * 6)
			f.z_index = -3
		else:
			_crown.add_child(f)
			f.position = spots[i]
		_fruits.append(f)


func _fly_fruit_to(player: Node2D) -> void:
	if FX.overlay == null or player == null:
		return
	var fam: int = int(FruitRegistry.get_species(planted_species_id).get("family", 0))
	var f := Art.sprite("trees/fruit_%d" % fam, 4, 1)
	f.centered = true
	f.offset = Vector2.ZERO
	FX.overlay.add_child(f)
	var start := global_position + Vector2(0, -70)
	f.global_position = start
	var t := f.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(player):
			var end := player.global_position + Vector2(0, -24)
			f.global_position = start.lerp(end, k) + Vector2(0, -sin(k * PI) * 40.0)
			f.scale = Vector2.ONE * (1.4 - k * 0.6), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_callback(f.queue_free)


func get_prompt() -> String:
	if is_timing_harvest:
		return "Tap in the gold zone!"
	var sp_name: String = FruitRegistry.get_species(planted_species_id).get("name", "Fruit")
	if tree_stage >= WindfallTypes.TreeStage.MATURE and fruit_count > 0:
		return ("Gather windfall %s" if current_ripeness == WindfallTypes.Ripeness.WINDFALL else "Harvest %s") % sp_name
	if tree_stage == WindfallTypes.TreeStage.EMPTY:
		if is_wild:
			return ""
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return ""
		var p: RootbornPlayer = players[0]
		var sid := p.selected_seed_id
		if int(p.satchel_seeds.get(sid, 0)) > 0:
			return "Plant %s seed" % FruitRegistry.get_species(sid).get("name", "")
		return "Empty plot · no seeds armed"
	var pl := get_tree().get_first_node_in_group("player") as RootbornPlayer
	if pl and pl.current_tool == WindfallTypes.ToolType.PRUNING_SHEARS and not is_pruned and tree_stage >= WindfallTypes.TreeStage.SAPLING:
		return "Prune %s" % sp_name
	return "Water %s" % sp_name
