extends PanelContainer
class_name DialogueBoxW

## Vine-framed dialogue box driven by the template's DialogueManager autoload.
## Typewriter text, blip sounds, and a bobbing continue marker.

signal closed

var _name: Label
var _text: RichTextLabel
var _arrow: Label
var _on_done: Callable
var _typing: bool = false
var _t: float = 0.0


func _init() -> void:
	theme_type_variation = "VinePanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(760, 150)
	var v := UIKit.vbox(6)
	add_child(v)
	_name = UIKit.header("", 18)
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(700, 60)
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_font_size_override("bold_font_size", 20)
	v.add_child(_text)
	_arrow = UIKit.bold("▼", 16, UITheme.GOLD)
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_arrow)


func _ready() -> void:
	DialogueManager.dialogue_line_changed.connect(_on_line)
	DialogueManager.dialogue_finished.connect(_on_finished)


func open(data: DialogueData, on_done: Callable) -> void:
	_on_done = on_done
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	DialogueManager.start_dialogue(data)


func _on_line(speaker: String, text: String) -> void:
	_name.text = speaker
	_text.text = text
	_text.visible_characters = 0
	_typing = true


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _typing:
		var before := _text.visible_characters
		_text.visible_characters = mini(_text.visible_characters + maxi(1, int(delta * 55.0)), _text.get_total_character_count())
		if _text.visible_characters / 3 != before / 3:
			WindfallSound.play_ui_move()
		if _text.visible_characters >= _text.get_total_character_count():
			_typing = false
	_arrow.modulate.a = 0.0 if _typing else 1.0
	_arrow.position.y = sin(_t * 6.0) * 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _typing:
			_text.visible_characters = -1
			_typing = false
		else:
			DialogueManager.advance_dialogue()


func _on_finished(_choice: int) -> void:
	visible = false
	closed.emit()
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call()
