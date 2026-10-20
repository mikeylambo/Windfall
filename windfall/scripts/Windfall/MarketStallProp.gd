extends Area2D
class_name MarketStallProp

@export var market_manager: MarketManager
var is_focused: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(110, 60)
	col.shape = shape
	add_child(col)
	_sprite = Art.sprite("props/market_stall", 1, 1, Vector2(64, 108))
	add_child(_sprite)
	var body := StaticBody2D.new()
	var bcs := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(112, 26)
	bcs.shape = br
	bcs.position = Vector2(0, -16)
	body.add_child(bcs)
	add_child(body)


func get_prompt() -> String:
	return "Trade at the Market"


func interact(_player: RootbornPlayer) -> void:
	if market_manager == null:
		return
	HUDBus.open_menu("market")


func set_focused(val: bool) -> void:
	is_focused = val
	_sprite.self_modulate = Color(1.12, 1.08, 0.98) if val else Color.WHITE
