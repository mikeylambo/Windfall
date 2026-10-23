# WINDFALL: Image-generation prompt pack

Written after reviewing GPT batches 1–10. Read this before generating more art.

## Status (after the "New Batch Update")

| Item | Status |
|---|---|
| T1 logo | **In game** (`ui/logo`, title screen) |
| Batch 1 fruit + X1 hybrids | **In game**: all 37 species art, 128 px painted (Codex, satchel, stomach, market) |
| C1 Rootborn + P2/P3 | **Approved**: the canonical hero. Saved in `/art_reference/rootborn/` |
| C2 portraits | **Approved** (Rootborn, Wren, Hesper, Poacher, Reaper) in `/art_reference/portraits/`. Waiting on a dialogue-portrait feature |
| T2 title plates (day/night) | **Approved** in `/art_reference/title/`. Not wired in: the title is currently a live in-engine diorama |
| S1 trees via GPT | **Stopped: not viable.** See below |

### Why GPT can't do native sprites (the S1 test)
GPT doesn't honour a pixel grid: the "48×64 at 16 px per block" canopy came out about 68×90 blocks of irregular size,
the three-stage image changed scale and leaf style between stages, and it drew the canopy top-down, not 3/4.
Snapped to 48×64 it turns noisy and loses its silhouette. Every native sprite would need repainting by hand,
which costs more than drawing it. **Rule:** GPT does painted, non-grid art (logo, illustrations, portraits, key art).
Everything on the world grid goes to PixelLab or the code painters.

## What the existing batches are good for

The batches are concept sheets, not game assets. GPT draws "pixel-look" art at about 3–4× the game's real
pixel density, with soft edges and labels baked in, on a cream background. I test-downscaled them to the
real sprite sizes in `ART_SPEC.md`: characters (20×26) and fruit icons (16×16) turn to mush, and props
hold up only roughly.

| Batch | Verdict | Use |
|---|---|---|
| 1 Fruit sheets | **Keep: best batch** | Large Codex illustrations (cut out from the cards). Map 4 of the 5 per family to the 32 species. Too detailed for 16×16 icons |
| 2 Tree stages | Reference | Good per-family silhouettes. The trunks and canopies don't pair, and the game shares one trunk per stage |
| 3 UI kits | Reference | Layout and hierarchy target. Not sliceable (inconsistent bevels, wrong element names) |
| 4 Weather / props / decor / terrain | Reference, partly extractable | The big props (market stall, gate, well, shrine) can be cut out and cleaned up. Weather and terrain are mood references |
| 5 Logo + title + key art | **Keep the logo.** Title art: reference | The logo replaces the text logo on the title screen. The title painting has the menu baked in, so it needs a clean plate (prompt T2) |
| 5 FX sheets | Reference | Strong per-family FX language. Rebuild it at native size |
| 6 Wren, Reaper, Gnawer, Poacher | **Keep as the character bible** | Locked designs to feed PixelLab. Not drop-in: no roll, eat or cast rows, and frames drift |
| 7–10 Codex, village, FX, marketing | **Discard** | Off-model: Fire/Water/Earth/Air/Light/Dark/Nature instead of Windfall's 8 families, a human boy instead of the Rootborn, floating sky islands. Don't feed these back as references |

**What's missing:** the Rootborn itself. Every batch draws the protagonist differently (a deer-sprite, a
straw-hat boy, a caped boy). Lock it first (prompt C1).

## The tool split

| Job | Best tool | Why |
|---|---|---|
| Logo, title plate, Codex illustrations, portraits, store art | **GPT image** | High-res slots with no pixel grid. This is GPT's strength |
| Character sheets (20 rows × 4 frames, 3 directions) | **PixelLab** (pixellab.ai) | Native-res pixel art, rotations, consistent animation. Feed it the Batch 6 sheets |
| Trees, props, fruit icons, FX at native size | GPT (rules below) or PixelLab | GPT works if you force a coarse grid, then Claude Code snaps it to true pixels |
| Ground, 9-slice UI panels, particles | **Claude Code, in the painters** | Code-drawn. Use Batch 3 and 4 as the target. Faster and exact |

## Rules for every GPT prompt

1. **One asset per image.** No sheets, labels, titles, frames, cards or captions.
2. **Paste the Style Lock first** in every new chat, then attach 1–2 approved references (Batch 1 fruit,
   the Batch 5 logo, Batch 6 characters). Never attach batches 7–10.
3. **Backgrounds:** high-res art gets a *transparent background*. Native sprites get *flat solid #FF00FF
   magenta* (chroma key, safer than alpha for hard pixel edges).
4. **Native sprites:** ask for a visible coarse grid. For example, "a 48×64 pixel sprite, each pixel a hard
   square block 16 px wide, on a 768×1024 canvas, no anti-aliasing". Claude Code samples the block centres
   back to exact size and snaps the palette.
5. Save each file under the name in its prompt heading (e.g. `logo.png`), so integration is drag-and-drop.

### Style Lock (paste first, every chat)

```
WINDFALL style lock. Use for every image in this chat.
Game: a cozy-but-dangerous orchard RPG. Skills literally grow on trees: you eat elemental fruit to gain spells, and defend the orchard from poachers at night.
Look: storybook orchard fantasy pixel art. Warm, grounded, hand-made world (old wood, soil, stone, moss). Elemental magic is the only thing that glows.
Light from the top-left. Outlines are dark plum #2a1d27 with selective outlining, never pure black. Chunky readable shapes, limited palette, no gradients except glows.
The 8 elemental families. Use ONLY these names and hues, never fire/water/earth/air/light/dark/nature:
Storm #8a6cff violet crystal and branching arcs · Ember #ff5a24 molten cracks and flame · Frost #62dcf2 faceted ice and snow · Tide #2464d6 glassy water and droplets · Verdant #3cc046 leaves, vines and white blossoms · Gale #a6f0c8 pale mint swirls and petals · Umbra #b0457e plum-magenta shadow and drips · Lumen #ffd94a gold stars and radiance.
No floating islands, no sky castles, no humans in straw hats as the hero. The hero is the Rootborn (described when needed).
No text, labels, UI, borders or watermarks unless the prompt asks for them.
```

---

## Priority 1: high-res slots (GPT, do these first)

### T1 `logo.png`: title logo, transparent
Attach: Batch 5 logo sheet.
```
Re-render the large WINDFALL logo from the attached image exactly: same lettering, wooden plank, vines, white blossoms, red apple and "Skill-Tree Gardening" plank. Change only the background to fully transparent, with no cream paper, drop shadow or vignette. Centred, 2048×1024, crisp pixel-art edges.
```

### T2 `title_plate.png`: title background, no UI
Attach: the Batch 5 title screen.
```
Recreate the attached orchard title scene (farmhouse left, Frost tree and apple tree right, fence, lanterns, chicken, golden afternoon light) as a clean background plate: NO logo, NO buttons, NO text. Keep the centre-top third calm and low-detail (soft sky and distant hills) so a logo sits there, and keep the lower centre open (dirt path) for a vertical menu. 1920×1080, 16:9, pixel-art painting.
```
Also make `title_plate_night.png`: the same plate at night with lit windows, fireflies, moonlight and an Umbra-plum tint at the treeline.

### C1 `rootborn_concept.png`: lock the hero (most important)
```
Character concept turnaround for the Rootborn, Windfall's playable hero: a small sprout-folk orchard keeper. Bark-brown wooden skin. A rounded mop of moss-green leaf "hair" with a distinctive TWIN SPROUT (two curled leaves on a short stem) growing from the crown. This is the signature silhouette and must read at tiny sizes. Russet-red coat with ochre trim, wood-brown trousers, dark bark boots, a leather satchel on the right hip. Friendly, determined, slightly stubby proportions (about 3 heads tall). Show: front, back, right-side, and one 3/4 hero pose holding a pruning shears. Below them, a palette strip of 8–10 swatches. Transparent background, no text.
```
Then make `rootborn_p2` and `rootborn_p3` with the same prompt, plus:
"Co-op variant: identical silhouette, coat recoloured to deep teal with cream trim" (P2) and
"…to plum with gold trim" (P3).

### C2 `portrait_<name>.png`: dialogue portraits (optional new feature)
One image per character (rootborn, wren, hesper, poacher, reaper). Attach the matching Batch 6 sheet.
```
Bust portrait of [NAME] matching the attached design exactly, for a dialogue box. Head and shoulders, 3/4 facing right, neutral-friendly expression, 512×512, transparent background, pixel-art painting style with plum outlines, no frame, no text.
```
Hesper isn't in Batch 6: *round, warm beekeeper in an ochre coat with cream trim and a wide-brimmed bee hat with a pulled-back net, a honey dipper at the belt, kind eyes.*

### X1 `codex/<species_id>.png`: Codex illustrations
Batch 1 already covers the 32 base species. Claude Code can cut them out. Generate only the **5 hybrids**,
one per image. Attach the Batch 1 sheet.
```
One fruit illustration in exactly the style of the attached sheet: [HYBRID] — [DESCRIPTION]. Single fruit with a stem and leaves, centred, 512×512, transparent background, no card, no label.
```
| species_id | Description |
|---|---|
| `plasma_plum` | Storm × Ember: a violet plum with molten orange cracks and arcing sparks |
| `glacier_gourd` | Frost × Tide: a faceted ice gourd with water sloshing inside, dripping |
| `wraith_kiwi` | Tide × Umbra: a fuzzy plum-black kiwi wreathed in drifting mist, a pale ghost glow |
| `halo_thorns` | Verdant × Lumen: a thorny green berry cluster circled by a golden halo |
| `forgefruit` | Ember × Verdant: an iron-dark seed pod split open to show an ember core, with vines |

---

## Priority 2: native-size sprites → PixelLab, not GPT

The S1/S4 GPT prompts below are kept for reference only. Do them in **PixelLab** instead, using its
"style reference" with the approved art: canopy prompt → *Create image*, 48×64 canvas,
"3/4 top-down orchard tree canopy, no trunk", family SHAPE from the table, palette lock on.
Make the Storm canopy first, then reuse it as the style reference for the other 7 so they match.

### S1 `trees/canopy_5_<fam>.png`: mature canopies (do Storm `0` first as the test)
```
Pixel-art sprite: the MATURE canopy of a [FAMILY] orchard tree, canopy layer only (no trunk), seen 3/4 top-down. Exactly 48×64 pixels, each pixel drawn as a hard square block 16 px wide on a 768×1024 canvas, with no anti-aliasing and no soft edges. Compact rounded orchard-tree crown filling the upper 2/3. Leave the bottom 20 px empty where the trunk shows through. Silhouette must read as [FAMILY] without colour: [SHAPE]. Max 12 colours, plum #2a1d27 outline, light from the top-left. Flat solid #FF00FF background.
```
| fam | FAMILY | SHAPE |
|---|---|---|
| 0 | Storm | jagged crown split by angular gaps, violet crystals poking through |
| 1 | Ember | upward flame-tongue lobes, hot orange underside |
| 2 | Frost | faceted crystalline crown, hard angles, frosted tips |
| 3 | Tide | weeping willow drape with cascading droplets |
| 4 | Verdant | lush round crown with white blossoms and a trailing vine |
| 5 | Gale | crown swept sideways by the wind, swirl-tipped |
| 6 | Umbra | drooping hood-like crown with dripping plum tendrils |
| 7 | Lumen | radiant fan-shaped crown with star-shaped leaf clusters |

Once the mature canopy is approved, ask: *"Same tree at stage [Sapling / Young / Ancient]: same family shapes,
scaled to [40% / 70% / 110%] of the canvas, same 48×64 grid."*

### S2 `characters/*.png`: use PixelLab, not GPT
In PixelLab, create each character from the C1 concept or the Batch 6 sheet at **40×52** canvas (20×26 art
scaled ×2, or work at 20×26 and export ×2). Produce down, up and right views and these animations, then
send the frames to Claude Code to pack into the 4×20 sheet:

idle 2 · walk 4 · attack 3 (anticipation, strike, follow-through, with no tool in hand; the tool is a separate sprite) ·
roll 4 (direction-agnostic tuck) · eat 2 · cast 2 (arms up) · hurt 1 · collapse 2 (enemies). Feet at pixel (20, 50).

### S3 `icons/species/<id>.png`: fruit icons
16×16 texels is below what GPT can hold. Pick one:
- **(Recommended)** Claude Code switches species icons to 48×48 **true-resolution** art made from the
  Batch 1 and X1 illustrations. Fast, and they read beautifully in the satchel and stomach.
- PixelLab at 16×16 from the same references.

### S4 `props/*.png`: hero props
Claude Code can cut the Batch 4 props out and clean them up. Only regenerate the farmhouse (it isn't in
Batch 4):
```
Pixel-art sprite: Windfall farmhouse, 3/4 top-down. Exactly 104×100 pixels, each pixel a hard 8 px block on an 832×800 canvas, no anti-aliasing. Two-storey timber cottage, red clay tile roof, stone chimney with a stone base, cream plaster walls with wood beams, flower boxes, a round-top wooden door centred at the bottom. Plum #2a1d27 outline, light from the top-left, max 20 colours. Flat #FF00FF background.
```

---

## Hand-off to Claude Code

Drop new files into `windfall/assets/art/_incoming/` (any names) and say *"integrate the incoming art"*.
Claude Code will key out the background, snap to the grid and palette, crop and anchor to `ART_SPEC.md`,
then wire in any new slots (logo, Codex illustrations, portraits), and check it all in-game.
