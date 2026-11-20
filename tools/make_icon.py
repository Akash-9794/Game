"""Draws the app icon (assets/icon/*.png) — the same gem logo as the home screen.

Run:  python3 tools/make_icon.py
Then: dart run flutter_launcher_icons   (copies it into android/ and web/)
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
SIZE = 1024
SS = 4  # draw 4x bigger, then shrink, for smooth edges

BACKGROUND = (0x12, 0x12, 0x1C)
GEMS = [(0xE5, 0x39, 0x5B), (0xF5, 0xA6, 0x23), (0x2E, 0xCC, 0x71), (0x3B, 0x82, 0xF6),
        (0x9B, 0x59, 0xB6), (0x1A, 0xBC, 0x9C), (0xFF, 0x6F, 0xB5)]
PATTERN = [[0, 1, 3], [5, -1, 2], [4, 6, -1]]  # same as the home-screen logo


def darker(c, f=0.35):
    return tuple(int(v * (1 - f)) for v in c)


def draw_gem(d, shine, x, y, s, color):
    r = s * 0.18
    d.rounded_rectangle([x, y, x + s, y + s], r, fill=darker(color))          # bevel
    d.rounded_rectangle([x, y, x + s, y + s * 0.9], r, fill=color)            # face
    # The shine goes on its own layer so it blends instead of replacing pixels.
    shine.rounded_rectangle([x + s * 0.12, y + s * 0.09, x + s * 0.88, y + s * 0.4],
                            s * 0.12, fill=(255, 255, 255, 72))


def logo(area, background):
    """Gem logo filling [area] (fraction of the icon) on [background] (None = transparent)."""
    big = SIZE * SS
    img = Image.new("RGBA", (big, big), background + (255,) if background else (0, 0, 0, 0))
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    shine_layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    shine = ImageDraw.Draw(shine_layer)
    cell = big * area / 3
    start = (big - cell * 3) / 2
    gap = cell * 0.07
    for r, row in enumerate(PATTERN):
        for c, g in enumerate(row):
            if g >= 0:
                draw_gem(d, shine, start + c * cell + gap, start + r * cell + gap, cell - 2 * gap, GEMS[g])
    img = Image.alpha_composite(img, layer)
    img = Image.alpha_composite(img, shine_layer)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


OUT.mkdir(parents=True, exist_ok=True)
# Normal icon: dark square with the logo (launchers/browsers round the corners).
logo(0.72, BACKGROUND).save(OUT / "icon.png")
# Android adaptive icon foreground: must stay inside the middle ~60% safe zone.
logo(0.56, None).save(OUT / "icon_foreground.png")
print("wrote", *sorted(p.name for p in OUT.glob("*.png")))
