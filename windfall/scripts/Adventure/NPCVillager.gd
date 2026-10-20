extends Interactable2D
class_name NPCVillager

@export var villager_name: String = "Elder Rowan"
@export var quest_to_give: QuestData

var _dialogue: DialogueData


func _ready() -> void:
	super._ready()
	prompt_text = "Talk to " + villager_name
	_dialogue = DialogueData.new()
	_dialogue.speaker_name = villager_name
	_dialogue.lines = [
		"Greetings, traveler! Dark shadows lurk in the ruins nearby.",
		"Would you be willing to recover the lost relic from the ancient chest?",
		"The key is said to be hidden around this very courtyard."
	]
	_dialogue.choices = ["I'll help you!", "Maybe later."]


func _on_interacted(_player: Node2D) -> void:
	var dm := get_node_or_null("/root/DialogueManager")
	if dm != null:
		dm.call("start_dialogue", _dialogue)
		var callable: Callable
		callable = func(choice_idx: int):
			if choice_idx == 0:
				var qm := get_node_or_null("/root/QuestManager")
				if qm != null and quest_to_give != null:
					qm.call("accept_quest", quest_to_give)
			dm.dialogue_finished.disconnect(callable)
		dm.dialogue_finished.connect(callable)


func _draw() -> void:
	super._draw()
	# Draw simple stylized NPC
	draw_circle(Vector2.ZERO, 14.0, Color(0.4, 0.8, 0.5))
	draw_circle(Vector2(0, -6), 8.0, Color(0.95, 0.8, 0.7))
	draw_circle(Vector2(-3, -7), 2.0, Color.BLACK)
	draw_circle(Vector2(3, -7), 2.0, Color.BLACK)
