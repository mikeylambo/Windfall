extends Node2D
class_name ExpeditionZone

signal returned_to_orchard

@export var region_name: String = "Homestead Vale Wilds"
@export var regional_family: int = WindfallTypes.Family.VERDANT

# Wild planting spots where player planted trees in the world
var wild_planted_trees: Dictionary = {} # Vector2i -> planted_species_id


func _ready() -> void:
	add_to_group("expedition_zone")
	_setup_wild_trees()


func _setup_wild_trees() -> void:
	# Spawn forageable wild fruit trees across the zone
	var tree_coords := [
		{"pos": Vector2(300, 250), "species": &"voltberry"},
		{"pos": Vector2(650, 180), "species": &"cinderapple"},
		{"pos": Vector2(850, 420), "species": &"rimepear"},
		{"pos": Vector2(250, 550), "species": &"briarcherry"},
		{"pos": Vector2(750, 680), "species": &"zephyr_kiwi"},
		{"pos": Vector2(450, 850), "species": &"brinemelon"}
	]

	for data in tree_coords:
		_create_wild_tree(data["pos"], data["species"])


func _create_wild_tree(pos: Vector2, species_id: StringName) -> void:
	var plot := OrchardPlot2D.new()
	plot.position = pos
	plot.tree_stage = WindfallTypes.TreeStage.MATURE
	plot.planted_species_id = species_id
	plot.fruit_count = 3
	plot.current_ripeness = WindfallTypes.Ripeness.RIPE
	plot.is_wild = true
	plot.add_to_group("wild_trees")
	add_child(plot)
