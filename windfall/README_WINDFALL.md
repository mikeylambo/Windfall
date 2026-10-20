# WINDFALL: Skill-Tree Gardening (Godot 4.7)

**WINDFALL** is an action RPG where every skill grows on a tree. You inherit a dying orchard, travel the world for seeds, cultivate fruit, and *eat* your build. One bite of a Voltberry and you have chain lightning.

Built upon the 2D Top-Down Adventure RPG Godot template.

---

## Controls

| Action | Key / Input | Description |
|---|---|---|
| **Move** | `W`, `A`, `S`, `D` / Arrows | 8-directional smooth movement |
| **Tool Attack** | `J` or `Left Click` | Swings equipped orchard tool weapon |
| **Cycle Tool** | `Tab` | Swaps between Shears, Scythe, Hoe-Staff, Seed Sling, and Watering Can |
| **Dodge / Dash** | `Shift` or `Right Click` | Invulnerable roll (enhanced with elemental trails by Motion fruits!) |
| **Interact / Harvest** | `E` | Tend plot, start harvest, talk to villagers, sleep in bed |
| **Prime Harvest Tap** | `E` | Tap when harvest cursor hits the green center zone for **PRIME** quality! |
| **Fast-Eat Fruit** | `1`, `2`, `3` | Bites carried fruit from satchel into stomach |
| **Skill 1 (Strike)** | `Q` | Casts 1st digesting fruit ability (e.g., Chain Lightning, Fireball, Ice Lance) |
| **Skill 2 (Burst)** | `R` | Casts 2nd digesting fruit ability (e.g., Thunderclap, Flame Wave, Tidal Push) |
| **Skill 3 (Ward)** | `T` | Casts 3rd digesting fruit ability (e.g., Frost Shell, Bubble Ward, Rekindle) |
| **Quickroot (Combat)**| `F` | Slings selected seed into combat to instantly sprout a temporary turret/hazard |
| **Open Satchel** | `I` or `B` | View carried fruit provisions and seed pouch |
| **Open Codex** | `C` | Browse the 32 launch species, elements, flavors, and hybrid breeding tree |

---

## Core Gameplay Systems

### 1. The Stomach & Digestion Terrarium (Bottom-Left HUD)
- **You are what you eat**: Skills exist only while their fruit is digesting.
- **Hero Bite Moment**: Taking a bite triggers a crisp crunch, elemental juice splash on screen, and the skill blooms onto your HUD.
- **Pairings & Clashes**:
  - `Storm` + `Tide` $\rightarrow$ **Conductive**: Lightning arcs through wet enemies for 1.5x damage!
  - `Ember` + `Gale` $\rightarrow$ **Fanned Flame**: Fire bursts unleash spreading flame vortexes!
  - `Frost` + `Ember` $\rightarrow$ **Indigestion**: Elemental clash dampens power by 25%!
  - `Lumen` + `Verdant` $\rightarrow$ **Sanctuary Bloom**: Defensive bursts emit continuous restorative mist.
- **Aura & Visuals**: Rootborn's body radiates the elemental color of whatever is currently digesting (violet sparks, molten embers, frosty mist).

### 2. The Orchard (Literal Skill Tree)
- **Plots & Soil**: Grid of garden plots with specific soil affinities (`Loam`, `Ash`, `Rime`, `Silt`, `Stormglass`, `Ley`).
- **Growth Stages**: `Seed` $\rightarrow$ `Sprout` $\rightarrow$ `Sapling` $\rightarrow$ `Young` $\rightarrow$ `Mature` $\rightarrow$ `Ancient`.
- **Tending**:
  - `Water`: speeds ripening and keeps roots healthy.
  - `Prune`: redirects growth to guarantee higher ripeness tiers.
  - `Harvest Mini-Game`: An oscillating timing cursor appears when picking ripe crops. Tapping within the green sweet-spot awards **PRIME** quality!
  - `Compost`: cleans windfall and fertilizes soil.

### 3. Quickroot: Battlefield Gardening
- Press **[F]** in combat to sling the selected seed from your pouch onto the ground.
- It instantly sprouts a living combat plant:
  - *Voltberry*: Lightning Rod zapping nearby foes every 1.5s.
  - *Cinderapple*: Fire Bloom launching explosive fireballs.
  - *Rimepear*: Glacial Spire chilling and freezing enemies.
  - *Briarcherry*: Thorn Barricade pinning enemies in place.
- **Strategic Choice**: Every seed spent in battle is one you didn't plant at home!

### 4. Day / Night Cycle & Night Raids
- **Morning**: Walk the orchard rows, prune, water, harvest prime fruit, and pack provisions.
- **Expedition**: Journey through the gate to explore wild groves, forage regional seeds, and plant permanent rest waystations.
- **Night Raid**: Poachers and Gnawer beasts invade the orchard targeting your ripe trees!
  - *Poachers that eat*: If a poacher reaches a ripe tree, they pick a fruit, **eat it on the spot**, and turn its skills against you! Catch them before they bite!
  - Defeating the raid secures your harvest and earns bonus Gold.

### 5. Economy & Village Companions
- **Market Stall**: Sell harvested fruits for Gold. Prices scale with ripeness and traits (e.g. *Sweet* sells for double).
- **Upgrades**: Purchase Land Plot Expansions, Tool Upgrades (+Damage & Reach), and Stomach Expansions (from 3 up to 8 slots).
- **Villager Companions**:
  - *Wren* (Watch / Rogue): Fast twin blades, alerts on night raids.
  - *Hesper* (Beekeeper / Support): Hives boost cross-pollination hybrid odds.
  - Recruit them to join your expedition party or leave them at home on guard duty!

---

## Project Structure

```
windfall/
├── scenes/
│   └── Windfall/
│       └── WindfallMain.tscn       # Main game scene
├── scripts/
│   └── Windfall/
│       ├── WindfallTypes.gd        # Enums, families, ripeness, colors
│       ├── FruitRegistry.gd        # 32 base species + hybrids registry
│       ├── SoundSynth.gd           # Procedural sound synthesizer (bites, spells, chimes)
│       ├── RootbornPlayer.gd       # Protagonist controller, digestion, tools, quickroot
│       ├── OrchardPlot2D.gd        # Garden plots, growth cycle, timing tap harvest
│       ├── PoacherEnemy2D.gd       # Night raid enemies that steal and eat fruit
│       ├── ElementalProjectile.gd  # Spells, chain lightning, fireballs, ice lances
│       ├── QuickrootSprout.gd      # Combat-planted living sprouts
│       ├── DayCycleManager.gd      # Morning -> Expedition -> Night Raid cycle
│       ├── MarketManager.gd        # Economy, selling crops, shop upgrades, pantry
│       ├── ExpeditionZone.gd       # Wild region exploration and wild planting
│       ├── MarketStallProp.gd      # Village shop prop
│       ├── BedProp.gd              # Farmhouse rest & day advance prop
│       ├── VillagerCompanion2D.gd  # NPC companions (Wren, Hesper)
│       ├── WindfallMain.gd         # Main game coordinator
│       └── UI/
│           └── WindfallHUD.gd      # Terrarium stomach, bars, bite splash, modals
└── project.godot                   # Configured with main scene & input maps
```

---

## Launching the Game

To run the game in Godot:
```bash
godot --path /Users/mikeparker/.gemini/antigravity/scratch/windfall
```
Or open the folder `/Users/mikeparker/.gemini/antigravity/scratch/windfall` directly in the Godot 4 Editor and press **F5** (Play Project).
