extends Area2D
class_name MarketStallProp

@export var market_manager: MarketManager
var is_focused: bool = false


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 40)
	col.shape = shape
	add_child(col)


func interact(player: RootbornPlayer) -> void:
	if market_manager == null:
		return

	# Sell all fresh fruits in satchel
	if not player.satchel_fruits.is_empty():
		var total_earned := 0
		for f in player.satchel_fruits:
			total_earned += market_manager.sell_fruit(f)
		player.satchel_fruits.clear()
		player.satchel_changed.emit()
	else:
		# Open market UI or buy seed
		var hud = get_tree().get_first_node_in_group("hud") as WindfallHUD
		if hud != null:
			hud.is_market_open = not hud.is_market_open
			hud.queue_redraw()


func set_focused(val: bool) -> void:
	is_focused = val
	queue_redraw()


func _draw() -> void:
	# Wooden stall counter
	draw_rect(Rect2(-24, -18, 48, 36), Color(0.42, 0.28, 0.16))
	# Counter top
	draw_rect(Rect2(-26, -20, 52, 10), Color(0.55, 0.38, 0.22))
	# Striped awning
	draw_rect(Rect2(-26, -34, 52, 14), Color(0.85, 0.25, 0.2))
	draw_rect(Rect2(-16, -34, 10, 14), Color(0.95, 0.9, 0.8))
	draw_rect(Rect2(4, -34, 10, 14), Color(0.95, 0.9, 0.8))

	if is_focused:
		draw_rect(Rect2(-26, -34, 52, 52), Color(1, 0.9, 0.4), false, 2.0)
