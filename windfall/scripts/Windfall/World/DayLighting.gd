extends Node
class_name DayLighting

## Gradient-driven day cycle on the world CanvasModulate.
## Each phase drifts through its own slice of the day so the light is always
## gently moving: warm morning -> golden afternoon -> dusk -> blue night.

const KEYS := [
	[0.00, Color("f6d6b0")],  # dawn, warm peach
	[0.18, Color("fff4dc")],  # morning
	[0.40, Color("ffffff")],  # noon
	[0.58, Color("ffe2a8")],  # golden afternoon
	[0.70, Color("f0a07a")],  # sunset
	[0.78, Color("7a6aa8")],  # dusk
	[0.86, Color("4a56a0")],  # night
	[1.00, Color("3c4890")],  # deep night
]
## [start, end] of each TimeOfDay phase on the 0..1 clock, and how many
## seconds it takes to drift across it.
const PHASE_SPAN := {0: [0.02, 0.36, 240.0], 1: [0.40, 0.66, 240.0], 2: [0.80, 0.95, 180.0]}

@export var modulate_path: NodePath
var clock: float = 0.02
var _target_start: float = 0.02
var _phase: int = 0
var _phase_time: float = 0.0
var _modulate: CanvasModulate
var _transition: Tween
var dresser: WorldDresser


func _ready() -> void:
	_modulate = get_node_or_null(modulate_path) as CanvasModulate


func set_phase(phase: int, instant: bool = false) -> void:
	_phase = phase
	_phase_time = 0.0
	var span: Array = PHASE_SPAN.get(phase, PHASE_SPAN[0])
	if instant:
		clock = span[0]
		return
	if _transition and _transition.is_valid():
		_transition.kill()
	var from := clock
	var to: float = span[0]
	# never run the clock backwards except into a fresh dawn
	if to < from and phase != 0:
		to = from
	_transition = create_tween()
	_transition.tween_method(func(v: float): clock = v, from if to >= from else 0.0, to, 2.5).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if _transition == null or not _transition.is_running():
		_phase_time += delta
		var span: Array = PHASE_SPAN.get(_phase, PHASE_SPAN[0])
		clock = lerpf(span[0], span[1], clampf(_phase_time / float(span[2]), 0.0, 1.0))
	var col := sample(clock)
	if _modulate:
		_modulate.color = col
	var n := clampf((clock - 0.66) / 0.16, 0.0, 1.0)
	FX.night = n
	if dresser:
		dresser.set_night(n)
	if dresser and dresser.window_glow:
		dresser.window_glow.modulate.a = clampf((clock - 0.6) / 0.15, 0.0, 1.0) * 0.9


static func sample(t: float) -> Color:
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if t <= b[0]:
			return (a[1] as Color).lerp(b[1], (t - a[0]) / maxf(b[0] - a[0], 0.0001))
	return KEYS[KEYS.size() - 1][1]


func hour_string() -> String:
	var minutes := int(lerpf(5.0 * 60.0, 29.0 * 60.0, clock)) % (24 * 60)
	return "%d:%02d" % [minutes / 60, (minutes % 60) / 10 * 10]
