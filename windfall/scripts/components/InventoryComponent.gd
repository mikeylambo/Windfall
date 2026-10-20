extends Node
class_name InventoryComponent

signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)
signal inventory_changed

@export var max_slots: int = 32

var items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false

	if not items.has(item_id):
		if items.size() >= max_slots:
			return false
		items[item_id] = 0

	items[item_id] = int(items[item_id]) + amount
	item_added.emit(item_id, amount)
	inventory_changed.emit()
	return true


func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false
	if not has_item(item_id, amount):
		return false

	items[item_id] = int(items[item_id]) - amount
	if int(items[item_id]) <= 0:
		items.erase(item_id)

	item_removed.emit(item_id, amount)
	inventory_changed.emit()
	return true


func has_item(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false
	return get_item_count(item_id) >= amount


func get_item_count(item_id: StringName) -> int:
	return int(items.get(item_id, 0))


func clear_inventory() -> void:
	if items.is_empty():
		return

	items.clear()
	inventory_changed.emit()


func get_save_data() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"max_slots": max_slots
	}


func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var saved_max_slots: Variant = data.get("max_slots", max_slots)
	if saved_max_slots is int or saved_max_slots is float:
		max_slots = max(int(saved_max_slots), 0)

	items.clear()
	var saved_items: Variant = data.get("items", {})
	if saved_items is Dictionary:
		for item_key in saved_items.keys():
			var item_id := StringName(item_key)
			var amount := int(saved_items[item_key])
			if item_id == &"" or amount <= 0:
				continue
			if items.size() >= max_slots:
				break
			items[item_id] = amount

	inventory_changed.emit()
