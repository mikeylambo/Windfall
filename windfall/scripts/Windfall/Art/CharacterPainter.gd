extends RefCounted
class_name CharacterPainter

## Parametric pixel "puppet" shared by every humanoid in WINDFALL, so the
## Rootborn, villagers and poachers are all built from the same proportions,
## light direction and outline rules.
##
## Frame: 20 x 26 texels, feet planted at (10, 24). Directions: 0 down, 1 up,
## 2 side (faces right; flip for left).

const FW := 20
const FH := 26
const CX := 10
const FY := 24

enum Dir { DOWN, UP, SIDE }


static func spec_rootborn() -> Dictionary:
	return {
		"skin": WPal.BARKSKIN, "coat": WPal.CLOTH_RUSSET, "trim": WPal.CLOTH_OCHRE, "pants": WPal.WOOD,
		"boots": WPal.BARK, "hair": WPal.MOSS, "head": "sprout", "body": "coat", "satchel": true,
		"eye": WPal.INK,
	}


static func spec_wren() -> Dictionary:
	return {
		"skin": WPal.SKIN, "coat": WPal.CLOTH_BLUE, "trim": WPal.STONE, "pants": WPal.CLOTH_DARK,
		"boots": WPal.CLOTH_DARK, "hair": WPal.HAIR_DARK, "head": "ponytail", "body": "slim", "satchel": false,
		"eye": WPal.INK, "scarf": WPal.RED,
	}


static func spec_hesper() -> Dictionary:
	return {
		"skin": WPal.SKIN, "coat": WPal.CLOTH_OCHRE, "trim": WPal.CREAM, "pants": WPal.WOOD,
		"boots": WPal.WOOD, "hair": WPal.WOOD, "head": "beehat", "body": "round", "satchel": false,
		"eye": WPal.INK,
	}


static func spec_poacher() -> Dictionary:
	return {
		"skin": WPal.CLOTH_DARK, "coat": WPal.CLOTH_PLUM, "trim": WPal.CLOTH_DARK, "pants": WPal.CLOTH_DARK,
		"boots": WPal.CLOTH_DARK, "hair": WPal.CLOTH_DARK, "head": "hood", "body": "cloak", "satchel": false,
		"eye": WPal.RED[4], "sack": true,
	}


## pose keys: dir, bob, step (-1 left foot up, 1 right foot up), arm (swing -1..1),
## reach (Vector2i hand push toward facing), arms_up, eat, blink, hurt, lean
static func paint(spec: Dictionary, pose: Dictionary) -> PixelCanvas:
	var c := PixelCanvas.new(FW, FH, 7)
	var dir: int = pose.get("dir", Dir.DOWN)
	var bob: int = pose.get("bob", 0)
	var step: int = pose.get("step", 0)
	var arm: float = pose.get("arm", 0.0)
	var lean: int = pose.get("lean", 0)

	match dir:
		Dir.DOWN:
			_paint_front(c, spec, pose, bob, step, arm, lean, false)
		Dir.UP:
			_paint_front(c, spec, pose, bob, step, arm, lean, true)
		Dir.SIDE:
			_paint_side(c, spec, pose, bob, step, arm, lean)

	c.outline(WPal.OUTLINE, 0.6)
	if pose.get("hurt", false):
		_hurt_flash(c)
	return c


# ── front / back ────────────────────────────────────────────────────────────

static func _paint_front(c: PixelCanvas, s: Dictionary, pose: Dictionary, bob: int, step: int, arm: float, lean: int, back: bool) -> void:
	var body: String = s.get("body", "coat")
	var half := 4
	if body == "round": half = 5
	elif body == "slim": half = 3
	var top := 13 + bob
	var hip := 20
	var coat: Array = s.coat

	# feet & legs
	var ly := FY - (1 if step < 0 else 0)
	var ry := FY - (1 if step > 0 else 0)
	if body != "cloak":
		c.rect(CX - 3, hip, 2, ly - hip, s.pants[2])
		c.rect(CX + 1, hip, 2, ry - hip, s.pants[1])
	c.rect(CX - 4, ly - 1, 3, 2, s.boots[2])
	c.px(CX - 4, ly - 1, s.boots[3])
	c.rect(CX + 1, ry - 1, 3, 2, s.boots[1])

	# back-side satchel / sack (drawn before body when seen from behind)
	if back and s.get("satchel", false):
		c.shade_ellipse(CX - 4.5, top + 5.5, 2.6, 2.6, WPal.WOOD.slice(2, 6))
	if s.get("sack", false):
		var sack_x: float = CX + 3.5 if not back else float(CX)
		c.shade_ellipse(sack_x, top + 2.5, 4.2, 3.8, WPal.CREAM.slice(0, 3), -0.1)

	# arms behind body when back-facing
	var arm_dy := int(round(arm))
	if back:
		_arm(c, s, CX - half - 1 + lean, top + 1 + arm_dy, false)
		_arm(c, s, CX + half - 1 + lean, top + 1 - arm_dy, false)

	# body
	var flare := 1 if body in ["coat", "cloak", "round"] else 0
	var body_bottom := hip + (2 if body == "cloak" else 1)
	c.shade_box(CX - half + lean, top, half * 2, body_bottom - top, coat, 0.05)
	if flare > 0:
		c.shade_box(CX - half - 1 + lean, body_bottom - 2, half * 2 + 2, 2, coat, -0.05)
	# trim / belt
	if body != "cloak":
		c.hline(CX - half + lean, CX + half - 1 + lean, top + 4, s.trim[1])
		if not back:
			c.px(CX - 1 + lean, top + 4, WPal.GOLD[3])
			# coat opening
			c.vline(CX + lean - (0 if half % 2 == 0 else 0), top + 5, body_bottom - 1, coat[0])
	else:
		# cloak clasp & folds
		c.vline(CX - 2 + lean, top + 3, body_bottom - 1, coat[1])
		c.vline(CX + 1 + lean, top + 3, body_bottom - 1, coat[1])
	if s.has("scarf"):
		c.rect(CX - half + lean, top, half * 2, 2, s.scarf[2])
		c.hline(CX - half + lean, CX + half - 1 + lean, top, s.scarf[3])
		if not back:
			c.rect(CX + 1 + lean, top + 2, 2, 3, s.scarf[2])
	if body == "round" and not back:
		# beekeeper apron with honeycomb pocket
		c.rect(CX - 3 + lean, top + 5, 6, body_bottom - top - 5, WPal.CREAM[2])
		c.hline(CX - 3 + lean, CX + 2 + lean, top + 5, WPal.CREAM[3])
		c.rect(CX - 1 + lean, top + 7, 2, 2, WPal.GOLD[3])

	# front satchel strap
	if not back and s.get("satchel", false):
		c.line(CX - half + 1 + lean, top, CX + half - 1 + lean, top + 5, WPal.WOOD[2])
		c.shade_ellipse(CX + half + 0.5 + lean, top + 6.5, 2.2, 2.2, WPal.WOOD.slice(2, 6))

	# arms in front
	if not back:
		var reach: Vector2i = pose.get("reach", Vector2i.ZERO)
		if pose.get("arms_up", false):
			_arm_up(c, s, CX - half - 1 + lean, top - 3)
			_arm_up(c, s, CX + half - 1 + lean, top - 3)
		elif pose.get("eat", false):
			_arm(c, s, CX - half - 1 + lean, top + 1 + arm_dy, true)
			# hand raised to mouth holding fruit
			c.rect(CX + lean, top - 1, 3, 3, s.skin[3])
		else:
			_arm(c, s, CX - half - 1 + lean, top + 1 + arm_dy, true)
			_arm(c, s, CX + half - 1 + lean + reach.x, top + 1 - arm_dy + reach.y, true)

	# head
	_head_front(c, s, pose, CX + lean, 9 + bob, back)


static func _arm(c: PixelCanvas, s: Dictionary, x: int, y: int, show_hand: bool) -> void:
	c.rect(x, y, 2, 5, s.coat[1])
	c.px(x, y, s.coat[2])
	if show_hand:
		c.rect(x, y + 5, 2, 1, s.skin[2])
		c.px(x, y + 5, s.skin[3])


static func _arm_up(c: PixelCanvas, s: Dictionary, x: int, y: int) -> void:
	c.rect(x, y + 1, 2, 4, s.coat[2])
	c.rect(x, y, 2, 1, s.skin[3])


static func _head_front(c: PixelCanvas, s: Dictionary, pose: Dictionary, hx: int, hy: int, back: bool) -> void:
	var head: String = s.get("head", "sprout")
	var cx := float(hx)
	var cy := float(hy)

	if head == "hood":
		c.shade_ellipse(cx, cy, 5.6, 5.2, s.coat, -0.05)
		if not back:
			# shadowed face opening with glowing eyes
			c.ellipse(cx, cy + 1.2, 3.6, 3.0, WPal.INK)
			var ey := hy + 1
			c.px(hx - 2, ey, s.eye)
			c.px(hx + 1, ey, s.eye)
			if not pose.get("blink", false):
				c.px(hx - 2, ey - 1, s.eye.darkened(0.3))
				c.px(hx + 1, ey - 1, s.eye.darkened(0.3))
			# mask strap
			c.hline(hx - 3, hx + 2, ey + 2, s.coat[0])
		else:
			c.vline(hx - 1, hy - 3, hy + 3, s.coat[1])
		# hood tip
		c.px(hx - 1, hy - 6, s.coat[2])
		c.px(hx, hy - 6, s.coat[2])
		return

	# skin
	c.shade_ellipse(cx, cy, 5.2, 4.7, s.skin, 0.05)

	# hair cap
	var hair: Array = s.hair
	if head == "sprout":
		for y in range(hy - 5, hy - 1 if not back else hy + 5):
			for x in range(hx - 6, hx + 6):
				var nx := (x + 0.5 - cx) / 5.6
				var ny := (y + 0.5 - (cy - 0.6)) / 5.0
				if nx * nx + ny * ny <= 1.0:
					var lum := 0.6 - nx * 0.35 - ny * 0.4
					c.px(x, y, c._ramp_dither(hair, lum, x, y))
		if not back:
			# leafy fringe
			for fx in [hx - 5, hx - 4, hx - 2, hx + 1, hx + 3, hx + 4]:
				c.px(fx, hy - 1, hair[2])
			c.px(hx - 5, hy, hair[1])
			c.px(hx + 4, hy, hair[1])
		# the twin sprout - Rootborn's signature silhouette
		var leaf: Array = WPal.LEAF
		c.vline(hx, hy - 8, hy - 5, leaf[2])
		c.shade_ellipse(cx - 2.5, cy - 8.5, 2.6, 1.4, leaf.slice(2, 6))
		c.shade_ellipse(cx + 2.6, cy - 9.6, 2.4, 1.3, leaf.slice(2, 6))
	elif head == "ponytail":
		for y in range(hy - 5, hy + (0 if not back else 4)):
			for x in range(hx - 6, hx + 6):
				var nx := (x + 0.5 - cx) / 5.5
				var ny := (y + 0.5 - (cy - 0.8)) / 4.8
				if nx * nx + ny * ny <= 1.0:
					c.px(x, y, c._ramp_dither(hair, 0.6 - nx * 0.3 - ny * 0.4, x, y))
		# ponytail sweeping to the side
		c.shade_ellipse(cx + 5.0, cy - 1.0, 1.8, 3.2, hair)
		c.px(hx + 6, hy + 2, hair[1])
		if not back:
			c.px(hx - 4, hy - 1, hair[3])
			c.px(hx - 3, hy - 1, hair[2])
	elif head == "beehat":
		# veil hanging around the face
		if not back:
			for y in range(hy - 1, hy + 5):
				for x in range(hx - 6, hx + 6):
					if PixelCanvas.bayer(x, y) < 0.35 and c.is_solid(x, y):
						c.px(x, y, Color(WPal.CREAM[3].r, WPal.CREAM[3].g, WPal.CREAM[3].b, 0.55))
		else:
			c.ellipse(cx, cy + 1, 5.4, 4.0, WPal.CREAM[2])
		# wide brim and crown
		c.shade_ellipse(cx, cy - 2.4, 8.4, 2.6, WPal.CREAM, 0.05)
		c.shade_ellipse(cx, cy - 5.0, 4.4, 3.2, WPal.CREAM, 0.1)
		c.hline(hx - 4, hx + 3, hy - 3, WPal.GOLD[2])

	if back or head == "beehat" and back:
		return

	# face
	var ey := hy + 1
	if head == "beehat":
		ey = hy + 1
	if pose.get("hurt", false):
		c.line(hx - 3, ey - 1, hx - 2, ey, s.eye)
		c.line(hx - 2, ey - 1, hx - 3, ey, s.eye)
		c.line(hx + 1, ey - 1, hx + 2, ey, s.eye)
		c.line(hx + 2, ey - 1, hx + 1, ey, s.eye)
	elif pose.get("blink", false):
		c.hline(hx - 3, hx - 2, ey, s.eye)
		c.hline(hx + 1, hx + 2, ey, s.eye)
	else:
		c.vline(hx - 3, ey - 1, ey, s.eye)
		c.vline(hx + 2, ey - 1, ey, s.eye)
		c.px(hx - 3, ey - 1, WPal.WHITE)
		c.px(hx + 2, ey - 1, WPal.WHITE)
	c.px(hx - 4, ey + 1, Color(WPal.RED[4], 0.7))
	c.px(hx + 3, ey + 1, Color(WPal.RED[4], 0.7))
	if pose.get("eat", false):
		c.rect(hx - 1, ey + 2, 2, 2, WPal.RED[1])
	elif pose.get("arms_up", false):
		c.px(hx - 1, ey + 2, WPal.RED[1])
		c.px(hx, ey + 2, WPal.RED[1])


# ── side view ───────────────────────────────────────────────────────────────

static func _paint_side(c: PixelCanvas, s: Dictionary, pose: Dictionary, bob: int, step: int, arm: float, lean: int) -> void:
	var body: String = s.get("body", "coat")
	var half := 3
	if body == "round": half = 4
	var top := 13 + bob
	var hip := 20
	var bx := CX + lean

	# legs: stride front/back
	var f_off := 2 * step
	if body != "cloak":
		c.rect(bx - 1 - f_off, hip, 2, FY - hip, s.pants[1])
		c.rect(bx - 1 + f_off, hip, 2, FY - hip, s.pants[2])
	c.rect(bx - 2 - f_off, FY - 1, 3, 2, s.boots[1])
	c.rect(bx - 1 + f_off, FY - 1, 4, 2, s.boots[2])
	c.px(bx + 2 + f_off, FY - 1, s.boots[3])

	if s.get("sack", false):
		c.shade_ellipse(bx - 4.0, top + 2.5, 3.6, 3.6, WPal.CREAM.slice(0, 3), -0.1)

	# back arm
	var arm_dx := int(round(arm * 2.0))
	c.rect(bx - 1 - arm_dx, top + 1, 2, 5, s.coat[0])

	var body_bottom := hip + (2 if body == "cloak" else 1)
	c.shade_box(bx - half, top, half * 2 + 1, body_bottom - top, s.coat, 0.05)
	if body in ["coat", "cloak", "round"]:
		c.shade_box(bx - half - 1, body_bottom - 2, half * 2 + 3, 2, s.coat, -0.05)
	if body != "cloak":
		c.hline(bx - half, bx + half, top + 4, s.trim[1])
	if s.has("scarf"):
		c.rect(bx - half, top, half * 2 + 1, 2, s.scarf[2])
		c.rect(bx - half - 2, top + 1, 2, 3, s.scarf[2])
	if body == "round":
		c.rect(bx + 1, top + 5, 3, body_bottom - top - 5, WPal.CREAM[2])
	if s.get("satchel", false):
		c.shade_ellipse(bx - half - 0.5, top + 6.5, 2.2, 2.4, WPal.WOOD.slice(2, 6))

	# front arm
	var reach: Vector2i = pose.get("reach", Vector2i.ZERO)
	if pose.get("arms_up", false):
		c.rect(bx + 1, top - 3, 2, 4, s.coat[2])
		c.rect(bx + 1, top - 4, 2, 1, s.skin[3])
	elif pose.get("eat", false):
		c.rect(bx + 1, top + 1, 2, 3, s.coat[2])
		c.rect(bx + 3, top - 1, 2, 2, s.skin[3])
	else:
		var ax := bx + arm_dx + reach.x
		var ay := top + 1 + reach.y
		c.rect(ax, ay, 2, 5, s.coat[2])
		c.rect(ax, ay + 5, 2, 1, s.skin[3])

	_head_side(c, s, pose, bx + 1, 9 + bob)


static func _head_side(c: PixelCanvas, s: Dictionary, pose: Dictionary, hx: int, hy: int) -> void:
	var head: String = s.get("head", "sprout")
	var cx := float(hx)
	var cy := float(hy)
	if head == "hood":
		c.shade_ellipse(cx - 0.5, cy, 5.4, 5.2, s.coat, -0.05)
		c.ellipse(cx + 2.2, cy + 1.0, 2.6, 3.0, WPal.INK)
		c.px(hx + 3, hy + 1, s.eye)
		c.px(hx + 3, hy, s.eye.darkened(0.3))
		c.px(hx - 4, hy - 5, s.coat[2])
		return

	c.shade_ellipse(cx, cy, 5.0, 4.7, s.skin, 0.05)
	var hair: Array = s.hair
	if head == "sprout":
		for y in range(hy - 5, hy + 3):
			for x in range(hx - 6, hx + 4):
				var nx := (x + 0.5 - (cx - 1.0)) / 5.2
				var ny := (y + 0.5 - (cy - 0.8)) / 5.0
				if nx * nx + ny * ny <= 1.0 and not (x > hx and y > hy - 1):
					c.px(x, y, c._ramp_dither(hair, 0.6 - nx * 0.35 - ny * 0.4, x, y))
		c.px(hx + 2, hy - 1, hair[2])
		var leaf: Array = WPal.LEAF
		c.vline(hx - 1, hy - 8, hy - 5, leaf[2])
		c.shade_ellipse(cx - 3.2, cy - 8.4, 2.4, 1.3, leaf.slice(2, 6))
		c.shade_ellipse(cx + 1.6, cy - 9.4, 2.4, 1.3, leaf.slice(2, 6))
	elif head == "ponytail":
		for y in range(hy - 5, hy + 2):
			for x in range(hx - 6, hx + 4):
				var nx := (x + 0.5 - (cx - 1.0)) / 5.2
				var ny := (y + 0.5 - (cy - 1.0)) / 4.6
				if nx * nx + ny * ny <= 1.0 and not (x > hx and y > hy - 2):
					c.px(x, y, c._ramp_dither(hair, 0.6 - nx * 0.3 - ny * 0.4, x, y))
		c.shade_ellipse(cx - 6.0, cy + 0.5, 1.8, 3.4, hair)
	elif head == "beehat":
		c.shade_ellipse(cx, cy - 2.4, 8.0, 2.4, WPal.CREAM, 0.05)
		c.shade_ellipse(cx - 0.5, cy - 5.0, 4.2, 3.0, WPal.CREAM, 0.1)
		c.hline(hx - 4, hx + 3, hy - 3, WPal.GOLD[2])
		for y in range(hy - 1, hy + 5):
			for x in range(hx - 1, hx + 6):
				if PixelCanvas.bayer(x, y) < 0.35 and c.is_solid(x, y):
					c.px(x, y, Color(WPal.CREAM[3].r, WPal.CREAM[3].g, WPal.CREAM[3].b, 0.55))

	var ey := hy + 1
	if pose.get("hurt", false):
		c.line(hx + 2, ey - 1, hx + 3, ey, s.eye)
		c.line(hx + 3, ey - 1, hx + 2, ey, s.eye)
	elif pose.get("blink", false):
		c.hline(hx + 2, hx + 3, ey, s.eye)
	else:
		c.vline(hx + 3, ey - 1, ey, s.eye)
		c.px(hx + 3, ey - 1, WPal.WHITE)
	c.px(hx + 2, ey + 1, Color(WPal.RED[4], 0.7))
	if pose.get("eat", false):
		c.rect(hx + 3, ey + 2, 2, 2, WPal.RED[1])


static func _hurt_flash(c: PixelCanvas) -> void:
	for y in c.h:
		for x in c.w:
			var col := c.img.get_pixel(x, y)
			if col.a > 0.5:
				c.img.set_pixel(x, y, col.lerp(Color("ff6a5a"), 0.35))


# ── rolled-up dodge ball ────────────────────────────────────────────────────

static func paint_roll(s: Dictionary, frame: int) -> PixelCanvas:
	var c := PixelCanvas.new(FW, FH, 3)
	var ang := frame * PI * 0.5
	var cy := 18.5
	c.shade_ellipse(CX, cy, 6.0, 5.6, s.coat, 0.05)
	# trim band rotating around the ball
	for i in 9:
		var t := ang + i * 0.18
		var x := int(round(CX + cos(t) * 5.0 - 0.5))
		var y := int(round(cy + sin(t) * 4.6 - 0.5))
		c.px(x, y, s.trim[2])
	# head / sprout peeking around the curl
	var hx := CX + cos(ang - PI * 0.5) * 3.5
	var hy := cy + sin(ang - PI * 0.5) * 3.2
	c.shade_ellipse(hx, hy, 2.6, 2.4, s.hair)
	if s.get("head", "") == "sprout":
		c.shade_ellipse(hx + cos(ang - PI * 0.5) * 2.6, hy + sin(ang - PI * 0.5) * 2.4, 1.6, 1.0, WPal.LEAF.slice(2, 6))
	c.outline(WPal.OUTLINE, 0.6)
	return c


# ── defeat / poof frames for enemies ────────────────────────────────────────

static func paint_collapse(s: Dictionary, frame: int) -> PixelCanvas:
	# frame 0: knocked back, 1: crumpled
	var c := PixelCanvas.new(FW, FH, 5)
	if frame == 0:
		c = paint(s, {"dir": Dir.DOWN, "hurt": true, "bob": 1, "lean": -1})
	else:
		c.shade_ellipse(CX, 21.0, 7.0, 3.0, s.coat, -0.05)
		c.shade_ellipse(CX - 4.0, 19.5, 3.4, 3.0, s.coat, 0.0)
		if s.get("sack", false):
			c.shade_ellipse(CX + 5.0, 20.0, 3.0, 2.6, WPal.CREAM.slice(0, 3))
		c.outline(WPal.OUTLINE, 0.6)
	return c
