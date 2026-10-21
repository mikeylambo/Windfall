extends Node
class_name MarketManager

signal gold_changed(new_gold: int)
signal transaction_completed(message: String)

@export var gold: int = 150

# Land plot expansion cost
var land_expansion_cost: int = 120
var plots_unlocked: int = 6

# Upgrades
var tool_level: int = 1
var satchel_capacity: int = 8
var stomach_upgrades: int = 0

# Seed shop inventory with prices
var seed_shop: Dictionary = {
	&"voltberry": 25,
	&"cinderapple": 25,
	&"rimepear": 25,
	&"briarcherry": 22,
	&"brinemelon": 40,
	&"zephyr_kiwi": 30,
	&"duskberry": 35,
	&"starfruit": 45
}


func _ready() -> void:
	gold_changed.emit(gold)


func sell_fruit(fruit_instance: Dictionary) -> int:
	var val: int = int(fruit_instance.get("market_value", 20))
	# Ripeness multiplier
	var rip: int = int(fruit_instance.get("ripeness", WindfallTypes.Ripeness.RIPE))
	val = int(val * WindfallTypes.RIPENESS_MULTIPLIERS.get(rip, 1.0))

	# Trait bonus: Sweet sells for double
	if "Sweet" in fruit_instance.get("traits", []):
		val *= 2

	gold += val
	gold_changed.emit(gold)
	WindfallSound.play_harvest()
	transaction_completed.emit("Sold %s for %d Gold" % [fruit_instance.get("name", "Fruit"), val])
	return val


func buy_seed(species_id: StringName, player: RootbornPlayer) -> bool:
	var price: int = seed_shop.get(species_id, 30)
	if gold < price:
		transaction_completed.emit("Not enough Gold for " + FruitRegistry.get_species(species_id).get("name", "Seed"))
		return false

	gold -= price
	gold_changed.emit(gold)
	player.satchel_seeds[species_id] = player.satchel_seeds.get(species_id, 0) + 1
	player.satchel_changed.emit()
	WindfallSound.play_harvest()
	transaction_completed.emit("Bought %s Seed" % FruitRegistry.get_species(species_id).get("name", "Seed"))
	return true


func buy_stomach_upgrade(player: RootbornPlayer) -> bool:
	var cost := 150 + (player.max_stomach_slots * 50)
	if gold < cost:
		transaction_completed.emit("Need %d Gold for Stomach Upgrade" % cost)
		return false
	if player.max_stomach_slots >= 8:
		transaction_completed.emit("Stomach at maximum capacity (8 slots)!")
		return false

	gold -= cost
	gold_changed.emit(gold)
	player.max_stomach_slots += 1
	player.stomach_changed.emit()
	WindfallSound.play_prime_timing()
	transaction_completed.emit("Stomach expanded to %d slots!" % player.max_stomach_slots)
	return true


func buy_tool_upgrade(player: RootbornPlayer) -> bool:
	var cost := 100 * tool_level
	if gold < cost:
		transaction_completed.emit("Need %d Gold for Tool Upgrade" % cost)
		return false

	gold -= cost
	gold_changed.emit(gold)
	tool_level += 1
	WindfallSound.play_prime_timing()
	transaction_completed.emit("Tools upgraded to Tier %d (+damage & reach)!" % tool_level)
	return true


# ── The Pantry (Juice, Dry, Jam) ───────────────────────────────────────────────

func make_juice(fruit: Dictionary) -> Dictionary:
	var juice := fruit.duplicate(true)
	juice["form"] = WindfallTypes.FruitForm.JUICE
	juice["name"] = "%s Juice" % fruit.get("name", "Fruit")
	juice["digestion_duration"] = float(fruit.get("digestion_duration", 50.0)) * 0.5
	return juice


func make_dried_fruit(fruit: Dictionary) -> Dictionary:
	var dried := fruit.duplicate(true)
	dried["form"] = WindfallTypes.FruitForm.DRIED
	dried["name"] = "Dried %s" % fruit.get("name", "Fruit")
	# One tier lower
	var rip: int = int(fruit.get("ripeness", WindfallTypes.Ripeness.RIPE))
	dried["ripeness"] = maxi(rip - 1, 0)
	dried["ripeness_name"] = WindfallTypes.RIPENESS_NAMES.get(dried["ripeness"], "Ripe")
	dried["traits"].append("Hardy")
	return dried


func make_jam(fruit_a: Dictionary, fruit_b: Dictionary) -> Dictionary:
	var jam := fruit_a.duplicate(true)
	jam["form"] = WindfallTypes.FruitForm.JAM
	jam["name"] = "%s & %s Jam" % [fruit_a.get("name", "A"), fruit_b.get("name", "B")]
	jam["slots"] = 1 # Pre-mixed Pairing in 1 slot!
	jam["jam_family"] = int(fruit_b.get("family", 0))
	jam["jam_with"] = fruit_b.get("species_id", &"")
	jam["traits"].append("Juicy")
	return jam
