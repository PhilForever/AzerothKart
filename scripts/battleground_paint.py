"""Paint one Battlegrounds Cup course for build_battlegrounds.py: its ground and its roofs.

A battleground course has two floors (LayeredTrack.lua). The picture is two
layers, both one texel per world unit, row 0 the north edge, as the karts'
camera sees them (height leans north by `lean`):

- Background.tga, opaque: the ground, everything floor 0 drives on and sees.
  Outdoors, Warcraft III terrain tiles (paint_terrain: Ashenvale on the
  Alliance's half, the Barrens on the Horde's); the cliffs round the field,
  their faces where the camera sees them; under each hill, the tunnels in the
  dark earth; under each roof, the base's halls and flag room between thick
  walls; the ramps; the Boots pads; the finish line; the scenery.
- Roofs.tga, with alpha: what stands over floor 0, laid at its world place:
  each hill (the plateau's top, its graveyard and fence, the slopes) and each
  base's roof (its walk, which floor 1 drives on, and its pitched roofs). The
  addon draws each roof over karts below it and under karts on it, and fades
  it while the player's kart is under it (UI.lua). Where a ramp or an open
  floor 0 room lies within a roof's box, the roof is clear.
- Preview.tga: both layers together, quartered, for the course menu.

Each side of the map (the Alliance's north of mid, the Horde's south) has its
style in d["sides"]. Integer compositing over IEEE-exact model rendering: the
bytes are the same on every machine.
"""
import hashlib
import struct
import time
from math import sqrt
from pathlib import Path

from city_paint import (Picture, Strata, Tileset, _Noise, bank_distance, hash32, paint_sprite, paint_terrain,
                        sprite_for)
from dungeon_paint import parquet
from paintkit import encode_png, encode_tga
from wc3render import forget_textures

ROOT = Path(__file__).resolve().parents[1]
CLIFF_HEIGHT = 80         # the gulch's cliffs: world units, rising `lean` rows each
PROP_SLACK = 3            # a model that is not solid may reach this far onto a floor


# ---------------------------------------------------------------------------
# An RGBA layer: the roofs.


class Layer:
    """Straight-alpha RGBA texels, row 0 north (a Picture with coverage)."""

    def __init__(self, width, height):
        self.w, self.h = width, height
        n = width * height
        self.r, self.g, self.b, self.a = bytearray(n), bytearray(n), bytearray(n), bytearray(n)

    def put(self, i, r, g, b, a=255):
        self.r[i], self.g[i], self.b[i], self.a[i] = r, g, b, a

    def over(self, i, r, g, b, a):
        if a <= 0:
            return
        da = self.a[i]
        if a >= 255 or da == 0:
            self.r[i], self.g[i], self.b[i], self.a[i] = r, g, b, a
            return
        k = da * (255 - a)                  # the layer's own share, times 255
        out = a * 255 + k                   # coverage, times 255
        self.r[i] = (r * a * 255 + self.r[i] * k + out // 2) // out
        self.g[i] = (g * a * 255 + self.g[i] * k + out // 2) // out
        self.b[i] = (b * a * 255 + self.b[i] * k + out // 2) // out
        self.a[i] = (out + 127) // 255

    def scale(self, i, k):
        self.r[i] = min(255, self.r[i] * k >> 8)
        self.g[i] = min(255, self.g[i] * k >> 8)
        self.b[i] = min(255, self.b[i] * k >> 8)

    def tga(self):
        """Type-2 BGRA32 with eight alpha bits, bottom-left origin."""
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, self.w, self.h, 32, 8)
        body = bytearray(self.w * self.h * 4)
        o = 0
        for row in range(self.h - 1, -1, -1):
            base = row * self.w
            body[o:o + 4 * self.w:4] = self.b[base:base + self.w]
            body[o + 1:o + 4 * self.w:4] = self.g[base:base + self.w]
            body[o + 2:o + 4 * self.w:4] = self.r[base:base + self.w]
            body[o + 3:o + 4 * self.w:4] = self.a[base:base + self.w]
            o += 4 * self.w
        return header + bytes(body)


# ---------------------------------------------------------------------------
# Where everything is: per texel (row 0 north).


class Masks:
    """`r0`/`r1`: 1 + the index of the floor 0 / floor 1 room painted there
    (a later room over an earlier); `rp`: 1 + the ramp's index; `cv`: 1 +
    the roof overlay's index whose picture covers the texel."""

    def __init__(self, d, g):
        w, h = g["width"], g["height"]
        self.w, self.h = w, h
        n = w * h
        self.rooms, self.ramps, self.overlays = g["rooms"], g["ramps"], g["overlays"]
        self.r0, self.r1, self.rp, self.cv = bytearray(n), bytearray(n), bytearray(n), bytearray(n)
        for k, r in enumerate(self.rooms):
            self._fill(self.r0 if r["level"] == 0 else self.r1, r, k + 1)
        for k, r in enumerate(self.ramps):
            self._fill(self.rp, r, k + 1)
        for k, o in enumerate(self.overlays):
            fx0, fy0, fx1, fy1 = o.get("footprint") or (o["x0"], o["y0"], o["x1"], o["y1"])
            for y in range(fy0, fy1):
                base = (h - 1 - y) * w
                for x in range(fx0, fx1):
                    i = base + x
                    if self.rp[i]:
                        continue
                    if self.r0[i] and not self.rooms[self.r0[i] - 1]["cover"]:
                        continue                 # an open floor 0 room within the box: the gully
                    self.cv[i] = k + 1
        # The kart floor of each layer: floor 0's rooms and ramps; floor 1's.
        self.ground = bytearray(1 if (self.r0[i] or self.rp[i]) else 0 for i in range(n))
        self.upper = bytearray(1 if (self.r1[i] or self.rp[i]) else 0 for i in range(n))

    def _fill(self, mask, r, value):
        w, h = self.w, self.h
        x0, x1 = int(r["x0"]), int(r["x1"])
        for y in range(int(r["y0"]), int(r["y1"])):
            base = (h - 1 - y) * w
            mask[base + x0:base + x1] = bytes([value]) * (x1 - x0)

    def side(self, y):
        return "alliance" if y >= self.h // 2 else "horde"


def _shade(rgb, k):
    return (min(255, rgb[0] * k >> 8), min(255, rgb[1] * k >> 8), min(255, rgb[2] * k >> 8))


# ---------------------------------------------------------------------------
# The ground.


def paint_ground_terrain(pic, d, tiles):
    """Warcraft III terrain over the whole world (the field, the cliff tops,
    the hills' and the bases' ground, under whatever stands on it)."""
    paint_terrain(pic, {"terrain": d["terrain"], "districts": d["districts"], "zones": d["zones"]}, tiles)


def paint_wild(pic, d, m, tiles):
    """Off the floor outdoors: the cliff tops round the gulch, darker away
    from the edge and under the woods; under a roof's box, the hill's dark
    earth or the base's walls (seen only while the roof fades)."""
    w, h = m.w, m.h
    near = bank_distance(bytearray(1 - v for v in m.ground), w, h, 40)     # distance from floor 0
    woods = _Noise(90, 611)
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        er, eg, eb = side["earth"]
        top = side["wall"]["top"]
        base = row * w
        for x in range(w):
            i = base + x
            if m.ground[i]:
                continue
            k = m.cv[i]
            if k:
                o = m.overlays[k - 1]
                if o["kind"] == "hill":
                    v = hash32(x // 6, y // 6, 613) % 13 - 6
                    s = 256 - min(near[i], 40) * 2
                    pic.r[i], pic.g[i], pic.b[i] = ((er + v) * s >> 8, (eg + v) * s >> 8, (eb + v) * s >> 8)
                else:
                    # The base's walls: courses of its stone (or logs).
                    course = y // 16
                    bx = (x + (course % 2) * 16) // 32
                    v = hash32(bx, course, 401) % 15 - 7
                    joint = y % 16 == 0 or (x + (course % 2) * 16) % 32 == 0
                    s = (236 if joint else 256) * (256 - min(near[i], 40) * 2) >> 8
                    pic.r[i] = max(0, min(255, (top[0] + v) * s >> 8))
                    pic.g[i] = max(0, min(255, (top[1] + v) * s >> 8))
                    pic.b[i] = max(0, min(255, (top[2] + v) * s >> 8))
                continue
            if m.rp[i]:
                continue
            e = near[i]
            if e <= 10:
                # The cliff's rim along the floor's edge: its side's rock, lit
                # on top, darkening to the drop.
                rr, rg, rb = _tile(tiles, side["rock"], x, y, 23)
                s = 168 + 9 * e if e > 2 else 120
                pic.r[i], pic.g[i], pic.b[i] = min(255, rr * s >> 8), min(255, rg * s >> 8), min(255, rb * s >> 8)
                continue
            # The cliff tops: the terrain, darker away from the edge, deeper
            # in shade under the woods.
            n = woods.at(x, y)
            s = 236 - min(e, 40) * 2 - int(max(0.0, n - 0.45) * 120)
            pic.r[i], pic.g[i], pic.b[i] = pic.r[i] * s >> 8, pic.g[i] * s >> 8, pic.b[i] * s >> 8


def _tile(tiles, spec, x, y, seed=3):
    r, g, b, _ = tiles.whole(spec["tile"], x, y, seed=seed, shade=spec.get("shade", 1.0))
    return r, g, b


def paint_rooms(pic, d, m, tiles):
    """Each floor 0 room in its side's style (the field keeps its terrain):
    the gully's and the tunnels' dirt, the bases' wooden floors and tiled
    doors; shade along the foot of every wall."""
    w, h = m.w, m.h
    edge = bank_distance(m.ground, w, h, 14)
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        base = row * w
        for x in range(w):
            i = base + x
            k = m.r0[i]
            if not k or m.rp[i]:
                continue
            style = m.rooms[k - 1]["floor"]
            if style == "field":
                r, g, b = pic.r[i], pic.g[i], pic.b[i]
            elif style == "gully":
                r, g, b = _tile(tiles, side["dirt"], x, y, 5)
            elif style == "tunnel":
                r, g, b = _tile(tiles, side["tunnel"], x, y, 7)
                if y % 64 < 6:
                    r, g, b = _shade(parquet(x, y, {"block": 64, "plank": 6, "colour": (110, 78, 48)}), 230)
            else:                                   # halls, doors and the flag room
                r, g, b = parquet(x, y, side["floor"]["parquet"])
            e = edge[i]
            s = 150 if e <= 1 else 196 + 60 * min(e, 14) // 14
            if style == "field":
                s = 256 if e > 3 else 210
            pic.r[i], pic.g[i], pic.b[i] = r * s >> 8, g * s >> 8, b * s >> 8


def paint_runners(pic, d, m):
    """The bases' runners: each side's carpet down the middle of its halls
    and across its flag room, edged."""
    w, h = m.w, m.h
    for r in m.rooms:
        if r["level"] != 0 or r["floor"] not in ("hall", "flag room"):
            continue
        side = d["sides"][r["name"].split()[0]]
        body, trim = side["runner"]
        horizontal = (r["x1"] - r["x0"]) >= (r["y1"] - r["y0"])
        mid = (r["y0"] + r["y1"]) // 2 if horizontal else (r["x0"] + r["x1"]) // 2
        half = 18
        lo, hi = (r["x0"] + 30, r["x1"] - 30) if horizontal else (r["y0"] + 30, r["y1"] - 30)
        for a in range(lo, hi):
            for b in range(mid - half, mid + half):
                x, y = (a, b) if horizontal else (b, a)
                i = (h - 1 - y) * w + x
                if m.rp[i] or not m.r0[i]:
                    continue
                t = abs(b - mid)
                rgb = trim if t >= half - 3 else body
                v = hash32(a // 3, b, 455) % 9 - 4
                pic.r[i] = max(0, min(255, rgb[0] + v))
                pic.g[i] = max(0, min(255, rgb[1] + v))
                pic.b[i] = max(0, min(255, rgb[2] + v))


def ramp_frame(r):
    """(along, across, low, high, side0, side1): the ramp's axis ('x' or 'y'),
    its low and high end coordinates along it, its side faces across it."""
    if r["axis"] == "x":
        low, high = (r["x0"], r["x1"]) if r["ascending"] == 1 else (r["x1"], r["x0"])
        return "x", low, high, r["y0"], r["y1"]
    low, high = (r["y0"], r["y1"]) if r["ascending"] == 1 else (r["y1"], r["y0"])
    return "y", low, high, r["x0"], r["x1"]


def paint_ramps(pic, d, m, tiles):
    """Each ramp: its side's dirt outdoors, planks across the slope at a
    base's door; treads every 12 units; lit toward its high end, and the
    more where it climbs toward the camera (north) than away from it; its
    rails the side walls' tops, a wall's width each, the north rail of an
    east-west ramp showing its face."""
    w, h = m.w, m.h
    inset = 18
    for r in m.ramps:
        side = d["sides"][r["name"].split()[0]]
        axis, low, high, s0, s1 = ramp_frame(r)
        wooden = "connector" in r["id"] or "front" in r["id"]
        facing = 1.0 if axis == "x" else (1.08 if high > low else 0.86)
        tr, tg, tb = side["wall"]["top"]
        cr, cg, cb = side["wall"]["coping"]
        for y in range(r["y0"], r["y1"]):
            row = h - 1 - y
            for x in range(r["x0"], r["x1"]):
                i = row * w + x
                q, c = (x, y) if axis == "x" else (y, x)
                t = (q - low) / (high - low)          # 0 at the low end, 1 at the high end
                across = min(c - s0, s1 - 1 - c)
                if across < inset - 6:
                    if axis == "x" and c >= s1 - (inset - 6):
                        # The north rail: its face, which the camera sees.
                        k = c - (s1 - (inset - 6))
                        rgb = _shade((tr + 30, tg + 28, tb + 26), 150 + 9 * k)
                    elif across < 3:
                        rgb = _shade((tr, tg, tb), 200)
                    else:
                        rgb = (cr, cg, cb) if across >= inset - 9 else _shade((tr + 20, tg + 18, tb + 16), 236)
                else:
                    if wooden:
                        rgb = planks(c, q, side["deck"], board=9, length=60) if axis == "y" else \
                            planks(y, x, side["deck"], board=9, length=60)
                    else:
                        rgb = _tile(tiles, side["dirt"], x, y, 11)
                    k = int((150 + 106 * t) * facing)
                    if int(abs(q - low)) % 12 < 2:
                        k -= 36                        # the treads across the slope
                    if across < inset:
                        k -= 24                        # the rails' shade
                    rgb = _shade(rgb, max(0, min(300, k)))
                pic.r[i], pic.g[i], pic.b[i] = (min(255, rgb[0]), min(255, rgb[1]), min(255, rgb[2]))


def paint_faces(pic, d, m, tiles):
    """Where the camera sees a wall, it rises over what lies beyond: a floor
    0 room's north edge (north of the floor, off it) rises `height` x lean
    rows, in its side's cliff strata outdoors and its fortress's stone
    inside a base's box; a tunnel's in its earth. Every other edge shows a
    coping, two texels wide."""
    w, h = m.w, m.h
    lean = d["lean"]
    faced = bytearray(w * h)
    strata = {}

    def face_of(side, kind):
        key = (side, kind)
        if key not in strata:
            spec = d["sides"][side]["cliff"] if kind == "cliff" else d["sides"][side]["wall"]["face"]
            strata[key] = Strata(tiles, spec)
        return strata[key]
    for x in range(w):
        for row in range(1, h):
            i = row * w + x
            if not m.ground[i] or m.ground[i - w]:
                continue
            y = h - 1 - row
            k = m.r0[i]
            room = m.rooms[k - 1] if k else None
            outdoor = room is not None and room["cover"] is None
            side = m.side(y)
            if outdoor:
                kind, height = "cliff", CLIFF_HEIGHT
            elif room is not None and room["floor"] == "tunnel":
                kind, height = "earth", 40
            else:
                kind, height = "wall", d["sides"][side]["wall"]["height"]
            up = int(height * lean + 0.5)
            cr, cg, cb = d["sides"][side]["wall"]["coping"]
            er, eg, eb = d["sides"][side]["earth"]
            face = None if kind == "earth" else face_of(side, kind)
            for kk in range(1, up + 1):
                j = (row - kk) * w + x
                if row - kk < 0 or m.ground[j]:
                    break
                if face is None:
                    v = hash32(x // 3, (row - kk) // 2, 617) % 17 - 8
                    fr, fg, fb = er + 30 + v, eg + 24 + v, eb + 18 + v
                    if (x // 24) % 4 == 0 and x % 24 < 5:
                        fr, fg, fb = 96 + v, 66 + v, 40 + v        # a timber post
                else:
                    fr, fg, fb = face.sample(x, up - kk, up)
                s = 150 + 120 * kk // up
                if kind == "wall" and kk >= up - 2:
                    fr, fg, fb, s = cr, cg, cb, 256
                pic.r[j] = max(0, min(255, fr * s >> 8))
                pic.g[j] = max(0, min(255, fg * s >> 8))
                pic.b[j] = max(0, min(255, fb * s >> 8))
                faced[j] = 1
    for row in range(h):
        y = h - 1 - row
        cr, cg, cb = d["sides"][m.side(y)]["wall"]["coping"]
        base = row * w
        for x in range(w):
            i = base + x
            if m.ground[i] or faced[i]:
                continue
            north = row > 0 and m.ground[i - w]
            side_ = (x > 0 and m.ground[i - 1]) or (x + 1 < w and m.ground[i + 1])
            north2 = row > 1 and m.ground[i - 2 * w]
            side2 = (x > 1 and m.ground[i - 2]) or (x + 2 < w and m.ground[i + 2])
            if north or side_ or north2 or side2:
                k = 230 if (north or side_) else 190
                if m.cv[i] and m.overlays[m.cv[i] - 1]["kind"] == "roof":
                    pic.r[i], pic.g[i], pic.b[i] = cr * k >> 8, cg * k >> 8, cb * k >> 8
                else:
                    pic.r[i], pic.g[i], pic.b[i] = (pic.r[i] + 40) * k >> 8, (pic.g[i] + 36) * k >> 8, \
                        (pic.b[i] + 30) * k >> 8
                    pic.r[i], pic.g[i], pic.b[i] = min(255, pic.r[i]), min(255, pic.g[i]), min(255, pic.b[i])
    return faced


# A boot, side on, toe east, in units of a pad's radius: the leg, the foot,
# a wing at the heel (the Boots of Speed).
BOOT = [(-0.30, 0.62), (0.10, 0.62), (0.10, 0.02), (0.52, -0.06), (0.58, -0.40), (-0.30, -0.40)]
WING = [(-0.30, 0.30), (-0.70, 0.52), (-0.58, 0.30), (-0.80, 0.30), (-0.62, 0.12), (-0.30, 0.10)]


def _in_polygon(points, x, y):
    hit = False
    for k in range(len(points)):
        ax, ay = points[k - 1]
        bx, by = points[k]
        if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
            hit = not hit
    return hit


def paint_pads(pic, d, g):
    """Each Boots pad: a glowing ring in its side's lamp colour and a winged
    boot in it."""
    w, h = g["width"], g["height"]
    for p in g["pads"]:
        lr, lg, lb = d["sides"][p["id"].split("_")[0]]["lamp"]
        cx, cy, radius = p["x"], p["y"], p["radius"] + 6
        for y in range(int(cy - radius - 8), int(cy + radius + 9)):
            for x in range(int(cx - radius - 8), int(cx + radius + 9)):
                i = (h - 1 - y) * w + x
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                dist = sqrt(dx * dx + dy * dy)
                a = 0
                if abs(dist - radius) < 2.2:
                    a = 255
                elif dist < radius:
                    a = 60
                elif dist < radius + 8:
                    a = int(120 * (1 - (dist - radius) / 8))
                bx, by = dx / (radius - 3), dy / (radius - 3)
                if _in_polygon(BOOT, bx, by) or _in_polygon(WING, bx, by):
                    a = 240
                if a:
                    pic.over(i, min(255, lr + 70), min(255, lg + 70), min(255, lb + 70), a)


def paint_flag_marks(pic, d, g, props):
    """A ring on the floor round each flag, in its side's colour: the flag the
    lap rounds."""
    w, h = g["width"], g["height"]
    for item in props:
        if not item["name"].endswith("_flag"):
            continue
        body, trim = d["sides"][item["name"].split("_")[0]]["runner"]
        cx, cy = item["x"], item["y"] + 4
        for y in range(int(cy - 48), int(cy + 49)):
            for x in range(int(cx - 48), int(cx + 49)):
                if not (0 <= x < w and 0 <= y < h):
                    continue
                dist = sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2)
                i = (h - 1 - y) * w + x
                if abs(dist - 42) < 3:
                    pic.over(i, trim[0], trim[1], trim[2], 210)
                elif dist < 39:
                    pic.over(i, body[0], body[1], body[2], 90)


def paint_finish(pic, g, m, thickness=10, cells=5):
    """A chequered band across the floor along the last gate (mid)."""
    from dungeon_paint import paint_finish as chequer
    chequer(pic, g["gates"][-1], m.ground, m.w, m.h, thickness, cells)


def paint_grade(pic, d, m):
    """Light: the tunnels and the halls in shade, lamplit; the field in
    daylight."""
    w, h = m.w, m.h
    for row in range(h):
        y = h - 1 - row
        base = row * w
        for x in range(w):
            i = base + x
            k = m.r0[i]
            if k and m.rooms[k - 1]["cover"]:
                s = 200 if m.rooms[k - 1]["floor"] == "tunnel" else 226
                pic.r[i] = pic.r[i] * (s + 12) >> 8
                pic.g[i] = pic.g[i] * s >> 8
                pic.b[i] = pic.b[i] * (s - 10) >> 8


# ---------------------------------------------------------------------------
# Relief: what stands how high, and the shadows it casts.

SUN = (0.57, -0.76)       # ground offset per unit of height, away from the light (the models' shadows)
HILL_HEIGHT = 80
ROOF_HEIGHT = 104


def heights(d, m):
    """World units above floor 0 per texel: the open floor 0; the ramps
    climbing to a hill; the hills and the cliff tops; the bases' roofs."""
    w, h = m.w, m.h
    out = bytearray(w * h)
    for i in range(w * h):
        if m.cv[i]:
            out[i] = HILL_HEIGHT if m.overlays[m.cv[i] - 1]["kind"] == "hill" else ROOF_HEIGHT
        elif m.rp[i]:
            out[i] = HILL_HEIGHT // 3
        elif not m.ground[i]:
            out[i] = HILL_HEIGHT
    for r in m.ramps:
        axis, low, high, s0, s1 = ramp_frame(r)
        for y in range(r["y0"], r["y1"]):
            base = (h - 1 - y) * w
            for x in range(r["x0"], r["x1"]):
                q = x if axis == "x" else y
                t = (q - low) / (high - low)
                out[base + x] = int(HILL_HEIGHT * max(0.0, min(1.0, t)) * 0.9)
    return out


def shadows(m, high, reach=110, step=2):
    """Per texel, 0-255: how deep in a cast shadow it lies (the sun's ray
    from it passes under something taller). Only texels within `reach` of a
    taller neighbour are marched."""
    w, h = m.w, m.h
    out = bytearray(w * h)
    sx, sy = SUN
    for row in range(h):
        y = h - 1 - row
        base = row * w
        for x in range(w):
            i = base + x
            h0 = high[i]
            if h0 >= ROOF_HEIGHT:
                continue
            # Toward the sun: back along the shadow vector.
            for t in range(step, reach, step):
                px, py = int(x - sx * t), int(y - sy * t)
                if px < 0 or px >= w or py < 0 or py >= h:
                    break
                hh = high[(h - 1 - py) * w + px]
                if hh > h0 + t:
                    out[i] = 255
                    break
                if t > ROOF_HEIGHT:
                    break
    return out


def apply_shadow(pic, shade, mask=None, depth=92):
    """Darken shadowed texels (of `mask`, when given) by `depth`/256,
    softened at the shadow's edge by a 3 x 3 average."""
    w, h = pic.w, pic.h
    for row in range(1, h - 1):
        base = row * w
        for x in range(1, w - 1):
            i = base + x
            if mask is not None and not mask[i]:
                continue
            s = (shade[i] * 4 + shade[i - 1] + shade[i + 1] + shade[i - w] + shade[i + w]) // 8
            if s:
                k = 256 - depth * s // 255
                pic.r[i], pic.g[i], pic.b[i] = pic.r[i] * k >> 8, pic.g[i] * k >> 8, pic.b[i] * k >> 8


# ---------------------------------------------------------------------------
# The roofs.


def hip(x, y, box):
    """A hip roof over `box`: (facet, distance in from its eave, ridge):
    facet 0 north, 1 south, 2 west, 3 east; ridge where two facets meet."""
    x0, y0, x1, y1 = box
    ds = (y1 - 1 - y, y - y0, x - x0, x1 - 1 - x)
    near = min(ds)
    facet = ds.index(near)
    second = sorted(ds)[1]
    return facet, near, second - near <= 1


FACET_LIGHT = (250, 196, 238, 166)      # north, south, west, east: lit from the north-west


def planks(x, y, colour, board=10, length=72):
    """Boards laid east-west, `board` rows wide, their butt joints staggered."""
    lane = y // board
    piece = (x + hash32(lane, 0, 641) % length) // length
    v = hash32(lane, piece, 643) % 25 - 12
    grain = hash32(x // 6, y, 645) % 7 - 3
    k = 168 if (y % board == 0 or (x + hash32(lane, 0, 641) % length) % length == 0) else 256
    return tuple(max(0, min(255, (c + v + grain) * k >> 8)) for c in colour)


def walk(tiles, spec, x, y):
    """A roof's walk: its side's flagstones, or planks."""
    if "planks" in spec:
        return planks(x, y, spec["planks"])
    return _tile(tiles, spec, x, y, 19)


def paint_roofs(layer, d, m, tiles, ground):
    """Each overlay within its box (m.cv). A hill: the plateau's grass over
    the ground's own terrain (so the edges meet), its slopes in rock, a
    rocky rim where it drops to lower ground. A base: its walk (floor 1) in
    its deck's planks with a crenellated parapet where the walk ends, its
    pitched roofs (d["hips"]) shingled facet by facet, the rest of its box
    its walls' tops in courses."""
    w, h = m.w, m.h
    into = bank_distance(m.upper, w, h, 14)                              # in from floor 1's edge
    away = bank_distance(bytearray(1 - v for v in m.upper), w, h, 14)    # out from floor 1's edge
    rim = bank_distance(covered_mask(m), w, h, 10)                       # in from the box's edge
    hips = [tuple(b) for b in d.get("hips", ())]
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        base = row * w
        for x in range(w):
            i = base + x
            k = m.cv[i]
            if not k:
                continue
            o = m.overlays[k - 1]
            on = m.r1[i]
            e = into[i] if on else away[i]
            edge = rim[i]
            if o["kind"] == "hill":
                r, g, b = ground[0][i], ground[1][i], ground[2][i]     # the terrain under the hill's ground
                if not on:
                    rr, rg, rb = _tile(tiles, side["rock"], x, y, 13)
                    t = min(e, 12)
                    r, g, b = (r * (12 - t) + rr * t) // 12, (g * (12 - t) + rg * t) // 12, (b * (12 - t) + rb * t) // 12
                    s = 214
                else:
                    s = 250 if e > 3 else 214
                if edge <= 6:
                    rr, rg, rb = _tile(tiles, side["rock"], x, y, 17)
                    r, g, b, s = rr, rg, rb, 150 + edge * 14       # the cliff's rim, darker at the drop
                layer.put(i, r * s >> 8, g * s >> 8, b * s >> 8, 255)
                continue
            if on:
                rgb = walk(tiles, side["walk"], x, y)
                if e <= 3:
                    rgb = _shade(rgb, 196)
                layer.put(i, rgb[0], rgb[1], rgb[2], 255)
                continue
            # Off the walk: a parapet beside it, a pitched roof, or wall tops.
            wr, wg, wb = side["wall"]["top"]
            cr, cg, cb = side["wall"]["coping"]
            if e <= 10:
                # The parapet: coping with crenels every 12 texels.
                merlon = ((x + y) // 12) % 2 == 0
                s = 250 if merlon else 176
                if e <= 2:
                    s = 210
                layer.put(i, min(255, cr * s >> 8), min(255, cg * s >> 8), min(255, cb * s >> 8), 255)
                continue
            box = next((b for b in hips if b[0] <= x < b[2] and b[1] <= y < b[3]), None)
            if box is not None:
                facet, depth, ridge = hip(x, y, box)
                rr, rg, rb = side["roof"]
                if facet < 2:
                    course, along = depth // 9, x
                else:
                    course, along = depth // 9, y
                sx = (along + (course % 2) * 7) // 14
                v = hash32(sx, course * 4 + facet, 631) % 21 - 10
                s = FACET_LIGHT[facet] - (4 if depth % 9 < 2 else 0) * 6
                if ridge and depth > 2:
                    rr, rg, rb = side["ridge"]
                    s, v = 236, 0
                if depth <= 2:
                    rr, rg, rb, s = wr, wg, wb, 200          # the eaves
                layer.put(i, max(0, min(255, (rr + v) * s >> 8)), max(0, min(255, (rg + v) * s >> 8)),
                          max(0, min(255, (rb + v) * s >> 8)), 255)
                continue
            course = y // 14
            bx = (x + (course % 2) * 14) // 28
            v = hash32(bx, course, 401) % 15 - 7
            joint = y % 14 == 0 or (x + (course % 2) * 14) % 28 == 0
            s = 220 if joint else 246
            if edge <= 4:
                s = 200
            layer.put(i, max(0, min(255, (wr + 26 + v) * s >> 8)), max(0, min(255, (wg + 24 + v) * s >> 8)),
                      max(0, min(255, (wb + 24 + v) * s >> 8)), 255)


def roof_faces(layer, d, m, tiles):
    """A base's front: where the roof's box meets lower ground to its south
    (the plateau, the hill), the camera sees its wall rise: the fortress's
    face over the roof's southernmost rows."""
    w, h = m.w, m.h
    lean = d["lean"]
    for o in m.overlays:
        if o["kind"] != "roof":
            continue
        side = d["sides"][o["side"]]
        if not side.get("front_face", True) or o["y0"] < h // 2:
            continue                                   # the Horde's front faces away
        face = Strata(tiles, side["wall"]["face"])
        up = int(side["wall"]["height"] * lean + 0.5)
        cr, cg, cb = side["wall"]["coping"]
        row0 = h - 1 - o["y0"]
        for x in range(o["x0"], o["x1"]):
            for kk in range(up):
                j = (row0 - kk) * w + x
                if not m.cv[j] or m.r1[j]:
                    continue
                fr, fg, fb = face.sample(x, up - kk, up)
                s = 150 + 120 * kk // up
                if kk >= up - 3:
                    fr, fg, fb, s = cr, cg, cb, 256
                layer.put(j, max(0, min(255, fr * s >> 8)), max(0, min(255, fg * s >> 8)),
                          max(0, min(255, fb * s >> 8)), 255)


# ---------------------------------------------------------------------------
# Models.


def check_props(g, m, placed):
    """Nothing the karts drive over unseen: a model that is not solid keeps
    its drawn body off the kart floor of the layer it is drawn in (floor 0's
    for the ground, floor 1's for the roofs), by the slack."""
    from build_battlegrounds import floor_definition
    from build_dungeon_tracks import Floor
    w, h = g["width"], g["height"]
    free = {level: Floor(dict(floor_definition(g, level), wallInset=g["wallInset"] + PROP_SLACK))
            for level in (0, 1)}
    boxes = [(o["x0"], o["y0"], o["x1"], o["y1"]) for o in g["overlays"]]
    for item, sprite, X, Y, level in placed:
        col0, row0 = X - sprite["ox"], h - Y - sprite["oy"]
        if level == 1:
            # The roofs are drawn box by box: what stands on one keeps in it.
            for i, j in sprite["body_points"]:
                x, y = col0 + i + 0.5, h - 1 - (row0 + j) + 0.5
                if not any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in boxes):
                    raise SystemExit(f"LAYOUT: {item['name']} at ({X}, {Y}) reaches out of its roof's box "
                                     f"(its body at {x:.0f}, {y:.0f}): move it or widen the box")
        if item["solid"]:
            continue
        for i, j in sprite["body_points"]:
            x, y = col0 + i + 0.5, h - 1 - (row0 + j) + 0.5
            if free[level].allowed(x, y):
                raise SystemExit(f"LAYOUT: {item['name']} at ({X}, {Y}) stands where floor {level} drives "
                                 f"(its body at {x:.0f}, {y:.0f}): make it solid or move it")


def place(wc3, d, items, cache, level):
    placed = []
    for item in items:
        sprite = sprite_for(wc3, d, item, cache)
        forget_textures()
        placed.append((item, sprite, int(round(item["x"])), int(round(item["y"])), level))
    return placed


# ---------------------------------------------------------------------------
# The build.


def build(wc3, d, g, check=False, preview=False, log=print, cache=None):
    started = time.time()
    w, h = g["width"], g["height"]
    tiles = Tileset(wc3)
    m = Masks(d, g)
    for o in m.overlays:
        o.setdefault("kind", "hill" if "hill" in o["id"] else "roof")
        o.setdefault("side", o["id"].split("_")[0])
    pic = Picture(w, h)
    paint_ground_terrain(pic, d, tiles)
    terrain = (bytes(pic.r), bytes(pic.g), bytes(pic.b))
    log(f"  terrain {time.time() - started:.0f}s")
    paint_wild(pic, d, m, tiles)
    paint_rooms(pic, d, m, tiles)
    paint_runners(pic, d, m)
    paint_ramps(pic, d, m, tiles)
    paint_faces(pic, d, m, tiles)
    paint_pads(pic, d, g)
    paint_flag_marks(pic, d, g, d["props"])
    paint_finish(pic, g, m)
    high = heights(d, m)
    shade = shadows(m, high)
    open_ground = bytearray(0 if m.cv[i] else 1 for i in range(w * h))
    apply_shadow(pic, shade, open_ground)
    log(f"  ground {time.time() - started:.0f}s")
    cache = {} if cache is None else cache
    ground_models = place(wc3, d, d["props"], cache, 0)
    roof_models = place(wc3, d, d["roof_props"], cache, 1)
    check_props(g, m, ground_models + roof_models)
    for item, sprite, X, Y, _ in sorted(ground_models, key=lambda p: (-p[3], p[2])):
        paint_sprite(pic, sprite, X, Y)
    paint_grade(pic, d, m)
    layer = Layer(w, h)
    paint_roofs(layer, d, m, tiles, terrain)
    roof_faces(layer, d, m, tiles)
    apply_shadow(layer, shade, covered_mask(m))
    for item, sprite, X, Y, _ in sorted(roof_models, key=lambda p: (-p[3], p[2])):
        paint_sprite(layer, sprite, X, Y)
    log(f"  roofs {time.time() - started:.0f}s ({len(ground_models) + len(roof_models)} models)")
    whole = composite(pic, layer, g["overlays"])
    preview_rows = whole.rows(4)
    folder = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / d["folder"]
    outputs = [(folder / "Background.tga", pic.tga()), (folder / "Roofs.tga", layer.tga()),
               (folder / "Preview.tga", encode_tga(preview_rows)),
               (ROOT / "addon" / "AzerothKart" / "Assets" / "UI" / "GuideArrow.tga", encode_tga(arrow_sheet()))]
    for output, data in outputs:
        relative = output.relative_to(ROOT).as_posix()
        if check:
            if not output.is_file() or output.read_bytes() != data:
                raise SystemExit(f"STALE: {relative}; run without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
        log(f"{'CHECK PASS' if check else 'WROTE'}: {relative}; BGRA32; {len(data)} bytes; "
            f"sha256={hashlib.sha256(data).hexdigest()}")
    if preview:
        docs = ROOT / "docs" / "art" / "tracks"
        docs.mkdir(parents=True, exist_ok=True)
        (docs / f"{d['id']}-overview.png").write_bytes(encode_png(preview_rows))
        (docs / f"{d['id']}-sources.txt").write_text(sources(d, tiles, ground_models + roof_models),
                                                     encoding="utf-8", newline="\n")
    return pic, layer, whole


# The guiding arrow's sheet (Presentation.GUIDE_ARROW): 16 headings in a
# 4 x 4 grid of 32 x 32 cells, frame k pointing k/16 of a turn
# counter-clockwise from east; gold with a dark rim, 4 x 4 supersampled.
ARROW = [(12.6, 0.0), (-2.4, 9.4), (-2.4, 3.8), (-11.2, 3.8), (-11.2, -3.8), (-2.4, -3.8), (-2.4, -9.4)]


def arrow_sheet():
    from math import cos, pi, sin
    cell, ss = 32, 4
    rows = [[[0, 0, 0, 0] for _ in range(4 * cell)] for _ in range(4 * cell)]
    for k in range(16):
        a = 2 * pi * k / 16
        ca, sa = cos(a), sin(a)
        shape = [(x * ca - y * sa, x * sa + y * ca) for x, y in ARROW]
        rim = [(x * 1.18, y * 1.18) for x, y in ARROW]
        rim = [(x * ca - y * sa, x * sa + y * ca) for x, y in rim]
        col, row = k % 4, k // 4
        for j in range(cell):
            for i in range(cell):
                inner = outer = 0
                for sj in range(ss):
                    for si in range(ss):
                        x = i + (si + 0.5) / ss - cell / 2
                        y = cell / 2 - (j + (sj + 0.5) / ss)          # rows run down; y up
                        if _in_polygon(shape, x, y):
                            inner += 1
                        elif _in_polygon(rim, x, y):
                            outer += 1
                n = ss * ss
                cover = inner + outer
                if cover:
                    r = (255 * inner + 40 * outer) // cover
                    g = (214 * inner + 26 * outer) // cover
                    b = (64 * inner + 10 * outer) // cover
                    rows[row * cell + j][col * cell + i] = [r, g, b, 255 * cover // n]
    return rows


def covered_mask(m):
    return bytearray(1 if m.cv[i] else 0 for i in range(m.w * m.h))


def composite(pic, layer, overlays):
    """The ground with the roofs over it, box by box, as the addon draws them."""
    out = Picture(pic.w, pic.h)
    out.r[:], out.g[:], out.b[:] = pic.r, pic.g, pic.b
    w, h = pic.w, pic.h
    inside = bytearray(w * h)
    for o in overlays:
        for y in range(o["y0"], o["y1"]):
            base = (h - 1 - y) * w
            inside[base + o["x0"]:base + o["x1"]] = b"\x01" * (o["x1"] - o["x0"])
    for i in range(w * h):
        a = layer.a[i]
        if a and inside[i]:
            out.over(i, layer.r[i], layer.g[i], layer.b[i], a)
    return out


def sources(d, tiles, models):
    counts = {}
    textures = set()
    for item, sprite, X, Y, _ in models:
        counts[item["model"]] = counts.get(item["model"], 0) + 1
        for path in sprite["textures"]:
            textures.add(path.replace("war3.w3mod/", "war3.w3mod:", 1).replace("_de.w3mod/", "_de.w3mod:", 1))
    for path, _ in tiles.cache:
        textures.add(path)
    for path, _, _ in tiles.strata:
        textures.add(path)
    lines = [f"# {d['name']}: Warcraft III Reforged files used by {d['folder']}/Background.tga and Roofs.tga",
             "# Generated by scripts/build_battlegrounds.py --preview. Archive paths as the client stores them.",
             "", "## Models (placements)"]
    lines += [f"{counts[k]:4d}  {k}" for k in sorted(counts)]
    lines += ["", "## Textures"] + sorted(textures)
    return "\n".join(lines) + "\n"
