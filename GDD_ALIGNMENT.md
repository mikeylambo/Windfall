# WINDFALL: GDD alignment (Pass 2)

> **Note:** `GDD.md` was not in the repository when this pass ran (it isn't on `main` or the working branch).
> This audit compares the build against the features stated in the original `README_WINDFALL.md` and the two
> production briefs, including the two gaps the brief called out explicitly (co-op, village party).
> Commit `GDD.md` and the table can be re-run line by line against it.

**Status key:** **Done** = already working before this pass. **Built** = built in this pass. **Remaining** = not built yet.

| GDD feature | Status | Notes |
|---|---|---|
| Stomach / digestion: skills exist only while fruit digests | Done | Slots 4 → 8 via upgrades. Radial timers, element glow, bloom moment |
| Pairing: Conductive (Storm + Tide) | **Built** | Was only applied to already-wet targets. Now Storm spells conduct through anything while paired |
| Pairing: Fanned Flame (Ember + Gale) | **Built** | Was a label only. Ember explosions get +45 radius and spread burn |
| Clash: Indigestion (Frost + Ember) | **Built** | Only weakened passives. Now spells are also −25% |
| Pairing: Sanctuary Bloom (Lumen + Verdant) | **Built** | Was a label only. Regenerates 5 HP/s |
| Pairing: Phantom Mist (Tide + Umbra) | **Built** | Was a label only. Dodges 30% of hits ("MIST") |
| 32 species + hybrids registry | Done | 37 entries. Each now has a unique icon |
| Growth stages Seed → Ancient, soil affinities | Done | Matching soil grows 1.4× faster. All 6 stages have distinct art |
| Tending: water, prune, PRIME timing harvest | Done | Pruning adds trait chances |
| Cross-pollination → hybrids (spring) | **Built** | The graft was set but unharvestable. Now it shows a glowing hybrid fruit, harvests as the hybrid, and is added to the Codex |
| Compost / windfall cleanup / blight | Remaining | `has_blight` and `windfall_compost_value` exist but have no gameplay yet. Windfall fruit can be gathered |
| Pantry: Juice / Dried / Jam | **Built** | Functions existed with no UI. New Market Pantry tab. Jams carry both elements, so they pair themselves. Saved |
| Mastery → Rooted skills (max 4) | **Built** | XP accumulated but was unused. At 100 a species becomes Rooted and digests 25% slower. Shown in the Codex. Saved |
| Quickroot battlefield planting | Done | Per-element sprouts (rod, bloom, spire, thorns…) |
| Fruit traits (Juicy, Twin, Sweet…) | Done | Affect duration, mastery and price |
| Day loop: Morning → Expedition → Night Raid → Sleep | Done | Gate drives the phases, the door sleeps. Autosave each morning |
| Seasons (7 days each) | Partial | Season ticks and is shown, and spring enables hybrids. No seasonal visuals or crop rules yet |
| Expedition: wild groves, regional seeds | Done | Wild trees in the eastern wilds can be harvested |
| Expedition: plant permanent rest waystations | Remaining | `wild_planted_trees` stub only |
| Night raid: Poachers that steal and **eat** fruit, turning skills on you | Done | Their projectiles now actually hit the player (fixed in pass 1) |
| Gnawer beasts | Done | Distinct beetle silhouette, amber night rim |
| Reaping Elite enemy | Remaining | Enum value exists. No spawn, art or behaviour |
| Raid reward + scaling | Done | 3 + 1.5 × day raiders. Bonus gold |
| Market: sell, seeds, stomach & tool upgrades | Done | Tool upgrade now really adds damage (pass 1) |
| Market: land plot expansion | Remaining | `plots_unlocked` / `land_expansion_cost` exist. The compact layout has room for a third row |
| **Village party system**: recruit or leave on guard | **Built** | Role-based: Wren (Rogue) fights or keeps watch, calls raids and defends the orchard. Hesper (Support) heals or tends hives for +20% hybrid odds. Companions travel with you. HUD roster |
| Villager loved / hated flavours (gifting) | Remaining | Data exists on each villager. Needs a gift interaction and an affinity meter |
| **3-player co-op** | **Built (local)** | Drop-in by gamepad (Start). Shared satchel and gold, per-player stomach. Shared camera framing. P2/P3 vitals chips |
| Online co-op | Remaining (wired) | Input is intent-based (`PlayerInput.to_intent()` / `NetworkInput.push_intent()`). Transport and sync not built |
| Codex: 32 species collection + hybrid tree | Done → improved | Distinct silhouettes, parent "?" for hybrids, mastery shown |
| Tutorial / onboarding | Done | Water → harvest → eat → cast → survive the raid |
| Save / Continue | Done | Now also saves rooted skills and pantry forms |
| Title, Settings, Pause, full gamepad menus | Done | |

### Recommended next GDD items
1. **Land expansion:** a third plot row inside the existing fence. Cheap, and it gives you a gold sink.
2. **Villager gifting:** flavour affinity that scales companion damage and healing.
3. **Compost & blight:** turns windfall fruit into a resource and adds risk to over-ripening.
4. **Reaping Elite:** a raid boss every 7th night that eats two fruits at once.
5. **Online co-op transport**, built on the existing intent seam.
