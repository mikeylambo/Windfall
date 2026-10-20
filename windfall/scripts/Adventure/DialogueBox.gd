extends CanvasLayer
class_name DialogueBox

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var choices_container: HBoxContainer = $Panel/ChoicesContainer
@onready var continue_prompt: Label = $Panel/ContinuePrompt

var _mgr: Node = null


func _ready() -> void:
	panel.visible = false
	_mgr = get_node_or_null("/root/DialogueManager")
	if _mgr != null:
		_mgr.dialogue_started.connect(_on_dialogue_started)
		_mgr.dialogue_line_changed.connect(_on_line_changed)
		_mgr.dialogue_finished.connect(_on_dialogue_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible or _mgr == null:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("confirm") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if choices_container.get_child_count() == 0:
			_mgr.call("advance_dialogue")


func _on_dialogue_started(data: DialogueData) -> void:
	panel.visible = true
	_clear_choices()


func _on_line_changed(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	_clear_choices()

	# If last line and choices exist, show buttons
	if _mgr != null and _mgr.get("current_dialogue") != null:
		var d: DialogueData = _mgr.get("current_dialogue")
		if _mgr.get("current_line_idx") == d.lines.size() - 1 and not d.choices.is_empty():
			continue_prompt.visible = false
			for i in range(d.choices.size()):
				var btn := Button.new()
				btn.text = d.choices[i]
				var idx := i
				btn.pressed.connect(func(): _mgr.call("select_choice", idx))
				choices_container.add_child(btn)
		else:
			continue_prompt.visible = true


func _on_dialogue_finished(_choice: int) -> void:
	panel.visible = false
	_clear_choices()


func _clear_choices() -> void:
	for c in choices_container.get_children():
		c.queue_free()
