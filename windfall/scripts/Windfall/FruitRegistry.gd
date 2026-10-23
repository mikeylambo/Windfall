extends Node

# Singleton / Registry for all fruit species and hybrids in Windfall

var species: Dictionary = {}
var hybrid_recipes: Dictionary = {}

func _init() -> void:
	_register_all_species()
	_register_hybrid_recipes()


func _register_all_species() -> void:
	# ─── STORM (4 species) ──────────────────────────────────────────────────
	_add_species({
		"id": &"voltberry",
		"name": "Voltberry",
		"family": WindfallTypes.Family.STORM,
		"skill_name": "Chain Lightning",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Fires an electric bolt that leaps between 4 nearby targets with a chance to stun.",
		"base_damage": 38.0,
		"cooldown": 1.2,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 30,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Lightning Rod that zaps nearby foes every 1.5s."
	})
	_add_species({
		"id": &"thunderplum",
		"name": "Thunderplum",
		"family": WindfallTypes.Family.STORM,
		"skill_name": "Thunderclap",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Detonates a concussive thunder shockwave in a wide area around you, repelling enemies.",
		"base_damage": 65.0,
		"cooldown": 3.0,
		"digestion_duration": 65.0,
		"slots": 2,
		"base_value": 55,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Thunder Spore that explodes when stepped on."
	})
	_add_species({
		"id": &"sparkfig",
		"name": "Sparkfig",
		"family": WindfallTypes.Family.STORM,
		"skill_name": "Static Dash",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Surges forward in a burst of speed, electrifying the ground behind you.",
		"base_damage": 25.0,
		"cooldown": 1.8,
		"digestion_duration": 45.0,
		"slots": 1,
		"base_value": 32,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Speed Conduit flower that supercharges walking speed."
	})
	_add_species({
		"id": &"stormglass_lemon",
		"name": "Stormglass Lemon",
		"family": WindfallTypes.Family.STORM,
		"skill_name": "Lightning Rod",
		"skill_type": WindfallTypes.SkillType.SPROUT,
		"skill_desc": "Places a persistent storm pylon calling down periodic thunderstrikes.",
		"base_damage": 42.0,
		"cooldown": 4.5,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 40,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Bitter",
		"quickroot_desc": "Summons a Storm Turret with high conductive arc range."
	})

	# ─── EMBER (4 species) ──────────────────────────────────────────────────
	_add_species({
		"id": &"cinderapple",
		"name": "Cinderapple",
		"family": WindfallTypes.Family.EMBER,
		"skill_name": "Fireball",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Launches a blazing projectile that explodes on impact, inflicting burn.",
		"base_damage": 45.0,
		"cooldown": 1.4,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 30,
		"soil_pref": WindfallTypes.SoilType.ASH,
		"flavor": "Spicy",
		"quickroot_desc": "Sprouts a Fire Bloom that shoots flame embers at invaders."
	})
	_add_species({
		"id": &"scorchpeach",
		"name": "Scorchpeach",
		"family": WindfallTypes.Family.EMBER,
		"skill_name": "Flame Wave",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Unleashes a sweeping wall of fire forward, igniting everything in its path.",
		"base_damage": 55.0,
		"cooldown": 2.6,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 38,
		"soil_pref": WindfallTypes.SoilType.ASH,
		"flavor": "Sweet",
		"quickroot_desc": "Creates a Blazing Line trap that scorches crossing enemies."
	})
	_add_species({
		"id": &"ashdate",
		"name": "Ashdate",
		"family": WindfallTypes.Family.EMBER,
		"skill_name": "Burning Aura",
		"skill_type": WindfallTypes.SkillType.AURA,
		"skill_desc": "Radiates intense heat, damaging nearby foes and burning flammable obstacles.",
		"base_damage": 16.0,
		"cooldown": 0.5,
		"digestion_duration": 60.0,
		"slots": 1,
		"base_value": 35,
		"soil_pref": WindfallTypes.SoilType.ASH,
		"flavor": "Bitter",
		"quickroot_desc": "Sprouts an Ash Furnace flower warming and empowering allies."
	})
	_add_species({
		"id": &"phoenix_pomegranate",
		"name": "Phoenix Pomegranate",
		"family": WindfallTypes.Family.EMBER,
		"skill_name": "Rekindle",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Grants fiery armor. Fatal damage is absorbed and triggers a fiery restorative blast.",
		"base_damage": 50.0,
		"cooldown": 30.0,
		"digestion_duration": 80.0,
		"slots": 2,
		"base_value": 75,
		"soil_pref": WindfallTypes.SoilType.ASH,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Phoenix Nest that radiates revival energy."
	})

	# ─── FROST (4 species) ──────────────────────────────────────────────────
	_add_species({
		"id": &"rimepear",
		"name": "Rimepear",
		"family": WindfallTypes.Family.FROST,
		"skill_name": "Ice Lance",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Flings a glacial lance that pierces targets and inflicts heavy chill/freeze.",
		"base_damage": 40.0,
		"cooldown": 1.3,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 30,
		"soil_pref": WindfallTypes.SoilType.RIME,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Frost Spire that slows and freezes nearby enemies."
	})
	_add_species({
		"id": &"glacier_grape",
		"name": "Glacier Grape",
		"family": WindfallTypes.Family.FROST,
		"skill_name": "Frost Shell",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Encases you in crystalline frost armor, reducing damage taken and chilling attackers.",
		"base_damage": 20.0,
		"cooldown": 3.0,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 35,
		"soil_pref": WindfallTypes.SoilType.RIME,
		"flavor": "Sweet",
		"quickroot_desc": "Creates an Ice Barrier that blocks enemy movement and attacks."
	})
	_add_species({
		"id": &"snowquince",
		"name": "Snowquince",
		"family": WindfallTypes.Family.FROST,
		"skill_name": "Blizzard Field",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Conjures a swirling snowstorm zone that continuously slows and shreds foes.",
		"base_damage": 60.0,
		"cooldown": 4.0,
		"digestion_duration": 70.0,
		"slots": 2,
		"base_value": 60,
		"soil_pref": WindfallTypes.SoilType.RIME,
		"flavor": "Bitter",
		"quickroot_desc": "Sprouts an Ice Geyser freezing water channels into traversable bridges."
	})
	_add_species({
		"id": &"icicle_plum",
		"name": "Icicle Plum",
		"family": WindfallTypes.Family.FROST,
		"skill_name": "Frozen Step",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Glides across surfaces on ice, chilling footsteps that make pursuers slip.",
		"base_damage": 22.0,
		"cooldown": 1.5,
		"digestion_duration": 45.0,
		"slots": 1,
		"base_value": 32,
		"soil_pref": WindfallTypes.SoilType.RIME,
		"flavor": "Savory",
		"quickroot_desc": "Freezes ground in a radius, granting allies speed and enemies slippage."
	})

	# ─── TIDE (4 species) ───────────────────────────────────────────────────
	_add_species({
		"id": &"brinemelon",
		"name": "Brinemelon",
		"family": WindfallTypes.Family.TIDE,
		"skill_name": "Tidal Push",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Summons a roaring surge of ocean water that washes foes away and applies Wet.",
		"base_damage": 50.0,
		"cooldown": 2.2,
		"digestion_duration": 65.0,
		"slots": 2,
		"base_value": 50,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Tidal Geyser that blasts foes into the air."
	})
	_add_species({
		"id": &"mistlime",
		"name": "Mistlime",
		"family": WindfallTypes.Family.TIDE,
		"skill_name": "Regen Mist",
		"skill_type": WindfallTypes.SkillType.AURA,
		"skill_desc": "Emits soothing vapor that continuously restores health to you and companions.",
		"base_damage": 0.0,
		"cooldown": 1.0,
		"digestion_duration": 60.0,
		"slots": 1,
		"base_value": 45,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Spring Orchid providing a healing fountain in combat."
	})
	_add_species({
		"id": &"coral_fig",
		"name": "Coral Fig",
		"family": WindfallTypes.Family.TIDE,
		"skill_name": "Bubble Ward",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Wraps you in a pressurized bubble that nullifies next incoming strike.",
		"base_damage": 15.0,
		"cooldown": 4.0,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 36,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts Coral Brambles that snare and cushion blows."
	})
	_add_species({
		"id": &"riptide_mango",
		"name": "Riptide Mango",
		"family": WindfallTypes.Family.TIDE,
		"skill_name": "Undertow",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Fires a swirling whirlpool vortex that pulls dispersed enemies together.",
		"base_damage": 36.0,
		"cooldown": 2.0,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 34,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Spicy",
		"quickroot_desc": "Places a Whirlpool trap vortex on the field."
	})

	# ─── VERDANT (4 species) ────────────────────────────────────────────────
	_add_species({
		"id": &"briarcherry",
		"name": "Briarcherry",
		"family": WindfallTypes.Family.VERDANT,
		"skill_name": "Root Snare",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Erupts thorny briars beneath targets, pinning them in place and dealing bleed.",
		"base_damage": 35.0,
		"cooldown": 1.5,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 28,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Bramble Barricade that wounds attackers."
	})
	_add_species({
		"id": &"bramblequince",
		"name": "Bramblequince",
		"family": WindfallTypes.Family.VERDANT,
		"skill_name": "Thorn Armor",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Covers your coat in barbed brambles, reflecting 50% damage back to attackers.",
		"base_damage": 25.0,
		"cooldown": 2.5,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 32,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Bitter",
		"quickroot_desc": "Sprouts a Thorn Bush turret that flings spines."
	})
	_add_species({
		"id": &"vine_apple",
		"name": "Vine Apple",
		"family": WindfallTypes.Family.VERDANT,
		"skill_name": "Vine Grapple",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Shoots an elastic vine forward to pull yourself across gaps or drag enemies.",
		"base_damage": 30.0,
		"cooldown": 1.2,
		"digestion_duration": 48.0,
		"slots": 1,
		"base_value": 34,
		"soil_pref": WindfallTypes.SoilType.SILT,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Grapple Post usable for rapid traversal."
	})
	_add_species({
		"id": &"ironnut",
		"name": "Ironnut",
		"family": WindfallTypes.Family.VERDANT,
		"skill_name": "Bark Skin",
		"skill_type": WindfallTypes.SkillType.AURA,
		"skill_desc": "Hardens skin into ancient ironwood, significantly raising defense.",
		"base_damage": 0.0,
		"cooldown": 0.0,
		"digestion_duration": 70.0,
		"slots": 2,
		"base_value": 65,
		"soil_pref": WindfallTypes.SoilType.LOAM,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts an Ironwood Totem increasing nearby allies' armor."
	})

	# ─── GALE (4 species) ───────────────────────────────────────────────────
	_add_species({
		"id": &"zephyr_kiwi",
		"name": "Zephyr Kiwi",
		"family": WindfallTypes.Family.GALE,
		"skill_name": "Gale Dash",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Blasts forward on a localized whirlwind, gaining invincibility and knocking back foes.",
		"base_damage": 28.0,
		"cooldown": 1.2,
		"digestion_duration": 45.0,
		"slots": 1,
		"base_value": 30,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts an Updraft Vent that launches you over hazards."
	})
	_add_species({
		"id": &"cyclone_citrus",
		"name": "Cyclone Citrus",
		"family": WindfallTypes.Family.GALE,
		"skill_name": "Whirlwind",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Spins up a violent cyclone that lifts and tosses surrounding enemies.",
		"base_damage": 48.0,
		"cooldown": 2.5,
		"digestion_duration": 52.0,
		"slots": 1,
		"base_value": 36,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Wind Turbine that repels enemy projectiles."
	})
	_add_species({
		"id": &"featherfig",
		"name": "Featherfig",
		"family": WindfallTypes.Family.GALE,
		"skill_name": "Glide",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Lightens your body, allowing effortless gliding and immunity to pit hazards.",
		"base_damage": 0.0,
		"cooldown": 1.0,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 35,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts an aerial slipstream lane."
	})
	_add_species({
		"id": &"squall_berry",
		"name": "Squall Berry",
		"family": WindfallTypes.Family.GALE,
		"skill_name": "Wind Blades",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Cuts the air with three crescent gale blades that slice through lines of enemies.",
		"base_damage": 36.0,
		"cooldown": 1.1,
		"digestion_duration": 48.0,
		"slots": 1,
		"base_value": 32,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Spicy",
		"quickroot_desc": "Sprouts a Razor Reed that flings wind slashes at invaders."
	})

	# ─── UMBRA (4 species) ──────────────────────────────────────────────────
	_add_species({
		"id": &"duskberry",
		"name": "Duskberry",
		"family": WindfallTypes.Family.UMBRA,
		"skill_name": "Shadow Blink",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Teleports through shadow, leaving a smoky decoy that confuses enemies.",
		"base_damage": 32.0,
		"cooldown": 1.4,
		"digestion_duration": 48.0,
		"slots": 1,
		"base_value": 36,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Bitter",
		"quickroot_desc": "Sprouts a Shadow Figurine that draws enemy aggression."
	})
	_add_species({
		"id": &"nightplum",
		"name": "Nightplum",
		"family": WindfallTypes.Family.UMBRA,
		"skill_name": "Shade Familiar",
		"skill_type": WindfallTypes.SkillType.SPROUT,
		"skill_desc": "Summons a shadowy orchard bat that attacks enemies alongside you.",
		"base_damage": 22.0,
		"cooldown": 3.0,
		"digestion_duration": 60.0,
		"slots": 1,
		"base_value": 42,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Gloom Lantern that curses enemies entering its light."
	})
	_add_species({
		"id": &"hollow_fig",
		"name": "Hollow Fig",
		"family": WindfallTypes.Family.UMBRA,
		"skill_name": "Drain",
		"skill_type": WindfallTypes.SkillType.AURA,
		"skill_desc": "Shrouds you in void mist, converting 25% of all damage dealt into player health.",
		"base_damage": 0.0,
		"cooldown": 0.0,
		"digestion_duration": 58.0,
		"slots": 1,
		"base_value": 45,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Sour",
		"quickroot_desc": "Sprouts a Leech Root that siphons enemy health into nearby allies."
	})
	_add_species({
		"id": &"eclipse_cherry",
		"name": "Eclipse Cherry",
		"family": WindfallTypes.Family.UMBRA,
		"skill_name": "Darkness",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Engulfs the battlefield in twilight; enemies lose tracking of you.",
		"base_damage": 20.0,
		"cooldown": 4.0,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 38,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Sweet",
		"quickroot_desc": "Creates a Shadow Shroud dome concealing allies inside."
	})

	# ─── LUMEN (4 species) ──────────────────────────────────────────────────
	_add_species({
		"id": &"starfruit",
		"name": "Starfruit",
		"family": WindfallTypes.Family.LUMEN,
		"skill_name": "Light Beam",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Focuses a piercing solar laser beam through lines of adversaries.",
		"base_damage": 52.0,
		"cooldown": 1.6,
		"digestion_duration": 52.0,
		"slots": 1,
		"base_value": 42,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Solar Lens that focuses searing sunlight on poachers."
	})
	_add_species({
		"id": &"lumen_lychee",
		"name": "Lumen Lychee",
		"family": WindfallTypes.Family.LUMEN,
		"skill_name": "Healing Bloom",
		"skill_type": WindfallTypes.SkillType.SPROUT,
		"skill_desc": "Places a radiant lily that pulses waves of restoration to the party.",
		"base_damage": 0.0,
		"cooldown": 3.5,
		"digestion_duration": 55.0,
		"slots": 1,
		"base_value": 45,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Healing Beacon restoring 15 HP/s to all allies."
	})
	_add_species({
		"id": &"dawnpeach",
		"name": "Dawnpeach",
		"family": WindfallTypes.Family.LUMEN,
		"skill_name": "Radiance",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Flashes blinding holy light that damages and disorients all surrounding beasts.",
		"base_damage": 46.0,
		"cooldown": 2.2,
		"digestion_duration": 50.0,
		"slots": 1,
		"base_value": 38,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Spicy",
		"quickroot_desc": "Sprouts a Dawn Lantern illuminating stealthy poachers."
	})
	_add_species({
		"id": &"halo_apricot",
		"name": "Halo Apricot",
		"family": WindfallTypes.Family.LUMEN,
		"skill_name": "Sanctuary",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Creates a shimmering golden sanctuary circle that enemies cannot enter.",
		"base_damage": 30.0,
		"cooldown": 5.0,
		"digestion_duration": 70.0,
		"slots": 2,
		"base_value": 70,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Sanctuary Ring protecting crops from being raided."
	})

	# ─── HYBRID SPECIES ────────────────────────────────────────────────────
	_add_species({
		"id": &"plasma_plum",
		"name": "Plasma Plum",
		"family": WindfallTypes.Family.STORM,
		"skill_name": "Arc Flame",
		"skill_type": WindfallTypes.SkillType.STRIKE,
		"skill_desc": "Hybrid: Chain lightning that ignites everything it leaps to with molten flame.",
		"base_damage": 62.0,
		"cooldown": 1.5,
		"digestion_duration": 65.0,
		"slots": 1,
		"base_value": 90,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Spicy",
		"quickroot_desc": "Sprouts a Plasma Conduit firing scorching electric charges."
	})
	_add_species({
		"id": &"glacier_gourd",
		"name": "Glacier Gourd",
		"family": WindfallTypes.Family.FROST,
		"skill_name": "Tidelock",
		"skill_type": WindfallTypes.SkillType.BURST,
		"skill_desc": "Hybrid: A tidal wave that flash-freezes into an impassable wall of ice spikes.",
		"base_damage": 70.0,
		"cooldown": 3.0,
		"digestion_duration": 75.0,
		"slots": 2,
		"base_value": 110,
		"soil_pref": WindfallTypes.SoilType.RIME,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Glacier Wall instantly sealing choke points."
	})
	_add_species({
		"id": &"wraith_kiwi",
		"name": "Wraith Kiwi",
		"family": WindfallTypes.Family.GALE,
		"skill_name": "Phantom Dash",
		"skill_type": WindfallTypes.SkillType.MOTION,
		"skill_desc": "Hybrid: A lightning-fast wind blink leaving an explosive shadow decoy.",
		"base_damage": 55.0,
		"cooldown": 1.4,
		"digestion_duration": 60.0,
		"slots": 1,
		"base_value": 85,
		"soil_pref": WindfallTypes.SoilType.STORMGLASS,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Phantom Gale cyclone distracting enemies."
	})
	_add_species({
		"id": &"halo_thorns",
		"name": "Halo Thorns",
		"family": WindfallTypes.Family.VERDANT,
		"skill_name": "Thornlight",
		"skill_type": WindfallTypes.SkillType.WARD,
		"skill_desc": "Hybrid: A protective ring of radiant briars that damages foes and heals allies.",
		"base_damage": 40.0,
		"cooldown": 3.2,
		"digestion_duration": 65.0,
		"slots": 1,
		"base_value": 95,
		"soil_pref": WindfallTypes.SoilType.LEY,
		"flavor": "Sweet",
		"quickroot_desc": "Sprouts a Radiant Briar Hedge defending orchard rows."
	})
	_add_species({
		"id": &"forgefruit",
		"name": "Forgefruit",
		"family": WindfallTypes.Family.EMBER,
		"skill_name": "Molten Plating",
		"skill_type": WindfallTypes.SkillType.AURA,
		"skill_desc": "Hybrid: Heavy ironwood armor infused with magma that burns attackers on contact.",
		"base_damage": 30.0,
		"cooldown": 0.0,
		"digestion_duration": 75.0,
		"slots": 2,
		"base_value": 120,
		"soil_pref": WindfallTypes.SoilType.ASH,
		"flavor": "Savory",
		"quickroot_desc": "Sprouts a Forge Anvil granting continuous thorns and damage bonus."
	})


func _add_species(data: Dictionary) -> void:
	species[data.id] = data


func _register_hybrid_recipes() -> void:
	# Key is sorted pair of Family enums
	hybrid_recipes[_make_pair_key(WindfallTypes.Family.STORM, WindfallTypes.Family.EMBER)] = &"plasma_plum"
	hybrid_recipes[_make_pair_key(WindfallTypes.Family.FROST, WindfallTypes.Family.TIDE)] = &"glacier_gourd"
	hybrid_recipes[_make_pair_key(WindfallTypes.Family.GALE, WindfallTypes.Family.UMBRA)] = &"wraith_kiwi"
	hybrid_recipes[_make_pair_key(WindfallTypes.Family.VERDANT, WindfallTypes.Family.LUMEN)] = &"halo_thorns"
	hybrid_recipes[_make_pair_key(WindfallTypes.Family.EMBER, WindfallTypes.Family.VERDANT)] = &"forgefruit"


func _make_pair_key(fam_a: int, fam_b: int) -> String:
	var a: int = mini(fam_a, fam_b)
	var b: int = maxi(fam_a, fam_b)
	return "%d_%d" % [a, b]


func get_species(species_id: StringName) -> Dictionary:
	if species.has(species_id):
		return species[species_id]
	# Fallback to voltberry
	return species[&"voltberry"]


func get_hybrid_for_families(fam_a: int, fam_b: int) -> StringName:
	var key := _make_pair_key(fam_a, fam_b)
	if hybrid_recipes.has(key):
		return hybrid_recipes[key]
	return &""


func create_fruit_instance(species_id: StringName, ripeness: int = WindfallTypes.Ripeness.RIPE, traits: Array = [], form: int = WindfallTypes.FruitForm.FRESH) -> Dictionary:
	var sp := get_species(species_id)
	var mult: float = WindfallTypes.RIPENESS_MULTIPLIERS.get(ripeness, 1.0)
	var duration: float = float(sp.get("digestion_duration", 50.0))
	var val: int = int(float(sp.get("base_value", 30)) * mult)

	# Trait modifications
	if "Juicy" in traits:
		duration *= 1.5
	if "Sweet" in traits:
		val *= 2

	return {
		"species_id": species_id,
		"name": sp.get("name", "Unknown Fruit"),
		"family": sp.get("family", WindfallTypes.Family.STORM),
		"skill_name": sp.get("skill_name", "Skill"),
		"skill_type": sp.get("skill_type", WindfallTypes.SkillType.STRIKE),
		"ripeness": ripeness,
		"ripeness_name": WindfallTypes.RIPENESS_NAMES.get(ripeness, "Ripe"),
		"traits": traits.duplicate(),
		"form": form,
		"slots": sp.get("slots", 1),
		"base_damage": float(sp.get("base_damage", 30.0)) * mult,
		"cooldown": float(sp.get("cooldown", 1.5)),
		"digestion_duration": duration,
		"remaining_duration": duration,
		"market_value": val,
		"flavor": sp.get("flavor", "Sweet"),
		"color": WindfallTypes.FAMILY_COLORS.get(sp.get("family", WindfallTypes.Family.STORM), Color.WHITE)
	}


func evaluate_pairings(active_families: Array) -> Array[int]:
	var pairings: Array[int] = []
	var has_storm := WindfallTypes.Family.STORM in active_families
	var has_tide := WindfallTypes.Family.TIDE in active_families
	var has_ember := WindfallTypes.Family.EMBER in active_families
	var has_gale := WindfallTypes.Family.GALE in active_families
	var has_frost := WindfallTypes.Family.FROST in active_families
	var has_lumen := WindfallTypes.Family.LUMEN in active_families
	var has_verdant := WindfallTypes.Family.VERDANT in active_families
	var has_umbra := WindfallTypes.Family.UMBRA in active_families

	if has_storm and has_tide:
		pairings.append(WindfallTypes.PairingEffect.CONDUCTIVE)
	if has_ember and has_gale:
		pairings.append(WindfallTypes.PairingEffect.FANNED_FLAME)
	if has_frost and has_ember:
		pairings.append(WindfallTypes.PairingEffect.INDIGESTION)
	if has_lumen and has_verdant:
		pairings.append(WindfallTypes.PairingEffect.SANCTUARY)
	if has_tide and has_umbra:
		pairings.append(WindfallTypes.PairingEffect.PHANTOM_MIST)

	return pairings


func roll_random_trait() -> String:
	var pool := ["Juicy", "Twin", "Thorned", "Volatile", "Sweet", "Hardy", "Wild"]
	return pool[randi() % pool.size()]
