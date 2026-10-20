extends Node

## FX — registered as the `FX` autoload.
## One place for every bit of juice: particles, popups, damage numbers,
## additive light glows, chain-lightning bolts, poofs and camera impact.
##
## Glows and popups live on an overlay CanvasLayer that follows the camera but
## is NOT darkened by the night CanvasModulate, so element colours pop at night.

const FONT := preload("res://assets/fonts/PixelifySans-Bold.woff2")

var world: Node2D = null          # y-sorted world root (set by WindfallMain)
var overlay: CanvasLayer = null   # unlit overlay for glows / popups
var night: float = 0.0            # 0 = day, 1 = deep night (set by DayLighting)
var _glows: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func bind(world_root: Node2D, overlay_layer: CanvasLayer) -> void:
	world = world_root
	overlay = overlay_layer
	_glows.clear()


func _process(_delta: float) -> void:
	# glows breathe a little and get stronger at night
	var i := _glows.size() - 1
	while i >= 0:
		var g: Dictionary = _glows[i]
		var s_raw = g.sprite
		var host_raw = g.host
		if not is_instance_valid(s_raw) or not is_instance_valid(host_raw) or not (host_raw as Node2D).is_inside_tree():
			if is_instance_valid(s_raw):
				(s_raw as Node).queue_free()
			_glows.remove_at(i)
			i -= 1
			continue
		var s: Sprite2D = s_raw
		var host: Node2D = host_raw
		s.global_position = host.global_position + g.offset
		var a: float = g.base_alpha * lerpf(g.day_alpha, 1.0, night)
		a *= 1.0 + sin(Time.get_ticks_msec() * 0.001 * g.pulse + g.seed) * 0.12
		s.modulate.a = a * (1.0 if host.visible else 0.0)
		i -= 1


# ── glows ───────────────────────────────────────────────────────────────────

## Attach a soft additive light to `host`. Returns the sprite so callers can
## recolour / resize it. day_alpha: how visible it is at noon (0..1).
func glow(host: Node2D, color: Color, radius: float, offset := Vector2.ZERO, day_alpha: float = 0.25, alpha: float = 0.8) -> Sprite2D:
	if overlay == null:
		return null
	var s := Sprite2D.new()
	s.texture = Art.glow_texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.modulate = Color(color, 0.0)
	s.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	overlay.add_child(s)
	s.global_position = host.global_position + offset
	_glows.append({"sprite": s, "host": host, "offset": offset, "base_alpha": alpha, "day_alpha": day_alpha, "pulse": randf_range(1.5, 3.0), "seed": randf() * 10.0})
	return s


func set_glow_offset(s: Sprite2D, offset: Vector2) -> void:
	for g in _glows:
		if is_instance_valid(g.sprite) and g.sprite == s:
			g.offset = offset


func flash_light(pos: Vector2, color: Color, radius: float, dur: float = 0.25) -> void:
	if overlay == null:
		return
	var s := Sprite2D.new()
	s.texture = Art.glow_texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.modulate = color
	s.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	overlay.add_child(s)
	s.global_position = pos
	var t := s.create_tween()
	t.tween_property(s, "modulate:a", 0.0, dur)
	t.tween_callback(s.queue_free)


# ── text popups ─────────────────────────────────────────────────────────────

func popup(text: String, pos: Vector2, color: Color, size: int = 16, rise: float = 26.0, dur: float = 0.8) -> Label:
	if overlay == null:
		return null
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", WPal.OUTLINE)
	l.add_theme_constant_override("outline_size", maxi(4, size / 3))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, size + 8)
	l.pivot_offset = l.size * 0.5
	overlay.add_child(l)
	l.global_position = pos - Vector2(80, size)
	l.scale = Vector2(0.4, 0.4)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "global_position:y", l.global_position.y - rise, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, dur * 0.35).set_delay(dur * 0.65)
	t.chain().tween_callback(l.queue_free)
	return l


func damage_number(amount: float, pos: Vector2, fam: int = -1, crit: bool = false) -> void:
	var col := Color("fff7e6") if fam < 0 else WPal.element(fam, 3)
	if crit:
		col = WPal.GOLD[4]
	var size := 22 if crit else 15
	var txt := str(int(round(amount))) + ("!" if crit else "")
	popup(txt, pos + Vector2(randf_range(-8, 8), -18), col, size, 30.0 if crit else 22.0, 0.75)


# ── particles ───────────────────────────────────────────────────────────────

## One-shot CPU particle burst. layer: "world" (lit by day/night) or "overlay" (glowy).
func burst(pos: Vector2, tex_path: String, color: Color, amount: int, speed: float, life: float = 0.5,
		gravity := Vector2.ZERO, spread: float = 180.0, dir := Vector2.UP, scale_range := Vector2(1.0, 1.0),
		layer: String = "overlay", color_end := Color(1, 1, 1, 0), additive: bool = false) -> CPUParticles2D:
	var parent: Node = overlay if layer == "overlay" else world
	if parent == null:
		return null
	var p := CPUParticles2D.new()
	p.texture = Art.tex(tex_path)
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.damping_min = speed * 0.6
	p.damping_max = speed * 1.2
	p.scale_amount_min = scale_range.x
	p.scale_amount_max = scale_range.y
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, color_end if color_end.a > 0.0 else Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	parent.add_child(p)
	p.global_position = pos
	p.z_index = 20
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


func dust(pos: Vector2, amount: int = 4) -> void:
	burst(pos, "fx/dot4", Color(WPal.DIRT[4], 0.85), amount, 30.0, 0.4, Vector2(0, -20), 70.0, Vector2.UP, Vector2(0.8, 1.6), "world")


## The signature particle language of each element.
func element_burst(fam: int, pos: Vector2, power: float = 1.0) -> void:
	var c := WPal.element(fam, 3)
	var n := int(10 * power)
	match fam:
		WindfallTypes.Family.STORM:
			burst(pos, "fx/spark", WPal.element(fam, 4), n, 160.0 * power, 0.35, Vector2.ZERO, 180.0, Vector2.UP, Vector2(1, 2), "overlay", Color(0,0,0,0), true)
			burst(pos, "fx/shard", c, n / 2, 110.0, 0.3)
		WindfallTypes.Family.EMBER:
			burst(pos, "fx/dot4", WPal.element(fam, 4), n, 120.0 * power, 0.45, Vector2.ZERO, 180.0, Vector2.UP, Vector2(0.8, 1.8), "overlay", WPal.element(fam, 1), true)
			burst(pos, "fx/dot", c, n, 50.0, 1.1, Vector2(0, -70), 50.0, Vector2.UP, Vector2(1, 2), "overlay", Color(0,0,0,0), true)  # rising embers
		WindfallTypes.Family.FROST:
			burst(pos, "fx/shard", WPal.element(fam, 4), n, 140.0 * power, 0.45, Vector2(0, 120), 180.0, Vector2.UP, Vector2(1, 2))
			burst(pos, "fx/glow", Color(c, 0.35), 4, 18.0, 0.9, Vector2(0, -8), 180.0, Vector2.UP, Vector2(0.4, 0.8))  # mist
		WindfallTypes.Family.TIDE:
			burst(pos, "fx/dot4", c, n, 140.0 * power, 0.5, Vector2(0, 260), 70.0, Vector2.UP, Vector2(0.8, 1.5))
			ring(pos, c, 34.0 * power, 0.35)
		WindfallTypes.Family.VERDANT:
			burst(pos, "fx/leaf", Color.WHITE, n, 90.0 * power, 0.8, Vector2(0, 60), 180.0, Vector2.UP, Vector2(1, 1.5), "world")
		WindfallTypes.Family.GALE:
			burst(pos, "fx/dot", WPal.element(fam, 4), n, 150.0 * power, 0.5, Vector2.ZERO, 180.0, Vector2.UP, Vector2(1, 2.5))
			ring(pos, c, 42.0 * power, 0.3)
		WindfallTypes.Family.UMBRA:
			burst(pos, "fx/dot4", WPal.element(fam, 1), n, 70.0 * power, 0.7, Vector2(0, -30), 180.0, Vector2.UP, Vector2(1, 2))
		_:
			burst(pos, "fx/spark", WPal.element(fam, 4), n, 110.0 * power, 0.5, Vector2.ZERO, 180.0, Vector2.UP, Vector2(1, 2), "overlay", Color(0,0,0,0), true)
	flash_light(pos, c, 40.0 * power, 0.3)


func ring(pos: Vector2, color: Color, radius: float, dur: float = 0.35) -> void:
	var host: Node = overlay
	if host == null:
		return
	var s := Sprite2D.new()
	s.texture = Art.tex("fx/ring")
	s.modulate = color
	host.add_child(s)
	s.global_position = pos
	s.scale = Vector2.ONE * 0.2
	var t := s.create_tween().set_parallel(true)
	t.tween_property(s, "scale", Vector2.ONE * (radius * 2.0 / 64.0), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, dur)
	t.chain().tween_callback(s.queue_free)


func poof(pos: Vector2, tint := Color.WHITE) -> void:
	if world == null:
		return
	var s := Art.sprite("fx/poof", 5, 1)
	s.centered = true
	s.offset = Vector2.ZERO
	s.modulate = tint
	s.z_index = 15
	world.add_child(s)
	s.global_position = pos
	var t := s.create_tween()
	t.tween_property(s, "frame", 4, 0.35)
	t.tween_property(s, "modulate:a", 0.0, 0.1)
	t.tween_callback(s.queue_free)


func sparkle(pos: Vector2, color: Color = Color.WHITE) -> void:
	if overlay == null:
		return
	var s := Art.sprite("fx/sparkle", 4, 1)
	s.centered = true
	s.offset = Vector2.ZERO
	s.modulate = color
	overlay.add_child(s)
	s.global_position = pos
	var t := s.create_tween()
	t.tween_property(s, "frame", 3, 0.35).from(0)
	t.tween_callback(s.queue_free)


## Branching chain-lightning bolt between two points.
func lightning(from: Vector2, to: Vector2, color: Color, width: float = 3.0, dur: float = 0.22) -> void:
	if overlay == null:
		return
	var root := Node2D.new()
	overlay.add_child(root)
	_bolt(root, from, to, color, width, 2)
	flash_light(to, color, 46.0, 0.25)
	var t := root.create_tween()
	t.tween_property(root, "modulate:a", 0.0, dur).set_delay(0.06)
	t.tween_callback(root.queue_free)


func _bolt(root: Node2D, a: Vector2, b: Vector2, color: Color, width: float, depth: int) -> void:
	var pts := PackedVector2Array([a])
	var segs := maxi(4, int(a.distance_to(b) / 14.0))
	var n := (b - a).orthogonal().normalized()
	for i in range(1, segs):
		var t := float(i) / segs
		pts.append(a.lerp(b, t) + n * randf_range(-9.0, 9.0) * (1.0 - absf(t - 0.5)))
	pts.append(b)
	for k in 2:
		var line := Line2D.new()
		line.points = pts
		line.width = width * (2.4 if k == 0 else 1.0)
		line.default_color = Color(color, 0.45) if k == 0 else Color(1, 1, 1, 0.95).lerp(color, 0.3)
		line.joint_mode = Line2D.LINE_JOINT_SHARP
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		line.material = m
		root.add_child(line)
	if depth > 0:
		for i in 2:
			var idx := randi_range(1, pts.size() - 2)
			var start := pts[idx]
			var dir := (b - a).normalized().rotated(randf_range(-1.0, 1.0))
			_bolt(root, start, start + dir * randf_range(18.0, 34.0), color, width * 0.5, depth - 1)


# ── camera impact (routes through the CameraFX autoload) ────────────────────

func shake(amount: float) -> void:
	CameraFX.add_trauma(clampf(amount, 0.0, 1.0))


func hitstop(dur: float) -> void:
	if Engine.time_scale < 1.0 or dur <= 0.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0


func punch(amount: float = 0.08) -> void:
	CameraFX.zoom_punch(amount, 0.08, 0.25)
