# Claude Thunder Bluff and Scarlet Graveyard integration review

2026-10-25,22:20 CET. Owner requests review, publication of both Claude feature
branches, then resumption of the production-map/multiplayer work.

Reviewed exact source:

- `claude/thunder-bluff`: `a7aeb6648d0adc51249729702a1b3e6ed38df71f`.
- `claude/scarlet-graveyard`: `1bc3ac8db34e40599377d458971e3b70ad7c3ae6`,
  containing Thunder Bluff, based on installed-tuning docs `aac1bdd`.
- Codex's independently tested map checkpoint `d30b582`, from `aac1bdd`.

The original branches are approved as feature history with the known score-sync
dependency. They were published without rewriting commits. `git ls-remote`
confirmed both exact hashes. Main and Claude's worktree were not changed.
**Do not install either original branch alone.** The corrected combined source
is merge`b98296c` on `codex/claude-courses-integration`; the installed runtime remains `bb085ac`.

## Reviewed source and corrections

Thunder Bluff uses existing Circuit geometry: six gates, six bridge narrows,
version1,5,616unit loop. Previous five city pictures are byte-identical to the
base. Four new TGAs have correct32bit bottom-origin headers/lengths: Thunder
Bluff2048square/512square, Graveyard2048×1024/512×256. Reviewed overview/camera
images and provenance are included. Existing redistribution questions remain
for release; this is no asset-rights or native-performance certification.

Owner-authorized `Race`/`SoloRecords` changes use optional integer `track.laps`
1–9, default3. The accepted solo Graveyard sprint is one ordered run through
three gates, with its own lapCount1 score context. Production-context admission
continues to reject retired/developer courses. UI now says Sprint during both
countdown and running, with regressions; other maps retain3laps.

Dungeon's new pure geometry uses prebuilt spatial lists, inset room rectangles,
rough lawn and swept solid boxes. Floor-wall movement is endpoint projection,
not a general continuous polygon sweep. The authored map's separated floor
regions are at least10units apart, beyond the current maximum normal4.333unit
step; generated data is validated accordingly. No Physics/version change.

The original hardcoded score count really prevents sharing from starting.
Combined ScoreSync derives eight active contexts/nine HELLO slots from its
arrays, adds stableT/G codes and keeps retiredO zero. Tests cover all-eight-board
catch-up, a new one-run Graveyard best, stable old codes, old-layout refusal,
save preservation and the existing158byte native working budget. No score
history is deleted or reset.

The existing live controller still requires3laps. Courses now explicitly
distinguishes solo availability from multiplayer eligibility: all seven lap
maps, including Thunder Bluff, enter the two-peer flow; Graveyard is filtered
from the lobby/Ready/native compatibility snapshot and has no control wire code.
This prevents a selectable session that fails later at GO. Eight-player/group
transport remains a separate unresolved gate; no raid requirement is imposed.

## Executed evidence

- `scripts/test_lua.py --runtime lua51`: **full suite PASS**,78Lua files parsed.
  Includes new Dungeon geometry, real sprint UI finish/save, status wording,
  eight-board sharing, seven-map grid/GO and complete two-client mocked menu/
  transport integration. Initial integration fixture/count/code conflicts were
  corrected before this final full pass; mechanics assertions were preserved.
- `scripts/build_city_tracks.py --wc3 . --geometry-only --check`: PASS.
- Dungeon full/model-based rebuild was **NOT RUN**: the attempted `--wc3 .`
  check stops on missing extracted `herobloodelf.mdx`. Independently executed
  ignored `local-artifacts/courses-review-20261025/check_dungeon_geometry.py`:
  checked-in footprint data plus source layout serialize byte-for-byte to the
  runtime file; floor-gap/route/gate-wall/flood-fill checks all PASS. This does
  not reproduce the original models' footprint extraction or painted pixels.
- `python -m unittest discover -s tests -p test_circuit_boundary.py -q`:11PASS.
  Equivalent `test_leaderboard_store.py`:13PASS.
- `scripts/export_score_catalog.py --check`: PASS,8production boards.
- `git diff --check`: PASS. Structural validator reports only the2pre-existing
  expired skill links in historical PROGRESS; it is not a full validator PASS.

Native new-map driving/art/HUD/performance, actual community delivery, city
multiplayer, Lua5.4 and eight-racer capacity: **NOT RUN** in this review.
No deployment, release, main merge, player-data access or client input.

Next networking task: establish supported fan-out/grouping policy for eight
racers, then build the bounded room controller around one shared start epoch.
Retain ungrouped two-peer racing. Live sprint support is also outstanding.
