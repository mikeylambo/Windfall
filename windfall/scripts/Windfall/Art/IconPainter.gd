extends RefCounted
class_name IconPainter

## 16x16 HUD / menu icons. Baked at 3x so they sit on the same 3px texel grid
## as the world at default zoom.


static func _c() -> PixelCanvas:
	return PixelCanvas.new(16, 16, 33)


static func heart() -> PixelCanvas:
	var c := _c()
	c.shade_ellipse(5, 6, 3.6, 3.4, WPal.RED.slice(1, 5))
	c.shade_ellipse(11, 6, 3.6, 3.4, WPal.RED.slice(1, 5))
	c.poly(PackedVector2Array([Vector2(1.6, 7), Vector2(14.4, 7), Vector2(8, 14.5)]), WPal.RED[2])
	c.px(4, 4, WPal.RED[4])
	c.px(4, 5, WPal.WHITE)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func bolt() -> PixelCanvas:
	var c := _c()
	c.poly(PackedVector2Array([Vector2(9, 1), Vector2(3, 9), Vector2(7.5, 9), Vector2(6, 15), Vector2(13, 6), Vector2(8.5, 6), Vector2(10.5, 1)]), WPal.GOLD[3])
	c.line(8, 3, 6, 7, WPal.GOLD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func coin() -> PixelCanvas:
	var c := _c()
	c.shade_ellipse(8, 8, 6, 6, WPal.GOLD)
	c.ellipse(8, 8, 3.6, 3.6, WPal.GOLD[2])
	c.vline(8, 5, 10, WPal.GOLD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func sun() -> PixelCanvas:
	var c := _c()
	for i in 8:
		var a := i * PI / 4.0
		c.line(8, 8, int(round(8 + cos(a) * 7)), int(round(8 + sin(a) * 7)), WPal.GOLD[2])
	c.shade_ellipse(8, 8, 4, 4, WPal.GOLD.slice(2, 5))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func sunset() -> PixelCanvas:
	var c := _c()
	c.shade_ellipse(8, 10, 5, 5, [WPal.RED[3], WPal.GOLD[2], WPal.GOLD[3]])
	for y in range(11, 16):
		c.hline(0, 15, y, Color(0, 0, 0, 0))
		for x in 16:
			c.erase(x, y)
	c.hline(1, 14, 11, WPal.WOOD[3])
	c.hline(3, 12, 13, WPal.WOOD[2])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func moon() -> PixelCanvas:
	var c := _c()
	c.shade_ellipse(8, 8, 6, 6, WPal.CREAM.slice(1, 4))
	c.ellipse(11, 6, 5, 5, Color(0, 0, 0, 0))
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5 - 11.0, y + 0.5 - 6.0).length()
			if d < 5.0:
				c.erase(x, y)
	c.px(13, 12, WPal.WHITE)
	c.px(3, 2, WPal.WHITE)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func season(s: int) -> PixelCanvas:
	var c := _c()
	match s:
		0:  # spring blossom
			for i in 5:
				var a := i * TAU / 5.0 - PI / 2.0
				c.shade_ellipse(8 + cos(a) * 3.6, 8 + sin(a) * 3.6, 2.6, 2.6, [Color("d97aa0"), Color("ff9bb4"), Color("ffd4e0")])
			c.shade_ellipse(8, 8, 1.8, 1.8, WPal.GOLD.slice(2, 5))
		1:  # summer leaf
			c.poly(PackedVector2Array([Vector2(2, 14), Vector2(4, 4), Vector2(14, 2), Vector2(12, 12)]), WPal.LEAF[3])
			c.line(3, 13, 12, 4, WPal.LEAF[1])
			c.speckle([WPal.LEAF[4]], 0.2)
		2:  # autumn maple
			c.poly(PackedVector2Array([Vector2(8, 1), Vector2(10, 5), Vector2(15, 4), Vector2(12, 9), Vector2(14, 12), Vector2(8, 11), Vector2(2, 12), Vector2(4, 9), Vector2(1, 4), Vector2(6, 5)]), WPal.RED[3])
			c.vline(8, 9, 15, WPal.WOOD[2])
			c.speckle([WPal.GOLD[3]], 0.15)
		_:  # winter flake
			for i in 3:
				var a := i * PI / 3.0
				c.line(int(round(8 - cos(a) * 6)), int(round(8 - sin(a) * 6)), int(round(8 + cos(a) * 6)), int(round(8 + sin(a) * 6)), WPal.ELEMENT[2][3])
			c.px(8, 8, WPal.WHITE)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func tool_icon(t: int) -> PixelCanvas:
	var c := _c()
	var steel := WPal.STONE.slice(2, 5)
	match t:
		0:  # pruning shears
			c.thick_line(3, 12, 9, 6, WPal.RED[2], 2)
			c.thick_line(3, 6, 9, 11, WPal.RED[3], 2)
			c.thick_line(9, 7, 14, 2, steel[2], 1)
			c.thick_line(9, 9, 14, 4, steel[1], 1)
			c.px(9, 8, WPal.GOLD[3])
		1:  # scythe
			c.thick_line(4, 15, 8, 2, WPal.WOOD[3], 2)
			for i in 9:
				var a := PI * 1.05 + i * 0.12
				c.px(int(8 + cos(a) * -6 + 0), int(3 + sin(a) * -3 + 0), steel[2])
			c.line(8, 2, 15, 5, steel[2])
			c.line(8, 3, 14, 6, steel[1])
		2:  # hoe-staff
			c.thick_line(3, 15, 11, 3, WPal.WOOD[3], 2)
			c.rect(9, 1, 6, 3, steel[1])
			c.hline(9, 14, 1, steel[2])
			c.px(4, 13, WPal.LEAF[3])
		3:  # seed sling
			c.thick_line(8, 15, 8, 8, WPal.WOOD[3], 2)
			c.line(8, 8, 3, 2, WPal.WOOD[3])
			c.line(9, 8, 13, 2, WPal.WOOD[3])
			c.line(3, 2, 8, 6, WPal.CREAM[2])
			c.line(13, 2, 8, 6, WPal.CREAM[2])
			c.shade_ellipse(8, 6, 1.6, 1.6, WPal.LEAF.slice(2, 5))
		4:  # watering can
			c.shade_box(3, 6, 8, 8, WPal.ELEMENT[3].slice(1, 5))
			c.line(10, 8, 14, 4, WPal.ELEMENT[3][2])
			c.rect(13, 3, 2, 2, WPal.ELEMENT[3][3])
			c.line(4, 6, 6, 3, WPal.STONE[3])
			c.line(6, 3, 9, 6, WPal.STONE[3])
			c.px(15, 6, WPal.ELEMENT[3][4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func element_sigil(fam: int) -> PixelCanvas:
	var c := _c()
	var r: Array = WPal.ELEMENT[fam]
	c.poly(PackedVector2Array([Vector2(8, 0.5), Vector2(15.5, 8), Vector2(8, 15.5), Vector2(0.5, 8)]), r[1])
	c.poly(PackedVector2Array([Vector2(8, 2), Vector2(14, 8), Vector2(8, 14), Vector2(2, 8)]), r[2])
	c.poly(PackedVector2Array([Vector2(8, 3), Vector2(8, 8), Vector2(3.5, 8)]), r[3])
	c.px(6, 5, r[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func fruit_icon(fam: int) -> PixelCanvas:
	var c := _c()
	var f: PixelCanvas = TreePainter.fruit_frames(fam)[0]
	var big := PixelCanvas.new(16, 16)
	# upscale the 8x9 fruit 1.5x by drawing it into the centre at 1:1 then
	# re-painting a larger silhouette for icon clarity
	var r: Array = WPal.ELEMENT[fam]
	var tmp := PixelCanvas.new(16, 16, 40 + fam)
	tmp.img = f.img.duplicate() as Image
	tmp.img.resize(16, 18, Image.INTERPOLATE_NEAREST)
	tmp.w = 16
	tmp.h = 18
	big.blit(tmp, 0, -1)
	big.px(5, 6, r[4])
	return big


static func seed_icon(fam: int) -> PixelCanvas:
	var c := _c()
	var r: Array = WPal.ELEMENT[fam]
	c.shade_ellipse(8, 9, 4.5, 5.5, WPal.WOOD.slice(2, 6))
	c.ellipse(8, 10, 2, 3, r[2])
	c.px(7, 8, r[4])
	c.vline(8, 1, 4, WPal.LEAF[3])
	c.shade_ellipse(10.5, 2.5, 2.2, 1.2, WPal.LEAF.slice(2, 6))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func satchel() -> PixelCanvas:
	var c := _c()
	c.shade_box(2, 5, 12, 10, WPal.WOOD.slice(1, 6))
	c.shade_box(2, 5, 12, 5, WPal.WOOD.slice(2, 6), 0.1)
	c.rect(7, 8, 2, 3, WPal.GOLD[3])
	c.line(3, 5, 7, 1, WPal.WOOD[2])
	c.line(13, 5, 9, 1, WPal.WOOD[2])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func codex() -> PixelCanvas:
	var c := _c()
	c.shade_box(2, 2, 12, 13, WPal.CLOTH_GREEN.slice(1, 5))
	c.rect(3, 3, 1, 11, WPal.GOLD[2])
	c.rect(13, 3, 2, 12, WPal.CREAM[2])
	c.shade_ellipse(9, 8, 2.6, 2.6, WPal.LEAF.slice(2, 6))
	c.px(9, 5, WPal.GOLD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func skull() -> PixelCanvas:
	var c := _c()
	c.shade_ellipse(8, 7, 6, 5.5, WPal.CREAM.slice(1, 4))
	c.rect(5, 11, 6, 3, WPal.CREAM[2])
	c.rect(5, 6, 2, 3, WPal.INK)
	c.rect(9, 6, 2, 3, WPal.INK)
	c.px(6, 12, WPal.INK)
	c.px(9, 12, WPal.INK)
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func stomach() -> PixelCanvas:
	var c := _c()
	c.shade_box(3, 5, 10, 10, [Color("2c5a5a"), Color("4a8a84"), Color("8ad0c4"), Color("d4fff4")])
	c.rect(4, 3, 8, 2, WPal.WOOD[3])
	c.shade_ellipse(7, 11, 2, 2, WPal.ELEMENT[1].slice(1, 5))
	c.shade_ellipse(10, 9, 1.6, 1.6, WPal.ELEMENT[0].slice(1, 5))
	c.vline(5, 6, 13, Color(1, 1, 1, 0.5))
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func star() -> PixelCanvas:
	var c := _c()
	c.poly(PackedVector2Array([Vector2(8, 0.5), Vector2(10, 6), Vector2(15.5, 6), Vector2(11, 9.5), Vector2(12.8, 15.5), Vector2(8, 12), Vector2(3.2, 15.5), Vector2(5, 9.5), Vector2(0.5, 6), Vector2(6, 6)]), WPal.GOLD[3])
	c.px(7, 4, WPal.GOLD[4])
	c.px(6, 6, WPal.GOLD[4])
	c.outline(WPal.OUTLINE, 0.6)
	return c


static func lock() -> PixelCanvas:
	var c := _c()
	c.shade_box(3, 7, 10, 8, WPal.GOLD.slice(1, 5))
	c.rect(5, 2, 1, 5, WPal.STONE[3])
	c.rect(10, 2, 1, 5, WPal.STONE[3])
	c.hline(5, 10, 2, WPal.STONE[3])
	c.rect(7, 10, 2, 3, WPal.INK)
	c.outline(WPal.OUTLINE, 0.6)
	return c
