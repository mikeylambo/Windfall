extends Area2D
class_name BedProp

## The farmhouse door. After the night raid is cleared, rest here to sleep
## through to the next morning (autosaves).

@export var day_manager: DayCycleManager
var is_focused: bool = false


func _ready() -> void:
	monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 36)
	col.shape = shape
	add_child(col)


func get_prompt() -> String:
	if day_manager and day_manager.current_phase == WindfallTypes.TimeOfDay.NIGHT_RAID and not day_manager.is_raid_active:
		return "Sleep until morning"
	return "Farmhouse"


func interact(_player: RootbornPlayer) -> void:
	if day_manager == null:
		return
	if day_manager.current_phase != WindfallTypes.TimeOfDay.NIGHT_RAID:
		HUDBus.toast("Too early to sleep. The east gate leads to the wilds.", WPal.CREAM[3])
		return
	if day_manager.is_raid_active:
		HUDBus.toast("Not while poachers are in the orchard!", WPal.RED[4])
		return
	WindfallSound.play_harvest()
	HUDBus.sleep_transition(func(): day_manager.advance_phase())


func set_focused(val: bool) -> void:
	is_focused = val
