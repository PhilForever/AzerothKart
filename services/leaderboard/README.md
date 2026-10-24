# Central leaderboard persistence component

This is the server-side submit/query store for the owner's central leaderboard
direction. It is **not connected to the WoW addon or deployed as a live global
board**. No network listener, uploader, credentials, game-file reader or native
API workaround is installed. The addon continues saving its local solo bests.

The available client-source audit found no supported generic HTTP/custom RPC
endpoint. Connecting this component needs a supported game-server adapter, or
an explicitly accepted external bridge. The owner has been asked whether the
product must stay addon-only; that constraint remains pending. A website or
database by itself does not create an in-game submission/query route.

## Small working interface

Python standard library only; SQLite supplies transactional persistence.
Import from this existing repository:

```python
from services.leaderboard.store import LeaderboardStore

with LeaderboardStore(db_path, deployment_id="private-test", allowed_boards=catalog["boards"]) as store:
    reply = store.submit(trusted_full_name, record)
    page = store.query(context, limit=10, offset=0)
```

`submit` returns `status`, `changed` and the retained `best`. Only a strictly
lower total changes the stored result. Equal/slower retries preserve its date
and kart. Concurrent writes use a transaction; a failed write must not remove
the prior best. Each player has a personal best even outside the first50rows.
`query` returns detached `rows,total,limit,offset`, with limit1–50 and bounded
offset. A page's total and rows come from one read transaction. Times remain
integer simulation ticks. Rows sort by ticks, finish date, ASCII-folded full
name and original name, matching the local score rules.

The ten record fields are unchanged from `Highscores.lua`: `trackId`,
`trackVersion`, `physicsVersion`, `lapCount`, `tickRate`, `rulesVersion`,
`playerName`, `totalTicks`, `finishedAt`, `kartId`. Context is the first6fields.
Each compatible board is independent. The store accepts only the configured
catalogue, never an arbitrary client-created ruleset. Names retain full UTF-8;
only ASCII letters are case-folded, with ASCII-space normalization.

**Identity boundary:** `trusted_full_name` must come from the eventual trusted
server/session adapter. It must match the record's normalized name. Passing a
name copied from an HTTP request body or a public addon secret is not
authentication. This component validates data and best-time ordering; the
submitted race time itself remains client-reported, not anti-cheat verified.
The adapter must enforce request/response correlation and finite packet budgets.

The database uses an application marker, schema version1 and an operator-chosen
deployment ID. Unknown/future/unrelated schemas or another deployment refuse
access; there is no automatic migration. Keep private AnoCore and public Forever
databases/configurations separate. Live data belongs outside Git, e.g. under
`local-artifacts/`. Supply an explicit file path; do not point this tool at game
SavedVariables, account databases or another application's SQLite file.

## Local operator example

The example is synthetic; it contains no actual player's result. `--actor` is
an operator/development input, not a public authentication mechanism. No WoW
files are read and no result is uploaded by these commands.

```powershell
python -m services.leaderboard --db local-artifacts/score-example.sqlite3 --deployment private-test submit --actor "Test Racer" --record services/leaderboard/example-result.json
python -m services.leaderboard --db local-artifacts/score-example.sqlite3 --deployment private-test board --key test_oval:2:10:3:60:1
```

Run from the repository root after creating `local-artifacts/` if absent.
JSON inputs are size-limited; duplicate fields/nonfinite numbers are refused.
The CLI does not parse or execute SavedVariables Lua.

`catalog.json` is generated from canonical Lua `Courses` and
`SoloRecords.Context`, not manually copied physics/track numbers:

```text
python scripts/export_score_catalog.py --check
```

That developer check needs pinned Lupa from `requirements-dev.txt`. The store
itself does not. Regenerate with the command without `--check` after an accepted
track/handling/rules version change; historical boards are retained in storage
but only currently configured contexts may be submitted/queried by this API.

## Connection still required

The future adapter must submit only eligible completed solo totals and derive
identity/deployment independently of record data. It must acknowledge the exact
pending result, retain offline personal bests and retry without duplicating or
clearing a newer result. The native addon has no such adapter in this slice.
No dead menu endpoint setting or automatic global/public traffic is added.
Hosting, public authentication, in-game submission/fetch and live persistence
remain unverified; do not label the existing local Highscores screen global.
