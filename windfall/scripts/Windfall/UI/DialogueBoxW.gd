extends PanelContainer
class_name DialogueBoxW

## Vine-framed dialogue box driven by the template's DialogueManager autoload.
## Typewriter text, blip sounds, a bobbing continue marker, and the
## speaker's painted portrait (portraits/<speaker>.png) when one exists.

signal closed

var _name: Label
var _portrait: PanelContainer
var _face: TextureRect
var _text: RichTextLabel
var _arrow: Label
var _on_done: Callable
var _choices: Array = []
var _choice_box: HBoxContainer
var _on_choice: Callable
var _typing: bool = false
var _t: float = 0.0


func _init() -> void:
	theme_type_variation = "VinePanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(760, 150)
	var row := UIKit.hbox(14)
	add_child(row)
	_portrait = UIKit.panel("PaperPanel")
	_portrait.custom_minimum_size = Vector2(128, 128)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(116, 116)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portrait.add_child(_face)
	var v := UIKit.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	_name = UIKit.header("", 18)
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(560, 60)
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_font_size_override("bold_font_size", 20)
	v.add_child(_text)
	_choice_box = UIKit.hbox(10)
	_choice_box.visible = false
	v.add_child(_choice_box)
	# the arrow bobs inside its own holder so the VBox never re-seats it
	var arrow_row := Control.new()
	arrow_row.custom_minimum_size = Vector2(0, 22)
	v.add_child(arrow_row)
	_arrow = UIKit.bold("▼", 16, UITheme.GOLD)
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow_row.add_child(_arrow)


func _ready() -> void:
	DialogueManager.dialogue_line_changed.connect(_on_line)
	DialogueManager.dialogue_finished.connect(_on_finished)


## Open with optional choices (shown after the last line).
func open_with_choices(data: DialogueData, on_choice: Callable) -> void:
	_on_choice = on_choice
	open(data, Callable())


func open(data: DialogueData, on_done: Callable) -> void:
	_on_done = on_done
	_choices = data.choices
	_name.text = ""
	_set_portrait(data.speaker_name)
	_choice_box.visible = false
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	DialogueManager.start_dialogue(data)


func _on_line(speaker: String, text: String) -> void:
	if speaker != _name.text:
		_set_portrait(speaker)
	_name.text = speaker
	_text.text = text
	_text.visible_characters = 0
	_typing = true


func _set_portrait(speaker: String) -> void:
	var path := "portraits/" + speaker.to_lower()
	var has := ResourceLoader.exists(Art.ROOT + path + ".png")
	_portrait.visible = has
	if not has:
		return
	_face.texture = Art.tex(path)
	# a small pop as a new face takes the stage
	_face.pivot_offset = _face.custom_minimum_size * 0.5
	_face.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(_face, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
			_maybe_show_choices()
	_arrow.modulate.a = 0.0 if _typing else 1.0
	_arrow.position.y = sin(_t * 6.0) * 2.0


func _maybe_show_choices() -> void:
	var last := DialogueManager.current_dialogue != null and DialogueManager.current_line_idx >= DialogueManager.current_dialogue.lines.size() - 1
	if not last or _choices.is_empty() or _choice_box.visible:
		return
	for c in _choice_box.get_children():
		c.queue_free()
	var first: Button = null
	for i in _choices.size():
		var idx := i
		var b := UIKit.button(_choices[i], func(): DialogueManager.select_choice(idx))
		_choice_box.add_child(b)
		if first == null:
			first = b
	_choice_box.visible = true
	first.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choice_box.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _typing:
			_text.visible_characters = -1
			_typing = false
			_maybe_show_choices()
		else:
			DialogueManager.advance_dialogue()


func _on_finished(choice: int) -> void:
	visible = false
	_choice_box.visible = false
	closed.emit()
	if _on_choice.is_valid():
		var cc := _on_choice
		_on_choice = Callable()
		cc.call(choice)
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call()
