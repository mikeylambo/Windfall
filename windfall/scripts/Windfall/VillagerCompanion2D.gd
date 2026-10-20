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
var body_sprite: Sprite2D
var _bubble: Sprite2D
var _home: Vector2
var _wander_target: Vector2
var _wander_wait: float = 1.0
var is_focused: bool = false
var _talks: int = 0

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
	_home = global_position
	_wander_target = _home
	add_child(Art.shadow("small"))
	body_sprite = Art.actor_sprite(villager_name.to_lower())
	add_child(body_sprite)
	_bubble = Art.sprite("ui/bubble")
	_bubble.position = Vector2(0, -58)
	_bubble.z_index = 30
	_bubble.visible = false
	add_child(_bubble)
	var dots := Label.new()
	dots.text = "!"
	dots.add_theme_font_override("font", load("res://assets/fonts/PixelifySans-Bold.woff2"))
	dots.add_theme_font_size_override("font_size", 16)
	dots.add_theme_color_override("font_color", WPal.OUTLINE)
	dots.size = Vector2(36, 24)
	dots.position = Vector2(-18, -28)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.add_child(dots)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _attack_cd > 0.0:
		_attack_cd -= delta

	if is_in_party:
		_process_party_follow_and_combat(delta)
	else:
		_wander(delta)
	_update_visuals()


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


func _wander(delta: float) -> void:
	_wander_wait -= delta
	if global_position.distance_to(_wander_target) < 6.0 or _wander_wait < -4.0:
		velocity = Vector2.ZERO
		if _wander_wait <= 0.0:
			_wander_wait = randf_range(1.5, 4.0)
			_wander_target = _home + Vector2(randf_range(-60, 60), randf_range(-30, 30))
	elif _wander_wait <= 0.0:
		velocity = (_wander_target - global_position).normalized() * 45.0
	if is_focused:
		velocity = Vector2.ZERO
	move_and_slide()


func _update_visuals() -> void:
	var dir := 0
	var face := velocity
	if is_focused:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			face = (players[0] as Node2D).global_position - global_position
	if absf(face.x) > absf(face.y) * 1.1: dir = 2
	elif face.y < -1.0: dir = 1
	var moving := velocity.length() > 10.0
	var anim := "walk" if moving else "idle"
	var fps := 8.0 if moving else 2.0
	body_sprite.frame = (Art.ROWS[anim] + dir) * 4 + int(_anim_time * fps) % Art.ROW_FRAMES[anim]
	body_sprite.flip_h = dir == 2 and face.x < 0.0
	_bubble.visible = is_focused
	if is_focused:
		_bubble.position.y = -58 + sin(_anim_time * 5.0) * 2.0
	var mat := body_sprite.material as ShaderMaterial
	mat.set_shader_parameter("rim_count", 1 if is_in_party else 0)
	mat.set_shader_parameter("rim_a", WPal.LEAF[4])
	mat.set_shader_parameter("rim_strength", 0.5 if is_in_party else 0.0)


func get_prompt() -> String:
	return "Talk to %s" % villager_name


func set_focused(val: bool) -> void:
	is_focused = val


const LINES := {
	"Wren": [
		["Poachers move after dusk. I watch the treeline so you don't have to.", "Want my blades at your back?"],
		["Sour fruit keeps me sharp. Sweet stuff? Keep it.", "Say the word and I'll ride along."],
	],
	"Hesper": [
		["My bees adore an orchard in bloom. Plant two families side by side in spring and watch what grows.", "Shall I come along and tend you?"],
		["Hybrids sprout where the pollen mingles. Sweet fruit makes the best honey!", "I can follow if you need mending."],
	],
}


func interact(_player: RootbornPlayer) -> void:
	var pool: Array = LINES.get(villager_name, [["Lovely day for the orchard."]])
	var lines: Array = pool[_talks % pool.size()].duplicate()
	_talks += 1
	var joining := not is_in_party
	lines.append("%s joined your party!" % villager_name if joining else "%s heads back to home duty." % villager_name)
	HUDBus.say(villager_name, lines, func():
		is_in_party = joining
		WindfallSound.play_harvest()
		spoken.emit(self))
