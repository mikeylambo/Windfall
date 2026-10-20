extends CharacterBody2D
class_name VillagerCompanion2D

signal spoken(villager: VillagerCompanion2D)

@export var villager_name: String = "Wren"
@export var village_job: String = "Watch"
@export var combat_role: String = "Rogue"
@export var loved_flavor: String = "Sour"
@export var hated_flavor: String = "Sweet"

var is_in_party: bool = false
var target_enemy: Node2D = null
var current_health: float = 90.0
var max_health: float = 90.0
var _attack_cd: float = 0.0
var _anim_time: float = 0.0

@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null


func _ready() -> void:
	add_to_group("allies")
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		add_child(col)

	if interaction_area == null:
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		var id_col := CollisionShape2D.new()
		var id_shape := CircleShape2D.new()
		id_shape.radius = 28.0
		id_col.shape = id_shape
		interaction_area.add_child(id_col)
		add_child(interaction_area)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _attack_cd > 0.0:
		_attack_cd -= delta

	if is_in_party:
		_process_party_follow_and_combat(delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	queue_redraw()


func _process_party_follow_and_combat(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: RootbornPlayer = players[0]

	# Check for nearby enemies to attack
	var enemies := get_tree().get_nodes_in_group("enemies")
	target_enemy = null
	var min_dist := 180.0

	for enemy in enemies:
		if enemy is Node2D:
			var d := global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				target_enemy = enemy

	if target_enemy != null:
		var to_enemy := (target_enemy.global_position - global_position).normalized()
		velocity = to_enemy * 140.0
		if min_dist <= 32.0 and _attack_cd <= 0.0:
			_attack_cd = 1.0
			if target_enemy.has_method("take_damage"):
				target_enemy.call("take_damage", 24.0)
				WindfallSound.play_swing()
	else:
		# Follow player
		var dist_to_player := global_position.distance_to(player.global_position)
		if dist_to_player > 50.0:
			var to_player := (player.global_position - global_position).normalized()
			velocity = to_player * 160.0
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)

	move_and_slide()


func interact(player: RootbornPlayer) -> void:
	is_in_party = not is_in_party
	var msg := "%s joined your party!" % villager_name if is_in_party else "%s returned to home duty." % villager_name
	WindfallSound.play_harvest()
	spoken.emit(self)


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(0, 6), 9.0, Color(0, 0, 0, 0.25))

	# Villager clothes & look
	var clothes_col := Color(0.3, 0.45, 0.6) # Wren blue rogue
	if villager_name == "Hesper": clothes_col = Color(0.8, 0.65, 0.2) # Beekeeper yellow
	elif villager_name == "Brick": clothes_col = Color(0.5, 0.25, 0.2) # Blacksmith brown

	draw_circle(Vector2.ZERO, 11.0, clothes_col)
	draw_circle(Vector2(0, -5), 6.5, Color(0.9, 0.75, 0.6)) # Face

	# Party follower indicator
	if is_in_party:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 16, Color(0.4, 0.9, 0.4), 2.0)
