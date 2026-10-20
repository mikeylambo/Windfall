extends SceneTree

## Runs tools/playtest_driver.gd: title → new game → full loop → continue.
##   xvfb-run godot --rendering-driver opengl3 --resolution 1280x720 -s res://tools/playtest_runner.gd

func _initialize() -> void:
	_go()


func _go() -> void:
	var Driver := load("res://tools/playtest_driver.gd")
	var d = Driver.new()
	root.add_child(d)
	d.tree = self

	# title screen
	change_scene_to_file("res://scenes/UI/TitleScreen.tscn")
	await create_timer(2.0).timeout
	await d.shot("00_title")

	# new game
	root.get_node("/root/SaveManager").delete_save()
	root.get_node("/root/GameFlow").set_meta("pending_load", false)
	change_scene_to_file("res://scenes/Windfall/WindfallMain.tscn")
	await process_frame
	await process_frame
	await d.run(current_scene, self)
	var gold: int = current_scene.market_manager.gold

	# continue
	root.get_node("/root/GameFlow").set_meta("pending_load", true)
	change_scene_to_file("res://scenes/Windfall/WindfallMain.tscn")
	await process_frame
	await process_frame
	await d.run_continue(current_scene, self, gold)

	print("[playtest] RESULT: %s (%d failures)" % ["OK" if d.failures == 0 else "FAILED", d.failures])
	quit(0 if d.failures == 0 else 1)
