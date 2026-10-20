extends CanvasLayer
class_name QuestTrackerHUD

@onready var quest_title: Label = $MarginContainer/VBoxContainer/Title
@onready var objective_label: Label = $MarginContainer/VBoxContainer/Objective

var _mgr: Node = null


func _ready() -> void:
	_mgr = get_node_or_null("/root/QuestManager")
	if _mgr != null:
		_mgr.quest_accepted.connect(_on_quest_updated)
		_mgr.quest_objective_updated.connect(func(q, _idx): _on_quest_updated(q))
		_mgr.quest_completed.connect(_on_quest_completed)
	_update_display(null)


func _on_quest_updated(q: QuestData) -> void:
	_update_display(q)


func _on_quest_completed(_q: QuestData) -> void:
	_update_display(null)


func _update_display(q: QuestData) -> void:
	if q == null:
		quest_title.text = "Quests: None active"
		objective_label.text = "Explore the village"
	else:
		quest_title.text = "Quest: " + q.title
		if q.current_objective_idx < q.objectives.size():
			objective_label.text = "• " + q.objectives[q.current_objective_idx]
		else:
			objective_label.text = "• Complete!"
