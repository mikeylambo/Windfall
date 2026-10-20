# Changelog

## 1.0 playtest: production polish pass

### Art & world
- New pixel-art pipeline: a shared palette and painters with lit-sphere shading, ordered dither and selective outlines, baked to editable PNG sheets.
- Characters: Rootborn (idle/walk/attack/roll/eat/cast/hurt × 4 directions), Wren, Hesper, Poacher, Gnawer (walk/steal/eat/death).
- Trees: six distinct growth stages, with leaves tinted per element, a unique fruit silhouette per element, ripe glints, Ancient glow, and wind sway.
- Soil beds for all six affinities (dry and wet). Watered plots sparkle.
- Map rebuilt from a single `WorldLayout`: soft-edged paths, pond, fenced orchard, hedged farmyard, forest border on all edges (the grey strip is gone), wilds to the east, lanterns, hives, clutter, camera limits.
- Farmhouse with chimney smoke and lit windows at night. Market stall with awning, crates and fruit baskets.
- Y-sorting everywhere, plus blob shadows.
- Gradient day cycle (dawn, noon, golden hour, dusk, night) with unlit additive glows on lanterns, windows, auras, spells, quickroots and Ancient trees.

### Feel
- Bite moment: crunch-squelch-chime SFX, hit-pause, screen juice splash, camera punch, element burst, and the skill blooming into its stomach slot.
- Combat: hit-flash shader, real knockback, damage numbers (crits bigger and gold), trauma screen shake via CameraFX, death collapse plus poof.
- Per-element particle signatures. Chain lightning draws branching bolts between targets.
- Harvest timing bar with a gold PRIME burst, chime and popup.
- Movement accel/decel, run and roll dust, i-frame flicker, digestion afterimage trail with a tri-colour rim glow.
- Audio rebuilt in 16-bit with cached sounds and pitch variation, a bird/breeze day bed, a cricket night bed, and a raid sting.

### UI
- One shared Theme: Pixelify Sans and Silkscreen, 9-slice wood/vine/paper panels, button and slot skins.
- HUD: HP/stamina bars with damage ghosting, clock/season/phase/gold chips, raid counter, quest tracker, stomach terrarium with radial digestion rings and pairing chips, tool/quickroot panel, snack bar, interaction prompts, toasts, banners.
- Menus: Satchel, Codex (collection grid with silhouettes, plus the hybrid tree), Market (sell/seeds/upgrades), Pause, Settings. Full keyboard and gamepad support.
- Title screen with a live orchard diorama. New / Continue / Settings / Quit.
- First-day tutorial through QuestManager and DialogueManager: water → harvest → eat → cast → survive the raid.

### Gameplay fixes found along the way
- Poacher spells could never hit the player. They now do.
- The Conductive (Storm + Tide) bonus never triggered. It now works.
- Knockback was overwritten every frame. It now applies.
- Camera shake was silently inactive. It's now hooked up.
- The tool upgrade now actually raises damage.
- Interaction targets the nearest object instead of whichever was entered last.
- Day loop is explicit: gate → expedition, gate → raid, door → sleep.

### Structure
- Removed AdventureDemo, InteriorHouse, scenes/Test, scenes/Units and their scripts, the template PauseMenu, `addons/godot_mcp`, and the duplicate `CameraManager` (CameraFX kept).
- Windfall emits through EventBus (damage, defeats, abilities).
- Save via the SaveManager provider: orchard, satchel, seeds, gold, upgrades, day/season, Codex discoveries, party, tutorial.
- Export presets for macOS and Web.
