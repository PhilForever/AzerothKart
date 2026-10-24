"""Actual SQLite checks; these do not establish a native WoW service adapter."""

from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
from copy import deepcopy
from pathlib import Path
import sqlite3
import tempfile
import unittest

from services.leaderboard import LeaderboardStore, StoreError


CONTEXT = {"trackId": "test_oval", "trackVersion": 2, "physicsVersion": 10,
           "lapCount": 3, "tickRate": 60, "rulesVersion": 1}
DEPLOYMENT = "private-anocore-70532"


def record(name="Amber Stone", ticks=1800, stamp=1792750000, *, context=None, kart="steam_tank"):
    return {**(context or CONTEXT), "playerName": name, "totalTicks": ticks,
            "finishedAt": stamp, "kartId": kart}


class LeaderboardStoreTests(unittest.TestCase):
    def setUp(self):
        # The desktop sandbox's default AppContainer temp path cannot be
        # opened by SQLite on this host. Keep test databases in the workspace.
        root = Path(__file__).resolve().parents[1] / "local-artifacts" / "leaderboard-store-tests"
        root.mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(prefix="case-", dir=root)
        assert Path(self.directory.name).resolve().is_relative_to(root.resolve())
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "scores.sqlite3"

    def open(self, *, deployment=DEPLOYMENT, boards=None):
        store = LeaderboardStore(self.path, deployment_id=deployment,
                                 allowed_boards=boards or [deepcopy(CONTEXT)])
        self.addCleanup(store.close)
        return store

    def test_persist_reopen_and_idempotent_retry(self):
        store = self.open()
        value = record()
        self.assertEqual(store.submit("Amber Stone", value),
                         {"status": "recorded", "changed": True, "best": value})
        store.close()
        again = self.open()
        retry = again.submit("Amber Stone", value)
        self.assertEqual(retry, {"status": "not_better", "changed": False, "best": value})
        self.assertEqual(again.query(CONTEXT), {"rows": [value], "total": 1, "limit": 10, "offset": 0})

    def test_only_faster_updates_date_and_kart(self):
        store = self.open()
        first = record()
        store.submit("Amber Stone", first)
        for ticks in (1800, 1801):
            value = record(ticks=ticks, stamp=1792800000, kart="meat_wagon")
            self.assertEqual(store.submit("Amber Stone", value)["best"], first)
        improved = record(ticks=1799, stamp=1792900000, kart="goblin_drag_car")
        self.assertTrue(store.submit("Amber Stone", improved)["changed"])
        self.assertEqual(store.query(CONTEXT)["rows"], [improved])

    def test_trusted_identity_normalizes_spaces_and_ascii_only(self):
        store = self.open()
        result = store.submit("  Amber   Stone  ", record("amber stone"))
        self.assertEqual(result["best"]["playerName"], "Amber Stone")
        with self.assertRaises(ValueError):
            store.submit("Other Person", record())
        with self.assertRaises(ValueError):
            store.submit("Åse Li", record("åse li"))
        for name in ("Åse 李", "åse 李", "Anne-Marie O'Brian", "A\u00a0B"):
            store.submit(name, record(name))
        self.assertEqual(store.query(CONTEXT)["total"], 5)

    def test_rejects_invalid_names_without_writes(self):
        store = self.open()
        for name in (None, True, 4, "", "   ", "A" * 97, "é" * 49, "A\tB", "A\nB",
                     "A\0B", "A\x7fB", "A|B", "\ud800", " " * 96 + "A"):
            with self.subTest(name=repr(name)), self.assertRaises(ValueError):
                store.submit(name, record(name))
        self.assertEqual(store.query(CONTEXT)["total"], 0)

    def test_record_bounds_exact_types_and_unknown_fields(self):
        store = self.open()
        for field, bads in {
            "totalTicks": (0, 5184001, True, 1.0, "1", float("nan")),
            "finishedAt": (0, 4102444801, False, 2.5),
            "kartId": ("", "bad-kart", "x" * 65, 1),
            "trackId": ("", "bad-track", "x" * 65, True),
            "trackVersion": (0, 2147483648, True, 2.0),
            "physicsVersion": (0, 2147483648, True),
            "lapCount": (0, 2147483648, 3.0),
            "tickRate": (0, 2147483648, "60"),
            "rulesVersion": (0, 2147483648, False),
        }.items():
            for bad in bads:
                value = record(); value[field] = bad
                with self.subTest(field=field, value=repr(bad)), self.assertRaises(ValueError):
                    store.submit("Amber Stone", value)
        for change in (lambda r: r.update(extra=1), lambda r: r.pop("kartId")):
            value = record(); change(value)
            with self.assertRaises(ValueError):
                store.submit("Amber Stone", value)
        self.assertEqual(store.query(CONTEXT)["total"], 0)
        boundary = record("B" * 96, ticks=5184000, stamp=4102444800, kart="_" * 64)
        self.assertTrue(store.submit(boundary["playerName"], boundary)["changed"])

    def test_catalogue_exact_variants_and_detached_input(self):
        other = {**CONTEXT, "physicsVersion": 11}
        boards = [deepcopy(CONTEXT), other]
        store = self.open(boards=boards)
        boards[0]["physicsVersion"] = 99
        store.submit("Amber Stone", record())
        store.submit("Amber Stone", record(ticks=2000, context=other))
        self.assertEqual(store.query(CONTEXT)["rows"][0]["totalTicks"], 1800)
        self.assertEqual(store.query(other)["rows"][0]["totalTicks"], 2000)
        for context in ({**CONTEXT, "physicsVersion": 99}, {**CONTEXT, "extra": 1}):
            with self.assertRaises(ValueError):
                store.query(context)
        with self.assertRaises(ValueError):
            LeaderboardStore(self.path, deployment_id=DEPLOYMENT, allowed_boards=[CONTEXT, CONTEXT])

    def test_pages_retain_bests_beyond_top_fifty_and_tie_order(self):
        store = self.open()
        for i in range(65):
            name = "Player %02d" % i
            store.submit(name, record(name, 1800 + i))
        self.assertEqual(len(store.query(CONTEXT, limit=50)["rows"]), 50)
        tail = store.query(CONTEXT, limit=20, offset=50)
        self.assertEqual(tail["total"], 65)
        self.assertEqual(len(tail["rows"]), 15)
        self.assertEqual(tail["rows"][-1]["playerName"], "Player 64")
        self.assertEqual(store.submit("Player 64", record("Player 64", 1864, 1792900000))["best"]["finishedAt"],
                         1792750000)
        store.submit("Player 64", record("Player 64", 1700))
        self.assertEqual(store.query(CONTEXT)["rows"][0]["playerName"], "Player 64")
        for name, stamp in (("Zulu One", 100), ("Beta One", 100), ("Alpha One", 101)):
            store.submit(name, record(name, 1500, stamp))
        self.assertEqual([r["playerName"] for r in store.query(CONTEXT, limit=3)["rows"]],
                         ["Beta One", "Zulu One", "Alpha One"])
        tail["rows"][0]["playerName"] = "Mutated"
        self.assertNotEqual(store.query(CONTEXT, limit=1, offset=50)["rows"][0]["playerName"], "Mutated")

    def test_query_bounds_and_empty_offset(self):
        store = self.open()
        for keyword, bads in (("limit", (0, 51, True, 1.0)), ("offset", (-1, 1000001, False, 0.0))):
            for bad in bads:
                with self.subTest(keyword=keyword, bad=bad), self.assertRaises(ValueError):
                    store.query(CONTEXT, **{keyword: bad})
        self.assertEqual(store.query(CONTEXT, offset=1000000)["rows"], [])

    def test_unknown_and_future_databases_preserve_bytes(self):
        for version, table in ((99, "future_data"), (1, "unrelated"), (0, "sqliteevil")):
            with self.subTest(version=version):
                path = Path(self.directory.name) / ("unknown%d.sqlite3" % version)
                with closing(sqlite3.connect(path)) as db:
                    db.execute("CREATE TABLE " + table + " (value TEXT)")
                    db.execute("INSERT INTO " + table + " VALUES ('keep')")
                    db.execute("PRAGMA user_version=" + str(version))
                    db.commit()
                before = path.read_bytes()
                with self.assertRaises(StoreError):
                    LeaderboardStore(path, deployment_id=DEPLOYMENT, allowed_boards=[CONTEXT])
                self.assertEqual(path.read_bytes(), before)

    def test_deployment_mismatch_refuses_without_writing(self):
        store = self.open()
        store.submit("Amber Stone", record())
        store.close()
        before = self.path.read_bytes()
        with self.assertRaises(StoreError):
            self.open(deployment="public-forever")
        self.assertEqual(self.path.read_bytes(), before)
        self.assertEqual(self.open().query(CONTEXT)["total"], 1)

    def test_failed_write_rolls_back_and_connection_remains_usable(self):
        store = self.open()
        store.submit("Amber Stone", record())
        # Fail COMMIT after the SQL update ran, without changing the database
        # schema. The transaction must roll back before callers can retry.
        def deny_commit(action, first, *_):
            if action == sqlite3.SQLITE_TRANSACTION and first == "COMMIT":
                return sqlite3.SQLITE_DENY
            return sqlite3.SQLITE_OK
        store._db.set_authorizer(deny_commit)
        with self.assertRaises(sqlite3.DatabaseError):
            store.submit("Amber Stone", record(ticks=1700))
        store._db.set_authorizer(None)
        self.assertEqual(store.query(CONTEXT)["rows"][0]["totalTicks"], 1800)
        self.assertTrue(store.submit("Amber Stone", record(ticks=1700))["changed"])

    def test_live_schema_and_deployment_changes_refuse_before_mutation(self):
        store = self.open()
        store.submit("Amber Stone", record())
        with closing(sqlite3.connect(self.path)) as db:
            db.execute("PRAGMA user_version=2")
        before = self.path.read_bytes()
        for operation in (lambda: store.submit("Amber Stone", record(ticks=1700)), lambda: store.query(CONTEXT)):
            with self.assertRaises(StoreError):
                operation()
        self.assertEqual(self.path.read_bytes(), before)
        with closing(sqlite3.connect(self.path)) as db:
            db.execute("PRAGMA user_version=1")
            db.execute("UPDATE metadata SET deployment_id='different-server'")
            db.commit()
        before = self.path.read_bytes()
        with self.assertRaises(StoreError):
            store.submit("Amber Stone", record(ticks=1700))
        with self.assertRaises(StoreError):
            store.query(CONTEXT)
        self.assertEqual(self.path.read_bytes(), before)

    def test_concurrent_connections_keep_fastest_and_context_manager_closes(self):
        with self.open() as initial:
            self.assertEqual(initial.query(CONTEXT)["total"], 0)
        with self.assertRaises(StoreError):
            initial.query(CONTEXT)
        def submit(ticks):
            with LeaderboardStore(self.path, deployment_id=DEPLOYMENT, allowed_boards=[CONTEXT]) as store:
                return store.submit("Amber Stone", record(ticks=ticks))
        with ThreadPoolExecutor(max_workers=4) as pool:
            list(pool.map(submit, (2100, 1700, 1900, 1800, 2000, 1750)))
        self.assertEqual(self.open().query(CONTEXT)["rows"][0]["totalTicks"], 1700)


if __name__ == "__main__":
    unittest.main()
