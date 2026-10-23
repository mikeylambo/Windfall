extends Node

signal dialogue_started(data: DialogueData)
signal dialogue_line_changed(speaker: String, text: String)
signal dialogue_finished(choice_index: int)

var current_dialogue: DialogueData = null
var current_line_idx: int = -1
var is_active: bool = false


func start_dialogue(data: DialogueData) -> void:
	if data == null:
		return
	current_dialogue = data
	current_line_idx = 0
	is_active = true
	dialogue_started.emit(current_dialogue)
	_show_current_line()


func advance_dialogue() -> void:
	if not is_active or current_dialogue == null:
		return
	current_line_idx += 1
	if current_line_idx < current_dialogue.lines.size():
		_show_current_line()
	elif current_dialogue.choices.is_empty():
		finish_dialogue(-1)


func select_choice(choice_idx: int) -> void:
	finish_dialogue(choice_idx)


func finish_dialogue(choice_idx: int) -> void:
	is_active = false
	current_dialogue = null
	current_line_idx = -1
	dialogue_finished.emit(choice_idx)


func _show_current_line() -> void:
	if current_dialogue != null and current_line_idx < current_dialogue.lines.size():
		dialogue_line_changed.emit(current_dialogue.speaker_name, current_dialogue.lines[current_line_idx])
