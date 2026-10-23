extends RefCounted
class_name WorldLayout

## Single source of truth for the homestead map. The ground bake
## (tools/bake_art.gd) and the runtime dresser (WorldDresser.gd) both read
## these numbers, so paths, fences and props always line up. World px.

const SIZE := Vector2(2560, 1536)
const BORDER := 112.0

const HOUSE := Vector2(520, 400)         # base-centre of farmhouse sprite
const DOOR := Vector2(520, 410)          # bed / sleep interaction
const STALL := Vector2(400, 650)
const PLAYER_SPAWN := Vector2(560, 500)
const ORCHARD := Rect2(650, 250, 380, 570)
const GATE := Vector2(1150, 486)
const WILDS := Rect2(1300, 140, 1140, 1260)
const POND := Vector2(860, 1030)
const POND_R := Vector2(140, 74)
const HIVES := [Vector2(1110, 880), Vector2(1150, 905), Vector2(1072, 910)]
const HESPER_HOME := Vector2(1130, 830)
const COMPOST_BIN := Vector2(610, 580)
## Expedition waystation clearings in the wilds.
const WAYSTATIONS := [Vector2(1720, 380), Vector2(2120, 760), Vector2(1760, 1180)]
const WELL := Vector2(400, 470)
const SCARECROW := Vector2(605, 300)
const HEDGE_NORTH_Y := 186.0
const HEDGE_WEST_X := 320.0

## Morning-tending camera frame: farmhouse + every plot, at zoom 1.5.
const HOMESTEAD_FRAME := Rect2(400, 190, 650, 470)

## Orchard plot centres (row-major, 3 x 2).
const PLOTS := [
	Vector2(720, 400), Vector2(840, 400), Vector2(960, 400),
	Vector2(720, 580), Vector2(840, 580), Vector2(960, 580),
	Vector2(720, 750), Vector2(840, 750), Vector2(960, 750),   # expansion row (bought)
]
const STARTING_PLOTS := 6

## Dirt paths as polylines (centre line) with half-width.
const PATHS := [
	{"pts": [Vector2(520, 420), Vector2(520, 486), Vector2(650, 486)], "w": 20.0},
	{"pts": [Vector2(520, 486), Vector2(520, 660)], "w": 18.0},
	{"pts": [Vector2(650, 486), Vector2(1030, 486), Vector2(1300, 486), Vector2(1500, 560), Vector2(1800, 560)], "w": 22.0},
	{"pts": [Vector2(780, 486), Vector2(780, 960)], "w": 12.0},
	{"pts": [Vector2(1500, 560), Vector2(1640, 860), Vector2(1900, 1060)], "w": 16.0},
]

const LANTERNS := [Vector2(610, 450), Vector2(1060, 450), Vector2(1200, 530), Vector2(460, 600), Vector2(440, 380), Vector2(820, 870)]

## Decorative flower patches filling the open lawn.
const FLOWER_PATCHES := [Vector2(600, 700), Vector2(660, 760), Vector2(1100, 640), Vector2(1180, 380), Vector2(560, 330), Vector2(1200, 960), Vector2(420, 760), Vector2(1220, 700)]

## Raid spawn points: out of the treeline around the orchard.
const RAID_SPAWNS := [Vector2(1260, 300), Vector2(1260, 720), Vector2(620, 960), Vector2(860, 170), Vector2(1180, 1000), Vector2(420, 880)]


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
