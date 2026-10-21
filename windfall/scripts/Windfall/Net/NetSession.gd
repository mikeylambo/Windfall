extends Node

## Net — online co-op session (autoload). Host-authoritative over ENet.
##
##   Host:   runs the full simulation. Remote players are ordinary
##           RootbornPlayers whose PlayerInput is a NetworkInput fed by RPC.
##   Client: runs the same scene as a *view*: simulation is off, and the world
##           is driven by the host's 20 Hz snapshots (players, enemies, plots,
##           day/phase/gold) plus one-shot spell events for visuals.
##           Each frame it sends its local input intent to the host.
##
## Same seam as local co-op: gameplay code never knows a player is remote.

signal session_started(role: String)
signal session_failed(reason: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const PORT := 7777
const MAX_CLIENTS := 2
const SNAPSHOT_HZ := 20.0

var role: String = "offline"            # offline | host | client
var my_index: int = 0                   # player slot on this machine
var main: Node = null                   # WindfallMain when in game
var last_snapshot: Dictionary = {}
var snapshots_received: int = 0
var _peer_to_player: Dictionary = {}    # host: peer id -> RootbornPlayer
var _snap_timer: float = 0.0
var _local_input := PlayerInput.new(-1, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_host() -> bool:
	return role == "host"


func is_client() -> bool:
	return role == "client"


func online() -> bool:
	return role != "offline"


# ── session control ─────────────────────────────────────────────────────────

func host(port: int = PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		session_failed.emit("Could not host on port %d (%s)" % [port, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	role = "host"
	my_index = 0
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	session_started.emit(role)
	return true


func join(address: String, port: int = PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		session_failed.emit("Could not reach %s (%s)" % [address, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	role = "client"
	multiplayer.connected_to_server.connect(func(): session_started.emit(role), CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(func(): session_failed.emit("Connection failed"); leave(), CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(func(): HUDBus.toast("Host left the session", WPal.RED[4]); leave())
	return true


func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = "offline"
	_peer_to_player.clear()


# ── host side ───────────────────────────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	if not is_host() or main == null:
		return
	var coop: CoopManager = main.get("coop")
	var p := coop.add_player(-2)
	if p == null:
		return
	p.input = NetworkInput.new()
	_peer_to_player[id] = p
	_assign_index.rpc_id(id, p.player_index)
	peer_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	if _peer_to_player.has(id) and main:
		(main.get("coop") as CoopManager).remove_player(_peer_to_player[id])
	_peer_to_player.erase(id)
	peer_left.emit(id)


@rpc("any_peer", "unreliable_ordered")
func _push_intent(intent: Dictionary) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: RootbornPlayer = _peer_to_player.get(id)
	if p and p.input is NetworkInput:
		(p.input as NetworkInput).push_intent(intent)


## Host: called by ElementalProjectile so clients can draw the spell.
func broadcast_projectile(pos: Vector2, dir: Vector2, fam: int, speed: float, hostile: bool) -> void:
	if is_host() and not _peer_to_player.is_empty():
		_spawn_projectile_visual.rpc(pos, dir, fam, speed, hostile)


func _physics_process(delta: float) -> void:
	if main == null or not is_instance_valid(main):
		return
	if is_client():
		_local_input.poll()
		_push_intent.rpc_id(1, _local_input.to_intent())
	elif is_host() and not _peer_to_player.is_empty():
		_snap_timer -= delta
		if _snap_timer <= 0.0:
			_snap_timer = 1.0 / SNAPSHOT_HZ
			_apply_snapshot.rpc(build_snapshot())


func build_snapshot() -> Dictionary:
	var players: Array = []
	for p in (main.get("coop") as CoopManager).players:
		if is_instance_valid(p):
			players.append([p.player_index, p.global_position, p.facing_direction, p.velocity, p.current_health,
				p.is_rolling, p.is_attacking, p.is_eating, p.current_tool,
				p.digesting_fruits.map(func(f): return [String(f.get("species_id", "")), float(f.get("remaining_duration", 0)), float(f.get("digestion_duration", 1))])])
	var enemies: Array = []
	for e in main.get_tree().get_nodes_in_group("enemies"):
		enemies.append([e.get_instance_id(), e.enemy_type, e.global_position, e.current_health, e.max_health, e.has_eaten_fruit, e.eaten_family])
	var plots: Array = []
	for pl in main.get("initial_plots"):
		plots.append([pl.tree_stage, String(pl.planted_species_id), pl.fruit_count, pl.current_ripeness, pl.water_level, pl.locked, pl.has_blight, pl.is_timing_harvest, pl.timing_cursor])
	var dm: DayCycleManager = main.get("day_manager")
	return {"p": players, "e": enemies, "pl": plots,
		"d": [dm.day_number, dm.current_phase, dm.current_season, dm.is_raid_active],
		"g": (main.get("market_manager") as MarketManager).gold}


# ── client side ─────────────────────────────────────────────────────────────

@rpc("authority", "reliable")
func _assign_index(index: int) -> void:
	my_index = index
	HUDBus.toast("Joined as Player %d" % (index + 1), CoopManager.TINTS[index])
	if main:
		main.call("net_bind_local", index)


@rpc("authority", "unreliable_ordered")
func _apply_snapshot(s: Dictionary) -> void:
	last_snapshot = s
	snapshots_received += 1
	if main and is_instance_valid(main):
		main.call("net_apply_snapshot", s)


@rpc("authority", "unreliable")
func _spawn_projectile_visual(pos: Vector2, dir: Vector2, fam: int, speed: float, hostile: bool) -> void:
	if main == null or FX.world == null:
		return
	var proj := ElementalProjectile.new()
	proj.position = pos
	proj.setup(dir, 0.0, fam, speed)
	proj.visual_only = true
	proj.hostile = hostile
	FX.world.add_child(proj)
