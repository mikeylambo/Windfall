# Credits

## Art
All sprites, tiles, icons, UI and effects are original pixel art drawn in code for WINDFALL (`scripts/Windfall/Art/`), baked by `tools/bake_art.gd`. No third-party art is used.

## Audio
All sound effects and ambience are synthesised procedurally at runtime (`scripts/Windfall/SoundSynth.gd`).

## Fonts
- **Jersey 10** (body / HUD) and **Jersey 15** (titles / banners) by Sarah Cadigan-Fried, The Soft Type Project.
  Copyright 2023 The Soft Type Project Authors (https://github.com/scfried/soft-type-jersey).
  SIL Open Font License 1.1, see `assets/fonts/OFL-Jersey10.txt` and `OFL-Jersey15.txt`.
  Obtained via the `@fontsource/jersey-10` and `@fontsource/jersey-15` npm packages.

Pixel Operator (CC0) and m6x11 were the first choice. They couldn't be fetched from the build
environment (its network only reaches npm and GitHub release assets), so Jersey was chosen after
rendering every digit side by side with the other options. To use Pixel Operator anyway, drop
`PixelOperator.ttf` into `assets/fonts/` and point `UITheme.FONT_PATH` at it. Its grid is 8 px,
so change `body_px()` to snap to multiples of 8.

## Engine
Godot Engine 4.6 (MIT), https://godotengine.org
