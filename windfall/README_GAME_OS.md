# Godot Game OS Architecture README

## 1. Purpose

This project is a reusable **Godot Game OS template**: a foundation of generic systems, services, components, resources, and conventions intended to be duplicated into future games.

This is **not** a Riftlings project.

Any Riftlings-specific prototype content has been archived under:

```text
res://archive/prototypes/riftlings/
```

The reusable template should remain game-agnostic and suitable for multiple genres, including action RPGs, tactical RPGs, creature collectors, survivors-likes, platform fighters, beat-em-ups, and incremental games.

---

## 2. Core Autoloads

### EventBus

Central signal hub for cross-system communication.

Responsibilities:

- Game lifecycle events: started, paused, resumed.
- Scene change events.
- Combat events: damage, healing, ability use, effects, unit defeat.
- Save/load request and completion events.

Use `EventBus` when systems need to broadcast state changes without hard dependencies on specific listeners.

### GameState

Global game state controller.

Responsibilities:

- Tracks high-level state such as boot, main menu, playing, paused, loading, and game over.
- Pauses and resumes the scene tree.
- Emits pause/resume events through `EventBus` when available.

### GameFlow

High-level flow coordinator.

Responsibilities:

- Switches between broad modes such as boot, main menu, gameplay, and game over.
- Coordinates `GameState` changes.
- Calls `SceneLoader` for scene transitions when scene paths are configured.
- Emits game-started events through `EventBus` when available.

### SceneLoader

Scene transition service.

Responsibilities:

- Change scenes by path.
- Reload the current scene.
- Quit the game.
- Track the last requested scene path.
- Emit scene-changed events through `EventBus` when available.

### SaveManager

Global save/load coordinator.

Responsibilities:

- Save dictionaries to JSON.
- Load dictionaries from JSON.
- Build scene-node snapshots from nodes in the `saveable` group.
- Restore saveable scene nodes by `save_id`.
- Maintain a global save provider registry for autoloads and global systems.
- Auto-register `AchievementManager` under the `achievements` section when available.

Primary calls:

```gdscript
SaveManager.save_game()
SaveManager.load_game()
```

### ResourceDatabase

Generic runtime resource index.

Responsibilities:

- Scan configured data folders for `.tres` and `.res` files.
- Index resources by ID, path, and tags.
- Notify listeners when scanning completes or resources are registered.
- Trigger `AchievementManager.register_from_database()` after scanning when available.
- Optionally forward database events to `EventBus` if matching methods exist.

---

## 3. Service Autoloads

### AudioManager

Audio playback and bus setup service.

Responsibilities:

- Ensure Master, Music, SFX, and UI buses exist.
- Play/stop music.
- Play SFX through a small pool of `AudioStreamPlayer` nodes.
- Play UI sounds.
- Set bus volume and mute state.

### SettingsManager

Persistent settings service.

Responsibilities:

- Load, save, and reset settings.
- Apply volume, mute, and fullscreen settings.
- Coordinate audio settings with `AudioManager`.

Settings are stored separately from game save data.

### UIManager

Generic menu stack service.

Responsibilities:

- Push menus onto a stack.
- Pop the top menu.
- Clear all menus.
- Reveal the previous menu after popping.
- Use `open_menu()` / `close_menu()` when available, otherwise fall back to `show()` / `hide()`.

### ObjectPool

Generic scene instance pooling service.

Responsibilities:

- Create pools from `PackedScene` resources.
- Spawn pooled objects under a requested parent or under `ObjectPool`.
- Despawn objects back into the pool.
- Clear one pool or all pools.

Use this for projectiles, enemies, pickups, VFX, UI effects, or any reusable scene instances after a game defines its own pool setup.

---

## 4. Gameplay Foundation Autoloads

### CombatManager

Generic combat action service.

Responsibilities:

- Deal damage to valid targets.
- Heal valid targets.
- Apply status effects through a target `StatusEffectController`.
- Emit local combat signals.
- Forward combat events to `EventBus` when available.

### AchievementManager

Generic achievement progression service.

Responsibilities:

- Register achievement resources manually or from `ResourceDatabase`.
- Track progress and unlocked state.
- Unlock achievements when progress reaches target values.
- Provide save/load data for `SaveManager` global provider registry.

No game-specific achievement rules should live in the template. Games should add their own resources and event wiring after duplication.

---

## 5. Core Resource Pattern

### EntityData

Static/base definition for an entity.

Typical use:

- ID and display fields.
- Base stats such as max health, move speed, team ID.
- Ability resource references.
- Tags.

### RuntimeStats

Mutable runtime values created from static data or exported component defaults.

Typical use:

- Current health.
- Shield.
- Energy.
- Runtime team ID.
- Damage/healing helpers.

### StatsComponent

Preferred reusable component path for stat-driven entities.

Responsibilities:

- Create and own `RuntimeStats`.
- Initialize from `EntityData` or exported values.
- Emit health, shield, energy, and death signals.
- Provide generic damage/healing/stat access methods.

### Unit.gd

`Unit.gd` is a simple/demo `CharacterBody2D` wrapper with basic health and runtime stats behavior.

It is useful as a minimal example, but it is **not the only canonical path**. For reusable game architecture, prefer composing entities from components such as `StatsComponent`, `TeamComponent`, `AbilityController`, `StatusEffectController`, `InventoryComponent`, and `SaveableComponent`.

---

## 6. Component Conventions

### StatsComponent

Attach to entities that need reusable runtime stats.

Expected node name when used with `SaveableComponent`:

```text
StatsComponent
```

### TeamComponent

Attach to entities that need team/faction/targeting information.

Tracks:

- `team_id`
- `faction_id`
- target self/allies/enemies flags

Expected node name when used with `SaveableComponent`:

```text
TeamComponent
```

### AbilityController

Attach to entities that own runtime abilities.

Responsibilities:

- Store ability resources.
- Duplicate runtime ability instances.
- Track cooldowns.
- Use abilities and emit ability events.

Expected node name when used with `SaveableComponent`:

```text
AbilityController
```

`SaveableComponent` will only save ability data if `AbilityController` supports `get_save_data()`.

### StatusEffectController

Attach to entities that can receive status effects.

Responsibilities:

- Add/remove effects.
- Process ticking/expiration.
- Track active effect instances.

Expected node name for `CombatManager.apply_effect()` lookup:

```text
StatusEffectController
```

### InventoryComponent

Attach to entities that need generic item counts.

Responsibilities:

- Add/remove item IDs.
- Enforce max unique slots.
- Provide save/load data.

Expected node name when used with `SaveableComponent`:

```text
InventoryComponent
```

### SaveableComponent

Attach as a child of any node that should participate in save/load.

Responsibilities:

- Add parent to the `saveable` group.
- Provide `get_save_data()` and `load_save_data(data)`.
- Save/restore optional transform data.
- Save/restore `StatsComponent` runtime stats.
- Save/restore sibling `InventoryComponent`, `TeamComponent`, and supported `AbilityController` data.

Expected node name for `SaveManager` automatic provider lookup:

```text
SaveableComponent
```

---

## 7. Save/Load Workflow

### Basic save/load calls

```gdscript
SaveManager.save_game()
SaveManager.load_game()
```

### Scene-node saves

Scene nodes are included in snapshots when they are in the `saveable` group.

The recommended way to do this is to add a child node named:

```text
SaveableComponent
```

`SaveableComponent` automatically adds its parent to the `saveable` group.

### Child naming conventions

For automatic component capture, use these child names under the saved node:

```text
StatsComponent
InventoryComponent
TeamComponent
AbilityController
```

### Global save providers

Autoloads and global systems can register with:

```gdscript
SaveManager.register_save_provider(section_id, provider)
```

Providers should implement:

```gdscript
get_save_data() -> Dictionary
load_save_data(data: Dictionary) -> void
```

`AchievementManager` auto-registers under:

```text
achievements
```

Future generic managers can use the same pattern after they exist.

---

## 8. ResourceDatabase Workflow

Actual `.tres` and `.res` data resources should live under:

```text
res://data
res://resources
```

`ResourceDatabase` scans those paths by default.

Recognized ID fields, in order:

1. `entity_id`
2. `ability_id`
3. `effect_id`
4. `item_id`
5. `achievement_id`
6. `quest_id`
7. `recipe_id`
8. `pool_id`
9. `menu_id`
10. `resource_id`

Resources can also be queried by tag through:

```gdscript
ResourceDatabase.get_resources_by_tag(tag)
```

Use tags to group resources generically, such as:

```text
achievement
enemy
player
item
ability
effect
```

---

## 9. UI Workflow

### BaseMenu

Generic `Control` base for menu screens.

Responsibilities:

- Show/open menu.
- Hide/close menu.
- Focus a configured default control.
- Handle cancel input when enabled.
- Emit open/closed signals.

### UIManager

Generic menu-stack autoload.

Responsibilities:

- Push a menu and hide the previous top menu.
- Pop a menu and reveal the previous menu.
- Clear all menus.
- Use `open_menu()` / `close_menu()` when available.

### PauseMenu

`PauseMenu` is currently standalone.

It talks directly to `GameState` and `SceneLoader` and has not yet been refactored to use `BaseMenu` or `UIManager`.

### DebugOverlay

Simple debug UI showing runtime information such as FPS and autoload availability.

It can be toggled with `debug_reset`.

---

## 10. Input Conventions

Project-defined actions:

- `move_up`
- `move_down`
- `move_left`
- `move_right`
- `pause`
- `confirm`
- `cancel`
- `debug_reset`

Godot built-in `ui_*` actions may still be used for UI internals.

Examples:

- `BaseMenu` currently uses `ui_cancel`.
- `PauseMenu` currently uses `pause`.

Before a game ships, standardize whether gameplay/UI code should prefer custom actions such as `cancel` or built-in actions such as `ui_cancel`.

---

## 11. What Not To Add To This Template

These are post-template/game-layer systems and should not be added to the reusable Game OS core unless they become generic optional modules later:

- Riftlings-specific data
- Tactical lane battle systems
- Capture, bond, or evolution systems
- Quest systems
- Dialogue systems
- Crafting systems
- Skill/talent trees
- Platform fighter specifics
- Survivors-like wave directors
- Incremental economy loops

Keep the template focused on reusable infrastructure. Add game-specific systems only after duplicating this template into a game project.

---

## 12. Freeze Checklist

Before freezing or duplicating this template:

- Boot `TestArena`.
- Move `PlayerUnit` with `move_up/down/left/right`.
- Toggle `PauseMenu` with `pause`.
- Toggle `DebugOverlay` with `debug_reset`.
- Confirm all intended autoloads are enabled.
- Confirm Godot reports `0` errors.
- Confirm no game-specific prototype content remains in active core/template paths.
- Zip or backup the project before duplicating.

Recommended candidate name:

```text
Godot_Game_OS_v1_candidate
```

After duplication, add game-specific content only in the new project.