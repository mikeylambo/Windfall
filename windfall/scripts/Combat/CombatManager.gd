extends Node

signal damage_dealt(source: Object, target: Object, amount: float)
signal healing_done(source: Object, target: Object, amount: float)
signal unit_defeated(unit: Object, source: Object)
signal effect_applied(source: Object, target: Object, effect: Resource)


func deal_damage(source: Object, target: Object, amount: float) -> void:
	if not is_valid_target(target):
		return

	var safe_amount := maxf(amount, 0.0)

	if target.has_method("take_damage"):
		target.call("take_damage", safe_amount)

	damage_dealt.emit(source, target, safe_amount)
	var event_bus_damage := get_node_or_null("/root/EventBus")
	if event_bus_damage != null and event_bus_damage.has_method("emit_damage_dealt"):
		event_bus_damage.call("emit_damage_dealt", source, target, safe_amount)

	if target.has_method("is_alive") and not bool(target.call("is_alive")):
		unit_defeated.emit(target, source)
		var event_bus_defeat := get_node_or_null("/root/EventBus")
		if event_bus_defeat != null and event_bus_defeat.has_method("emit_unit_defeated"):
			event_bus_defeat.call("emit_unit_defeated", target, source)


func heal(source: Object, target: Object, amount: float) -> void:
	if not is_valid_target(target):
		return

	var safe_amount := maxf(amount, 0.0)

	if target.has_method("heal"):
		target.call("heal", safe_amount)

	healing_done.emit(source, target, safe_amount)
	var event_bus_healing := get_node_or_null("/root/EventBus")
	if event_bus_healing != null and event_bus_healing.has_method("emit_healing_done"):
		event_bus_healing.call("emit_healing_done", source, target, safe_amount)


func apply_effect(source: Object, target: Object, effect: Resource) -> void:
	if not is_valid_target(target) or effect == null or not is_instance_valid(effect):
		return

	var controller := _get_status_effect_controller(target)

	if controller == null or not controller.has_method("add_effect"):
		return

	controller.call("add_effect", effect)
	effect_applied.emit(source, target, effect)
	var event_bus_effect := get_node_or_null("/root/EventBus")
	if event_bus_effect != null and event_bus_effect.has_method("emit_effect_applied"):
		event_bus_effect.call("emit_effect_applied", source, target, effect)


func is_valid_target(target: Object) -> bool:
	return target != null and is_instance_valid(target)



func _get_status_effect_controller(target: Object) -> Node:
	if target is Node:
		return (target as Node).get_node_or_null("StatusEffectController")

	return null
