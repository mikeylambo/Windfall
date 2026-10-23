extends Node

signal action_selected(user: Node, target: Node, ability: Resource)

@export var controlled_unit: Node
@export var default_ability: Resource


func choose_target(candidates: Array[Node]) -> Node:
	for candidate in candidates:
		if is_instance_valid(candidate) and candidate.has_method("is_alive") and candidate.is_alive() and candidate != controlled_unit:
			return candidate
	return null


func choose_ability(_target: Node) -> Resource:
	return default_ability


func take_turn(candidates: Array[Node]) -> void:
	if not is_instance_valid(controlled_unit) or not controlled_unit.has_method("is_alive") or not controlled_unit.is_alive():
		return

	var target := choose_target(candidates)
	var ability := choose_ability(target)
	if ability == null or target == null:
		return

	if ability.has_method("use"):
		ability.use(controlled_unit, target)
	action_selected.emit(controlled_unit, target, ability)
