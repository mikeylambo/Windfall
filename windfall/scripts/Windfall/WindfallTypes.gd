extends RefCounted
class_name WindfallTypes

enum Family {
	STORM,
	EMBER,
	FROST,
	TIDE,
	VERDANT,
	GALE,
	UMBRA,
	LUMEN
}

enum Ripeness {
	WINDFALL,  # Dropped, bruised, knocked loose by raiders
	UNRIPE,    # Picked early
	RIPE,      # Picked on time
	PRIME,     # Tended + peak harvest timing
	GOLDEN     # Ancient trees, legendary power
}

enum SkillType {
	STRIKE,
	BURST,
	MOTION,
	WARD,
	SPROUT,
	AURA
}

enum FruitForm {
	FRESH,
	JUICE,
	DRIED,
	JAM,
	FERMENTED
}

enum SoilType {
	LOAM,        # Neutral
	ASH,         # Ember thrives
	RIME,        # Frost thrives
	SILT,        # Tide & Verdant thrive
	STORMGLASS,  # Storm & Gale thrive
	LEY          # Lumen & Umbra thrive
}

enum TreeStage {
	EMPTY,
	SEED,
	SPROUT,
	SAPLING,
	YOUNG,
	MATURE,
	ANCIENT
}

enum TimeOfDay {
	MORNING,
	EXPEDITION,
	NIGHT_RAID
}

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

enum PairingEffect {
	NONE,
	CONDUCTIVE,    # Storm + Tide: lightning arcs on wet targets
	FANNED_FLAME,  # Ember + Gale: fire spreads on wind swirls
	INDIGESTION,   # Frost + Ember: clash! -25% power
	SANCTUARY,     # Lumen + Verdant: healing bloom thorns
	PHANTOM_MIST   # Tide + Umbra: untargetable shroud
}

enum ToolType {
	PRUNING_SHEARS,
	SCYTHE,
	HOE_STAFF,
	SEED_SLING,
	WATERING_CAN
}

const FAMILY_COLORS: Dictionary = {
	Family.STORM: Color(0.7, 0.4, 1.0),      # Electric violet
	Family.EMBER: Color(1.0, 0.35, 0.15),    # Molten ember
	Family.FROST: Color(0.4, 0.85, 1.0),     # Glacial cyan
	Family.TIDE: Color(0.15, 0.55, 0.95),    # Deep ocean blue
	Family.VERDANT: Color(0.25, 0.85, 0.35), # Vibrant jade
	Family.GALE: Color(0.75, 0.95, 0.8),     # Zephyr mint
	Family.UMBRA: Color(0.4, 0.2, 0.6),      # Shadow twilight
	Family.LUMEN: Color(1.0, 0.9, 0.3)       # Radiant gold
}

const RIPENESS_NAMES: Dictionary = {
	Ripeness.WINDFALL: "Windfall",
	Ripeness.UNRIPE: "Unripe",
	Ripeness.RIPE: "Ripe",
	Ripeness.PRIME: "Prime",
	Ripeness.GOLDEN: "Golden"
}

const RIPENESS_MULTIPLIERS: Dictionary = {
	Ripeness.WINDFALL: 0.65,
	Ripeness.UNRIPE: 0.8,
	Ripeness.RIPE: 1.0,
	Ripeness.PRIME: 1.45,
	Ripeness.GOLDEN: 2.2
}

const RIPENESS_COLORS: Dictionary = {
	Ripeness.WINDFALL: Color(0.65, 0.55, 0.45),
	Ripeness.UNRIPE: Color(0.6, 0.8, 0.4),
	Ripeness.RIPE: Color(1.0, 0.85, 0.3),
	Ripeness.PRIME: Color(0.3, 1.0, 0.5),
	Ripeness.GOLDEN: Color(1.0, 0.95, 0.2)
}
