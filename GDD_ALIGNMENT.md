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
| Compost / windfall cleanup / blight | **Built (pass 3)** | The compost bin turns windfall fruit into compost (2 each). Neglected trees (dry, or fruit left to rot) may catch blight, which halts growth. Hoe-Staff + compost cures blight and gives a growth surge |
| Pantry: Juice / Dried / Jam | **Built** | Functions existed with no UI. New Market Pantry tab. Jams carry both elements, so they pair themselves. Saved |
| Mastery → Rooted skills (max 4) | **Built** | XP accumulated but was unused. At 100 a species becomes Rooted and digests 25% slower. Shown in the Codex. Saved |
| Quickroot battlefield planting | Done | Per-element sprouts (rod, bloom, spire, thorns…) |
| Fruit traits (Juicy, Twin, Sweet…) | Done | Affect duration, mastery and price |
| Day loop: Morning → Expedition → Night Raid → Sleep | Done | Gate drives the phases, the door sleeps. Autosave each morning |
| Seasons (7 days each) | **Built (pass 3)** | Per-season light tint and ground wash, weather (petals, sun motes, leaves, snow) and a banner. Rules: summer ×1.2 growth, autumn +25% prices, winter ×0.5 growth except Frost trees and Rime soil (×1.3), spring hybrids |
| Expedition: wild groves, regional seeds | Done | Wild trees in the eastern wilds can be harvested |
| Expedition: plant permanent rest waystations | **Built (pass 3)** | Three wild clearings. Plant a seed and it grows into a shrine after 2 mornings. Resting there heals the whole party, sets your respawn point, and gives 1 fruit a day. Saved |
| Night raid: Poachers that steal and **eat** fruit, turning skills on you | Done | Their projectiles now actually hit the player (fixed in pass 1) |
| Gnawer beasts | Done | Distinct beetle silhouette, amber night rim |
| Reaping Elite enemy | **Built (pass 3)** | Every 7th night. Crimson boss with a boss bar. Eats *two* fruits and alternates both skills in triple volleys. Summons Gnawers at half health. Drops 150g and rare seeds |
| Raid reward + scaling | Done | 3 + 1.5 × day raiders. Bonus gold |
| Market: sell, seeds, stomach & tool upgrades | Done | Tool upgrade now really adds damage (pass 1) |
| Market: land plot expansion | **Built (pass 3)** | A third row of 3 overgrown plots inside the extended fence. Buy them in place or from Market → Upgrades (120g, +60g each). Saved |
| **Village party system**: recruit or leave on guard | **Built** | Role-based: Wren (Rogue) fights or keeps watch, calls raids and defends the orchard. Hesper (Support) heals or tends hives for +20% hybrid odds. Companions travel with you. HUD roster |
| Villager loved / hated flavours (gifting) | **Built (pass 3)** | Dialogue now has choices (Party / Gift / Goodbye), and gifting picks a fruit from the satchel. Loved +20, neutral +8, hated −10, one gift a day. Affinity (0–5) scales Wren's damage and Hesper's healing. Saved |
| **3-player co-op** | **Built (local)** | Drop-in by gamepad (Start). Shared satchel and gold, per-player stomach. Shared camera framing. P2/P3 vitals chips |
| Online co-op | **Built (pass 3)** | Host-authoritative ENet (port 7777, up to 3 players). Clients send intents; the host streams 20 Hz snapshots (players, stomachs, enemies, plots, day/phase/gold) plus spell events. Title → Online Co-op → Host / Join by IP. Verified with two processes (`tools/net_test.sh`). Limits: the host owns the satchel, market and dialogue; there's no NAT punch-through (use LAN, port forwarding or a VPN such as Tailscale) and no client-side prediction |
| Codex: 32 species collection + hybrid tree | Done → improved | Distinct silhouettes, parent "?" for hybrids, mastery shown |
| Tutorial / onboarding | Done | Water → harvest → eat → cast → survive the raid |
| Save / Continue | Done | Now also saves rooted skills and pantry forms |
| Title, Settings, Pause, full gamepad menus | Done | |

### What's left
Every item in this table is built. Natural next steps:
1. **Online polish:** client-side prediction for your own character, plus a Steam or relay transport so friends don't need port forwarding.
2. **Season-specific content:** winter-only species, autumn festival quests.
3. **More Elites:** one per element, with arena mechanics.
