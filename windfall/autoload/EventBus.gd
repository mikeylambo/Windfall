extends Node

signal game_started
signal game_paused
signal game_resumed
signal scene_changed(scene_path)
signal unit_spawned(unit)
signal unit_defeated(unit, source)
signal damage_dealt(source, target, amount)
signal healing_done(source, target, amount)
signal ability_used(user, target, ability)
signal effect_applied(source, target, effect)
signal save_requested
signal save_completed
signal load_requested
signal load_completed


func emit_game_started() -> void:
	game_started.emit()


func emit_game_paused() -> void:
	game_paused.emit()


func emit_game_resumed() -> void:
	game_resumed.emit()


func emit_scene_changed(scene_path: String) -> void:
	scene_changed.emit(scene_path)


func emit_unit_spawned(unit) -> void:
	unit_spawned.emit(unit)


func emit_unit_defeated(unit, source) -> void:
	unit_defeated.emit(unit, source)


func emit_damage_dealt(source, target, amount: float) -> void:
	damage_dealt.emit(source, target, amount)


func emit_healing_done(source, target, amount: float) -> void:
	healing_done.emit(source, target, amount)


func emit_ability_used(user, target, ability) -> void:
	ability_used.emit(user, target, ability)


func emit_effect_applied(source, target, effect) -> void:
	effect_applied.emit(source, target, effect)


func emit_save_requested() -> void:
	save_requested.emit()


func emit_save_completed() -> void:
	save_completed.emit()


func emit_load_requested() -> void:
	load_requested.emit()


func emit_load_completed() -> void:
	load_completed.emit()
