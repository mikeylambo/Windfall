extends RefCounted
class_name UIPainter

## 9-slice panels and widget skins. Baked at 3x (UI texel = 3 screen px).


## Wooden frame panel 24x24 (9-slice margins 7 texels).
static func panel_wood() -> PixelCanvas:
	var c := PixelCanvas.new(24, 24, 1)
	c.shade_box(0, 0, 24, 24, WPal.WOOD.slice(1, 6))
	for y in [0, 23]:
		c.hline(1, 22, y, WPal.OUTLINE)
	for x in [0, 23]:
		c.vline(x, 1, 22, WPal.OUTLINE)
	c.hline(2, 21, 1, WPal.WOOD[5])
	c.hline(2, 21, 22, WPal.WOOD[1])
	# inner parchment
	c.rect(5, 5, 14, 14, Color("2a1e22"))
	c.rect(6, 6, 12, 12, Color("3a2a2c"))
	c.hline(6, 17, 6, Color("4a3638"))
	# nails
	for p in [Vector2i(2, 2), Vector2i(21, 2), Vector2i(2, 21), Vector2i(21, 21)]:
		c.px(p.x, p.y, WPal.GOLD[3])
	return c


## Vine-wrapped panel for the Codex / dialogue.
static func panel_vine() -> PixelCanvas:
	var c := panel_wood()
	var leaf: Array = WPal.LEAF
	for i in 24:
		if i % 5 == 0:
			c.px(i, 0, leaf[3])
			c.px(i, 1, leaf[4])
			c.px(0, i, leaf[3])
			c.px(23, (i + 2) % 24, leaf[3])
	c.px(3, 1, leaf[4])
	c.px(4, 0, leaf[3])
	return c


## Parchment inset for lists and tooltips (12x12, margins 4).
static func panel_paper() -> PixelCanvas:
	var c := PixelCanvas.new(12, 12)
	c.rect(1, 1, 10, 10, WPal.CREAM[2])
	c.hline(1, 10, 1, WPal.CREAM[3])
	c.hline(1, 10, 10, WPal.CREAM[1])
	c.outline(WPal.WOOD[1], 1.0)
	return c


## Dark glass panel for the HUD chips (12x12, margins 4).
static func panel_dark() -> PixelCanvas:
	var c := PixelCanvas.new(12, 12)
	c.rect(1, 1, 10, 10, Color(0.12, 0.08, 0.12, 0.86))
	c.hline(2, 9, 1, Color(1, 0.94, 0.8, 0.18))
	c.outline(Color("4a3040"), 1.0)
	return c


## Item slot frames (20x20, margins 5).
static func slot(state: int) -> PixelCanvas:
	var c := PixelCanvas.new(20, 20)
	var rim: Color = [WPal.WOOD[2], WPal.GOLD[3], WPal.ELEMENT[5][2], WPal.STONE[1]][state]
	c.rect(0, 0, 20, 20, WPal.OUTLINE)
	c.rect(1, 1, 18, 18, rim)
	c.rect(2, 2, 16, 16, Color("2a1e24"))
	c.rect(3, 3, 14, 14, Color("362830"))
	c.hline(3, 16, 3, Color("44323a"))
	if state == 1:
		for p in [Vector2i(1, 1), Vector2i(18, 1), Vector2i(1, 18), Vector2i(18, 18)]:
			c.px(p.x, p.y, WPal.GOLD[4])
	return c


## Buttons 16x12 (margins 4): 0 normal, 1 hover/focus, 2 pressed, 3 disabled.
static func button(state: int) -> PixelCanvas:
	var c := PixelCanvas.new(16, 12)
	var ramp: Array = [WPal.WOOD.slice(2, 6), WPal.CLOTH_OCHRE.slice(1, 5), WPal.WOOD.slice(1, 4), WPal.STONE.slice(1, 4)][state]
	var top := 1 if state == 2 else 0
	c.rect(0, top, 16, 12 - top, WPal.OUTLINE)
	# flat body so 9-slice stretching stays clean; bevel lives in the margins
	c.rect(1, top + 1, 14, 9 - top, ramp[2])
	c.hline(1, 14, top + 1, ramp[ramp.size() - 1])
	c.hline(2, 13, top + 2, ramp[3] if ramp.size() > 3 else ramp[2])
	if state != 2:
		c.hline(1, 14, 10, ramp[0].darkened(0.3))
		c.hline(1, 14, 9, ramp[1])
	if state == 1:
		c.px(1, 1, WPal.GOLD[4])
		c.px(14, 1, WPal.GOLD[4])
	return c


## Bar frame (32x8, margins 3) and fills (4x4).
static func bar_frame() -> PixelCanvas:
	var c := PixelCanvas.new(32, 8)
	c.rect(0, 0, 32, 8, WPal.OUTLINE)
	c.rect(1, 1, 30, 6, Color("1e1418"))
	c.hline(1, 30, 1, Color("2e2228"))
	return c


static func bar_fill(ramp: Array) -> PixelCanvas:
	var c := PixelCanvas.new(4, 6)
	c.hline(0, 3, 0, ramp[3])
	c.rect(0, 1, 4, 3, ramp[2])
	c.rect(0, 4, 4, 2, ramp[1])
	return c


## Digestion ring for TextureProgressBar radial fill (24x24).
static func ring(col: Color, width: int = 3) -> PixelCanvas:
	var c := PixelCanvas.new(24, 24)
	for y in 24:
		for x in 24:
			var d := Vector2(x + 0.5 - 12.0, y + 0.5 - 12.0).length()
			if d <= 11.5 and d >= 11.5 - width:
				c.px(x, y, col)
	return c


## Glass terrarium jar for the stomach (88 x 40, margins 10).
static func jar() -> PixelCanvas:
	var c := PixelCanvas.new(40, 40)
	var glass := Color(0.08, 0.16, 0.17, 0.82)
	c.rect(2, 4, 36, 34, glass)
	# rim/lid
	c.shade_box(4, 0, 32, 5, WPal.WOOD.slice(2, 6))
	c.hline(4, 35, 0, WPal.WOOD[5])
	# soil & moss bed
	c.rect(3, 31, 34, 6, WPal.SOIL[2])
	c.hline(3, 36, 31, WPal.MOSS[3])
	c.speckle(WPal.MOSS.slice(2, 5), 0.3, Rect2i(3, 30, 34, 3), false)
	# glass highlights
	c.rect(3, 5, 34, 2, Color(0.3, 0.55, 0.52, 0.5))
	c.vline(4, 7, 28, Color(1, 1, 1, 0.45))
	c.vline(5, 9, 14, Color(1, 1, 1, 0.3))
	c.vline(35, 10, 30, Color(1, 1, 1, 0.18))
	c.outline(Color("2a4a4a"), 1.0)
	return c


## Key/button prompt cap (12x12, margins 4).
static func keycap() -> PixelCanvas:
	var c := PixelCanvas.new(12, 12)
	c.rect(0, 0, 12, 12, WPal.OUTLINE)
	c.rect(1, 1, 10, 9, WPal.CREAM[2])
	c.hline(1, 10, 1, WPal.CREAM[3])
	c.rect(1, 10, 10, 1, WPal.CREAM[0])
	return c


## Chip / pill used for pairing badges (12x10, margins 4).
static func chip() -> PixelCanvas:
	var c := PixelCanvas.new(12, 10)
	c.rect(1, 0, 10, 10, WPal.WHITE)
	c.rect(0, 1, 12, 8, WPal.WHITE)
	return c


## Speech/emote bubble (12x12) with tail.
static func bubble() -> PixelCanvas:
	var c := PixelCanvas.new(14, 14)
	c.ellipse(7, 6, 6.5, 5.5, WPal.WHITE)
	c.poly(PackedVector2Array([Vector2(5, 10), Vector2(9, 10), Vector2(6, 13.5)]), WPal.WHITE)
	c.outline(WPal.OUTLINE, 1.0)
	return c


## Harvest timing bar 48 x 10 with prime window.
static func harvest_bar() -> PixelCanvas:
	var c := PixelCanvas.new(50, 10)
	c.rect(0, 0, 50, 10, WPal.OUTLINE)
	c.rect(1, 1, 48, 8, Color("2a1e24"))
	for x in range(2, 48):
		var t := float(x - 2) / 45.0
		var col := WPal.RED[2].lerp(WPal.GOLD[2], clampf(1.0 - absf(t - 0.5) * 2.6, 0.0, 1.0))
		c.vline(x, 2, 7, col)
	# prime window 38%-62%
	var a := 2 + int(0.38 * 46)
	var b := 2 + int(0.62 * 46)
	c.rect(a, 2, b - a, 6, WPal.ELEMENT[4][3])
	c.hline(a, b - 1, 2, WPal.ELEMENT[4][4])
	c.vline(a, 1, 8, WPal.GOLD[4])
	c.vline(b - 1, 1, 8, WPal.GOLD[4])
	return c


static func harvest_cursor() -> PixelCanvas:
	var c := PixelCanvas.new(5, 14)
	c.poly(PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(2.5, 3.5)]), WPal.WHITE)
	c.rect(2, 3, 1, 9, WPal.WHITE)
	c.poly(PackedVector2Array([Vector2(0, 14), Vector2(5, 14), Vector2(2.5, 10.5)]), WPal.WHITE)
	c.outline(WPal.OUTLINE, 1.0)
	return c


## Focus brackets drawn around the interactable in focus (16x16, margins 6).
static func focus_brackets() -> PixelCanvas:
	var c := PixelCanvas.new(16, 16)
	var g: Color = WPal.GOLD[4]
	for p in [[0, 0, 1, 1], [15, 0, -1, 1], [0, 15, 1, -1], [15, 15, -1, -1]]:
		for i in 4:
			c.px(p[0] + i * p[2], p[1], g)
			c.px(p[0], p[1] + i * p[3], g)
	return c


## Enemy world HP bar: frame (14x4) and fill (12x2), cropped at runtime.
static func world_hp_frame() -> PixelCanvas:
	var c := PixelCanvas.new(14, 4)
	c.rect(0, 0, 14, 4, WPal.OUTLINE)
	c.rect(1, 1, 12, 2, Color("2a1e24"))
	return c


static func world_hp_fill() -> PixelCanvas:
	var c := PixelCanvas.new(12, 2)
	c.hline(0, 11, 0, WPal.RED[4])
	c.hline(0, 11, 1, WPal.RED[3])
	return c


## Soft radial vignette (not pixelated on purpose), 256x256.
static func vignette() -> Image:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var d := Vector2((x + 0.5) / 128.0 - 1.0, (y + 0.5) / 128.0 - 0.9).length() / 1.45
			var a := clampf((d - 0.38) / 0.62, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.06, 0.03, 0.08, a * a * 0.75))
	return img
