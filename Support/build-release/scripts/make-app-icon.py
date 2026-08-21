#!/usr/bin/env python3
"""Rebuild the macOS app icon set from the design source.

Why this exists
---------------
The icon that shipped had its transparency *flattened*: the checkerboard a design
tool draws behind a transparent layer was exported as real pixels, so macOS drew a
light square behind the artwork in the Dock, in Finder and on the DMG. No macOS app
has a square backing or a border around its icon — the icon *is* the shape.

So the source is treated as artwork on a background that has to go: the flattened
backing is flood-filled away from the edges, the artwork is trimmed to its own
bounds, and it is placed on a transparent 1024pt canvas at the proportion Apple's
icon grid uses, so it sits at the same visual size as every other icon in the Dock.

Run it whenever the design source changes:

    bash build/scripts/make-app-icon.sh

It writes the ten PNGs the asset catalogue names, plus a transparent master next to
the design source so the cleaned artwork is reviewable on its own.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image, ImageFilter

REPO_ROOT = pathlib.Path(__file__).resolve().parents[3]

DEFAULT_SOURCE = REPO_ROOT / "Support/context/concepts-designs/AppIcons/LXC-BRM-AppIcon2.png"
DEFAULT_MASTER = REPO_ROOT / "Support/context/concepts-designs/AppIcons/LXC-BRM-AppIcon-transparent.png"
ICON_SET = REPO_ROOT / "App/Resources/Assets.xcassets/AppIcon.appiconset"

# Apple's macOS icon grid: the artwork occupies 824 of a 1024pt canvas, and the rest
# is the margin every icon in the Dock shares. Filling the canvas edge to edge is what
# makes an icon look oversized next to the system's own.
CANVAS = 1024
ARTWORK = 824

# The ten renderings the asset catalogue names.
SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

# What counts as backing rather than artwork: near-neutral and light. The artwork's own
# pale surfaces are tinted — a light blue reads as far from neutral as this allows — so
# the test separates the two without a hand-drawn mask.
NEUTRAL_SPREAD = 14
BACKING_FLOOR = 170

# The artwork's outline was anti-aliased against the backing before it was flattened, so
# the pixels right at its edge are part artwork and part old background. Left alone they
# survive as a pale rim — exactly the border this is meant to remove — so the background
# is grown a little way into them, and the alpha is softened afterwards to keep the edge
# from turning into a staircase.
FRINGE = 3
EDGE_SOFTNESS = 0.9


def backing_mask(rgb: np.ndarray) -> np.ndarray:
    """Every pixel reachable from the edge of the image without crossing the artwork.

    Reachability is the whole point: the artwork has pale, near-neutral surfaces of its
    own, and a plain colour test would punch holes straight through them. Only what the
    outside can reach is background.
    """
    spread = rgb.max(axis=2).astype(np.int16) - rgb.min(axis=2).astype(np.int16)
    candidate = (spread <= NEUTRAL_SPREAD) & (rgb.min(axis=2) >= BACKING_FLOOR)

    reached = np.zeros_like(candidate)
    reached[0, :] = candidate[0, :]
    reached[-1, :] = candidate[-1, :]
    reached[:, 0] = candidate[:, 0]
    reached[:, -1] = candidate[:, -1]

    # Grow the reached region into its neighbours until it stops growing.
    while True:
        grown = spread_once(reached) & candidate
        if np.array_equal(grown, reached):
            break
        reached = grown

    # Past the edge of the artwork now, into the fringe the flattening left behind.
    for _ in range(FRINGE):
        reached = spread_once(reached)
    return reached


def spread_once(mask: np.ndarray) -> np.ndarray:
    """The mask plus each of its neighbours.

    Vectorised rather than a pixel-at-a-time flood fill: a million-pixel fill in Python
    is slow enough to be annoying, and four array shifts per pass are not.
    """
    grown = mask.copy()
    grown[1:, :] |= mask[:-1, :]
    grown[:-1, :] |= mask[1:, :]
    grown[:, 1:] |= mask[:, :-1]
    grown[:, :-1] |= mask[:, 1:]
    return grown


def transparent_master(source: pathlib.Path) -> Image.Image:
    """The artwork alone, trimmed, on a transparent canvas at Apple's proportion."""
    rgb = np.asarray(Image.open(source).convert("RGB"))
    alpha = np.where(backing_mask(rgb), 0, 255).astype(np.uint8)
    softened = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(EDGE_SOFTNESS))

    cleaned = Image.merge("RGBA", (*Image.fromarray(rgb).split(), softened))
    bounds = cleaned.getbbox()
    if bounds is None:
        sys.exit(f"{source} has no artwork left once its backing is removed.")
    artwork = cleaned.crop(bounds)

    # Square first, so a source that is not exactly square is not stretched.
    side = max(artwork.size)
    squared = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    squared.paste(artwork, ((side - artwork.width) // 2, (side - artwork.height) // 2))

    scaled = squared.resize((ARTWORK, ARTWORK), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(scaled, ((CANVAS - ARTWORK) // 2, (CANVAS - ARTWORK) // 2))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=pathlib.Path, default=DEFAULT_SOURCE)
    parser.add_argument("--master", type=pathlib.Path, default=DEFAULT_MASTER)
    parser.add_argument("--icon-set", type=pathlib.Path, default=ICON_SET)
    arguments = parser.parse_args()

    if not arguments.source.is_file():
        sys.exit(f"No design source at {arguments.source}")

    master = transparent_master(arguments.source)
    master.save(arguments.master)

    for filename, pixels in SIZES:
        master.resize((pixels, pixels), Image.LANCZOS).save(arguments.icon_set / filename)

    print(f"Icon set rebuilt from {arguments.source.relative_to(REPO_ROOT)}")
    print(f"  master  {arguments.master.relative_to(REPO_ROOT)}")
    print(f"  set     {arguments.icon_set.relative_to(REPO_ROOT)} ({len(SIZES)} renderings)")


if __name__ == "__main__":
    main()
