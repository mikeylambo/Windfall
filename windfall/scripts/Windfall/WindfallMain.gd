extends Node2D
class_name WindfallMain

@onready var player: RootbornPlayer = $Player
@onready var day_manager: DayCycleManager = $DayCycleManager
@onready var market_manager: MarketManager = $MarketManager
@onready var hud: WindfallHUD = $HUDLayer/WindfallHUD
@onready var camera: Camera2D = $Player/Camera2D

var initial_plots: Array[OrchardPlot2D] = []


func _ready() -> void:
	# Add all orchard plots to group
	for child in $OrchardGrid.get_children():
		if child is OrchardPlot2D:
			child.add_to_group("orchard_plots")
			initial_plots.append(child)
			child.plot_harvested.connect(_on_plot_harvested)

	# Connect day cycle events
	day_manager.raid_started.connect(_on_raid_started)
	day_manager.raid_cleared.connect(_on_raid_cleared)
	day_manager.new_day_started.connect(_on_new_day)

	# Connect HUD signals
	hud.player = player
	hud.day_manager = day_manager
	hud.market = market_manager

	call_deferred("_run_system_diagnostics")


func _run_system_diagnostics() -> void:
	print("--- WINDFALL ENGINE READY ---")
	print("• Species Registered: %d base + hybrid species" % FruitRegistry.species.size())
	print("• Player HP: %.0f/%.0f | Energy: %.0f/%.0f" % [player.current_health, player.max_health, player.current_energy, player.max_energy])
	print("• Satchel Fruits Carried: %d" % player.satchel_fruits.size())
	print("• Satchel Seeds Stocked: %d types" % player.satchel_seeds.size())
	print("• Orchard Plots Active: %d" % initial_plots.size())
	print("• Day Cycle: Day %d (%s, %s)" % [day_manager.day_number, WindfallTypes.Season.keys()[day_manager.current_season], WindfallTypes.TimeOfDay.keys()[day_manager.current_phase]])
	print("• Market Gold: %d G" % market_manager.gold)
	print("-----------------------------------")


func _on_plot_harvested(plot: OrchardPlot2D, fruit_instance: Dictionary) -> void:
	# Notification or sound
	pass


func _on_raid_started(day_num: int) -> void:
	# Camera slight shake on raid horn
	if has_node("/root/CameraFX"):
		var cfx = get_node("/root/CameraFX")
		if cfx.has_method("shake"):
			cfx.call("shake", 8.0, 0.4)


func _on_raid_cleared(day_num: int) -> void:
	# Reward player with bonus gold for defending the orchard!
	var bonus_gold := 50 + (day_num * 20)
	market_manager.gold += bonus_gold
	market_manager.gold_changed.emit(market_manager.gold)


func _on_new_day(day_num: int) -> void:
	# Heal player slightly each morning
	player.heal(40.0)
