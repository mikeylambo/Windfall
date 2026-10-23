extends Resource

@export var item_id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var tags: Array[StringName] = []
