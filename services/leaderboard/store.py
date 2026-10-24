"""Transactional personal bests, independent of HTTP, WoW globals and clocks.

The caller supplies a trusted actor identity obtained by a supported transport.
This module does not authenticate a client-reported name or verify race times.
"""

from contextlib import closing, contextmanager
from pathlib import Path
import re
import sqlite3


SCHEMA_VERSION = 1
APPLICATION_ID = 0x415A4B54  # AZKT, not an arbitrary existing SQLite database.
MAX_INTEGER = 2147483647
CONTEXT_FIELDS = ("trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion")
RECORD_FIELDS = CONTEXT_FIELDS + ("playerName", "totalTicks", "finishedAt", "kartId")
_IDENTIFIER = re.compile(r"[A-Za-z0-9_]{1,64}\Z")
_DEPLOYMENT = re.compile(r"[A-Za-z0-9_.:-]{1,96}\Z")
_ASCII_LOWER = str.maketrans("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz")


class StoreError(RuntimeError):
    """An existing database cannot safely be used by this service."""


def _integer(value, minimum, maximum, field):
    if type(value) is not int or not minimum <= value <= maximum:
        raise ValueError("invalid " + field)
    return value


def _identifier(value, field):
    if type(value) is not str or not _IDENTIFIER.fullmatch(value):
        raise ValueError("invalid " + field)
    return value


def _name(value):
    if type(value) is not str or not value:
        raise ValueError("invalid player name")
    try:
        encoded = value.encode("utf-8", errors="strict")
    except UnicodeEncodeError as exc:
        raise ValueError("invalid player name") from exc
    if len(encoded) > 96 or any(ord(c) < 32 or ord(c) == 127 or c == "|" for c in value):
        raise ValueError("invalid player name")
    normalized = re.sub(" +", " ", value).strip(" ")
    if not normalized:
        raise ValueError("invalid player name")
    return normalized


def _context(value):
    if type(value) is not dict or set(value) != set(CONTEXT_FIELDS):
        raise ValueError("invalid board context")
    values = [_identifier(value[CONTEXT_FIELDS[0]], CONTEXT_FIELDS[0])]
    values.extend(_integer(value[field], 1, MAX_INTEGER, field) for field in CONTEXT_FIELDS[1:])
    return tuple(values)


def _key(context):
    return ":".join(map(str, context))


_DDL = (
    "CREATE TABLE metadata (singleton INTEGER NOT NULL PRIMARY KEY CHECK(singleton=1), "
    "deployment_id TEXT NOT NULL)",
    "CREATE TABLE boards (board_key TEXT NOT NULL PRIMARY KEY, track_id TEXT NOT NULL, "
    "track_version INTEGER NOT NULL, physics_version INTEGER NOT NULL, lap_count INTEGER NOT NULL, "
    "tick_rate INTEGER NOT NULL, rules_version INTEGER NOT NULL)",
    "CREATE TABLE personal_bests (board_key TEXT NOT NULL REFERENCES boards(board_key), "
    "player_key TEXT NOT NULL, player_name TEXT NOT NULL, total_ticks INTEGER NOT NULL "
    "CHECK(total_ticks BETWEEN 1 AND 5184000), finished_at INTEGER NOT NULL "
    "CHECK(finished_at BETWEEN 1 AND 4102444800), kart_id TEXT NOT NULL, "
    "PRIMARY KEY(board_key, player_key))",
    "CREATE INDEX best_order ON personal_bests "
    "(board_key, total_ticks, finished_at, player_key, player_name)",
)
_COLUMNS = {
    "metadata": ("singleton", "deployment_id"),
    "boards": ("board_key", "track_id", "track_version", "physics_version", "lap_count", "tick_rate", "rules_version"),
    "personal_bests": ("board_key", "player_key", "player_name", "total_ticks", "finished_at", "kart_id"),
}
_SELECT = (
    "SELECT b.track_id, b.track_version, b.physics_version, b.lap_count, b.tick_rate, b.rules_version, "
    "p.player_name, p.total_ticks, p.finished_at, p.kart_id "
    "FROM personal_bests p JOIN boards b ON b.board_key=p.board_key "
)


class LeaderboardStore:
    """A deployment-bound SQLite store with a configured compatible-board catalogue."""

    def __init__(self, path, *, deployment_id, allowed_boards):
        if type(deployment_id) is not str or not _DEPLOYMENT.fullmatch(deployment_id):
            raise ValueError("invalid deployment_id")
        if type(allowed_boards) not in (list, tuple) or not allowed_boards:
            raise ValueError("allowed_boards must be a nonempty catalogue")
        contexts = [_context(context) for context in allowed_boards]
        self._catalogue = {_key(context): context for context in contexts}
        if len(self._catalogue) != len(contexts):
            raise ValueError("duplicate board context")
        self.deployment_id = deployment_id
        self._db = None
        path_text = str(path)
        if not path_text or path_text.startswith("file:"):
            raise ValueError("use an explicit database path")
        if path_text != ":memory:":
            database_path = Path(path)
            if database_path.exists():
                # Inspect before any writable connection. Incompatible databases
                # must not be migrated, marked, journalled or re-created here.
                with closing(sqlite3.connect(database_path.resolve().as_uri() + "?mode=ro", uri=True)) as db:
                    self._inspect(db)
        db = sqlite3.connect(path_text, timeout=5, isolation_level=None)
        self._db = db
        try:
            db.execute("PRAGMA foreign_keys=ON")
            with self._transaction(validate=False):
                empty = self._inspect(db)  # Also closes the creation/open race.
                if empty:
                    for statement in _DDL:
                        db.execute(statement)
                    db.execute("INSERT INTO metadata VALUES (1, ?)", (deployment_id,))
                    db.execute("PRAGMA application_id=" + str(APPLICATION_ID))
                    db.execute("PRAGMA user_version=" + str(SCHEMA_VERSION))
                for board_key, context in self._catalogue.items():
                    db.execute("INSERT OR IGNORE INTO boards VALUES (?, ?, ?, ?, ?, ?, ?)",
                               (board_key,) + context)
        except BaseException:
            self.close()
            raise

    def _inspect(self, db):
        version = db.execute("PRAGMA user_version").fetchone()[0]
        application = db.execute("PRAGMA application_id").fetchone()[0]
        objects = set(db.execute("SELECT type, name FROM sqlite_master WHERE substr(name,1,7) != 'sqlite_'"))
        if version == 0 and application == 0 and not objects:
            return True
        if version != SCHEMA_VERSION:
            raise StoreError("unsupported database schema version")
        expected = {("table", table) for table in _COLUMNS} | {("index", "best_order")}
        if application != APPLICATION_ID or objects != expected:
            raise StoreError("unknown database schema")
        for table, columns in _COLUMNS.items():
            actual = tuple(row[1] for row in db.execute("PRAGMA table_info(" + table + ")"))
            if actual != columns:
                raise StoreError("unknown database columns")
        metadata = db.execute("SELECT singleton, deployment_id FROM metadata").fetchall()
        if metadata != [(1, self.deployment_id)]:
            raise StoreError("database belongs to a different deployment")
        for stored in db.execute("SELECT * FROM boards"):
            try:
                context = _context(dict(zip(CONTEXT_FIELDS, stored[1:])))
            except ValueError as exc:
                raise StoreError("invalid stored board") from exc
            if stored[0] != _key(context):
                raise StoreError("invalid stored board key")
        return False

    @contextmanager
    def _transaction(self, *, write=True, validate=True):
        if self._db is None:
            raise StoreError("database is closed")
        self._db.execute("BEGIN IMMEDIATE" if write else "BEGIN")
        try:
            if validate:
                self._inspect(self._db)
            yield self._db
            self._db.execute("COMMIT")
        except BaseException:
            if self._db.in_transaction:
                self._db.execute("ROLLBACK")
            raise

    def _allowed(self, context):
        values = _context(context)
        key = _key(values)
        if key not in self._catalogue:
            raise ValueError("board is not in the configured catalogue")
        return key

    def submit(self, actor_name, record):
        """Persist one self-reported best, using an identity trusted by the caller."""
        if type(record) is not dict or set(record) != set(RECORD_FIELDS):
            raise ValueError("invalid score record")
        context = {field: record[field] for field in CONTEXT_FIELDS}
        board_key = self._allowed(context)
        actor, claimed = _name(actor_name), _name(record["playerName"])
        player_key = actor.translate(_ASCII_LOWER)
        if player_key != claimed.translate(_ASCII_LOWER):
            raise ValueError("record name does not match trusted actor")
        ticks = _integer(record["totalTicks"], 1, 5184000, "totalTicks")
        stamp = _integer(record["finishedAt"], 1, 4102444800, "finishedAt")
        kart = _identifier(record["kartId"], "kartId")
        with self._transaction() as db:
            changed = db.execute(
                "INSERT INTO personal_bests VALUES (?, ?, ?, ?, ?, ?) "
                "ON CONFLICT(board_key, player_key) DO UPDATE SET player_name=excluded.player_name, "
                "total_ticks=excluded.total_ticks, finished_at=excluded.finished_at, kart_id=excluded.kart_id "
                "WHERE excluded.total_ticks < personal_bests.total_ticks",
                (board_key, player_key, actor, ticks, stamp, kart)).rowcount == 1
            best = db.execute(_SELECT + "WHERE p.board_key=? AND p.player_key=?", (board_key, player_key)).fetchone()
            return {"status": "recorded" if changed else "not_better", "changed": changed,
                    "best": dict(zip(RECORD_FIELDS, best))}

    def query(self, context, *, limit=10, offset=0):
        """Read a consistent, bounded board page; keep every stored personal best."""
        board_key = self._allowed(context)
        _integer(limit, 1, 50, "limit")
        _integer(offset, 0, 1000000, "offset")
        with self._transaction(write=False) as db:
            total = db.execute("SELECT count(*) FROM personal_bests WHERE board_key=?", (board_key,)).fetchone()[0]
            rows = db.execute(_SELECT + "WHERE p.board_key=? ORDER BY p.total_ticks, p.finished_at, "
                              "p.player_key COLLATE BINARY, p.player_name COLLATE BINARY LIMIT ? OFFSET ?",
                              (board_key, limit, offset)).fetchall()
            return {"rows": [dict(zip(RECORD_FIELDS, row)) for row in rows], "total": total,
                    "limit": limit, "offset": offset}

    def close(self):
        if self._db is not None:
            self._db.close()
            self._db = None

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()
