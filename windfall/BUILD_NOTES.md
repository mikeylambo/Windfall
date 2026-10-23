# Godot Game OS Build Notes

## Project Identity

- Project type: reusable Godot Game OS template
- Template purpose: universal foundation for starting new Godot games
- Game-specific content: intentionally excluded

## Godot Version Target

- Target engine: Godot 4.x
- Validate against the project’s currently installed Godot editor before release.

## Template Version

- Template version: v1.1 universal infrastructure
- Previous baseline: v1 reusable template foundation

## Known Systems

- EventBus
- SceneLoader
- SaveManager
- AudioManager
- SettingsManager
- GameState
- ResourceDatabase
- GameFlow
- ObjectPool
- AchievementManager
- UIManager
- CameraManager
- LocalizationManager
- AccessibilityManager
- LoadingScreen UI foundation
- CreditsScene UI foundation
- DevConsole UI foundation

## Known Non-Blocking Limitations

- LoadingScreen is a reusable UI foundation only; async scene loading is not wired yet.
- CreditsScene ships with generic placeholder credits and should be customized per game.
- DevConsole includes safe generic commands only and does not expose cheats or game-specific debug actions.
- AccessibilityManager stores universal preferences, but each game/UI theme must decide how to visually apply high contrast, large text, and colorblind modes.
- LocalizationManager supports in-memory dictionaries; file-based translation loading can be added per project need.
- Platform-specific icons, splash screens, and export preset tuning should be completed per game.

## Starting a New Game from This Template

1. Duplicate the full template project folder before adding game-specific logic.
2. Rename the duplicate project and update project identity/version settings.
3. Keep reusable infrastructure generic when improving the template itself.
4. Add game-specific scenes, data, art, audio, dialogue, quests, and mechanics only inside the duplicated game project.
5. Re-run the export checklist before sharing or releasing a build.