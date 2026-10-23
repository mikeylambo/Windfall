## Online co-op smoke test, host half. Run with tools/net_test.sh.
extends SceneTree
func _initialize(): _go()
func _go():
	await process_frame
	var net = root.get_node("/root/Net")
	root.get_node("/root/SaveManager").delete_save()
	net.host(7781)
	change_scene_to_file("res://scenes/Windfall/WindfallMain.tscn")
	var t0 := Time.get_ticks_msec()
	var remote = null
	var start := Vector2.ZERO
	while Time.get_ticks_msec() - t0 < 25000:
		await create_timer(0.25).timeout
		if remote == null and net._peer_to_player.size() > 0:
			remote = net._peer_to_player.values()[0]
			start = remote.global_position
			print("[host] remote player joined as P%d" % (remote.player_index + 1))
		if remote and remote.global_position.x - start.x > 60.0:
			print("[host] PASS remote player moved by client intents (%.0f px)" % (remote.global_position.x - start.x))
			await create_timer(6.0).timeout
			quit(0)
			return
	print("[host] FAIL remote=%s moved=%.0f" % [remote != null, (remote.global_position.x - start.x) if remote else 0.0])
	quit(1)
