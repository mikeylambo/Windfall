extends PlayerInput
class_name NetworkInput

## Seam for online co-op. A remote peer serialises its local PlayerInput with
## to_intent() each tick; the host feeds those dictionaries in here and the
## remote player's RootbornPlayer runs exactly as a local one would.
## Transport (ENet/WebRTC via MultiplayerAPI) is intentionally not built yet.

var _queue: Array[Dictionary] = []


func _init() -> void:
	super(-1, false)


func push_intent(d: Dictionary) -> void:
	_queue.append(d)


func poll() -> void:
	if _queue.is_empty():
		pressed.clear()
		return
	apply_intent(_queue.pop_front())
