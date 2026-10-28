"""Build the Battlegrounds Cup's two-floor courses: geometry data, scenery and roofs.

python scripts/build_battlegrounds.py --wc3 ROOT             # write every output
python scripts/build_battlegrounds.py --wc3 ROOT --check     # verify exact bytes, write nothing
python scripts/build_battlegrounds.py --wc3 ROOT --preview   # also write review PNGs under docs/art/tracks/
python scripts/build_battlegrounds.py --wc3 ROOT --geometry-only                     # only the Lua data
python scripts/build_battlegrounds.py --wc3 ROOT --geometry-only --schematic OUT.png  # a floor plan to review

ROOT holds Warcraft III Reforged files extracted from the owner's own install
by scripts/wc3casc.py, as for build_city_tracks.py.

Outputs, per course in battleground_layouts.BATTLEGROUNDS:

- addon/AzerothKart/Battlegrounds.lua: the two-floor geometry (rooms with
  their floor, ramps, gates, Boots pads, spawn, solids, lap count, the roof
  overlays and the reviewed route), generated from battleground_layouts.py
  for LayeredTrack.new (docs/LAYERED_TRACKS.md).
- addon/AzerothKart/Assets/Tracks/<Folder>/Background.tga, Preview.tga and
  Roofs.tga: the ground as floor 0 sees it, and the roof overlays over it,
  painted by battleground_paint.py from the same rooms.

validate() checks LayeredTrack's authoring rules before LayeredTrack.new
does at load, plus the dungeon rules (no invisible wall on either floor,
rooms that do not meet stay apart, gates from wall to wall) and walks the
reviewed route across the floors, through the gates in order.

Standard library only for the outputs; --schematic uses Pillow.
"""
import argparse
from math import sqrt
from pathlib import Path

import battleground_layouts as L
from build_city_tracks import number, prop_box, q
from build_dungeon_tracks import CHECKPOINT_MAX_STEP, HEADINGS, Floor, blocking, floor_gap, hidden_walls
from city_layouts import WALL_INSET
from wc3render import forget_textures

ROOT = Path(__file__).resolve().parents[1]
LUA_OUTPUT = ROOT / "addon" / "AzerothKart" / "Battlegrounds.lua"
MAX_STEP = 16          # LayeredTrack.MAX_STEP: the longest movement request
EPS = 1e-7
# Beyond each end of a gate, this far is wall on its floor: the karts cannot
# pass round the end.
GATE_WALL = WALL_INSET + 2


# ---------------------------------------------------------------------------
# Geometry.


def geometry(d, wc3=None, cache=None):
    """The runtime definition of one course (plain Python values). Solid
    scenery blocks where the picture draws it (build_dungeon_tracks.blocking:
    a hut's round, a tree's crown), on its layer's floor: the ground's
    props on floor 0, the roofs' on floor 1. `cache` keeps the sprites for
    the painter. With mid's stumps, the finish line (the last gate) runs
    from the field's wall (its `ax`) to the stumps, across their middle."""
    width, height = d["size"]
    sx, sy, heading, level = d["spawn"]
    cache = {} if cache is None else cache
    solids = [dict(s) for s in d["solids"]]
    for floor, items in ((0, d.get("props", ())), (1, d.get("roof_props", ()))):
        for item in items:
            if not item["solid"]:
                continue
            if wc3 is None:
                raise SystemExit("--wc3 is required: solid scenery blocks where it is drawn")
            found = prop_box(wc3, d, item)
            forget_textures()
            if item.get("blocks"):
                found = blocking(wc3, d, item, found, cache)
            found["level"] = floor
            solids.append(found)
    seen = {}
    for s in solids:         # unique ids: a repeated model gets a numbered suffix
        seen[s["id"]] = seen.get(s["id"], 0) + 1
        if seen[s["id"]] > 1:
            s["id"] = "%s_%d" % (s["id"], seen[s["id"]])
    gates = [dict(g) for g in d["gates"]]
    mid = next((s for s in solids if s["id"] == "mid_stumps"), None)
    if mid is not None:
        finish = gates[-1]
        cy = mid["y"] + mid["height"] // 2
        finish["ay"] = finish["by"] = cy
        east = finish["ax"] > mid["x"] + mid["width"]
        finish["bx"] = mid["x"] + mid["width"] if east else mid["x"]
    return {"id": d["id"], "name": d["name"], "version": d["version"], "width": width, "height": height,
            "wallInset": WALL_INSET, "laps": d["laps"],
            "rooms": [dict(r) for r in d["rooms"]], "ramps": [dict(r) for r in d["ramps"]],
            "gates": gates, "pads": [dict(p) for p in d["pads"]],
            "solids": solids, "overlays": [dict(o) for o in d["overlays"]],
            "spawn": (sx, sy, heading, level), "route": list(d["route"])}


def corridor(r, inset=WALL_INSET):
    """A ramp's usable corridor (kart centres): its whole length, less the
    inset at either side."""
    if r["axis"] == "x":
        return (r["x0"], r["y0"] + inset, r["x1"], r["y1"] - inset)
    return (r["x0"] + inset, r["y0"], r["x1"] - inset, r["y1"])


def interior(r, inset=WALL_INSET):
    """A ramp's reserved interior: all of it but twice the inset at either
    end, where no room of either floor may lie."""
    if r["axis"] == "x":
        return (r["x0"] + 2 * inset, r["y0"], r["x1"] - 2 * inset, r["y1"])
    return (r["x0"], r["y0"] + 2 * inset, r["x1"], r["y1"] - 2 * inset)


def ramp_room(r, inset=WALL_INSET):
    """The room LayeredTrack adds to both floors for a ramp: its footprint
    run on by the inset at either end, so its floor reaches the end planes."""
    x0, y0, x1, y1 = r["x0"], r["y0"], r["x1"], r["y1"]
    if r["axis"] == "x":
        x0, x1 = x0 - inset, x1 + inset
    else:
        y0, y1 = y0 - inset, y1 + inset
    return {"name": r["name"], "x0": x0, "y0": y0, "x1": x1, "y1": y1, "surface": "road", "ramp": r["id"]}


def ends(r):
    """((x, y, floor), (x, y, floor)): the middle of a ramp's low and high
    end planes."""
    cx0, cy0, cx1, cy1 = corridor(r)
    if r["axis"] == "x":
        mid = (cy0 + cy1) / 2
        low, high = (cx0, cx1) if r["ascending"] == 1 else (cx1, cx0)
        return (low, mid, 0), (high, mid, 1)
    mid = (cx0 + cx1) / 2
    low, high = (cy0, cy1) if r["ascending"] == 1 else (cy1, cy0)
    return (mid, low, 0), (mid, high, 1)


def overlaps(a, b):
    """Two (x0, y0, x1, y1) boxes share area (touching is not overlapping)."""
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def rect_gap(a, b):
    dx = max(a[0] - b[2], b[0] - a[2], 0.0)
    dy = max(a[1] - b[3], b[1] - a[3], 0.0)
    return sqrt(dx * dx + dy * dy)


def inside(box, x, y):
    return box[0] <= x <= box[2] and box[1] <= y <= box[3]


def floor_definition(g, level):
    """One floor as a Dungeon definition (for Floor and hidden_walls): its
    rooms, its solids and every ramp's room, as LayeredTrack builds it."""
    rooms = [r for r in g["rooms"] if r["level"] == level] + [ramp_room(r) for r in g["ramps"]]
    solids = [s for s in g["solids"] if s.get("level", 0) == level]
    return {"width": g["width"], "height": g["height"], "wallInset": g["wallInset"],
            "rooms": rooms, "solids": solids}


# ---------------------------------------------------------------------------
# A kart centre's way across the floors: LayeredTrack's ramp rules.


class Floors:
    def __init__(self, g):
        self.g = g
        self.floor = {level: Floor(floor_definition(g, level)) for level in (0, 1)}
        self.corridors = [(r, corridor(r)) for r in g["ramps"]]

    def ramp_at(self, x, y):
        for r, box in self.corridors:
            if inside(box, x, y):
                return r, box
        return None, None

    def clear(self, level, x, y):
        return self.floor[level].allowed(x, y)

    def step(self, x, y, tx, ty, level):
        """The floor after moving (x, y) to (tx, ty) on `level`, as
        LayeredTrack.resolveMovement decides it, or a reason the move is
        refused (a wall, a ramp's side, its wrong end)."""
        r, box = self.ramp_at(x, y)
        if r is not None:
            # On the ramp: its sides are walls; leaving by an end sets the floor.
            if r["axis"] == "x":
                if not box[1] <= ty <= box[3]:
                    return None, "the side of %s" % r["name"]
                q0, q1, tq = box[0], box[2], tx
            else:
                if not box[0] <= tx <= box[2]:
                    return None, "the side of %s" % r["name"]
                q0, q1, tq = box[1], box[3], ty
            if q0 <= tq <= q1:
                return level, None
            high_end_max = r["ascending"] == 1
            to = 1 if (tq > q1) == high_end_max else 0
            if not self.clear(to, tx, ty):
                return None, "a wall beyond %s" % r["name"]
            return to, None
        for r, box in self.corridors:
            hit = entry(box, x, y, tx - x, ty - y)
            if hit is None:
                continue
            t, axis = hit
            if axis != r["axis"]:
                return None, "the side of %s" % r["name"]
            ex, ey = x + (tx - x) * t, y + (ty - y) * t
            q, q1 = (ex, box[2]) if r["axis"] == "x" else (ey, box[3])
            at_high = (abs(q - q1) < EPS) == (r["ascending"] == 1)
            if (1 if at_high else 0) != level:
                return None, "the wrong end of %s" % r["name"]
            return level, None
        if not self.clear(level, tx, ty):
            return None, "a wall on floor %d" % level
        return level, None


def entry(box, x, y, dx, dy):
    """LayeredTrack's entry(): (fraction, axis) of the first entry into a
    ramp corridor from outside it, or None."""
    tx0, tx1, ty0, ty1 = float("-inf"), float("inf"), float("-inf"), float("inf")
    if dx == 0:
        if x < box[0] or x > box[2]:
            return None
    elif dx > 0:
        tx0, tx1 = (box[0] - x) / dx, (box[2] - x) / dx
    else:
        tx0, tx1 = (box[2] - x) / dx, (box[0] - x) / dx
    if dy == 0:
        if y < box[1] or y > box[3]:
            return None
    elif dy > 0:
        ty0, ty1 = (box[1] - y) / dy, (box[3] - y) / dy
    else:
        ty0, ty1 = (box[3] - y) / dy, (box[1] - y) / dy
    near, far = max(tx0, ty0), min(tx1, ty1)
    if near < 0 or near > 1 or far <= near:
        return None
    return near, "x" if tx0 >= ty0 else "y"


def crosses(gt, ax, ay, bx, by):
    """Track.crossesGate: from behind the gate to on or past it, across its
    own segment."""
    before = (ax - gt["ax"]) * gt["nx"] + (ay - gt["ay"]) * gt["ny"]
    after = (bx - gt["ax"]) * gt["nx"] + (by - gt["ay"]) * gt["ny"]
    if not (before < 0 <= after):
        return False
    t = before / (before - after)
    ix, iy = ax + (bx - ax) * t, ay + (by - ay) * t
    return (min(gt["ax"], gt["bx"]) <= ix <= max(gt["ax"], gt["bx"])
            and min(gt["ay"], gt["by"]) <= iy <= max(gt["ay"], gt["by"]))


def walk(g, route, level, step=4.0):
    """Drive the route's kart centre in steps no longer than `step`: returns
    the gates passed in lap order (as Checkpoints counts them: the next gate
    only, both poses on its floor), the floors visited, the ramps used and,
    for each gate passed, the index of the route point the kart was driving
    to when it crossed (the guiding arrow's way to each gate)."""
    floors = Floors(g)
    passed, levels, ramps_used, crossings = [], [level], [], []
    nxt = 0
    (x, y) = route[0]
    for index, (bx, by) in enumerate(route[1:], 1):
        n = max(1, int(sqrt((bx - x) ** 2 + (by - y) ** 2) / step) + 1)
        ax, ay = x, y
        for k in range(1, n + 1):
            tx, ty = ax + (bx - ax) * k / n, ay + (by - ay) * k / n
            new, why = floors.step(x, y, tx, ty, level)
            assert why is None, "route (%.0f, %.0f) to (%.0f, %.0f) on floor %d meets %s" % (x, y, tx, ty, level, why)
            r, _ = floors.ramp_at(tx, ty)
            if r is not None and (not ramps_used or ramps_used[-1] != r["id"]):
                ramps_used.append(r["id"])
            if nxt < len(g["gates"]):
                gt = g["gates"][nxt]
                if level == new == gt["level"] and crosses(gt, x, y, tx, ty):
                    passed.append(gt["name"])
                    crossings.append(index)
                    nxt += 1
            if new != level:
                levels.append(new)
            x, y, level = tx, ty, new
    return passed, levels, ramps_used, crossings


# ---------------------------------------------------------------------------
# Validation.


def validate(g):
    """LayeredTrack's authoring rules (docs/LAYERED_TRACKS.md) and the
    dungeon rules, on both floors; then the reviewed route."""
    width, height, inset = g["width"], g["height"], g["wallInset"]
    names = set()
    for r in g["rooms"]:
        assert r["name"] not in names, "room names are unique: " + r["name"]
        names.add(r["name"])
        assert 0 <= r["x0"] < r["x1"] <= width and 0 <= r["y0"] < r["y1"] <= height, f"room {r['name']} leaves the world"
        assert r["level"] in (0, 1) and r["surface"] == "road", r["name"]
    for level in (0, 1):
        assert any(r["level"] == level for r in g["rooms"]), "each floor needs a room"

    # Ramps: size, the reserved interior, the gaps between them, their ends.
    floors = Floors(g)
    ids = set()
    for r in g["ramps"]:
        assert r["id"] not in ids, "ramp ids are unique"
        ids.add(r["id"])
        w, h = r["x1"] - r["x0"], r["y1"] - r["y0"]
        assert w > 2 * inset and h > 2 * inset, f"ramp {r['id']} is wider than two insets"
        length = w if r["axis"] == "x" else h
        assert length >= 2 * MAX_STEP and length > 4 * inset, f"ramp {r['id']} is too short"
        core = interior(r)
        for room in g["rooms"]:
            assert not overlaps(core, (room["x0"], room["y0"], room["x1"], room["y1"])), \
                f"room {room['name']} lies in ramp {r['id']}'s interior"
        box = corridor(r)
        for s in g["solids"]:
            grown = (s["x"] - inset, s["y"] - inset, s["x"] + s["width"] + inset, s["y"] + s["height"] + inset)
            assert not overlaps(grown, box), f"solid {s['id']} blocks ramp {r['id']}"
        for other in g["ramps"]:
            if other is not r:
                assert rect_gap(box, corridor(other)) > MAX_STEP + EPS, f"ramps {r['id']} and {other['id']} are too close"
        (lx, ly, _), (hx, hy, _) = ends(r)
        out = 0.01
        if r["axis"] == "x":
            lx, hx = lx - r["ascending"] * out, hx + r["ascending"] * out
        else:
            ly, hy = ly - r["ascending"] * out, hy + r["ascending"] * out
        assert floors.clear(0, lx, ly), f"ramp {r['id']}'s low end meets no floor 0"
        assert floors.clear(1, hx, hy), f"ramp {r['id']}'s high end meets no floor 1"
        # A floor meets a ramp only at that floor's own end, from beyond it,
        # or keeps a wall's width away: a kart then reaches the ramp only
        # across that end (LayeredTrack's entry rule). A room of the other
        # floor touching the end would put a kart on the ramp with no entry;
        # a room running past the end plane beside the ramp, a lip of side
        # wall standing out into it.
        for room in g["rooms"]:
            core = (room["x0"] + inset, room["y0"] + inset, room["x1"] - inset, room["y1"] - inset)
            gap = rect_gap(core, box)
            if gap >= 2 * CHECKPOINT_MAX_STEP:
                continue
            assert gap == 0, f"room {room['name']} stands a step from ramp {r['id']}"
            i = 0 if r["axis"] == "x" else 1
            low_at_min = r["ascending"] == 1
            at_min = low_at_min if room["level"] == 0 else not low_at_min
            if at_min:
                assert core[i + 2] <= box[i], f"room {room['name']} meets ramp {r['id']} off its floor's end"
            else:
                assert core[i] >= box[i + 2], f"room {room['name']} meets ramp {r['id']} off its floor's end"

    # Each floor: no invisible wall, rooms that do not meet stay apart.
    for level in (0, 1):
        fd = floor_definition(g, level)
        hidden = hidden_walls(fd)
        assert not hidden, "invisible wall on floor %d at %s" % (
            level, ", ".join("(%d, %d)" % p for p in hidden[::max(1, len(hidden) // 8)][:8]))
        floor = floors.floor[level]
        for a, ra in zip(floor.rooms, fd["rooms"]):
            for b, rb in zip(floor.rooms, fd["rooms"]):
                if ra is not rb:
                    gap = floor_gap(a, b)
                    assert gap == 0 or gap >= 2 * CHECKPOINT_MAX_STEP, \
                        f"floor {level}: {ra['name']} and {rb['name']} are too close to keep a wall between them"

    # The spawn: on stone on its floor, outside every ramp.
    sx, sy, heading, level = g["spawn"]
    assert heading in HEADINGS and level in (0, 1)
    assert floors.clear(level, sx, sy), "the spawn stands on its floor"
    assert floors.ramp_at(sx, sy)[0] is None, "the spawn stands off the ramps"

    # Solids: on their floor (the middle of the box, or of one of its sides:
    # a banner drawn over the wall behind it).
    for s in g["solids"]:
        cx, cy = s["x"] + s["width"] / 2, s["y"] + s["height"] / 2
        probes = ((cx, cy), (s["x"], cy), (s["x"] + s["width"], cy), (cx, s["y"]), (cx, s["y"] + s["height"]))
        assert any(floors.floor[s.get("level", 0)].on_floor(px, py) for px, py in probes), \
            f"solid {s['id']} stands off its floor"

    # Gates: axis-aligned, from wall to wall on their floor, clear of ramps.
    for gt in g["gates"]:
        assert gt["level"] in (0, 1)
        assert gt["ax"] == gt["bx"] or gt["ay"] == gt["by"], f"gate {gt['name']} is not axis-aligned"
        assert (gt["nx"], gt["ny"]) in (L.NORTH, L.SOUTH, L.EAST, L.WEST), f"gate {gt['name']} normal"
        assert (gt["bx"] - gt["ax"]) * gt["nx"] + (gt["by"] - gt["ay"]) * gt["ny"] == 0
        cx, cy = (gt["ax"] + gt["bx"]) / 2, (gt["ay"] + gt["by"]) / 2
        assert floors.clear(gt["level"], cx, cy), f"gate {gt['name']}'s centre is on its floor"
        m = CHECKPOINT_MAX_STEP
        box = (min(gt["ax"], gt["bx"]) - m, min(gt["ay"], gt["by"]) - m,
               max(gt["ax"], gt["bx"]) + m, max(gt["ay"], gt["by"]) + m)
        for r in g["ramps"]:
            assert not overlaps(box, corridor(r)), f"gate {gt['name']} lies within a step of ramp {r['id']}"
        dx, dy = gt["bx"] - gt["ax"], gt["by"] - gt["ay"]
        length = sqrt(dx * dx + dy * dy)
        ux, uy = dx / length, dy / length
        floor = floors.floor[gt["level"]]
        for (px, py), sign in (((gt["ax"], gt["ay"]), -1), ((gt["bx"], gt["by"]), 1)):
            for k in range(1, GATE_WALL + 1):
                assert not floor.allowed(px + ux * sign * k, py + uy * sign * k), \
                    f"gate {gt['name']} does not reach the wall"
        # Its own floor runs either side of it.
        for side in (-12, 12):
            assert floor.allowed(cx + gt["nx"] * side, cy + gt["ny"] * side), f"gate {gt['name']} lies in a wall"

    # Boots pads: Physics.ValidatePads' definitions; on their floor, clear of ramps.
    pids = set()
    for p in g["pads"]:
        assert p["id"] not in pids and 1 <= len(p["id"]) <= 32
        assert all(c.isalnum() or c in "_-" for c in p["id"]), p["id"]
        pids.add(p["id"])
        assert 1 <= p["radius"] <= 256 and 1 <= p["boostTicks"] <= 600 and p["level"] in (0, 1)
        assert floors.clear(p["level"], p["x"], p["y"]), f"pad {p['id']} is on its floor"
        for r in g["ramps"]:
            box = corridor(r)
            dx = max(box[0] - p["x"], 0, p["x"] - box[2])
            dy = max(box[1] - p["y"], 0, p["y"] - box[3])
            assert sqrt(dx * dx + dy * dy) > p["radius"] + MAX_STEP, f"pad {p['id']} is too close to ramp {r['id']}"
    assert len(g["pads"]) <= 32

    # Roof overlays: over floor 0 rooms that fade them.
    oids = set()
    for o in g["overlays"]:
        assert o["id"] not in oids
        oids.add(o["id"])
        assert 0 <= o["x0"] < o["x1"] <= width and 0 <= o["y0"] < o["y1"] <= height
        fx0, fy0, fx1, fy1 = o["footprint"]
        assert o["x0"] <= fx0 < fx1 <= o["x1"] and o["y0"] <= fy0 < fy1 <= o["y1"], f"{o['id']}'s footprint is in its box"
        for name in o["under"]:
            r = next(r for r in g["rooms"] if r["name"] == name)
            assert r["level"] == 0 and r["cover"] == o["name"], f"{name} lies under {o['name']}"
            assert overlaps((o["x0"], o["y0"], o["x1"], o["y1"]), (r["x0"], r["y0"], r["x1"], r["y1"]))
    for r in g["rooms"]:
        if r["cover"]:
            assert any(r["name"] in o["under"] for o in g["overlays"]), f"{r['name']}'s roof is listed"

    # The reviewed route: from the spawn, on the floors as the ramps set them,
    # through every gate in lap order.
    route = g["route"]
    assert route[0] == (sx, sy), "the route starts at the spawn"
    passed, levels, used, crossings = walk(g, route, level)
    assert passed == [gt["name"] for gt in g["gates"]], "the route passes the gates in order: %s" % passed
    assert levels[-1] == level, "the route ends on the spawn's floor"
    g["routeGates"] = crossings
    return {"passed": passed, "levels": levels, "ramps": used, "crossings": crossings}


# ---------------------------------------------------------------------------
# The Lua data file.


def lua_data(courses):
    lines = [
        "-- Battlegrounds Cup two-floor geometry. GENERATED by scripts/build_battlegrounds.py",
        "-- from scripts/battleground_layouts.py; edit the layouts there, not this file.",
        "-- Pure data: LayeredTrack.new builds each course from its entry",
        "-- (docs/LAYERED_TRACKS.md). `overlays`, `route` and `routeGates` are",
        "-- presentation and review data: the covers over floor 0, the reviewed way",
        "-- round and where along it each gate is crossed (the guiding arrow's way).",
        "local _, namespace = ...",
        "local Battlegrounds = {}",
        "",
    ]
    for g in courses:
        sx, sy, heading, level = g["spawn"]
        lines.append("Battlegrounds[%s] = {" % q(g["id"]))
        lines.append("    id=%s, version=%d, name=%s, laps=%d," % (q(g["id"]), g["version"], q(g["name"]), g["laps"]))
        lines.append("    width=%d, height=%d, wallInset=%d, checkpointMaxStep=%d," % (
            g["width"], g["height"], g["wallInset"], CHECKPOINT_MAX_STEP))
        lines.append("    spawn={x=%s, y=%s, heading=%s, level=%d}," % (number(sx), number(sy), HEADINGS[heading][0], level))
        lines.append("    rooms={")
        for r in g["rooms"]:
            lines.append("        {x=%d, y=%d, width=%d, height=%d, surface=%s, level=%d}, -- %s" % (
                r["x0"], r["y0"], r["x1"] - r["x0"], r["y1"] - r["y0"], q(r["surface"]), r["level"], r["name"]))
        lines.append("    },")
        lines.append("    ramps={")
        for r in g["ramps"]:
            lines.append("        {id=%s, x=%d, y=%d, width=%d, height=%d, axis=%s, ascending=%d, lowLevel=0, highLevel=1}," % (
                q(r["id"]), r["x0"], r["y0"], r["x1"] - r["x0"], r["y1"] - r["y0"], q(r["axis"]), r["ascending"]))
        lines.append("    },")
        lines.append("    gates={")
        for gt in g["gates"]:
            lines.append("        {name=%s, ax=%s, ay=%s, bx=%s, by=%s, nx=%d, ny=%d, level=%d}," % (
                q(gt["name"]), number(gt["ax"]), number(gt["ay"]), number(gt["bx"]), number(gt["by"]),
                gt["nx"], gt["ny"], gt["level"]))
        lines.append("    },")
        lines.append("    pads={")
        for p in g["pads"]:
            lines.append("        {id=%s, x=%s, y=%s, radius=%s, level=%d, boostTicks=%d}," % (
                q(p["id"]), number(p["x"]), number(p["y"]), number(p["radius"]), p["level"], p["boostTicks"]))
        lines.append("    },")
        lines.append("    solids={")
        for s in g["solids"]:
            shape = ", shape=%s" % q(s["shape"]) if s.get("shape", "rect") != "rect" else ""
            lines.append("        {id=%s, x=%d, y=%d, width=%d, height=%d%s, level=%d}," % (
                q(s["id"]), s["x"], s["y"], s["width"], s["height"], shape, s.get("level", 0)))
        lines.append("    },")
        # The roof pictures: each over floor 0, fading while the player's kart
        # is on floor 0 in one of its `under` boxes (the rooms below it,
        # within its box).
        lines.append("    overlays={")
        for o in g["overlays"]:
            under = [r for r in g["rooms"] if r["name"] in o["under"]]
            boxes = " ".join("{x0=%d, y0=%d, x1=%d, y1=%d}," % (max(r["x0"], o["x0"]), max(r["y0"], o["y0"]),
                                                                min(r["x1"], o["x1"]), min(r["y1"], o["y1"]))
                             for r in under)
            lines.append("        {id=%s, x0=%d, y0=%d, x1=%d, y1=%d, under={%s}}," % (
                q(o["id"]), o["x0"], o["y0"], o["x1"], o["y1"], boxes.rstrip(",")))
        lines.append("    },")
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
        # For each gate, the route point (1-based) the reviewed kart was
        # driving to as it crossed: the guiding arrow follows the route from
        # the gate before to there.
        lines.append("    routeGates={%s}," % ", ".join(str(k + 1) for k in g["routeGates"]))
        lines.append("}")
        lines.append("")
    lines.append("if type(namespace) == \"table\" then namespace.Battlegrounds = Battlegrounds end")
    lines.append("return Battlegrounds")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# A floor plan to review (Pillow; not an addon output).


def schematic(g, path, scale=0.5):
    from PIL import Image, ImageDraw
    w, h = int(g["width"] * scale), int(g["height"] * scale)
    img = Image.new("RGB", (w, h), (28, 26, 24))
    d = ImageDraw.Draw(img, "RGBA")

    def box(x0, y0, x1, y1):
        return (x0 * scale, (g["height"] - y1) * scale, x1 * scale, (g["height"] - y0) * scale)

    def pt(x, y):
        return (x * scale, (g["height"] - y) * scale)
    for r in g["rooms"]:
        if r["level"] == 0:
            d.rectangle(box(r["x0"], r["y0"], r["x1"], r["y1"]), fill=(70, 96, 58, 255))
    for r in g["rooms"]:
        if r["level"] == 0:
            i = WALL_INSET
            d.rectangle(box(r["x0"] + i, r["y0"] + i, r["x1"] - i, r["y1"] - i), fill=(104, 140, 82, 255))
    for r in g["rooms"]:
        if r["level"] == 1:
            d.rectangle(box(r["x0"], r["y0"], r["x1"], r["y1"]), fill=(150, 110, 200, 90),
                        outline=(190, 150, 240, 255))
    for r in g["ramps"]:
        d.rectangle(box(r["x0"], r["y0"], r["x1"], r["y1"]), fill=(220, 170, 60, 200), outline=(255, 220, 120))
        (lx, ly, _), (hx, hy, _) = ends(r)
        d.line([pt(lx, ly), pt(hx, hy)], fill=(80, 40, 0), width=2)
        d.ellipse([pt(hx, hy)[0] - 3, pt(hx, hy)[1] - 3, pt(hx, hy)[0] + 3, pt(hx, hy)[1] + 3], fill=(80, 40, 0))
    for o in g["overlays"]:
        d.rectangle(box(o["x0"], o["y0"], o["x1"], o["y1"]), outline=(240, 240, 240, 120))
    for s in g["solids"]:
        d.ellipse(box(s["x"], s["y"], s["x"] + s["width"], s["y"] + s["height"]), fill=(90, 60, 40, 255))
    for p in g["pads"]:
        d.ellipse(box(p["x"] - p["radius"], p["y"] - p["radius"], p["x"] + p["radius"], p["y"] + p["radius"]),
                  fill=(60, 200, 255, 255))
    for gt in g["gates"]:
        d.line([pt(gt["ax"], gt["ay"]), pt(gt["bx"], gt["by"])], fill=(255, 60, 60), width=2)
    d.line([pt(x, y) for x, y in g["route"]], fill=(255, 255, 255, 160), width=1)
    sx, sy = g["spawn"][:2]
    d.ellipse([pt(sx, sy)[0] - 3, pt(sx, sy)[1] - 3, pt(sx, sy)[0] + 3, pt(sx, sy)[1] + 3], fill=(255, 255, 0))
    img.save(path)


# ---------------------------------------------------------------------------
# Command line.


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--wc3", type=Path, required=True, help="folder of extracted Warcraft III files")
    parser.add_argument("--check", action="store_true", help="verify outputs without writing")
    parser.add_argument("--preview", action="store_true", help="also write review PNGs")
    parser.add_argument("--geometry-only", action="store_true", help="only the Lua data")
    parser.add_argument("--schematic", type=Path, help="write a floor plan PNG of each course here")
    args = parser.parse_args()
    caches = {d["id"]: {} for d in L.BATTLEGROUNDS}         # each course's sprites, for its painter
    courses = [geometry(d, args.wc3, caches[d["id"]]) for d in L.BATTLEGROUNDS]
    for g in courses:
        report = validate(g)
        print("VALID: %s gates %s; floors %s; ramps %s" % (g["id"], len(report["passed"]),
              "".join(str(n) for n in report["levels"]), ",".join(report["ramps"])))
        if args.schematic:
            schematic(g, args.schematic)
            print("WROTE: %s" % args.schematic)
    text = lua_data(courses)
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
    import battleground_paint
    for d, g in zip(L.BATTLEGROUNDS, courses):
        battleground_paint.build(args.wc3, d, g, check=args.check, preview=args.preview, cache=caches[d["id"]])


if __name__ == "__main__":
    main()
