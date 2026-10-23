extends Node2D

## Title screen: the painted homestead (day, or night after dark on the
## player's clock) drifting slowly behind the WINDFALL logo.

const GAME_SCENE := "res://scenes/Windfall/WindfallMain.tscn"
const DRIFT := 1.06

var _plate: TextureRect
var _night: bool = false
var _t: float = 0.0
var _menu: VBoxContainer
var _settings: SettingsPanel
var _logo: Control
var _continue: Button


func _ready() -> void:
	GameFlow.gameplay_scene = GAME_SCENE
	GameFlow.main_menu_scene = "res://scenes/UI/TitleScreen.tscn"
	GameFlow.set_mode(&"main_menu")
	get_tree().paused = false
	Engine.time_scale = 1.0

	var hour := int(Time.get_datetime_dict_from_system().get("hour", 12))
	_night = hour >= 19 or hour < 6
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	_plate = TextureRect.new()
	_plate.texture = Art.tex("ui/title_night" if _night else "ui/title_day")
	_plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(_plate)
	_plate.resized.connect(func(): _plate.pivot_offset = _plate.size * 0.5)

	var overlay := CanvasLayer.new()
	overlay.layer = 2
	add_child(overlay)
	_add_ambient_particles(overlay)
	_build_ui()
	WindfallSound.start_ambience()
	WindfallSound.set_ambience_night(_night)
	WindfallSound.prewarm()


func _add_ambient_particles(overlay: CanvasLayer) -> void:
	var view := get_viewport().get_visible_rect().size
	var leaves := CPUParticles2D.new()
	leaves.texture = Art.tex("fx/leaf")
	leaves.amount = 8 if _night else 20
	leaves.lifetime = 9.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(view.x * 0.6, 10)
	leaves.position = Vector2(view.x * 0.5, -20)
	leaves.direction = Vector2(0.4, 1)
	leaves.gravity = Vector2(10, 18)
	leaves.initial_velocity_min = 10
	leaves.initial_velocity_max = 30
	leaves.angular_velocity_min = -90
	leaves.angular_velocity_max = 90
	leaves.scale_amount_min = 2.0
	leaves.scale_amount_max = 3.0
	leaves.preprocess = 9.0
	overlay.add_child(leaves)
	var flies := CPUParticles2D.new()
	flies.texture = Art.glow_texture()
	flies.amount = 40 if _night else 18
	flies.lifetime = 5.0
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(view.x * 0.5, view.y * 0.25)
	flies.position = Vector2(view.x * 0.5, view.y * 0.72)
	flies.gravity = Vector2(0, -4)
	flies.initial_velocity_min = 4
	flies.initial_velocity_max = 14
	flies.spread = 180
	flies.scale_amount_min = 0.1
	flies.scale_amount_max = 0.2
	flies.color = WPal.GOLD[4]
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 1))
	flies.color_ramp = g
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flies.material = add
	flies.preprocess = 5.0
	overlay.add_child(flies)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.theme = load("res://assets/ui/windfall_theme.tres")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var vignette := TextureRect.new()
	vignette.texture = Art.tex("ui/vignette")
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var col := UIKit.vbox(6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	_logo = UIKit.vbox(0)
	# the painted logo already carries the "Skill-Tree Gardening" plank
	var logo := UIKit.icon("ui/logo", 0)
	logo.custom_minimum_size = Vector2(560, 238)
	_logo.add_child(logo)
	var sprout := HBoxContainer.new()
	sprout.alignment = BoxContainer.ALIGNMENT_CENTER
	# one signature fruit per family, in family order
	for sid in [&"voltberry", &"cinderapple", &"snowquince", &"brinemelon", &"vine_apple", &"zephyr_kiwi", &"eclipse_cherry", &"starfruit"]:
		sprout.add_child(UIKit.icon(Art.species_icon(sid), 38))
	_logo.add_child(sprout)
	col.add_child(_logo)
	col.add_child(UIKit.spacer(0, 20))

	var holder := CenterContainer.new()
	col.add_child(holder)
	var panel := UIKit.panel()
	holder.add_child(panel)
	_menu = UIKit.vbox(8)
	_menu.custom_minimum_size.x = 300
	panel.add_child(_menu)
	var new_game := UIKit.button("New Game", _new_game, "icons/season_0")
	_continue = UIKit.button("Continue", _continue_game, "icons/sun")
	_continue.disabled = not SaveManager.has_save()
	var online := UIKit.button("Online Co-op", _open_online, "icons/star")
	var settings := UIKit.button("Settings", _open_settings, "icons/codex")
	var quit := UIKit.button("Quit", func(): get_tree().quit(), "icons/moon")
	for b in [new_game, _continue, online, settings, quit]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_menu.add_child(b)
	(_continue if not _continue.disabled else new_game).call_deferred("grab_focus")

	var foot := UIKit.label("v1.0 playtest  ·  Made with Godot 4.6", 13, UITheme.CREAM_DIM)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	foot.position = Vector2(-16, -12)
	root.add_child(foot)

	_logo.pivot_offset = Vector2(280, 140)
	_logo.modulate.a = 0.0
	_logo.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(_logo, "modulate:a", 1.0, 0.8)
	t.tween_property(_logo, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	# slow Ken Burns drift: a gentle zoom-in with a lazy sideways sway
	var z := DRIFT + 0.02 * sin(_t * 0.05)
	_plate.scale = Vector2(z, z)
	_plate.position = Vector2(sin(_t * 0.04) * 18.0, cos(_t * 0.03) * 6.0)
	if _logo:
		_logo.position.y = sin(_t * 1.4) * 3.0


func _new_game() -> void:
	if not Net.online():
		SaveManager.delete_save()
	QuestManager.completed_quests.clear()
	QuestManager.active_quests.clear()
	GameFlow.set_meta("pending_load", false)
	_go()


func _continue_game() -> void:
	GameFlow.set_meta("pending_load", true)
	_go()


func _go() -> void:
	WindfallSound.stop_ambience()
	var fade := ColorRect.new()
	fade.color = Color("0e0a14")
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	layer.add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, 0.45)
	t.tween_callback(func(): GameFlow.start_game())


func _open_online() -> void:
	_menu.visible = false
	var box := UIKit.vbox(8)
	box.custom_minimum_size.x = 340
	_menu.get_parent().add_child(box)
	box.add_child(UIKit.header("ONLINE CO-OP", 30))
	box.add_child(UIKit.label("Host shares your orchard; up to 2 friends join by IP (port %d)." % Net.PORT, 20, UITheme.CREAM_DIM))
	var status := UIKit.label("", 20, UITheme.GOLD)
	var ip := LineEdit.new()
	ip.text = "127.0.0.1"
	ip.placeholder_text = "Host IP address"
	ip.custom_minimum_size = Vector2(300, 40)
	var host_btn := UIKit.button("Host a Game", func():
		if Net.host():
			status.text = "Hosting on port %d..." % Net.PORT
			if SaveManager.has_save():
				_continue_game()
			else:
				_new_game())
	var join_btn := UIKit.button("Join", func():
		status.text = "Connecting to %s..." % ip.text
		Net.session_started.connect(func(_r): _join_world(), CONNECT_ONE_SHOT)
		Net.session_failed.connect(func(reason): status.text = reason, CONNECT_ONE_SHOT)
		Net.join(ip.text.strip_edges()))
	var back := UIKit.button("Back", func():
		box.queue_free()
		_menu.visible = true
		_menu.get_child(0).grab_focus())
	for c in [host_btn, ip, join_btn, back, status]:
		box.add_child(c)
	host_btn.call_deferred("grab_focus")


func _join_world() -> void:
	GameFlow.set_meta("pending_load", false)
	_go()


func _open_settings() -> void:
	_menu.visible = false
	_settings = SettingsPanel.new()
	_settings.back_pressed.connect(func():
		_settings.queue_free()
		_menu.visible = true
		_menu.get_child(0).grab_focus())
	_menu.get_parent().add_child(_settings)
	_settings.first.call_deferred("grab_focus")
