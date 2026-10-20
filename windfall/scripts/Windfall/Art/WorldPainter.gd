extends RefCounted
class_name WorldPainter

## Ground layer + tilled soil beds. Ground is baked at texel resolution
## (1 texel = 2 world px) from WorldLayout so paths and props line up.

const FLOWERS := [
	[Color("fff7e6"), Color("f2c94e")],
	[Color("ff9bb4"), Color("fff0a0")],
	[Color("b9a4ff"), Color("fff7e6")],
	[Color("f2c94e"), Color("d9784e")],
	[Color("8eeaf0"), Color("fff7e6")],
]


static func ground() -> PixelCanvas:
	var tw := int(WorldLayout.SIZE.x / 2)
	var th := int(WorldLayout.SIZE.y / 2)
	var c := PixelCanvas.new(tw, th, 4242)
	var n := FastNoiseLite.new()
	n.seed = 7
	n.frequency = 0.018
	var n2 := FastNoiseLite.new()
	n2.seed = 99
	n2.frequency = 0.09
	var img := c.img

	for y in th:
		for x in tw:
			var p := Vector2(x * 2 + 1, y * 2 + 1)
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var fine := n2.get_noise_2d(x, y) * 0.5 + 0.5
			var lum := v * 0.7 + fine * 0.3
			# wilds fade: darker, cooler grass to the east
			var wild := clampf((p.x - (WorldLayout.WILDS.position.x - 160.0)) / 220.0, 0.0, 1.0)
			var g: Array = WorldPainter._grass_ramp(wild)
			var col: Color = c._ramp_dither(g, 0.42 + lum * 0.3, x, y)

			# dirt paths with soft dithered edges
			var pd := WorldLayout.dist_to_paths(p)
			if pd < 8.0:
				var dl := 0.35 + fine * 0.35
				var dirt: Color = c._ramp_dither(WPal.DIRT, dl, x, y)
				if pd < 0.0:
					col = dirt
					if pd > -4.0:
						col = WPal.DIRT[1]
				elif PixelCanvas.bayer(x, y) > pd / 8.0:
					col = dirt if pd < 3.0 else g[1]

			# pond with sandy shore
			var pr := WorldLayout.in_pond(p)
			if pr < 1.18:
				if pr < 1.0:
					var depth := 1.0 - pr
					col = c._ramp_dither(WPal.WATER, 0.72 - depth * 0.45 + fine * 0.1, x, y)
					if pr > 0.9:
						col = WPal.WATER[4]
				else:
					col = WPal.DIRT[3] if PixelCanvas.bayer(x, y) < (1.18 - pr) * 6.0 else WPal.DIRT[2]
			img.set_pixel(x, y, col)

	# grass tufts & flowers (skip paths/pond/house footprint/orchard beds)
	var rng := c.rng
	for i in 9000:
		var x := rng.randi_range(1, tw - 2)
		var y := rng.randi_range(2, th - 2)
		var p := Vector2(x * 2, y * 2)
		if WorldLayout.dist_to_paths(p) < 8.0 or WorldLayout.in_pond(p) < 1.25:
			continue
		var wild := clampf((p.x - (WorldLayout.WILDS.position.x - 160.0)) / 220.0, 0.0, 1.0)
		var g: Array = WorldPainter._grass_ramp(wild)
		var r := rng.randf()
		if r < 0.78:
			# grass tuft: dark base, light tip
			c.px(x, y, g[1])
			c.px(x, y - 1, g[4])
			if rng.randf() < 0.5:
				c.px(x + 1, y, g[1])
				c.px(x + 1, y - 2, g[3])
		elif _flower_ok(p):
			var f: Array = FLOWERS[rng.randi() % FLOWERS.size()]
			for k in rng.randi_range(2, 4):
				var fx := x + rng.randi_range(-3, 3)
				var fy := y + rng.randi_range(-2, 2)
				c.px(fx, fy + 1, g[1])
				c.px(fx, fy, f[0])
				c.px(fx + 1, fy, f[1])
	# path pebbles
	for i in 1400:
		var x := rng.randi_range(0, tw - 1)
		var y := rng.randi_range(0, th - 1)
		if WorldLayout.dist_to_paths(Vector2(x * 2, y * 2)) < -4.0:
			c.px(x, y, WPal.DIRT[4])
			c.px(x, y + 1, WPal.DIRT[0])
	return c


static func _grass_ramp(wild: float) -> Array:
	if wild <= 0.0:
		return WPal.GRASS
	if wild >= 1.0:
		return WPal.GRASS_WILD + [WPal.GRASS[4]]
	var out: Array = []
	for i in 5:
		out.append(WPal.GRASS[i].lerp(WPal.GRASS_WILD[i], wild))
	out.append(WPal.GRASS[5].lerp(WPal.GRASS[4], wild))
	return out


static func _flower_ok(p: Vector2) -> bool:
	for pl in WorldLayout.PLOTS:
		if p.distance_to(pl) < 70.0:
			return false
	return p.distance_to(WorldLayout.HOUSE) > 120.0


## A raised soil bed (40 x 30 texels) for an affinity, dry or watered.
static func soil_bed(soil: int, wet: bool) -> PixelCanvas:
	var c := PixelCanvas.new(40, 30, 500 + soil)
	var r: Array = WPal.SOIL_TYPES.get(soil, WPal.SOIL_TYPES[0])
	var base: Array = r.slice(0, 4)
	if wet:
		base = [r[0].darkened(0.3), r[0].darkened(0.1), r[1], r[2].darkened(0.15)]
	# wooden frame
	c.shade_box(0, 2, 40, 28, WPal.WOOD.slice(1, 6))
	c.hline(0, 39, 2, WPal.WOOD[5])
	# soil interior with tilled furrows
	for y in range(5, 27):
		for x in range(3, 37):
			var furrow := (y - 5) % 4
			var lum := 0.55 if furrow == 0 else (0.25 if furrow == 3 else 0.45)
			lum += (c.rng.randf() - 0.5) * 0.15
			c.px(x, y, c._ramp_dither(base, lum, x, y))
	# affinity signature detail
	var accent: Color = r[4]
	match soil:
		1:  # ash: glowing ember flecks
			for i in 10:
				c.px(c.rng.randi_range(4, 35), c.rng.randi_range(6, 25), accent)
		2:  # rime: frost crystals
			for i in 12:
				var x := c.rng.randi_range(4, 35)
				var y := c.rng.randi_range(6, 25)
				c.px(x, y, accent)
				c.px(x + 1, y, r[3])
		3:  # silt: damp puddle sheen
			c.ellipse(28, 20, 4, 2, Color(accent, 0.55))
			c.px(27, 19, WPal.WHITE)
		4:  # stormglass: violet glass shards
			for i in 7:
				var x := c.rng.randi_range(4, 34)
				var y := c.rng.randi_range(6, 24)
				c.px(x, y, accent)
				c.px(x, y + 1, r[2])
				c.px(x + 1, y + 1, r[1])
		5:  # ley: golden rune lines
			c.line(8, 9, 14, 9, accent)
			c.line(26, 21, 32, 18, accent)
			c.px(20, 14, accent)
			c.px(19, 15, accent)
			c.px(21, 15, accent)
	if wet:
		for i in 6:
			c.px(c.rng.randi_range(4, 35), c.rng.randi_range(6, 25), Color(WPal.WATER[4], 0.8))
	# corner posts
	for x in [0, 37]:
		c.shade_box(x, 0, 3, 5, WPal.WOOD.slice(2, 6))
		c.shade_box(x, 25, 3, 5, WPal.WOOD.slice(2, 6))
	c.outline(WPal.OUTLINE, 0.6)
	return c
