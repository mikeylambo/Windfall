#!/usr/bin/env python3
"""Pack exported animation strips into a Windfall character sheet (4 columns x 20 rows).

Usage:
    python3 tools/pack_character_sheet.py <strips_dir> <out.png> [--size 64]

<strips_dir> holds one horizontal strip per animation and direction, named
<anim>_<dir>.png: anim is idle, walk, attack, roll, eat, cast, hurt or collapse, and dir is
down, up or side (side faces right; the game mirrors it). roll and collapse have one row,
so name them roll.png and collapse.png. Each strip is N frames of size x size laid side by
side, with N up to 4 (extra frames are dropped).

A missing strip is filled from the closest one that exists (same anim in another direction,
then idle), so a partial set still plays in game. The layout matches ProceduralSprites.ROWS.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

ROWS = {"idle": 0, "walk": 3, "attack": 6, "roll": 9, "eat": 10, "cast": 13, "hurt": 16, "collapse": 19}
SINGLE = {"roll", "collapse"}
DIRS = ["down", "up", "side"]


def load_strip(path: Path, size: int) -> list:
    img = Image.open(path).convert("RGBA")
    if img.height != size:
        img = img.resize((round(img.width * size / img.height), size), Image.NEAREST)
    count = min(4, max(1, img.width // size))
    return [img.crop((i * size, 0, (i + 1) * size, size)) for i in range(count)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("strips_dir", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--size", type=int, default=64)
    args = ap.parse_args()
    size = args.size

    strips = {}
    for anim in ROWS:
        for d in [None] if anim in SINGLE else DIRS:
            name = anim if d is None else f"{anim}_{d}"
            p = args.strips_dir / f"{name}.png"
            if p.exists():
                strips[name] = load_strip(p, size)
    if not strips:
        print(f"No strips found in {args.strips_dir}", file=sys.stderr)
        return 1

    def pick(anim: str, d: str):
        names = [anim] if anim in SINGLE else [f"{anim}_{d}"] + [f"{anim}_{o}" for o in DIRS if o != d]
        names += [f"idle_{d}"] + [f"idle_{o}" for o in DIRS] + list(strips)
        return next(strips[n] for n in names if n in strips)

    sheet = Image.new("RGBA", (size * 4, size * 20), (0, 0, 0, 0))
    filled = []
    for anim, row in ROWS.items():
        for i, d in enumerate(["down"] if anim in SINGLE else DIRS):
            frames = pick(anim, d)
            for col in range(4):
                # Short strips repeat their last frame so every cell is drawn.
                sheet.paste(frames[min(col, len(frames) - 1)], (col * size, (row + i) * size))
            filled.append(f"{anim}_{d}" if anim not in SINGLE else anim)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out)
    missing = [n for n in filled if n not in strips]
    print(f"Wrote {args.out} ({sheet.width}x{sheet.height}, {size}px frames)")
    if missing:
        print("Filled from nearest strip: " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    sys.exit(main())
