extends WMenu
class_name PauseMenuW

const TITLE_SCENE := "res://scenes/UI/TitleScreen.tscn"

var _main: VBoxContainer
var _settings: SettingsPanel


func _icon() -> String:
	return "icons/sun"


func _title_text() -> String:
	return "PAUSED"


func build() -> void:
	_main = UIKit.vbox(8)
	_main.custom_minimum_size.x = 340
	body.add_child(_main)
	var items := [
		UIKit.button("Resume", close),
		UIKit.button("Settings", _open_settings),
		UIKit.button("Save Game", _save),
		UIKit.button("Quit to Title", _to_title),
		UIKit.button("Quit Game", func(): get_tree().quit()),
	]
	for b in items:
		_main.add_child(b)
	set_first_focus(items[0])
	# controls cheat sheet
	var help := UIKit.label("Move WASD/Stick · Attack J/X · Dodge Shift/B · Interact E/A\nEat 1-3/D-pad · Skills Q R T/LB RB RT · Quickroot F/LT · Tool Tab/Y", 13, UITheme.CREAM_DIM)
	body.add_child(help)


func _open_settings() -> void:
	_main.visible = false
	_settings = SettingsPanel.new()
	_settings.back_pressed.connect(func():
		_settings.queue_free()
		_main.visible = true
		focus_first())
	body.add_child(_settings)
	body.move_child(_settings, 0)
	_settings.first.call_deferred("grab_focus")


func _save() -> void:
	if SaveManager.save_game():
		HUDBus.toast("Game saved", WPal.LEAF[5])
	close()


func _to_title() -> void:
	SaveManager.save_game()
	get_tree().paused = false
	WindfallSound.stop_ambience()
	SceneLoader.change_scene(TITLE_SCENE)
