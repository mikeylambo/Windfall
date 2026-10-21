extends Node2D

## Title screen: a living diorama of the homestead behind the WINDFALL logo.

const GAME_SCENE := "res://scenes/Windfall/WindfallMain.tscn"

var _cam: Camera2D
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

	var ground := Node2D.new()
	add_child(ground)
	var world := Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var overlay := CanvasLayer.new()
	overlay.layer = 2
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	FX.bind(world, overlay)
	FX.night = 0.15
	var dresser := WorldDresser.new()
	add_child(dresser)
	dresser.dress(world, ground)

	# an orchard in full fruit, one tree per element
	var fams := [1, 0, 2, 4, 3, 7]
	for i in WorldLayout.PLOTS.size():
		var p: Vector2 = WorldLayout.PLOTS[i]
		if i >= WorldLayout.STARTING_PLOTS:
			var wild := Art.sprite("props/overgrown_plot")
			wild.centered = true
			wild.offset = Vector2.ZERO
			wild.position = p + Vector2(0, 6)
			wild.z_index = -5
			world.add_child(wild)
			continue
		var stage := 6 if i == 3 else 5
		var trunk := Art.sprite("trees/trunk_%d" % stage, 1, 1, Vector2(48, 120))
		trunk.position = p
		world.add_child(trunk)
		var crown := Art.sprite("trees/canopy_%d_%d" % [stage, fams[i]], 1, 1, Vector2(48, 120))
		crown.material = Art.sway_material(1.2, i * 1.7)
		trunk.add_child(crown)
		var soil := Art.sprite("world/soil_%d" % (i % 6))
		soil.centered = true
		soil.offset = Vector2.ZERO
		soil.position = Vector2(0, 6)
		soil.z_index = -5
		trunk.add_child(soil)
		for k in 4:
			var f := Art.sprite("trees/fruit_%d" % fams[i], 4, 1)
			f.centered = true
			f.offset = Vector2.ZERO
			f.position = OrchardPlot2D.FRUIT_SPOTS[stage][k]
			trunk.add_child(f)
		if stage == 6:
			FX.glow(trunk, WPal.element(fams[i], 3), 90.0, Vector2(0, -80), 0.5, 0.5)

	var mod := CanvasModulate.new()
	mod.color = DayLighting.sample(0.6)
	add_child(mod)

	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.5, 1.5)
	_cam.position = Vector2(820, 560)
	add_child(_cam)
	_cam.make_current()

	_add_ambient_particles(overlay)
	_build_ui()
	WindfallSound.start_ambience()
	WindfallSound.set_ambience_night(false)
	WindfallSound.prewarm()


func _add_ambient_particles(overlay: CanvasLayer) -> void:
	var leaves := CPUParticles2D.new()
	leaves.texture = Art.tex("fx/leaf")
	leaves.amount = 24
	leaves.lifetime = 8.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(800, 10)
	leaves.position = Vector2(820, 200)
	leaves.direction = Vector2(0.4, 1)
	leaves.gravity = Vector2(10, 18)
	leaves.initial_velocity_min = 10
	leaves.initial_velocity_max = 30
	leaves.angular_velocity_min = -90
	leaves.angular_velocity_max = 90
	leaves.scale_amount_min = 1.5
	leaves.scale_amount_max = 2.5
	leaves.preprocess = 8.0
	overlay.add_child(leaves)
	var flies := CPUParticles2D.new()
	flies.texture = Art.glow_texture()
	flies.amount = 30
	flies.lifetime = 5.0
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(700, 300)
	flies.position = Vector2(820, 600)
	flies.gravity = Vector2(0, -4)
	flies.initial_velocity_min = 4
	flies.initial_velocity_max = 14
	flies.spread = 180
	flies.scale_amount_min = 0.12
	flies.scale_amount_max = 0.22
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
	var logo := UIKit.header("WINDFALL", 88, UITheme.GOLD)
	logo.add_theme_constant_override("outline_size", 18)
	logo.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.1, 0.6))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 8)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_child(logo)
	var sub := UIKit.bold("~ Skill-Tree Gardening ~", 22, Color("c2e078"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_child(sub)
	var sprout := HBoxContainer.new()
	sprout.alignment = BoxContainer.ALIGNMENT_CENTER
	for fam in 8:
		sprout.add_child(UIKit.icon("icons/fruit_%d" % fam, 30))
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

	_logo.pivot_offset = Vector2(260, 60)
	_logo.modulate.a = 0.0
	_logo.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(_logo, "modulate:a", 1.0, 0.8)
	t.tween_property(_logo, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	_cam.position = Vector2(820 + sin(_t * 0.07) * 260.0, 540 + sin(_t * 0.05) * 60.0)
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
