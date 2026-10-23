# WINDFALL: Skill-Tree Gardening (Godot 4.6, GL Compatibility)

You inherit a dying orchard, and your skills literally grow on trees. Tend by day, forage the wilds in the afternoon, and defend your ripe fruit from poachers at night. Eat a Voltberry and you have chain lightning.

## Run

Open this folder in **Godot 4.6** and press **F5** (or `godot --path .` from this directory). It boots to the title screen.

## Controls

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | WASD / Arrows | Left stick |
| Tool attack | J / Left click | X |
| Dodge roll (i-frames) | Shift / K / Right click | B |
| Interact · harvest tap · talk · sleep | E | A |
| Cycle tool | Tab | Y |
| Eat satchel fruit 1 · 2 · 3 | 1 · 2 · 3 | D-pad ← · L3 · D-pad → |
| Fruit skills 1 · 2 · 3 | Q · R · T | LB · RB · RT |
| Quickroot (sling seed) | F | LT |
| Satchel · Codex | I · C | Back · R3 |
| Pause | Esc | Start |

**Co-op (local, up to 3):** P1 plays on keyboard/mouse plus the first gamepad. Press **Start on any other gamepad** to drop in as P2 or P3. The satchel, seeds and gold are shared; stomachs, tools and cooldowns are per player. The camera frames everyone.

**Village party:** talk to **Wren** or **Hesper** to bring them along or send them home.

- **Wren in the party:** fights with twin blades. **On watch at home:** calls out raids and defends the orchard.
- **Hesper in the party:** heals the nearest Rootborn. **Tending the hives at home:** +20% spring hybrid odds.

**Online co-op:** Title → **Online Co-op**. One player chooses **Host a Game**, and friends choose **Join** with the host's IP (port **7777**, UDP). On a LAN this just works. Over the internet, the host forwards UDP 7777 or everyone joins a VPN such as Tailscale. The host's save is the shared world.

**Orchard life:**
- **Seasons** change the rules every 7 days.
- **Blight** hits neglected trees. Cure it with compost (windfall fruit → compost bin → Hoe-Staff on the tree).
- Clear **overgrown land** to expand to 9 plots.
- Plant **waystations** in the wilds.
- **Gift** villagers their loved flavours.
- Survive the **Reaping Elite** every 7th night.

All menus are fully keyboard and gamepad navigable (arrows/WASD/D-pad + E/Enter/A, Esc/B to close).

## The day loop

1. **Morning**: water, prune, and harvest. Tap **E** while the cursor is in the gold zone for **PRIME** fruit.
2. **Expedition**: take the **east gate** to forage the wilds.
3. **Dusk**: return through the gate and the **Night Raid** begins. Poachers eat stolen fruit and turn its skill on you.
4. **Sleep** at the farmhouse door once the raid is cleared. The game **autosaves** each morning. Use **Continue** on the title screen to resume.

## Project layout

```
scenes/UI/TitleScreen.tscn         entry point
scenes/Windfall/WindfallMain.tscn  the game
scripts/Windfall/                  gameplay (player, plots, enemies, day cycle, market…)
scripts/Windfall/Art/              pixel-art painters (code-drawn sprites)
scripts/Windfall/World/            WorldLayout (map data), WorldDresser, DayLighting
scripts/Windfall/UI/               HUD, menus, theme builder
scripts/Windfall/FX/WFX.gd         FX autoload: particles, popups, glows, lightning
autoload/ProceduralSprites.gd      `Art` autoload: texture catalog for the baked sheets
assets/art/                        baked PNG sprite sheets (edit freely in Aseprite)
assets/ui/windfall_theme.tres      the shared UI Theme
tools/                             bake + automated playtest scripts (excluded from exports)
```

## Art pipeline

Every sprite is loaded by a stable name through the `Art` autoload. Swap any PNG for one with the same layout and nothing else needs to change. The layout of every sheet is documented in `assets/art/ART_SPEC.md`.


All art is hand-authored pixel art written as code: palette in `WPal.gd`, painters in `scripts/Windfall/Art/`. It is baked to PNG sheets at 1 texel = 2 world px (UI at 3 px).

```
godot --headless -s res://tools/bake_art.gd                 # rebake everything
godot --headless -s res://tools/bake_art.gd -- only=trees   # one group
godot --headless --import && godot --headless -s res://tools/bake_art.gd -- only=theme
```

You can also paint over any PNG in `assets/art/` directly; just don't rebake that group afterwards.

## Automated playtest

`tools/playtest_runner.gd` plays a full loop: title, tutorial, PRIME harvest, combo, expedition, raid, sleep, autosave, Continue. It asserts each step and writes the screenshots in `/screenshots`. It needs a display:

```
xvfb-run godot --rendering-driver opengl3 --resolution 1280x720 -s res://tools/playtest_runner.gd
```

## Online smoke test

`tools/net_test.sh` launches a host and a client headless over localhost and checks that snapshots and intents flow.

## Export

Presets for **macOS** (universal, ad-hoc signed) and **Web** (single-threaded, so it hosts anywhere, including itch.io) are in `export_presets.cfg`. Output goes to `../build/`.
