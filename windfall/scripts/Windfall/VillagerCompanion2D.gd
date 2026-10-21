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
	add_to_group("villagers")
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
	dots.add_theme_font_override("font", load(UITheme.FONT_PATH))
	dots.add_theme_font_size_override("font_size", 10)
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
		if is_support():
			_tick_support(delta)
	elif is_guard() and _raid_active():
		_process_guard(delta)
	else:
		_wander(delta)
	_update_visuals()


# ── village party roles ─────────────────────────────────────────────────────
## In the party: Rogues (Wren) fight beside you, Supports (Hesper) mend you.
## Left at home: Wren keeps watch and defends the orchard; Hesper tends the
## hives, raising spring cross-pollination odds (DayCycleManager reads it).

var _support_timer: float = 4.0


func is_support() -> bool:
	return combat_role == "Support"


func is_guard() -> bool:
	return village_job == "Watch"


## Hybrid odds bonus while this villager tends the hives at home.
func hive_bonus() -> float:
	return 0.2 if village_job == "Beekeeper" and not is_in_party else 0.0


func _raid_active() -> bool:
	var dm := get_tree().get_first_node_in_group("day_manager")
	return dm != null and bool(dm.get("is_raid_active"))


func _nearest_player() -> RootbornPlayer:
	var best: RootbornPlayer = null
	var bd := INF
	for p in get_tree().get_nodes_in_group("player"):
		var d := global_position.distance_to((p as Node2D).global_position)
		if d < bd:
			bd = d
			best = p
	return best


func _tick_support(delta: float) -> void:
	_support_timer -= delta
	if _support_timer > 0.0:
		return
	_support_timer = 4.0
	var p := _nearest_player()
	if p and p.current_health < p.max_health and global_position.distance_to(p.global_position) < 160.0:
		p.heal(8.0 * power_mult())
		FX.burst(p.global_position + Vector2(0, -20), "fx/sparkle", WPal.GOLD[4], 6, 40.0, 0.6, Vector2(0, -30), 180.0, Vector2.UP, Vector2(1, 1.5))
		FX.popup("+%d" % int(8.0 * power_mult()), p.global_position + Vector2(0, -44), WPal.LEAF[5], 12)


func _process_guard(delta: float) -> void:
	# patrol the orchard and intercept raiders near the trees
	var orchard := WorldLayout.ORCHARD
	target_enemy = null
	var best := 220.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var ep: Vector2 = (e as Node2D).global_position
		if orchard.grow(120).has_point(ep):
			var d := global_position.distance_to(ep)
			if d < best:
				best = d
				target_enemy = e
	if target_enemy:
		velocity = (target_enemy.global_position - global_position).normalized() * 130.0
		if best <= 32.0 and _attack_cd <= 0.0:
			_attack_cd = 1.1
			target_enemy.call("take_damage", 18.0 * power_mult())
			WindfallSound.play_swing()
	else:
		var post := orchard.get_center() + Vector2(0, 80)
		velocity = (post - global_position).normalized() * 90.0 if global_position.distance_to(post) > 30.0 else Vector2.ZERO
	move_and_slide()


func _process_party_follow_and_combat(delta: float) -> void:
	var player := _nearest_player()
	if player == null:
		return

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
				target_enemy.call("take_damage", 24.0 * power_mult())
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
		var np := _nearest_player()
		if np:
			face = np.global_position - global_position
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
	return "Talk to %s  (%s)" % [villager_name, "in party" if is_in_party else ("on watch" if is_guard() else "tending hives")]


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


# ── affinity & gifts ────────────────────────────────────────────────────────
## 0..100. Loved flavours +20, neutral +8, hated -10, one gift per day.
## Affinity scales Wren's blades and Hesper's healing.
var affinity: int = 10
var gifted_today: bool = false


func affinity_level() -> int:
	return clampi(affinity / 20, 0, 5)


func power_mult() -> float:
	return 1.0 + affinity / 100.0


func on_new_day() -> void:
	gifted_today = false


func receive_gift(f: Dictionary) -> void:
	var flavor: String = f.get("flavor", "")
	var line := ""
	var delta := 8
	if flavor == loved_flavor:
		delta = 20
		line = "%s! My favourite. You remembered." % f.get("name", "")
	elif flavor == hated_flavor:
		delta = -10
		line = "Oh... %s. Too %s for me." % [f.get("name", ""), flavor.to_lower()]
	else:
		line = "A %s? That's thoughtful, thank you." % f.get("name", "")
	affinity = clampi(affinity + delta, 0, 100)
	gifted_today = true
	var col := WPal.LEAF[5] if delta > 0 else WPal.RED[4]
	FX.popup(("+" if delta > 0 else "") + "%d affinity" % delta, global_position + Vector2(0, -60), col, 14)
	if delta >= 20:
		FX.burst(global_position + Vector2(0, -40), "fx/sparkle", WPal.RED[4], 8, 50.0, 0.8, Vector2(0, -40), 180.0, Vector2.UP, Vector2(1, 1.5))
	HUDBus.say(villager_name, [line, "Affinity %d / 5" % affinity_level()])


func interact(_player: RootbornPlayer) -> void:
	if _player.is_remote():
		FX.popup("Hi!", global_position + Vector2(0, -60), WPal.CREAM[3], 12)
		return
	var pool: Array = LINES.get(villager_name, [["Lovely day for the orchard."]])
	var lines: Array = pool[_talks % pool.size()].duplicate()
	_talks += 1
	lines[lines.size() - 1] = "%s  (Affinity %d / 5)" % [lines[-1], affinity_level()]
	var choices := ["Head home" if is_in_party else "Join my party", "Give a gift" if not gifted_today else "(Gifted today)", "Goodbye"]
	HUDBus.ask(villager_name, lines, choices, _on_talk_choice)


func _on_talk_choice(choice: int) -> void:
	match choice:
		0:
			is_in_party = not is_in_party
			WindfallSound.play_harvest()
			HUDBus.toast("%s %s" % [villager_name, "joined your party!" if is_in_party else ("heads back to " + ("watch the treeline." if is_guard() else "tend the hives."))], WPal.LEAF[5])
			spoken.emit(self)
		1:
			if not gifted_today:
				HUDBus.open_gift(self)
