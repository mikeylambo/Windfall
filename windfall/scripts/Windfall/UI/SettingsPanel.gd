extends VBoxContainer
class_name SettingsPanel

## Volume + display settings on top of the template SettingsManager.

signal back_pressed

const BUSES := [["Master", "master_volume_db"], ["Music & Ambience", "music_volume_db"], ["Effects", "sfx_volume_db"], ["Interface", "ui_volume_db"]]
var first: Control


func _init() -> void:
	add_theme_constant_override("separation", 10)
	var controls: Array = []
	for b in BUSES:
		var row := UIKit.hbox(12)
		var l := UIKit.bold(b[0], 16)
		l.custom_minimum_size.x = 200
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 100
		s.step = 5
		s.custom_minimum_size = Vector2(260, 24)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.value = _db_to_pct(float(SettingsManager.get_setting(b[1], 0.0)))
		var key: String = b[1]
		s.value_changed.connect(func(v: float):
			SettingsManager.set_setting(key, _pct_to_db(v))
			SettingsManager.apply_settings()
			WindfallSound.play_ui_move())
		row.add_child(s)
		add_child(row)
		controls.append(s)
	var fs := UIKit.button("Fullscreen: %s" % ("On" if SettingsManager.get_setting("fullscreen", false) else "Off"))
	fs.pressed.connect(func():
		var on := not bool(SettingsManager.get_setting("fullscreen", false))
		SettingsManager.set_setting("fullscreen", on)
		SettingsManager.apply_settings()
		fs.text = "Fullscreen: %s" % ("On" if on else "Off"))
	add_child(fs)
	controls.append(fs)
	var back := UIKit.button("Back", func():
		SettingsManager.save_settings()
		back_pressed.emit())
	add_child(back)
	controls.append(back)
	first = controls[0]


static func _db_to_pct(db: float) -> float:
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)


static func _pct_to_db(p: float) -> float:
	return linear_to_db(maxf(p / 100.0, 0.0001))
