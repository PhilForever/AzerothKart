"""Paint one Scarlet Crusade Cup dungeon for build_dungeon_tracks.py.

A dungeon is its rooms: the floor the karts drive and, everywhere else, the
monastery's masonry. The picture shows it from the karts' camera (height
leans north by `lean`, as in the cities). Layers, bottom to top:

1. Masonry: everything off the floor is the walls' tops, dark stone in
   courses, darkest far from any room.
2. Floors: each room's Warcraft III tile in its style (a later room paints
   over an earlier: the cloister's path over its lawn; a round room is the
   disc in its square), with the dungeon's carpets, a round room's rings,
   stairs and the portal the karts arrive through; shade along the foot of
   every wall; the chequered finish across the last gate.
3. Walls: the camera sees a room's north wall, so it rises `height` x lean
   rows over the masonry beyond, in a Warcraft III city wall's stones, its
   coping lit along the top. Every other wall shows its coping edge.
4. Lights, then the models, north to south so nearer things cover farther
   ones: banners, torches, braziers and lanterns, graves, tombs and trees,
   the dead and the living. Each model is rendered by wc3render.py with its
   ground shadow.
5. Grade: moonlight on the open cloister (`moonlight`, `mist`); the halls
   stay lamplit.

One texel per world unit; row 0 is the north edge. Integer compositing, no
transcendental function feeds a pixel: the bytes are the same on every
machine.
"""
import hashlib
from math import sqrt
from pathlib import Path

from city_paint import Picture, Strata, Tileset, bank_distance, hash32, paint_sprite, sprite_for
from paintkit import encode_png, encode_tga
from wc3render import forget_textures

ROOT = Path(__file__).resolve().parents[1]


def _masks(d, w, h):
    """Per texel (row 0 north): the floor style's index (0: masonry), and
    whether the room there is open to the sky."""
    names = [None] + sorted({r["floor"] for r in d["rooms"]})
    style = bytearray(w * h)
    sky = bytearray(w * h)
    open_sky = set(d.get("open_sky", ()))
    for r in d["rooms"]:
        k = names.index(r["floor"])
        open_ = 1 if r["name"] in open_sky else 0
        x0, x1 = int(r["x0"]), int(r["x1"])
        if r.get("shape") == "disc":
            # A round room: every texel whose centre lies within the radius.
            cx, cy, radius = (r["x0"] + r["x1"]) / 2, (r["y0"] + r["y1"]) / 2, (r["x1"] - r["x0"]) / 2
            for y in range(int(r["y0"]), int(r["y1"])):
                base = (h - 1 - y) * w
                for x in range(x0, x1):
                    dx, dy = x + 0.5 - cx, y + 0.5 - cy
                    if dx * dx + dy * dy <= radius * radius:
                        style[base + x] = k
                        sky[base + x] = open_
            continue
        for y in range(int(r["y0"]), int(r["y1"])):
            base = (h - 1 - y) * w
            style[base + x0:base + x1] = bytes([k]) * (x1 - x0)
            sky[base + x0:base + x1] = bytes([open_]) * (x1 - x0)
    return names, style, sky


def _room(d, name):
    return next(r for r in d["rooms"] if r["name"] == name)


def paint_masonry(pic, d, floor):
    """The walls' tops: dark stone laid in courses (32 x 16 blocks, the
    joints darker), each block its own shade, darker still away from the
    rooms."""
    w, h = pic.w, pic.h
    tr, tg, tb = d["wall"]["top"]
    near = bank_distance(bytearray(1 - v for v in floor), w, h, 48)   # distance into the masonry
    for row in range(h):
        y = h - 1 - row
        course = y // 16
        base = row * w
        for x in range(w):
            i = base + x
            if floor[i]:
                continue
            bx = (x + (course % 2) * 16) // 32
            v = hash32(bx, course, 401) % 15 - 7
            joint = y % 16 == 0 or (x + (course % 2) * 16) % 32 == 0
            k = 236 if joint else 256
            k = k * (256 - near[i] * 2) >> 8                  # deeper into the mass, darker
            pic.r[i] = max(0, min(255, (tr + v) * k >> 8))
            pic.g[i] = max(0, min(255, (tg + v) * k >> 8))
            pic.b[i] = max(0, min(255, (tb + v) * k >> 8))


def paint_floors(pic, d, tiles, names, style, floor):
    """Each room's tile; shade along the foot of every wall."""
    w, h = pic.w, pic.h
    specs = [None] + [d["floors"][n] for n in names[1:]]
    edge = bank_distance(floor, w, h, 14)                 # distance from the wall's foot
    for row in range(h):
        y = h - 1 - row
        base = row * w
        for x in range(w):
            i = base + x
            k = style[i]
            if not k:
                continue
            spec = specs[k]
            r, g, b, _ = tiles.whole(spec["tile"], x, y, seed=spec.get("seed", 3), shade=spec["shade"])
            e = edge[i]
            if e <= 1:
                s = 150                                   # the skirting stone at the wall's foot
            else:
                s = 196 + 60 * min(e, 14) // 14            # the walls' shade on the floor
            pic.r[i], pic.g[i], pic.b[i] = r * s >> 8, g * s >> 8, b * s >> 8


CARPET = (132, 20, 24)
CARPET_EDGE = (196, 150, 58)


def paint_carpets(pic, d, floor):
    """The Scarlet Crusade's red runners down the halls, gold-edged, each a
    run of straight lengths turning square at its corners."""
    w, h = pic.w, pic.h
    mask = bytearray(w * h)
    for points, width in d.get("carpets", ()):
        half = width // 2
        for (ax, ay), (bx, by) in zip(points, points[1:]):
            x0, x1 = min(ax, bx) - half, max(ax, bx) + half
            y0, y1 = min(ay, by) - half, max(ay, by) + half
            for y in range(y0, y1):
                base = (h - 1 - y) * w
                for x in range(x0, x1):
                    if floor[base + x]:
                        mask[base + x] = 1
    edge = bank_distance(mask, w, h, 4)
    for i in range(w * h):
        if not mask[i]:
            continue
        row, x = divmod(i, w)
        c = CARPET_EDGE if edge[i] <= 3 and edge[i] >= 2 else CARPET
        if edge[i] == 1:
            c = (96, 14, 18)                              # the runner's dark hem
        v = hash32(x // 2, row // 2, 409) % 11 - 5
        pic.r[i] = max(0, min(255, c[0] + v))
        pic.g[i] = max(0, min(255, c[1] + v // 2))
        pic.b[i] = max(0, min(255, c[2] + v // 2))


GOLD = (204, 160, 64)


def paint_rings(pic, d, floor):
    """A round room's floor in rings about its centre (the round library's
    stone, gold ring and Scarlet carpet). `rings` = {"room": name, "bands":
    [(outer radius, kind), ...]}, innermost first: "floor" keeps the room's
    tile, "gold" lays a gilt ring, "carpet" the red carpet, its edges hemmed
    dark and gold. Beyond the last band the tile runs on to the wall."""
    spec = d.get("rings")
    if not spec:
        return
    w, h = pic.w, pic.h
    r = _room(d, spec["room"])
    cx, cy = (r["x0"] + r["x1"]) / 2, (r["y0"] + r["y1"]) / 2
    for y in range(int(r["y0"]), int(r["y1"])):
        for x in range(int(r["x0"]), int(r["x1"])):
            i = (h - 1 - y) * w + x
            if not floor[i]:
                continue
            dist = sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2)
            inner, kind, outer = 0.0, None, 0.0
            for outer, kind in spec["bands"]:
                if dist < outer:
                    break
                inner = outer
            else:
                continue
            if kind == "floor":
                continue
            edge = min(dist - inner, outer - dist)            # texels from the band's nearer edge
            v = hash32(x // 2, y // 2, 431) % 11 - 5
            if kind == "gold":
                k = 200 if edge < 1.5 else 256
                c = (GOLD[0] * k >> 8, GOLD[1] * k >> 8, GOLD[2] * k >> 8)
            elif edge < 1.5:
                c = (96, 14, 18)                                 # the carpet's dark hem
            elif edge < 4.5:
                c = CARPET_EDGE
            else:
                c = CARPET
            pic.r[i] = max(0, min(255, c[0] + v))
            pic.g[i] = max(0, min(255, c[1] + v // 2))
            pic.b[i] = max(0, min(255, c[2] + v // 2))


def paint_kerbs(pic, d, style, names, floor):
    """A stone kerb where a paved room meets the lawn (`kerbed` floors)."""
    w, h = pic.w, pic.h
    for name in d.get("kerbed", ()):
        k = names.index(name)
        mask = bytearray(1 if v == k else 0 for v in style)
        edge = bank_distance(mask, w, h, 4)
        lawn = names.index("lawn")
        for i in range(w * h):
            if not mask[i] or edge[i] > 3:
                continue
            # Only along the lawn, not the walls.
            row, x = divmod(i, w)
            beside = False
            for j in (i - 4 * w, i + 4 * w, i - 4, i + 4):
                if 0 <= j < w * h and style[j] == lawn:
                    beside = True
            if not beside:
                continue
            s = 300 if edge[i] >= 2 else 200
            v = hash32(x // 6, row // 6, 413) % 17 - 8
            pic.r[i] = max(0, min(255, (150 + v) * s >> 8))
            pic.g[i] = max(0, min(255, (146 + v) * s >> 8))
            pic.b[i] = max(0, min(255, (136 + v) * s >> 8))


def paint_room_lights(pic, lights, floor, faced):
    """Pools of light, (x, y, radius, (r, g, b)) each, added to the colour:
    full on the floor, less on the wall faces, a glimmer on the walls' tops."""
    w, h = pic.w, pic.h
    for lx, ly, radius, (gr, gg, gb) in lights:
        for y in range(max(0, int(ly - radius)), min(h, int(ly + radius) + 1)):
            for x in range(max(0, int(lx - radius)), min(w, int(lx + radius) + 1)):
                dd = (x + 0.5 - lx) ** 2 + (y + 0.5 - ly) ** 2
                if dd >= radius * radius:
                    continue
                f = (1.0 - sqrt(dd) / radius) ** 2
                i = (h - 1 - y) * w + x
                k = 1.0 if floor[i] else (0.7 if faced[i] else 0.12)
                pic.r[i] = min(255, pic.r[i] + int(gr * f * k + 0.5))
                pic.g[i] = min(255, pic.g[i] + int(gg * f * k + 0.5))
                pic.b[i] = min(255, pic.b[i] + int(gb * f * k + 0.5))


def paint_stairs(pic, d):
    """Steps down the stair hall, its risers across it every `tread` units."""
    w, h = pic.w, pic.h
    spec = d.get("stairs")
    if not spec:
        return
    r = _room(d, spec["room"])
    tread = spec["tread"]
    for y in range(r["y0"], r["y1"]):
        for x in range(r["x0"] + spec.get("from", 0), r["x1"] - spec.get("to", 0)):
            i = (h - 1 - y) * w + x
            step = (x - r["x0"]) % tread
            if step < 2:
                k = 150                                   # the riser's shadowed lip
            elif step < 4:
                k = 286                                   # the tread's lit nose
            else:
                k = 256
            pic.r[i] = min(255, pic.r[i] * k >> 8)
            pic.g[i] = min(255, pic.g[i] * k >> 8)
            pic.b[i] = min(255, pic.b[i] * k >> 8)


def paint_portal(pic, d):
    """The instance portal the karts arrive through: a swirl of blue light
    on the floor, its arms from a pseudo-angle (no trigonometry)."""
    if not d.get("portal"):
        return
    w, h = pic.w, pic.h
    cx, cy, radius = d["portal"]
    for y in range(int(cy - radius) - 2, int(cy + radius) + 3):
        for x in range(int(cx - radius) - 2, int(cx + radius) + 3):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            r = sqrt(dx * dx + dy * dy)
            if r > radius + 2:
                continue
            i = (h - 1 - y) * w + x
            if r > radius:
                pic.r[i], pic.g[i], pic.b[i] = 60, 54, 62    # the portal's stone ring
                continue
            # Diamond angle in [0, 4): exact, monotonic in the true angle.
            if dy >= 0:
                a = dy / (abs(dx) + dy) if dx >= 0 else 1 - dx / (-dx + dy)
            else:
                a = 2 + (-dy / (-dx - dy) if dx < 0 else 1 + dx / (dx - dy))
            arm = (a * 0.75 + r / radius * 1.6) % 1.0           # three arms winding out
            glow = 1.0 - r / radius
            band = 0.55 + 0.45 * (1.0 - abs(arm * 2 - 1))
            k = band * (0.45 + 0.55 * glow)
            rr, gg, bb = 70 + 150 * k, 120 + 130 * k, 210 + 45 * k
            if r > radius - 3:
                rr, gg, bb = 120, 170, 230
            pic.r[i], pic.g[i], pic.b[i] = min(255, int(rr)), min(255, int(gg)), min(255, int(bb))


def paint_finish(pic, gate, floor, w, h, thickness=10, cells=5):
    """A chequered band across the floor along the last gate."""
    horizontal = gate["ay"] == gate["by"]
    lo = int(min(gate["ax"], gate["bx"])) if horizontal else int(min(gate["ay"], gate["by"]))
    hi = int(max(gate["ax"], gate["bx"])) if horizontal else int(max(gate["ay"], gate["by"]))
    mid = gate["ay"] if horizontal else gate["ax"]
    for a in range(lo, hi):
        for b in range(int(mid - thickness / 2), int(mid + thickness / 2)):
            x, y = (a, b) if horizontal else (b, a)
            i = (h - 1 - y) * w + x
            if not floor[i]:
                continue
            dark = ((a // cells) + ((b - int(mid - thickness / 2)) // cells)) % 2
            pic.r[i], pic.g[i], pic.b[i] = (34, 30, 30) if dark else (226, 222, 210)


def paint_walls(pic, d, tiles, floor):
    """A room's north wall rises over the masonry beyond: Warcraft III city
    wall stones, `height` x lean rows, shaded down to its foot, its coping lit
    along the top. The other walls show their coping edge, two texels wide."""
    w, h = pic.w, pic.h
    spec = d["wall"]
    rise = int(spec["height"] * d["lean"] + 0.5)
    face = Strata(tiles, spec["face"])
    cr, cg, cb = spec["coping"]
    faced = bytearray(w * h)
    for x in range(w):
        for row in range(1, h):
            i = row * w + x
            if not floor[i] or floor[i - w]:
                continue
            # (x, row) is floor and the texel north of it masonry: the room's
            # north wall, facing the camera.
            for k in range(1, rise + 1):
                j = (row - k) * w + x
                if row - k < 0 or floor[j]:
                    break
                fr, fg, fb = face.sample(x, rise - k, rise)
                s = 150 + 120 * k // rise                     # darker toward the foot
                if k >= rise - 2:
                    fr, fg, fb, s = cr, cg, cb, 256              # the coping
                pic.r[j] = min(255, fr * s >> 8)
                pic.g[j] = min(255, fg * s >> 8)
                pic.b[j] = min(255, fb * s >> 8)
                faced[j] = 1
    # The other walls' coping: masonry beside the floor to its north (a
    # room's south wall), east or west, two texels wide, never over a face.
    for row in range(h):
        base = row * w
        for x in range(w):
            i = base + x
            if floor[i] or faced[i]:
                continue
            north = row > 0 and floor[i - w]
            side = (x > 0 and floor[i - 1]) or (x + 1 < w and floor[i + 1])
            north2 = row > 1 and floor[i - 2 * w]
            side2 = (x > 1 and floor[i - 2]) or (x + 2 < w and floor[i + 2])
            if north or side or north2 or side2:
                k = 230 if (north or side) else 190
                pic.r[i], pic.g[i], pic.b[i] = cr * k >> 8, cg * k >> 8, cb * k >> 8
    return faced


def paint_grade(pic, d, sky, floor):
    """Moonlight over the open cloister: cooler, with drifts of mist; indoors
    the lamps' warmth."""
    from city_paint import _Noise
    w, h = pic.w, pic.h
    mist = _Noise(150, 421)
    fine = _Noise(46, 423)
    mr, mg, mb = d.get("mist", (150, 160, 176))
    mr2, mg2, mb2 = d.get("moonlight", (214, 228, 250))     # the open sky's tint, of 256
    for row in range(h):
        y = h - 1 - row
        base = row * w
        for x in range(w):
            i = base + x
            r, g, b = pic.r[i], pic.g[i], pic.b[i]
            if sky[i]:
                grey = (r * 77 + g * 151 + b * 28) >> 8
                r = (r * 3 + grey) >> 2
                g = (g * 3 + grey) >> 2
                b = (b * 3 + grey) >> 2
                r, g, b = r * mr2 >> 8, g * mg2 >> 8, min(255, (b * mb2 >> 8) + 10)
                m = mist.at(x, y) * 0.7 + fine.at(x, y) * 0.3
                a = max(0.0, m - 0.42) * 0.42                    # 0 .. ~0.24 where the mist lies
                r = int(r + (mr - r) * a + 0.5)
                g = int(g + (mg - g) * a + 0.5)
                b = int(b + (mb - b) * a + 0.5)
            elif floor[i]:
                r, g, b = min(255, r * 262 >> 8), g * 250 >> 8, b * 226 >> 8
            pic.r[i], pic.g[i], pic.b[i] = r, g, b


def build(wc3, d, geometry, check=False, preview=False, log=print):
    import time
    started = time.time()
    w, h = geometry["width"], geometry["height"]
    tiles = Tileset(wc3)
    pic = Picture(w, h)
    names, style, sky = _masks(d, w, h)
    floor = bytearray(1 if v else 0 for v in style)
    paint_masonry(pic, d, floor)
    paint_floors(pic, d, tiles, names, style, floor)
    paint_kerbs(pic, d, style, names, floor)
    paint_carpets(pic, d, floor)
    paint_rings(pic, d, floor)
    paint_stairs(pic, d)
    paint_portal(pic, d)
    paint_finish(pic, geometry["gates"][-1], floor, w, h)
    log(f"  floors {time.time() - started:.0f}s")
    faced = paint_walls(pic, d, tiles, floor)
    log(f"  walls {time.time() - started:.0f}s")
    cache = {}
    models = []
    for item in d["props"]:
        sprite = sprite_for(wc3, d, item, cache)
        forget_textures()                 # Reforged's textures are large: one model's at a time
        models.append((item, sprite, int(round(item["x"])), int(round(item["y"]))))
    lights = [(X + 0.5, Y + 0.5, item["light"][0], item["light"][1]) for item, sprite, X, Y in models
              if item.get("light")]
    if lights:
        paint_room_lights(pic, lights, floor, faced)
    for item, sprite, X, Y in sorted(models, key=lambda m: (-m[3], m[2])):
        paint_sprite(pic, sprite, X, Y)
    log(f"  models {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    paint_grade(pic, d, sky, floor)
    log(f"  painted {time.time() - started:.0f}s")
    image = pic.tga()
    preview_rows = pic.rows(4)
    outputs = [("Background.tga", image), ("Preview.tga", encode_tga(preview_rows))]
    folder = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / d["folder"]
    for name, data in outputs:
        output = folder / name
        relative = output.relative_to(ROOT).as_posix()
        if check:
            if not output.is_file() or output.read_bytes() != data:
                raise SystemExit(f"STALE: {relative}; run without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
        log(f"{'CHECK PASS' if check else 'WROTE'}: {relative}; opaque BGRA32; {len(data)} bytes; "
            f"sha256={hashlib.sha256(data).hexdigest()}")
    if preview:
        docs = ROOT / "docs" / "art" / "tracks"
        docs.mkdir(parents=True, exist_ok=True)
        (docs / f"{d['id']}-overview.png").write_bytes(encode_png(preview_rows))
        (docs / f"{d['id']}-sources.txt").write_text(sources(d, tiles, models), encoding="utf-8", newline="\n")
    return pic, models


def sources(d, tiles, models):
    """Every Warcraft III file the picture draws on: models with their use
    counts, then the textures they and the floors and walls read."""
    counts = {}
    for item, sprite, X, Y in models:
        counts[item["model"]] = counts.get(item["model"], 0) + 1
    textures = set()
    for item, sprite, X, Y in models:
        for path in sprite["textures"]:
            textures.add(path.replace("war3.w3mod/", "war3.w3mod:", 1).replace("_de.w3mod/", "_de.w3mod:", 1))
    for path, _ in tiles.cache:
        textures.add(path)
    for path, _, _ in tiles.strata:
        textures.add(path)
    lines = [f"# {d['name']}: Warcraft III Reforged files used by {d['folder']}/Background.tga",
             "# Generated by scripts/build_dungeon_tracks.py --preview. Archive paths as the client stores them.",
             "", "## Models (placements)"]
    lines += [f"{counts[m]:4d}  {m}" for m in sorted(counts)]
    lines += ["", "## Textures"] + sorted(textures)
    return "\n".join(lines) + "\n"
