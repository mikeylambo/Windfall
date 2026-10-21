# WINDFALL Art Spec

Every sprite in the game is loaded by **stable name** through one registry, the `Art` autoload
(`autoload/ProceduralSprites.gd`), as `Art.tex("<folder>/<name>")`, which maps to `res://assets/art/<folder>/<name>.png`.
No gameplay script draws art inline. **To reskin the game, replace a PNG with one of the same
size and layout. No code changes are needed.** Then run `godot --headless --import`.

The current PNGs are baked from code painters (`scripts/Windfall/Art/`) by `tools/bake_art.gd`.
If you hand-edit or replace a sheet, **don't rebake that group** (`-- only=<group>`) or your file is overwritten.

## Global conventions

| Rule | Value |
|---|---|
| Texel density | 16 px tiles. **World art is stored at 2×** (1 art texel = 2×2 PNG pixels = 2 world px) |
| UI / icons | stored at **3×** (1 texel = 3×3 PNG pixels) |
| Camera | 2× zoom in play (4 screen px per texel), 1.5× when framing the homestead (3 px) |
| Filtering | nearest (project default). No mipmaps |
| Light | from the top-left. Outlines are dark plum `#2a1d27` sel-out, never pure black |
| Palette | `scripts/Windfall/Art/WPal.gd`. Element signature hues are listed below |
| Anchor | world sprites are placed by their **feet / base-centre**. See each sheet's anchor |

Element hues: Storm `#8a6cff` · Ember `#ff5a24` · Frost `#62dcf2` · Tide `#2464d6` · Verdant `#3cc046` · Gale `#a6f0c8` · Umbra `#b0457e` · Lumen `#ffd94a`.
Family index order everywhere: 0 Storm, 1 Ember, 2 Frost, 3 Tide, 4 Verdant, 5 Gale, 6 Umbra, 7 Lumen.

## Character sheets: `characters/*.png`

`rootborn`, `rootborn_p2`, `rootborn_p3`, `wren`, `hesper`, `poacher`, `reaper` (Reaping Elite, drawn at 1.5×) and `gnawer` all share one layout:

* Frame: **20×26 texels → 40×52 px**. Sheet: **4 columns × 20 rows** (160×1040 px).
* Anchor (feet): frame pixel **(20, 50)**.
* Facing: `down`, `up`, `side`. **Side faces right**; left is drawn with `flip_h`.
* Unused cells are transparent.

| Rows | Animation | Frames | Notes |
|---|---|---|---|
| 0–2 | idle (down, up, side) | 2 | breathing bob |
| 3–5 | walk | 4 | contact / pass / contact / pass |
| 6–8 | attack | 3 | anticipation, strike, follow-through. The tool is a separate sprite |
| 9 | roll | 4 | direction-agnostic tuck spin |
| 10–12 | eat | 2 | chew |
| 13–15 | cast | 2 | arms up |
| 16–18 | hurt | 1 | |
| 19 | collapse | 2 | knocked back, then down (enemies) |

Row/frame counts are defined once, in `Art.ROWS` / `Art.ROW_FRAMES`.

## Trees: `trees/`

* `trunk_<stage>` and `canopy_<stage>_<family>`: **48×64 texels → 96×128 px**, base anchor **(48, 120)**.
  Stages: 1 Seed, 2 Sprout, 3 Sapling, 4 Young, 5 Mature, 6 Ancient (trunks exist for 3–6).
  The canopy is a separate layer so it can sway, and fruit rides on it.
* `fruit_<family>`: **4 frames of 8×9 texels** in a row (64×18 px): rest, then a 3-frame glint. Centered.
* Fruit attach points per stage are in `OrchardPlot2D.FRUIT_SPOTS`.

## World: `world/`

* `ground`: the whole map at **1 px per texel** (1280×768), drawn at 2× scale. It's laid out from `WorldLayout.gd`.
* `soil_<soil>` / `soil_<soil>_wet`: raised bed, **40×30 texels → 80×60 px**, centered on the plot.
  Soil order: 0 Loam, 1 Ash, 2 Rime, 3 Silt, 4 Stormglass, 5 Ley.

## Props: `props/`

Single sprites anchored at base-centre (bottom-middle), except `shadow_*`, which are centered.
`farmhouse_windows` is an additive night-glow mask with the same canvas as `farmhouse`.
`overgrown_plot` (locked land) replaces the soil bed, so it uses the same centred anchor. `waystation_shrine` is anchored at (42, 88) px.

## Icons: `icons/` (UI, 3×)

16×16 texels → **48×48 px**: tools `tool_0..4` (Shears, Scythe, Hoe-Staff, Sling, Watering Can),
`element_<fam>`, `seed_<fam>`, `fruit_<fam>` (family fallback), `season_0..3`, plus misc HUD icons.
`icons/species/<species_id>`: one per species (Codex, satchel, stomach, market). The species id must match `FruitRegistry`.

## UI: `ui/` (3×, 9-slice)

| Name | Texels | 9-slice margin (px) |
|---|---|---|
| `panel_wood`, `panel_vine` | 24×24 | 21 |
| `panel_paper`, `panel_dark` | 12×12 | 12 |
| `button_0..3` (normal / hover / pressed / disabled) | 16×12 | 12 |
| `slot_0..3` | 20×20 | 15 |
| `bar_frame` / `bar_hp`, `bar_stamina`, `bar_gold` | 32×8 / 4×6 | 9 |
| `ring`, `ring_bg` (radial progress) | 24×24 | |
| `jar` | 40×40 | 30 |
| `keycap`, `chip` | 12×12, 12×10 | 9 |
| `harvest_bar`, `harvest_cursor`, `focus`, `bubble`, `hp_world_*` | world-space, 2× | |
| `vignette` | 256×256 soft alpha | |

Theme wiring lives in `scripts/Windfall/UI/UITheme.gd`, saved to `assets/ui/windfall_theme.tres`.

## FX: `fx/` (2×)

* `glow`: smooth 64×64 radial alpha, used additively for all lights. Intentionally not pixelated.
* `dust`, `smoke` (4 frames), `poof` (5 frames), `sparkle` (4 frames), `butterfly` (2 frames): horizontal strips.
* `slash_0..2`: 3 frames of 40×40 texels, drawn facing right.
* `proj_<fam>`: 16×16 texels, facing right. `quickroot_<fam>`: 24×28 texels, base (24, 52) px.
* `blight`: speckle overlay on the same 48×64 canvas as the tree canopies. `petal`, `snowflake`, `leaf`, `dot`: seasonal weather.
* `ring`, `ground_ring`, `spark`, `shard`, `leaf`, `dot`, `dot4`: particle textures. Particles are tinted at runtime, so keep them white or neutral.

Not art (by design): chain-lightning bolts are `Line2D` geometry, and fades/menu dims are solid palette colours.

## Full file list (current sizes in PNG pixels)

| File | Size |
|---|---|
| `characters/gnawer` | 160×1040 |
| `characters/hesper` | 160×1040 |
| `characters/poacher` | 160×1040 |
| `characters/reaper` | 160×1040 |
| `characters/rootborn` | 160×1040 |
| `characters/rootborn_p2` | 160×1040 |
| `characters/rootborn_p3` | 160×1040 |
| `characters/wren` | 160×1040 |
| `trees/canopy_1_0` | 96×128 |
| `trees/canopy_1_1` | 96×128 |
| `trees/canopy_1_2` | 96×128 |
| `trees/canopy_1_3` | 96×128 |
| `trees/canopy_1_4` | 96×128 |
| `trees/canopy_1_5` | 96×128 |
| `trees/canopy_1_6` | 96×128 |
| `trees/canopy_1_7` | 96×128 |
| `trees/canopy_2_0` | 96×128 |
| `trees/canopy_2_1` | 96×128 |
| `trees/canopy_2_2` | 96×128 |
| `trees/canopy_2_3` | 96×128 |
| `trees/canopy_2_4` | 96×128 |
| `trees/canopy_2_5` | 96×128 |
| `trees/canopy_2_6` | 96×128 |
| `trees/canopy_2_7` | 96×128 |
| `trees/canopy_3_0` | 96×128 |
| `trees/canopy_3_1` | 96×128 |
| `trees/canopy_3_2` | 96×128 |
| `trees/canopy_3_3` | 96×128 |
| `trees/canopy_3_4` | 96×128 |
| `trees/canopy_3_5` | 96×128 |
| `trees/canopy_3_6` | 96×128 |
| `trees/canopy_3_7` | 96×128 |
| `trees/canopy_4_0` | 96×128 |
| `trees/canopy_4_1` | 96×128 |
| `trees/canopy_4_2` | 96×128 |
| `trees/canopy_4_3` | 96×128 |
| `trees/canopy_4_4` | 96×128 |
| `trees/canopy_4_5` | 96×128 |
| `trees/canopy_4_6` | 96×128 |
| `trees/canopy_4_7` | 96×128 |
| `trees/canopy_5_0` | 96×128 |
| `trees/canopy_5_1` | 96×128 |
| `trees/canopy_5_2` | 96×128 |
| `trees/canopy_5_3` | 96×128 |
| `trees/canopy_5_4` | 96×128 |
| `trees/canopy_5_5` | 96×128 |
| `trees/canopy_5_6` | 96×128 |
| `trees/canopy_5_7` | 96×128 |
| `trees/canopy_6_0` | 96×128 |
| `trees/canopy_6_1` | 96×128 |
| `trees/canopy_6_2` | 96×128 |
| `trees/canopy_6_3` | 96×128 |
| `trees/canopy_6_4` | 96×128 |
| `trees/canopy_6_5` | 96×128 |
| `trees/canopy_6_6` | 96×128 |
| `trees/canopy_6_7` | 96×128 |
| `trees/fruit_0` | 64×18 |
| `trees/fruit_1` | 64×18 |
| `trees/fruit_2` | 64×18 |
| `trees/fruit_3` | 64×18 |
| `trees/fruit_4` | 64×18 |
| `trees/fruit_5` | 64×18 |
| `trees/fruit_6` | 64×18 |
| `trees/fruit_7` | 64×18 |
| `trees/trunk_3` | 96×128 |
| `trees/trunk_4` | 96×128 |
| `trees/trunk_5` | 96×128 |
| `trees/trunk_6` | 96×128 |
| `world/ground` | 1280×768 |
| `world/soil_0` | 80×60 |
| `world/soil_0_wet` | 80×60 |
| `world/soil_1` | 80×60 |
| `world/soil_1_wet` | 80×60 |
| `world/soil_2` | 80×60 |
| `world/soil_2_wet` | 80×60 |
| `world/soil_3` | 80×60 |
| `world/soil_3_wet` | 80×60 |
| `world/soil_4` | 80×60 |
| `world/soil_4_wet` | 80×60 |
| `world/soil_5` | 80×60 |
| `world/soil_5_wet` | 80×60 |
| `props/barrel` | 28×36 |
| `props/beehive` | 32×40 |
| `props/border_tree_0` | 80×116 |
| `props/border_tree_1` | 80×116 |
| `props/border_tree_2` | 80×116 |
| `props/border_tree_3` | 80×116 |
| `props/bush_0` | 32×24 |
| `props/bush_1` | 32×24 |
| `props/bush_2` | 32×24 |
| `props/bush_3` | 32×24 |
| `props/compost_bin` | 52×48 |
| `props/crate` | 32×32 |
| `props/farmhouse` | 208×200 |
| `props/farmhouse_windows` | 208×200 |
| `props/fence_h` | 32×28 |
| `props/fence_post` | 12×32 |
| `props/flowers_0` | 44×28 |
| `props/flowers_1` | 44×28 |
| `props/flowers_2` | 44×28 |
| `props/flowers_3` | 44×28 |
| `props/gate` | 96×92 |
| `props/hedge_0` | 40×36 |
| `props/hedge_1` | 40×36 |
| `props/hedge_2` | 40×36 |
| `props/hedge_3` | 40×36 |
| `props/lantern` | 20×52 |
| `props/market_stall` | 128×116 |
| `props/overgrown_plot` | 80×68 |
| `props/reeds` | 24×32 |
| `props/rock_0` | 28×20 |
| `props/rock_1` | 28×20 |
| `props/rock_2` | 28×20 |
| `props/rock_3` | 28×20 |
| `props/scarecrow` | 52×84 |
| `props/shadow_large` | 92×36 |
| `props/shadow_medium` | 52×24 |
| `props/shadow_small` | 32×16 |
| `props/stump` | 32×24 |
| `props/waystation_ring` | 84×52 |
| `props/waystation_shrine` | 84×100 |
| `props/well` | 60×76 |
| `icons/bolt` | 48×48 |
| `icons/codex` | 48×48 |
| `icons/coin` | 48×48 |
| `icons/element_0` | 48×48 |
| `icons/element_1` | 48×48 |
| `icons/element_2` | 48×48 |
| `icons/element_3` | 48×48 |
| `icons/element_4` | 48×48 |
| `icons/element_5` | 48×48 |
| `icons/element_6` | 48×48 |
| `icons/element_7` | 48×48 |
| `icons/fruit_0` | 48×48 |
| `icons/fruit_1` | 48×48 |
| `icons/fruit_2` | 48×48 |
| `icons/fruit_3` | 48×48 |
| `icons/fruit_4` | 48×48 |
| `icons/fruit_5` | 48×48 |
| `icons/fruit_6` | 48×48 |
| `icons/fruit_7` | 48×48 |
| `icons/heart` | 48×48 |
| `icons/lock` | 48×48 |
| `icons/moon` | 48×48 |
| `icons/satchel` | 48×48 |
| `icons/season_0` | 48×48 |
| `icons/season_1` | 48×48 |
| `icons/season_2` | 48×48 |
| `icons/season_3` | 48×48 |
| `icons/seed_0` | 48×48 |
| `icons/seed_1` | 48×48 |
| `icons/seed_2` | 48×48 |
| `icons/seed_3` | 48×48 |
| `icons/seed_4` | 48×48 |
| `icons/seed_5` | 48×48 |
| `icons/seed_6` | 48×48 |
| `icons/seed_7` | 48×48 |
| `icons/skull` | 48×48 |
| `icons/star` | 48×48 |
| `icons/stomach` | 48×48 |
| `icons/sun` | 48×48 |
| `icons/sunset` | 48×48 |
| `icons/tool_0` | 48×48 |
| `icons/tool_1` | 48×48 |
| `icons/tool_2` | 48×48 |
| `icons/tool_3` | 48×48 |
| `icons/tool_4` | 48×48 |
| `icons/species/ashdate` | 48×48 |
| `icons/species/bramblequince` | 48×48 |
| `icons/species/briarcherry` | 48×48 |
| `icons/species/brinemelon` | 48×48 |
| `icons/species/cinderapple` | 48×48 |
| `icons/species/coral_fig` | 48×48 |
| `icons/species/cyclone_citrus` | 48×48 |
| `icons/species/dawnpeach` | 48×48 |
| `icons/species/duskberry` | 48×48 |
| `icons/species/eclipse_cherry` | 48×48 |
| `icons/species/featherfig` | 48×48 |
| `icons/species/forgefruit` | 48×48 |
| `icons/species/glacier_gourd` | 48×48 |
| `icons/species/glacier_grape` | 48×48 |
| `icons/species/halo_apricot` | 48×48 |
| `icons/species/halo_thorns` | 48×48 |
| `icons/species/hollow_fig` | 48×48 |
| `icons/species/icicle_plum` | 48×48 |
| `icons/species/ironnut` | 48×48 |
| `icons/species/lumen_lychee` | 48×48 |
| `icons/species/mistlime` | 48×48 |
| `icons/species/nightplum` | 48×48 |
| `icons/species/phoenix_pomegranate` | 48×48 |
| `icons/species/plasma_plum` | 48×48 |
| `icons/species/rimepear` | 48×48 |
| `icons/species/riptide_mango` | 48×48 |
| `icons/species/scorchpeach` | 48×48 |
| `icons/species/snowquince` | 48×48 |
| `icons/species/sparkfig` | 48×48 |
| `icons/species/squall_berry` | 48×48 |
| `icons/species/starfruit` | 48×48 |
| `icons/species/stormglass_lemon` | 48×48 |
| `icons/species/thunderplum` | 48×48 |
| `icons/species/vine_apple` | 48×48 |
| `icons/species/voltberry` | 48×48 |
| `icons/species/wraith_kiwi` | 48×48 |
| `icons/species/zephyr_kiwi` | 48×48 |
| `ui/bar_frame` | 96×24 |
| `ui/bar_gold` | 12×18 |
| `ui/bar_hp` | 12×18 |
| `ui/bar_stamina` | 12×18 |
| `ui/bubble` | 28×28 |
| `ui/button_0` | 48×36 |
| `ui/button_1` | 48×36 |
| `ui/button_2` | 48×36 |
| `ui/button_3` | 48×36 |
| `ui/chip` | 36×30 |
| `ui/focus` | 32×32 |
| `ui/harvest_bar` | 100×20 |
| `ui/harvest_cursor` | 10×28 |
| `ui/hp_world_fill` | 24×4 |
| `ui/hp_world_frame` | 28×8 |
| `ui/jar` | 120×120 |
| `ui/keycap` | 36×36 |
| `ui/panel_dark` | 36×36 |
| `ui/panel_paper` | 36×36 |
| `ui/panel_vine` | 72×72 |
| `ui/panel_wood` | 72×72 |
| `ui/ring` | 72×72 |
| `ui/ring_bg` | 72×72 |
| `ui/slot_0` | 60×60 |
| `ui/slot_1` | 60×60 |
| `ui/slot_2` | 60×60 |
| `ui/slot_3` | 60×60 |
| `ui/vignette` | 256×256 |
| `fx/blight` | 96×128 |
| `fx/butterfly` | 28×10 |
| `fx/dot` | 4×4 |
| `fx/dot4` | 8×8 |
| `fx/dust` | 80×20 |
| `fx/glow` | 64×64 |
| `fx/ground_ring` | 52×24 |
| `fx/leaf` | 10×8 |
| `fx/petal` | 8×6 |
| `fx/pixel_glow` | 64×64 |
| `fx/poof` | 240×48 |
| `fx/proj_0` | 32×32 |
| `fx/proj_1` | 32×32 |
| `fx/proj_2` | 32×32 |
| `fx/proj_3` | 32×32 |
| `fx/proj_4` | 32×32 |
| `fx/proj_5` | 32×32 |
| `fx/proj_6` | 32×32 |
| `fx/proj_7` | 32×32 |
| `fx/quickroot_0` | 48×56 |
| `fx/quickroot_1` | 48×56 |
| `fx/quickroot_2` | 48×56 |
| `fx/quickroot_3` | 48×56 |
| `fx/quickroot_4` | 48×56 |
| `fx/quickroot_5` | 48×56 |
| `fx/quickroot_6` | 48×56 |
| `fx/quickroot_7` | 48×56 |
| `fx/ring` | 64×64 |
| `fx/shard` | 8×12 |
| `fx/slash_0` | 240×80 |
| `fx/slash_1` | 240×80 |
| `fx/slash_2` | 240×80 |
| `fx/smoke` | 96×24 |
| `fx/snowflake` | 6×6 |
| `fx/spark` | 10×10 |
| `fx/sparkle` | 56×14 |
