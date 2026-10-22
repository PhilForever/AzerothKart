"""Focused analytic boundary tests; run with Python's standard library."""
import math
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from circuit_boundary import boundary_vertices, loop_radii


def geometry(*branches, radius=1, plazas=()):
    return {"centerline": [], "branches": list(branches),
            "wallRadius": radius, "plazas": list(plazas)}


class BoundaryTests(unittest.TestCase):
    def assertVertex(self, vertices, expected, tolerance=1e-6):
        self.assertTrue(any(math.hypot(x - expected[0], y - expected[1]) < tolerance
                            for x, y in vertices), (expected, vertices))

    def test_concave_l_union_retains_the_exposed_inner_corner(self):
        vertices = boundary_vertices(geometry([(-10, 0), (0, 0), (0, 10)]), 1)
        self.assertVertex(vertices, (-2, 2))
        # Primitive intersections buried inside the other arm are not walls.
        self.assertNotIn((0.0, 2.0), vertices)
        self.assertNotIn((-2.0, 0.0), vertices)
        self.assertEqual(vertices, sorted(vertices))
        self.assertEqual(vertices, boundary_vertices(
            geometry([(-10, 0), (0, 0), (0, 10)]), 1))

    def test_overlapping_circles_expose_two_exact_crossings(self):
        g = geometry(plazas=({"ax": 0, "ay": 0, "bx": 0, "by": 0, "radius": 2},
                             {"ax": 2, "ay": 0, "bx": 2, "by": 0, "radius": 2}))
        vertices = boundary_vertices(g, 0)
        self.assertEqual(len(vertices), 2)
        self.assertVertex(vertices, (1, math.sqrt(3)))
        self.assertVertex(vertices, (1, -math.sqrt(3)))

    def test_tangent_circles_keep_one_contact(self):
        g = geometry(plazas=({"ax": 0, "ay": 0, "bx": 0, "by": 0, "radius": 1},
                             {"ax": 2, "ay": 0, "bx": 2, "by": 0, "radius": 1}))
        self.assertEqual(boundary_vertices(g, 0), [(1.0, 0.0)])

    def test_circle_over_straight_wall_exposes_line_circle_crossings(self):
        g = geometry([(0, 0), (10, 0)], plazas=(
            {"ax": 5, "ay": 1, "bx": 5, "by": 1, "radius": 1},))
        vertices = boundary_vertices(g, 0)
        self.assertVertex(vertices, (4, 1))
        self.assertVertex(vertices, (6, 1))

    def test_contained_and_isolated_circles_have_no_vertices(self):
        circle = {"ax": 0, "ay": 0, "bx": 0, "by": 0, "radius": 3}
        self.assertEqual(boundary_vertices(geometry(plazas=[circle]), 0), [])
        smaller = dict(circle, ax=1, bx=1, radius=1)
        self.assertEqual(boundary_vertices(geometry(plazas=[circle, smaller]), 0), [])

    def test_collinear_segments_preserve_exposed_join_endpoints(self):
        vertices = boundary_vertices(geometry([(0, 0), (5, 0), (10, 0)]), 0)
        for point in [(0, -1), (0, 1), (5, -1), (5, 1), (10, -1), (10, 1)]:
            self.assertVertex(vertices, point)
        self.assertEqual(len(vertices), 6)

    def test_perpendicular_overlaps_remove_buried_intersections(self):
        vertices = boundary_vertices(geometry([(-10, 0), (10, 0)],
                                              [(0, -10), (0, 10)]), 0)
        for point in [(-1, -1), (-1, 1), (1, -1), (1, 1)]:
            self.assertVertex(vertices, point)
        self.assertNotIn((0.0, 0.0), vertices)

    def test_rounded_stormwind_geometry_has_the_reported_water_wall_apex(self):
        source = (ROOT / "addon/AzerothKart/CapitalCities.lua").read_text(encoding="utf-8")
        body = source.split("centerline={", 1)[1].split("branches={", 1)[0]
        line = [tuple(map(float, pair)) for pair in
                re.findall(r"\{x=([\d.]+),y=([\d.]+)\}", body)]
        g = {"centerline": line, "wallRadius": 76}
        self.assertVertex(boundary_vertices(g, 14),
                          (476.2652153292576, 866.3694266226744), 0.001)

    def test_narrows_use_their_own_radius_and_expose_their_joins(self):
        # Segment 1 (Lua's count: point 1 to point 2) of a square loop narrows
        # to 5: its straight walls meet the wide neighbours' end circles.
        g = {"centerline": [(0, 0), (100, 0), (100, 100), (0, 100)], "wallRadius": 10,
             "narrows": [{"first": 1, "last": 1, "wallRadius": 5}]}
        vertices = boundary_vertices(g, 0)
        for point in [(math.sqrt(75), -5), (100 - math.sqrt(75), -5), (10, 5), (90, 5)]:
            self.assertVertex(vertices, point)
        self.assertEqual(loop_radii(g), [10.0, 5.0, 10.0, 10.0])
        # With clearance every capsule grows by it, the narrows' too.
        self.assertVertex(boundary_vertices(g, 1), (math.sqrt(11 * 11 - 36), -6))
        for bad in ({"first": 0, "last": 1, "wallRadius": 5}, {"first": 2, "last": 1, "wallRadius": 5},
                    {"first": 1, "last": 5, "wallRadius": 5}, {"first": 1, "last": 1, "wallRadius": 11}):
            with self.assertRaises(ValueError):
                boundary_vertices(dict(g, narrows=[bad]), 0)

    def test_invalid_clearance_is_rejected(self):
        for clearance in (-1, math.inf, math.nan):
            with self.assertRaises(ValueError):
                boundary_vertices(geometry([(0, 0), (2, 0)]), clearance)


if __name__ == "__main__":
    unittest.main()
