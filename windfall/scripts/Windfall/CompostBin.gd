extends Area2D
class_name CompostBin

## Turn windfall (over-ripe, dropped) fruit into compost. Compost is applied
## to plots with the Hoe-Staff: it cures blight and gives a growth surge.

var is_focused: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 44)
	col.shape = shape
	add_child(col)
	_sprite = Art.sprite("props/compost_bin", 1, 1, Vector2(26, 46))
	add_child(_sprite)


func _market() -> MarketManager:
	return get_tree().get_first_node_in_group("market") as MarketManager


func get_prompt() -> String:
	var m := _market()
	var n := _windfall_count()
	if n > 0:
		return "Compost %d windfall fruit" % n
	return "Compost bin (x%d) · bring windfall fruit" % (m.compost if m else 0)


func _windfall_count() -> int:
	var p := get_tree().get_first_node_in_group("player") as RootbornPlayer
	if p == null:
		return 0
	return p.satchel_fruits.filter(func(f): return int(f.get("ripeness", 2)) == WindfallTypes.Ripeness.WINDFALL).size()


func interact(player: RootbornPlayer) -> void:
	var m := _market()
	var n := 0
	for i in range(player.satchel_fruits.size() - 1, -1, -1):
		if int(player.satchel_fruits[i].get("ripeness", 2)) == WindfallTypes.Ripeness.WINDFALL:
			player.satchel_fruits.remove_at(i)
			n += 1
	if n == 0:
		HUDBus.toast("Only windfall fruit rots down into compost.", WPal.CREAM[3])
		return
	m.compost += n * 2
	m.compost_changed.emit(m.compost)
	player.satchel_changed.emit()
	FX.burst(global_position + Vector2(0, -24), "fx/leaf", Color.WHITE, 10, 60.0, 0.8, Vector2(0, 60), 120.0, Vector2.UP, Vector2(1, 1.4), "world")
	FX.popup("+%d COMPOST" % (n * 2), global_position + Vector2(0, -48), WPal.LEAF[5], 15)
	WindfallSound.play_plant()


func set_focused(val: bool) -> void:
	is_focused = val
	_sprite.self_modulate = Color(1.12, 1.08, 0.98) if val else Color.WHITE
