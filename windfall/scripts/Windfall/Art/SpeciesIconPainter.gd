extends RefCounted
class_name SpeciesIconPainter

## One 16x16 icon per species. The fruit *kind* (berry, plum, fig, citrus…)
## sets the silhouette, the element family sets the colour ramp, and hybrids
## get a second band in their other parent's colour. Silhouettes are distinct
## enough to guess a species from its blacked-out Codex shape.

const KINDS := [
	["pomegranate", "pomegranate"], ["lychee", "lychee"], ["starfruit", "star"], ["thorns", "thorns"],
	["gourd", "gourd"], ["mango", "mango"], ["melon", "melon"], ["grape", "grape"], ["quince", "quince"],
	["kiwi", "kiwi"], ["cherry", "cherry"], ["berry", "berry"], ["plum", "plum"], ["fig", "fig"],
	["lemon", "citrus"], ["lime", "citrus"], ["citrus", "citrus"], ["apple", "apple"], ["peach", "peach"],
	["apricot", "peach"], ["date", "date"], ["pear", "pear"], ["nut", "nut"], ["forge", "forge"],
]

## Hybrid second-parent families (for the two-tone band).
const HYBRID_SECOND := {&"plasma_plum": 1, &"glacier_gourd": 3, &"wraith_kiwi": 6, &"halo_thorns": 7, &"forgefruit": 4}


static func kind_of(species_id: StringName) -> String:
	var s := String(species_id)
	for k in KINDS:
		if s.contains(k[0]):
			return k[1]
	return "berry"


static func icon(species_id: StringName, fam: int) -> PixelCanvas:
	var c := PixelCanvas.new(16, 16, hash(species_id))
	var r: Array = WPal.ELEMENT[fam]
	var ramp: Array = r.slice(0, 5)
	var leaf: Array = WPal.LEAF.slice(2, 6)
	match kind_of(species_id):
		"berry":
			for p in [Vector2(5, 10), Vector2(10, 10), Vector2(7.5, 6), Vector2(11, 6), Vector2(4.5, 6)]:
				c.shade_ellipse(p.x, p.y, 2.6, 2.6, ramp)
			c.px(7, 2, leaf[1]); c.px(8, 2, leaf[2])
		"plum":
			c.shade_ellipse(8, 9, 5.5, 5.8, ramp)
			c.vline(8, 5, 13, r[1])
			c.vline(8, 1, 3, WPal.WOOD[2])
		"fig":
			c.poly(PackedVector2Array([Vector2(8, 1.5), Vector2(12.5, 9), Vector2(12, 14), Vector2(4, 14), Vector2(3.5, 9)]), r[2])
			c.shade_ellipse(8, 10.5, 4.6, 3.8, ramp)
			c.px(8, 1, WPal.WOOD[2])
		"citrus":
			c.shade_ellipse(8, 8.5, 6.2, 4.8, ramp)
			c.px(1, 8, r[3]); c.px(14, 8, r[3])
			c.speckle([r[3]], 0.08, Rect2i(3, 5, 10, 7))
			c.shade_ellipse(10, 3, 2.2, 1.2, leaf)
		"apple":
			c.shade_ellipse(5.5, 9, 4.2, 5.2, ramp)
			c.shade_ellipse(10.5, 9, 4.2, 5.2, ramp)
			c.vline(8, 2, 5, WPal.WOOD[2])
			c.shade_ellipse(11, 3, 2.4, 1.3, leaf)
		"peach":
			c.shade_ellipse(8, 9, 6, 5.6, ramp)
			c.line(8, 4, 6, 13, r[1])
			c.shade_ellipse(5, 3.5, 2.4, 1.3, leaf)
		"date":
			c.shade_ellipse(8, 8, 3.4, 6.4, ramp)
			c.line(7, 3, 7, 13, r[1])
		"pomegranate":
			c.shade_ellipse(8, 9.5, 6, 5.6, ramp)
			c.rect(6, 2, 4, 2, r[1])
			c.px(5, 2, r[1]); c.px(10, 2, r[1]); c.px(7, 1, r[2]); c.px(8, 1, r[2])
		"pear":
			c.shade_ellipse(8, 10.5, 5.2, 4.5, ramp)
			c.shade_ellipse(8, 5.5, 3, 3, ramp, 0.05)
			c.vline(8, 1, 2, WPal.WOOD[2])
		"grape":
			for row in 4:
				for k in 4 - row:
					c.shade_ellipse(4.5 + k * 2.4 + row * 1.2, 4.5 + row * 2.6, 1.7, 1.7, ramp)
			c.vline(8, 1, 3, WPal.WOOD[2])
		"quince":
			c.shade_ellipse(8, 9, 5.6, 5.4, ramp)
			c.shade_ellipse(8, 4.5, 2.6, 2.2, ramp, 0.05)
			c.px(6, 12, r[1]); c.px(10, 12, r[1])
			c.shade_ellipse(11, 2.5, 2.2, 1.2, leaf)
		"melon":
			c.shade_ellipse(8, 8.5, 6.8, 6, ramp)
			for x in [4, 8, 12]:
				c.vline(x, 4, 13, r[1])
		"mango":
			c.poly(PackedVector2Array([Vector2(4, 4), Vector2(11, 2.5), Vector2(14, 8), Vector2(10, 14), Vector2(3, 11)]), r[2])
			c.shade_ellipse(8.5, 8, 4.8, 4.8, ramp)
		"cherry":
			c.shade_ellipse(5, 11, 3.2, 3.2, ramp)
			c.shade_ellipse(11, 11, 3.2, 3.2, ramp)
			c.line(5, 8, 8, 2, WPal.WOOD[3]); c.line(11, 8, 8, 2, WPal.WOOD[3])
			c.shade_ellipse(10, 2.5, 2.2, 1.2, leaf)
		"nut":
			c.shade_ellipse(8, 9.5, 5.2, 5, ramp)
			c.shade_ellipse(8, 5, 6, 2.6, WPal.WOOD.slice(1, 5))
			c.px(8, 2, WPal.WOOD[2])
		"kiwi":
			c.shade_ellipse(8, 8.5, 6.4, 5.2, ramp)
			c.ellipse(8, 8.5, 2.6, 2, r[4])
			for a in 6:
				c.px(int(8 + cos(a) * 3.6), int(8.5 + sin(a) * 3), WPal.INK)
		"star":
			c.poly(PackedVector2Array([Vector2(8, 0.5), Vector2(10, 6), Vector2(15.5, 6), Vector2(11, 9.5), Vector2(12.8, 15.5), Vector2(8, 12), Vector2(3.2, 15.5), Vector2(5, 9.5), Vector2(0.5, 6), Vector2(6, 6)]), r[2])
			c.px(7, 5, r[4]); c.px(6, 7, r[3])
		"lychee":
			c.shade_ellipse(8, 8.5, 6, 6, ramp)
			for y in range(4, 14, 2):
				for x in range(3 + (y / 2) % 2, 14, 2):
					if c.is_solid(x, y): c.px(x, y, r[1])
		"gourd":
			c.shade_ellipse(8, 11, 5.4, 4.4, ramp)
			c.shade_ellipse(8, 5.5, 3, 3, ramp, 0.05)
			c.vline(8, 1, 2, WPal.WOOD[2])
		"thorns":
			c.shade_ellipse(8, 9, 5, 5, ramp)
			for a in 8:
				var ang := a * TAU / 8.0
				c.line(int(8 + cos(ang) * 4), int(9 + sin(ang) * 4), int(8 + cos(ang) * 7.5), int(9 + sin(ang) * 7), WPal.LEAF[1])
		"forge":
			c.shade_box(3, 6, 10, 8, ramp)
			c.rect(5, 3, 6, 3, r[3])
			c.hline(3, 12, 9, r[1])
	# hybrid two-tone band
	if HYBRID_SECOND.has(species_id):
		var r2: Array = WPal.ELEMENT[HYBRID_SECOND[species_id]]
		for y in range(9, 12):
			for x in 16:
				if c.is_solid(x, y) and PixelCanvas.bayer(x, y) < 0.75:
					c.px(x, y, r2[2] if y == 10 else r2[1])
	c.outline(WPal.OUTLINE, 0.6)
	return c
