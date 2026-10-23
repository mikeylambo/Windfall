# 2D Top-Down Adventure & RPG Template

A feature-complete Godot 4 foundation for 2D top-down adventure games and action RPGs (inspired by *The Legend of Zelda*, *Hyper Light Drifter*, and *Crosscode*).

## Key Systems

1. **Player Controller (`AdventurePlayer2D.gd`)**:
   - 8-directional smooth movement with facing direction tracking.
   - Roll/dodge dash with invincibility frames and stamina/energy cost via `StatsComponent`.
   - Directional sword swing with circular arc, knockback, and damage.
   - Forward interaction detector targeting `Interactable2D` objects.
   - Integrated with `InventoryComponent` for item storage and save/load.

2. **Interaction System (`Interactable2D.gd`, `Chest.gd`, `DestructibleProp.gd`)**:
   - Hover prompt indicator (`[E]` / `[A Button]`).
   - Reusable `Chest` that awards items into player inventory and locks into an opened state.
   - Destructible pots and bushes that take damage and drop items.

3. **Dialogue System (`DialogueData.gd`, `DialogueManager.gd`, `DialogueBox.gd`)**:
   - Branching dialogue with multiple choice buttons and speaker labels.
   - Autoloaded `DialogueManager` with signal coordination.

4. **Quest Tracking (`QuestData.gd`, `QuestManager.gd`, `QuestTrackerHUD.gd`)**:
   - Multi-objective quests with rewards, progression signals, and HUD display.

5. **Room & Scene Transitions (`Door2D.gd`, `SpawnPoint2D.gd`)**:
   - Doors that seamlessly load new scenes via `SceneLoader` and place the player at matching spawn markers.

## Controls
- Move: `W`, `A`, `S`, `D` or Arrow Keys
- Interact / Talk: `E`
- Attack: `J` or Left Click
- Roll / Dash: `Shift` or Right Click
