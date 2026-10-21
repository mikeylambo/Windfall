# Changelog

## 1.1 playtest: Pass 2 (readability, framing, GDD alignment)

### Readability
- **New fonts:** Jersey 10 for body/HUD and Jersey 15 for display. The 5 no longer reads as S. Antialiasing and hinting are off, and every size snaps to the font's pixel grid through `UITheme.body_px` / `display_px` / `world_px`. Set once in the shared Theme. Minimum UI text size is now 20 px.
- **Raid:** projectile glow down about 50%, impact flashes halved, additive particles about 60% dimmer, and smaller bolt cores.
- **Enemy rims:** Poachers and Gnawers get a warm 1px rim that strengthens at night (ember for Poachers, amber for Gnawers).
- **Player at night:** a soft cream outline and a ground ring tinted by your digesting element.
- **Stomach:** Q/R/T are now keycap chips tinted by the digesting fruit's element.
- **Banners:** a dark backing plate for contrast. Enemy HP bars are baked sprites.

### Camera & world
- Homestead re-laid out so the farmhouse and all six plots fit one frame.
- New **CameraRig:** eases to a 1.5× homestead frame during Morning Tending, plays at 2×, leads gently in the movement direction, clamps to the map, and frames every co-op player.
- Negative space filled: scarecrow, well, flower patches, crates, butterflies by day and fireflies by night.

### Codex
- **37 unique species icons** (about 20 fruit silhouettes × element colour, with two-tone hybrids) used across the Codex, satchel, stomach and market.
- Undiscovered species render as a dark silhouette with a faint outline. Undiscovered hybrids show their parents with a "?".
- The detail pane shows mastery % and Rooted status.

### Gameplay built from the audit
- **Local co-op for 3** (drop-in by gamepad), with an input-intent layer and a `NetworkInput` seam for online later.
- **Village party roles:** Wren fights or keeps watch; Hesper heals or tends the hives (+20% hybrid odds). Party companions travel with you, and a roster chip shows on the HUD.
- **Pairings now do something:**
  - Conductive arcs through anything.
  - Fanned Flame widens Ember explosions and spreads burn.
  - Sanctuary regenerates 5 HP/s.
  - Phantom Mist dodges 30% of hits.
  - Indigestion now also weakens spells.
- **Hybrids are harvestable:** a grafted tree shows a glowing hybrid fruit, and picking it yields the hybrid ("HYBRID!").
- **Mastery → Rooted skills** (up to 4): rooted species digest 25% slower. Saved.
- **Pantry tab** in the Market: Juice, Dry, and two-element Jams that pair by themselves. Preserved forms survive save/load.

### Art pipeline
- No art is drawn inline in gameplay scripts. Everything comes through `Art.tex(name)`.
- `assets/art/ART_SPEC.md` documents every sheet: frame sizes, rows, animation order, anchors and the 9-slice margins.

### Fixes
- Chain-lightning bolts no longer spawn inside a physics callback (engine error).
- Poachers, villagers and drops now use the nearest player, not player 1.

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
