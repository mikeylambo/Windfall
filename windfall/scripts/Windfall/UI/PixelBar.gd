extends Control
class_name PixelBar

## Pixel-art value bar: 9-slice frame, stretched fill, and a trailing "damage
## ghost" segment that drains after the real value so hits read clearly.

var max_value: float = 100.0:
	set(v):
		max_value = maxf(v, 0.001)
		queue_redraw()
var value: float = 100.0:
	set(v):
		if v < value:
			_ghost = maxf(_ghost, value)
		value = v
		queue_redraw()
var fill: Texture2D
var _frame: StyleBoxTexture
var _ghost: float = 0.0


func _init(fill_path: String = "ui/bar_hp", w: int = 200) -> void:
	fill = Art.tex(fill_path)
	_frame = UITheme.box("ui/bar_frame", 9, 3)
	custom_minimum_size = Vector2(w, 24)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _ghost > value:
		_ghost = move_toward(_ghost, value, max_value * delta * 0.6)
		queue_redraw()


func _draw() -> void:
	draw_style_box(_frame, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	if _ghost > value:
		var gw := inner.size.x * clampf(_ghost / max_value, 0.0, 1.0)
		draw_rect(Rect2(inner.position, Vector2(gw, inner.size.y)), Color("fff2d6"))
	var w := inner.size.x * clampf(value / max_value, 0.0, 1.0)
	if w > 0.5 and fill:
		draw_texture_rect(fill, Rect2(inner.position, Vector2(w, inner.size.y)), false)
