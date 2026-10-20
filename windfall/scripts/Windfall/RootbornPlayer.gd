extends CharacterBody2D
class_name RootbornPlayer

signal stomach_changed
signal satchel_changed
signal bite_taken(fruit_data: Dictionary)
signal health_updated(current: float, max_val: float)
signal energy_updated(current: float, max_val: float)
signal tool_changed(tool_type: int)
signal quickroot_planted(species_id: StringName)
signal skill_cast(fruit_data: Dictionary)

@export var move_speed: float = 170.0
@export var roll_speed: float = 350.0
@export var roll_duration: float = 0.22
@export var roll_cooldown: float = 0.4
@export var max_health: float = 120.0
@export var max_energy: float = 100.0

var current_health: float = 120.0
var current_energy: float = 100.0

var facing_direction: Vector2 = Vector2.DOWN
var is_rolling: bool = false
var is_invulnerable: bool = false
var is_attacking: bool = false
var is_eating: bool = false

var _roll_timer: float = 0.0
var _roll_cd_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cd_timer: float = 0.0
var _skill_cooldowns: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0}

# Tool weapon
var current_tool: int = WindfallTypes.ToolType.PRUNING_SHEARS

# Stomach & Digestion
var max_stomach_slots: int = 4
var digesting_fruits: Array[Dictionary] = []
var active_pairings: Array[int] = []

# Satchel Inventory (carried provisions & seeds)
var satchel_fruits: Array[Dictionary] = []
var satchel_seeds: Dictionary = {} # species_id -> count
var selected_seed_id: StringName = &"voltberry"

# Mastery & Rooted skills
var mastery_xp: Dictionary = {} # species_id -> float (0 to 100)
var rooted_skills: Array[StringName] = [] # up to 4 permanent skills

# Visual & hitstop
var _anim_time: float = 0.0
var _hitstop_timer: float = 0.0
var _eating_timer: float = 0.0
var _damage_flash_timer: float = 0.0
var _aura_color: Color = Color.TRANSPARENT

# Presentation
const ACCEL := 1500.0
const DECEL := 1700.0
const DIR_DOWN := 0
const DIR_UP := 1
const DIR_SIDE := 2
var input_locked: bool = false
var tool_level: int = 1
var body_sprite: Sprite2D
var tool_sprite: Sprite2D
var _shadow: Sprite2D
var _anim: String = "idle"
var _anim_frame_time: float = 0.0
var _anim_dir: int = DIR_DOWN
var _cast_timer: float = 0.0
var _hurt_timer: float = 0.0
var _iframe_timer: float = 0.0
var _dust_timer: float = 0.0
var _ghost_timer: float = 0.0
var _aura_glow: Sprite2D
var _respawn_point: Vector2 = Vector2.ZERO

@onready var interaction_detector: Area2D = $InteractionDetector if has_node("InteractionDetector") else null
@onready var weapon_hitbox: Area2D = $WeaponHitbox if has_node("WeaponHitbox") else null
var _current_interactable = null


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	current_energy = max_energy

	_setup_collision()
	_setup_default_satchel()
	_setup_visuals()
	_respawn_point = global_position

	health_updated.emit(current_health, max_health)
	energy_updated.emit(current_energy, max_energy)
	stomach_changed.emit()
	satchel_changed.emit()


func _setup_collision() -> void:
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		add_child(col)

	if interaction_detector == null:
		interaction_detector = Area2D.new()
		interaction_detector.name = "InteractionDetector"
		var id_col := CollisionShape2D.new()
		var id_shape := CircleShape2D.new()
		id_shape.radius = 28.0
		id_col.shape = id_shape
		interaction_detector.add_child(id_col)
		add_child(interaction_detector)

	interaction_detector.area_entered.connect(_on_interact_area_entered)
	interaction_detector.area_exited.connect(_on_interact_area_exited)

	if weapon_hitbox == null:
		weapon_hitbox = Area2D.new()
		weapon_hitbox.name = "WeaponHitbox"
		var wh_col := CollisionShape2D.new()
		var wh_shape := CircleShape2D.new()
		wh_shape.radius = 24.0
		wh_col.shape = wh_shape
		weapon_hitbox.add_child(wh_col)
		add_child(weapon_hitbox)

	weapon_hitbox.monitoring = false
	weapon_hitbox.body_entered.connect(_on_weapon_hit_body)
	weapon_hitbox.area_entered.connect(_on_weapon_hit_area)


func _setup_default_satchel() -> void:
	# Provide starting fresh fruits and seeds
	satchel_fruits.append(FruitRegistry.create_fruit_instance(&"voltberry", WindfallTypes.Ripeness.RIPE))
	satchel_fruits.append(FruitRegistry.create_fruit_instance(&"cinderapple", WindfallTypes.Ripeness.RIPE))
	satchel_fruits.append(FruitRegistry.create_fruit_instance(&"rimepear", WindfallTypes.Ripeness.RIPE))
	satchel_fruits.append(FruitRegistry.create_fruit_instance(&"briarcherry", WindfallTypes.Ripeness.PRIME, ["Juicy"]))

	satchel_seeds[&"voltberry"] = 4
	satchel_seeds[&"cinderapple"] = 3
	satchel_seeds[&"rimepear"] = 3
	satchel_seeds[&"briarcherry"] = 3
	satchel_seeds[&"brinemelon"] = 2
	satchel_seeds[&"zephyr_kiwi"] = 2
	satchel_seeds[&"starfruit"] = 1


func _physics_process(delta: float) -> void:
	_anim_time += delta

	# Hitstop freeze frame
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		return

	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta

	if _eating_timer > 0.0:
		_eating_timer -= delta
		if _eating_timer <= 0.0:
			is_eating = false

	_tick_digestion(delta)
	_tick_cooldowns(delta)
	_tick_stamina(delta)

	if is_eating:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_rolling:
		velocity = facing_direction * roll_speed
		move_and_slide()
		# Motion fruit trail damage
		_check_motion_fruit_trail()
		return

	if is_attacking:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		return

	var input_vec := Vector2.ZERO
	if not input_locked:
		input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec != Vector2.ZERO:
		facing_direction = input_vec.normalized()
		velocity = velocity.move_toward(input_vec * move_speed, ACCEL * delta)
		interaction_detector.position = facing_direction * 22.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECEL * delta)

	move_and_slide()
	_refresh_interactable()
	if not input_locked:
		_handle_input()


func _handle_input() -> void:
	# Interaction
	if Input.is_action_just_pressed("interact"):
		if _current_interactable != null and is_instance_valid(_current_interactable):
			_current_interactable.interact(self)

	# Dash / Dodge
	if Input.is_action_just_pressed("dash") and _roll_cd_timer <= 0.0 and current_energy >= 15.0:
		_start_roll()

	# Tool Attack
	if Input.is_action_just_pressed("attack") and _attack_cd_timer <= 0.0:
		_start_tool_attack()

	# Tool cycle (Tab)
	if Input.is_action_just_pressed("cycle_tool"):
		current_tool = (current_tool + 1) % 5
		tool_changed.emit(current_tool)
		WindfallSound.play_swing()

	# Fruit Skills: Q (Skill 1), R (Skill 2), T (Skill 3)
	if Input.is_action_just_pressed("skill_1"):
		_cast_fruit_skill(0, 1)
	if Input.is_action_just_pressed("skill_2"):
		_cast_fruit_skill(1, 2)
	if Input.is_action_just_pressed("skill_3"):
		_cast_fruit_skill(2, 3)

	# Quickroot seed in combat (F)
	if Input.is_action_just_pressed("quickroot"):
		quickroot_seed()

	# Fast eat from satchel (Key 1, 2, 3)
	if Input.is_action_just_pressed("eat_1"):
		eat_satchel_fruit_at(0)
	elif Input.is_action_just_pressed("eat_2"):
		eat_satchel_fruit_at(1)
	elif Input.is_action_just_pressed("eat_3"):
		eat_satchel_fruit_at(2)


# ── Eating & Digestion System ──────────────────────────────────────────────────

func eat_fruit(fruit_data: Dictionary) -> bool:
	var needed_slots: int = int(fruit_data.get("slots", 1))
	var used_slots := get_used_stomach_slots()

	if used_slots + needed_slots > max_stomach_slots:
		return false

	is_eating = true
	_hitstop_timer = 0.09 # Satisfying hitstop freeze!

	var fam: int = int(fruit_data.get("family", WindfallTypes.Family.STORM))
	WindfallSound.play_bite(fam)

	var digesting_copy := fruit_data.duplicate(true)
	digesting_copy["remaining_duration"] = float(fruit_data.get("digestion_duration", 50.0))
	digesting_fruits.append(digesting_copy)

	# Add mastery progression
	var sid: StringName = fruit_data.get("species_id", &"voltberry")
	var m_gain: float = 12.0 * WindfallTypes.RIPENESS_MULTIPLIERS.get(fruit_data.get("ripeness", 2), 1.0)
	if "Twin" in fruit_data.get("traits", []):
		m_gain *= 2.0
	mastery_xp[sid] = minf(mastery_xp.get(sid, 0.0) + m_gain, 100.0)

	_update_pairings()
	_bite_feedback(fam)
	bite_taken.emit(fruit_data)
	stomach_changed.emit()

	_eating_timer = 0.32
	return true


func eat_satchel_fruit_at(index: int) -> bool:
	if index < 0 or index >= satchel_fruits.size():
		return false
	var fruit := satchel_fruits[index]
	if eat_fruit(fruit):
		satchel_fruits.remove_at(index)
		satchel_changed.emit()
		return true
	return false


func get_used_stomach_slots() -> int:
	var count := 0
	for f in digesting_fruits:
		count += int(f.get("slots", 1))
	return count


func _tick_digestion(delta: float) -> void:
	var changed := false
	var i := digesting_fruits.size() - 1
	while i >= 0:
		var f := digesting_fruits[i]
		var rem: float = float(f.get("remaining_duration", 0.0)) - delta
		f["remaining_duration"] = rem

		# Tick passive auras while digesting
		_tick_fruit_passive(f, delta)

		if rem <= 0.0:
			digesting_fruits.remove_at(i)
			changed = true
		i -= 1

	if changed:
		_update_pairings()
		stomach_changed.emit()


func _update_pairings() -> void:
	var families: Array = []
	for f in digesting_fruits:
		families.append(int(f.get("family", 0)))
	active_pairings = FruitRegistry.evaluate_pairings(families)

	# Update aura color to match primary digesting fruit
	if not digesting_fruits.is_empty():
		var primary_fam: int = int(digesting_fruits[0].get("family", 0))
		_aura_color = WindfallTypes.FAMILY_COLORS.get(primary_fam, Color.WHITE)
	else:
		_aura_color = Color.TRANSPARENT


func _tick_fruit_passive(fruit: Dictionary, delta: float) -> void:
	var sid: StringName = fruit.get("species_id", &"")
	var fam: int = int(fruit.get("family", 0))
	var mult: float = 1.0
	if WindfallTypes.PairingEffect.INDIGESTION in active_pairings:
		mult = 0.75

	# Mistlime: Continuous health regeneration
	if sid == &"mistlime":
		heal(6.0 * mult * delta)
	# Ashdate: Passive burning damage to nearby enemies
	elif sid == &"ashdate":
		var enemies := get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy is Node2D and global_position.distance_to(enemy.global_position) <= 65.0:
				if enemy.has_method("take_damage"):
					enemy.call("take_damage", 12.0 * mult * delta)


# ── Active Skills & Combat ─────────────────────────────────────────────────────

func _cast_fruit_skill(fruit_index: int, skill_slot: int) -> void:
	if _skill_cooldowns[skill_slot] > 0.0:
		return

	if fruit_index >= digesting_fruits.size():
		return

	var fruit := digesting_fruits[fruit_index]
	var sid: StringName = fruit.get("species_id", &"voltberry")
	var fam: int = int(fruit.get("family", WindfallTypes.Family.STORM))
	var stype: int = int(fruit.get("skill_type", WindfallTypes.SkillType.STRIKE))
	var dmg: float = float(fruit.get("base_damage", 30.0))
	var cd: float = float(fruit.get("cooldown", 1.5))

	# Slight accelerated digestion burn on cast
	fruit["remaining_duration"] = maxf(float(fruit.get("remaining_duration", 10.0)) - 0.75, 0.0)

	_skill_cooldowns[skill_slot] = cd
	WindfallSound.play_spell(fam)
	_cast_timer = 0.28
	FX.element_burst(fam, global_position + facing_direction * 16.0 + Vector2(0, -14), 0.7)
	FX.shake(0.12)
	EventBus.emit_ability_used(self, null, fruit.get("skill_name", ""))
	skill_cast.emit(fruit)

	# Execute specific skill logic
	_execute_skill(sid, fam, stype, dmg)


func _execute_skill(sid: StringName, fam: int, stype: int, dmg: float) -> void:
	match sid:
		&"voltberry":
			# Chain Lightning projectile
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg, fam, 480.0, 0.0, false, 4)
			get_parent().add_child(proj)
		&"thunderplum":
			# Concussive Thunderclap burst
			_burst_shockwave(dmg, 120.0, fam)
		&"cinderapple":
			# Fireball explosive projectile
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg, fam, 440.0, 50.0, false, 0)
			get_parent().add_child(proj)
		&"scorchpeach":
			# Sweeping flame wave
			for angle_offset in [-0.25, 0.0, 0.25]:
				var dir := facing_direction.rotated(angle_offset)
				var proj := ElementalProjectile.new()
				proj.position = global_position + dir * 18.0
				proj.setup(dir, dmg * 0.7, fam, 380.0, 0.0, true, 0)
				get_parent().add_child(proj)
		&"rimepear":
			# Ice Lance piercing projectile
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg, fam, 520.0, 0.0, true, 0)
			get_parent().add_child(proj)
		&"snowquince":
			# Blizzard Field burst
			_burst_shockwave(dmg, 140.0, fam)
		&"brinemelon":
			# Tidal Push wave
			_burst_shockwave(dmg, 100.0, fam, 350.0)
		&"briarcherry":
			# Root Snare
			_burst_shockwave(dmg, 85.0, fam)
		&"starfruit":
			# Light Beam piercing beam
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg * 1.2, fam, 650.0, 0.0, true, 0)
			get_parent().add_child(proj)
		&"plasma_plum":
			# Arc Flame hybrid: Chain lightning + fire explosion
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg, fam, 500.0, 60.0, false, 5)
			get_parent().add_child(proj)
		_:
			# Default: launch elemental projectile
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, dmg, fam, 440.0, 0.0, false, 0)
			get_parent().add_child(proj)


func _burst_shockwave(dmg: float, radius: float, fam: int, knockback: float = 240.0) -> void:
	FX.ring(global_position, WPal.element(fam, 3), radius, 0.4)
	FX.element_burst(fam, global_position, 1.3)
	FX.shake(0.3)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.call("take_damage", dmg)
			if enemy is CharacterBody2D:
				var away: Vector2 = (enemy.global_position - global_position).normalized()
				if enemy.has_method("knockback"):
					enemy.call("knockback", away * knockback)
				else:
					(enemy as CharacterBody2D).velocity = away * knockback


func _check_motion_fruit_trail() -> void:
	for f in digesting_fruits:
		var sid: StringName = f.get("species_id", &"")
		if sid == &"sparkfig":
			# Static dash shock nearby foes
			var enemies := get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if enemy is Node2D and global_position.distance_to(enemy.global_position) <= 35.0:
					if enemy.has_method("take_damage"):
						enemy.call("take_damage", 18.0)


# ── Tool Attacks ───────────────────────────────────────────────────────────────

func _start_tool_attack() -> void:
	is_attacking = true
	_attack_timer = 0.18
	_attack_cd_timer = 0.32
	WindfallSound.play_swing()
	_anim_frame_time = 0.0
	_play_swing_fx()

	match current_tool:
		WindfallTypes.ToolType.PRUNING_SHEARS:
			# Fast twin blades
			_attack_timer = 0.14
			_attack_cd_timer = 0.22
			_position_weapon_hitbox(24.0, 18.0)
		WindfallTypes.ToolType.SCYTHE:
			# Wide sweeping arc
			_attack_timer = 0.22
			_attack_cd_timer = 0.4
			_position_weapon_hitbox(36.0, 32.0)
		WindfallTypes.ToolType.HOE_STAFF:
			# Heavy ground slam
			_attack_timer = 0.25
			_attack_cd_timer = 0.48
			_position_weapon_hitbox(28.0, 26.0)
			_burst_shockwave(35.0, 70.0, WindfallTypes.Family.VERDANT, 280.0)
		WindfallTypes.ToolType.SEED_SLING:
			# Sling ranged seed pellet
			var proj := ElementalProjectile.new()
			proj.position = global_position + facing_direction * 18.0
			proj.setup(facing_direction, 22.0, WindfallTypes.Family.VERDANT, 480.0, 0.0, false, 0)
			get_parent().add_child(proj)
		WindfallTypes.ToolType.WATERING_CAN:
			# Spray water cone to wet enemies & douse
			_spray_water_cone()


func _position_weapon_hitbox(offset_dist: float, radius: float) -> void:
	weapon_hitbox.position = facing_direction * offset_dist
	weapon_hitbox.rotation = facing_direction.angle()
	var col := weapon_hitbox.get_child(0) as CollisionShape2D
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = radius
	weapon_hitbox.monitoring = true


func _spray_water_cone() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D:
			var to_enemy: Vector2 = enemy.global_position - global_position
			if to_enemy.length() <= 85.0 and facing_direction.dot(to_enemy.normalized()) > 0.5:
				if enemy.has_method("apply_status"):
					enemy.call("apply_status", "wet", 6.0)
				if enemy.has_method("take_damage"):
					enemy.call("take_damage", 12.0)
	WindfallSound.play_spell(WindfallTypes.Family.TIDE)


func _on_weapon_hit_body(body: Node2D) -> void:
	if body == self or body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		var dmg := 28.0
		if current_tool == WindfallTypes.ToolType.SCYTHE: dmg = 36.0
		elif current_tool == WindfallTypes.ToolType.HOE_STAFF: dmg = 44.0
		dmg *= 1.0 + (tool_level - 1) * 0.2
		var crit := randf() < 0.12
		if crit:
			dmg *= 1.75
		if body.has_method("set_next_hit_crit"):
			body.call("set_next_hit_crit", crit)
		body.call("take_damage", dmg)
		EventBus.emit_damage_dealt(self, body, dmg)
		WindfallSound.play_hit()
		FX.hitstop(0.05 if not crit else 0.09)
		FX.shake(0.18 if not crit else 0.35)
	if body.has_method("knockback"):
		body.call("knockback", facing_direction * 240.0)


func _on_weapon_hit_area(area: Area2D) -> void:
	var p := area.get_parent()
	if p != null and not p.is_in_group("player") and p.has_method("take_damage"):
		p.call("take_damage", 25.0)


# ── Quickroot (Combat Gardening) ───────────────────────────────────────────────

func quickroot_seed() -> bool:
	if satchel_seeds.get(selected_seed_id, 0) <= 0:
		# Fall back to any available seed
		for sid in satchel_seeds.keys():
			if satchel_seeds[sid] > 0:
				selected_seed_id = sid
				break

	if satchel_seeds.get(selected_seed_id, 0) <= 0:
		return false

	satchel_seeds[selected_seed_id] -= 1
	satchel_changed.emit()

	var sp := FruitRegistry.get_species(selected_seed_id)
	var fam: int = int(sp.get("family", WindfallTypes.Family.STORM))

	var sprout := QuickrootSprout.new()
	sprout.position = global_position + facing_direction * 32.0
	sprout.setup(selected_seed_id, fam, 32.0, 14.0)
	get_parent().add_child(sprout)

	WindfallSound.play_plant()
	quickroot_planted.emit(selected_seed_id)
	return true


# ── Health, Damage & Stamina ───────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	# Thorn armor reflection check
	for f in digesting_fruits:
		if f.get("species_id") == &"bramblequince":
			amount *= 0.65
		elif f.get("species_id") == &"coral_fig":
			# Absorbs first hit
			amount = 0.0
			f["remaining_duration"] = 0.0 # Popped bubble
			break

	if amount <= 0.0:
		FX.popup("BLOCKED", global_position + Vector2(0, -40), WPal.element(WindfallTypes.Family.TIDE, 3), 13)
		return
	current_health = maxf(current_health - amount, 0.0)
	health_updated.emit(current_health, max_health)

	_damage_flash_timer = 0.14
	_hurt_timer = 0.25
	_iframe_timer = 0.5
	is_invulnerable = true
	FX.popup("-%d" % int(round(amount)), global_position + Vector2(0, -44), WPal.RED[4], 15)
	FX.shake(0.35)
	FX.hitstop(0.06)
	WindfallSound.play_hurt()

	if current_health <= 0.0:
		_die()


func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	health_updated.emit(current_health, max_health)


func _die() -> void:
	# Phoenix Pomegranate check (Rekindle)
	for i in digesting_fruits.size():
		if digesting_fruits[i].get("species_id") == &"phoenix_pomegranate":
			digesting_fruits.remove_at(i)
			current_health = max_health * 0.7
			health_updated.emit(current_health, max_health)
			WindfallSound.play_spell(WindfallTypes.Family.EMBER)
			_burst_shockwave(60.0, 150.0, WindfallTypes.Family.EMBER)
			return

	# Handle normal death: wilt, then regrow at the farmhouse door
	FX.poof(global_position, WPal.LEAF[4])
	FX.element_burst(WindfallTypes.Family.VERDANT, global_position, 1.5)
	FX.popup("WILTED...", global_position + Vector2(0, -50), WPal.CREAM[3], 18)
	current_health = max_health
	health_updated.emit(current_health, max_health)
	global_position = _respawn_point


func _start_roll() -> void:
	current_energy -= 18.0
	energy_updated.emit(current_energy, max_energy)
	is_rolling = true
	is_invulnerable = true
	_roll_timer = roll_duration
	_anim_frame_time = 0.0
	FX.dust(global_position, 6)
	WindfallSound.play_roll()
	_roll_cd_timer = roll_cooldown


func _tick_cooldowns(delta: float) -> void:
	if _roll_cd_timer > 0.0: _roll_cd_timer -= delta
	if _attack_cd_timer > 0.0: _attack_cd_timer -= delta
	for k in _skill_cooldowns.keys():
		if _skill_cooldowns[k] > 0.0:
			_skill_cooldowns[k] -= delta

	if is_rolling:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			is_rolling = false
			is_invulnerable = _iframe_timer > 0.0
			FX.dust(global_position, 3)

	if is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			is_attacking = false
			weapon_hitbox.monitoring = false


func _tick_stamina(delta: float) -> void:
	if not is_rolling and current_energy < max_energy:
		current_energy = minf(current_energy + 25.0 * delta, max_energy)
		energy_updated.emit(current_energy, max_energy)


func _on_interact_area_entered(_area: Area2D) -> void:
	pass


func _on_interact_area_exited(_area: Area2D) -> void:
	pass


## Focus the nearest interactable in reach (more forgiving than "last entered").
func _refresh_interactable() -> void:
	var best: Node = null
	var best_d := INF
	for a in interaction_detector.get_overlapping_areas():
		if a.has_method("interact") and a.visible:
			var d: float = (a as Node2D).global_position.distance_to(interaction_detector.global_position)
			if d < best_d:
				best_d = d
				best = a
	for b in interaction_detector.get_overlapping_bodies():
		if b != self and b.has_method("interact"):
			var d2: float = (b as Node2D).global_position.distance_to(interaction_detector.global_position)
			if d2 < best_d:
				best_d = d2
				best = b
	if best != _current_interactable:
		if _current_interactable != null and is_instance_valid(_current_interactable) and _current_interactable.has_method("set_focused"):
			_current_interactable.call("set_focused", false)
		_current_interactable = best
		if best != null and best.has_method("set_focused"):
			best.call("set_focused", true)


func get_interactable() -> Node:
	return _current_interactable


# ── Presentation ───────────────────────────────────────────────────────────

func _setup_visuals() -> void:
	add_to_group("saveable_player")
	_shadow = Art.shadow("small")
	add_child(_shadow)
	body_sprite = Art.actor_sprite("rootborn")
	add_child(body_sprite)
	tool_sprite = Sprite2D.new()
	tool_sprite.texture = Art.tex("icons/tool_0")
	tool_sprite.scale = Vector2.ONE * (2.0 / 3.0)
	tool_sprite.offset = Vector2(12, -12)
	add_child(tool_sprite)
	tool_changed.connect(func(t): tool_sprite.texture = Art.tex("icons/tool_%d" % t))
	stomach_changed.connect(_refresh_aura)
	call_deferred("_late_visuals")


func _late_visuals() -> void:
	_aura_glow = FX.glow(self, Color.WHITE, 46.0, Vector2(0, -16), 0.35, 0.0)
	_refresh_aura()


func _refresh_aura() -> void:
	var mat := body_sprite.material as ShaderMaterial
	var n := mini(digesting_fruits.size(), 3)
	mat.set_shader_parameter("rim_count", n)
	mat.set_shader_parameter("rim_strength", 0.85 if n > 0 else 0.0)
	var keys := ["rim_a", "rim_b", "rim_c"]
	for i in n:
		mat.set_shader_parameter(keys[i], WPal.element(int(digesting_fruits[i].get("family", 0)), 3))
	if _aura_glow:
		_aura_glow.modulate = _aura_color if n > 0 else Color(0, 0, 0, 0)
		FX.set_glow_offset(_aura_glow, Vector2(0, -16))
		for g in FX._glows:
			if is_instance_valid(g.sprite) and g.sprite == _aura_glow:
				g.base_alpha = 0.55 if n > 0 else 0.0


func _process(delta: float) -> void:
	_anim_frame_time += delta
	if _cast_timer > 0.0: _cast_timer -= delta
	if _hurt_timer > 0.0: _hurt_timer -= delta
	if _iframe_timer > 0.0:
		_iframe_timer -= delta
		if _iframe_timer <= 0.0 and not is_rolling:
			is_invulnerable = false

	var moving := velocity.length() > 20.0
	var dir := _dir_from(facing_direction)
	var anim := "idle"
	if is_rolling: anim = "roll"
	elif _hurt_timer > 0.0: anim = "hurt"
	elif is_eating: anim = "eat"
	elif _cast_timer > 0.0: anim = "cast"
	elif is_attacking: anim = "attack"
	elif moving: anim = "walk"
	if anim != _anim:
		_anim = anim
		_anim_frame_time = 0.0
	_anim_dir = dir

	var fps := {"idle": 2.5, "walk": 9.0, "attack": 16.0, "roll": 18.0, "eat": 8.0, "cast": 7.0, "hurt": 1.0}
	var count: int = Art.ROW_FRAMES[anim]
	var f := int(_anim_frame_time * fps.get(anim, 6.0))
	f = mini(f, count - 1) if anim == "attack" else f % count
	var row: int = Art.ROWS[anim] + (0 if anim == "roll" else dir)
	body_sprite.frame = row * 4 + f
	body_sprite.flip_h = dir == DIR_SIDE and facing_direction.x < 0.0
	if anim == "roll":
		body_sprite.flip_h = facing_direction.x < 0.0

	# tool held in hand, swung during attacks
	tool_sprite.visible = not is_rolling and not is_eating and _cast_timer <= 0.0
	var side := -1.0 if body_sprite.flip_h else 1.0
	tool_sprite.flip_h = side < 0.0
	tool_sprite.offset = Vector2(12 * side, -12)
	tool_sprite.z_index = -1 if dir == DIR_UP else 1
	var base_rot := 0.0
	if is_attacking:
		var t := clampf(_anim_frame_time / 0.18, 0.0, 1.0)
		base_rot = lerpf(-1.6, 1.4, ease(t, 0.4)) * side
	tool_sprite.rotation = base_rot
	tool_sprite.position = Vector2(4 * side, -16) + (facing_direction * 6.0 if is_attacking else Vector2.ZERO)

	# i-frame flicker
	var flicker := (is_rolling or _iframe_timer > 0.0) and int(Time.get_ticks_msec() / 50) % 2 == 0
	body_sprite.modulate.a = 0.45 if flicker else 1.0

	# hit flash
	(body_sprite.material as ShaderMaterial).set_shader_parameter("flash", clampf(_damage_flash_timer / 0.14, 0.0, 1.0))

	# run dust & digesting afterimages
	if moving and not is_rolling:
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.28
			FX.dust(global_position + Vector2(0, -2), 2)
	if not digesting_fruits.is_empty() and (moving or is_rolling):
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.05 if is_rolling else 0.09
			_spawn_afterimage()


func _dir_from(v: Vector2) -> int:
	if absf(v.x) > absf(v.y) * 1.1:
		return DIR_SIDE
	return DIR_UP if v.y < 0.0 else DIR_DOWN


func _spawn_afterimage() -> void:
	if FX.world == null:
		return
	var g := Sprite2D.new()
	g.texture = body_sprite.texture
	g.hframes = body_sprite.hframes
	g.vframes = body_sprite.vframes
	g.frame = body_sprite.frame
	g.flip_h = body_sprite.flip_h
	g.centered = false
	g.offset = body_sprite.offset
	var m := ShaderMaterial.new()
	m.shader = Art.ACTOR_SHADER
	m.set_shader_parameter("ghost", 0.38)
	var idx := int(Time.get_ticks_msec() / 90) % mini(digesting_fruits.size(), 3)
	m.set_shader_parameter("ghost_color", WPal.element(int(digesting_fruits[idx].get("family", 0)), 3))
	g.material = m
	g.z_index = -1
	FX.world.add_child(g)
	g.global_position = global_position
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.28)
	t.tween_callback(g.queue_free)


func _play_swing_fx() -> void:
	if FX.world == null or current_tool == WindfallTypes.ToolType.SEED_SLING:
		return
	var idx := 0
	match current_tool:
		WindfallTypes.ToolType.SCYTHE: idx = 1
		WindfallTypes.ToolType.HOE_STAFF: idx = 2
	if current_tool == WindfallTypes.ToolType.WATERING_CAN:
		FX.burst(global_position + facing_direction * 30.0 + Vector2(0, -12), "fx/dot4", WPal.WATER[4], 14, 160.0, 0.45, Vector2(0, 200), 25.0, facing_direction, Vector2(0.8, 1.4), "world")
		return
	var s := Art.sprite("fx/slash_%d" % idx, 3, 1)
	s.centered = true
	s.offset = Vector2.ZERO
	s.rotation = facing_direction.angle()
	s.z_index = 5
	s.modulate = Color(1, 0.96, 0.82) if _aura_color == Color.TRANSPARENT else _aura_color.lightened(0.4)
	add_child(s)
	s.position = facing_direction * (14.0 + idx * 4.0) + Vector2(0, -14)
	if idx == 1:
		s.scale = Vector2(1.35, 1.35)
	var t := s.create_tween()
	t.tween_property(s, "frame", 2, 0.14).from(0)
	t.tween_callback(s.queue_free)
	if idx == 2:
		FX.ring(global_position + facing_direction * 22.0, WPal.DIRT[4], 46.0, 0.3)
		FX.dust(global_position + facing_direction * 22.0, 8)
		FX.shake(0.22)


func _bite_feedback(fam: int) -> void:
	var c := WPal.element(fam, 3)
	FX.burst(global_position + Vector2(0, -26), "fx/dot4", c, 22, 170.0, 0.55, Vector2(0, 260), 160.0, Vector2.UP, Vector2(0.8, 1.8))
	FX.element_burst(fam, global_position + Vector2(0, -20), 1.0)
	FX.ring(global_position + Vector2(0, -14), c, 40.0, 0.3)
	FX.punch(0.12)
	FX.shake(0.22)
	FX.popup("CRUNCH!", global_position + Vector2(0, -52), c, 18)


func set_respawn_point(p: Vector2) -> void:
	_respawn_point = p
