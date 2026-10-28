"""Paint one Battlegrounds Cup course for build_battlegrounds.py: its ground and the covers over its tunnels.

A battleground course has two floors (LayeredTrack.lua). The painter makes
two pictures of the whole world, one texel per world unit, row 0 the north
edge, as the karts' camera sees them (height leans north by `lean`):

- UPPER, the battleground from above: its own ground (d["survey"], the
  client's map measured by wow_map_survey.py: each ground texture's weight
  per texel, drawn as the Warcraft III tile that stands for it, and the
  terrain's relief, shading it); on that ground every floor the camera sees
  (floor 1, and floor 0 where no cover hides it): the field and the plateau
  in their terrain, the bases' floors between their walls; cliffs and walls
  where the floors end, their faces where the camera sees them; the Boots
  pads, the flags' daises, the gates' thresholds and the finish line; the
  scenery, north to south.
- LOWER, under each cover only: the tunnel there, its floor and walls in the
  hill's dark earth.

The outputs:

- Background.tga, opaque: UPPER, except within each cover's footprint, where
  it is LOWER.
- Roofs.tga, with alpha: UPPER within each cover's footprint (the ground over
  the tunnel), clear elsewhere and where a tunnel's portal opens in a cliff
  face. The addon draws each cover over the karts below it and under those on
  floor 1, and fades it while the player's kart is in the tunnel beneath
  (UI.lua): cover and ground are one picture, so they always meet.
- Preview.tga: UPPER, quartered, for the course menu.

Integer compositing; no transcendental function feeds a pixel: the bytes are
the same on every machine.
"""
import base64
import hashlib
import json
import struct
import time
import zlib
from math import sqrt
from pathlib import Path

from city_paint import Picture, Strata, Tileset, _Noise, bank_distance, hash32, paint_sprite, sprite_for
from dungeon_paint import parquet
from paintkit import encode_png, encode_tga
from wc3render import forget_textures

ROOT = Path(__file__).resolve().parents[1]
CELL = 32                 # a terrain tile's cell, world units
CLIFF_HEIGHT = 80         # a cliff's face: world units, rising `lean` rows each
PROP_SLACK = 3            # a model that is not solid may reach this far onto a floor
WALL = 30                 # a base's walls: at most this thick beside its floors
CLIFF = 16                # a cliff's band of rock beside an outdoor floor
FAR = 48                  # off the floors, the ground darkens out to this far


# ---------------------------------------------------------------------------
# An RGBA layer: the covers.


class Layer:
    """Straight-alpha RGBA texels, row 0 north (a Picture with coverage)."""

    def __init__(self, width, height):
        self.w, self.h = width, height
        n = width * height
        self.r, self.g, self.b, self.a = bytearray(n), bytearray(n), bytearray(n), bytearray(n)

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


def _shade(rgb, k):
    return (max(0, min(255, rgb[0] * k >> 8)), max(0, min(255, rgb[1] * k >> 8)), max(0, min(255, rgb[2] * k >> 8)))


def _put(pic, i, rgb):
    pic.r[i], pic.g[i], pic.b[i] = rgb


# ---------------------------------------------------------------------------
# The battleground's own ground.


class Survey:
    """scripts/wow_map_survey.py's measurements of the battleground: per
    `grid`-unit texel (row 0 north) each ground texture's weight (0-15), the
    terrain's height (yards; None where it has a hole) and, where the map
    has any, the depth of the water over it (yards; 0 where dry)."""

    def __init__(self, path):
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        self.grid, self.cols, self.rows = data["grid"], data["columns"], data["rows"]
        self.planes = {name: zlib.decompress(base64.b64decode(text)) for name, text in data["ground"].items()}
        relief = data["relief"]
        raw = zlib.decompress(base64.b64decode(relief["texels"]))
        self.heights = [None if v == 255 else relief["base"] + v * relief["step"] for v in raw]
        self.placements = data["placements"]
        self.water = None
        if "water" in data:
            step = data["water"]["step"]
            self.water = [v * step for v in zlib.decompress(base64.b64decode(data["water"]["texels"]))]


def survey_heights(sv, smooth=0):
    """The survey's terrain heights (yards, per texel, row 0 north), its holes
    filled from their edges inward, evened by `smooth` passes of a 3 x 3
    mean."""
    cols, rows = sv.cols, sv.rows
    h = list(sv.heights)
    for _ in range(64):                                  # fill the holes from their edges inward
        missing = [i for i, v in enumerate(h) if v is None]
        if not missing:
            break
        fill = {}
        for i in missing:
            r, c = divmod(i, cols)
            near = [h[j] for j in (i - 1 if c else -1, i + 1 if c + 1 < cols else -1,
                                   i - cols if r else -1, i + cols if r + 1 < rows else -1) if j >= 0 and h[j] is not None]
            if near:
                fill[i] = sum(near) / len(near)
        for i, v in fill.items():
            h[i] = v
    h = [290.0 if v is None else v for v in h]
    for _ in range(smooth):
        even = [0.0] * (cols * rows)
        for r in range(rows):
            r0, r1 = max(0, r - 1), min(rows - 1, r + 1)
            for c in range(cols):
                c0, c1 = max(0, c - 1), min(cols - 1, c + 1)
                acc = 0.0
                for rr in (r0, r, r1):
                    base = rr * cols
                    acc += h[base + c0] + h[base + c] + h[base + c1]
                even[r * cols + c] = acc / 9.0
        h = even
    return h


def occlusion(sv, h, spec):
    """Per survey texel, how open its sky is (1: open; less in a pit or
    under a cliff), from the evened heights `h`: on a coarse grid
    (spec["step"] texels), in eight directions out to spec["reach"] units,
    the steepest rise's share of the sky (its height over its distance, as
    t / sqrt(1 + t * t): no transcendental), then bilinear between the grid's
    points. The light is scaled by 1 - spec["strength"] * (1 - openness)."""
    cols, rows, gs = sv.cols, sv.rows, sv.grid
    step = spec["step"]
    steps = max(1, int(spec["reach"] / (step * gs)))
    ccols, crows = (cols + step - 1) // step, (rows + step - 1) // step
    diagonal = 1.4142135623730951
    dirs = [(1, 0, 1.0), (1, 1, diagonal), (0, 1, 1.0), (-1, 1, diagonal), (-1, 0, 1.0), (-1, -1, diagonal),
            (0, -1, 1.0), (1, -1, diagonal)]
    coarse = [1.0] * (ccols * crows)
    for cr in range(crows):
        r0 = min(rows - 1, cr * step + step // 2)
        for cc in range(ccols):
            c0 = min(cols - 1, cc * step + step // 2)
            here = h[r0 * cols + c0]
            shut = 0.0
            for dc, dr, unit in dirs:
                best = 0.0
                for k in range(1, steps + 1):
                    c, r = c0 + dc * step * k, r0 - dr * step * k
                    if not (0 <= c < cols and 0 <= r < rows):
                        break
                    t = (h[r * cols + c] - here) / (k * step * gs * unit / 3.0)
                    if t > best:
                        best = t
                shut += best / sqrt(1.0 + best * best)
            coarse[cr * ccols + cc] = 1.0 - shut / 8.0
    strength = spec["strength"]
    out = [1.0] * (cols * rows)
    for r in range(rows):
        v = (r - step // 2) / step
        cr0 = max(0, min(crows - 1, int(v // 1)))
        cr1 = min(crows - 1, cr0 + 1)
        fv = min(1.0, max(0.0, v - cr0))
        for c in range(cols):
            u = (c - step // 2) / step
            cc0 = max(0, min(ccols - 1, int(u // 1)))
            cc1 = min(ccols - 1, cc0 + 1)
            fu = min(1.0, max(0.0, u - cc0))
            a, b = coarse[cr0 * ccols + cc0], coarse[cr0 * ccols + cc1]
            e, f = coarse[cr1 * ccols + cc0], coarse[cr1 * ccols + cc1]
            top = a + (b - a) * fu
            open_ = top + (e + (f - e) * fu - top) * fv
            out[r * cols + c] = 1.0 - strength * (1.0 - open_)
    return out


def relief_light(sv, spec):
    """Per survey texel, the sun on the terrain, x256 (256 on level ground):
    its slope (exaggerated by spec["exaggerate"]) toward spec["light"] (a
    direction east, north, up), never below spec["ambient"] of level
    ground's. Holes take their neighbours' heights. Optionally the heights
    are first evened (spec["smooth"] passes of a 3 x 3 mean: a coarse
    relief's steps), the light raised on high ground and lowered in the
    hollows (spec["height_tint"]: the fraction at the survey's highest and
    lowest ground) and dimmed where the sky is shut in (spec["occlusion"]:
    a pit, the foot of a cliff)."""
    cols, rows = sv.cols, sv.rows
    h = survey_heights(sv, spec.get("smooth", 0))
    shut = occlusion(sv, h, spec["occlusion"]) if spec.get("occlusion") else None
    lx, ly, lz = spec["light"]
    n = sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / n, ly / n, lz / n
    run = 2 * sv.grid / 3.0                               # yards between a texel's two neighbours
    k = spec["exaggerate"] / run
    ambient = spec["ambient"]
    tint = spec.get("height_tint", 0.0)
    low, high = min(h), max(h)
    span = (high - low) or 1.0
    out = [256] * (cols * rows)
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            gx = (h[i + 1 if c + 1 < cols else i] - h[i - 1 if c else i]) * k
            gy = (h[i - cols if r else i] - h[i + cols if r + 1 < rows else i]) * k     # north is up the rows
            norm = sqrt(gx * gx + gy * gy + 1.0)
            lit = (-gx * lx - gy * ly + lz) / norm / lz
            value = max(ambient, ambient + (1 - ambient) * lit)
            if tint:
                value *= 1.0 + tint * (2.0 * (h[i] - low) / span - 1.0)
            if shut is not None:
                value *= shut[i]
            out[i] = int(256 * value)
    return out


def _bilinear(grid, cols, rows, gs, x, row):
    """A survey grid's value at picture texel (x, row), interpolated."""
    u = (x + 0.5) / gs - 0.5
    v = (row + 0.5) / gs - 0.5
    c0, r0 = int(u // 1), int(v // 1)
    fu, fv = u - c0, v - r0
    c0, c1 = max(0, min(cols - 1, c0)), max(0, min(cols - 1, c0 + 1))
    r0, r1 = max(0, min(rows - 1, r0)), max(0, min(rows - 1, r0 + 1))
    a, b = grid[r0 * cols + c0], grid[r0 * cols + c1]
    c, d = grid[r1 * cols + c0], grid[r1 * cols + c1]
    top = a + (b - a) * fu
    return top + (c + (d - c) * fu - top) * fv


def paint_ground(pic, d, sv, tiles, light):
    """The battleground's ground everywhere: each texel takes the Warcraft III
    tile standing for one of the client's ground textures, picked by their
    measured weights (bilinear between survey texels) against smooth noise,
    so each texture keeps its share of the ground with a ragged edge; within
    a hair of the edge the two tiles mix. A texture's `boost` scales its
    weight (the paths, drawn bolder than measured). The relief's light over
    it all."""
    w, h, gs, cols, rows = pic.w, pic.h, sv.grid, sv.cols, sv.rows
    order = list(d["ground"])
    classes = []
    for k, name in enumerate(order):
        spec = d["ground"][name]
        cells = tiles.cells(spec["tile"], spec.get("shade", 1.0))
        pool = cells[16:] if len(cells) > 16 else cells[15:16]
        classes.append((sv.planes[name], pool, 101 + 17 * k, spec.get("boost", 1.0)))
    coarse, fine = _Noise(18, 721), _Noise(6, 727)
    edge = 0.05
    for row in range(h):
        y = h - 1 - row
        v = (row + 0.5) / gs - 0.5
        r0 = int(v // 1)
        fv = v - r0
        r0c, r1c = max(0, min(rows - 1, r0)), max(0, min(rows - 1, r0 + 1))
        base = row * w
        cy = y // CELL
        ty = (CELL - 1 - (y % CELL)) * CELL
        for x in range(w):
            u = (x + 0.5) / gs - 0.5
            c0 = int(u // 1)
            fu = u - c0
            c0c, c1c = max(0, min(cols - 1, c0)), max(0, min(cols - 1, c0 + 1))
            i00, i01, i10, i11 = r0c * cols + c0c, r0c * cols + c1c, r1c * cols + c0c, r1c * cols + c1c
            weights, total = [], 0.0
            for plane, pool, seed, boost in classes:
                a, b, c, e = plane[i00], plane[i01], plane[i10], plane[i11]
                if a or b or c or e:
                    top = a + (b - a) * fu
                    wv = (top + (c + (e - c) * fu - top) * fv) * boost
                    if wv > 0:
                        weights.append((wv, pool, seed))
                        total += wv
            t = 0.62 * coarse.at(x, y) + 0.38 * fine.at(x, y)
            t = min(0.999, max(0.0, (t - 0.5) * 1.9 + 0.5)) * total
            cum, pick, prev, gap = 0.0, None, None, 1.0
            for entry in weights:
                lo = cum
                cum += entry[0]
                if t < cum:
                    pick = entry
                    gap = (t - lo) / total if total else 1.0
                    break
                prev = entry
            if pick is None:
                pick = weights[-1] if weights else (1.0, classes[0][1], classes[0][2])
            cx = x // CELL
            cell = pick[1][hash32(cx, cy, pick[2]) % len(pick[1])]
            r, g, b, _ = cell[ty + x % CELL]
            if prev is not None and gap < edge:
                other = prev[1][hash32(cx, cy, prev[2]) % len(prev[1])][ty + x % CELL]
                f = int(128 * (1 - gap / edge))
                r, g, b = (r * (256 - f) + other[0] * f) >> 8, (g * (256 - f) + other[1] * f) >> 8, \
                    (b * (256 - f) + other[2] * f) >> 8
            k = int(_bilinear(light, cols, rows, gs, x, row))
            i = base + x
            pic.r[i] = min(255, r * k >> 8)
            pic.g[i] = min(255, g * k >> 8)
            pic.b[i] = min(255, b * k >> 8)


# ---------------------------------------------------------------------------
# Where everything is: per texel (row 0 north).


class Masks:
    """`r0`/`r1`: 1 + the index of the floor 0 / floor 1 room there (an
    earlier room over a later: the field over a tunnel's mouth); `rp`: 1 + the ramp's index; `cv`: 1 + the cover's
    index whose footprint holds the texel. `seen`: the floors UPPER shows
    (floor 1, the ramps, floor 0 outside the covers); `low`: floor 0 under a
    cover (LOWER's). `style`: per seen texel, what it is drawn as (see
    STYLES)."""

    def __init__(self, d, g):
        w, h = g["width"], g["height"]
        self.w, self.h = w, h
        n = w * h
        self.rooms, self.ramps, self.overlays = g["rooms"], g["ramps"], g["overlays"]
        self.r0, self.r1, self.rp, self.cv = bytearray(n), bytearray(n), bytearray(n), bytearray(n)
        for k in range(len(self.rooms) - 1, -1, -1):          # an earlier room over a later one
            r = self.rooms[k]
            self._fill(self.r0 if r["level"] == 0 else self.r1, r, k + 1)
        for k, r in enumerate(self.ramps):
            self._fill(self.rp, r, k + 1)
        for k, o in enumerate(self.overlays):
            fx0, fy0, fx1, fy1 = o["footprint"]
            for y in range(fy0, fy1):
                base = (h - 1 - y) * w
                self.cv[base + fx0:base + fx1] = bytes([k + 1]) * (fx1 - fx0)
        self.seen, self.low, self.style = bytearray(n), bytearray(n), bytearray(n)
        building = {s for s, name in enumerate(STYLES) if name in BUILDING}
        for i in range(n):
            if self.rp[i]:
                r = self.ramps[self.rp[i] - 1]
                self.seen[i] = 1
                self.style[i] = STYLES.index("indoor ramp" if r.get("indoor") else "outdoor ramp")
            elif self.r1[i] and not (self.r0[i] and not self.cv[i]):
                self.seen[i] = 1
                self.style[i] = STYLES.index(self.rooms[self.r1[i] - 1]["floor"])
            elif self.r0[i]:
                if self.cv[i]:
                    self.low[i] = 1
                else:
                    self.seen[i] = 1
                    self.style[i] = STYLES.index(self.rooms[self.r0[i] - 1]["floor"])
        self.indoor = bytearray(1 if self.seen[i] and self.style[i] in building else 0 for i in range(n))
        self.outdoor = bytearray(1 if self.seen[i] and self.style[i] not in building else 0 for i in range(n))

    def _fill(self, mask, r, value):
        w, h = self.w, self.h
        x0, x1 = int(r["x0"]), int(r["x1"])
        for y in range(int(r["y0"]), int(r["y1"])):
            base = (h - 1 - y) * w
            mask[base + x0:base + x1] = bytes([value]) * (x1 - x0)

    def side(self, y):
        return "alliance" if y >= self.h // 2 else "horde"


STYLES = ["", "field", "plateau", "slope", "tunnel", "hall", "flag room", "door", "indoor ramp", "outdoor ramp"]
BUILDING = ("hall", "flag room", "door", "indoor ramp")


# ---------------------------------------------------------------------------
# UPPER: the floors on the ground, their walls and cliffs.


def paint_floors(pic, d, m, tiles):
    """The bases' floors (each side's stones or planks, its runner down the
    middle of each hall), lit ramps with treads; shade along the foot of
    every wall. Outdoor floors keep the battleground's ground, a little
    shaded at their edges."""
    w, h = m.w, m.h
    edge = bank_distance(m.seen, w, h, 14)
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        base = row * w
        for x in range(w):
            i = base + x
            if not m.seen[i]:
                continue
            style = STYLES[m.style[i]]
            e = edge[i]
            if style in ("field", "plateau", "slope", "outdoor ramp"):
                if e <= 3:
                    k = 214 + 10 * e
                    pic.r[i], pic.g[i], pic.b[i] = pic.r[i] * k >> 8, pic.g[i] * k >> 8, pic.b[i] * k >> 8
                continue
            if style == "indoor ramp":
                continue                                   # paint_ramps
            floor = side["floor"]
            if "tile" in floor:
                r, g, b = _tile(tiles, floor, x, y, 5)
            else:
                r, g, b = parquet(x, y, floor["parquet"])
            k = 150 if e <= 1 else 196 + 60 * min(e, 14) // 14
            pic.r[i], pic.g[i], pic.b[i] = r * k >> 8, g * k >> 8, b * k >> 8


def _tile(tiles, spec, x, y, seed=3):
    r, g, b, _ = tiles.whole(spec["tile"], x, y, seed=seed, shade=spec.get("shade", 1.0))
    return r, g, b


def paint_runners(pic, d, m):
    """Each base's runner: its side's carpet down the middle of its halls and
    across its flag room's far side, edged; under the flag's dais."""
    w, h = m.w, m.h
    for r in m.rooms:
        if r["floor"] not in ("hall", "flag room") or not r.get("runner"):
            continue
        side = d["sides"][r["name"].split()[0]]
        body, trim = side["runner"]
        x0, y0, x1, y1 = r["runner"]
        for y in range(y0, y1):
            for x in range(x0, x1):
                i = (h - 1 - y) * w + x
                if not m.seen[i] or STYLES[m.style[i]] not in BUILDING:
                    continue
                t = min(x - x0, x1 - 1 - x, y - y0, y1 - 1 - y)
                rgb = trim if t < 3 else body
                v = hash32(x // 3, y, 455) % 9 - 4
                _put(pic, i, (max(0, min(255, rgb[0] + v)), max(0, min(255, rgb[1] + v)), max(0, min(255, rgb[2] + v))))


def ramp_frame(r):
    """(along, low, high, side0, side1): the ramp's axis ('x' or 'y'), its low
    and high end coordinates along it, its side faces across it."""
    if r["axis"] == "x":
        low, high = (r["x0"], r["x1"]) if r["ascending"] == 1 else (r["x1"], r["x0"])
        return "x", low, high, r["y0"], r["y1"]
    low, high = (r["y0"], r["y1"]) if r["ascending"] == 1 else (r["y1"], r["y0"])
    return "y", low, high, r["x0"], r["x1"]


def paint_ramps(pic, d, m, tiles):
    """Each ramp: lit toward its high end, the more where it climbs toward
    the camera (north); treads every 12 units; kerbs along its sides, a
    wall's width each (its sides are walls on both floors). Indoors, its
    side's floor stones; outdoors, the ground (the path the client's map
    has there)."""
    w, h = m.w, m.h
    inset = 18
    for r in m.ramps:
        side = d["sides"][r["name"].split()[0]]
        axis, low, high, s0, s1 = ramp_frame(r)
        indoor = r.get("indoor")
        facing = 1.0 if axis == "x" else (1.1 if high > low else 0.86)
        tr, tg, tb = side["wall"]["top"]
        cr, cg, cb = side["wall"]["coping"]
        for y in range(r["y0"], r["y1"]):
            row = h - 1 - y
            for x in range(r["x0"], r["x1"]):
                i = row * w + x
                q, c = (x, y) if axis == "x" else (y, x)
                t = (q - low) / (high - low)
                across = min(c - s0, s1 - 1 - c)
                if across < inset - 8:
                    # A kerb: coping on top, the wall's stones below it.
                    if across < 2:
                        rgb = _shade((tr, tg, tb), 190)
                    elif across >= inset - 11:
                        rgb = (cr, cg, cb)
                    else:
                        v = hash32(q // 9, c, 461) % 13 - 6
                        rgb = _shade((tr + 24 + v, tg + 22 + v, tb + 20 + v), 236)
                    _put(pic, i, rgb)
                    continue
                if indoor:
                    rgb = _tile(tiles, side["floor"], x, y, 11) if "tile" in side["floor"] else \
                        parquet(x, y, side["floor"]["parquet"])
                else:
                    rgb = (pic.r[i], pic.g[i], pic.b[i])
                k = int((176 + 80 * t) * facing)
                if int(abs(q - low)) % 12 < 2:
                    k -= 30
                if across < inset:
                    k -= 22
                _put(pic, i, _shade(rgb, max(0, min(300, k))))


def paint_walls(pic, d, m, tiles):
    """Where the floors end. Beside a base's floor, its walls: their tops in
    courses of its stone (or logs), up to WALL thick, the coping lit along
    the inner edge. Beside an outdoor floor, a cliff: a band of its side's
    rock CLIFF wide, dark at the floor's edge, into the ground beyond. Off
    every floor the ground darkens the farther it lies. The camera sees a
    floor's north wall rise over what lies beyond: a base's wall `height` x
    lean rows in its stones, a cliff CLIFF_HEIGHT x lean rows in its strata,
    each over its floor's whole north edge (a portal is cut later), stopping
    where another floor begins. Returns the faces' texels."""
    w, h = m.w, m.h
    lean = d["lean"]
    near_in = bank_distance(bytearray(1 - v for v in m.indoor), w, h, WALL + 2)
    near_out = bank_distance(bytearray(1 - v for v in m.outdoor), w, h, FAR)
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        wall = side["wall"]
        base = row * w
        for x in range(w):
            i = base + x
            if m.seen[i]:
                continue
            di, do = near_in[i], near_out[i]
            if di and di <= WALL and (not do or di <= do):
                if di <= 2:
                    rgb = wall["coping"] if di == 2 else _shade(wall["coping"], 196)
                elif di >= WALL - 1:
                    rgb = _shade(wall["top"], 170)
                else:
                    course = y // 12
                    bx = (x + (course % 2) * 12) // 24
                    v = hash32(bx, course, 401) % 15 - 7
                    joint = y % 12 == 0 or (x + (course % 2) * 12) % 24 == 0
                    s = 222 if joint else 248
                    tr, tg, tb = wall["top"]
                    rgb = _shade((tr + 26 + v, tg + 24 + v, tb + 24 + v), s)
                _put(pic, i, rgb)
                continue
            dist = do if do else FAR
            if dist <= CLIFF:
                rr, rg, rb = _tile(tiles, side["rock"], x, y, 23)
                if dist <= 2:
                    k = 96
                else:
                    k = 150 + 70 * (dist - 2) // (CLIFF - 2)
                f = 256 if dist <= CLIFF // 2 else 256 - 256 * (dist - CLIFF // 2) // (CLIFF - CLIFF // 2 + 1)
                kk = 228 - dist * 3 // 2
                pic.r[i] = (min(255, rr * k >> 8) * f + (pic.r[i] * kk >> 8) * (256 - f)) >> 8
                pic.g[i] = (min(255, rg * k >> 8) * f + (pic.g[i] * kk >> 8) * (256 - f)) >> 8
                pic.b[i] = (min(255, rb * k >> 8) * f + (pic.b[i] * kk >> 8) * (256 - f)) >> 8
            else:
                k = 228 - min(dist, FAR) * 3 // 2
                pic.r[i], pic.g[i], pic.b[i] = pic.r[i] * k >> 8, pic.g[i] * k >> 8, pic.b[i] * k >> 8
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
            if not m.seen[i] or m.seen[i - w]:
                continue
            y = h - 1 - row
            side = m.side(y)
            indoor = m.indoor[i]
            if indoor:
                kind, height = "wall", d["sides"][side]["wall"]["height"]
            else:
                kind, height = "cliff", CLIFF_HEIGHT
            up = int(height * lean + 0.5)
            cr, cg, cb = d["sides"][side]["wall"]["coping"]
            face = face_of(side, kind)
            for kk in range(1, up + 1):
                j = (row - kk) * w + x
                if row - kk < 0 or m.seen[j]:
                    break
                fr, fg, fb = face.sample(x, up - kk, up)
                s = 150 + 120 * kk // up
                if kind == "wall" and kk >= up - 2:
                    fr, fg, fb, s = cr, cg, cb, 256
                pic.r[j] = max(0, min(255, fr * s >> 8))
                pic.g[j] = max(0, min(255, fg * s >> 8))
                pic.b[j] = max(0, min(255, fb * s >> 8))
                faced[j] = 1
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


def paint_daises(pic, d, g):
    """Each flag's dais: a round stone step under the banner, ringed in its
    side's colour, and a ring on the floor round it (the flag the lap rounds)."""
    w, h = g["width"], g["height"]
    for s in g["solids"]:
        if not s["id"].endswith("_flag"):
            continue
        side = d["sides"][s["id"].split("_")[0]]
        body, trim = side["runner"]
        stone = side["wall"]["coping"]
        cx, cy, radius = s["x"] + s["width"] / 2, s["y"] + s["height"] / 2, s["width"] / 2
        for y in range(int(cy - radius - 30), int(cy + radius + 31)):
            for x in range(int(cx - radius - 30), int(cx + radius + 31)):
                if not (0 <= x < w and 0 <= y < h):
                    continue
                dist = sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2)
                i = (h - 1 - y) * w + x
                if dist <= radius - 3:
                    v = hash32(x // 4, y // 4, 467) % 11 - 5
                    lit = 236 + (30 if (x - cx) + (cy - y) < 0 else -10)
                    _put(pic, i, _shade((stone[0] + v, stone[1] + v, stone[2] + v), lit))
                elif dist <= radius:
                    _put(pic, i, trim)
                elif dist <= radius + 3:
                    pic.over(i, 20, 16, 14, 150)                  # its shadow on the floor
                elif abs(dist - (radius + 22)) < 2.5:
                    pic.over(i, body[0], body[1], body[2], 200)


def paint_thresholds(pic, d, g, m):
    """Each gate but the finish: a threshold across the floor in its side's
    colours (a band of the runner's trim, chevrons pointing the way)."""
    w, h = g["width"], g["height"]
    for gt in g["gates"][:-1]:
        side = d["sides"][gt["name"].split()[0].lower()]
        body, trim = side["runner"]
        horizontal = gt["ay"] == gt["by"]
        lo = int(min(gt["ax"], gt["bx"])) if horizontal else int(min(gt["ay"], gt["by"]))
        hi = int(max(gt["ax"], gt["bx"])) if horizontal else int(max(gt["ay"], gt["by"]))
        mid = gt["ay"] if horizontal else gt["ax"]
        n = gt["ny"] if horizontal else gt["nx"]
        for a in range(lo, hi):
            for b in range(-7, 8):
                x, y = (a, int(mid) + b) if horizontal else (int(mid) + b, a)
                i = (h - 1 - y) * w + x
                if not (m.seen[i] or m.low[i]):
                    continue
                if abs(b) >= 6:
                    pic.over(i, trim[0], trim[1], trim[2], 210)
                    continue
                # Chevrons every 24 along the gate, pointing along its normal.
                u = (a - lo) % 24 - 12
                tip = -b * n
                if abs(abs(u) - (tip + 6)) < 2.5 and abs(u) <= 10:
                    pic.over(i, trim[0], trim[1], trim[2], 230)
                else:
                    pic.over(i, body[0], body[1], body[2], 110)


def paint_finish(pic, g, m, thickness=12, cells=6):
    """A chequered band across the floor along the last gate (mid)."""
    gate = g["gates"][-1]
    w, h = g["width"], g["height"]
    horizontal = gate["ay"] == gate["by"]
    lo = int(min(gate["ax"], gate["bx"])) if horizontal else int(min(gate["ay"], gate["by"]))
    hi = int(max(gate["ax"], gate["bx"])) if horizontal else int(max(gate["ay"], gate["by"]))
    mid = int(gate["ay"] if horizontal else gate["ax"])
    for a in range(lo, hi):
        for b in range(mid - thickness // 2, mid + thickness // 2):
            x, y = (a, b) if horizontal else (b, a)
            i = (h - 1 - y) * w + x
            if not m.seen[i]:
                continue
            dark = ((a // cells) + ((b - (mid - thickness // 2)) // cells)) % 2
            pic.over(i, *((34, 30, 30) if dark else (226, 222, 210)), 225)


def paint_portals(pic, d, m, tiles):
    """Each tunnel's mouth (d["portals"]): an arch cut in the cliff's face
    (`arch`: the opening, clear in Roofs.tga, so the tunnel's own floor shows
    through it), framed in its side's stone or timber; or a lintel of timber
    along the cover's edge where the camera sees the hill's top. Returns
    the opening's texels."""
    w, h = m.w, m.h
    hole = bytearray(w * h)
    for p in d.get("portals", ()):
        side = d["sides"][p["side"]]
        x0, x1, y0, rise = p["x0"], p["x1"], p["y"], p.get("rise", 0)
        frame = side["portal"]
        cx, half = (x0 + x1) / 2, (x1 - x0) / 2
        if p["kind"] == "arch":
            for y in range(y0, y0 + rise + 10):
                for x in range(x0 - 10, x1 + 10):
                    i = (h - 1 - y) * w + x
                    # The opening: straight sides, a round head.
                    u = (x + 0.5 - cx) / half
                    top = rise - half * 0.6 * (1 - sqrt(max(0.0, 1 - u * u))) if abs(u) <= 1 else -1
                    k = y - y0
                    if abs(u) <= 1 and k < top:
                        hole[i] = 1
                        pic.r[i], pic.g[i], pic.b[i] = 10, 8, 8
                    elif abs(u) <= 1 + 10 / half and k < top + 10:
                        v = hash32(x // 6, y // 5, 471) % 13 - 6
                        s = 236 if (k + x) % 14 else 200
                        _put(pic, i, _shade((frame[0] + v, frame[1] + v, frame[2] + v), s))
        else:
            # A lintel along the cover's edge, posts at either side.
            for y in range(y0 - 8, y0 + 4):
                for x in range(x0 - 6, x1 + 6):
                    i = (h - 1 - y) * w + x
                    post = x < x0 + 6 or x >= x1 - 6
                    if y >= y0 - 2 or post:
                        v = hash32(x // 8, y, 473) % 15 - 7
                        s = 250 if y >= y0 else 196
                        _put(pic, i, _shade((frame[0] + v, frame[1] + v, frame[2] + v), s))
    return hole


# ---------------------------------------------------------------------------
# LOWER: the tunnels under their covers.


def paint_lower(pic, d, m, tiles):
    """Within each cover's footprint: the hill's dark earth; the tunnel's
    floor (its side's dirt, a timber frame across it every 48 units, lit
    toward the middle) and walls (timber-lined earth, a post every 24)."""
    w, h = m.w, m.h
    near = bank_distance(bytearray(1 - v for v in m.low), w, h, 20)
    edge = bank_distance(m.low, w, h, 14)
    for row in range(h):
        y = h - 1 - row
        side = d["sides"][m.side(y)]
        er, eg, eb = side["earth"]
        base = row * w
        for x in range(w):
            i = base + x
            if not m.cv[i]:
                continue
            if m.low[i]:
                r, g, b = _tile(tiles, side["tunnel"], x, y, 7)
                if y % 48 < 5:
                    r, g, b = _shade(parquet(x, y, {"block": 64, "plank": 5, "colour": (110, 78, 48)}), 230)
                e = edge[i]
                k = 150 if e <= 1 else 190 + 52 * min(e, 14) // 14
                _put(pic, i, _shade((r, g, b), k))
                continue
            e = near[i]
            if e <= WALL:
                v = hash32(x // 3, y // 2, 617) % 17 - 8
                fr, fg, fb = er + 34 + v, eg + 28 + v, eb + 20 + v
                if (y // 24) % 2 == 0 and y % 24 < 4 or e <= 2:
                    fr, fg, fb = 100 + v, 70 + v, 44 + v           # timber
                _put(pic, i, _shade((fr, fg, fb), 236 - 4 * e))
            else:
                v = hash32(x // 6, y // 6, 613) % 13 - 6
                _put(pic, i, (max(0, er + v), max(0, eg + v), max(0, eb + v)))


# ---------------------------------------------------------------------------
# Models.


def prop_trouble(g, m, free, item, sprite, X, Y, walls=None):
    """Why a model may not stand where it is drawn, or None: a model that is
    not solid keeps its drawn body off every floor UPPER shows (by the
    slack); every model stands wholly in or wholly out of each cover (its
    picture would be cut where the cover fades); optional scenery keeps out
    of the bases' walls (`walls`: per texel, its distance from a base's
    floor)."""
    w, h = g["width"], g["height"]
    col0, row0 = X - sprite["ox"], h - Y - sprite["oy"]
    covers = set()
    for i, j in sprite["body_points"]:
        row, col = row0 + j, col0 + i
        if 0 <= row < h and 0 <= col < w:
            covers.add(m.cv[row * w + col])
    if len(covers) > 1:
        return f"{item['name']} at ({X}, {Y}) stands across a cover's edge: move it"
    if walls is not None and 0 <= X < w and 0 <= Y < h and walls[(h - 1 - Y) * w + X] <= WALL + 4:
        return f"{item['name']} at ({X}, {Y}) stands in a base's walls"
    if item["solid"]:
        return None
    for i, j in sprite["body_points"]:
        x, y = col0 + i + 0.5, h - 1 - (row0 + j) + 0.5
        px, py = int(x), int(y)
        if not (0 <= px < w and 0 <= py < h):
            continue
        under = m.cv[(h - 1 - py) * w + px]
        for level in (0, 1):
            if level == 0 and under:
                continue                           # floor 0 runs beneath the cover: not seen
            if free[level].allowed(x, y):
                return (f"{item['name']} at ({X}, {Y}) stands where floor {level} drives "
                        f"(its body at {x:.0f}, {y:.0f}): make it solid or move it")
    return None


def check_props(g, m, placed):
    """The scenery that may stand (prop_trouble): optional models that may
    not are left out; any other stops the build. Returns those kept."""
    from build_battlegrounds import floor_definition
    from build_dungeon_tracks import Floor
    free = {level: Floor(dict(floor_definition(g, level), wallInset=g["wallInset"] + PROP_SLACK))
            for level in (0, 1)}
    walls = bank_distance(bytearray(1 - v for v in m.indoor), m.w, m.h, WALL + 6)
    kept = []
    for entry in placed:
        item, sprite, X, Y, level = entry
        why = prop_trouble(g, m, free, item, sprite, X, Y, walls if item.get("optional") else None)
        if why is None:
            kept.append(entry)
        elif not item.get("optional"):
            raise SystemExit("LAYOUT: " + why)
    return kept


def place(wc3, d, items, cache, level):
    placed = []
    for item in items:
        sprite = sprite_for(wc3, d, item, cache)
        forget_textures()
        placed.append((item, sprite, int(round(item["x"])), int(round(item["y"])), level))
    return placed


def paint_lights(pic, d, placed, m):
    """A pool of light round each model that has one (`light`: (radius,
    (r, g, b))), on the ground under it."""
    w, h = pic.w, pic.h
    for item, sprite, X, Y, level in placed:
        light = item.get("light")
        if not light:
            continue
        radius, (lr, lg, lb) = light
        for y in range(Y - radius, Y + radius + 1):
            for x in range(X - radius, X + radius + 1):
                if not (0 <= x < w and 0 <= y < h):
                    continue
                d2 = (x - X) ** 2 + (y - Y) ** 2
                if d2 > radius * radius:
                    continue
                a = int(70 * (1 - d2 / (radius * radius)))
                i = (h - 1 - y) * w + x
                pic.r[i] = min(255, pic.r[i] + (lr * a >> 8))
                pic.g[i] = min(255, pic.g[i] + (lg * a >> 8))
                pic.b[i] = min(255, pic.b[i] + (lb * a >> 8))


# ---------------------------------------------------------------------------
# The build.


def build(wc3, d, g, check=False, preview=False, log=print, cache=None):
    if g.get("kind") == "circuit":
        return build_circuit(wc3, d, g, check=check, preview=preview, log=log, cache=cache)
    started = time.time()
    w, h = g["width"], g["height"]
    tiles = Tileset(wc3)
    sv = Survey(Path(__file__).resolve().parent / d["survey"])
    m = Masks(d, g)
    upper = Picture(w, h)
    light = relief_light(sv, d["relief"])
    paint_ground(upper, d, sv, tiles, light)
    log(f"  ground {time.time() - started:.0f}s")
    paint_floors(upper, d, m, tiles)
    paint_runners(upper, d, m)
    paint_ramps(upper, d, m, tiles)
    paint_walls(upper, d, m, tiles)
    hole = paint_portals(upper, d, m, tiles)
    paint_finish(upper, g, m)
    paint_thresholds(upper, d, g, m)
    paint_daises(upper, d, g)
    log(f"  floors {time.time() - started:.0f}s")
    cache = {} if cache is None else cache
    candidates = place(wc3, d, d["props"], cache, 0) + place(wc3, d, d["roof_props"], cache, 1)
    models = check_props(g, m, candidates)
    paint_lights(upper, d, models, m)
    for item, sprite, X, Y, _ in sorted(models, key=lambda p: (-p[3], p[2])):
        paint_sprite(upper, sprite, X, Y)
    log(f"  models {time.time() - started:.0f}s ({len(models)} models, {len(candidates) - len(models)} optional left out)")
    lower = Picture(w, h)
    paint_lower(lower, d, m, tiles)
    paint_pads(lower, d, g)
    paint_thresholds(lower, d, g, m)
    # Background: UPPER, LOWER under the covers. Roofs: UPPER over them.
    background = Picture(w, h)
    layer = Layer(w, h)
    for i in range(w * h):
        if m.cv[i]:
            background.r[i], background.g[i], background.b[i] = lower.r[i], lower.g[i], lower.b[i]
            if not hole[i]:
                layer.r[i], layer.g[i], layer.b[i], layer.a[i] = upper.r[i], upper.g[i], upper.b[i], 255
        else:
            background.r[i], background.g[i], background.b[i] = upper.r[i], upper.g[i], upper.b[i]
    preview_rows = upper.rows(4)
    folder = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / d["folder"]
    outputs = [(folder / "Background.tga", background.tga()), (folder / "Roofs.tga", layer.tga()),
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
        (docs / f"{d['id']}-sources.txt").write_text(sources(d, tiles, models), encoding="utf-8", newline="\n")
    return upper, lower, background, layer


# ---------------------------------------------------------------------------
# A circuit on the battleground's own ground (Arathi Basin).
#
# One floor, one picture. The street is city_paint's (Street: per texel the
# distance beyond the karts' reach plus a kart's length, `gap`, <= 0 inside;
# the nearest road axis, its segment and the distance to it, `lane`). Over the
# battleground's own ground (paint_ground, the relief's light):
#
# - the water the survey measured, outside the street (paint_circuit_water);
# - the street (paint_course): the course's dirt road along its axis (to the
#   paved radius, a ragged edge, two worn ruts), grass to the walls, the
#   plazas in the yard's dirt, all under the relief's light; on a narrows (a
#   bridge) its stone deck from bank to bank;
# - the walls (circuit_walls): a timber rail fence along the street's edge,
#   a stone parapet on the bridges and wherever water lies beyond;
# - the finish line; the scenery (the survey's placements as Warcraft III
#   models; the bases), with the walls, north to south.


def narrow_segments_of(g, street):
    """{Street segment index: the narrows' drivable radius} for the loop
    segments in a narrows (Lua segment k is Street segment k % n)."""
    n = street.loop_count
    out = {}
    for narrow in g.get("narrows", ()):
        for k in range(narrow["first"], narrow["last"] + 1):
            out[k % n] = narrow["wallRadius"]
    return out


def water_depth(sv, x, row):
    """The survey's water depth (yards) at picture texel (x, row),
    bilinear; 0 where there is none."""
    return _bilinear(sv.water, sv.cols, sv.rows, sv.grid, x, row)


def even(values, cols, rows, passes):
    """A survey plane evened by `passes` 3 x 3 means (the edges keep their
    own neighbours only)."""
    for _ in range(passes):
        out = [0.0] * (cols * rows)
        for r in range(rows):
            r0, r1 = max(0, r - 1), min(rows - 1, r + 1)
            for c in range(cols):
                c0, c1 = max(0, c - 1), min(cols - 1, c + 1)
                acc = 0.0
                for rr in range(r0, r1 + 1):
                    base = rr * cols
                    for cc in range(c0, c1 + 1):
                        acc += values[base + cc]
                out[r * cols + c] = acc / ((r1 - r0 + 1) * (c1 - c0 + 1))
        values = out
    return values


def paint_circuit_water(pic, d, sv, street, light):
    """The rivers and pools, outside the street: shallow to deep by the
    measured depth (evened, spec["smooth"] passes: the client's water ends
    on its terrain cells' edges), a slow swell of light over them, pale where
    they meet the bank."""
    if sv.water is None:
        return bytearray(pic.w * pic.h)
    spec = d["water"]
    w, h, gs, cols = pic.w, pic.h, sv.grid, sv.cols
    depths = even(sv.water, cols, sv.rows, spec.get("smooth", 0))
    shallow, deep, bank = spec["shallow"], spec["deep"], spec["bank"]
    swell, glint = _Noise(26, 811), _Noise(5, 813)
    wet = bytearray(w * h)
    for sr in range(sv.rows):
        for sc in range(cols):
            near = False
            for rr in (sr - 1, sr, sr + 1):
                for cc in (sc - 1, sc, sc + 1):
                    if 0 <= rr < sv.rows and 0 <= cc < cols and depths[rr * cols + cc] > 0:
                        near = True
            if not near:
                continue
            for row in range(sr * gs, sr * gs + gs):
                y = h - 1 - row
                base = row * w
                for x in range(sc * gs, sc * gs + gs):
                    i = base + x
                    if street.gap[i] <= 0:
                        continue
                    depth = _bilinear(depths, cols, sv.rows, gs, x, row)
                    if depth < spec["shore"]:
                        continue
                    wet[i] = 1
                    t = min(1.0, depth / spec["full"])
                    r = shallow[0] + (deep[0] - shallow[0]) * t
                    g_ = shallow[1] + (deep[1] - shallow[1]) * t
                    b = shallow[2] + (deep[2] - shallow[2]) * t
                    k = 0.86 + 0.24 * swell.at(x, y) + (0.10 if glint.at(x, y) > 0.86 else 0.0)
                    edge = depth - spec["shore"]
                    if edge < spec["rim"]:
                        f = 1.0 - edge / spec["rim"]
                        r, g_, b = r + (bank[0] - r) * f, g_ + (bank[1] - g_) * f, b + (bank[2] - b) * f
                    pic.r[i] = max(0, min(255, int(r * k)))
                    pic.g[i] = max(0, min(255, int(g_ * k)))
                    pic.b[i] = max(0, min(255, int(b * k)))
    return wet


def survey_road_mask(sv, spec, w, h):
    """Per texel (row 0 north), 1 where the client paints its road: the
    weight of the ground texture spec["plane"], evened (spec["smooth"]
    passes: its texels are noisy) and bilinear between the survey's texels,
    over spec["threshold"], its edge ragged by spec["ragged"] (a share of a
    full weight either way); patches smaller than spec["least"] texels of
    the survey are left out (scattered rubble, not a road)."""
    gs, cols, rows = sv.grid, sv.cols, sv.rows
    plane = even([v / 15.0 for v in sv.planes[spec["plane"]]], cols, rows, spec.get("smooth", 0))
    threshold, ragged = spec["threshold"], spec.get("ragged", 0.0)
    # The road's patches on the survey's grid, eight-connected; the small ones go.
    keep = bytearray(cols * rows)
    seen = bytearray(cols * rows)
    for start in range(cols * rows):
        if seen[start] or plane[start] <= threshold:
            continue
        seen[start] = 1
        patch, todo = [start], [start]
        while todo:
            i = todo.pop()
            r, c = divmod(i, cols)
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    rr, cc = r + dr, c + dc
                    if 0 <= rr < rows and 0 <= cc < cols:
                        j = rr * cols + cc
                        if not seen[j] and plane[j] > threshold:
                            seen[j] = 1
                            patch.append(j)
                            todo.append(j)
        if len(patch) >= spec.get("least", 1):
            for i in patch:
                keep[i] = 1
    noise = _Noise(9, 841)
    mask = bytearray(w * h)
    for sr in range(rows):
        for sc in range(cols):
            near = False
            for rr in (sr - 1, sr, sr + 1):
                for cc in (sc - 1, sc, sc + 1):
                    if 0 <= rr < rows and 0 <= cc < cols and keep[rr * cols + cc]:
                        near = True
            if not near:
                continue
            for row in range(sr * gs, sr * gs + gs):
                y = h - 1 - row
                base = row * w
                for x in range(sc * gs, sc * gs + gs):
                    if _bilinear(plane, cols, rows, gs, x, row) < threshold + ragged * (2.0 * noise.at(x, y) - 1.0):
                        continue
                    # Only where a kept patch is among the four texels blended.
                    c0 = max(0, min(cols - 1, int(((x + 0.5) / gs - 0.5) // 1)))
                    r0 = max(0, min(rows - 1, int(((row + 0.5) / gs - 0.5) // 1)))
                    c1, r1 = min(cols - 1, c0 + 1), min(rows - 1, r0 + 1)
                    if keep[r0 * cols + c0] or keep[r0 * cols + c1] or keep[r1 * cols + c0] or keep[r1 * cols + c1]:
                        mask[base + x] = 1
    return mask


def paint_survey_roads(pic, d, street, tiles, light, sv, mask, wet):
    """The client's roads outside the street (`mask`), drawn as the street's
    road, a little paler down the middle and darker along its edges (2 units
    from the verge), so a road reads as a road on the rocky ground: the
    paths a kart would take if nothing stood in them."""
    w, h, gs, cols, rows = pic.w, pic.h, sv.grid, sv.cols, sv.rows
    road = d["course"]["road"]
    crown, rim = d["survey_roads"].get("crown", 268), d["survey_roads"].get("rim", 200)
    for row in range(h):
        base = row * w
        y = h - 1 - row
        for x in range(w):
            i = base + x
            if not mask[i] or wet[i] or street.gap[i] <= 0:
                continue
            edge = False
            for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
                xx, rr = x + dx, row + dy
                if 0 <= xx < w and 0 <= rr < h and not mask[rr * w + xx]:
                    edge = True
            rgb = _tile(tiles, road, x, y, 17)
            k = int(_bilinear(light, cols, rows, gs, x, row)) * (rim if edge else crown) >> 8
            _put(pic, i, _shade(rgb, k))


def paint_cliffs(pic, d, sv, street, tiles, wet):
    """The steep ground off the street as cliffs (d["cliffs"]): where the
    terrain (evened once) rises steeper than spec["from"] (yards per yard), a
    rock face, wholly from spec["full"]: the cliff texture's strata
    (spec["face"]) laid along the slope's contours (spec["strata"] rows per
    yard of height), lit by its own steepness toward spec["light"] and dimmed
    with the sky (occlusion); its brink (the top) catches the light, its foot
    is in shade. Returns the faces' texels (no scenery stands on a cliff)."""
    spec = d["cliffs"]
    w, h, gs, cols, rows = pic.w, pic.h, sv.grid, sv.cols, sv.rows
    hts = survey_heights(sv, spec.get("smooth", 1))
    shut = occlusion(sv, hts, d["relief"]["occlusion"]) if d["relief"].get("occlusion") else [1.0] * (cols * rows)
    # Per texel: the gradient (yards per world unit, x east and y north).
    gxs, gys = [0.0] * (cols * rows), [0.0] * (cols * rows)
    steep = bytearray(cols * rows)
    lo, hi = spec["from"], spec["full"]
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            gx = (hts[i + 1 if c + 1 < cols else i] - hts[i - 1 if c else i]) / (2.0 * gs)
            gy = (hts[i - cols if r else i] - hts[i + cols if r + 1 < rows else i]) / (2.0 * gs)
            gxs[i], gys[i] = gx, gy
            if 3.0 * sqrt(gx * gx + gy * gy) > lo * 0.8:
                steep[i] = 1
    strata = Strata(tiles, spec["face"])
    srows, swidth, sheight = strata.rows, strata.width, strata.height
    flat = spec.get("flatten", 0.0)
    if flat:
        count = swidth * sheight
        mr = sum(t[0] for line in srows for t in line) / count
        mg = sum(t[1] for line in srows for t in line) / count
        mb = sum(t[2] for line in srows for t in line) / count
        srows = [[(int(t[0] + (mr - t[0]) * flat), int(t[1] + (mg - t[1]) * flat), int(t[2] + (mb - t[2]) * flat))
                  for t in line] for line in srows]
    kv = spec["strata"]
    lx, ly, lz = spec["light"]
    norm = sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / norm, ly / norm, lz / norm
    br, bg, bb = spec["brink"]
    foot = spec["foot"]
    thick = d["wall"]["thickness"]
    face = bytearray(w * h)

    def weight(x, row):
        gx = _bilinear(gxs, cols, rows, gs, x, row)
        gy = _bilinear(gys, cols, rows, gs, x, row)
        t = (3.0 * sqrt(gx * gx + gy * gy) - lo) / (hi - lo)
        return (0.0 if t < 0.0 else (1.0 if t > 1.0 else t)), gx, gy

    for sr in range(rows):
        for sc in range(cols):
            near = False
            for rr in (sr - 1, sr, sr + 1):
                for cc in (sc - 1, sc, sc + 1):
                    if 0 <= rr < rows and 0 <= cc < cols and steep[rr * cols + cc]:
                        near = True
            if not near:
                continue
            for row in range(sr * gs, sr * gs + gs):
                y = h - 1 - row
                base = row * w
                for x in range(sc * gs, sc * gs + gs):
                    i = base + x
                    if wet[i] or street.gap[i] <= thick + 1.5:
                        continue
                    f, gx, gy = weight(x, row)
                    if f <= 0.0:
                        continue
                    g2 = gx * gx + gy * gy
                    glen = sqrt(g2)
                    ux, uy = gx / glen, gy / glen                 # uphill
                    height = _bilinear(hts, cols, rows, gs, x, row)
                    ty = int((height * kv) // 1) % sheight
                    across = gy * gy / g2                          # an east-west cliff: strata run east
                    a = srows[ty][(x * 2) % swidth]
                    b = srows[ty][(y * 2) % swidth]
                    cr = a[0] * across + b[0] * (1.0 - across)
                    cg = a[1] * across + b[1] * (1.0 - across)
                    cb = a[2] * across + b[2] * (1.0 - across)
                    nx, ny = -3.0 * gx, -3.0 * gy
                    lit = (nx * lx + ny * ly + lz) / sqrt(nx * nx + ny * ny + 1.0)
                    k = (spec.get("dark", 0.36) + spec.get("bright", 0.82) * (lit if lit > 0.0 else 0.0)) * \
                        _bilinear(shut, cols, rows, gs, x, row)
                    cr, cg, cb = cr * k, cg * k, cb * k
                    # The brink: no face a little way uphill; the foot: none downhill.
                    up, _, _ = weight(int(x + ux * 5.0 + 0.5), int(row - uy * 5.0 + 0.5))
                    if up < f:
                        e = spec.get("lip", 0.45) * (f - up)
                        cr, cg, cb = cr + (br - cr) * e, cg + (bg - cg) * e, cb + (bb - cb) * e
                    down, _, _ = weight(int(x - ux * 5.0 + 0.5), int(row + uy * 5.0 + 0.5))
                    if down < f:
                        e = 1.0 - foot * (f - down)
                        cr, cg, cb = cr * e, cg * e, cb * e
                    m = int(256 * f)
                    pic.r[i] = max(0, min(255, (pic.r[i] * (256 - m) + int(cr) * m) >> 8))
                    pic.g[i] = max(0, min(255, (pic.g[i] * (256 - m) + int(cg) * m) >> 8))
                    pic.b[i] = max(0, min(255, (pic.b[i] * (256 - m) + int(cb) * m) >> 8))
                    if f > 0.5:
                        face[i] = 1
    # The ground at a face's foot in its shade: off the faces, within
    # spec["shadow"][0] units downhill of one, dimmed by up to [1].
    reach_, depth = spec.get("shadow", (0, 0.0))
    if reach_:
        for row in range(h):
            y = h - 1 - row
            base = row * w
            for x in range(w):
                i = base + x
                if face[i] or wet[i] or street.gap[i] <= 0:
                    continue
                sr, sc = row // gs, x // gs
                if not steep[min(rows - 1, sr) * cols + min(cols - 1, sc)]:
                    continue
                gx = _bilinear(gxs, cols, rows, gs, x, row)
                gy = _bilinear(gys, cols, rows, gs, x, row)
                glen = sqrt(gx * gx + gy * gy)
                if glen <= 0.0:
                    continue
                ux, uy = gx / glen, gy / glen
                for k in range(2, reach_ + 1, 2):
                    xx, rr = int(x + ux * k + 0.5), int(row - uy * k + 0.5)
                    if 0 <= xx < w and 0 <= rr < h and face[rr * w + xx]:
                        dim = int(256 - 256 * depth * (1.0 - (k - 2) / reach_))
                        pic.r[i], pic.g[i], pic.b[i] = (pic.r[i] * dim) >> 8, (pic.g[i] * dim) >> 8, \
                            (pic.b[i] * dim) >> 8
                        break
    return face


def openings(d, street, roads):
    """The fence's texels left out where a real road leaves the course
    (d["openings"]: each `at` a road's mouth, within `reach`): the street's
    edge band where the client's road (`roads`, widened by 3) crosses it.
    {opening index: [texel index, ...]}."""
    w, h = street.w, street.h
    thick = d["wall"]["thickness"]
    out = {}
    for k, opening in enumerate(d.get("openings", ())):
        ax, ay = opening["at"]
        reach = opening["reach"]
        found = []
        for y in range(max(0, int(ay - reach)), min(h, int(ay + reach) + 1)):
            row = h - 1 - y
            for x in range(max(0, int(ax - reach)), min(w, int(ax + reach) + 1)):
                if (x - ax) ** 2 + (y - ay) ** 2 > reach * reach:
                    continue
                i = row * w + x
                if not (0.5 < street.gap[i] <= thick + 0.5):
                    continue
                hit = False
                for dy in (-3, 0, 3):
                    for dx in (-3, 0, 3):
                        xx, rr = x + dx, row + dy
                        if 0 <= xx < w and 0 <= rr < h and roads[rr * w + xx]:
                            hit = True
                if hit:
                    found.append(i)
        if not found:
            raise SystemExit(f"LAYOUT: no road leaves the course at {opening['name']}")
        out[k] = found
    return out


def _octant(dx, dy):
    """A model's yaw (degrees, a multiple of 45, 0 east, 90 north) facing
    (dx, dy), without a transcendental: by the ratio of the sides."""
    t = 0.41421356237309503                     # tan(22.5 degrees)
    if abs(dy) <= abs(dx) * t:
        return 0 if dx >= 0 else 180
    if abs(dx) <= abs(dy) * t:
        return 90 if dy >= 0 else 270
    if dx >= 0:
        return 45 if dy >= 0 else 315
    return 135 if dy >= 0 else 225


def place_blockers(wc3, d, street, gaps, cache, log):
    """What stands in each opening's road (d["openings"], d["blockers"]):
    along the gap in the fence, a model every `spacing` units at the street's
    edge facing the course, and a second row behind; each stepped outward
    until its body is off the street. Every texel of the gap must lie within
    `cover` units of a model's body, so a kart never stops at nothing."""
    from city_layouts import prop
    from city_paint import body_clear
    w, h = street.w, street.h
    placed = []
    for k, opening in enumerate(d.get("openings", ())):
        kinds = d["blockers"][opening["blockers"]]
        spacing = opening.get("spacing", 14)
        # The front row: greedily, every texel of the gap within 0.7 of a
        # spacing of a model's place (in the order of the course).
        texels = sorted(gaps[k], key=lambda i: (street.along(i), i))
        fronts, spots = [], []
        near = (0.7 * spacing) ** 2
        for i in texels:
            row, x = divmod(i, w)
            y = h - 1 - row
            if any((x - fx) ** 2 + (y - fy) ** 2 < near for fx, fy in spots):
                continue
            fronts.append(i)
            spots.append((x, y))
        rows = [(fronts, 3.0, 0)]
        if opening.get("rows", 2) > 1:
            rows.append((fronts[1::2] if len(fronts) > 2 else fronts, 3.0 + opening.get("depth", 18), 1))
        front_points = []
        for texels_, out, rank in rows:
            for n, i in enumerate(texels_):
                row, x = divmod(i, w)
                y = h - 1 - row
                nx, ny = street.nx[i], street.ny[i]
                px, py = x + 0.5 + nx * out, y + 0.5 + ny * out
                if rank:
                    px, py = px - ny * spacing * 0.5, py + nx * spacing * 0.5
                model, sequence, scale, team = kinds[hash32(int(px), int(py), 61 + k) % len(kinds)]
                item = prop(model, int(round(px)), int(round(py)), yaw=_octant(-nx, -ny), scale=scale,
                            sequence=sequence, team=team, name="%s_%d" % (opening["blockers"], len(placed)))
                sprite = sprite_for(wc3, d, item, cache)
                forget_textures()
                X, Y = item["x"], item["y"]
                for push in range(0, 80, 2):
                    QX, QY = int(round(X + nx * push)), int(round(Y + ny * push))
                    if body_clear(street, sprite, QX, QY):
                        X, Y = QX, QY
                        break
                else:
                    raise SystemExit(f"LAYOUT: {item['name']} in {opening['name']} cannot stand off the street")
                placed.append((item, sprite, X, Y))
                col0, row0 = X - sprite["ox"], h - Y - sprite["oy"]
                for bi, bj in sprite["body_points"]:
                    c, r = col0 + bi, row0 + bj
                    if 0 <= c < w and 0 <= r < h:
                        front_points.append(r * w + c)
        body = set(front_points)
        cover = opening.get("cover", 9)
        for i in gaps[k]:
            row, x = divmod(i, w)
            if not any((row + dy) * w + x + dx in body for dy in range(-cover, cover + 1)
                       for dx in range(-cover, cover + 1)):
                raise SystemExit(f"LAYOUT: the gap in the fence at {opening['name']} is open at "
                                 f"({x}, {h - 1 - row})")
        log(f"  {opening['name']}: {len(gaps[k])} texels of road, {len(fronts)} models in front")
    return placed


def paint_course(pic, d, g, street, sv, tiles, light, roads=None, zone=None):
    """Inside the street (gap <= 0): the road, the verges, the plazas, the
    decks (see above). A meadow (a grass plaza: d["course"]["meadow"]) is
    long grass where the karts' reach of the road ends; the verge beside it
    is worn to the yard's dirt, so the road's full speed and the meadow's
    slow grass do not look alike. Within an opening's `zone`, the client's
    road (`roads`) runs across the verge into the street's. Returns the
    decks' texels."""
    w, h, gs, cols, rows = pic.w, pic.h, sv.grid, sv.cols, sv.rows
    spec = d["course"]
    road, verge, yard, deck_spec = spec["road"], spec["verge"], spec["yard"], spec["deck"]
    meadow = spec.get("meadow") if any(p.get("surface") == "grass" for p in g["plazas"]) else None
    reach = g["wallRadius"]
    tufts = []
    half, rut = spec["road_half"], spec["rut"]
    narrows = narrow_segments_of(g, street)
    kart = street.kart
    ragged = _Noise(14, 821)
    deck = bytearray(w * h)
    # The decks (d["decks"]: each the straight from bank to bank, a to b):
    # a narrows' texels within its chord's ends.
    chords = []
    for (ax, ay), (bx, by) in d.get("decks", ()):
        length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
        chords.append((ax, ay, (bx - ax) / length, (by - ay) / length, length))
    for (bi, bj) in street.buckets:
        for y in range(bj * 64, min(h, (bj + 1) * 64)):
            row = h - 1 - y
            base = row * w
            for x in range(bi * 64, min(w, (bi + 1) * 64)):
                i = base + x
                gap = street.gap[i]
                if gap > 0:
                    continue
                lane, seg = street.lane[i], street.seg[i]
                on_deck = False
                if seg in narrows and lane <= narrows[seg] + kart + 0.5:
                    for ax, ay, ux, uy, length in chords:
                        t = (x + 0.5 - ax) * ux + (y + 0.5 - ay) * uy
                        c = -(x + 0.5 - ax) * uy + (y + 0.5 - ay) * ux
                        if 0.0 <= t <= length and abs(c) <= narrows[seg] + kart + 0.5:
                            on_deck = True
                if on_deck:
                    deck[i] = 1
                    rgb = _tile(tiles, deck_spec, x, y, 13)
                    # Shaded toward the parapets; the courses' joints every 16.
                    k = 236 if lane > narrows[seg] + kart - 6 else 256
                    if int(street.along(i)) % 16 == 0:
                        k -= 30
                    _put(pic, i, _shade(rgb, k))
                    continue
                edge = half + 8 * (ragged.at(x, y) - 0.5)
                if lane <= edge:
                    rgb = _tile(tiles, road, x, y, 17)
                    if abs(lane - rut[0]) < rut[1]:
                        rgb = _shade(rgb, 222)
                elif street.plaza[i] and meadow and \
                        lane > (narrows[seg] if seg in narrows else reach) + 16 * (ragged.at(x, y) - 0.5):
                    rgb = _tile(tiles, meadow, x, y, 29)
                    if hash32(x, y, 97) % meadow["tuft_every"] == 0:
                        tufts.append(i)
                elif street.plaza[i]:
                    rgb = _tile(tiles, yard, x, y, 19)
                elif roads is not None and zone[i] and roads[i]:
                    rgb = _tile(tiles, road, x, y, 17)
                else:
                    rgb = _tile(tiles, verge, x, y, 23)
                k = int(_bilinear(light, cols, rows, gs, x, row))
                if gap > -6:
                    k = k * (226 + 5 * int(-gap)) >> 8          # the wall's foot in its shade
                _put(pic, i, _shade(rgb, k))
    # The meadow's long grass: a blade or two up from each tuft's root, pale
    # at the tip, in the meadow only.
    if meadow:
        tip, root = meadow["tip"], meadow["root"]
        for i in tufts:
            row, x = divmod(i, w)
            tall = 3 + hash32(x, row, 101) % 4
            for lean in ((0,) if hash32(x, row, 103) % 3 else (0, 1)):
                for k in range(tall):
                    rr, xx = row - k, x + (lean * k) // 3
                    if rr < 0 or xx >= w:
                        break
                    j = rr * w + xx
                    seg_ = street.seg[j]
                    if street.gap[j] > 0 or not street.plaza[j] or \
                            street.lane[j] <= (narrows[seg_] if seg_ in narrows else reach):
                        break
                    c = tip if k >= tall - 2 else root
                    pic.r[j], pic.g[j], pic.b[j] = (pic.r[j] + c[0]) >> 1, (pic.g[j] + c[1]) >> 1, \
                        (pic.b[j] + c[2]) >> 1
    return deck


def circuit_walls(d, street, deck, skip=frozenset()):
    """The street's edge walls (as city_paint.wall_columns lays them): per
    world row, the texels just outside the karts' reach plus a kart, each
    with its height and style: a bridge's stone parapet beside its deck
    (taller every 24 units), else the timber rail fence (`rope_fence`, its
    rails straight). None in `skip` (where a road leaves the course)."""
    w, h = street.w, street.h
    thick = d["wall"]["thickness"]
    fence = d["rope_fence"]["land"]
    rows = {}
    for (bi, bj) in street.buckets:
        for y in range(bj * 64, min(h, (bj + 1) * 64)):
            row = h - 1 - y
            for x in range(bi * 64, min(w, (bi + 1) * 64)):
                i = row * w + x
                gap = street.gap[i]
                if not (0.5 < gap <= thick + 0.5) or i in skip:
                    continue
                along = street.along(i) if street.seg[i] >= 0 else float(x + y)
                inner_x = int(x - street.nx[i] * (gap + 2))
                inner_y = int(y - street.ny[i] * (gap + 2))
                if 0 <= inner_x < w and 0 <= inner_y < h and deck[(h - 1 - inner_y) * w + inner_x]:
                    rows.setdefault(y, []).append((x, 14 if along % 24 < 5 else 10, "bridge"))
                    continue
                rows.setdefault(y, []).append((x, fence["post_height"], "rope",
                                               (along % fence["every"], fence, 1.5 < gap <= 3.8)))
    return rows


def paint_off_bridges(pic, d, street, tiles, walls):
    """The bridges off the course (d["bridges"]: each from its end `a` to
    `b`, `width` wide), outside the street: a stone deck over the water and
    its parapets (added to `walls`, the street's wall rows)."""
    w, h = pic.w, pic.h
    deck_spec = d["course"]["deck"]
    for bridge in d.get("bridges", ()):
        (ax, ay), (bx, by), width = bridge["a"], bridge["b"], bridge["width"]
        length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
        ux, uy = (bx - ax) / length, (by - ay) / length
        half = width / 2.0
        x0, x1 = int(min(ax, bx) - half - 2), int(max(ax, bx) + half + 3)
        y0, y1 = int(min(ay, by) - half - 2), int(max(ay, by) + half + 3)
        for y in range(max(0, y0), min(h, y1)):
            for x in range(max(0, x0), min(w, x1)):
                i = (h - 1 - y) * w + x
                if street.gap[i] <= 3.5:
                    continue
                px, py = x + 0.5 - ax, y + 0.5 - ay
                t = px * ux + py * uy
                c = -px * uy + py * ux
                if not (0.0 <= t <= length and abs(c) <= half):
                    continue
                if abs(c) > half - 3:
                    walls.setdefault(y, []).append((x, 14 if int(t) % 24 < 5 else 10, "bridge"))
                    continue
                rgb = _tile(tiles, deck_spec, x, y, 13)
                k = 236 if abs(c) > half - 7 else 256
                if int(t) % 16 == 0:
                    k -= 30
                _put(pic, i, _shade(rgb, k))


def survey_fences(d, sv, street, walls):
    """The battleground's own field fences (the survey's placements of the
    models d["fences"]["models"] name, a section every 12 units or so): each
    section joined to every other within d["fences"]["link"], drawn as the
    timber rail fence (d["rope_fence"]["field"], a post at each section)
    along the joins, outside the street; added to `walls`."""
    spec = d["fences"]
    fence = d["rope_fence"]["field"]
    w, h = street.w, street.h
    names = tuple(spec["models"])
    nodes = [(x, y) for kind, model, x, y, _h, _yaw, _s in sv.placements
             if kind == "doodad" and model.startswith(names) and 0 <= x < w and 0 <= y < h]
    link = spec["link"]
    seen = set()
    for a, (ax, ay) in enumerate(nodes):
        for b, (bx, by) in enumerate(nodes):
            if a >= b or (ax - bx) ** 2 + (ay - by) ** 2 > link * link:
                continue
            length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
            ux, uy = (bx - ax) / length, (by - ay) / length
            for y in range(int(min(ay, by) - 2), int(max(ay, by) + 3)):
                for x in range(int(min(ax, bx) - 2), int(max(ax, bx) + 3)):
                    if not (0 <= x < w and 0 <= y < h) or (x, y) in seen:
                        continue
                    px, py = x + 0.5 - ax, y + 0.5 - ay
                    t = px * ux + py * uy
                    if not (-1.0 <= t <= length + 1.0) or abs(-px * uy + py * ux) > 1.1:
                        continue
                    if street.gap[(h - 1 - y) * w + x] <= 3.0:
                        continue
                    seen.add((x, y))
                    walls.setdefault(y, []).append((x, fence["post_height"], "rope",
                                                    (max(0.0, t) if t < length - fence["post"] else 0.0, fence, True)))


def paint_circuit_finish(pic, street, gate, thickness=12, cells=6):
    """A chequered band across the street along the finish gate."""
    w, h = pic.w, pic.h
    horizontal = gate["ay"] == gate["by"]
    lo = int(min(gate["ax"], gate["bx"])) if horizontal else int(min(gate["ay"], gate["by"]))
    hi = int(max(gate["ax"], gate["bx"])) if horizontal else int(max(gate["ay"], gate["by"]))
    mid = int(gate["ay"] if horizontal else gate["ax"])
    for a in range(lo, hi + 1):
        for b in range(mid - thickness // 2, mid + thickness // 2):
            x, y = (a, b) if horizontal else (b, a)
            if not (0 <= x < w and 0 <= y < h):
                continue
            i = (h - 1 - y) * w + x
            if street.gap[i] > -2:
                continue
            dark = ((a // cells) + ((b - (mid - thickness // 2)) // cells)) % 2
            pic.over(i, *((34, 30, 30) if dark else (226, 222, 210)), 230)


def place_circuit_props(wc3, d, street, cache, log, sv=None):
    """The scenery's models: each keeps its drawn body off the street (a
    `nudge`d one steps away from it until clear); optional ones that cannot
    are left out, any other stops the build. A solid one stands on the street
    (its box blocks the karts: circuit_geometry)."""
    from city_paint import body_clear
    placed, dropped = [], 0
    for item in d["props"]:
        sprite = sprite_for(wc3, d, item, cache)
        forget_textures()
        X, Y = int(round(item["x"])), int(round(item["y"]))
        if item["solid"]:
            placed.append((item, sprite, X, Y))
            continue
        if item.get("optional") and sv is not None and sv.water is not None and \
                water_depth(sv, X, street.h - 1 - Y) > 0:
            dropped += 1
            continue
        if item.get("nudge") and not body_clear(street, sprite, X, Y):
            _, nx, ny = street.nearest(X + 0.5, Y + 0.5)
            for push in range(4, 160, 4):
                QX, QY = int(round(X + nx * push)), int(round(Y + ny * push))
                if body_clear(street, sprite, QX, QY):
                    log(f"  {item['name']} stepped from ({X}, {Y}) to ({QX}, {QY}), off the street")
                    X, Y = QX, QY
                    break
        if not body_clear(street, sprite, X, Y):
            if item.get("optional"):
                dropped += 1
                continue
            raise SystemExit(f"LAYOUT: {item['name']} at ({X}, {Y}) covers the street")
        placed.append((item, sprite, X, Y))
    return placed, dropped


def build_circuit(wc3, d, g, check=False, preview=False, log=print, cache=None):
    from city_paint import Street, paint_scenery
    started = time.time()
    w, h = g["width"], g["height"]
    tiles = Tileset(wc3)
    sv = Survey(Path(__file__).resolve().parent / d["survey"])
    street = Street(g, g["kart"], d["street_reach"], d["street_far"])
    log(f"  street {time.time() - started:.0f}s")
    pic = Picture(w, h)
    light = relief_light(sv, d["relief"])
    paint_ground(pic, d, sv, tiles, light)
    log(f"  ground {time.time() - started:.0f}s")
    wet = paint_circuit_water(pic, d, sv, street, light)
    roads = zone = None
    gaps, skip = {}, frozenset()
    if d.get("survey_roads"):
        roads = survey_road_mask(sv, d["survey_roads"], w, h)
        paint_survey_roads(pic, d, street, tiles, light, sv, roads, wet)
        log(f"  roads {time.time() - started:.0f}s")
    if d.get("cliffs"):
        paint_cliffs(pic, d, sv, street, tiles, wet)
        log(f"  cliffs {time.time() - started:.0f}s")
    if d.get("openings"):
        # The roads off the course, and the bridges off it with 50 units of
        # their road at either end: a bridge's mouth is a road's mouth.
        roads = bytearray(roads) if roads is not None else bytearray(w * h)
        for bridge in d.get("bridges", ()):
            (ax, ay), (bx, by), half = bridge["a"], bridge["b"], bridge["width"] / 2.0
            length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
            ux, uy = (bx - ax) / length, (by - ay) / length
            for y in range(max(0, int(min(ay, by) - 60)), min(h, int(max(ay, by) + 61))):
                for x in range(max(0, int(min(ax, bx) - 60)), min(w, int(max(ax, bx) + 61))):
                    px, py = x + 0.5 - ax, y + 0.5 - ay
                    t = px * ux + py * uy
                    if -50.0 <= t <= length + 50.0 and abs(-px * uy + py * ux) <= half:
                        roads[(h - 1 - y) * w + x] = 1
        gaps = openings(d, street, roads)
        skip = frozenset(i for found in gaps.values() for i in found)
        zone = bytearray(w * h)
        for opening in d["openings"]:
            ax, ay = opening["at"]
            reach = opening["reach"]
            for y in range(max(0, int(ay - reach)), min(h, int(ay + reach) + 1)):
                for x in range(max(0, int(ax - reach)), min(w, int(ax + reach) + 1)):
                    if (x - ax) ** 2 + (y - ay) ** 2 <= reach * reach:
                        zone[(h - 1 - y) * w + x] = 1
    deck = paint_course(pic, d, g, street, sv, tiles, light, roads, zone)
    paint_circuit_finish(pic, street, g["gates"][-1])
    log(f"  course {time.time() - started:.0f}s")
    cache = {} if cache is None else cache
    models, dropped = place_circuit_props(wc3, d, street, cache, log, sv)
    if gaps:
        models += place_blockers(wc3, d, street, gaps, cache, log)
    walls = circuit_walls(d, street, deck, skip)
    paint_off_bridges(pic, d, street, tiles, walls)
    survey_fences(d, sv, street, walls)
    paint_scenery(pic, d, walls, models)
    log(f"  scenery {time.time() - started:.0f}s ({len(models)} models, {dropped} optional left out)")
    preview_rows = pic.rows(4)
    folder = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / d["folder"]
    outputs = [(folder / "Background.tga", pic.tga()), (folder / "Preview.tga", encode_tga(preview_rows))]
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
        (docs / f"{d['id']}-sources.txt").write_text(sources(d, tiles, [(m[0], m[1], m[2], m[3], 0) for m in models]),
                                                    encoding="utf-8", newline="\n")
    return pic


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
    pictures = "Background.tga" if d.get("kind") == "circuit" else "Background.tga and Roofs.tga"
    lines = [f"# {d['name']}: Warcraft III Reforged files used by {d['folder']}/{pictures}",
             "# Generated by scripts/build_battlegrounds.py --preview. Archive paths as the client stores them.",
             "# The ground's layout, relief and the models' places are measured from the World of Warcraft",
             f"# client's own map ({d['survey']}, scripts/wow_map_survey.py): numbers only, no client file.",
             "", "## Models (placements)"]
    lines += [f"{counts[k]:4d}  {k}" for k in sorted(counts)]
    lines += ["", "## Textures"] + sorted(textures)
    return "\n".join(lines) + "\n"
