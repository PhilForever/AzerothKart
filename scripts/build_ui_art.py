"""Build Azeroth Kart's menu art: the track-select previews.

python scripts/build_ui_art.py            # write the runtime TGA
python scripts/build_ui_art.py --check    # verify exact bytes, write nothing
python scripts/build_ui_art.py --preview  # also write docs/art/ui/track-previews.png

TrackPreviews.tga is a 1024x512 BGRA32 atlas with one 512x512 cell per track,
read by Menu.PREVIEW_CELLS:

- cell 0, Mirage Raceway: the committed scenery-v1 Background.tga reduced
  2x2 by an exact box filter. Nothing is added; it is the same painting the
  race draws.
- cell 1, Test Oval: a 500x300 painting of the oval from its analytical
  geometry (Track.lua: centre, ellipse radii, the four gates, both crates and
  the perimeter), in the race's own flat colours, plus a chequered start line
  and four direction arrows. It sits at the top of the cell, 6 texels from
  each side; the rest of the cell is grass, so the atlas is fully opaque and a
  cropped edge never filters in a dark fringe.

Inputs are the repository's own scenery file and geometry numbers; no external
image is used. Only exact arithmetic (+ - * /, sqrt) and integer averaging feed
texel values, so the bytes are the same on every platform.
"""
import argparse
import hashlib
from math import sqrt
from pathlib import Path

from paintkit import decode_tga, encode_png, encode_tga

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / "SaltFlats" / "Background.tga"
OUTPUT = ROOT / "addon" / "AzerothKart" / "Assets" / "UI" / "TrackPreviews.tga"
PREVIEW = ROOT / "docs" / "art" / "ui" / "track-previews.png"

WIDTH, HEIGHT, CELL = 1024, 512, 512
OVAL_WIDTH, OVAL_HEIGHT, OVAL_LEFT = 500, 300, CELL + 6   # 800x480 world units, 1.6 per texel
SUPERSAMPLE = 4

# Test Oval geometry (addon/AzerothKart/Track.lua, version 2).
CX, CY = 400, 240
OUTER, INNER, LINE = (370, 218), (170, 84), (266, 151)
WALL = 4
CRATES = [(270, 400, 32, 24), (490, 60, 32, 24)]
GATES = [  # (x0, y0, x1, y1) road-spanning strips, 5 units thick
    (CX - 2.5, CY + INNER[1], CX + 2.5, CY + OUTER[1]),          # North
    (CX - OUTER[0], CY - 2.5, CX - INNER[0], CY + 2.5),          # West
    (CX - 2.5, CY - OUTER[1], CX + 2.5, CY - INNER[1]),          # South
]
START = (CX + INNER[0], CX + OUTER[0], CY)                       # x0, x1, y: the Start gate

# The race's flat colours (UI.lua drawTrack/drawWalls).
GRASS = (0.08, 0.24, 0.12)
ROAD = (0.26, 0.25, 0.23)
WALLS = (0.42, 0.44, 0.48)
GATE, GATE_ALPHA = (0.55, 0.58, 0.62), 0.65
CRATE, CRATE_EDGE = (0.88, 0.25, 0.12), (0.45, 0.12, 0.06)
CHECK_LIGHT, CHECK_DARK = (0.92, 0.91, 0.88), (0.10, 0.10, 0.11)
ARROW, ARROW_ALPHA = (0.93, 0.92, 0.86), 0.75


def inside_ellipse(x, y, rx, ry):
    dx, dy = (x - CX) / rx, (y - CY) / ry
    return dx * dx + dy * dy <= 1.0


def arrows():
    """Four triangles on the racing line between the gates, pointing the
    counterclockwise way round (angles 45, 135, 225 and 315 degrees)."""
    h = sqrt(0.5)
    shapes = []
    for c, s in ((h, h), (-h, h), (-h, -h), (h, -h)):
        px, py = CX + LINE[0] * c, CY + LINE[1] * s
        tx, ty = -LINE[0] * s, LINE[1] * c                 # counterclockwise tangent
        length = sqrt(tx * tx + ty * ty)
        tx, ty = tx / length, ty / length
        nx, ny = -ty, tx
        tip = (px + 18 * tx, py + 18 * ty)                     # slim, so the tip reads at a glance
        left = (px - 12 * tx + 7 * nx, py - 12 * ty + 7 * ny)
        right = (px - 12 * tx - 7 * nx, py - 12 * ty - 7 * ny)
        shapes.append((tip, left, right))
    return shapes


def in_triangle(x, y, triangle):
    (ax, ay), (bx, by), (cx, cy) = triangle
    d1 = (x - bx) * (ay - by) - (ax - bx) * (y - by)
    d2 = (x - cx) * (by - cy) - (bx - cx) * (y - cy)
    d3 = (x - ax) * (cy - ay) - (cx - ax) * (y - ay)
    negative = d1 < 0 or d2 < 0 or d3 < 0
    positive = d1 > 0 or d2 > 0 or d3 > 0
    return not (negative and positive)


ARROWS = arrows()


def oval_sample(x, y):
    """Colour of the Test Oval at world point (x, y), +y north."""
    if x < WALL or x > 800 - WALL or y < WALL or y > 480 - WALL:
        return WALLS
    for left, bottom, width, height in CRATES:
        if left <= x <= left + width and bottom <= y <= bottom + height:
            edge = x < left + 2 or x > left + width - 2 or y < bottom + 2 or y > bottom + height - 2
            return CRATE_EDGE if edge else CRATE
    road = inside_ellipse(x, y, *OUTER) and not inside_ellipse(x, y, *INNER)
    if not road:
        return GRASS
    color = ROAD
    x0, x1, line_y = START
    if x0 <= x <= x1 and abs(y - line_y) <= 8:
        column, row = int((x - x0) // 8), int((y - line_y + 8) // 8)
        return CHECK_LIGHT if (column + row) % 2 == 0 else CHECK_DARK
    for gx0, gy0, gx1, gy1 in GATES:
        if gx0 <= x <= gx1 and gy0 <= y <= gy1:
            color = tuple(r + (g - r) * GATE_ALPHA for r, g in zip(color, GATE))
    for triangle in ARROWS:
        if in_triangle(x, y, triangle):
            color = tuple(r + (a - r) * ARROW_ALPHA for r, a in zip(color, ARROW))
    return color


def paint_oval():
    """Top-down rows of 8-bit RGBA; each texel averages SUPERSAMPLE^2 samples."""
    step = 800 / OVAL_WIDTH
    samples = SUPERSAMPLE * SUPERSAMPLE
    rows = []
    for j in range(OVAL_HEIGHT):
        row = []
        for i in range(OVAL_WIDTH):
            total = [0, 0, 0]
            for b in range(SUPERSAMPLE):
                y = 480 - (j + (b + 0.5) / SUPERSAMPLE) * step
                for a in range(SUPERSAMPLE):
                    x = (i + (a + 0.5) / SUPERSAMPLE) * step
                    for c, value in enumerate(oval_sample(x, y)):
                        total[c] += int(value * 65535 + 0.5)
            row.append([(t * 255 + samples * 65535 // 2) // (samples * 65535) for t in total] + [255])
        rows.append(row)
    return rows


def reduce_background():
    """Scenery v1 at half size: each texel is the rounded mean of a 2x2 block."""
    fields, pixels = decode_tga(BACKGROUND.read_bytes())
    width, height = fields[8], fields[9]
    assert (width, height) == (2 * CELL, 2 * CELL), "Background.tga must stay 1024x1024"
    rows = []
    for j in range(CELL):
        top, bottom = pixels[2 * j], pixels[2 * j + 1]
        row = []
        for i in range(CELL):
            block = (top[2 * i], top[2 * i + 1], bottom[2 * i], bottom[2 * i + 1])
            row.append([(sum(p[c] for p in block) + 2) // 4 for c in range(4)])
        rows.append(row)
    return rows


def build():
    grass = [int(c * 255 + 0.5) for c in GRASS] + [255]
    atlas = [[list(grass) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for j, row in enumerate(reduce_background()):
        atlas[j][:CELL] = row
    for j, row in enumerate(paint_oval()):
        atlas[j][OVAL_LEFT:OVAL_LEFT + OVAL_WIDTH] = row
    return atlas


def validate(pixels):
    assert len(pixels) == HEIGHT and all(len(row) == WIDTH for row in pixels), "atlas size"
    assert all(p[3] == 255 for row in pixels for p in row), "the atlas is fully opaque"
    road = int(ROAD[0] * 255 + 0.5)
    # A texel on the oval's east straight, between the gates, is plain road.
    j = round((480 - (CY - 40)) / 1.6)
    i = OVAL_LEFT + round((CX + 300) / 1.6)
    assert abs(pixels[j][i][0] - road) <= 1, "east straight is road"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify exact runtime bytes without writing")
    parser.add_argument("--preview", action="store_true", help="also write a review PNG under docs/art/ui/")
    args = parser.parse_args()
    pixels = build()
    validate(pixels)
    image = encode_tga(pixels)
    relative = OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != image:
            raise SystemExit(f"STALE: {relative}; run without --check")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(image)
    if args.preview:
        PREVIEW.parent.mkdir(parents=True, exist_ok=True)
        PREVIEW.write_bytes(encode_png(pixels))
    print(f"{'CHECK PASS' if args.check else 'WROTE'}: {relative}; {WIDTH}x{HEIGHT} BGRA32 opaque; "
          f"{len(image)} bytes; sha256={hashlib.sha256(image).hexdigest()}")


if __name__ == "__main__":
    main()
