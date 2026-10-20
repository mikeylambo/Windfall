extends CharacterBody2D
class_name AdventurePlayer2D

signal player_dashed
signal player_attacked
signal player_interacted

@export var move_speed: float = 160.0
@export var roll_speed: float = 340.0
@export var roll_duration: float = 0.22
@export var roll_cooldown: float = 0.45
@export var roll_energy_cost: float = 20.0

@export var attack_damage: float = 25.0
@export var attack_duration: float = 0.18
@export var attack_cooldown: float = 0.35
@export var attack_knockback: float = 240.0

var facing_direction: Vector2 = Vector2.DOWN
var is_rolling: bool = false
var is_attacking: bool = false
var is_invulnerable: bool = false

var _roll_timer: float = 0.0
var _roll_cd_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cd_timer: float = 0.0

var _current_interactable: Interactable2D = null

@onready var stats: StatsComponent = $StatsComponent if has_node("StatsComponent") else null
@onready var inventory: InventoryComponent = $InventoryComponent if has_node("InventoryComponent") else null
@onready var interaction_detector: Area2D = $InteractionDetector if has_node("InteractionDetector") else null
@onready var sword_hitbox: Area2D = $SwordHitbox if has_node("SwordHitbox") else null


func _ready() -> void:
	add_to_group("player")
	if interaction_detector != null:
		interaction_detector.area_entered.connect(_on_interact_area_entered)
		interaction_detector.area_exited.connect(_on_interact_area_exited)
	if sword_hitbox != null:
		sword_hitbox.monitoring = false
		sword_hitbox.body_entered.connect(_on_sword_hit_body)
		sword_hitbox.area_entered.connect(_on_sword_hit_area)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if is_rolling:
		velocity = facing_direction * roll_speed
		move_and_slide()
		return

	if is_attacking:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec != Vector2.ZERO:
		facing_direction = input_vec.normalized()
		velocity = input_vec * move_speed
		_update_interaction_detector_pos()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)

	move_and_slide()
	_handle_input()
	queue_redraw()


func _handle_input() -> void:
	if Input.is_action_just_pressed("interact"):
		if _current_interactable != null and is_instance_valid(_current_interactable):
			_current_interactable.interact(self)
			player_interacted.emit()

	if Input.is_action_just_pressed("dash") and _roll_cd_timer <= 0.0:
		_start_roll()

	if Input.is_action_just_pressed("attack") and _attack_cd_timer <= 0.0:
		_start_attack()


func _start_roll() -> void:
	if stats != null and stats.energy < roll_energy_cost:
		return
	if stats != null:
		stats.energy -= roll_energy_cost

	is_rolling = true
	is_invulnerable = true
	_roll_timer = roll_duration
	_roll_cd_timer = roll_cooldown
	player_dashed.emit()


func _start_attack() -> void:
	is_attacking = true
	_attack_timer = attack_duration
	_attack_cd_timer = attack_cooldown
	if sword_hitbox != null:
		sword_hitbox.position = facing_direction * 22.0
		sword_hitbox.rotation = facing_direction.angle()
		sword_hitbox.monitoring = true
	player_attacked.emit()


func _tick_timers(delta: float) -> void:
	if _roll_cd_timer > 0.0: _roll_cd_timer -= delta
	if _attack_cd_timer > 0.0: _attack_cd_timer -= delta

	if is_rolling:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			is_rolling = false
			is_invulnerable = false

	if is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			is_attacking = false
			if sword_hitbox != null:
				sword_hitbox.monitoring = false


func _update_interaction_detector_pos() -> void:
	if interaction_detector != null:
		interaction_detector.position = facing_direction * 20.0


func _on_interact_area_entered(area: Area2D) -> void:
	if area is Interactable2D:
		_current_interactable = area as Interactable2D
		_current_interactable.set_focused(true)


func _on_interact_area_exited(area: Area2D) -> void:
	if area == _current_interactable:
		_current_interactable.set_focused(false)
		_current_interactable = null


func _on_sword_hit_body(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", attack_damage)
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = facing_direction * attack_knockback


func _on_sword_hit_area(area: Area2D) -> void:
	var p := area.get_parent()
	if p != null and p.has_method("take_damage"):
		p.call("take_damage", attack_damage)


func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	if stats != null:
		stats.take_damage(amount)
	modulate = Color(1.8, 0.4, 0.4)
	await get_tree().create_timer(0.12).timeout
	modulate = Color.WHITE


func _draw() -> void:
	# Draw player circle + facing indicator
	var body_col := Color(0.2, 0.7, 0.9) if not is_rolling else Color(0.5, 0.9, 1.0, 0.6)
	draw_circle(Vector2.ZERO, 12.0, body_col)
	draw_circle(facing_direction * 8.0, 4.0, Color.WHITE)
	if is_attacking:
		# Draw sword slash arc
		var angle := facing_direction.angle()
		draw_arc(Vector2.ZERO, 26.0, angle - 0.7, angle + 0.7, 8, Color(1, 0.9, 0.4), 3.0)
