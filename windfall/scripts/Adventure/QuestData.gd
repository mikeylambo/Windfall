extends Resource
class_name QuestData

@export var quest_id: StringName
@export var title: String = "New Quest"
@export var description: String = ""
@export var objectives: Array[String] = []
@export var current_objective_idx: int = 0
@export var reward_gold: int = 50
@export var reward_item_id: StringName = &""
