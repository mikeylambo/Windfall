extends RefCounted
class_name TreePainter

## Orchard trees: six growth stages, leaf ramps tinted per element family,
## and per-element fruit with a 4-frame glint. Canopy and trunk are painted
## separately so the canopy can sway (fruit rides on the canopy node).
##
## All tree frames share a 48 x 64 texel canvas with the trunk base at (24, 60).

const TW := 48
const TH := 64
const BX := 24
const BY := 60


## Trunk + roots for a stage (SEED..ANCIENT = 1..6). Seed/Sprout have none.
static func trunk(stage: int) -> PixelCanvas:
	var c := PixelCanvas.new(TW, TH, 100 + stage)
	var bark: Array = WPal.BARK
	match stage:
		3:  # sapling: thin stem
			c.rect(BX - 1, BY - 14, 2, 14, bark[3])
			c.vline(BX - 1, BY - 14, BY - 1, bark[2])
		4:  # young
			c.shade_box(BX - 2, BY - 20, 4, 20, bark)
			c.line(BX + 1, BY - 14, BX + 5, BY - 19, bark[2])
		5:  # mature
			c.shade_box(BX - 3, BY - 26, 6, 26, bark)
			c.shade_box(BX - 5, BY - 4, 10, 4, bark, -0.1)
			c.line(BX - 2, BY - 18, BX - 8, BY - 26, bark[2])
			c.line(BX + 2, BY - 16, BX + 9, BY - 25, bark[2])
			c.vline(BX, BY - 22, BY - 6, bark[1])
		6:  # ancient: gnarled, rooted, mossy, with glowing rune knots
			c.shade_box(BX - 5, BY - 30, 10, 30, bark)
			for r in [-11, -7, 6, 10]:
				c.line(BX + int(sign(r)) * 3, BY - 3, BX + r, BY, bark[2])
				c.line(BX + int(sign(r)) * 3, BY - 2, BX + r, BY + 1, bark[1])
			c.line(BX - 3, BY - 22, BX - 12, BY - 34, bark[2])
			c.line(BX + 3, BY - 20, BX + 13, BY - 33, bark[2])
			c.vline(BX - 1, BY - 28, BY - 4, bark[1])
			c.vline(BX + 2, BY - 24, BY - 8, bark[1])
			c.speckle(WPal.MOSS.slice(2, 5), 0.18, Rect2i(BX - 5, BY - 12, 10, 12))
			c.px(BX, BY - 14, WPal.GOLD[4])
			c.px(BX, BY - 15, WPal.GOLD[3])
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Canopy for a stage tinted by family leaf ramp.
static func canopy(stage: int, fam: int) -> PixelCanvas:
	var c := PixelCanvas.new(TW, TH, 200 + stage * 10 + fam)
	var leaf: Array = WPal.FAMILY_LEAF.get(fam, WPal.LEAF)
	match stage:
		1:  # seed: soil mound with a seed peeking
			c.shade_ellipse(BX, BY - 2, 5, 2.5, WPal.SOIL.slice(1, 5))
			c.shade_ellipse(BX + 0.5, BY - 3.5, 1.6, 1.4, WPal.WOOD.slice(3, 6))
			c.px(BX, BY - 5, leaf[4])
		2:  # sprout: two seed leaves
			c.vline(BX, BY - 7, BY - 1, leaf[3])
			c.shade_ellipse(BX - 3, BY - 8, 3, 1.6, leaf.slice(2, 5))
			c.shade_ellipse(BX + 3.5, BY - 9, 3, 1.6, leaf.slice(2, 5))
			c.shade_ellipse(BX, BY - 1, 3, 1.3, WPal.SOIL.slice(1, 5))
		3:  # sapling
			for p in [Vector2(-4, -15), Vector2(4, -17), Vector2(-2, -20), Vector2(3, -12), Vector2(0, -22)]:
				c.shade_ellipse(BX + p.x, BY + p.y, 3.4, 2.2, leaf.slice(1, 5))
		4:  # young: small round crown
			_crown(c, BX, BY - 26, 11, 9, leaf, 3)
		5:  # mature: full layered crown
			_crown(c, BX, BY - 36, 19, 14, leaf, 5)
		6:  # ancient: towering, wider, with hanging tendrils
			_crown(c, BX, BY - 40, 22, 17, leaf, 7)
			for i in 6:
				var x := BX - 16 + i * 6 + (c.rng.randi() % 3)
				c.vline(x, BY - 30, BY - 30 + 4 + (c.rng.randi() % 6), leaf[1])
	c.outline(WPal.OUTLINE, 0.55)
	return c


static func _crown(c: PixelCanvas, cx: int, cy: int, rx: float, ry: float, leaf: Array, clumps: int) -> void:
	# back mass, then lit clumps on top for a painterly layered crown
	c.shade_ellipse(cx, cy + 1, rx, ry, leaf.slice(0, 4), -0.05, false)
	var pts := [Vector2(-0.45, -0.25), Vector2(0.45, -0.2), Vector2(0, -0.5), Vector2(-0.3, 0.3), Vector2(0.35, 0.35), Vector2(-0.6, 0.1), Vector2(0.6, 0.05)]
	for i in clumps:
		var p: Vector2 = pts[i % pts.size()]
		c.shade_ellipse(cx + p.x * rx, cy + p.y * ry, rx * 0.5, ry * 0.5, leaf.slice(1, 5), 0.0)
	# leaf sparkle highlights
	c.speckle([leaf[5], leaf[4]], 0.06, Rect2i(cx - int(rx), cy - int(ry), int(rx), int(ry)))
	# dark underside band
	for x in range(cx - int(rx), cx + int(rx)):
		for y in range(cy + int(ry * 0.6), cy + int(ry) + 2):
			if c.is_solid(x, y) and PixelCanvas.bayer(x, y) < 0.5:
				c.px(x, y, leaf[0])


## Fruit sprite per family: 4 frames (rest, glint x3). 8x8 texels.
static func fruit_frames(fam: int) -> Array:
	var r: Array = WPal.ELEMENT.get(fam, WPal.ELEMENT[4])
	var frames: Array = []
	for f in 4:
		var c := PixelCanvas.new(8, 9, 300 + fam)
		_fruit_shape(c, fam, r)
		if f > 0:
			# diagonal glint sweep
			var gx := 1 + f * 2
			c.px(gx, 2 + (3 - f), r[4])
			c.px(gx - 1, 3 + (3 - f), Color(r[4], 0.7))
			if f == 2:
				c.px(gx + 1, 1, Color.WHITE)
		c.outline(WPal.OUTLINE, 0.5)
		frames.append(c)
	return frames


## Each family's fruit gets its own silhouette so they read even when colour-blind.
static func _fruit_shape(c: PixelCanvas, fam: int, r: Array) -> void:
	var ramp := r.slice(0, 5)
	match fam:
		0:  # STORM voltberry: berry cluster
			c.shade_ellipse(2.8, 5.0, 2.0, 2.0, ramp)
			c.shade_ellipse(5.4, 5.2, 2.0, 2.0, ramp)
			c.shade_ellipse(4.0, 3.0, 2.0, 2.0, ramp, 0.05)
		1:  # EMBER cinderapple: apple with notch
			c.shade_ellipse(4.0, 5.0, 3.4, 3.0, ramp)
			c.px(4, 2, r[0])
		2:  # FROST rimepear: pear
			c.shade_ellipse(4.0, 5.6, 3.0, 2.6, ramp)
			c.shade_ellipse(4.0, 3.2, 1.8, 1.8, ramp, 0.05)
		3:  # TIDE brinemelon: round melon with stripes
			c.shade_ellipse(4.0, 4.8, 3.4, 3.2, ramp)
			c.vline(3, 3, 7, r[1])
			c.vline(5, 3, 7, r[1])
		4:  # VERDANT briarcherry: twin cherries
			c.shade_ellipse(2.6, 5.8, 1.9, 1.9, ramp)
			c.shade_ellipse(5.6, 5.4, 1.9, 1.9, ramp)
			c.line(3, 4, 4, 1, WPal.WOOD[3])
			c.line(5, 3, 4, 1, WPal.WOOD[3])
		5:  # GALE zephyr kiwi: oval with fuzz
			c.shade_ellipse(4.0, 4.8, 3.2, 2.6, ramp)
			c.px(1, 4, r[3])
			c.px(7, 5, r[3])
		6:  # UMBRA duskberry: teardrop
			c.shade_ellipse(4.0, 5.4, 2.8, 2.8, ramp)
			c.px(4, 2, r[2])
			c.px(4, 1, r[1])
		_:  # LUMEN starfruit: star
			c.poly(PackedVector2Array([Vector2(4, 0.5), Vector2(5.2, 3.4), Vector2(8, 3.6), Vector2(5.8, 5.6), Vector2(6.6, 8.5), Vector2(4, 6.8), Vector2(1.4, 8.5), Vector2(2.2, 5.6), Vector2(0, 3.6), Vector2(2.8, 3.4)]), r[2])
			c.px(3, 3, r[4])
			c.px(4, 4, r[3])
	# leaf on top (not on star / cherries)
	if fam != 7 and fam != 4:
		c.px(4, 1, WPal.LEAF[3])
		c.px(5, 0, WPal.LEAF[4])
