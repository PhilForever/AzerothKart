"""Build the Scarlet Crusade Cup's dungeon sprints: scenery, preview and geometry data.

python scripts/build_dungeon_tracks.py --wc3 ROOT             # write every output
python scripts/build_dungeon_tracks.py --wc3 ROOT --check     # verify exact bytes, write nothing
python scripts/build_dungeon_tracks.py --wc3 ROOT --preview   # also write review PNGs under docs/art/tracks/
python scripts/build_dungeon_tracks.py --wc3 ROOT --geometry-only

ROOT holds Warcraft III Reforged files extracted from the owner's own install
by scripts/wc3casc.py, as for build_city_tracks.py.

Outputs, per dungeon in dungeon_layouts.DUNGEONS:

- addon/AzerothKart/ScarletCrusade.lua: the dungeon geometry (rooms, gates,
  spawn, solid boxes, lap count, the reviewed route), generated from
  dungeon_layouts.py. Solid boxes of scenery models come from the models'
  own footprints, or from the layout.
- addon/AzerothKart/Assets/Tracks/<Folder>/Background.tga (one texel per
  world unit) and Preview.tga (4x reduced), painted by dungeon_paint.py from
  the same rooms Dungeon.lua collides with.

Standard library only; integer compositing over IEEE-exact model rendering,
so the bytes are reproducible.
"""
import argparse
from math import cos, pi, sin, sqrt
from pathlib import Path

import dungeon_layouts as L
from build_city_tracks import number, prop_box, q
from city_layouts import WALL_INSET, box
from wc3render import forget_textures

ROOT = Path(__file__).resolve().parents[1]
LUA_OUTPUT = ROOT / "addon" / "AzerothKart" / "ScarletCrusade.lua"
HEADINGS = {"north": ("math.pi/2", pi / 2), "south": ("-math.pi/2", -pi / 2),
            "east": ("0", 0.0), "west": ("math.pi", pi)}
CHECKPOINT_MAX_STEP = 5
# The picture's walls stand at the inset from the karts' floor; this much
# more is allowed (a doorway's corner, a round wall's rounding).
WALL_SLACK = 3


# ---------------------------------------------------------------------------
# Geometry.


def geometry(wc3, d):
    """The runtime definition of one dungeon (plain Python values)."""
    width, height = d["size"]
    solids = []
    for item in d["props"]:
        solid = item["solid"]
        if not solid:
            continue
        if solid is True:
            found = prop_box(wc3, d, item)
            forget_textures()             # one model's decoded textures at a time
        else:
            x0, y0, x1, y1 = solid
            found = box(item["name"], int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1)))
        solids.append(found)
    seen = {}
    for s in solids:         # unique ids: a repeated model gets a numbered suffix
        seen[s["id"]] = seen.get(s["id"], 0) + 1
        if seen[s["id"]] > 1:
            s["id"] = "%s_%d" % (s["id"], seen[s["id"]])
    sx, sy, heading = d["spawn"]
    return {"id": d["id"], "name": d["name"], "version": d.get("version", 1), "width": width, "height": height,
            "wallInset": WALL_INSET, "laps": d["laps"],
            "rooms": [dict(r) for r in d["rooms"]], "gates": [dict(g) for g in d["gates"]],
            "solids": solids, "spawn": (sx, sy, heading), "route": list(d["route"])}


class Floor:
    """The kart centre's floor of a definition, as Dungeon.lua tests it: each
    room inset on every side, a round room (`shape` "disc") to its radius
    less the inset."""

    def __init__(self, g):
        self.g = g
        inset = g["wallInset"]
        self.rooms = []
        for r in g["rooms"]:
            box = (r["x0"] + inset, r["y0"] + inset, r["x1"] - inset, r["y1"] - inset)
            if r.get("shape") == "disc":
                reach = (r["x1"] - r["x0"]) / 2 - inset
                self.rooms.append(box + (((r["x0"] + r["x1"]) / 2, (r["y0"] + r["y1"]) / 2, reach),))
            else:
                self.rooms.append(box + (None,))
        self.solids = [(s["x"] - inset, s["y"] - inset, s["x"] + s["width"] + inset, s["y"] + s["height"] + inset)
                       for s in g["solids"]]

    @staticmethod
    def _in(room, x, y):
        x0, y0, x1, y1, disc = room
        if not (x0 <= x <= x1 and y0 <= y <= y1):
            return False
        if disc is None:
            return True
        cx, cy, reach = disc
        dx, dy = x - cx, y - cy
        return dx * dx + dy * dy <= reach * reach

    def on_floor(self, x, y):
        return any(self._in(room, x, y) for room in self.rooms)

    def allowed(self, x, y):
        inset = self.g["wallInset"]
        if not (inset <= x <= self.g["width"] - inset and inset <= y <= self.g["height"] - inset):
            return False
        return self.on_floor(x, y) and not any(x0 < x < x1 and y0 < y < y1 for x0, y0, x1, y1 in self.solids)

    def road(self, x, y):
        for r in self.g["rooms"]:
            if r["surface"] != "road" or not (r["x0"] <= x <= r["x1"] and r["y0"] <= y <= r["y1"]):
                continue
            if r.get("shape") != "disc":
                return True
            radius = (r["x1"] - r["x0"]) / 2
            dx, dy = x - (r["x0"] + r["x1"]) / 2, y - (r["y0"] + r["y1"]) / 2
            if dx * dx + dy * dy <= radius * radius:
                return True
        return False


def floor_gap(a, b):
    """The distance between two rooms' kart floors (0 when they meet)."""
    if a[4] is None and b[4] is None:
        dx = max(a[0] - b[2], b[0] - a[2], 0.0)
        dy = max(a[1] - b[3], b[1] - a[3], 0.0)
        return sqrt(dx * dx + dy * dy)
    if a[4] is None:
        a, b = b, a
    cx, cy, reach = a[4]
    if b[4] is not None:                       # two round rooms
        bx, by, other = b[4]
        return max(0.0, sqrt((cx - bx) ** 2 + (cy - by) ** 2) - reach - other)
    dx = max(b[0] - cx, cx - b[2], 0.0)        # a round room and a rectangle
    dy = max(b[1] - cy, cy - b[3], 0.0)
    return max(0.0, sqrt(dx * dx + dy * dy) - reach)


def painted_floor(g):
    """The floor the picture paints, one byte per world unit (row y at
    y * width): each room's texels (a round room's whose centres lie in its
    disc), as dungeon_paint.py lays them. Everywhere else is masonry."""
    w, h = g["width"], g["height"]
    mask = bytearray(w * h)
    for r in g["rooms"]:
        x0, x1 = int(r["x0"]), int(r["x1"])
        if r.get("shape") == "disc":
            cx, cy, radius = (r["x0"] + r["x1"]) / 2, (r["y0"] + r["y1"]) / 2, (r["x1"] - r["x0"]) / 2
            for y in range(int(r["y0"]), int(r["y1"])):
                for x in range(x0, x1):
                    if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= radius * radius:
                        mask[y * w + x] = 1
            continue
        for y in range(int(r["y0"]), int(r["y1"])):
            mask[y * w + x0:y * w + x1] = b"\x01" * (x1 - x0)
    return mask


def hidden_walls(g, slack=WALL_SLACK):
    """Where the karts' floor ends with no wall painted beside it: an
    invisible wall. Along every edge of the kart centre's floor (a room's,
    where no other room's floor runs on), the picture's masonry must lie
    within the inset (and `slack`, for corners and rounding), measured
    square, as the kart's clearance is. Returns the offending points."""
    w, h, inset = g["width"], g["height"], g["wallInset"]
    mask = painted_floor(g)
    floor = Floor(g)
    reach = int(inset + slack)
    bad = []

    def masonry_near(px, py):
        x0, x1 = px - reach, px + reach + 1
        if x0 < 0 or x1 > w or py - reach < 0 or py + reach + 1 > h:
            return True                     # the world's edge is masonry
        return any(0 in mask[y * w + x0:y * w + x1] for y in range(py - reach, py + reach + 1))

    def edge(px, py, nx, ny):
        if floor.on_floor(px + nx * 0.5, py + ny * 0.5):
            return                          # another room's floor runs on: a doorway
        if not masonry_near(int(round(px)), int(round(py))):
            bad.append((int(round(px)), int(round(py))))

    for x0, y0, x1, y1, disc in floor.rooms:
        if disc is None:
            for x in range(int(x0), int(x1) + 1):
                edge(x, y1, 0, 1)
                edge(x, y0, 0, -1)
            for y in range(int(y0), int(y1) + 1):
                edge(x1, y, 1, 0)
                edge(x0, y, -1, 0)
        else:
            cx, cy, radius = disc
            n = int(2 * pi * radius)
            for k in range(n):
                c, s = cos(2 * pi * k / n), sin(2 * pi * k / n)
                edge(cx + radius * c, cy + radius * s, c, s)
    return bad


def reachable(floor, start, barrier=None, step=2):
    """Grid cells (step units) of the kart centre's floor reachable from
    `start`, optionally never crossing the `barrier` gate."""
    g = floor.g
    cols, rows = g["width"] // step, g["height"] // step

    def blocked(i, j):
        x, y = i * step + step / 2, j * step + step / 2
        if barrier is not None:
            ax, ay, bx, by = barrier["ax"], barrier["ay"], barrier["bx"], barrier["by"]
            if ax == bx and abs(x - ax) <= step and min(ay, by) <= y <= max(ay, by):
                return True
            if ay == by and abs(y - ay) <= step and min(ax, bx) <= x <= max(ax, bx):
                return True
        return not floor.allowed(x, y)

    seen = bytearray(cols * rows)
    i0, j0 = int(start[0] // step), int(start[1] // step)
    assert not blocked(i0, j0), "flood start is off the floor"
    stack = [(i0, j0)]
    seen[j0 * cols + i0] = 1
    while stack:
        i, j = stack.pop()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ni, nj = i + di, j + dj
            if 0 <= ni < cols and 0 <= nj < rows and not seen[nj * cols + ni] and not blocked(ni, nj):
                seen[nj * cols + ni] = 1
                stack.append((ni, nj))
    return lambda x, y: bool(seen[int(y // step) * cols + int(x // step)])


def validate_geometry(g):
    """Authoring rules: rooms inside the world; the spawn on stone floor;
    separate rooms far enough apart that no step jumps a wall; no invisible
    wall (wherever the karts' floor ends, the picture paints a wall beside
    it); every gate axis-aligned across one doorway, which the karts cannot
    pass round; the route clear from the spawn through every gate; solids
    inside the floor."""
    width, height, inset = g["width"], g["height"], g["wallInset"]
    floor = Floor(g)
    for r in g["rooms"]:
        assert 0 <= r["x0"] < r["x1"] <= width and 0 <= r["y0"] < r["y1"] <= height, f"room {r['name']} leaves the world"
        assert r["surface"] in ("road", "rough"), r["name"]
        assert r.get("shape", "rect") in ("rect", "disc"), r["name"]
        assert r.get("shape") != "disc" or r["x1"] - r["x0"] == r["y1"] - r["y0"], f"round room {r['name']} is square"
    # Rooms that abut without a doorway look like one floor but stop the
    # karts between them: paint a wall there, or run the floor on.
    hidden = hidden_walls(g)
    assert not hidden, "invisible wall: the karts' floor ends with no wall painted beside it at %s" % (
        ", ".join("(%d, %d)" % p for p in hidden[::max(1, len(hidden) // 8)][:8]))
    # No tunnelling: the kart floors of rooms that do not meet stay apart.
    for a, ra in zip(floor.rooms, g["rooms"]):
        for b, rb in zip(floor.rooms, g["rooms"]):
            if ra is rb:
                continue
            gap = floor_gap(a, b)
            if gap > 0:
                assert gap >= 2 * CHECKPOINT_MAX_STEP, \
                    f"rooms {ra['name']} and {rb['name']} are too close to keep a wall between them"
    sx, sy, heading = g["spawn"]
    assert heading in HEADINGS, "spawn heading is a compass word"
    assert floor.allowed(sx, sy) and floor.road(sx, sy), "spawn stands on stone floor, clear of solids"
    for s in g["solids"]:
        assert s["width"] > 0 and s["height"] > 0, f"solid {s['id']} is empty"
        cx, cy = s["x"] + s["width"] / 2, s["y"] + s["height"] / 2
        assert floor.on_floor(cx, cy), f"solid {s['id']} stands off the floor"
    # The route: clear of walls and solids, from the spawn through every gate.
    route = g["route"]
    assert route[0] == (sx, sy), "the route starts at the spawn"
    crossed = []
    for (ax, ay), (bx, by) in zip(route, route[1:]):
        n = max(1, int(sqrt((bx - ax) ** 2 + (by - ay) ** 2) / 2))
        for k in range(n + 1):
            x, y = ax + (bx - ax) * k / n, ay + (by - ay) * k / n
            assert floor.allowed(x, y), f"route point ({x:.0f}, {y:.0f}) meets a wall or a solid"
        for index, gt in enumerate(g["gates"]):
            before = (ax - gt["ax"]) * gt["nx"] + (ay - gt["ay"]) * gt["ny"]
            after = (bx - gt["ax"]) * gt["nx"] + (by - gt["ay"]) * gt["ny"]
            if before < 0 <= after:
                # Across the gate's own segment, as Track.crossesGate counts it.
                t = before / (before - after)
                ix, iy = ax + (bx - ax) * t, ay + (by - ay) * t
                if min(gt["ax"], gt["bx"]) <= ix <= max(gt["ax"], gt["bx"]) \
                        and min(gt["ay"], gt["by"]) <= iy <= max(gt["ay"], gt["by"]):
                    crossed.append(index)
    assert crossed == list(range(len(g["gates"]))), f"the route crosses the gates in order, once each: {crossed}"
    # Every gate: axis-aligned, its ends in the walls, unavoidable.
    free = reachable(floor, (sx, sy))
    for gt in g["gates"]:
        assert gt["ax"] == gt["bx"] or gt["ay"] == gt["by"], f"gate {gt['name']} is not axis-aligned"
        assert (gt["nx"], gt["ny"]) in ((1, 0), (-1, 0), (0, 1), (0, -1)), f"gate {gt['name']} normal"
        assert (gt["bx"] - gt["ax"]) * gt["nx"] + (gt["by"] - gt["ay"]) * gt["ny"] == 0
        dx, dy = (gt["bx"] - gt["ax"]), (gt["by"] - gt["ay"])
        length = sqrt(dx * dx + dy * dy)
        ux, uy = dx / length, dy / length
        for (px, py), sign in (((gt["ax"], gt["ay"]), -1), ((gt["bx"], gt["by"]), 1)):
            for k in range(1, 40):
                assert not floor.on_floor(px + ux * sign * k, py + uy * sign * k), \
                    f"gate {gt['name']} does not reach the wall"
        # Just past the gate, all along it (a solid may stand on the line, as
        # Herod does on the Armory's finish): reachable, but not round it.
        beyond = [(gt["ax"] + ux * k + gt["nx"] * 12, gt["ay"] + uy * k + gt["ny"] * 12)
                  for k in range(2, int(length) - 1, 4)]
        assert any(free(x, y) for x, y in beyond), f"past gate {gt['name']} cannot be reached"
        around = reachable(floor, (sx, sy), barrier=gt)
        assert not any(around(x, y) for x, y in beyond), f"gate {gt['name']} can be passed round"
    return True


# ---------------------------------------------------------------------------
# The Lua data file.


def lua_data(dungeons):
    lines = [
        "-- Scarlet Crusade Cup dungeon geometry. GENERATED by scripts/build_dungeon_tracks.py",
        "-- from scripts/dungeon_layouts.py; edit the layouts there, not this file.",
        "-- Pure data: Dungeon.new builds each course from its entry.",
        "local _, namespace = ...",
        "local ScarletCrusade = {}",
        "",
    ]
    for g in dungeons:
        sx, sy, heading = g["spawn"]
        lines.append("ScarletCrusade[%s] = {" % q(g["id"]))
        lines.append("    id=%s, version=%d, name=%s, laps=%d," % (q(g["id"]), g["version"], q(g["name"]), g["laps"]))
        lines.append("    width=%d, height=%d, wallInset=%d, checkpointMaxStep=%d," % (
            g["width"], g["height"], g["wallInset"], CHECKPOINT_MAX_STEP))
        lines.append("    spawn={x=%s, y=%s, heading=%s}," % (number(sx), number(sy), HEADINGS[heading][0]))
        lines.append("    rooms={")
        for r in g["rooms"]:
            shape = ", shape=%s" % q(r["shape"]) if r.get("shape", "rect") != "rect" else ""
            lines.append("        {x=%d, y=%d, width=%d, height=%d, surface=%s%s}, -- %s" % (
                r["x0"], r["y0"], r["x1"] - r["x0"], r["y1"] - r["y0"], q(r["surface"]), shape, r["name"]))
        lines.append("    },")
        lines.append("    gates={")
        for gt in g["gates"]:
            lines.append("        {name=%s, ax=%s, ay=%s, bx=%s, by=%s, nx=%d, ny=%d}," % (
                q(gt["name"]), number(gt["ax"]), number(gt["ay"]), number(gt["bx"]), number(gt["by"]),
                gt["nx"], gt["ny"]))
        lines.append("    },")
        lines.append("    solids={")
        for s in g["solids"]:
            lines.append("        {id=%s, x=%d, y=%d, width=%d, height=%d}," % (
                q(s["id"]), s["x"], s["y"], s["width"], s["height"]))
        lines.append("    },")
        # The reviewed way through the gates (kart centre); tests walk it.
        lines.append("    route={")
        row = []
        for x, y in g["route"]:
            row.append("{x=%s,y=%s}," % (number(x), number(y)))
            if len(row) == 6:
                lines.append("        " + " ".join(row))
                row = []
        if row:
            lines.append("        " + " ".join(row))
        lines.append("    },")
        lines.append("}")
        lines.append("")
    lines.append("if type(namespace) == \"table\" then namespace.ScarletCrusade = ScarletCrusade end")
    lines.append("return ScarletCrusade")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Command line.


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--wc3", type=Path, required=True, help="folder of extracted Warcraft III files")
    parser.add_argument("--check", action="store_true", help="verify outputs without writing")
    parser.add_argument("--preview", action="store_true", help="also write review PNGs")
    parser.add_argument("--dungeon", help="paint only this dungeon id (geometry is always complete)")
    parser.add_argument("--geometry-only", action="store_true", help="only the Lua dungeon data")
    args = parser.parse_args()
    dungeons = [geometry(args.wc3, d) for d in L.DUNGEONS]
    for g in dungeons:
        validate_geometry(g)
    text = lua_data(dungeons)
    relative = LUA_OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not LUA_OUTPUT.is_file() or LUA_OUTPUT.read_text(encoding="utf-8") != text:
            raise SystemExit(f"STALE: {relative}; run without --check")
        print(f"CHECK PASS: {relative}")
    else:
        LUA_OUTPUT.write_text(text, encoding="utf-8", newline="\n")
        print(f"WROTE: {relative}")
    if args.geometry_only:
        return
    import dungeon_paint
    for d, g in zip(L.DUNGEONS, dungeons):
        if args.dungeon and d["id"] != args.dungeon:
            continue
        dungeon_paint.build(args.wc3, d, g, check=args.check, preview=args.preview)


if __name__ == "__main__":
    main()
