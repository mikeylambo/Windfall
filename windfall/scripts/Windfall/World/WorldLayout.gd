extends RefCounted
class_name WorldLayout

## Single source of truth for the homestead map. The ground bake
## (tools/bake_art.gd) and the runtime dresser (WorldDresser.gd) both read
## these numbers, so paths, fences and props always line up. World px.

const SIZE := Vector2(2560, 1536)
const BORDER := 112.0

const HOUSE := Vector2(360, 430)         # base-centre of farmhouse sprite
const DOOR := Vector2(360, 440)          # bed / sleep interaction
const STALL := Vector2(330, 760)
const PLAYER_SPAWN := Vector2(470, 560)
const ORCHARD := Rect2(600, 250, 680, 620)
const GATE := Vector2(1440, 560)
const WILDS := Rect2(1560, 140, 880, 1260)
const POND := Vector2(840, 1170)
const POND_R := Vector2(150, 80)
const HIVES := [Vector2(540, 960), Vector2(600, 990), Vector2(480, 990)]

## Orchard plot centres (row-major, 3 x 2).
const PLOTS := [
	Vector2(760, 420), Vector2(940, 420), Vector2(1120, 420),
	Vector2(760, 690), Vector2(940, 690), Vector2(1120, 690),
]

## Dirt paths as polylines (centre line) with half-width.
const PATHS := [
	{"pts": [Vector2(360, 450), Vector2(360, 560), Vector2(600, 560)], "w": 22.0},
	{"pts": [Vector2(360, 560), Vector2(360, 740)], "w": 20.0},
	{"pts": [Vector2(600, 560), Vector2(1280, 560), Vector2(1600, 560), Vector2(1780, 620), Vector2(2000, 600)], "w": 24.0},
	{"pts": [Vector2(940, 560), Vector2(940, 1050)], "w": 16.0},
	{"pts": [Vector2(1780, 620), Vector2(1900, 900), Vector2(2120, 1080)], "w": 16.0},
]

const LANTERNS := [Vector2(560, 520), Vector2(1310, 520), Vector2(1400, 610), Vector2(410, 720), Vector2(300, 470), Vector2(900, 1020)]

## Raid spawn points: out of the treeline around the orchard.
const RAID_SPAWNS := [Vector2(1500, 300), Vector2(1500, 850), Vector2(700, 1080), Vector2(1100, 160), Vector2(1320, 1060), Vector2(560, 180)]


static func dist_to_paths(p: Vector2) -> float:
	var best := INF
	for path in PATHS:
		var pts: Array = path.pts
		for i in pts.size() - 1:
			var d := _seg_dist(p, pts[i], pts[i + 1]) - float(path.w)
			best = minf(best, d)
	return best


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func in_pond(p: Vector2, grow: float = 0.0) -> float:
	var d := (p - POND) / (POND_R + Vector2(grow, grow))
	return d.length()
