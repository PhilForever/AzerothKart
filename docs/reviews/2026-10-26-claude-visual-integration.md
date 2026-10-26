# Reviewed Scarlet v3, race screens and Gryphon wings

2026-10-26, Codex integration branch `codex/claude-race-integration`, from
`7cd2aed` (installed rematch runtime `94d4d1e`). Owner asks to review Claude's
latest work and integrate if approved. Reviewed tips, unchanged in Claude's
worktree: Scarlet-v3 `a4fe2d5`, race-screens `8511d8c`, Gryphon-wings `e3c82ad`.
Merge ancestry preserves both authors' history; no main merge or publication.

## Accepted source

- Scarlet Library opens its courtyard and fountain ring; Cathedral stairs
  turn at landings; all Scarlet grass has full grip. Current versions G3/L3/A2/C3.
- Estimated in-race place and peer name tag, visual multiplayer results,
  solo score medals/confetti, and a Highscores shortcut to the finisher's row.
- Gryphon four-pose wingbeat and boost glide, matching outline and garage.

The final multiplayer screen preserves the newer same-player Play Again/map
commands. These remain two-peer observations, not authenticated standings.
Missing finishes stay pending; ties share first. Four dungeon sprints remain
solo, seven circuits remain eligible for two peers. Eight-player gates stay open.

## Required corrections applied

1. Graveyard's grass change requires version3. Generated data, current board,
   catch-up test and server example catalogue now agree. Historical scores stay.
2. Solo celebrations consume exact saved `playerName` and detached placement;
   no equal-time/latest-row identity guess. The optional metadata preserves
   existing return fields. Cold initialization uses the pre-finish personal
   snapshot rather than preloading the just-saved result as its own previous PB.
3. Final MP visuals use the retained backend result snapshot, including after
   a new lobby has `live=nil`. Pending/stopped peers cannot award a victory;
   equal ticks remain joint first. Late refresh/reopen never replay sounds.
4. Peer wing animation requires a fresh running observation in a running live
   view. Grid/stale/stopped/finished observations rest, even with old boosting.

No changes to Physics, collision solver, Race, input, fixed step, wire codecs,
PeerSession, LiveRace or SessionTransport. Existing turning interpolation,
rematch lifecycle and persistent native traffic budgets remain intact.

## Focused executed checks

- Lua51 `dungeon presentation menu`: PASS after updating one second historical
  Graveyard2 assertion to3. Normal-step production pool sweep still hits with
  clearance133.005451112; route/ordered-gate and courtyard/stair checks pass.
- Lua51 `ui`: PASS, including peer wing lifecycle/read-only observations and
  existing turning/room regressions. The new fresh-packet fixture initially
  inherited `remoteStale=true`; corrected the fixture to reflect actual input.
- Lua51 `solo_records score_sharing multiplayer_integration`: PASS. Includes
  exact finisher metadata, failed sharing, preserved historical boards, all11
  course catch-up, bounded packet sizes/pacing, and two completed races with
  same players/new session/map/full countdown and no solo score.
- After the cold-first-finish fix, Lua51 `solo_records score_sharing`: PASS.
- Agent's focused Lua51/Lua54 `menu`: PASS; all80 Lua sources/tests parse.
- `scripts/build_celebration_art.py --check`: PASS,524306bytes,
  SHA256 `2296c4ac78f02e304c26a4872719f779520c666ebb4052d2a4e7b4aa8a9892fd`.
- `scripts/build_kart_outlines.py --check`: PASS, all10 outlines, including
  all Gryphon phases. `scripts/export_score_catalog.py --check`: PASS11boards.
- `scripts/validate_project.py`: only two pre-existing expired skill-path links
  in historical PROGRESS entries fail. This is not a full validator pass.

Full-suite repetition, model/map image rebuilding and actual client appearance,
sound, rematch feel, wing motion and texture memory/hitch checks: **NOT RUN**
by this integration run. Claude's prior rebuild claims are recorded in its own
handoff and are not relabelled as tests executed here. Review PNGs are offline
mockups, not screenshots of the combined native build.

## Budget and deployment

Production explicit pool is90frames/91textures/150fontStrings, up from89/77/140.
All extra objects are created with the window; no driving/results allocation.
Developer Oval fixture includes its98 extra road/obstacle textures (189 total).
Gryphon sheet grows4→16MiB raw and outline1→4MiB; Celebration adds0.5MiB. This
15.5MiB potential raw-pixel increase is accepted for local visual testing;
actual client residency, overhead and loading hitch remain unmeasured. New
Celebration path and resized sheets require a full client restart on both PCs.
Rights/provenance status remains explicit in the asset ledger; no release claim.

Deployment hashes/backup/package receipt follow in [PROGRESS](../PROGRESS.md).
Next native task: restart, check Gryphon beat/glide and finish presentation,
then one same-player Play Again/map-change check when a friend is available.
