extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ui_player: AudioStreamPlayer
var sfx_pool_size: int = 8


func _ready() -> void:
	_ensure_audio_bus(&"Master")
	_ensure_audio_bus(&"Music")
	_ensure_audio_bus(&"SFX")
	_ensure_audio_bus(&"UI")
	_setup_music_player()
	_setup_ui_player()
	_setup_sfx_pool()


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if music_player == null:
		_setup_music_player()

	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()


func stop_music() -> void:
	if music_player != null:
		music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if sfx_players.is_empty():
		_setup_sfx_pool()

	var player := sfx_players[0]
	for candidate in sfx_players:
		if not candidate.playing:
			player = candidate
			break

	player.stream = stream
	player.volume_db = volume_db
	player.play()


func play_ui(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if ui_player == null:
		_setup_ui_player()

	ui_player.stream = stream
	ui_player.volume_db = volume_db
	ui_player.play()


func set_bus_volume(bus_name: StringName, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)


func mute_bus(bus_name: StringName, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, muted)


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, String(bus_name))
	if bus_name != &"Master":
		AudioServer.set_bus_send(bus_index, &"Master")


func _setup_music_player() -> void:
	music_player = get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)
	music_player.bus = &"Music"


func _setup_ui_player() -> void:
	ui_player = get_node_or_null("UIPlayer") as AudioStreamPlayer
	if ui_player == null:
		ui_player = AudioStreamPlayer.new()
		ui_player.name = "UIPlayer"
		add_child(ui_player)
	ui_player.bus = &"UI"


func _setup_sfx_pool() -> void:
	sfx_players.clear()
	for index in sfx_pool_size:
		var player_name := "SFXPlayer%s" % str(index)
		var player := get_node_or_null(player_name) as AudioStreamPlayer
		if player == null:
			player = AudioStreamPlayer.new()
			player.name = player_name
			add_child(player)
		player.bus = &"SFX"
		sfx_players.append(player)
