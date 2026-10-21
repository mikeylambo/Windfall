extends Node
class_name CoopManager

## Local drop-in co-op for up to 3 Rootborn.
## P1: keyboard/mouse + the first gamepad. Any other gamepad presses START to
## join as P2/P3. Players share the satchel, seeds and gold (one homestead)
## but each has their own stomach, tools and cooldowns.
## Online later: create a RootbornPlayer with a NetworkInput source instead.

signal player_joined(player: RootbornPlayer)
signal player_left(player: RootbornPlayer)

const MAX_PLAYERS := 3
const SHEETS := ["rootborn", "rootborn_p2", "rootborn_p3"]
const TINTS := [Color("c87c52"), Color("78c4b4"), Color("d47a94")]

var main: Node
var players: Array[RootbornPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_changed)


func setup(p1: RootbornPlayer) -> void:
	players = [p1]
	p1.player_index = 0
	var pads := Input.get_connected_joypads()
	p1.input = PlayerInput.new(pads[0] if not pads.is_empty() else -1, true)


func claimed(device: int) -> bool:
	for p in players:
		if is_instance_valid(p) and p.input.device == device:
			return true
	return false


func _on_joy_changed(device: int, connected: bool) -> void:
	if connected and players.size() > 0 and players[0].input.device < 0:
		players[0].input.device = device
	elif not connected:
		for i in range(players.size() - 1, 0, -1):
			if players[i].input.device == device:
				remove_player(players[i])


func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton) or not event.pressed:
		return
	var dev: int = event.device
	var hud: Node = main.get("hud") if main else null
	if not claimed(dev):
		if event.button_index == JOY_BUTTON_START and not get_tree().paused:
			add_player(dev)
			get_viewport().set_input_as_handled()
		return
	# claimed pads: menu buttons are routed to the HUD (works while paused)
	if hud == null or hud.call("menu_blocked"):
		return
	match event.button_index:
		JOY_BUTTON_START:
			if hud.call("menu_open"): hud.call("close_menu")
			else: hud.call("open_menu", "pause")
		JOY_BUTTON_BACK:
			hud.call("_toggle", "satchel")
		JOY_BUTTON_RIGHT_STICK:
			hud.call("_toggle", "codex")


func add_player(device: int) -> RootbornPlayer:
	if players.size() >= MAX_PLAYERS:
		return null
	var p1 := players[0]
	var p := RootbornPlayer.new()
	p.player_index = players.size()
	p.sheet = SHEETS[p.player_index]
	p.input = PlayerInput.new(device, false)
	# one homestead: share the satchel and seed pouch by reference
	p.satchel_fruits = p1.satchel_fruits
	p.satchel_seeds = p1.satchel_seeds
	p.selected_seed_id = p1.selected_seed_id
	p.position = p1.global_position + Vector2(24 * p.player_index, 12)
	p1.get_parent().add_child(p)
	p.set_respawn_point(p1._respawn_point)
	players.append(p)
	FX.poof(p.global_position + Vector2(0, -12), TINTS[p.player_index])
	FX.element_burst(WindfallTypes.Family.VERDANT, p.global_position + Vector2(0, -16), 1.0)
	WindfallSound.play_prime_timing()
	HUDBus.toast("Player %d sprouted in!" % (p.player_index + 1), TINTS[p.player_index])
	player_joined.emit(p)
	return p


func remove_player(p: RootbornPlayer) -> void:
	if p == players[0]:
		return
	players.erase(p)
	FX.poof(p.global_position + Vector2(0, -12))
	player_left.emit(p)
	p.queue_free()


## Teleport the whole party together (phase changes, waking up).
func gather_at(pos: Vector2) -> void:
	for i in players.size():
		if is_instance_valid(players[i]):
			players[i].global_position = pos + Vector2((i - (players.size() - 1) * 0.5) * 26.0, 0)


func centroid() -> Vector2:
	var c := Vector2.ZERO
	var n := 0
	for p in players:
		if is_instance_valid(p):
			c += p.global_position
			n += 1
	return c / maxf(n, 1)


func spread() -> float:
	var c := centroid()
	var r := 0.0
	for p in players:
		if is_instance_valid(p):
			r = maxf(r, p.global_position.distance_to(c))
	return r
