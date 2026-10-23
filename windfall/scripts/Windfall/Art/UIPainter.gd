extends RefCounted
class_name UIPainter

## 9-slice panels and widget skins. Baked at 3x (UI texel = 3 screen px).


## Wooden frame panel 32x32 (9-slice margins 10 texels): a bevelled dark-oak
## band with brass corner brackets around a plum interior. Edges are uniform
## along their length so 9-slice stretching never smears them; all ornament
## lives in the corners.
const FRAME := 7


static func panel_wood() -> PixelCanvas:
	var c := PixelCanvas.new(32, 32, 1)
	var n := 32
	var band: Array = [WPal.WOOD[1], WPal.WOOD[4], WPal.WOOD[3], WPal.WOOD[3], WPal.WOOD[2], WPal.WOOD[2], WPal.WOOD[1]]
	# the band: each ring is one tone, lit from the top-left (light top/left, shade bottom/right)
	for i in FRAME:
		var lit: Color = band[i]
		var shade: Color = band[i].darkened(0.28) if i > 0 else band[i]
		c.hline(i, n - 1 - i, i, lit)
		c.vline(i, i, n - 1 - i, lit)
		c.hline(i, n - 1 - i, n - 1 - i, shade)
		c.vline(n - 1 - i, i, n - 1 - i, shade)
	# plank seam halfway through the band
	for i in range(3, n - 3):
		c.px(i, 3, WPal.WOOD[2].darkened(0.1))
		c.px(3, i, WPal.WOOD[2].darkened(0.1))
		c.px(i, n - 4, WPal.WOOD[1])
		c.px(n - 4, i, WPal.WOOD[1])
	_ring(c, 0, n, WPal.OUTLINE)
	_ring(c, FRAME - 1, n - 2 * (FRAME - 1), WPal.OUTLINE)
	# plum interior with an inset shadow along the top and left
	c.rect(FRAME, FRAME, n - 2 * FRAME, n - 2 * FRAME, Color("33242c"))
	c.hline(FRAME, n - 1 - FRAME, FRAME, Color("1f161c"))
	c.vline(FRAME, FRAME, n - 1 - FRAME, Color("1f161c"))
	c.hline(FRAME + 1, n - 2 - FRAME, FRAME + 1, Color("2a1e25"))
	# brass corner brackets with a rivet
	for corner in 4:
		_bracket(c, corner, n)
	return c


static func _ring(c: PixelCanvas, at: int, size: int, col: Color) -> void:
	c.hline(at, at + size - 1, at, col)
	c.hline(at, at + size - 1, at + size - 1, col)
	c.vline(at, at, at + size - 1, col)
	c.vline(at + size - 1, at, at + size - 1, col)


## An L-shaped brass cap over one corner. corner: 0 TL, 1 TR, 2 BL, 3 BR.
static func _bracket(c: PixelCanvas, corner: int, n: int) -> void:
	var fx := corner % 2 == 1
	var fy := corner >= 2
	var g: Array = WPal.GOLD
	# drawn for the top-left corner, then mirrored
	var cells := {}
	for i in 7:
		for j in 3:
			cells[Vector2i(i, j)] = true
			cells[Vector2i(j, i)] = true
	for p in cells:
		var x: int = n - 1 - p.x if fx else p.x
		var y: int = n - 1 - p.y if fy else p.y
		var edge: bool = p.x == 6 or p.y == 6 or (p.x == 2 and p.y > 2) or (p.y == 2 and p.x > 2)
		var col: Color = WPal.OUTLINE if (p.x == 0 or p.y == 0) else (g[1] if edge else g[2])
		c.px(x, y, col)
	# highlight on the lit edges, rivet in the elbow
	for i in range(1, 6):
		c.px(n - 1 - i if fx else i, n - 2 if fy else 1, g[3] if not fy else g[1])
		c.px(n - 2 if fx else 1, n - 1 - i if fy else i, g[3] if not fx else g[1])
	var rx := n - 3 if fx else 2
	var ry := n - 3 if fy else 2
	c.px(rx, ry, g[4])
	c.px(rx + (-1 if fx else 1), ry + (-1 if fy else 1), g[0])


## Vine-wrapped panel for the Codex / dialogue: the wood frame with leaf
## clusters and a white blossom on the top-left and bottom-right corners.
static func panel_vine() -> PixelCanvas:
	var c := panel_wood()
	_leaves(c, false)
	_leaves(c, true)
	return c


static func _leaves(c: PixelCanvas, mirror: bool) -> void:
	var n := 32
	var lf: Array = WPal.LEAF
	# leaf: [x, y, dir] in top-left space; dir 0 points right, 1 points down
	# every pixel must stay within x, y < 10
	var leaves := [[6, 0, 0], [6, 3, 0], [0, 6, 1], [3, 6, 1], [5, 5, 0]]
	for l in leaves:
		var pts: Array = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, -1), Vector2i(1, 1), Vector2i(3, 0)]
		for k in pts.size():
			var o: Vector2i = pts[k] if l[2] == 0 else Vector2i(pts[k].y, pts[k].x)
			var x: int = l[0] + o.x
			var y: int = l[1] + o.y
			if mirror:
				x = n - 1 - x
				y = n - 1 - y
			var col: Color = lf[4] if k == 3 else (lf[2] if k == 4 else lf[3])
			if k == 5:
				col = lf[1]
			c.px(x, y, col)
	# the vine stem tying them together (kept inside the 10-texel corner,
	# anything past it would be stretched along the edge by the 9-slice)
	for i in range(4, 9):
		var a := Vector2i(i, 2 + int(i % 3 == 0))
		var b := Vector2i(2 + int(i % 3 == 0), i)
		for p in [a, b]:
			c.px(n - 1 - p.x if mirror else p.x, n - 1 - p.y if mirror else p.y, lf[1])
	# a five-petal blossom in the corner
	var cx := n - 5 if mirror else 4
	var cy := n - 5 if mirror else 4
	for o in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		c.px(cx + o.x, cy + o.y, WPal.WHITE)
	for o in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		c.px(cx + o.x, cy + o.y, WPal.CREAM[1])
	c.px(cx, cy, WPal.GOLD[3])


## Parchment inset for lists and tooltips (12x12, margins 4).
static func panel_paper() -> PixelCanvas:
	var c := PixelCanvas.new(12, 12)
	c.rect(0, 0, 12, 12, WPal.WOOD[1])
	c.rect(1, 1, 10, 10, WPal.CREAM[1])
	c.rect(2, 2, 8, 8, WPal.CREAM[2])
	c.hline(2, 9, 2, WPal.CREAM[3])
	c.vline(2, 2, 9, WPal.CREAM[3])
	for p in [Vector2i(0, 0), Vector2i(11, 0), Vector2i(0, 11), Vector2i(11, 11)]:
		c.erase(p.x, p.y)
	for p in [Vector2i(1, 1), Vector2i(10, 1), Vector2i(1, 10), Vector2i(10, 10)]:
		c.px(p.x, p.y, WPal.WOOD[1])
	return c


## Dark glass panel for the HUD chips (12x12, margins 4).
static func panel_dark() -> PixelCanvas:
	var c := PixelCanvas.new(12, 12)
	c.rect(1, 1, 10, 10, Color(0.12, 0.08, 0.12, 0.86))
	c.hline(2, 9, 1, Color(1, 0.94, 0.8, 0.18))
	c.outline(Color("4a3040"), 1.0)
	return c


## Item slot frames (20x20, margins 5): a bevelled rim around an inset well.
## 0 normal, 1 selected (gold, with corner brackets), 2 element-lit, 3 locked.
static func slot(state: int) -> PixelCanvas:
	var c := PixelCanvas.new(20, 20)
	var ramp: Array = [WPal.WOOD, WPal.GOLD, WPal.ELEMENT[5], WPal.STONE][state]
	var lit: Color = ramp[4] if state == 0 else ramp[3]
	var mid: Color = ramp[2]
	var dark: Color = ramp[1]
	c.rect(0, 0, 20, 20, WPal.OUTLINE)
	c.rect(1, 1, 18, 18, mid)
	c.hline(1, 18, 1, lit)
	c.vline(1, 1, 18, lit)
	c.hline(1, 18, 18, dark)
	c.vline(18, 1, 18, dark)
	c.rect(2, 2, 16, 16, mid)
	_ring(c, 3, 14, WPal.OUTLINE)
	# the well: darkest under the top-left lip, catching light at the bottom-right
	c.rect(4, 4, 12, 12, Color("2e2229"))
	c.hline(4, 15, 4, Color("1a1217"))
	c.vline(4, 4, 15, Color("1a1217"))
	c.hline(5, 15, 15, Color("3d2e36"))
	c.vline(15, 5, 15, Color("3d2e36"))
	if state == 1:
		for p in [Vector2i(0, 0), Vector2i(19, 0), Vector2i(0, 19), Vector2i(19, 19)]:
			c.px(p.x, p.y, WPal.GOLD[4])
		for i in 3:
			c.px(1 + i, 1, WPal.GOLD[4])
			c.px(1, 1 + i, WPal.GOLD[4])
	return c


## Buttons 16x12 (margins 4): 0 normal, 1 hover/focus, 2 pressed, 3 disabled.
## A bevelled plank: lit top and left rims, a 2-texel lip below, brass studs on hover.
static func button(state: int) -> PixelCanvas:
	var c := PixelCanvas.new(16, 12)
	var ramp: Array = [WPal.WOOD.slice(1, 6), WPal.CLOTH_OCHRE, WPal.WOOD.slice(0, 5), WPal.STONE][state]
	var top := 1 if state == 2 else 0
	c.rect(0, top, 16, 12 - top, WPal.OUTLINE)
	# flat body so 9-slice stretching stays clean; bevel lives in the margins
	c.rect(1, top + 1, 14, 10 - top, ramp[2])
	c.hline(1, 14, top + 1, ramp[4])
	c.hline(2, 13, top + 2, ramp[3])
	c.vline(1, top + 2, 9, ramp[3])
	c.vline(14, top + 2, 9, ramp[1])
	if state != 2:
		c.hline(1, 14, 10, ramp[0])
		c.hline(1, 14, 9, ramp[1])
	if state == 1:
		for p in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 8), Vector2i(13, 8)]:
			c.px(p.x, p.y, WPal.GOLD[4])
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
