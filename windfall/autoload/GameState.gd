extends Node

enum State { BOOT, MAIN_MENU, PLAYING, PAUSED, LOADING, GAME_OVER }

signal state_changed(previous_state, current_state)

var current_state: State = State.BOOT
var previous_state: State = State.BOOT


func set_state(new_state: State) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)


func get_state() -> State:
	return current_state


func is_state(state: State) -> bool:
	return current_state == state


func pause_game() -> void:
	set_state(State.PAUSED)
	get_tree().paused = true
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_game_paused"):
		event_bus.call("emit_game_paused")


func resume_game() -> void:
	get_tree().paused = false
	set_state(State.PLAYING)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_method("emit_game_resumed"):
		event_bus.call("emit_game_resumed")


func toggle_pause() -> void:
	if current_state == State.PAUSED:
		resume_game()
	else:
		pause_game()
