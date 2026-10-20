"""Paint Azeroth Kart's drift and boost effect textures.

python scripts/build_effect_sprites.py            # write the runtime TGAs
python scripts/build_effect_sprites.py --check    # verify exact bytes/invariants, write nothing
python scripts/build_effect_sprites.py --preview  # also write docs/art/effects/drift-boost-atlases.png

Two original, procedurally painted atlases; no model, photo or external
image is an input:

- Particles.tga, 256x128: four soft smoke puffs (64x64 cells, top row) and
  sixteen spark streaks (32x32 cells, the two rows below). Streak k points
  k * 2pi/16 counter-clockwise from east, head first.
- Flame.tga, 512x256: thirty-two exhaust flames (64x64 cells). Flame k points
  along world heading k * 2pi/32 as the kart sheets' three-quarter camera sees
  it (north is foreshortened by the same 0.8), with its base at the cell
  center so the cell can be centered on an exhaust pipe.

Cells are read left to right and top to bottom. Every texel is white or
near-white; SetVertexColor colors them at runtime, so one puff serves tire
dust and exhaust soot and one streak serves every drift tier. Sparks carry a
faint dark halo so they stay readable on the pale salt flats. Each cell keeps
a transparent one-texel border, and transparent texels get bled edge color.

Only IEEE arithmetic (+ - * /, sqrt, floor) and integer hashing feed texel
values (directions come from half-angle square roots), so the bytes are
identical on every platform.
"""
import argparse
import hashlib
from math import sqrt
from pathlib import Path

from build_wc3_kart import TILT_COS, directions   # 64 headings without libm trigonometry
from paintkit import bleed, clamp, decode_tga, encode_png, encode_tga, value_noise

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "addon" / "AzerothKart" / "Assets" / "Effects"
DOCS = ROOT / "docs" / "art" / "effects"

# Must agree with Presentation.EFFECTS (tests re-read both atlases).
PARTICLES_WIDTH, PARTICLES_HEIGHT = 256, 128
SMOKE_CELL, SMOKE_VARIANTS = 64, 4                # top row
SPARK_CELL, SPARK_DIRECTIONS, SPARK_COLUMNS = 32, 16, 8
SPARK_TOP = SMOKE_CELL                            # spark rows start below the puffs
FLAME_WIDTH, FLAME_HEIGHT = 512, 256
FLAME_CELL, FLAME_DIRECTIONS, FLAME_COLUMNS = 64, 32, 8


def sq(x):
    return x * x


def unit(i, j, size):
    """Cell texel center in [-1, 1], +y up."""
    return (i + 0.5) / size * 2.0 - 1.0, 1.0 - (j + 0.5) / size * 2.0


def quantize(color, alpha):
    a = int(255.0 * clamp(alpha) + 0.5)
    if a == 0:
        return [0, 0, 0, 0]
    c = int(255.0 * clamp(color) + 0.5)
    return [c, c, c, a]


def transparent_border(cell):
    size = len(cell)
    for j in range(size):
        for i in range(size):
            if j in (0, size - 1) or i in (0, size - 1):
                cell[j][i] = [0, 0, 0, 0]
    return bleed(cell)


def smoke_cell(seed):
    """A lumpy, soft-edged puff, lit from the scenery's north-west."""
    size, cell = SMOKE_CELL, []
    for j in range(size):
        row = []
        for i in range(size):
            u, v = unit(i, j, size)
            lumps = value_noise(i, j, 9.0, seed)
            grain = value_noise(i, j, 4.0, seed + 11)
            r = sqrt(u * u + v * v) / 0.9 * (1.0 + 0.24 * (lumps - 0.5))
            d = 1.0 - r * r
            if d <= 0.0:
                row.append([0, 0, 0, 0])
                continue
            density = d * d * (0.68 + 0.32 * grain) * 1.05
            light = 0.80 + 0.20 * clamp(0.5 + 0.6 * (0.8 * v - 0.6 * u))
            row.append(quantize(light, density))
        cell.append(row)
    return transparent_border(cell)


def spark_cell(c, s):
    """A tapered streak pointing (c, s): white core, soft glow, faint dark halo."""
    size, cell = SPARK_CELL, []
    for j in range(size):
        row = []
        for i in range(size):
            x, y = unit(i, j, size)
            along, across = x * c + y * s, y * c - x * s
            if along > 0.72:
                body = sq(max(0.0, 1.0 - sq((along - 0.72) / 0.14)))      # rounded head
            elif along >= -0.72:
                t = (along + 0.72) / 1.44
                body = t * sqrt(t)                                          # fades toward the tail
            else:
                body = 0.0
            core = sq(max(0.0, 1.0 - sq(across / 0.16)))
            glow = 0.5 * sq(max(0.0, 1.0 - sq(across / 0.38)))
            light = body * min(1.0, core + glow)
            dark = 0.40 * body * sq(max(0.0, 1.0 - sq(across / 0.54))) * (1.0 - light)
            alpha = light + dark
            row.append(quantize((light + 0.10 * dark) / alpha, alpha) if alpha > 0.0 else [0, 0, 0, 0])
        cell.append(row)
    return transparent_border(cell)


def flame_cell(c, s, seed):
    """An exhaust jet along world heading (c, s), seen by the tilted camera; base at the center."""
    size, cell = FLAME_CELL, []
    ax, ay = c, s * TILT_COS
    length = sqrt(ax * ax + ay * ay)
    ux, uy = ax / length, ay / length
    reach = 0.94 * length
    for j in range(size):
        row = []
        for i in range(size):
            x, y = unit(i, j, size)
            along, across = x * ux + y * uy, y * ux - x * uy
            if along < 0.0:                                                 # rounded pipe mouth
                d = (along * along + across * across) / sq(0.07)
                intensity, t = 0.9 * sq(max(0.0, 1.0 - d)), 0.0
            else:
                t = along / reach
                if t >= 1.0:
                    row.append([0, 0, 0, 0])
                    continue
                licks = value_noise(along * size * 0.5, across * size, 5.0, seed)
                # Narrow at the mouth, flared plume, long pointed tail.
                width = (0.08 + 0.18 * sqrt(t)) * (1.0 - t * t) * (0.85 + 0.30 * licks)
                q = 1.0 - sq(across / width) if width > 0.0 else 0.0
                intensity = sqrt(q) * (1.0 - 0.75 * t * t) if q > 0.0 else 0.0
            row.append(quantize(1.0 - 0.45 * t, intensity))
        cell.append(row)
    return transparent_border(cell)


def place(atlas, cell, ox, oy):
    for j, row in enumerate(cell):
        atlas[oy + j][ox:ox + len(row)] = row


def build():
    headings = directions()                       # 64 entries; subsample for 32 and 16
    particles = [[[0, 0, 0, 0] for _ in range(PARTICLES_WIDTH)] for _ in range(PARTICLES_HEIGHT)]
    for k in range(SMOKE_VARIANTS):
        place(particles, smoke_cell(101 + 17 * k), k * SMOKE_CELL, 0)
    for k in range(SPARK_DIRECTIONS):
        c, s = headings[k * (64 // SPARK_DIRECTIONS)]
        place(particles, spark_cell(c, s), (k % SPARK_COLUMNS) * SPARK_CELL,
              SPARK_TOP + (k // SPARK_COLUMNS) * SPARK_CELL)
    flame = [[[0, 0, 0, 0] for _ in range(FLAME_WIDTH)] for _ in range(FLAME_HEIGHT)]
    for k in range(FLAME_DIRECTIONS):
        c, s = headings[k * (64 // FLAME_DIRECTIONS)]
        place(flame, flame_cell(c, s, 307), (k % FLAME_COLUMNS) * FLAME_CELL, (k // FLAME_COLUMNS) * FLAME_CELL)
    return {"Particles.tga": particles, "Flame.tga": flame}


# ---------------------------------------------------------------------------
# Validation: packaging, cell borders, coverage and orientation.


def cells(name):
    if name == "Particles.tga":
        out = [(k * SMOKE_CELL, 0, SMOKE_CELL, None) for k in range(SMOKE_VARIANTS)]
        headings = directions()
        out += [((k % SPARK_COLUMNS) * SPARK_CELL, SPARK_TOP + (k // SPARK_COLUMNS) * SPARK_CELL, SPARK_CELL,
                 headings[k * (64 // SPARK_DIRECTIONS)]) for k in range(SPARK_DIRECTIONS)]
        return out
    headings = directions()
    return [((k % FLAME_COLUMNS) * FLAME_CELL, (k // FLAME_COLUMNS) * FLAME_CELL, FLAME_CELL,
             (headings[k * 2][0], headings[k * 2][1] * TILT_COS)) for k in range(FLAME_DIRECTIONS)]


def validate(name, image, width, height):
    fields, px = decode_tga(image)
    assert fields == (0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 8), f"{name}: unexpected TGA header"
    assert len(image) == 18 + width * height * 4, f"{name}: unexpected payload size"
    smallest = None
    for ox, oy, size, direction in cells(name):
        covered, mx, my = 0, 0.0, 0.0
        for j in range(size):
            for i in range(size):
                a = px[oy + j][ox + i][3]
                if j in (0, size - 1) or i in (0, size - 1):
                    assert a == 0, f"{name}: cell at {ox},{oy} needs a transparent border"
                if a:
                    covered += 1
                    x, y = unit(i, j, size)
                    mx += x * a
                    my += y * a
        assert covered > size * size // 40, f"{name}: cell at {ox},{oy} is unexpectedly empty"
        if direction is not None:                 # weight leans toward the head/tip
            assert mx * direction[0] + my * direction[1] > 0.0, f"{name}: cell at {ox},{oy} points the wrong way"
        smallest = covered if smallest is None else min(smallest, covered)
    return smallest


def review_sheet(images):
    """Atlases on a checkerboard, then tinted samples on dark lane and pale salt."""
    particles, flame = images["Particles.tga"], images["Flame.tga"]
    tints = [(0.40, 0.68, 1.00), (1.00, 0.80, 0.16), (1.00, 0.36, 0.78),     # spark tiers
             (0.95, 0.90, 0.81), (0.24, 0.22, 0.21),                          # Mirage dust, soot
             (1.00, 0.52, 0.12), (1.00, 0.93, 0.62)]                          # flame outer, inner
    grounds = [(92, 72, 52), (226, 214, 190)]
    zoom, gap, tile = 2, 8, 64
    width = gap + FLAME_WIDTH + gap
    height = gap + PARTICLES_HEIGHT * zoom + gap + FLAME_HEIGHT + gap + 2 * (tile + gap)
    sheet = [[[24, 24, 28, 255] for _ in range(width)] for _ in range(height)]

    def over(y, x, rgb, a):
        base = sheet[y][x]
        sheet[y][x] = [int(rgb[k] * a + base[k] * (1.0 - a) + 0.5) for k in range(3)] + [255]

    for y in range(PARTICLES_HEIGHT * zoom):
        for x in range(PARTICLES_WIDTH * zoom):
            r, g, b, a = particles[y // zoom][x // zoom]
            check = 150 if ((x // 8) + (y // 8)) % 2 else 110
            sheet[gap + y][gap + x] = [(r * a + check * (255 - a)) // 255] * 3 + [255]
    top = gap + PARTICLES_HEIGHT * zoom + gap
    for y in range(FLAME_HEIGHT):
        for x in range(FLAME_WIDTH):
            r, g, b, a = flame[y][x]
            check = 150 if ((x // 8) + (y // 8)) % 2 else 110
            sheet[top + y][gap + x] = [(r * a + check * (255 - a)) // 255] * 3 + [255]
    top += FLAME_HEIGHT + gap
    samples = [(particles, 0, 0, SMOKE_CELL, 3), (particles, 0, 0, SMOKE_CELL, 4),
               (particles, 2 * SPARK_CELL, SPARK_TOP, SPARK_CELL, 0),
               (particles, 2 * SPARK_CELL, SPARK_TOP, SPARK_CELL, 1),
               (particles, 2 * SPARK_CELL, SPARK_TOP, SPARK_CELL, 2),
               (flame, 0, 2 * FLAME_CELL, FLAME_CELL, 5), (flame, 0, 2 * FLAME_CELL, FLAME_CELL, 6)]
    for row, ground in enumerate(grounds):
        oy = top + row * (tile + gap)
        for y in range(tile):
            for x in range(width):
                sheet[oy + y][x] = list(ground) + [255]
        for n, (atlas, cx, cy, size, tint) in enumerate(samples):
            ox = gap + n * (tile + gap)
            for y in range(tile):
                for x in range(tile):
                    r, g, b, a = atlas[cy + y * size // tile][cx + x * size // tile]
                    rgb = [r * tints[tint][0], g * tints[tint][1], b * tints[tint][2]]
                    over(oy + y, ox + x, rgb, a / 255.0)
    return sheet


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify exact runtime bytes without writing")
    parser.add_argument("--preview", action="store_true", help="also write a review PNG under docs/art/effects/")
    args = parser.parse_args()
    images = build()
    sizes = {"Particles.tga": (PARTICLES_WIDTH, PARTICLES_HEIGHT), "Flame.tga": (FLAME_WIDTH, FLAME_HEIGHT)}
    for name, pixels in images.items():
        image = encode_tga(pixels)
        smallest = validate(name, image, *sizes[name])
        output = ASSETS / name
        if args.check:
            if not output.is_file() or output.read_bytes() != image:
                raise SystemExit(f"STALE: {output.relative_to(ROOT).as_posix()}; run without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(image)
        width, height = sizes[name]
        print(f'{"CHECK PASS" if args.check else "GENERATED"}: {output.relative_to(ROOT).as_posix()}; '
              f"{width}x{height} BGRA32 straight alpha bottom-left; {len(image)} bytes; "
              f"at least {smallest} covered texels per cell; sha256={hashlib.sha256(image).hexdigest()}")
    if args.preview and not args.check:
        DOCS.mkdir(parents=True, exist_ok=True)
        (DOCS / "drift-boost-atlases.png").write_bytes(encode_png(review_sheet(images)))
        print("PREVIEW: docs/art/effects/drift-boost-atlases.png")


if __name__ == "__main__":
    main()
