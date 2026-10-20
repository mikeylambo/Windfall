extends Area2D
class_name ExpeditionGate

## The east gate drives the day: Morning -> set out on Expedition,
## Expedition -> return home at dusk and the Night Raid begins.

@export var day_manager: DayCycleManager
var is_focused: bool = false


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 70)
	col.shape = shape
	col.position = Vector2(0, -10)
	add_child(col)


func get_prompt() -> String:
	if day_manager == null:
		return ""
	match day_manager.current_phase:
		WindfallTypes.TimeOfDay.MORNING:
			return "Set out on Expedition"
		WindfallTypes.TimeOfDay.EXPEDITION:
			return "Return home at dusk"
	return "Defend the orchard!" if day_manager.is_raid_active else "Rest at the farmhouse"


func interact(_player: RootbornPlayer) -> void:
	if day_manager == null:
		return
	match day_manager.current_phase:
		WindfallTypes.TimeOfDay.MORNING, WindfallTypes.TimeOfDay.EXPEDITION:
			day_manager.advance_phase()
		_:
			HUDBus.toast(get_prompt(), WPal.CREAM[3])


func set_focused(val: bool) -> void:
	is_focused = val
