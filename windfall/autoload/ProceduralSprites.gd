## ProceduralSprites.gd
## Game OS Template Addition — Generic Procedural Sprite System
##
## Draws game characters and UI elements procedurally using Godot's
## CanvasItem draw calls. No external art files needed.
##
## Usage:
##   1. Add as autoload: ProceduralSprites = "res://autoload/ProceduralSprites.gd"
##   2. Call draw methods from any Node's _draw() function:
##        func _draw():
##            ProceduralSprites.draw_humanoid(self, config)
##   3. Call node.queue_redraw() each frame to animate.
##
## All draw methods take a CanvasItem as first argument so they render
## into that node's local coordinate space. Origin (0,0) is center of sprite.
##
## GENERIC — contains no game-specific content. Games extend this by
## passing config dictionaries that define colors, proportions, and state.

extends Node

# ── Palette helpers ────────────────────────────────────────────────────────────

## Darken a color by a factor (0=black, 1=original)
static func darken(col: Color, factor: float) -> Color:
	return Color(col.r * factor, col.g * factor, col.b * factor, col.a)

## Lighten toward white
static func lighten(col: Color, factor: float) -> Color:
	return col.lerp(Color.WHITE, factor)

## Alpha variant
static func alpha(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)


# ── Shadow ─────────────────────────────────────────────────────────────────────

## Draw a soft drop shadow ellipse. Call before drawing the character body.
static func draw_shadow(ci: CanvasItem, ox: float = 2.0, oy: float = 16.0,
		w: float = 24.0, h: float = 8.0, opacity: float = 0.28) -> void:
	ci.draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
	ci.draw_circle(Vector2.ZERO, w * 0.5, alpha(Color.BLACK, opacity))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── Humanoid character ─────────────────────────────────────────────────────────

## Draw a stylized humanoid character suitable for top-down or angled view.
##
## config keys:
##   body_color      : Color   — jersey/torso color
##   helmet_color    : Color   — helmet/head color
##   trim_color      : Color   — stripe/highlight color
##   number          : String  — jersey number ("55", "32", etc.)
##   pose            : String  — "stand" | "run" | "dive" | "stun"
##   facing          : float   — angle in radians (0 = down)
##   anim_time       : float   — Time.get_ticks_msec() * 0.001 for leg cycle
##   scale           : float   — uniform scale (default 1.0)
##   has_ball        : bool    — draw football tucked under arm
##   stun_stars      : bool    — draw spinning stars above head
static func draw_humanoid(ci: CanvasItem, config: Dictionary) -> void:
	var body_col  : Color  = config.get("body_color",   Color(0.1, 0.42, 1.0))
	var helm_col  : Color  = config.get("helmet_color", Color(0.05, 0.25, 0.8))
	var trim_col  : Color  = config.get("trim_color",   Color.YELLOW)
	var number    : String = config.get("number",       "55")
	var pose      : String = config.get("pose",         "stand")
	var anim_t    : float  = config.get("anim_time",    0.0)
	var sc        : float  = config.get("scale",        1.0)
	var has_ball  : bool   = config.get("has_ball",     false)
	var stun      : bool   = config.get("stun_stars",   false)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))

	match pose:
		"dive":
			_draw_humanoid_dive(ci, body_col, helm_col, trim_col, has_ball)
		"stun":
			_draw_humanoid_stand(ci, Color(0.4,0.4,0.4), Color(0.25,0.25,0.25),
				Color(0.5,0.5,0.5), number, 0.0, has_ball)
			_draw_stun_stars(ci, anim_t)
		_:
			_draw_humanoid_stand(ci, body_col, helm_col, trim_col, number, anim_t, has_ball)
			if stun: _draw_stun_stars(ci, anim_t)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_humanoid_stand(ci: CanvasItem, body: Color, helm: Color,
		trim: Color, number: String, t: float, has_ball: bool) -> void:
	# Shadow
	draw_shadow(ci, 2, 18, 22, 8, 0.25)

	# Legs with walk cycle
	var leg_cycle := sin(t * 8.0) * 5.0
	var leg_col := darken(helm, 0.7)
	ci.draw_rect(Rect2(-8, 6, 6, 14 + leg_cycle), leg_col)
	ci.draw_rect(Rect2(2,  6, 6, 14 - leg_cycle), leg_col)
	# Cleats
	ci.draw_rect(Rect2(-9, 20 + leg_cycle, 8, 3), darken(Color.BLACK, 0.8))
	ci.draw_rect(Rect2(1,  20 - leg_cycle, 8, 3), darken(Color.BLACK, 0.8))

	# Body
	ci.draw_rect(Rect2(-11, -10, 22, 20), body)
	# Jersey stripe
	ci.draw_rect(Rect2(-11, -2, 22, 4), alpha(trim, 0.35))
	# Top highlight
	ci.draw_rect(Rect2(-11, -10, 22, 3), alpha(Color.WHITE, 0.14))
	# Shoulder pads
	ci.draw_circle(Vector2(-14, -5), 6.0, body)
	ci.draw_circle(Vector2(14, -5),  6.0, body)
	ci.draw_circle(Vector2(-14, -6), 5.0, alpha(trim, 0.45))
	ci.draw_circle(Vector2(14, -6),  5.0, alpha(trim, 0.45))

	# Jersey number
	_draw_jersey_number(ci, number, Vector2(0, 4))

	# Helmet
	ci.draw_circle(Vector2(0, -15), 13.0, helm)
	# Helmet shine
	ci.draw_circle(Vector2(4, -20), 7.0, alpha(lighten(helm, 0.3), 0.55))
	# Helmet stripe
	ci.draw_rect(Rect2(-1.5, -28, 3, 16), alpha(trim, 0.55))
	# Facemask bars
	ci.draw_line(Vector2(10, -15), Vector2(16, -9),  Color(0.75, 0.75, 0.75), 2.0)
	ci.draw_line(Vector2(10, -19), Vector2(16, -13), Color(0.75, 0.75, 0.75), 2.0)

	# Football
	if has_ball:
		_draw_football(ci, Vector2(13, -3))


static func _draw_humanoid_dive(ci: CanvasItem, body: Color, helm: Color,
		trim: Color, has_ball: bool) -> void:
	# Horizontal dive pose — body stretched along X axis
	draw_shadow(ci, 0, 10, 36, 7, 0.22)

	# Body ellipse stretched horizontal
	ci.draw_circle(Vector2(0, 0), 10.0, body)
	ci.draw_rect(Rect2(-18, -9, 36, 18), body)  # approximate ellipse
	ci.draw_circle(Vector2(-18, 0), 9.0, body)
	ci.draw_circle(Vector2(18, 0), 9.0, body)
	# Trim stripe
	ci.draw_rect(Rect2(-14, -3, 28, 6), alpha(trim, 0.35))

	# Helmet at front (right side = forward)
	ci.draw_circle(Vector2(20, -1), 12.0, helm)
	ci.draw_circle(Vector2(23, -5), 6.0, alpha(lighten(helm, 0.3), 0.5))
	ci.draw_line(Vector2(28, -1), Vector2(34, 3),  Color(0.75, 0.75, 0.75), 2.0)
	ci.draw_line(Vector2(28, -4), Vector2(34, 0),  Color(0.75, 0.75, 0.75), 2.0)
	# Trailing arm
	ci.draw_circle(Vector2(-20, 2), 7.0, darken(body, 0.8))

	if has_ball:
		_draw_football(ci, Vector2(14, -4))


static func _draw_stun_stars(ci: CanvasItem, t: float) -> void:
	for i in 3:
		var ang := t * 2.5 + i * (TAU / 3.0)
		var sx := cos(ang) * 16.0
		var sy := -28.0 + sin(ang) * 5.0
		_draw_star(ci, Vector2(sx, sy), 5.0, Color.YELLOW)


# ── Villain / AI character ─────────────────────────────────────────────────────

## Draw an AI-controlled character (carrier/enemy). Slightly more menacing silhouette.
## Same config keys as draw_humanoid, plus:
##   shimmy_time : float — for side-to-side sway (use anim_time * 0.35 * dir)
static func draw_carrier(ci: CanvasItem, config: Dictionary) -> void:
	var body_col : Color  = config.get("body_color",   Color(0.75, 0.22, 0.18))
	var helm_col : Color  = config.get("helmet_color", Color(0.57, 0.15, 0.12))
	var trim_col : Color  = config.get("trim_color",   Color.WHITE)
	var pose     : String = config.get("pose",         "stand")
	var anim_t   : float  = config.get("anim_time",    0.0)
	var sc       : float  = config.get("scale",        1.0)
	var shimmy   : float  = config.get("shimmy_time",  0.0)
	var stun     : bool   = config.get("stun_stars",   false)

	var ox := sin(shimmy) * 3.0
	ci.draw_set_transform(Vector2(ox, 0.0), 0.0, Vector2(sc, sc))

	if stun:
		_draw_humanoid_stand(ci, Color(0.4,0.4,0.4), Color(0.25,0.25,0.25),
			Color(0.5,0.5,0.5), "32", anim_t, true)
		_draw_stun_stars(ci, anim_t)
	else:
		_draw_carrier_body(ci, body_col, helm_col, trim_col, anim_t)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_carrier_body(ci: CanvasItem, body: Color, helm: Color,
		trim: Color, t: float) -> void:
	draw_shadow(ci, 2, 20, 26, 9, 0.3)

	# Legs
	var lc := sin(t * 8.0) * 5.0
	ci.draw_rect(Rect2(-8, 7, 7, 15 + lc), darken(Color(0.2,0.2,0.2), 0.8))
	ci.draw_rect(Rect2(1,  7, 7, 15 - lc), darken(Color(0.2,0.2,0.2), 0.8))
	ci.draw_rect(Rect2(-9, 22 + lc, 9, 3), Color(0.1,0.1,0.1))
	ci.draw_rect(Rect2(0,  22 - lc, 9, 3), Color(0.1,0.1,0.1))

	# Body — slightly wider than defender
	ci.draw_rect(Rect2(-12, -11, 24, 24), body)
	ci.draw_rect(Rect2(-12, -3, 24, 4), alpha(trim, 0.18))
	ci.draw_rect(Rect2(-12, -11, 24, 3), alpha(Color.WHITE, 0.1))
	ci.draw_circle(Vector2(-15, -6), 7.0, body)
	ci.draw_circle(Vector2(15, -6),  7.0, body)

	_draw_jersey_number(ci, "32", Vector2(0, 6))

	# Football tucked
	_draw_football(ci, Vector2(13, -3))

	# Helmet — slightly larger
	ci.draw_circle(Vector2(0, -16), 14.0, helm)
	ci.draw_circle(Vector2(4, -22), 8.0, alpha(lighten(helm, 0.25), 0.5))
	ci.draw_rect(Rect2(-1.5, -30, 3, 17), alpha(body, 0.65))
	ci.draw_line(Vector2(11, -16), Vector2(17, -10), Color(0.7,0.7,0.7), 2.5)
	ci.draw_line(Vector2(11, -20), Vector2(17, -14), Color(0.7,0.7,0.7), 2.5)


# ── Blocker ────────────────────────────────────────────────────────────────────

## Draw a blocker character — stockier build than carrier.
static func draw_blocker(ci: CanvasItem, config: Dictionary) -> void:
	var body_col : Color = config.get("body_color",   Color(0.545, 0.27, 0.075))
	var helm_col : Color = config.get("helmet_color", Color(0.36, 0.18, 0.05))
	var stunned  : bool  = config.get("stunned",      false)
	var sc       : float = config.get("scale",        1.0)
	var anim_t   : float = config.get("anim_time",    0.0)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
	if stunned:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc * 0.9, sc * 0.9))

	var body := Color(0.3,0.3,0.3) if stunned else body_col
	var helm := Color(0.2,0.2,0.2) if stunned else helm_col

	draw_shadow(ci, 2, 16, 20, 7, 0.22)

	ci.draw_rect(Rect2(-7, 4, 6, 12), darken(helm, 0.7))
	ci.draw_rect(Rect2(1, 4, 6, 12),  darken(helm, 0.7))
	# Body — wide and squat
	ci.draw_rect(Rect2(-10, -8, 20, 16), body)
	ci.draw_rect(Rect2(-10, -1, 20, 3), alpha(Color.WHITE, 0.1))
	ci.draw_circle(Vector2(-13, -4), 6.0, body)
	ci.draw_circle(Vector2(13, -4),  6.0, body)
	# Helmet
	ci.draw_circle(Vector2(0, -13), 10.0, helm)
	ci.draw_circle(Vector2(3, -17), 5.0, alpha(lighten(helm, 0.25), 0.45))
	ci.draw_line(Vector2(8, -13), Vector2(13, -8), Color(0.6,0.6,0.6), 1.5)
	ci.draw_line(Vector2(8, -16), Vector2(13, -11), Color(0.6,0.6,0.6), 1.5)

	if stunned: _draw_stun_stars(ci, anim_t)

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── Generic shapes ─────────────────────────────────────────────────────────────

## Progress bar (horizontal). Use for HP, stamina, cooldown, etc.
## @param filled: 0.0–1.0
static func draw_bar(ci: CanvasItem, pos: Vector2, size: Vector2,
		filled: float, fill_color: Color, bg_color: Color = Color(0.1,0.1,0.1,0.6),
		border_color: Color = Color(0,0,0,0)) -> void:
	ci.draw_rect(Rect2(pos, size), bg_color)
	if filled > 0.001:
		ci.draw_rect(Rect2(pos, Vector2(size.x * clampf(filled, 0.0, 1.0), size.y)), fill_color)
	if border_color.a > 0.0:
		ci.draw_rect(Rect2(pos, size), border_color, false, 1.0)


## Cooldown arc drawn around a point. angle_pct: 0.0–1.0 fill.
static func draw_cooldown_arc(ci: CanvasItem, center: Vector2, radius: float,
		angle_pct: float, color: Color, width: float = 2.5) -> void:
	if angle_pct <= 0.001: return
	var pts := PackedVector2Array()
	var steps := 32
	for i in steps + 1:
		var t := float(i) / float(steps)
		if t > angle_pct: break
		var ang := -PI * 0.5 + t * TAU
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	if pts.size() > 1:
		ci.draw_polyline(pts, color, width)


## Draw an outlined circle glow (for ability readiness, auras, etc.)
static func draw_glow_ring(ci: CanvasItem, center: Vector2, radius: float,
		color: Color, rings: int = 3) -> void:
	for i in rings:
		var r := radius + float(i) * 3.0
		var a := color.a * (1.0 - float(i) / float(rings)) * 0.4
		ci.draw_arc(center, r, 0, TAU, 32, alpha(color, a), 2.0)


## 7-segment style digit rendering — no font needed.
static func draw_digit(ci: CanvasItem, digit: String, pos: Vector2,
		w: float = 5.0, h: float = 9.0, color: Color = Color.WHITE) -> void:
	const SEGS := {
		"0":[1,1,1,0,1,1,1], "1":[0,0,1,0,0,1,0], "2":[1,0,1,1,1,0,1],
		"3":[1,0,1,1,0,1,1], "4":[0,1,1,1,0,1,0], "5":[1,1,0,1,0,1,1],
		"6":[1,1,0,1,1,1,1], "7":[1,0,1,0,0,1,0], "8":[1,1,1,1,1,1,1],
		"9":[1,1,1,1,0,1,1],
	}
	var s: Array = SEGS.get(digit, SEGS["0"])
	var hh := h * 0.5
	var th := 1.0  # segment thickness
	if s[0]: ci.draw_rect(Rect2(pos + Vector2(1,0),     Vector2(w-2, th)), color)
	if s[1]: ci.draw_rect(Rect2(pos + Vector2(0,1),     Vector2(th, hh-1)), color)
	if s[2]: ci.draw_rect(Rect2(pos + Vector2(w-th,1),  Vector2(th, hh-1)), color)
	if s[3]: ci.draw_rect(Rect2(pos + Vector2(1,hh),    Vector2(w-2, th)), color)
	if s[4]: ci.draw_rect(Rect2(pos + Vector2(0,hh+1),  Vector2(th, hh-1)), color)
	if s[5]: ci.draw_rect(Rect2(pos + Vector2(w-th,hh+1),Vector2(th, hh-1)), color)
	if s[6]: ci.draw_rect(Rect2(pos + Vector2(1,h-th),  Vector2(w-2, th)), color)


## Draw a multi-digit number centered at a position.
static func draw_number(ci: CanvasItem, number: String, center: Vector2,
		digit_w: float = 5.0, digit_h: float = 9.0,
		gap: float = 2.0, color: Color = Color.WHITE) -> void:
	var total_w := number.length() * (digit_w + gap) - gap
	var sx := center.x - total_w * 0.5
	for ch in number:
		draw_digit(ci, ch, Vector2(sx, center.y - digit_h * 0.5), digit_w, digit_h, color)
		sx += digit_w + gap


# ── Special objects ────────────────────────────────────────────────────────────

## American football.
static func _draw_football(ci: CanvasItem, pos: Vector2) -> void:
	# Ellipse approximation
	ci.draw_circle(pos, 5.0, Color(0.545, 0.271, 0.075))
	ci.draw_rect(Rect2(pos + Vector2(-8, -2), Vector2(16, 4)), Color(0.545, 0.271, 0.075))
	ci.draw_circle(pos + Vector2(-8, 0), 4.0, Color(0.545, 0.271, 0.075))
	ci.draw_circle(pos + Vector2(8, 0),  4.0, Color(0.545, 0.271, 0.075))
	# Laces
	ci.draw_line(pos + Vector2(-5, 0), pos + Vector2(5, 0), alpha(Color.WHITE, 0.85), 1.5)
	ci.draw_line(pos + Vector2(0, -4), pos + Vector2(0, 4), alpha(Color.WHITE, 0.5), 1.0)


## 4-point diamond star.
static func _draw_star(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -r),
		pos + Vector2(r*0.38, 0),
		pos + Vector2(0, r),
		pos + Vector2(-r*0.38, 0),
	])
	ci.draw_colored_polygon(pts, color)


## Draw jersey number using draw_number.
static func _draw_jersey_number(ci: CanvasItem, number: String, pos: Vector2) -> void:
	draw_number(ci, number, pos, 5.0, 8.0, 1.5, alpha(Color.WHITE, 0.88))


# ── Field / arena elements ─────────────────────────────────────────────────────

## Draw yard line (horizontal, full width).
static func draw_yard_line(ci: CanvasItem, y: float, width: float,
		color: Color = Color(1,1,1,0.12), thickness: float = 2.0) -> void:
	ci.draw_line(Vector2(0, y), Vector2(width, y), color, thickness)


## Draw alternating grass stripes across a rect.
static func draw_grass_stripes(ci: CanvasItem, rect: Rect2,
		color_a: Color = Color(0.1, 0.23, 0.1),
		color_b: Color = Color(0.12, 0.26, 0.12),
		stripe_h: float = 110.0) -> void:
	var y := rect.position.y
	var toggle := false
	while y < rect.end.y:
		var h := minf(stripe_h * 0.5, rect.end.y - y)
		ci.draw_rect(Rect2(rect.position.x, y, rect.size.x, h),
			color_b if toggle else color_a)
		y += h
		if fmod(y - rect.position.y, stripe_h) < stripe_h * 0.5 + 1.0:
			pass  # same stripe
		else:
			toggle = !toggle
		y += minf(stripe_h * 0.5, rect.end.y - y)
		toggle = !toggle


## Draw endzone diagonal stripe pattern.
static func draw_endzone(ci: CanvasItem, rect: Rect2, base_color: Color,
		stripe_color: Color = Color(1,1,1,0.05)) -> void:
	ci.draw_rect(rect, base_color)
	ci.draw_line(Vector2.ZERO, Vector2.ZERO, stripe_color, 14.0)  # force antialias
	var x := rect.position.x - rect.size.y
	while x < rect.end.x + rect.size.y:
		ci.draw_line(
			Vector2(x, rect.position.y),
			Vector2(x + rect.size.y, rect.end.y),
			stripe_color, 14.0
		)
		x += 34.0


## Draw dashed line between two points.
static func draw_dashed_line(ci: CanvasItem, from: Vector2, to: Vector2,
		color: Color, width: float = 1.5, dash: float = 10.0, gap: float = 7.0) -> void:
	var total := from.distance_to(to)
	if total < 0.1: return
	var dir := (to - from) / total
	var t := 0.0
	var drawing := true
	while t < total:
		var seg_len := dash if drawing else gap
		var end_t := minf(t + seg_len, total)
		if drawing:
			ci.draw_line(from + dir * t, from + dir * end_t, color, width)
		t = end_t
		drawing = !drawing


# ── UI panel elements ──────────────────────────────────────────────────────────

## Draw a styled panel background with border and optional header strip.
static func draw_panel(ci: CanvasItem, rect: Rect2,
		bg_color: Color = Color(0.07, 0.07, 0.07, 0.94),
		border_color: Color = Color(0.16, 0.16, 0.16),
		header_color: Color = Color(0,0,0,0),
		header_h: float = 40.0,
		radius: float = 0.0) -> void:
	ci.draw_rect(rect, bg_color)
	if header_color.a > 0.0:
		ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, header_h)), header_color)
	if border_color.a > 0.0:
		ci.draw_rect(rect, border_color, false, 1.0)


## Draw a rarity-colored badge background.
static func draw_rarity_badge(ci: CanvasItem, rect: Rect2, rarity: int) -> void:
	const RARITY_COLORS := [
		Color(0.47, 0.47, 0.47, 0.9),  # COMMON
		Color(0.22, 0.69, 1.0, 0.9),   # RARE
		Color(0.96, 0.95, 0.0, 0.9),   # EPIC
		Color(1.0, 0.42, 0.21, 0.9),   # LEGENDARY
	]
	const RARITY_BG := [
		Color(0.06, 0.06, 0.06),
		Color(0.0, 0.1, 0.16),
		Color(0.08, 0.08, 0.0),
		Color(0.1, 0.04, 0.0),
	]
	var i := clampi(rarity, 0, 3)
	ci.draw_rect(rect, RARITY_BG[i])
	ci.draw_rect(rect, RARITY_COLORS[i], false, 1.0)


## Draw a stat bar row (label + fill bar).
static func draw_stat_row(ci: CanvasItem, pos: Vector2, label: String,
		value: float, bar_width: float = 80.0, bar_color: Color = Color.YELLOW) -> void:
	# Label drawn as digits if it's a number, otherwise skip (use Label node)
	var bar_pos := pos + Vector2(0, 2)
	draw_bar(ci, bar_pos, Vector2(bar_width * value, 4), 1.0, bar_color,
		Color(0.1,0.1,0.1,0.7))
