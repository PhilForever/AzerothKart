# Scarlet v2 and kart stat bars — reviewed integration

**Published and installed:** runtime `da292f6`, `codex/scarlet-stats-review`.
Both original Claude branches also published; exact remote tips verified.
Deployment verifies84source/installed files and84complete prior backup files;
the matching installed-file friend ZIP and receipts are recorded in PROGRESS.
Native checks remain pending after full client restart.

## Source and disposition

Approved for source integration, publication and the owner-requested install.
Codex base `98f433e` includes the verified installed runtime9c80746. Claude's
six-commit stack is `claude/scarlet-fixes`8889aa4 followed by
`claude/kart-stat-bars`e122120. The combined `codex/scarlet-stats-review` keeps
both original histories and merges without conflict. No other worktree is
switched, reset or overwritten; existing untracked outputs remain intact.

Two independent read-only reviewers found no blocking issue in the Scarlet
geometry/gates or stat-bar math, layout, loading/fallback and ownership.

## Reviewed behavior

- Library version2 removes the path huntsman and Loksey checkpoint; the kennel
  stays accessible as an optional room. Its kerbed lawns retain rough handling.
- Armory version2 redraws the Training Grounds and gives the yard full grip.
- Cathedral version2 gives the gardens full grip and separates the garden floors
  at raised plinths so the two stairs beside the falls are the route upward.
  Tree/bush collision follows explicit generated round solids around drawn
  crowns; large pillars and yard props block where drawn. The generator retains
  ordered-route, unavoidable-gate and visible-wall checks. Its offline footprint
  measurement produces data; no runtime texture-reading collision is added.
- Graveyard data/art and the swept-disc solver are unchanged. Slender-prop
  overlaps listed in Claude's handoff remain a native visual-review limit.
- Library/Armory/Cathedral use geometry version2 in the eleven-board catalogue.
  Existing version1 records stay saved as separate contexts. No migration or
  deletion, new score codes, native packet changes or multiplayer-sprint claim.
- The kart chooser and Garage show four original gold-framed segmented bars
  from detached `Physics.GetHandling` values: Speed, Acceleration, Turning and
  Braking. Balanced fills4/4/4/4; Heavy5/2/2/6; Agile3/6/6/2. The proportional
  scale changes one of six windows per4%, without changing handling.
- Atlas loading is guarded once on the first visit. A refused load hides all
  bars, keeps the descriptive text and does not retry. Eight textures and four
  labels are created with the window; production pool89/77/140. The legacy
  developer Oval fixture reports89/175/140. No driving-time object creation.
- Dungeon/UI/Presentation/Physics/SoloRecords/Highscores/ScoreSync/ScoreSharing/
  SessionTransport implementations remain unchanged from the Codex base.
  Existing remote-turn smoothing, collision penalty, discovery leases, retired
  Oval and eleven-course158-byte score ceiling are preserved.

## Executed validation

Actual combined source commands:

- `scripts/test_lua.py --runtime lua51 --tests dungeon menu ui circuit score_sharing presentation`:
  **PASS**, all six modules and80Lua files parsed. This exercises changed room/
  gate data, menu layout/preferences/fallback, the declared object budget,
  eleven-course score catch-up and retained opponent heading/position behavior.
- `scripts/export_score_catalog.py --check`: **PASS**, eleven canonical boards
  with the three new version2 contexts.
- `scripts/build_stat_bars.py --check`: **PASS**,131,090bytes, SHA256
  `f1528efd5d9f8891f735f8393bbc7e1983d512f8e66f584a9710d2038f896131`.
  Original stat-bar preview was visually inspected; native fonts/appearance
  remain unverified.
- Working/staged `git diff --check`: **PASS**. Structural validator still fails
  only on the two historical expired skill links in PROGRESS, not a full pass.
- Independent deployment preflight checks the installed prior manifest and
  current source/TOC shape before replacement; exact backup/install/package
  evidence is recorded after deployment in PROGRESS and the Codex handoff.

Full-suite/dual-runtime repetition, Python service tests and city/dungeon image
regeneration were **NOT RUN by Codex for this slice**. The source scope is
bounded and the focused checks cover its changes. Claude's full-suite/rebuild
claims remain attributed evidence, not new Codex passes. Native appearance,
grass/pool/stair feel and matched-build score delivery remain **NOT RUN**.

## Publication and test handoff

Publish this combined branch and the two exact original Claude tips with
normal create/fast-forward pushes. Preserve main and all other branch histories;
no forced push, release or author rewrite. Install only the tested combined
source with complete previous-addon backup and independent SHA256 verification;
preserve the legacy extra and all player data. Package installed tested paths
as a matching friend ZIP. `Assets/UI/StatBars.tga` is new, so both clients must
fully exit/relaunch after updating. No client automation is required.

Next native check: drive the three revised Scarlet courses, especially the
Cathedral's stairs and the Armory yard, then inspect each profile's four bars
in the kart chooser/Garage. Verify matching-build score catch-up separately;
source review does not complete global discovery, eight-racer or release gates.
