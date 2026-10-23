extends Camera2D
class_name CameraRig

## Player camera: leads gently in the movement direction, clamps to the map
## (via Camera2D limits), and during Morning Tending eases out to frame the
## whole homestead (farmhouse + every plot) when the player is inside it.
## Zoom only ever settles on integer texel scales (1.5 = 3px, 2 = 4px).

const ZOOM_PLAY := Vector2(2, 2)
const ZOOM_HOMESTEAD := Vector2(1.5, 1.5)
const LEAD := 40.0

var target: Node2D
var day_manager: DayCycleManager
var coop: CoopManager
var _lead := Vector2.ZERO
var _frame_weight := 0.0


func _ready() -> void:
	top_level = true
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_left = 0
	limit_top = 0
	limit_right = int(WorldLayout.SIZE.x)
	limit_bottom = int(WorldLayout.SIZE.y)
	if target:
		global_position = target.global_position + Vector2(0, -16)


func snap() -> void:
	if target:
		global_position = _desired()
		reset_smoothing()


func _framing() -> bool:
	if target == null or day_manager == null:
		return false
	return day_manager.current_phase == WindfallTypes.TimeOfDay.MORNING \
		and WorldLayout.HOMESTEAD_FRAME.grow(40).has_point(_focus())


func _focus() -> Vector2:
	if coop and coop.players.size() > 1:
		return coop.centroid()
	return target.global_position


func _desired() -> Vector2:
	var p := _focus() + Vector2(0, -16) + _lead
	return p.lerp(WorldLayout.HOMESTEAD_FRAME.get_center() + Vector2(0, 10), _frame_weight * 0.85)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var v: Vector2 = target.get("velocity") if "velocity" in target else Vector2.ZERO
	var want_lead := v.normalized() * LEAD if v.length() > 30.0 else Vector2.ZERO
	_lead = _lead.lerp(want_lead, clampf(delta * 2.5, 0.0, 1.0))
	_frame_weight = move_toward(_frame_weight, 1.0 if _framing() else 0.0, delta * 1.2)
	global_position = _desired()
	# zoom eases between the two pixel-perfect scales; CameraFX owns zoom
	# during punches so we only update its base when it's idle.
	var z := ZOOM_PLAY.lerp(ZOOM_HOMESTEAD, smoothstep(0.0, 1.0, _frame_weight))
	# co-op: ease out (never past the 1.5x pixel scale) to keep everyone framed
	if coop and coop.players.size() > 1:
		var need := clampf(coop.spread() / 160.0, 0.0, 1.0)
		z = z.lerp(ZOOM_HOMESTEAD, need)
	if CameraFX._zoom_state == "idle":
		zoom = z
	CameraFX._base_zoom = z
	CameraFX._zoom_base = z
