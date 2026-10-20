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

	queue_redraw()


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
	WindfallSound.play_spell(WindfallTypes.Family.TIDE)
	plot_tended.emit(self, "Watered Plot")


func prune_tree() -> void:
	if tree_stage >= WindfallTypes.TreeStage.SAPLING and not is_pruned:
		is_pruned = true
		WindfallSound.play_swing()
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
	if timing_cursor >= 0.38 and timing_cursor <= 0.62:
		final_ripeness = WindfallTypes.Ripeness.PRIME
		WindfallSound.play_prime_timing()
	else:
		final_ripeness = WindfallTypes.Ripeness.RIPE
		WindfallSound.play_harvest()

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

	plot_harvested.emit(self, fruit_inst)


func _bear_fruit() -> void:
	fruit_count = 4 if tree_stage == WindfallTypes.TreeStage.ANCIENT else 3
	ripeness_progress = 0.45 # Starts at early ripe
	current_ripeness = WindfallTypes.Ripeness.RIPE


func set_focused(val: bool) -> void:
	is_focused = val


# ── Visual Rendering ───────────────────────────────────────────────────────────

func _draw() -> void:
	# 1. Soil tile
	var soil_col: Color = _get_soil_color()
	if water_level > 20.0:
		soil_col = soil_col.darkened(0.2)
	draw_rect(Rect2(-36, -36, 72, 72), soil_col)

	# Border
	var border_col := Color(0.25, 0.18, 0.12)
	if is_focused:
		border_col = Color(1.0, 0.95, 0.4)
	draw_rect(Rect2(-36, -36, 72, 72), border_col, false, 2.5)

	# Water puddle shimmer
	if water_level > 40.0:
		var w_alpha: float = (water_level / 100.0) * 0.3
		draw_circle(Vector2(12, 12), 10.0, Color(0.2, 0.6, 1.0, w_alpha))

	# 2. Tree drawing by stage
	match tree_stage:
		WindfallTypes.TreeStage.SEED:
			draw_circle(Vector2.ZERO, 5.0, Color(0.4, 0.25, 0.15))
			draw_line(Vector2.ZERO, Vector2(0, -8), Color(0.3, 0.8, 0.2), 2.0)
		WindfallTypes.TreeStage.SPROUT:
			draw_line(Vector2.ZERO, Vector2(0, -14), Color(0.25, 0.75, 0.2), 3.0)
			draw_circle(Vector2(-5, -12), 4.0, Color(0.3, 0.85, 0.3))
			draw_circle(Vector2(5, -12), 4.0, Color(0.3, 0.85, 0.3))
		WindfallTypes.TreeStage.SAPLING:
			draw_line(Vector2.ZERO, Vector2(0, -24), Color(0.45, 0.3, 0.15), 4.0)
			draw_circle(Vector2(0, -26), 12.0, Color(0.2, 0.6, 0.2))
		WindfallTypes.TreeStage.YOUNG:
			draw_line(Vector2.ZERO, Vector2(0, -32), Color(0.4, 0.25, 0.12), 6.0)
			draw_circle(Vector2(0, -34), 18.0, Color(0.18, 0.55, 0.18))
		WindfallTypes.TreeStage.MATURE, WindfallTypes.TreeStage.ANCIENT:
			_draw_mature_tree()

	# 3. Harvest Timing Mini-Game Bar
	if is_timing_harvest:
		_draw_timing_bar()


func _draw_mature_tree() -> void:
	var sp := FruitRegistry.get_species(planted_species_id)
	var fam: int = int(sp.get("family", WindfallTypes.Family.STORM))
	var fruit_col: Color = WindfallTypes.FAMILY_COLORS.get(fam, Color.RED)

	# Trunk
	draw_line(Vector2(0, 10), Vector2(0, -22), Color(0.38, 0.22, 0.1), 8.0)

	# Canopy with sway
	var sway: float = sin(_anim_time * 2.5 + plot_index) * 3.0
	draw_circle(Vector2(sway, -32), 24.0, Color(0.16, 0.5, 0.16))
	draw_circle(Vector2(sway + 10, -26), 18.0, Color(0.2, 0.58, 0.2))
	draw_circle(Vector2(sway - 10, -26), 18.0, Color(0.2, 0.58, 0.2))

	# Glowing ripe fruits swaying on branches!
	if fruit_count > 0:
		var fruit_glow := 1.0 + sin(_anim_time * 5.0) * 0.25
		for f_idx in fruit_count:
			var angle: float = (float(f_idx) / float(fruit_count)) * TAU
			var f_pos := Vector2(sway, -28) + Vector2(cos(angle) * 16.0, sin(angle) * 12.0)
			# Outer element glow
			draw_circle(f_pos, 6.0 * fruit_glow, fruit_col)
			# Ripeness center pip
			var rip_col: Color = WindfallTypes.RIPENESS_COLORS.get(current_ripeness, Color.WHITE)
			draw_circle(f_pos, 3.0, rip_col)


func _draw_timing_bar() -> void:
	# Floating oscillating bar above plot: Green sweet spot in center!
	var bar_w := 64.0
	var bar_h := 8.0
	var bar_y := -60.0

	# Background bar
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.15, 0.85))
	# Green sweet spot (center 25%)
	var sweet_w := bar_w * 0.24
	draw_rect(Rect2(-sweet_w * 0.5, bar_y, sweet_w, bar_h), Color(0.2, 0.9, 0.3, 0.9))
	# Moving cursor
	var cursor_x := (-bar_w * 0.5) + (timing_cursor * bar_w)
	draw_line(Vector2(cursor_x, bar_y - 3), Vector2(cursor_x, bar_y + bar_h + 3), Color.WHITE, 2.5)


func _get_soil_color() -> Color:
	match soil_type:
		WindfallTypes.SoilType.ASH:
			return Color(0.3, 0.28, 0.26)
		WindfallTypes.SoilType.RIME:
			return Color(0.55, 0.65, 0.75)
		WindfallTypes.SoilType.SILT:
			return Color(0.38, 0.32, 0.22)
		WindfallTypes.SoilType.STORMGLASS:
			return Color(0.42, 0.35, 0.52)
		WindfallTypes.SoilType.LEY:
			return Color(0.52, 0.48, 0.32)
		_:
			return Color(0.32, 0.24, 0.16)
