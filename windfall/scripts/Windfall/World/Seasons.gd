extends RefCounted
class_name Seasons

## Seasonal rules and look. Every 7 days the season turns (DayCycleManager).
##   Spring: cross-pollination (hybrids)   Summer: growth x1.2
##   Autumn: fruit sells for +25%          Winter: growth x0.5, but Frost trees
##                                          and Rime soil thrive (x1.3)

const TINT := [Color(1.0, 0.97, 1.0), Color(1.04, 1.0, 0.9), Color(1.08, 0.9, 0.76), Color(0.82, 0.9, 1.12)]
## Light wash over the ground layer (under props): frost in winter, amber in autumn.
const GROUND_WASH := [Color(1, 0.9, 0.95, 0.0), Color(1, 0.95, 0.6, 0.05), Color(1.0, 0.62, 0.25, 0.14), Color(0.92, 0.96, 1.0, 0.42)]
const NAMES := ["Spring", "Summer", "Autumn", "Winter"]
const BLURB := ["Blossoms drift. Neighbouring families may cross-pollinate.", "Long warm days: trees grow faster.", "Harvest season: fruit sells for 25% more.", "Frost bites: most trees slow down, but Frost thrives."]


static func current() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var dm := tree.get_first_node_in_group("day_manager") if tree else null
	return int(dm.get("current_season")) if dm else 0


static func growth_mult(fam: int, soil: int) -> float:
	match current():
		WindfallTypes.Season.SUMMER:
			return 1.2
		WindfallTypes.Season.WINTER:
			if fam == WindfallTypes.Family.FROST or soil == WindfallTypes.SoilType.RIME:
				return 1.3
			return 0.5
	return 1.0


static func price_mult() -> float:
	return 1.25 if current() == WindfallTypes.Season.AUTUMN else 1.0


## Ambient weather particles that follow the camera (overlay layer).
static func make_weather(season: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(560, 340)
	p.direction = Vector2(0.3, 1)
	p.spread = 20.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(8, 14)
	p.angular_velocity_min = -120.0
	p.angular_velocity_max = 120.0
	p.local_coords = true   # weather stays with the camera
	match season:
		WindfallTypes.Season.SPRING:
			p.texture = Art.tex("fx/petal")
			p.color = Color("ffbfd4")
		WindfallTypes.Season.SUMMER:
			p.texture = Art.tex("fx/dot")
			p.color = Color(1.0, 0.95, 0.7, 0.6)
			p.amount = 16
			p.gravity = Vector2(4, -4)
		WindfallTypes.Season.AUTUMN:
			p.texture = Art.tex("fx/leaf")
			p.color = Color("ffb070")
		_:
			p.texture = Art.tex("fx/snowflake")
			p.color = Color.WHITE
			p.amount = 70
	return p
