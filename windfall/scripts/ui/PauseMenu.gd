extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_connect_buttons()
	_connect_game_state()
	_sync_visibility_with_game_state()


func _process(_delta: float) -> void:
	if InputMap.has_action("pause") and Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _connect_buttons() -> void:
	if resume_button != null and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button != null and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button != null and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)


func _connect_game_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("state_changed"):
		if not game_state.state_changed.is_connected(_on_game_state_changed):
			game_state.state_changed.connect(_on_game_state_changed)


func _sync_visibility_with_game_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("is_state"):
		visible = bool(game_state.call("is_state", game_state.State.PAUSED))
	else:
		visible = false


func _toggle_pause() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("toggle_pause"):
		game_state.call("toggle_pause")


func _on_game_state_changed(_previous_state, current_state) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		visible = current_state == game_state.State.PAUSED


func _on_resume_pressed() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("resume_game"):
		game_state.call("resume_game")


func _on_restart_pressed() -> void:
	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("reload_current_scene"):
		scene_loader.call("reload_current_scene")


func _on_quit_pressed() -> void:
	var scene_loader := get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("quit_game"):
		scene_loader.call("quit_game")
