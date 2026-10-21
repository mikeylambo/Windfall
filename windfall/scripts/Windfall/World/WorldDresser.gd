extends Node
class_name WorldDresser

## Dresses the homestead from WorldLayout: ground, farmhouse, fences, hedges,
## the forest border that frames the map, lanterns, pond, hives and clutter.
## Everything with a footprint goes into the y-sorted world root.

var world: Node2D
var rng := RandomNumberGenerator.new()
var lantern_glows: Array[Sprite2D] = []
var window_glow: Sprite2D
var butterflies: CPUParticles2D
var fireflies: CPUParticles2D


func dress(world_root: Node2D, ground_parent: Node2D) -> void:
	world = world_root
	rng.seed = 1337
	_ground(ground_parent)
	_farmhouse()
	_orchard_fence()
	_yard_hedges()
	_border_forest()
	_pond()
	_lanterns()
	_homestead_life()
	_clutter()


func _add(path: String, pos: Vector2, foot := Vector2.ZERO, sway: float = 0.0) -> Sprite2D:
	var s := Art.sprite(path, 1, 1, foot)
	s.position = pos
	if sway > 0.0:
		s.material = Art.sway_material(sway, pos.x * 0.07)
	world.add_child(s)
	return s


func _blocker(pos: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = pos
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	b.add_child(cs)
	world.add_child(b)


func _ground(parent: Node2D) -> void:
	var g := Sprite2D.new()
	g.texture = Art.tex("world/ground")
	g.centered = false
	g.scale = Vector2(2, 2)
	g.z_index = -20
	parent.add_child(g)
	# deep backdrop beyond the map edge so nothing ever shows engine grey
	var back := ColorRect.new()
	back.color = WPal.GRASS_WILD[0]
	back.position = Vector2(-400, -400)
	back.size = WorldLayout.SIZE + Vector2(800, 800)
	back.z_index = -21
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(back)


func _farmhouse() -> void:
	var house := _add("props/farmhouse", WorldLayout.HOUSE, Vector2(104, 192))
	_blocker(WorldLayout.HOUSE + Vector2(0, -56), Vector2(168, 92))
	# chimney smoke
	var smoke := CPUParticles2D.new()
	smoke.texture = Art.tex("fx/dot4")
	smoke.position = Vector2(-104 + 78 * 2, -192 + 6 * 2)
	smoke.amount = 10
	smoke.lifetime = 2.6
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(12, -18)
	smoke.initial_velocity_min = 14.0
	smoke.initial_velocity_max = 24.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 4.0
	var grad := Gradient.new()
	grad.set_color(0, Color(WPal.STONE[4], 0.7))
	grad.set_color(1, Color(WPal.STONE[3], 0.0))
	smoke.color_ramp = grad
	house.add_child(smoke)
	# night window light (sprite mask + soft spill)
	window_glow = Art.sprite("props/farmhouse_windows", 1, 1, Vector2(104, 192))
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	window_glow.material = m
	window_glow.modulate.a = 0.0
	house.add_child(window_glow)
	FX.glow(house, Color("ffb860"), 70.0, Vector2(-62, -40), 0.0, 0.55)
	FX.glow(house, Color("ffb860"), 70.0, Vector2(42, -40), 0.0, 0.55)
	_add("props/barrel", WorldLayout.HOUSE + Vector2(96, 4))
	_add("props/crate", WorldLayout.HOUSE + Vector2(-98, 6))
	_blocker(WorldLayout.HOUSE + Vector2(96, -6), Vector2(22, 14))


func _orchard_fence() -> void:
	var r := WorldLayout.ORCHARD
	var gap_y := 486.0
	# top & bottom rails
	for y in [r.position.y, r.end.y]:
		var x := r.position.x
		while x < r.end.x:
			if not (y == r.end.y and absf(x - 840.0) < 36.0):
				_add("props/fence_h", Vector2(x, y), Vector2(0, 26))
			x += 32.0
	_blocker(Vector2(r.position.x + r.size.x * 0.5, r.position.y - 6), Vector2(r.size.x, 8))
	# bottom rail blockers either side of the south gap
	_blocker(Vector2((r.position.x + 804.0) * 0.5, r.end.y - 6), Vector2(804.0 - r.position.x, 8))
	_blocker(Vector2((876.0 + r.end.x) * 0.5, r.end.y - 6), Vector2(r.end.x - 876.0, 8))
	# side posts with path gaps
	for x in [r.position.x, r.end.x]:
		var y := r.position.y + 24.0
		while y <= r.end.y:
			if absf(y - gap_y) > 44.0:
				_add("props/fence_post", Vector2(x, y), Vector2(6, 30))
			y += 24.0
		_blocker(Vector2(x, (r.position.y + gap_y - 44.0) * 0.5), Vector2(8, gap_y - 44.0 - r.position.y))
		_blocker(Vector2(x, (gap_y + 44.0 + r.end.y) * 0.5), Vector2(8, r.end.y - gap_y - 44.0))


func _yard_hedges() -> void:
	# a hedge line framing the farmyard to the north and west
	var x := WorldLayout.HEDGE_WEST_X
	while x < 640.0:
		if absf(x - WorldLayout.HOUSE.x) > 120.0:
			_add("props/hedge_%d" % (rng.randi() % 4), Vector2(x, WorldLayout.HEDGE_NORTH_Y), Vector2(20, 34), 0.4)
		x += 34.0
	var y := WorldLayout.HEDGE_NORTH_Y + 30.0
	while y < 800.0:
		_add("props/hedge_%d" % (rng.randi() % 4), Vector2(WorldLayout.HEDGE_WEST_X, y), Vector2(20, 34), 0.4)
		y += 30.0
	_blocker(Vector2(WorldLayout.HEDGE_WEST_X, (WorldLayout.HEDGE_NORTH_Y + 800.0) * 0.5), Vector2(30, 800.0 - WorldLayout.HEDGE_NORTH_Y))


func _border_forest() -> void:
	var size := WorldLayout.SIZE
	var b := WorldLayout.BORDER
	# dense ring of trees on every edge, layered two deep for depth
	for layer in 3:
		var inset := 18.0 + layer * 44.0
		var step := 54.0 - layer * 6.0
		var x := -20.0
		while x < size.x + 20.0:
			_tree(Vector2(x + rng.randf_range(-10, 10), inset + rng.randf_range(-8, 8)))
			_tree(Vector2(x + rng.randf_range(-10, 10), size.y - inset + 70.0 + rng.randf_range(-8, 8)))
			x += step
		var y := inset + 40.0
		while y < size.y + 40.0:
			_tree(Vector2(inset - 10.0 + rng.randf_range(-8, 8), y + rng.randf_range(-10, 10)))
			_tree(Vector2(size.x - inset + 10.0 + rng.randf_range(-8, 8), y + rng.randf_range(-10, 10)))
			y += step
	# invisible walls just inside the treeline
	_blocker(Vector2(size.x * 0.5, b * 0.5), Vector2(size.x, b))
	_blocker(Vector2(size.x * 0.5, size.y - b * 0.3), Vector2(size.x, b * 0.6))
	_blocker(Vector2(b * 0.5, size.y * 0.5), Vector2(b, size.y))
	_blocker(Vector2(size.x - b * 0.5, size.y * 0.5), Vector2(b, size.y))
	# scattered wild trees in the eastern wilds
	for i in 26:
		var p := Vector2(rng.randf_range(WorldLayout.WILDS.position.x, WorldLayout.WILDS.end.x), rng.randf_range(WorldLayout.WILDS.position.y, WorldLayout.WILDS.end.y))
		if WorldLayout.dist_to_paths(p) > 60.0:
			_tree(p)
			_blocker(p + Vector2(0, -6), Vector2(14, 10))


func _tree(p: Vector2) -> void:
	_add("props/border_tree_%d" % (rng.randi() % 4), p, Vector2(40, 108), 0.8)


func _pond() -> void:
	var b := StaticBody2D.new()
	b.position = WorldLayout.POND
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = WorldLayout.POND_R.y * 0.85
	cap.height = WorldLayout.POND_R.x * 1.8
	cs.shape = cap
	cs.rotation = PI * 0.5
	b.add_child(cs)
	world.add_child(b)
	for i in 10:
		var a := rng.randf_range(0, TAU)
		var p := WorldLayout.POND + Vector2(cos(a) * WorldLayout.POND_R.x * 1.05, sin(a) * WorldLayout.POND_R.y * 1.08)
		_add("props/reeds", p, Vector2(12, 30), 0.6)


func _lanterns() -> void:
	for p in WorldLayout.LANTERNS:
		var s := _add("props/lantern", p, Vector2(10, 50))
		lantern_glows.append(FX.glow(s, Color("ffc070"), 64.0, Vector2(0, -36), 0.0, 0.85))


func _homestead_life() -> void:
	for i in WorldLayout.FLOWER_PATCHES.size():
		_add("props/flowers_%d" % (i % 4), WorldLayout.FLOWER_PATCHES[i], Vector2(22, 26), 0.25)
	_add("props/scarecrow", WorldLayout.SCARECROW + Vector2(0, -6), Vector2(26, 82), 0.3)
	_add("props/well", WorldLayout.WELL, Vector2(30, 74))
	_blocker(WorldLayout.WELL + Vector2(0, -10), Vector2(44, 20))
	_add("props/crate", WorldLayout.ORCHARD.position + Vector2(24, 28))
	_add("props/barrel", WorldLayout.ORCHARD.end + Vector2(-24, -20))
	_add("props/crate", WorldLayout.GATE + Vector2(-40, 40))
	_ambient_critters()


## Butterflies by day, fireflies by night: both live on the unlit overlay.
func _ambient_critters() -> void:
	if FX.overlay == null:
		return
	var b := CPUParticles2D.new()
	b.texture = Art.tex("fx/butterfly")
	b.amount = 10
	b.lifetime = 9.0
	b.preprocess = 9.0
	b.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	b.position = WorldLayout.HOMESTEAD_FRAME.get_center()
	b.emission_rect_extents = WorldLayout.HOMESTEAD_FRAME.size * 0.5
	b.gravity = Vector2.ZERO
	b.direction = Vector2(1, -0.3)
	b.spread = 180.0
	b.initial_velocity_min = 8.0
	b.initial_velocity_max = 20.0
	b.orbit_velocity_min = -0.05
	b.orbit_velocity_max = 0.05
	b.anim_speed_min = 6.0
	b.anim_speed_max = 9.0
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = 2
	mat.particles_anim_v_frames = 1
	mat.particles_anim_loop = true
	b.material = mat
	var cols := Gradient.new()
	cols.set_color(0, Color("ffcf6a"))
	cols.set_color(1, Color("ff9bb4"))
	cols.add_point(0.5, Color("b9a4ff"))
	b.color_initial_ramp = cols
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.15, Color(1, 1, 1, 1))
	fade.add_point(0.85, Color(1, 1, 1, 1))
	b.color_ramp = fade
	world.add_child(b)
	b.z_index = 30
	butterflies = b
	var f := CPUParticles2D.new()
	f.texture = Art.glow_texture()
	f.amount = 40
	f.lifetime = 5.0
	f.preprocess = 5.0
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	f.position = WorldLayout.HOMESTEAD_FRAME.get_center() + Vector2(150, 150)
	f.emission_rect_extents = WorldLayout.HOMESTEAD_FRAME.size * 0.75
	f.gravity = Vector2(0, -3)
	f.spread = 180.0
	f.initial_velocity_min = 3.0
	f.initial_velocity_max = 10.0
	f.scale_amount_min = 0.1
	f.scale_amount_max = 0.16
	f.color = Color("e8ff8a")
	var ff := Gradient.new()
	ff.set_color(0, Color(1, 1, 1, 0))
	ff.set_color(1, Color(1, 1, 1, 0))
	ff.add_point(0.5, Color(1, 1, 1, 1))
	f.color_ramp = ff
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	f.material = add
	FX.overlay.add_child(f)
	fireflies = f


func set_night(n: float) -> void:
	if butterflies:
		butterflies.modulate.a = clampf(1.0 - n * 2.0, 0.0, 1.0)
		butterflies.emitting = n < 0.5
	if fireflies:
		fireflies.modulate.a = clampf(n * 1.4 - 0.2, 0.0, 1.0)
		fireflies.emitting = n > 0.15


func _clutter() -> void:
	for p in WorldLayout.HIVES:
		_add("props/beehive", p, Vector2(16, 38))
	_add("props/crate", WorldLayout.STALL + Vector2(-76, 4))
	_add("props/barrel", WorldLayout.STALL + Vector2(-58, -8))
	_add("props/gate", WorldLayout.GATE, Vector2(48, 88), 0.0)
	for i in 70:
		var p := Vector2(rng.randf_range(180, WorldLayout.SIZE.x - 180), rng.randf_range(180, WorldLayout.SIZE.y - 160))
		if WorldLayout.dist_to_paths(p) < 30.0 or WorldLayout.in_pond(p) < 1.4 or WorldLayout.ORCHARD.grow(30).has_point(p):
			continue
		if WorldLayout.HOMESTEAD_FRAME.grow(20).has_point(p) or p.distance_to(WorldLayout.STALL) < 90.0:
			continue
		var k := rng.randi() % 10
		if k < 5:
			_add("props/bush_%d" % (rng.randi() % 4), p, Vector2(16, 22), 0.3)
		elif k < 8:
			_add("props/rock_%d" % (rng.randi() % 4), p, Vector2(14, 18))
		else:
			_add("props/stump", p, Vector2(16, 22))
