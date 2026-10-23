extends Node

signal quest_accepted(quest: QuestData)
signal quest_objective_updated(quest: QuestData, objective_idx: int)
signal quest_completed(quest: QuestData)

var active_quests: Array[QuestData] = []
var completed_quests: Array[StringName] = []


func accept_quest(quest: QuestData) -> void:
	if quest == null or is_quest_active(quest.quest_id) or is_quest_completed(quest.quest_id):
		return
	active_quests.append(quest)
	quest_accepted.emit(quest)


func advance_quest(quest_id: StringName) -> void:
	for q in active_quests:
		if q.quest_id == quest_id:
			q.current_objective_idx += 1
			if q.current_objective_idx >= q.objectives.size():
				complete_quest(quest_id)
			else:
				quest_objective_updated.emit(q, q.current_objective_idx)
			break


func complete_quest(quest_id: StringName) -> void:
	for i in range(active_quests.size()):
		if active_quests[i].quest_id == quest_id:
			var q := active_quests[i]
			active_quests.remove_at(i)
			completed_quests.append(quest_id)
			quest_completed.emit(q)
			break


func is_quest_active(quest_id: StringName) -> bool:
	for q in active_quests:
		if q.quest_id == quest_id: return true
	return false


func is_quest_completed(quest_id: StringName) -> bool:
	return completed_quests.has(quest_id)
