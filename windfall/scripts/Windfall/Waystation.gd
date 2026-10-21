extends Area2D
class_name Waystation

## A clearing in the wilds. Plant a seed to grow a permanent waystation:
## after GROW_DAYS mornings it becomes a shrine where you can rest (full heal
## for the whole party, sets your respawn point) and gather one fruit a day.

const GROW_DAYS := 2

var index: int = 0
var species_id: StringName = &""
var days_grown: int = 0
var gathered_today: bool = false
var is_focused: bool = false
var _base: Sprite2D
var _tree: Node2D
var _glow: Sprite2D


func _ready() -> void:
	add_to_group("waystations")
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	col.shape = shape
	add_child(col)
	_base = Art.sprite("props/waystation_ring", 1, 1, Vector2(42, 40))
	_base.z_index = -3
	add_child(_base)
	_tree = Node2D.new()
	add_child(_tree)
	refresh()


func grown() -> bool:
	return species_id != &"" and days_grown >= GROW_DAYS


func _fam() -> int:
	return int(FruitRegistry.get_species(species_id).get("family", 0))


func refresh() -> void:
	for c in _tree.get_children():
		c.queue_free()
	if species_id == &"":
		_base.texture = Art.tex("props/waystation_ring")
		return
	if grown():
		_base.texture = Art.tex("props/waystation_shrine")
		_base.offset = Vector2(-42, -88)
		_base.z_index = 0
		var t := Art.sprite("trees/trunk_5", 1, 1, Vector2(48, 120))
		t.position = Vector2(46, -6)
		_tree.add_child(t)
		var c := Art.sprite("trees/canopy_5_%d" % _fam(), 1, 1, Vector2(48, 120))
		c.material = Art.sway_material(1.0, index * 2.0)
		t.add_child(c)
		if _glow == null:
			_glow = FX.glow(self, WPal.element(_fam(), 3), 70.0, Vector2(0, -40), 0.35, 0.6)
	else:
		var stage := 2 if days_grown == 0 else 3
		if stage >= 3:
			var tr := Art.sprite("trees/trunk_3", 1, 1, Vector2(48, 120))
			_tree.add_child(tr)
		var sp := Art.sprite("trees/canopy_%d_%d" % [stage, _fam()], 1, 1, Vector2(48, 120))
		_tree.add_child(sp)


func on_new_day() -> void:
	gathered_today = false
	if species_id != &"" and days_grown < GROW_DAYS:
		days_grown += 1
		refresh()


func get_prompt() -> String:
	if species_id == &"":
		var p := get_tree().get_first_node_in_group("player") as RootbornPlayer
		if p and int(p.satchel_seeds.get(p.selected_seed_id, 0)) > 0:
			return "Plant a waystation (%s seed)" % FruitRegistry.get_species(p.selected_seed_id).get("name", "")
		return "Waystation clearing · needs a seed"
	if not grown():
		return "Waystation growing (%d day%s left)" % [GROW_DAYS - days_grown, "" if GROW_DAYS - days_grown == 1 else "s"]
	return "Rest at the waystation" + ("" if gathered_today else " + gather fruit")


func interact(player: RootbornPlayer) -> void:
	if species_id == &"":
		var sid := player.selected_seed_id
		if int(player.satchel_seeds.get(sid, 0)) <= 0:
			HUDBus.toast("Arm a seed in the Satchel to plant a waystation.", WPal.CREAM[3])
			return
		player.satchel_seeds[sid] -= 1
		player.satchel_changed.emit()
		species_id = sid
		days_grown = 0
		refresh()
		WindfallSound.play_plant()
		FX.element_burst(_fam(), global_position + Vector2(0, -10), 1.0)
		FX.popup("WAYSTATION PLANTED", global_position + Vector2(0, -50), WPal.GOLD[4], 15)
		return
	if not grown():
		HUDBus.toast("It needs %d more morning(s) to take root." % (GROW_DAYS - days_grown), WPal.CREAM[3])
		return
	for p in get_tree().get_nodes_in_group("player"):
		p.heal(p.max_health)
		p.set_respawn_point(global_position + Vector2(0, 40))
	FX.element_burst(_fam(), global_position + Vector2(0, -40), 1.4)
	FX.popup("RESTED · RESPAWN SET", global_position + Vector2(0, -70), WPal.LEAF[5], 15)
	WindfallSound.play_prime_timing()
	if not gathered_today:
		gathered_today = true
		player.satchel_fruits.append(FruitRegistry.create_fruit_instance(species_id, WindfallTypes.Ripeness.RIPE))
		player.satchel_changed.emit()


func set_focused(val: bool) -> void:
	is_focused = val
	_base.self_modulate = Color(1.15, 1.1, 1.0) if val else Color.WHITE


func get_save_data() -> Dictionary:
	return {"species": String(species_id), "days": days_grown, "gathered": gathered_today}


func load_save_data(d: Dictionary) -> void:
	species_id = StringName(d.get("species", ""))
	days_grown = int(d.get("days", 0))
	gathered_today = bool(d.get("gathered", false))
	refresh()
