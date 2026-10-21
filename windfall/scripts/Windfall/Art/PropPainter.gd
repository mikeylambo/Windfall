extends RefCounted
class_name PropPainter

## Homestead props. Every prop's origin is its base-centre (where it touches
## the ground) so Y-sorting works out of the box.


## Farmhouse: 104 x 100 texels, base at (52, 96). Windows separate for night glow.
static func farmhouse() -> PixelCanvas:
	var c := PixelCanvas.new(104, 100, 61)
	var wall_top := 50
	var base := 96
	# stone foundation
	c.shade_box(10, base - 8, 84, 8, WPal.STONE.slice(1, 5))
	for x in range(12, 92, 7):
		c.vline(x, base - 8, base - 1, WPal.STONE[1])
	# timber walls
	c.shade_box(12, wall_top, 80, base - 8 - wall_top, WPal.CREAM, -0.05)
	for x in [12, 40, 64, 91]:
		c.rect(x, wall_top, 2 if x < 91 else 1, base - 8 - wall_top, WPal.WOOD[2])
	c.hline(12, 91, wall_top + 16, WPal.WOOD[2])
	# door
	c.shade_box(46, base - 30, 14, 22, WPal.WOOD.slice(1, 5))
	c.rect(45, base - 31, 16, 1, WPal.WOOD[1])
	c.px(57, base - 19, WPal.GOLD[3])
	c.vline(53, base - 29, base - 9, WPal.WOOD[1])
	# step
	c.shade_box(43, base - 8, 20, 3, WPal.STONE.slice(2, 5))
	# windows (dark glass by day; night glow added at runtime)
	for wx in [20, 72]:
		c.rect(wx, wall_top + 20, 14, 12, WPal.WOOD[1])
		c.rect(wx + 1, wall_top + 21, 12, 10, Color("2c3a5a"))
		c.rect(wx + 2, wall_top + 22, 4, 3, Color("6a8ab0"))
		c.vline(wx + 7, wall_top + 21, wall_top + 30, WPal.WOOD[2])
		c.hline(wx + 1, wx + 12, wall_top + 26, WPal.WOOD[2])
		# flower box
		c.shade_box(wx - 1, wall_top + 32, 16, 3, WPal.WOOD.slice(2, 6))
		for fx in range(wx, wx + 14, 3):
			c.px(fx, wall_top + 31, WPal.RED[3] if fx % 2 == 0 else WPal.GOLD[3])
	# roof: big gabled shingles
	var roof_pts := PackedVector2Array([Vector2(2, wall_top + 4), Vector2(52, 6), Vector2(102, wall_top + 4)])
	c.poly(roof_pts, WPal.ROOF[2])
	for y in range(8, wall_top + 4):
		var t := float(y - 6) / float(wall_top - 2)
		var half := int(t * 50.0)
		for x in range(52 - half, 52 + half):
			var row := (y - 6) % 5
			var shingle := (x + (y / 5) * 3) % 7
			var lum := 0.55 - float(x - 52) / 100.0 * 0.6
			if row == 0:
				lum -= 0.3
			if shingle == 0:
				lum -= 0.15
			c.px(x, y, c._ramp_dither(WPal.ROOF, lum, x, y))
	# eave
	c.hline(2, 101, wall_top + 4, WPal.ROOF[0])
	c.hline(4, 99, wall_top + 5, WPal.WOOD[1])
	# ridge
	c.line(52, 6, 52, 8, WPal.ROOF[4])
	# chimney (smoke emitted at runtime at texel (78, 10))
	c.shade_box(72, 8, 12, 22, WPal.STONE.slice(1, 5))
	c.shade_box(71, 6, 14, 3, WPal.STONE.slice(2, 5))
	c.rect(74, 6, 8, 1, WPal.INK)
	# dormer window
	c.rect(46, 26, 12, 12, WPal.CREAM[1])
	c.rect(48, 28, 8, 8, Color("2c3a5a"))
	c.rect(49, 29, 3, 2, Color("6a8ab0"))
	c.poly(PackedVector2Array([Vector2(44, 27), Vector2(52, 20), Vector2(60, 27)]), WPal.ROOF[3])
	# ivy
	c.speckle(WPal.MOSS.slice(2, 5), 0.25, Rect2i(12, wall_top + 2, 8, 30))
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Window glow mask (same canvas as farmhouse) used as an additive night sprite.
static func farmhouse_windows() -> PixelCanvas:
	var c := PixelCanvas.new(104, 100)
	for wx in [20, 72]:
		c.rect(wx + 1, 71, 12, 10, Color("ffcf6a"))
		c.vline(wx + 7, 71, 80, Color("d98a3a"))
		c.hline(wx + 1, wx + 12, 76, Color("d98a3a"))
	c.rect(48, 28, 8, 8, Color("ffcf6a"))
	return c


## Market stall: 60 x 56, base (30, 54). Awning, crates and displayed fruit.
static func market_stall() -> PixelCanvas:
	var c := PixelCanvas.new(64, 58, 77)
	var base := 54
	# posts
	for x in [6, 56]:
		c.shade_box(x, 12, 3, base - 12, WPal.WOOD.slice(1, 5))
	# counter
	c.shade_box(4, base - 18, 56, 18, WPal.WOOD.slice(1, 6))
	for x in range(6, 58, 6):
		c.vline(x, base - 16, base - 1, WPal.WOOD[2])
	c.shade_box(2, base - 21, 60, 4, WPal.WOOD.slice(2, 6))
	# fruit baskets on the counter, one per element
	var fams := [1, 0, 2, 4, 7]
	for i in fams.size():
		var bx := 9 + i * 11
		c.shade_ellipse(bx + 3, base - 22, 5, 2.4, WPal.WOOD.slice(2, 6))
		var r: Array = WPal.ELEMENT[fams[i]]
		for k in 3:
			c.shade_ellipse(bx + 1.5 + k * 1.8, base - 24.5 - (k % 2), 1.6, 1.6, r.slice(1, 5))
	# striped awning with scalloped edge
	for y in range(4, 14):
		for x in range(0, 64):
			var stripe := (x / 8) % 2 == 0
			var lum := 0.6 - float(y - 4) / 20.0
			c.px(x, y, c._ramp_dither(WPal.RED.slice(1, 5) if stripe else WPal.CREAM, lum, x, y))
	for x in range(0, 64):
		var sc := 14 + (1 if (x % 8) in [2, 3, 4, 5] else 0)
		c.vline(x, 14, sc, WPal.RED[2] if (x / 8) % 2 == 0 else WPal.CREAM[2])
	c.hline(0, 63, 4, WPal.CREAM[3])
	# crate stack beside
	c.blit(crate(), 50, base - 12)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func crate() -> PixelCanvas:
	var c := PixelCanvas.new(14, 12)
	c.shade_box(0, 0, 14, 12, WPal.WOOD.slice(2, 6))
	c.rect(0, 0, 14, 1, WPal.WOOD[5])
	c.line(1, 1, 12, 10, WPal.WOOD[2])
	c.rect(0, 5, 14, 1, WPal.WOOD[2])
	return c


static func crate_prop() -> PixelCanvas:
	var c := PixelCanvas.new(16, 16)
	c.blit(crate(), 1, 3)
	var r: Array = WPal.ELEMENT[1]
	c.shade_ellipse(5, 3, 2, 2, r.slice(1, 5))
	c.shade_ellipse(9, 3.5, 2, 2, WPal.ELEMENT[4].slice(1, 5))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func barrel() -> PixelCanvas:
	var c := PixelCanvas.new(14, 18)
	c.shade_ellipse(7, 9, 6, 8, WPal.WOOD.slice(1, 6))
	c.hline(1, 12, 4, WPal.STONE[2])
	c.hline(1, 12, 14, WPal.STONE[2])
	c.shade_ellipse(7, 2.5, 5, 1.6, WPal.WOOD.slice(3, 6))
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Fence: horizontal segment 16x14 and post-only 6x14.
static func fence_h() -> PixelCanvas:
	var c := PixelCanvas.new(16, 14)
	c.shade_box(0, 4, 16, 2, WPal.WOOD.slice(2, 6))
	c.shade_box(0, 8, 16, 2, WPal.WOOD.slice(1, 5))
	c.shade_box(0, 1, 3, 13, WPal.WOOD.slice(1, 6))
	c.px(1, 0, WPal.WOOD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func fence_post() -> PixelCanvas:
	var c := PixelCanvas.new(6, 16)
	c.shade_box(1, 2, 4, 14, WPal.WOOD.slice(1, 6))
	c.px(2, 1, WPal.WOOD[4])
	c.px(3, 1, WPal.WOOD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Hedge block 18 x 16.
static func hedge(variant: int) -> PixelCanvas:
	var c := PixelCanvas.new(20, 18, 900 + variant)
	c.shade_ellipse(10, 10, 9.5, 7.5, WPal.LEAF.slice(0, 5), -0.05)
	c.shade_ellipse(6, 8, 5, 4.5, WPal.LEAF.slice(1, 6))
	c.shade_ellipse(14, 8.5, 5, 4.5, WPal.LEAF.slice(1, 6))
	if variant % 3 == 0:
		for i in 4:
			c.px(c.rng.randi_range(4, 16), c.rng.randi_range(5, 12), WPal.RED[3] if variant % 2 == 0 else WPal.CREAM[3])
	c.outline(WPal.OUTLINE, 0.55)
	return c


## Border tree: tall pine or round oak, 40 x 56, base (20, 54).
static func border_tree(variant: int) -> PixelCanvas:
	var c := PixelCanvas.new(40, 58, 1000 + variant)
	c.shade_box(18, 40, 5, 16, WPal.BARK)
	if variant % 2 == 0:
		# pine tiers
		for i in 4:
			var y := 42 - i * 9
			var hw := 17 - i * 3
			c.poly(PackedVector2Array([Vector2(20 - hw, y), Vector2(20, y - 14), Vector2(20 + hw, y)]), WPal.GRASS_WILD[1])
			for yy in range(y - 13, y):
				for xx in range(20 - hw, 20):
					if c.is_solid(xx, yy) and PixelCanvas.bayer(xx, yy) < 0.5:
						c.px(xx, yy, WPal.GRASS_WILD[2])
			c.hline(20 - hw + 2, 20 + hw - 2, y - 1, WPal.GRASS_WILD[0])
		c.px(19, 6, WPal.GRASS_WILD[3])
	else:
		_round_crown(c, 20, 26, 17, 15, WPal.LEAF)
	c.outline(WPal.OUTLINE, 0.55)
	return c


static func _round_crown(c: PixelCanvas, cx: int, cy: int, rx: float, ry: float, leaf: Array) -> void:
	c.shade_ellipse(cx, cy, rx, ry, leaf.slice(0, 4), -0.05)
	c.shade_ellipse(cx - rx * 0.4, cy - ry * 0.3, rx * 0.55, ry * 0.5, leaf.slice(1, 6))
	c.shade_ellipse(cx + rx * 0.4, cy - ry * 0.15, rx * 0.5, ry * 0.5, leaf.slice(1, 6))
	c.shade_ellipse(cx, cy - ry * 0.55, rx * 0.5, ry * 0.45, leaf.slice(2, 6))


static func bush(variant: int) -> PixelCanvas:
	var c := PixelCanvas.new(16, 12, 1100 + variant)
	c.shade_ellipse(8, 7, 7.5, 5, WPal.LEAF.slice(1, 6))
	if variant % 2 == 0:
		c.px(5, 5, WPal.CREAM[3])
		c.px(10, 4, WPal.RED[4])
	c.outline(WPal.OUTLINE, 0.55)
	return c


static func rock(variant: int) -> PixelCanvas:
	var c := PixelCanvas.new(14, 10, 1200 + variant)
	c.shade_ellipse(7, 6, 6 - variant % 2, 4, WPal.STONE.slice(1, 5))
	c.speckle([WPal.MOSS[3]], 0.12, Rect2i(1, 1, 12, 4))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func lantern() -> PixelCanvas:
	var c := PixelCanvas.new(10, 26)
	c.shade_box(4, 6, 2, 20, WPal.WOOD.slice(1, 5))
	c.hline(4, 8, 6, WPal.WOOD[2])
	c.shade_box(5, 7, 4, 6, WPal.STONE.slice(0, 3))
	c.rect(6, 8, 2, 4, Color("ffcf6a"))
	c.hline(5, 8, 6, WPal.STONE[3])
	c.outline(WPal.OUTLINE, 0.6)
	return c


## East gate arch with signboard: 48 x 44, base (24, 42).
static func gate() -> PixelCanvas:
	var c := PixelCanvas.new(48, 46)
	for x in [4, 40]:
		c.shade_box(x, 10, 5, 36, WPal.WOOD.slice(1, 6))
	c.shade_box(0, 6, 48, 5, WPal.WOOD.slice(1, 6))
	c.hline(0, 47, 6, WPal.WOOD[5])
	# hanging sign
	c.vline(17, 11, 14, WPal.STONE[2])
	c.vline(30, 11, 14, WPal.STONE[2])
	c.shade_box(13, 14, 22, 9, WPal.WOOD.slice(2, 6))
	# arrow glyph
	c.hline(17, 28, 18, WPal.CREAM[3])
	c.line(26, 16, 29, 18, WPal.CREAM[3])
	c.line(26, 20, 29, 18, WPal.CREAM[3])
	# vines
	c.speckle(WPal.LEAF.slice(2, 6), 0.35, Rect2i(0, 5, 48, 7))
	c.speckle(WPal.LEAF.slice(2, 5), 0.25, Rect2i(4, 10, 5, 20))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func beehive() -> PixelCanvas:
	var c := PixelCanvas.new(16, 20)
	c.shade_box(2, 16, 12, 4, WPal.WOOD.slice(1, 5))
	for i in 3:
		c.shade_box(1, 4 + i * 4, 14, 4, WPal.CLOTH_OCHRE.slice(1, 5))
		c.hline(1, 14, 4 + i * 4, WPal.CLOTH_OCHRE[4])
	c.shade_box(0, 1, 16, 3, WPal.WOOD.slice(2, 6))
	c.rect(7, 13, 3, 2, WPal.INK)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func reeds() -> PixelCanvas:
	var c := PixelCanvas.new(12, 16, 1300)
	for i in 5:
		var x := 1 + i * 2 + c.rng.randi_range(0, 1)
		var top := c.rng.randi_range(1, 6)
		c.vline(x, top, 15, WPal.MOSS[2 + i % 2])
		if i % 2 == 0:
			c.vline(x, top, top + 2, WPal.WOOD[2])
	c.outline(WPal.OUTLINE, 0.5)
	return c


static func stump() -> PixelCanvas:
	var c := PixelCanvas.new(16, 12)
	c.shade_box(3, 4, 10, 8, WPal.BARK)
	c.shade_ellipse(8, 4, 5, 2, WPal.WOOD.slice(3, 6))
	c.px(8, 4, WPal.WOOD[2])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func blob_shadow(rx: int, ry: int) -> PixelCanvas:
	var c := PixelCanvas.new(rx * 2 + 2, ry * 2 + 2)
	c.ellipse(rx + 1, ry + 1, rx, ry, WPal.SHADOW)
	return c


## Scarecrow 24 x 40, base (12, 39).
static func scarecrow() -> PixelCanvas:
	var c := PixelCanvas.new(26, 42, 1400)
	c.shade_box(12, 12, 2, 30, WPal.WOOD.slice(1, 5))
	c.shade_box(2, 15, 22, 2, WPal.WOOD.slice(1, 5))
	# patched shirt
	c.shade_box(7, 14, 12, 12, WPal.CLOTH_BLUE.slice(1, 5))
	c.rect(9, 18, 3, 3, WPal.RED[3])
	c.hline(7, 18, 25, WPal.CREAM[1])
	for x in [7, 10, 13, 16, 18]:
		c.vline(x, 26, 28, WPal.GOLD[2])  # straw tufts
	c.px(2, 17, WPal.GOLD[3]); c.px(23, 17, WPal.GOLD[3])
	# sack head + straw hat
	c.shade_ellipse(13, 9, 4.5, 4.5, WPal.CREAM.slice(0, 3))
	c.px(11, 9, WPal.INK); c.px(15, 9, WPal.INK)
	c.hline(11, 15, 11, WPal.WOOD[2])
	c.shade_ellipse(13, 5.5, 8, 2, WPal.GOLD.slice(1, 4))
	c.shade_ellipse(13, 3.5, 4, 2.4, WPal.GOLD.slice(1, 4))
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Stone well with a little roof, 28 x 36, base (14, 35).
static func well() -> PixelCanvas:
	var c := PixelCanvas.new(30, 38, 1500)
	c.shade_ellipse(15, 29, 12, 7, WPal.STONE.slice(1, 5))
	c.ellipse(15, 27, 8.5, 4, WPal.WATER[1])
	c.px(12, 26, WPal.WATER[4])
	for y in range(30, 36):
		c.hline(4, 25, y, WPal.STONE[2] if (y % 3) else WPal.STONE[1])
	c.shade_box(4, 8, 2, 22, WPal.WOOD.slice(1, 5))
	c.shade_box(24, 8, 2, 22, WPal.WOOD.slice(1, 5))
	c.poly(PackedVector2Array([Vector2(1, 10), Vector2(15, 1), Vector2(29, 10)]), WPal.ROOF[2])
	c.hline(1, 28, 10, WPal.ROOF[0])
	c.hline(6, 24, 14, WPal.WOOD[3])
	c.vline(15, 14, 20, WPal.STONE[3])
	c.shade_box(13, 20, 4, 3, WPal.WOOD.slice(2, 6))
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Wildflower patch 20 x 12 (variant picks a colour pair).
static func flower_patch(variant: int) -> PixelCanvas:
	var c := PixelCanvas.new(22, 14, 1600 + variant)
	var pairs := [[Color("fff7e6"), Color("f2c94e")], [Color("ff9bb4"), Color("fff0a0")], [Color("b9a4ff"), Color("fff7e6")], [Color("f2c94e"), Color("d9784e")]]
	var pair: Array = pairs[variant % pairs.size()]
	for i in 9:
		var x := c.rng.randi_range(2, 19)
		var y := c.rng.randi_range(4, 12)
		c.vline(x, y, mini(y + 2, 13), WPal.LEAF[2])
		c.px(x, y, pair[0]); c.px(x + 1, y, pair[0]); c.px(x, y - 1, pair[0])
		c.px(x + 1, y - 1, pair[1])
	c.outline(WPal.OUTLINE, 0.4)
	return c
