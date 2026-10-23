extends RefCounted
class_name PlayerInput

## One player's input source. Gameplay never reads Input directly: each frame
## a source produces an *intent* (move vector + which actions were pressed),
## and RootbornPlayer consumes only that. Local sources poll keyboard/gamepads;
## a future NetworkInput just assigns intents received over the wire, so
## online co-op needs no gameplay changes (see NetworkInput.gd).

const ACTIONS := ["interact", "attack", "dash", "cycle_tool", "skill_1", "skill_2", "skill_3",
	"quickroot", "eat_1", "eat_2", "eat_3", "open_satchel", "open_codex", "pause"]

## Gamepad layout (Godot JoyButton / JoyAxis indices), mirrored in README.
const PAD_BUTTONS := {
	"interact": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "dash": JOY_BUTTON_B, "cycle_tool": JOY_BUTTON_Y,
	"skill_1": JOY_BUTTON_LEFT_SHOULDER, "skill_2": JOY_BUTTON_RIGHT_SHOULDER,
	"eat_1": JOY_BUTTON_DPAD_LEFT, "eat_2": JOY_BUTTON_LEFT_STICK, "eat_3": JOY_BUTTON_DPAD_RIGHT,
	"open_satchel": JOY_BUTTON_BACK, "open_codex": JOY_BUTTON_RIGHT_STICK, "pause": JOY_BUTTON_START,
}
const PAD_TRIGGERS := {"skill_3": JOY_AXIS_TRIGGER_RIGHT, "quickroot": JOY_AXIS_TRIGGER_LEFT}

## -1 = no gamepad. keyboard = also read keyboard/mouse actions.
var device: int = -1
var keyboard: bool = true

var move := Vector2.ZERO
var pressed: Dictionary = {}       # action -> true on the frame it went down
var _held: Dictionary = {}


func _init(p_device: int = -1, p_keyboard: bool = true) -> void:
	device = p_device
	keyboard = p_keyboard


func poll() -> void:
	var now: Dictionary = {}
	var mv := Vector2.ZERO
	if keyboard:
		mv = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		for a in ACTIONS:
			if Input.is_action_pressed(a):
				now[a] = true
	if device >= 0:
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() < 0.25:
			stick = Vector2.ZERO
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP): stick.y = -1.0
		if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN): stick.y = 1.0
		if stick.length() > mv.length():
			mv = stick.limit_length(1.0)
		for a in PAD_BUTTONS:
			if Input.is_joy_button_pressed(device, PAD_BUTTONS[a]):
				now[a] = true
		for a in PAD_TRIGGERS:
			if Input.get_joy_axis(device, PAD_TRIGGERS[a]) > 0.5:
				now[a] = true
	pressed.clear()
	for a in now:
		if not _held.has(a):
			pressed[a] = true
	_held = now
	move = mv


func just(action: String) -> bool:
	return pressed.has(action)


## Wire format for online play: tiny and stable.
func to_intent() -> Dictionary:
	return {"m": [move.x, move.y], "p": pressed.keys()}


func apply_intent(d: Dictionary) -> void:
	var m: Array = d.get("m", [0.0, 0.0])
	move = Vector2(float(m[0]), float(m[1]))
	pressed.clear()
	for a in d.get("p", []):
		pressed[String(a)] = true
