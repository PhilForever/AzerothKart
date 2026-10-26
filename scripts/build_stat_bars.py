"""Build the kart screen's stat bars: StatBars.tga.

python scripts/build_stat_bars.py            # write the runtime TGA
python scripts/build_stat_bars.py --check    # verify exact bytes, write nothing
python scripts/build_stat_bars.py --preview  # also write docs/art/ui/stat-bars.png

StatBars.tga is a 512x64 BGRA32 atlas with alpha: two rows, each one bar of
480x32 texels (twice the 240x16 the menu draws it at), the last 32 columns
clear:

- row 0 (v 0 to 0.5), the empty bar: a gold plate, bright along its top and
  bronze at its foot, a dark outline and rounded ends, with six recessed
  windows, dark and deeper at their top;
- row 1 (v 0.5 to 1), the full bar: the same plate, its windows filled with
  a glossy green, lit along their top and rounded at their sides.

Menu.lua draws row 0 and row 1 over it, cropped from the left to the kart's
value, so a bar fills window by window and part of a window shows a value
between two. The plate is identical in both rows, so the crop never shows.
It is original art in the style of the client's gold-trimmed frames and green
health bars; nothing from another game is used.

Only exact arithmetic (+ - * /, sqrt) and integer averaging feed texel
values, so the bytes are the same on every platform.
"""
import argparse
import hashlib
from pathlib import Path

from paintkit import decode_tga, encode_png, encode_tga, sd_box

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "addon" / "AzerothKart" / "Assets" / "UI" / "StatBars.tga"
PREVIEW = ROOT / "docs" / "art" / "ui" / "stat-bars.png"

WIDTH, HEIGHT, ROW = 512, 64, 32
BAR_W, BAR_H = 480, 32                # one bar, at twice the menu's 240x16
SEGMENTS = 6                          # windows, as Menu.STAT_SEGMENTS
SUPERSAMPLE = 4

# The plate: rounded ends, an outline, the windows inside it.
CX, CY, HX, HY, RADIUS = BAR_W / 2, BAR_H / 2, BAR_W / 2 - 1, BAR_H / 2 - 1, 9.0
OUTLINE = 1.6
INNER_X0, INNER_X1, DIVIDER = 8.0, BAR_W - 8.0, 4.0
WINDOW_W = (INNER_X1 - INNER_X0 - DIVIDER * (SEGMENTS - 1)) / SEGMENTS
WINDOW_Y0, WINDOW_Y1, WINDOW_RADIUS, WINDOW_RIM = 7.0, BAR_H - 7.0, 3.0, 1.4

OUTLINE_RGB = (20, 13, 6)
GOLD_TOP, GOLD_MID, GOLD_FOOT, GOLD_SHINE = (248, 212, 118), (200, 150, 62), (124, 84, 30), (255, 240, 176)
RIM_RGB = (54, 35, 14)
EMPTY_TOP, EMPTY_FOOT = (10, 9, 9), (46, 40, 34)
GREEN_TOP, GREEN_MID, GREEN_FOOT = (150, 238, 96), (64, 198, 44), (28, 128, 22)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def windows():
    """(centre x, half width) of each window, left to right."""
    out = []
    for k in range(SEGMENTS):
        x0 = INNER_X0 + k * (WINDOW_W + DIVIDER)
        out.append((x0 + WINDOW_W / 2, WINDOW_W / 2))
    return out


WINDOWS = windows()


def sample(px, py, full):
    """Straight colour and coverage (r, g, b, a in 0..255 and 0..1) at a point
    of one bar, (0, 0) its top-left corner."""
    outer = sd_box(px, py, CX, CY, HX, HY, RADIUS)
    if outer > 0.0:
        return (0.0, 0.0, 0.0, 0.0)
    if outer > -OUTLINE:
        return OUTLINE_RGB + (1.0,)
    # The nearest window.
    hy = (WINDOW_Y1 - WINDOW_Y0) / 2
    best = None
    for wx, hx in WINDOWS:
        d = sd_box(px, py, wx, CY, hx, hy, WINDOW_RADIUS)
        if best is None or d < best[0]:
            best = (d, wx, hx)
    d, wx, hx = best
    if d <= -WINDOW_RIM:
        t = (py - WINDOW_Y0) / (WINDOW_Y1 - WINDOW_Y0)             # 0 at a window's top, 1 at its foot
        if not full:
            rgb = mix(EMPTY_TOP, EMPTY_FOOT, t * t)               # recessed: darkest under the plate's lip
            return rgb + (1.0,)
        rgb = mix(GREEN_TOP, GREEN_MID, t / 0.45) if t < 0.45 else mix(GREEN_MID, GREEN_FOOT, (t - 0.45) / 0.55)
        if t < 0.42:                                               # the gloss along the top
            rgb = mix(rgb, (255.0, 255.0, 255.0), 0.30 * (1.0 - t / 0.42))
        u = (px - wx) / hx                                         # -1 at the left edge, 1 at the right
        shade = 1.0 - 0.18 * u * u                                 # rounded at the sides
        return (rgb[0] * shade, rgb[1] * shade, rgb[2] * shade, 1.0)
    if d <= 0.0:
        return RIM_RGB + (1.0,)
    # The gold plate: bright at the top, bronze at the foot, a shine just
    # inside the outline along the top.
    t = py / BAR_H
    rgb = mix(GOLD_TOP, GOLD_MID, t / 0.5) if t < 0.5 else mix(GOLD_MID, GOLD_FOOT, (t - 0.5) / 0.5)
    if outer > -(OUTLINE + 1.6) and py < CY:
        rgb = mix(rgb, GOLD_SHINE, 0.65)
    return rgb + (1.0,)


def paint_bar(full):
    """One bar, BAR_H rows of BAR_W (r, g, b, a) texels, supersampled; the
    colour averaged by coverage (straight alpha), the coverage by count."""
    n = SUPERSAMPLE
    rows = []
    for y in range(BAR_H):
        row = []
        for x in range(BAR_W):
            sr = sg = sb = sa = 0.0
            for j in range(n):
                for i in range(n):
                    r, g, b, a = sample(x + (i + 0.5) / n, y + (j + 0.5) / n, full)
                    sr, sg, sb, sa = sr + r * a, sg + g * a, sb + b * a, sa + a
            if sa == 0.0:
                row.append((0, 0, 0, 0))
                continue
            row.append((int(sr / sa + 0.5), int(sg / sa + 0.5), int(sb / sa + 0.5), int(sa * 255 / (n * n) + 0.5)))
        rows.append(row)
    return rows


def build():
    pixels = []
    for full in (False, True):
        for row in paint_bar(full):
            pixels.append(row + [(0, 0, 0, 0)] * (WIDTH - BAR_W))
    return pixels


def validate(pixels):
    assert len(pixels) == HEIGHT and all(len(row) == WIDTH for row in pixels), "512x64 atlas"
    # The plate is the same in both rows: only the windows differ.
    for y in range(ROW):
        for x in range(BAR_W):
            empty, full = pixels[y][x], pixels[ROW + y][x]
            if empty != full:
                inside = any(abs(x + 0.5 - wx) < hx and WINDOW_Y0 <= y + 0.5 <= WINDOW_Y1 for wx, hx in WINDOWS)
                assert inside, f"the plate differs between the rows at ({x}, {y})"
    assert all(pixels[y][x][3] == 0 for y in range(HEIGHT) for x in range(BAR_W, WIDTH)), "unused columns clear"


# Menu.lua's scale: each window is 4% of the Balanced kart's value, which
# fills four of the six (the preview shows the three handling profiles).
PROFILES = {
    "Balanced": (4, 4, 4, 4),
    "Heavy": (5, 2, 2, 6),
    "Agile": (3, 6, 6, 2),
}
LABELS = ("Speed", "Acceleration", "Turning", "Braking")


def preview(pixels):
    """The atlas at full size, then each profile's four bars as the menu
    composes them (row 0, row 1 cropped), half size like the menu, on the
    dialog's dark background."""
    bg = (18, 16, 14)
    width = WIDTH + 24
    out = [[bg] * width for _ in range(12)]
    for y in range(HEIGHT):
        out.append([bg] * 12 + [blend(bg, p) for p in pixels[y]] + [bg] * 12)
    out += [[bg] * width for _ in range(12)]
    half = []
    for y in range(0, HEIGHT, 2):          # the menu's size: 2x2 texels averaged per pixel
        line = []
        for x in range(0, BAR_W, 2):
            quad = [pixels[y + dy][x + dx] for dy in (0, 1) for dx in (0, 1)]
            a = sum(q[3] for q in quad)
            if a == 0:
                line.append((0, 0, 0, 0))
                continue
            line.append(tuple((sum(q[c] * q[3] for q in quad) + a // 2) // a for c in range(3)) + ((a + 2) // 4,))
        half.append(line)
    empty, full = half[:ROW // 2], half[ROW // 2:]
    for name, values in PROFILES.items():
        for segments in values:
            cut = BAR_W // 2 * segments // SEGMENTS
            for y in range(ROW // 2):
                line = [blend(bg, full[y][x] if x < cut else empty[y][x]) for x in range(BAR_W // 2)]
                out.append([bg] * 120 + line + [bg] * (width - 120 - BAR_W // 2))
            out += [[bg] * width for _ in range(6)]
        out += [[bg] * width for _ in range(14)]
    return [[tuple(c) + (255,) for c in row] for row in out]


def blend(bg, p):
    a = p[3]
    return tuple((p[c] * a + bg[c] * (255 - a) + 127) // 255 for c in range(3))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify the TGA without writing")
    parser.add_argument("--preview", action="store_true", help="also write the review PNG")
    args = parser.parse_args()
    pixels = build()
    validate(pixels)
    data = encode_tga(pixels)
    _, decoded = decode_tga(data)
    assert [tuple(p) for row in decoded for p in row] == [p for row in pixels for p in row], "round trip"
    relative = OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != data:
            raise SystemExit(f"STALE: {relative}; run without --check")
        print(f"CHECK PASS: {relative}; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(data)
        print(f"WROTE: {relative}; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    if args.preview:
        PREVIEW.parent.mkdir(parents=True, exist_ok=True)
        PREVIEW.write_bytes(encode_png(preview(pixels)))
        print(f"WROTE: {PREVIEW.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    main()
