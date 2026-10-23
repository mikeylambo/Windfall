extends Resource

signal used(user: Object, target: Object)

@export var ability_id: StringName = &"ability"
@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export_range(0.0, 9999.0, 0.01, "or_greater") var cooldown: float = 0.0
@export var power: float = 0.0
@export_range(0.0, 999999.0, 0.1, "or_greater") var range: float = 0.0
@export var tags: Array[StringName] = []


func can_use(user: Object, _target: Object) -> bool:
	if user == null or not is_instance_valid(user):
		return false

	if user.has_method("is_alive"):
		return bool(user.call("is_alive"))

	return true


func use(user: Object, target: Object) -> void:
	if not can_use(user, target):
		return

	# Safe placeholder: derived abilities can override this to apply effects.
	used.emit(user, target)
