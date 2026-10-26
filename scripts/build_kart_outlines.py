"""Derive each kart sheet's outline sheet: the optional bright line round the
player's own kart (Settings: "Outline my kart").

python scripts/build_kart_outlines.py            # write every outline sheet
python scripts/build_kart_outlines.py --check    # verify exact bytes/invariants, write nothing
python scripts/build_kart_outlines.py --preview  # also write docs/art/karts/kart-outlines-review.png

The only input is the kart sheets themselves (addon/AzerothKart/Assets/Karts/,
see build_wc3_kart.py): no model or texture outside the repository. For each
of a sheet's 64 frames the kart's body is its texels at least half opaque
(the baked ground shadow, at most 42% opaque, is not body). The outline is
every texel outside the body within RING texels of it, fully opaque, fading
over one more texel; then the frame is halved (exact 2x2 integer box filter).
So an outline sheet is 512x512: the same 8x8 grid of frames, 64 texels each,
covering the same quad as its kart's frames, so the kart's frame crop and
quad place it exactly. A sheet with wing phases (2048x2048, 16x16 frames)
gets a 1024x1024 outline of every frame of every phase. Its colour is white, tinted by the UI; it is drawn
over the kart, which it never covers, and over its shadow, which would
otherwise dim it.

Standard library only. Distances come from integer offsets and IEEE square
roots, so the bytes are the same on every platform.
"""
import argparse
import hashlib
from math import sqrt
from pathlib import Path

import build_wc3_kart as kart
from paintkit import decode_tga, encode_png, encode_tga

ROOT = Path(__file__).resolve().parents[1]
OUTLINES = kart.ASSETS / "Outlines"
FRAME, COLUMNS, FRAMES = kart.FRAME, kart.COLUMNS, kart.FRAMES      # 128-texel frames, 8 columns, 64
HALF = FRAME // 2                                                    # outline frame side
BODY = 128            # alpha from which a kart texel is body
RING = 5              # outline width in kart texels (full opacity), then a one-texel fade
REACH = RING + 1
DISK = [(dx, dy, dx * dx + dy * dy) for dy in range(-REACH, REACH + 1) for dx in range(-REACH, REACH + 1)
        if 0 < dx * dx + dy * dy <= REACH * REACH]


def outline_frame(alpha, ox, oy, width):
    """Outline alpha (HALF x HALF, rows top first) of the frame at (ox, oy) of a
    sheet whose top-down alpha plane is `alpha` (`width` texels a row)."""
    body = bytearray(FRAME * FRAME)
    for j in range(FRAME):
        base = (oy + j) * width + ox
        for i in range(FRAME):
            body[j * FRAME + i] = alpha[base + i] >= BODY
    nearest = [REACH * REACH + 1] * (FRAME * FRAME)       # squared distance to the body, out to REACH
    for j in range(FRAME):
        for i in range(FRAME):
            if not body[j * FRAME + i]:
                continue
            edge = False                                  # a body texel with open ground beside it
            for dj, di in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                y, x = j + dj, i + di
                if 0 <= y < FRAME and 0 <= x < FRAME and not body[y * FRAME + x]:
                    edge = True
                    break
            if not edge:
                continue
            for dx, dy, d2 in DISK:
                y, x = j + dy, i + dx
                if 0 <= y < FRAME and 0 <= x < FRAME:
                    k = y * FRAME + x
                    if not body[k] and d2 < nearest[k]:
                        nearest[k] = d2
    full = bytearray(FRAME * FRAME)
    for k in range(FRAME * FRAME):
        d2 = nearest[k]
        if d2 <= RING * RING:
            full[k] = 255
        elif d2 <= REACH * REACH:
            full[k] = int((REACH - sqrt(d2)) * 255.0 + 0.5)
    rows = []
    for j in range(HALF):
        row = []
        for i in range(HALF):
            k = 2 * j * FRAME + 2 * i
            row.append((full[k] + full[k + 1] + full[k + FRAME] + full[k + FRAME + 1] + 2) // 4)
        rows.append(row)
    for j in range(HALF):                                 # a clear border: no neighbouring frame filters in
        for i in range(HALF):
            if j in (0, HALF - 1) or i in (0, HALF - 1):
                rows[j][i] = 0
    return rows


def sheet_alpha(image):
    """Top-down alpha plane of a bottom-left-origin BGRA32 TGA."""
    width, height = image[12] | image[13] << 8, image[14] | image[15] << 8
    plane = bytearray(width * height)
    for row in range(height):
        src = 18 + (height - 1 - row) * width * 4 + 3
        plane[row * width:(row + 1) * width] = image[src:src + width * 4:4]
    return width, height, plane


def grid(width, height, name):
    """Frame columns and rows of a kart sheet: 8x8, or 16x16 with four wing phases."""
    assert (width, height) in ((kart.ATLAS, kart.ATLAS), (2 * kart.ATLAS, 2 * kart.ATLAS)), \
        f"{name}: not a {kart.ATLAS}- or {2 * kart.ATLAS}-texel kart sheet"
    return width // FRAME, height // FRAME


def build(sheet_path):
    image = sheet_path.read_bytes()
    width, height, alpha = sheet_alpha(image)
    columns, rows_ = grid(width, height, sheet_path.name)
    pixels = [[[255, 255, 255, 0] for _ in range(columns * HALF)] for _ in range(rows_ * HALF)]
    for k in range(columns * rows_):
        ox, oy = (k % columns) * FRAME, (k // columns) * FRAME
        rows = outline_frame(alpha, ox, oy, width)
        hx, hy = (k % columns) * HALF, (k // columns) * HALF
        for j in range(HALF):
            line = pixels[hy + j]
            for i in range(HALF):
                line[hx + i][3] = rows[j][i]
    return pixels, alpha


def validate(pixels, alpha, name):
    """Every frame has a line; it keeps off the body and the frame border."""
    columns, rows = len(pixels[0]) // HALF, len(pixels) // HALF
    width = columns * FRAME
    assert len(alpha) == width * rows * FRAME and all(len(row) == columns * HALF for row in pixels), f"{name}: size"
    fewest = None
    for k in range(columns * rows):
        hx, hy = (k % columns) * HALF, (k // columns) * HALF
        ox, oy = (k % columns) * FRAME, (k // columns) * FRAME
        lit = 0
        for j in range(HALF):
            for i in range(HALF):
                a = pixels[hy + j][hx + i][3]
                if j in (0, HALF - 1) or i in (0, HALF - 1):
                    assert a == 0, f"{name}: frame {k} keeps a transparent border"
                if a == 0:
                    continue
                lit += 1
                base = (oy + 2 * j) * width + ox + 2 * i
                block = (alpha[base], alpha[base + 1], alpha[base + width], alpha[base + width + 1])
                assert min(block) < BODY, f"{name}: frame {k} line covers the kart at ({i}, {j})"
        assert lit > 0, f"{name}: frame {k} has no outline"
        fewest = lit if fewest is None else min(fewest, lit)
    return fewest


def review(sheets):
    """Each kart over the Mirage ground at two headings, with and without its
    line, at about 1440p size (1.47 pixels per world unit), enlarged 2x."""
    from math import floor, pi
    from paintkit import sample_bilinear
    bg = kart.load_background()
    ppu, size, zoom = 1.47, 80, 2
    color = (1.0, 0.92, 0.16)                         # the UI's tint
    tiles = []
    for vehicle, sheet, outline in sheets:
        columns = len(sheet[0]) // FRAME                  # the rest pose: the first FRAMES cells
        for heading in (pi / 2 + pi / 8, -pi / 4 + pi / 16):
            k = int(floor(heading / (2 * pi / FRAMES) + 0.5)) % FRAMES
            fx, fy = (k % columns) * FRAME, (k // columns) * FRAME
            hx, hy = (k % columns) * HALF, (k // columns) * HALF
            frame = [row[fx:fx + FRAME] for row in sheet[fy:fy + FRAME]]
            line = [row[hx:hx + HALF] for row in outline[hy:hy + HALF]]
            for lit in (False, True):
                tile = []
                for j in range(size * zoom):
                    row = []
                    for i in range(size * zoom):
                        dx = (i / zoom + 0.5 - size / 2) / ppu
                        dy = (size / 2 - j / zoom - 0.5) / ppu
                        c = kart.background_color(bg, 700 + dx, 600 + dy)
                        quad, (px, py) = vehicle["quad"], vehicle["pivot"]
                        u, v = (dx - px + quad / 2) / quad, (py + quad / 2 - dy) / quad
                        if 0 <= u < 1 and 0 <= v < 1:
                            r, g, b, a = sample_bilinear(frame, u * FRAME, v * FRAME)
                            a /= 255.0
                            c = [r * a + c[0] * (1 - a), g * a + c[1] * (1 - a), b * a + c[2] * (1 - a)]
                            if lit:
                                a = sample_bilinear(line, u * HALF, v * HALF)[3] / 255.0
                                c = [255 * color[n] * a + c[n] * (1 - a) for n in range(3)]
                        row.append([int(min(255.0, c[0]) + 0.5), int(min(255.0, c[1]) + 0.5),
                                    int(min(255.0, c[2]) + 0.5), 255])
                    tile.append(row)
                tiles.append(tile)
    per_row, gap, edge = 8, 4, size * zoom
    rows = []
    for start in range(0, len(tiles), per_row):
        group = tiles[start:start + per_row]
        for j in range(edge):
            line = []
            for tile in group:
                line += tile[j] + [[24, 24, 28, 255]] * gap
            line += [[24, 24, 28, 255]] * ((per_row - len(group)) * (edge + gap))
            rows.append(line)
        rows += [[[24, 24, 28, 255]] * len(rows[-1]) for _ in range(gap)]
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify exact runtime bytes without writing")
    parser.add_argument("--preview", action="store_true", help="also write the review PNG under docs/art/karts/")
    args = parser.parse_args()
    reviewed = []
    for vehicle in kart.VEHICLES.values():
        source = kart.ASSETS / vehicle["output"]
        pixels, alpha = build(source)
        fewest = validate(pixels, alpha, vehicle["output"])
        image = encode_tga(pixels)
        output = OUTLINES / vehicle["output"]
        relative = output.relative_to(ROOT).as_posix()
        if args.check:
            if not output.is_file() or output.read_bytes() != image:
                raise SystemExit(f"STALE: {relative}; run this script without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(image)
        print(f'{"CHECK PASS" if args.check else "GENERATED"}: {relative}; {len(pixels[0])}x{len(pixels)} '
              f"BGRA32 white, alpha line {RING}+1 kart texels wide; {len(image)} bytes; at least {fewest} lit "
              f"texels per frame; from {vehicle['output']}; sha256={hashlib.sha256(image).hexdigest()}")
        if args.preview and not args.check:
            reviewed.append((vehicle, decode_tga(source.read_bytes())[1], pixels))
    if reviewed:
        (kart.DOCS / "kart-outlines-review.png").write_bytes(encode_png(review(reviewed)))
        print("PREVIEW: docs/art/karts/kart-outlines-review.png")


if __name__ == "__main__":
    main()
