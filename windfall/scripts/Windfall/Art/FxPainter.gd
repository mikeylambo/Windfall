extends RefCounted
class_name FxPainter

## Particle and effect textures.


## Smooth radial glow used by additive light sprites (not pixelated on purpose:
## light should feel soft against crisp pixels).
static func soft_glow(size: int = 64) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length() / r
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img


## Pixel-dithered glow disc (for in-world auras that should stay "pixel").
static func pixel_glow(r: int) -> PixelCanvas:
	var c := PixelCanvas.new(r * 2, r * 2)
	for y in r * 2:
		for x in r * 2:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length() / float(r)
			if d < 1.0 and PixelCanvas.bayer(x, y) < (1.0 - d) * 1.2:
				c.px(x, y, Color(1, 1, 1, 0.85))
	return c


static func dot(size: int) -> PixelCanvas:
	var c := PixelCanvas.new(size, size)
	c.ellipse(size * 0.5, size * 0.5, size * 0.5, size * 0.5, Color.WHITE)
	return c


static func spark() -> PixelCanvas:
	var c := PixelCanvas.new(5, 5)
	c.vline(2, 0, 4, Color(1, 1, 1, 0.8))
	c.hline(0, 4, 2, Color(1, 1, 1, 0.8))
	c.px(2, 2, Color.WHITE)
	return c


static func shard() -> PixelCanvas:
	var c := PixelCanvas.new(4, 6)
	c.poly(PackedVector2Array([Vector2(2, 0), Vector2(4, 3), Vector2(2, 6), Vector2(0, 3)]), Color.WHITE)
	c.px(1, 2, Color(1, 1, 1, 1))
	return c


static func leaf() -> PixelCanvas:
	var c := PixelCanvas.new(5, 4)
	c.ellipse(2.5, 2, 2.5, 1.6, WPal.LEAF[3])
	c.px(1, 1, WPal.LEAF[5])
	return c


## Dust puff 4 frames, 10x10 each.
static func dust_frames() -> PixelCanvas:
	var frames: Array = []
	for f in 4:
		var c := PixelCanvas.new(10, 10)
		var r := 2.0 + f * 1.2
		var a := 0.9 - f * 0.2
		c.ellipse(5, 6, r, r * 0.8, Color(WPal.DIRT[4], a))
		c.ellipse(4, 5, r * 0.6, r * 0.5, Color(WPal.CREAM[3], a))
		frames.append(c)
	return PixelCanvas.pack(frames, 4)


## Smoke puff 4 frames, 12x12.
static func smoke_frames() -> PixelCanvas:
	var frames: Array = []
	for f in 4:
		var c := PixelCanvas.new(12, 12)
		var r := 2.5 + f * 1.3
		c.ellipse(6, 6, r, r, Color(WPal.STONE[3], 0.8 - f * 0.15))
		c.ellipse(5, 5, r * 0.6, r * 0.6, Color(WPal.STONE[4], 0.7 - f * 0.15))
		frames.append(c)
	return PixelCanvas.pack(frames, 4)


## Death poof 5 frames, 24x24.
static func poof_frames() -> PixelCanvas:
	var frames: Array = []
	for f in 5:
		var c := PixelCanvas.new(24, 24, 77)
		var r := 3.0 + f * 2.2
		for i in 7:
			var a := i * TAU / 7.0 + f * 0.3
			var d := r
			var cr := maxf(3.6 - f * 0.6, 0.8)
			c.ellipse(12 + cos(a) * d, 12 + sin(a) * d, cr, cr, WPal.CREAM[3] if i % 2 == 0 else WPal.STONE[4])
		if f < 2:
			c.ellipse(12, 12, 4 - f * 2, 4 - f * 2, WPal.WHITE)
		frames.append(c)
	return PixelCanvas.pack(frames, 5)


## Sparkle star 4 frames, 7x7.
static func sparkle_frames() -> PixelCanvas:
	var frames: Array = []
	for f in 4:
		var c := PixelCanvas.new(7, 7)
		var l: int = [1, 3, 2, 1][f]
		c.vline(3, 3 - l, 3 + l, Color.WHITE)
		c.hline(3 - l, 3 + l, 3, Color.WHITE)
		frames.append(c)
	return PixelCanvas.pack(frames, 4)


## Weapon slash arc, 3 frames, 40x40, drawn facing right.
static func slash_frames(width: int, span: float) -> PixelCanvas:
	var frames: Array = []
	for f in 3:
		var c := PixelCanvas.new(40, 40)
		var start := -span * 0.5
		var end := start + span * (0.5 + f * 0.25)
		var steps := 40
		for i in steps:
			var t := float(i) / steps
			var a := lerpf(start, end, t)
			var tail := t
			var w := int(round(width * tail))
			for k in w + 1:
				var r := 16.0 - k
				var x := int(round(20 + cos(a) * r))
				var y := int(round(20 + sin(a) * r))
				var col := Color.WHITE if k == 0 else Color(1, 0.95, 0.75, 0.8 - k * 0.15)
				if f == 2:
					col.a *= 0.5
				c.px(x, y, col)
		frames.append(c)
	return PixelCanvas.pack(frames, 3)


## Expanding shockwave ring 32x32 (single, scaled at runtime).
static func shock_ring() -> PixelCanvas:
	var c := PixelCanvas.new(32, 32)
	for y in 32:
		for x in 32:
			var d := Vector2(x + 0.5 - 16.0, y + 0.5 - 16.0).length()
			if d <= 15.5 and d >= 13.0:
				c.px(x, y, Color(1, 1, 1, 0.9 if d > 14.0 else 0.5))
	return c


## Projectile cores per family: 16x16 texels, facing right.
static func projectile(fam: int) -> PixelCanvas:
	var c := PixelCanvas.new(16, 16, 600 + fam)
	var r: Array = WPal.ELEMENT[fam]
	match fam:
		0:  # storm orb with crackle
			c.shade_ellipse(9, 8, 3.5, 3.5, r.slice(2, 5), 0.2)
			c.line(2, 8, 5, 6, r[3])
			c.line(5, 6, 7, 9, r[3])
			c.px(9, 7, Color.WHITE)
		1:  # fireball with tail
			c.ellipse(6, 8, 4, 2.6, r[1])
			c.ellipse(4, 8, 3, 1.6, r[2])
			c.shade_ellipse(10, 8, 4, 4, r.slice(2, 5), 0.25)
			c.ellipse(11, 8, 1.8, 1.8, r[4])
		2:  # ice lance
			c.poly(PackedVector2Array([Vector2(1, 8), Vector2(9, 5), Vector2(15, 8), Vector2(9, 11)]), r[2])
			c.line(3, 8, 14, 8, r[4])
			c.px(10, 6, Color.WHITE)
		3:  # water orb
			c.shade_ellipse(9, 8, 4, 4, r.slice(1, 5), 0.2)
			c.px(8, 6, Color.WHITE)
			c.px(3, 8, r[3])
			c.px(5, 10, r[3])
		7:  # light beam bolt
			c.rect(0, 7, 16, 2, r[3])
			c.hline(2, 15, 7, Color.WHITE)
			c.ellipse(13, 8, 2.5, 2.5, r[4])
		_:  # seed / generic bolt
			c.shade_ellipse(9, 8, 3, 3, r.slice(1, 5), 0.2)
			c.px(8, 7, r[4])
			c.hline(3, 6, 8, Color(r[3], 0.6))
	c.outline(r[0].darkened(0.4), 0.6)
	return c


## Quickroot combat sprout per family (24 x 28), base (12, 26).
static func quickroot(fam: int) -> PixelCanvas:
	var c := PixelCanvas.new(24, 28, 700 + fam)
	var r: Array = WPal.ELEMENT[fam]
	var leaf: Array = WPal.FAMILY_LEAF[fam]
	c.shade_ellipse(12, 25, 7, 2.6, WPal.SOIL.slice(1, 5))
	c.vline(12, 10, 24, leaf[2])
	c.vline(11, 14, 24, leaf[1])
	c.shade_ellipse(7, 18, 4, 2, leaf.slice(1, 6))
	c.shade_ellipse(17, 16, 4, 2, leaf.slice(1, 6))
	match fam:
		0:  # lightning rod: crystal tip
			c.poly(PackedVector2Array([Vector2(12, 1), Vector2(15, 7), Vector2(12, 12), Vector2(9, 7)]), r[2])
			c.line(12, 2, 12, 10, r[4])
		1:  # fire bloom
			for i in 5:
				var a := i * TAU / 5.0
				c.shade_ellipse(12 + cos(a) * 3.4, 8 + sin(a) * 3.4, 2.4, 2.4, r.slice(1, 5))
			c.ellipse(12, 8, 2, 2, r[4])
		2:  # glacial spire
			c.poly(PackedVector2Array([Vector2(12, 0), Vector2(16, 12), Vector2(8, 12)]), r[2])
			c.line(12, 1, 13, 11, r[4])
		4:  # thorn barricade
			for i in 4:
				c.line(12, 10, 6 + i * 4, 2, leaf[1])
			c.shade_ellipse(12, 9, 3, 3, r.slice(1, 5))
		_:
			c.shade_ellipse(12, 8, 4, 4, r.slice(1, 5), 0.1)
			c.ellipse(12, 8, 1.6, 1.6, r[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


## Butterfly, 2 frames (wings open / closed), 7x5 each. Tinted at runtime.
static func butterfly_frames() -> PixelCanvas:
	var frames: Array = []
	for f in 2:
		var c := PixelCanvas.new(7, 5)
		if f == 0:
			c.rect(0, 0, 3, 2, Color.WHITE); c.rect(4, 0, 3, 2, Color.WHITE)
			c.rect(1, 2, 2, 2, Color(0.85, 0.85, 0.85)); c.rect(4, 2, 2, 2, Color(0.85, 0.85, 0.85))
		else:
			c.rect(2, 0, 1, 3, Color.WHITE); c.rect(4, 0, 1, 3, Color.WHITE)
		c.vline(3, 1, 4, WPal.INK)
		frames.append(c)
	return PixelCanvas.pack(frames, 2)


## Ground ring under the player at night, 24 x 10.
static func ground_ring() -> PixelCanvas:
	var c := PixelCanvas.new(26, 12)
	for y in 12:
		for x in 26:
			var d := Vector2((x + 0.5 - 13.0) / 12.0, (y + 0.5 - 6.0) / 5.0).length()
			if d <= 1.0 and d >= 0.74:
				c.px(x, y, Color(1, 1, 1, 0.9 if d > 0.86 else 0.45))
	return c


## Blight spots: sickly speckle overlay for a canopy (48 x 64, same canvas).
static func blight_overlay() -> PixelCanvas:
	var c := PixelCanvas.new(48, 64, 2100)
	var cols := [Color("5a4a6a"), Color("7a6a3a"), Color("3a2a3a")]
	for i in 70:
		var x := c.rng.randi_range(6, 41)
		var y := c.rng.randi_range(10, 40)
		c.px(x, y, cols[i % 3])
		if i % 4 == 0:
			c.px(x + 1, y, cols[(i + 1) % 3])
	return c


static func petal() -> PixelCanvas:
	var c := PixelCanvas.new(4, 3)
	c.rect(0, 0, 3, 2, Color.WHITE)
	c.px(3, 1, Color(1, 1, 1, 0.8))
	c.px(1, 2, Color(1, 1, 1, 0.8))
	return c


static func snowflake() -> PixelCanvas:
	var c := PixelCanvas.new(3, 3)
	c.px(1, 0, Color.WHITE); c.px(0, 1, Color.WHITE); c.px(1, 1, Color.WHITE); c.px(2, 1, Color.WHITE); c.px(1, 2, Color.WHITE)
	return c
