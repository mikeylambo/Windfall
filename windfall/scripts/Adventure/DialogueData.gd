extends Resource
class_name DialogueData

@export var dialogue_id: StringName
@export var speaker_name: String = "Villager"
@export var speaker_avatar: Texture2D
@export_multiline var lines: Array[String] = []
@export var choices: Array[String] = []
