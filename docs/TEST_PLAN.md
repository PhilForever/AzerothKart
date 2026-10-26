# Verification and QA plan

Latest solo finish-record slice: run the focused Lua5.1 modules `highscores
solo_records ui menu race loop multiplayer_integration` using scripts/test_lua.py.
They cover exact total ticks, once-only finish, dropped-time eligibility versus
terminal remainder, full names/dates, compatible rankings, bounded storage,
malformed/future saves, native callback races/reentry and visible pooled menu
navigation. No broad dual-runtime rerun is required without a new concern.
The deferred native check and open global route are in [HIGHSCORES](HIGHSCORES.md).
Offline results do not prove native timestamp availability, restart persistence,
UI placement, frame cost or global delivery.

## Current start-clock slice

Executed Lua 5.1 focused commands and outcomes are recorded in PROGRESS. The changed modules use `--tests clock_protocol start_clock race_start race peer_session session_transport`; native lease/UI regression uses `--tests session_transport transport_probe ui`. Codec cases cover exact wire fields/bounds; pure clock cases include asymmetric synthetic 700 ms RTT, independent offsets, queued reply subtraction, retries/duplicates, malformed/conflicting packets, finite deadlines, late callbacks, reentrant outcomes and final-ACK ambiguity. RaceStart checks actual Physics/Race initialization, exactly-once/cancel/error handling and a 900-tick identical input tape. Native doubles cover both prefixes sharing a persistent budget, delayed delivery/five-second offset, scoped sender, exception/Stop cleanup and callback clock advancement. No client synchronization, clock drift, opponent movement, finish agreement or race feel is inferred. See [START_CLOCK](START_CLOCK.md); no new manual probe/download requested.

## Current session transport slice

Focused command: `python scripts/test_lua.py --runtime lua51 --tests session_transport peer_session transport_probe ui`. Real codec/controller with injected native APIs: explicit two-peer Host/Listen/Join/Ready/Start proposal, complete identity/compatibility, strict enum/capability refusal, bounded retries and copied state, persistent native call/byte pacing, no send from actions/Message, terminal lifecycle/drain and exclusive probe/session ownership. Include cancellation during native setup/send, pre-send guard cancellation and both directions of lease handover. Core routing/local-drive cancellation and unchanged pool/drive trace are covered by UI doubles. Native AZKART2/client menu/start-clock/race feel NOT RUN; no broad repeated matrix or new manual probe requested.

## Current bounded transport experiment

Focused command: `python scripts/test_lua.py --runtime lua51 --tests network_probe transport_probe ui`. It checks exact codecs, capped schedules/no catch-up, send outcome classes, same-clock deadlines/hitch-anchored drain, timing percentiles, sender/session/version/size validation, duplicates/reorder/flood limits, ACK-once/burst cap, four sequence maps and stale/fresh sessions. Adapter doubles cover no startup calls/UI allocation, guarded enum/prefix failures, lifecycle/error cleanup/no resume and bounded explicit output. Core/UI integration checks the real slash/event routing and unchanged race/input/pooling regressions. No synthetic result is a measured transport-capacity or client pass. See [the actual two-client checklist](../tests/MANUAL_NETWORK_CHECKLIST.md); PARTY/bidirectional/4/8-client and playable replication remain future work.

## Current Oval collision slice

Focused command: `python scripts/test_lua.py --runtime lua51 --tests track obstacles physics drift surface determinism mirage ui`. The obstacle module checks long-segment tunneling, head-on/reverse contact, tangent/corner/graze cases, stable release/recovery, perimeter compatibility, immutable geometry and a nonvacuous 900-tick tape with actual obstacle hits at 30/60/144 simulated render Hz across all fifteen fields. Existing 10k-tick replay remains in `determinism`. UI checks physical marker registration, actual fixed-step contact, hiding on Mirage and reuse through switches/updates. The obstacle-only pool was 9/113/13; the combined source adds38 pooled effect textures plus the Close results and Kart buttons, for11/151/13. No per-update UI objects are created. `presentation` and `ui` check the effects' atlases, emission, pooling, canvas bounds and unchanged simulation with effects on, refused or under the primitive kart, plus the kart roster, the picker's refusals and untinted art in every phase. These are offline checks. Actual obstacle appearance/handling and integrated Claude art are NOT RUN. Multiplayer has priority over dedicated ghosts/time trials under ADR0010.

## Current Capital Cities Cup slice (proposed, `claude/capital-cup`)

Focused command: `python scripts/test_lua.py --runtime lua51 --tests circuit menu ui`; geometry and art bytes: `python scripts/build_city_tracks.py --wc3 WC3 --check` (needs the Warcraft III files extracted as in [the Stormwind sheet](art/tracks/stormwind.md#rebuilding)). `tests/test_circuit.lua` builds a small street circuit and the generated Stormwind circuit: road, kerbside strip and wall surfaces; a step into a wall ends at it and slides along it with a hit; the plaza is open paving and its statue blocks with the usual clearance (a fixture: Stormwind has no plaza or solid); recovery from outside the street; 4,000 random steps near walls never move further than requested or end in a wall; the catalog's cups, coming-soon entries (none left once Thunder Bluff is ready: it is marked soon for one check), Track button cycle and kept builds; a walk of Stormwind's course passes the six district gates in order, completes the lap's checkpoints and never meets a wall, and so does Ironforge's with its seven, then throttle from Ironforge's grid stays on the road; Orgrimmar's walk passes its four gates in order with a wall-free centerline, its gates close the street at both ends, and throttle from its grid stays on the road; so do Darnassus's six and Undercity's five (Undercity's walk starts on the loop: it has no approach road); Thunder Bluff's six (proposed on `claude/thunder-bluff`; on `claude/drive-fixes` its version 2 grid stands on the loop, facing the way the course runs, with the finish line just ahead), each of its six rope-bridge narrows road to its own wall at 54, and both new cities' proposed street heights have one finite value per centerline and branch point while the flat cities carry none; reviewed `narrows` (Ironforge version3): a narrowed square side is road to its own wall, invalid narrows are refused; closing-segment numbering, minimum overlap radii, independent metadata copies and unchanged branches are covered; Ironforge's two Forlorn Cavern tunnels have road then wall either side with shoulders kept before them, and steering into a tunnel wall registers impacts without ending a step in it (`tests/test_circuit_boundary.py` adds the narrow/wide join vertices); a Physics drive up the approach stays on the road, and steering into a wall registers impacts without leaving the street. The generator validates the layout before painting (gates span wall to wall and guard one stretch, separate stretches keep a wall between them, spawn, solids, world bounds, nothing drawn over the street). `tests/test_ui.lua` and `tests/test_menu.lua` cover the pooled counts (79/166/81 in the integrated build), gate visibility, safe background refusal, preference restoration and the Track button's cycle through the seven tracks (Orgrimmar's four gates in the gate-pool test; a fixture is the coming-soon example since Thunder Bluff is ready). Loading the 2048-square scenery, the drive, the camera and the menus in the client are NOT RUN; see [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md).

## Current Scarlet Crusade Cup slice (proposed, `claude/scarlet-graveyard`)

Focused command: `python scripts/test_lua.py --runtime lua51 --tests dungeon circuit menu ui`. Geometry and art bytes: `python scripts/build_dungeon_tracks.py --wc3 WC3 --check`, which needs the Warcraft III files extracted as in [the Scarlet Graveyard sheet](art/tracks/scarlet-graveyard.md#rebuilding).

`tests/test_dungeon.lua` builds a small synthetic crypt:

- stone, lawn and wall surfaces;
- a step into a wall ends at it and slides along it with a hit;
- a doorway joins two rooms;
- a grave blocks with the usual clearance and slides the kart along its face;
- recovery from off the floor;
- 4,000 random steps never move further than requested or end off the floor;
- invalid definitions are refused.

It then runs a one-run sprint race to "Sprint complete" and checks the one-run score context against the oval's three-lap one. It checks the third cup and its coming-soon courses, and the Track button's cycle. A walk of the Graveyard's reviewed route crosses its three gates in order and never meets a wall or a solid, and full throttle from the grid launches cleanly.

`tests/test_ui.lua` drives a whole sprint through the UI: three gates, the sprint captions and summary, and a saved score with lap count 1. `tests/test_menu.lua` covers the third cup's heading and buttons, the 2:1 preview, the race lines and the sprint board's rule line, at 90/167/136.

The generator refuses a layout unless:

- the rooms are inside the world;
- the spawn is on stone;
- every solid is on the floor;
- each gate is axis-aligned, reaches the walls and is unavoidable, by a flood fill with the gate as a barrier;
- the route crosses the gates in order;
- (on `claude/drive-fixes`) no invisible wall: wherever the karts' floor ends, the picture's masonry lies within the inset and 3 units, measured square (`hidden_walls`);
- (on `claude/drive-fixes`, when painting) no model that is not solid has its drawn body more than 3 units onto the kart centre's floor (`dungeon_paint.check_props`).

On the installed Graveyard (version 1) the new rules flag the places in the owner's screenshots: the floors of the Chamber of Atonement and the west hall meeting without a wall, and 17 props, among them the armour rack on the stairs and the ghost on the path. The Library as first proposed had 71 such props. Both rules pass for the Graveyard's version 2 and the Library on `claude/drive-fixes`. `tests/test_dungeon.lua` checks that the karts leave the chamber west only by its door (version 2), and the Library's lawn at a point clear of its now-solid bushes.

On `claude/scarlet-library`, `tests/test_dungeon.lua` also covers round rooms (`shape="disc"`):

- a rotunda's floor to its round wall;
- a doorway into it;
- a step into the wall that slides round it;
- 2,000 random steps that never end off the round floor;
- refused shapes.

It walks the Scarlet Library's reviewed route through its five gates in order, crossing back over Loksey's line once on the way out, never meeting a wall or a solid, and checks a clean launch and every solid. The menu tests follow the Library into the Track cycle, its square preview and its sprint board. The rebuild commands are in [the Scarlet Library sheet](art/tracks/scarlet-library.md#rebuilding).

On `claude/scarlet-armory`, `tests/test_dungeon.lua` walks the Scarlet Armory's reviewed route through its five gates in order (Training Grounds, Footman's Armory, Crusader's Armory, Hall of Champions, Herod), never meeting a wall or a solid. It also checks:

- a clean launch east from the grid, and every solid;
- the Training Grounds' yard as grass inside its stone walks;
- the round Hall of Champions to its wall;
- Herod blocking on the finish line, with stone either side of him.

Only the Monastery is coming soon. The menu tests follow the Armory into the Track cycle, the cup's rows, its square preview and its sprint board. The generator now checks the floor just past each gate all along it (Herod stands on the finish). `build_dungeon_tracks.py --check` keeps the Graveyard's and the Library's data and pictures byte for byte after the painter's new layers. The rebuild commands are in [the Scarlet Armory sheet](art/tracks/scarlet-armory.md#rebuilding).

On `claude/scarlet-cathedral`, `tests/test_dungeon.lua` also covers round solids (`shape="disc"` on a solid), with a pond:

- the pool is wall to its rim, its square's corners floor;
- a kart driving at it head on stops at its reach, and one passing clear never meets it;
- one pushing past it slides round it and on;
- a centre inside it leaves along the radius;
- 2,000 random steps never end within its reach;
- invalid solid shapes are refused.

It walks the Scarlet Cathedral's reviewed route through its four gates in order (Chapel Gardens, Upper Gardens, Crusader's Chapel, High Altar), never meeting a wall or a solid. It also checks:

- a clean launch west from the grid, and every solid, the round pool's centre included;
- the lawns as grass and the walks as stone;
- the three pools blocking to their rims;
- the finish across the chancel;
- a kart stopped at the round pool's reach and sliding round its rim.

No course is coming soon now. The menu tests follow the Cathedral into the Track cycle, the cup's four rows, its twice-as-tall preview and its sprint board. `build_dungeon_tracks.py --check` keeps the Graveyard's and the Library's data and pictures byte for byte after the painter's pools and parquet; the Armory's picture changes only with Herod's new model. The rebuild commands are in [the Scarlet Cathedral sheet](art/tracks/scarlet-cathedral.md#rebuilding).

`test_score_sharing` needs Codex's score-sync change (the patch is in Claude's handoff). The drive, the lawn, the picture and the camera in the client are NOT RUN; see [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md).

On `claude/scarlet-fixes` (the three courses' version 2, after the owner's first drive), `tests/test_dungeon.lua` checks:

- the Library: four gates, none in Loksey's kennel, which stays open floor; the route through them in order; the courtyard's cross path clear where version 1's huntsman stood;
- the Armory: every room `road` (the yard no longer slows); at least fourteen solids in the yard (its dummies, targets, backstops, bushes and flowers); open flags between the dummies; the route straight through the yard;
- the Cathedral: every room `road`; eleven round solids (the round pool, the trees' and bushes' crowns); the plinths `wall` and the stairs floor; a kart driving north at a plinth's face stops at it, and one driving up the stairs runs clean into the upper garden; a kart driving at a tree stops at its crown's reach, not at its trunk.

`build_dungeon_tracks.py` validates the new layouts (gates that cannot be passed round, the plinths as walls, no invisible wall, nothing non-solid on the floor) and keeps the Graveyard byte for byte. The full Lua 5.1 suite and the score catalogue's check cover the three new versions. The drive, the yard's look, the plinths and the trees in the client are NOT RUN.

## Current front-end slice (proposed, `claude/ui-flow`)

Focused command: `python scripts/test_lua.py --runtime lua51 --tests menu ui presentation`; art bytes: `python scripts/build_ui_art.py --check`. `tests/test_menu.lua` runs the addon against a widget mock that passes Show/Hide on to child frames, like the client. It covers the main menu and one dialog at a time; browsing without changing the run, track or kart; the Single Player flow, including a refused start; every results path, the track view and the lap list; the garage turntable; settings (sizes that do not fit, effects off, sound mute); saved preferences, failed restores and unknown or newer records; the coming-soon lobby and a mapped PeerSession view; Alt+Z versus a real close; the combat track restore; the build fallback; and missing templates. `tests/test_ui.lua` keeps Codex's assertions; only its counts, module list, results-panel size and a Lua 5.4 `unpack` call changed. Explicit counts become 65 frames/160 textures/79 font strings (11/151/13 without the front end). The menus' client appearance and sounds are NOT RUN; see [the front-end client check](art/ui/front-end.md#client-check-not-run).

## Current build-first cadence

The owner requested about 80% less testing on 2026-10-19 ([ADR 0007](adr/0007-build-first-development.md)). Build local M1 slices with one targeted Lua 5.1 check and cheap relevant structural validation. For the current drift tuning slice, target physics, steering, drift, surfaces, presentation and UI in one focused Lua 5.1 pass. Check 30/60 charging-tick tiers, twelve paused correction ticks versus cancellation on tick thirteen, resuming opposite steering without lost charge, valid release during correction, immediate brake/slow/rough-ground/wall cancellation, gentler drift yaw with ordinary yaw unchanged, pause text/fill retention and all fifteen state fields in the seeded replay. Keep the earlier map selection/reset/failure-retention and pooled-scene assertions; no new art export is needed. Broad dual-runtime, long manual scale/profiling and stress matrices below are deferred until a concrete failure/risk or integration checkpoint. M0/M1/M3 acceptance remains open; deferred checks are NOT RUN, not waived passes.

The v3 drift slice passed focused Lua 5.1 physics/input/UI checks (17 files parsed) and a separate drift run covering charge thresholds, signed slip, cancellation, boost bounds/duration and a 720-tick tape at 30/60/144 schedules. The v4 surface slice added road/grass classification, gradual forward/reverse slowdown, road recovery, cancellation on entry and tangent wall/corner response. Version 5 introduced progressive steering and immediate raw-input drift cancellation. Version 6 retains that ordinary steering response but replaces immediate drift cancellation with bounded correction grace and faster charge tiers. Current presentation coverage targets clamped scalar positions, shortest-arc heading, exact endpoints, unchanged simulation states and namespace purity, plus meter readiness at charge ticks 29/30/59/60, retained fill during corrections and boost fractions on one 48-tick capacity. UI coverage includes zero-step/catch-up interpolation, exact stopped/fresh-Start poses, meter fill/phase caching, empty-fill hiding, retained stopped feedback and stable current 9/111/13 explicit object counts. See PROGRESS for exact executed commands/results and the next build task. Human steering/handling/layout/interpolation/meter/countdown/finish appearance, Lua 5.4 and the complete suite are **NOT RUN this slice**. The [short Mirage first-load probe](FEASIBILITY.md#mirage-blockout-first-load-probe) records custom-texture/viewport checks separately from future transparent-sprite alpha and atlas UVs.

Checkpoint coverage targets strict directional finite-segment crossings, endpoints, rejection of backward/parallel/zero movement and departures from the line, ordered four-gate terminal progress, duplicate/stale/gapped ticks, finite movement bounds, reset/retention and same-input fixed-step replay. Laps coverage targets initially empty best fields, first completed-lap assignment, strictly faster replacement, equal/slower retention with earliest lap number, rejection of incomplete laps, reset/retention and repeated circuits, exactly one award per accepted finish, immediate rearming, exact integer current/last durations, clock advancement without malformed-movement awards, duplicate/gap rejection, immutable state and render-cadence equivalence. Race coverage targets exact 180-tick countdown and 3/2/1/GO boundaries, GO timing-origin reset, the fixed three-lap finish, exact total/finish ticks, retained terminal object identity and partial stopped/interrupted results with explicit module dependencies. Loop coverage targets callback cancellation after a counted step, fractional-remainder/drop accounting and no false hitch on ordinary finishes. UI integration targets sampled held input with neutral countdown physics, spawn retention until GO, first driving input at tick 181, GO visibility for racing ticks 0–59, phase-cached cue writes, hitch/drop behavior without skipped countdown, zero elapsed stopped/interrupted countdown results, fresh-countdown restart, actual physics coordinates rather than interpolation, next/passed gate feedback, completed/current/last and best lap HUD values, best text in finished/stopped/interrupted summaries, retained best on reopen/rejected Start and empty best after fresh Start/GO reset, exact finish pose, release of capture, no extra catch-up physics steps, stopped/combat/reopen result retention, rejected/successful restart and pooled setters/allocations. A rejected consecutive oversized movement consumes its tick to allow recovery; these guards do not prove an entire valid road route or establish anti-cheat. This covers an in-memory best within one run; no saved personal record across runs, save, ghost or remote winner comparison is under test. Record only commands actually executed in PROGRESS.

## Testing layers

Mirage camera coverage checks a full-canvas uniform zoom, bounded heading look-ahead and world-edge clamps, upright UV cropping, clipped gate/wall rectangles, interpolated-pose following without simulation mutation, frozen Stop/reopen and restart behavior. Missing/erroring crop APIs preserve the stopped fallback result. The stopped client crop and Start/West marker placement were observed on build 70450; motion, edge transitions, handling and sustained allocation/performance checks remain NOT RUN. See [the scoped evidence](evidence/2026-10-20-mirage-camera-static.md).

1. **Static pack validation:** expected files, synchronized TOC module order, discovery markers and protocol documentation via `python scripts/validate_project.py`. It does not execute Lua or establish API limits.
2. **Offline suite, integration checkpoint:** `python scripts/test_lua.py` parses all addon/test Lua and executes the complete suite in Lua 5.1 and 5.4 via pinned Lupa; `--tests` selects focused modules for normal slices. Includes analytical track checks, handling/drift, alias-safe input, bounded hitch/elapsed accounting, pure profiling aggregates, synthetic 60-second schedules, 10k-tick replay equivalence and mocked UI/Core lifecycle/allocations/combat guards. Timing regressions check frozen stopped samples, fresh Start resets, immediate Start/Stop HUD updates and explicit probe values. Synthetic durations/cadences are not observed client FPS or performance. Record each executed command and result in `PROGRESS.md`; native `lua tests/run.lua` and optional Linux `python scripts/test_with_lua54.py` support the complete suite when needed.
3. **Simulation property tests (later):** multiple seeded driving scenarios, lap gate order, no teleport-finish, hazard events and track/physics compatibility. The current seeded input tape proves same-runtime replay equivalence for its one tested seed, not cross-client floating-point identity or handling quality.
4. **Protocol/unit test doubles (to build after M2):** fake transport reorder, duplicate, loss, throttle, sender spoof, malformed/saturated packets, session mismatch and bounded retry.
5. **Manual Forever client tests:** visible load, UI, focus, keyboard controls, combat, reload, zoning, high UI scale, 20-minute continuous play, and 2-client network probe.
6. **Performance regression:** FPS and Lua memory before/during/after 8 visual karts; total UI objects stable after 30 minutes.

The mocked combat lifecycle also covers repeated Close/toggle/reopen and rejected Start attempts: the interruption note and terminal result stay retained, refusal text remains visible, and only a successful fresh Start clears them. Those assertions are separate from actual-client acceptance.

Road rendering regressions inspect the textures actually produced by `UI.Create`: 64 outer bands, 32 island bands, explicit grass sublevel below the road and canvas bounds. A dense grid compares the painted footprint with `Track.isDrivable` outside the documented 3.5-unit vertical raster margin and checks the former mismatch at `(400,440)`. Checks require creation-only band snapping, unchanged grass snapping and no reconfiguration during updates/reopening; missing/throwing optional setters cannot stop driving. Existing allocation and deterministic replay tests still apply. Mock configuration checks do not establish display correctness; actual source-only reload acceptance is recorded separately.

The Performance unit test covers phase totals/maxima, zero-resolution samples, missing/malformed/nonfinite/negative/backwards readings, finite sum overflow, namespace purity and the 600-attempt cap including invalid samples. UI integration verifies no profiler reads by default, reachable slash commands, active-change refusal, guarded arming, three reads per sampled update with no calls after the cap, frozen stopped/reopened aggregates, fresh Start reset and stable current 9/111/13 UI counts. An identical 650-update driving tape produces identical state with profiling on/off. Reader errors and validation/arithmetic refusal stay bounded and cannot stop simulation. Mock timings prove accounting only, not actual client costs.

## Deferred manual acceptance suite
- A. Addon shows up with correct TOC and `/akart`; no Lua error.
- B. Press **Race!** (menus) or **Start Race** (bar) out of combat, test W then Up, S then Down, A/D then Left/Right; car moves and rotates, stays near oval. Simultaneous W/Up is SKIPPED at the owner's request for this keyboard; offline alias coverage remains.
- C. Release keys and move chat focus: no character movement blocked after closing racing UI.
- D. ESC and close button both release game, toggling with `/akart` works; Alt-Tab and `/reload` safe.
- E. Attempt while in combat -> no keyboard capture; if combat begins mid-race no restricted API calls/taint.
- F. Run 15 min, resize UI scale, record FPS and memory. Confirm no per-tick widget creation.
- G. M0 SavedVariables: isolated sentinel across reload/logout/restart and inactive capture after load. Corrupt-save handling/migrations for actual settings/records remain later milestones.

Build 70450 has scoped [stationary profiling](evidence/2026-10-19-m0-stationary-profile.md), [road-layer startup](evidence/2026-10-19-m0-road-layer.md) and [917.598-second stopped/open idle](evidence/2026-10-19-m0-idle.md) evidence. The later [normal-scale attempt](evidence/2026-10-19-m0-scale.md) is INCOMPLETE: timed acceptance expired, original preferences returned but effective scale differed. No accepted alternative renderer or exact effective-scale restoration pass exists. Further setting changes stopped for review. The prepared read-only geometry snapshot in client-checklist section 3d is deferred under ADR 0007; it does not block local M1 work. Current dimensions cannot establish unmeasured baseline dimensions. The ten-minute drive, three-drive timing protocol, fresh unprofiled Start, supported-scale/stress matrix, sustained FPS, memory/CPU and full focus/taint/performance acceptance remain **PENDING**. No extra combat or skipped simultaneous W/Up test is requested.

## Developer install helper fixtures

Run from the repository root in each available runtime:

```powershell
powershell.exe -NoProfile -File tests/test_install_local.ps1
pwsh -NoProfile -File tests/test_install_local.ps1
```

The suite uses temporary workspace AddOns fixtures, not the installed game or SavedVariables. Cover fresh installation and repeated installation into the same addon target; refusal of existing targets without `-Overwrite`; zero writes for `-WhatIf` and declined confirmation; prior-tree backup and SHA-256 manifests; copied-file verification; and preservation/reporting of unknown target files. Exercise preflight rejection and a controlled copy failure, checking that the retained backup is usable and the failure record does not imply a verified target. A manual restore rehearsal must verify recovered fixture-file hashes and acknowledge any additional files left by an interrupted overlay.

The helper is a file overlay, not an atomic update or automatic rollback. No source Lua, race, UI, migration or multiplayer acceptance follows from passing these fixtures. Record the executed commands, runtime versions and exact outcomes in `PROGRESS.md`; do not infer a second runtime pass or a game install from one run. See [developer install and recovery](RELEASE.md#developer-install) for the intended operator workflow.

## Network testing (M2, when implemented)
- Distinguish sender enqueue success vs receiver ACK. Send small packets 0.5–4/sec during consented test only.
- Validate 2 players first; then 4; then 8 if realistic. Measure p50/p95 RTT, ACK timeouts, reorder/duplicates, arrival gaps, throttle returns, message counts and recovery. Missing ACKs do not uniquely prove packet loss.
- Repeat instanced and non-instanced; record client build, connection, channel, payload bytes and conditions.
- Fail behavior: leave button still responsive, no stale winning result, no infinite retransmits.

## Release blocking bugs
Key capture not released; combat taint; corrupt SavedVariables crashes; lap skips; irreversible stuck state; cheating other players via spoofed packets; unbounded memory/packet sends; accidental prohibited automation.

## Record actual evidence
Never mark tests passed without running them. Include command logs, screenshots if user supplies them, exact client build and reproducible steps in `PROGRESS.md`.

## Stormwind exposed-wall regression

Run `python tests/test_circuit_boundary.py -q` (standard library) and focused `python scripts/test_lua.py --runtime lua51 --tests circuit physics surface obstacles ui`. Python covers exposed line/circle junctions, tangencies, covered intersections, deterministic order and the actual white-wall apex. Lua covers the reported(442,849)→(445,846) passage, open(450,850) wedge,14±0.1 centre clearance/real contact, unchanged straight walls, reachable projection/tangential slides and an actual full-speed Physics drive. Geometry-only rebuild/check uses `python scripts/build_city_tracks.py --wc3 . --geometry-only [--check]`; the current no-solid city needs no model archive for that scope. Full art regeneration and native corner handling remain separate checks.
