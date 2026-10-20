## CameraFX.gd
## Game OS Template Addition — Camera Effects System
##
## Provides trauma-based screen shake, zoom punch, chromatic aberration,
## and hit pause. Attach to any Camera2D or call statically.
##
## Usage — Option A: Attach as component script to your Camera2D:
##   @onready var cam := $Camera2D
##   func _ready():
##       CameraFX.init(cam)
##   func _process(delta):
##       CameraFX.update(delta)
##
## Usage — Option B: Standalone autoload (registers itself on boot):
##   CameraFX = "res://autoload/CameraFX.gd"
##   Then call CameraFX.shake(power) from anywhere.
##
## GENERIC — no game-specific content.

extends Node

# ── Registered camera ──────────────────────────────────────────────────────────
var _cam: Camera2D = null
var _base_zoom: Vector2 = Vector2.ONE
var _base_offset: Vector2 = Vector2.ZERO

# ── Trauma shake (Square Law) ──────────────────────────────────────────────────
## trauma: 0.0–1.0. Shake = trauma². Decays each frame.
## This is the industry-standard approach (from GDC "Math for Game Programmers").
var trauma: float = 0.0
var trauma_decay: float = 1.8   # units per second
var max_shake_offset: float = 14.0
var max_shake_rotation: float = 0.035  # radians
var _noise: FastNoiseLite = null
var _noise_time: float = 0.0
var _noise_speed: float = 90.0

# ── Zoom punch ─────────────────────────────────────────────────────────────────
var _zoom_target: Vector2 = Vector2.ONE
var _zoom_base: Vector2 = Vector2.ONE
var _zoom_speed: float = 0.0
var _zoom_hold: float = 0.0
var _zoom_snap_speed: float = 0.0
var _zoom_state: String = "idle"  # idle | punch_in | hold | snap_out

# ── Hit pause ─────────────────────────────────────────────────────────────────
var _hit_pause_active: bool = false

# ── Chromatic aberration (via shader if available) ─────────────────────────────
var _chroma_intensity: float = 0.0
var _chroma_decay: float = 4.0


func _ready() -> void:
	_build_noise()
	# Auto-find camera if it exists in tree at boot
	call_deferred("_auto_find_camera")


func _build_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.seed = randi()
	_noise.frequency = 0.5


func _auto_find_camera() -> void:
	var cams := get_tree().get_nodes_in_group("main_camera")
	if cams.size() > 0 and cams[0] is Camera2D:
		init(cams[0])


## Register a Camera2D for effects. Call once from your scene's _ready().
func init(cam: Camera2D) -> void:
	_cam = cam
	_base_zoom = cam.zoom
	_base_offset = cam.offset
	_zoom_base = cam.zoom
	_zoom_target = cam.zoom


func _process(delta: float) -> void:
	if _hit_pause_active: return
	_update_trauma(delta)
	_update_zoom(delta)
	_update_chroma(delta)


func _update_trauma(delta: float) -> void:
	if _cam == null or trauma <= 0.0: return

	trauma = maxf(0.0, trauma - trauma_decay * delta)
	var shake := trauma * trauma

	_noise_time += delta * _noise_speed
	var ox := _noise.get_noise_2d(_noise_time,       0.0) * max_shake_offset * shake
	var oy := _noise.get_noise_2d(_noise_time + 100, 0.0) * max_shake_offset * shake
	var rot := _noise.get_noise_2d(_noise_time + 200, 0.0) * max_shake_rotation * shake

	_cam.offset = _base_offset + Vector2(ox, oy)
	_cam.rotation = rot


func _update_zoom(delta: float) -> void:
	if _cam == null: return
	match _zoom_state:
		"punch_in":
			_cam.zoom = _cam.zoom.move_toward(_zoom_target, _zoom_speed * delta)
			if _cam.zoom.is_equal_approx(_zoom_target):
				_zoom_state = "hold"
		"hold":
			_zoom_hold -= delta
			if _zoom_hold <= 0.0:
				_zoom_state = "snap_out"
		"snap_out":
			_cam.zoom = _cam.zoom.move_toward(_zoom_base, _zoom_snap_speed * delta)
			if _cam.zoom.is_equal_approx(_zoom_base):
				_zoom_state = "idle"
				_cam.zoom = _zoom_base


func _update_chroma(delta: float) -> void:
	if _chroma_intensity <= 0.0: return
	_chroma_intensity = maxf(0.0, _chroma_intensity - _chroma_decay * delta)
	# Apply to camera's environment shader if available
	if _cam and _cam.has_node("ChromaViewport"):
		var vp := _cam.get_node("ChromaViewport")
		if vp.has_method("set_aberration"):
			vp.set_aberration(_chroma_intensity)


# ── Public API ─────────────────────────────────────────────────────────────────

## Add trauma (clamped to 1.0). Values: light=0.35, heavy=0.65, perfect=0.9
func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


## Convenience: named trauma levels matching tackle power tiers.
func shake(power: String = "light") -> void:
	match power:
		"perfect": add_trauma(0.9)
		"heavy":   add_trauma(0.65)
		"light":   add_trauma(0.35)
		_:         add_trauma(float(power) if power.is_valid_float() else 0.35)


## Camera zoom punch toward a world position.
## punch_amount: how much to zoom in (e.g. 0.15 = 15% zoom increase)
## hold_sec: how long to hold at peak zoom before snapping back
func zoom_punch(punch_amount: float = 0.12, hold_sec: float = 0.08,
		snap_speed: float = 3.0) -> void:
	if _cam == null: return
	_zoom_base = _base_zoom
	_zoom_target = _base_zoom + Vector2(punch_amount, punch_amount)
	_zoom_speed = (_zoom_target - _cam.zoom).length() / 0.07  # 70ms punch-in
	_zoom_hold = hold_sec
	_zoom_snap_speed = (_zoom_target - _zoom_base).length() / maxf(0.01, snap_speed * 0.1)
	_zoom_state = "punch_in"


## Full impact moment: hit pause + shake + zoom punch.
## power: "light" | "heavy" | "perfect"
func impact(power: String = "light") -> void:
	match power:
		"perfect":
			_hit_pause(0.13)
			shake("perfect")
			zoom_punch(0.22, 0.14, 0.28)
			_chroma_intensity = 0.8
		"heavy":
			_hit_pause(0.09)
			shake("heavy")
			zoom_punch(0.16, 0.10, 0.22)
			_chroma_intensity = 0.45
		_:  # light
			_hit_pause(0.055)
			shake("light")
			zoom_punch(0.09, 0.06, 0.18)
			_chroma_intensity = 0.15


## Screen flash (white). Call directly on the flash overlay node.
func flash(node: CanvasItem, duration: float = 0.08, color: Color = Color.WHITE) -> void:
	node.modulate = color
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", Color.TRANSPARENT, duration)


## Pan camera smoothly toward a world position (for split-cam between two targets).
func pan_toward(world_pos: Vector2, speed: float = 0.05) -> void:
	if _cam == null: return
	# Convert world pos to camera scroll
	_cam.global_position = _cam.global_position.lerp(world_pos, speed)


## Reset all effects immediately.
func reset() -> void:
	trauma = 0.0
	_zoom_state = "idle"
	_chroma_intensity = 0.0
	_hit_pause_active = false
	if _cam:
		_cam.offset = _base_offset
		_cam.rotation = 0.0
		_cam.zoom = _base_zoom
	Engine.time_scale = 1.0


# ── Hit pause (time freeze) ────────────────────────────────────────────────────

func _hit_pause(duration_sec: float) -> void:
	if _hit_pause_active: return
	_hit_pause_active = true
	Engine.time_scale = 0.0
	var timer := get_tree().create_timer(duration_sec, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
		_hit_pause_active = false
	)


# ── Preset sequences ───────────────────────────────────────────────────────────

## Tackle impact — call from TackleSystem on resolve.
func tackle_impact(power: String = "light") -> void:
	impact(power)


## Carrier scores — big dramatic shake.
func carrier_scored() -> void:
	add_trauma(0.85)
	zoom_punch(0.05, 0.2, 0.3)


## Boss phase change.
func boss_phase() -> void:
	_hit_pause(0.18)
	add_trauma(1.0)
	zoom_punch(0.12, 0.25, 0.35)
	_chroma_intensity = 1.0


## Round announce — subtle pulse.
func round_announce() -> void:
	zoom_punch(0.04, 0.3, 0.5)


## Upgrade select — gentle zoom in.
func upgrade_selected() -> void:
	zoom_punch(0.06, 0.15, 0.4)
