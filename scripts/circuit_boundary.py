"""Exact exposed vertices of a union of street capsules, for offline builds.

The painted street is the union of capsules whose radius is wallRadius plus
the kart clearance (a narrows' smaller wallRadius on its loop segments).
Shrinking each capsule independently loses drivable room
at a concave join. Runtime clearance therefore needs the exposed union boundary:
the capsules' arcs/segments and their intersection vertices.

Only geometry is consumed. Pass the same rounded coordinates written to Lua;
this module never samples art, rounds authored coordinates or changes radii.
"""
from math import hypot, isfinite, sqrt


EPSILON = 1.0e-7  # world units: exposure, segment ends and duplicate vertices


def _xy(point):
    if isinstance(point, dict):
        return float(point["x"]), float(point["y"])
    return float(point[0]), float(point[1])


def _axis_distance(x, y, capsule):
    ax, ay, bx, by, radius = capsule
    dx, dy = bx - ax, by - ay
    length_squared = dx * dx + dy * dy
    t = 0.0 if length_squared == 0 else max(
        0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / length_squared))
    return hypot(x - ax - t * dx, y - ay - t * dy)


def _bounds(primitive):
    kind, values = primitive
    if kind == "circle":
        x, y, radius = values
        return x - radius, y - radius, x + radius, y + radius
    ax, ay, bx, by = values
    return min(ax, bx), min(ay, by), max(ax, bx), max(ay, by)


def _overlap(a, b):
    return not (a[2] < b[0] - EPSILON or b[2] < a[0] - EPSILON
                or a[3] < b[1] - EPSILON or b[3] < a[1] - EPSILON)


def _line_line(first, second):
    ax, ay, bx, by = first
    cx, cy, dx, dy = second
    ux, uy, vx, vy = bx - ax, by - ay, dx - cx, dy - cy
    determinant = ux * vy - uy * vx
    # Collinear overlaps contribute their endpoints instead. Parallel lines
    # have no isolated intersection vertex.
    scale = hypot(ux, uy) * hypot(vx, vy)
    if abs(determinant) <= 1.0e-14 * scale:
        return ()
    ex, ey = cx - ax, cy - ay
    t = (ex * vy - ey * vx) / determinant
    u = (ex * uy - ey * ux) / determinant
    t_margin = EPSILON / hypot(ux, uy)
    u_margin = EPSILON / hypot(vx, vy)
    if -t_margin <= t <= 1 + t_margin and -u_margin <= u <= 1 + u_margin:
        t = max(0.0, min(1.0, t))
        return ((ax + t * ux, ay + t * uy),)
    return ()


def _line_circle(line, circle):
    ax, ay, bx, by = line
    cx, cy, radius = circle
    dx, dy = bx - ax, by - ay
    length_squared = dx * dx + dy * dy
    at = ((cx - ax) * dx + (cy - ay) * dy) / length_squared
    px, py = ax + at * dx, ay + at * dy
    distance = hypot(px - cx, py - cy)
    if distance > radius + EPSILON:
        return ()
    half = sqrt(max(0.0, radius * radius - distance * distance) / length_squared)
    margin = EPSILON / sqrt(length_squared)
    points = []
    for t in (at - half, at + half):
        if -margin <= t <= 1 + margin:
            t = max(0.0, min(1.0, t))
            points.append((ax + t * dx, ay + t * dy))
    return points


def _circle_circle(first, second):
    ax, ay, ar = first
    bx, by, br = second
    dx, dy = bx - ax, by - ay
    distance = hypot(dx, dy)
    if (distance <= EPSILON or distance > ar + br + EPSILON
            or distance < abs(ar - br) - EPSILON):
        return ()
    at = (ar * ar - br * br + distance * distance) / (2 * distance)
    height = sqrt(max(0.0, ar * ar - at * at))
    x, y = ax + at * dx / distance, ay + at * dy / distance
    ox, oy = -dy * height / distance, dx * height / distance
    return ((x - ox, y - oy), (x + ox, y + oy))


def loop_radii(geometry):
    """Each closed-centerline segment's drivable radius, indexed as the
    segment ``centerline[i - 1] -> centerline[i]``: wallRadius, or the
    smaller wallRadius of a narrows covering it.

    ``geometry["narrows"]`` (optional) lists ``{first, last, wallRadius}``
    with 1-based loop segments as Circuit.lua counts them (segment k joins
    point k to point k % n + 1), so Lua segment k is index ``k % n`` here.
    Branches and plazas never narrow."""
    line = geometry.get("centerline", [])
    count = len(line)
    default = float(geometry["wallRadius"])
    radii = [default] * count
    for narrow in geometry.get("narrows", []):
        first, last = narrow["first"], narrow["last"]
        if isinstance(narrow["wallRadius"], bool):
            raise ValueError("a narrows' wall radius must be numeric, not boolean")
        reach = float(narrow["wallRadius"])
        if not (type(first) is int and type(last) is int and 1 <= first <= last <= count):
            raise ValueError("narrows must name loop segments 1..n, first <= last")
        if not isfinite(reach) or reach <= 0 or reach > default:
            raise ValueError("a narrows' wall radius must be positive and within wallRadius")
        for k in range(first, last + 1):
            radii[k % count] = min(radii[k % count], reach)
    return radii


def boundary_vertices(geometry, clearance):
    """Return exposed union-boundary vertices as sorted ``[(x, y), ...]``.

    ``geometry`` accepts the build pipeline's centerline/open branches and
    plaza dictionaries. Each road capsule has radius wallRadius + clearance
    (a narrows' own wallRadius on its loop segments: loop_radii); each plaza
    has radius plaza.radius + clearance. Coordinates may be pairs or {x, y}
    dictionaries. An isolated circle has no vertices and returns [].

    Full endpoint circles are used when enumerating intersections. Filtering
    against every complete capsule removes inward semicircles and all hidden
    intersections. Exposed line endpoints are retained for collinear overlaps
    and tangencies. Smooth joins can remain in the result; they are harmless
    candidate points for a nearest-boundary query.
    """
    clearance = float(clearance)
    if not isfinite(clearance) or clearance < 0:
        raise ValueError("finite nonnegative clearance required")
    radius = float(geometry["wallRadius"]) + clearance
    if not isfinite(radius) or radius <= 0:
        raise ValueError("finite positive wall radius plus clearance required")
    capsules = []

    def add(a, b, reach):
        ax, ay = _xy(a)
        bx, by = _xy(b)
        if not all(isfinite(n) for n in (ax, ay, bx, by, reach)) or reach <= 0:
            raise ValueError("finite capsule coordinates and positive radius required")
        capsules.append((ax, ay, bx, by, reach))

    line = geometry.get("centerline", [])
    radii = loop_radii(geometry)
    for index in range(len(line)):
        a, b = line[index - 1], line[index]
        if _xy(a) != _xy(b):
            add(a, b, radii[index] + clearance)
    for branch in geometry.get("branches", []):
        for a, b in zip(branch, branch[1:]):
            if _xy(a) != _xy(b):
                add(a, b, radius)
    for plaza in geometry.get("plazas", []):
        add((plaza["ax"], plaza["ay"]), (plaza["bx"], plaza["by"]),
            float(plaza["radius"]) + clearance)

    primitives = set()
    endpoints = []
    for ax, ay, bx, by, reach in capsules:
        primitives.add(("circle", (ax, ay, reach)))
        primitives.add(("circle", (bx, by, reach)))
        length = hypot(bx - ax, by - ay)
        if length == 0:
            continue
        nx, ny = -(by - ay) / length, (bx - ax) / length
        for side in (-1, 1):
            a = (ax + side * nx * reach, ay + side * ny * reach)
            b = (bx + side * nx * reach, by + side * ny * reach)
            if b < a:
                a, b = b, a
            primitives.add(("line", (*a, *b)))
            endpoints.extend((a, b))

    primitives = sorted(primitives)
    boxes = [_bounds(p) for p in primitives]
    capsule_boxes = [(min(a, c) - r, min(b, d) - r,
                      max(a, c) + r, max(b, d) + r)
                     for a, b, c, d, r in capsules]

    def exposed(point):
        x, y = point
        for capsule, box in zip(capsules, capsule_boxes):
            if (box[0] - EPSILON <= x <= box[2] + EPSILON
                    and box[1] - EPSILON <= y <= box[3] + EPSILON
                    and _axis_distance(x, y, capsule) < capsule[4] - EPSILON):
                return False
        return True

    candidates = list(endpoints)
    for i, (first_kind, first) in enumerate(primitives):
        for j in range(i + 1, len(primitives)):
            if not _overlap(boxes[i], boxes[j]):
                continue
            second_kind, second = primitives[j]
            if first_kind == "line" and second_kind == "line":
                candidates.extend(_line_line(first, second))
            elif first_kind == "circle" and second_kind == "circle":
                candidates.extend(_circle_circle(first, second))
            elif first_kind == "line":
                candidates.extend(_line_circle(first, second))
            else:
                candidates.extend(_line_circle(second, first))

    # Sort before deduplication so the representative and output order are
    # stable. Neighboring epsilon cells catch duplicates across cell borders.
    vertices, cells = [], {}
    for x, y in sorted(point for point in candidates if exposed(point)):
        cell = (round(x / EPSILON), round(y / EPSILON))
        duplicate = False
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for px, py in cells.get((cell[0] + dx, cell[1] + dy), ()):
                    if hypot(x - px, y - py) <= EPSILON:
                        duplicate = True
                        break
        if not duplicate:
            point = (x, y)
            cells.setdefault(cell, []).append(point)
            vertices.append(point)
    return vertices
