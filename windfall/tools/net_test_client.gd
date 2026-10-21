## Online co-op smoke test, client half. Run with tools/net_test.sh.
extends SceneTree
func _initialize(): _go()
func _go():
	await process_frame
	var net = root.get_node("/root/Net")
	await create_timer(2.5).timeout
	net.session_started.connect(func(_r): change_scene_to_file("res://scenes/Windfall/WindfallMain.tscn"))
	net.join("127.0.0.1", 7781)
	var fake = load("res://scripts/Windfall/Input/NetworkInput.gd").new()
	net._local_input = fake
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		await process_frame
		fake.push_intent({"m": [1.0, 0.0], "p": []})
		if net.snapshots_received > 40:
			var m = net.main
			print("[client] PASS snapshots=%d my_index=%d puppets=%d plots_synced=%s" % [net.snapshots_received, net.my_index, m._net_players.size(), str(m.initial_plots[0].tree_stage == 5)])
			quit(0)
			return
	print("[client] FAIL snapshots=%d" % net.snapshots_received)
	quit(1)
