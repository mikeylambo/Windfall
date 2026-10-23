extends Resource

signal applied(target: Object)
signal removed(target: Object)
signal ticked(target: Object)
signal expired(target: Object)

@export var effect_id: StringName = &"status_effect"
@export var display_name: String = "Status Effect"
@export_multiline var description: String = ""
@export_range(0.0, 999999.0, 0.01, "or_greater") var duration: float = 0.0
@export_range(0.0, 999999.0, 0.01, "or_greater") var tick_interval: float = 0.0
@export_range(1, 999, 1, "or_greater") var max_stacks: int = 1
@export var tags: Array[StringName] = []

var remaining_duration: float = 0.0
var stacks: int = 0

var _tick_elapsed: float = 0.0
var _expired_emitted: bool = false


func apply(target: Object) -> void:
	remaining_duration = maxf(duration, 0.0)
	stacks = maxi(stacks, 1)
	stacks = mini(stacks, maxi(max_stacks, 1))
	_tick_elapsed = 0.0
	_expired_emitted = false
	applied.emit(target)


func remove(target: Object) -> void:
	remaining_duration = 0.0
	stacks = 0
	_tick_elapsed = 0.0
	removed.emit(target)


func tick(target: Object, delta: float) -> void:
	if stacks <= 0:
		return

	var safe_delta := maxf(delta, 0.0)

	if duration > 0.0:
		remaining_duration = maxf(remaining_duration - safe_delta, 0.0)

	if tick_interval <= 0.0:
		ticked.emit(target)
	else:
		_tick_elapsed += safe_delta
		while _tick_elapsed >= tick_interval and not is_expired():
			_tick_elapsed -= tick_interval
			ticked.emit(target)

	if is_expired() and not _expired_emitted:
		_expired_emitted = true
		expired.emit(target)


func can_stack() -> bool:
	return stacks < maxi(max_stacks, 1)


func add_stack(amount: int = 1) -> void:
	if amount <= 0:
		return

	stacks = clampi(stacks + amount, 0, maxi(max_stacks, 1))


func is_expired() -> bool:
	return duration > 0.0 and remaining_duration <= 0.0
