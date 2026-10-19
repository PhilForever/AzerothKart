# Technical architecture

## System boundaries

```
User input (WoW UI events)
        |
        v
 InputAdapter -> InputSample (bitmask per fixed tick)
        |                         |
        v                         v
 UIController/Scene        Pure Simulation (Physics/Track/Race/Items/PRNG)
        |                         |
        +<------ Immutable-ish render state / events
        |
 Renderer (pooled Texture/FontString objects, HUD and audio)

Optional multiplayer (behind measured gate):
 TransportAdapter -> ProtocolCodec -> Session/RaceAuthority -> state ingest
                               -> replay/anti-corruption checks
SavedVariables -> Schema/Migrations -> settings/personal-bests/ghosts
```

## Layering
- `Simulation`: math data only; pure-ish tick(state, input, track, parameters) -> new state/events. No game globals.
- `Track`: analytical/collision world, checkpoint gates, item/hazard spawn coordinates. Data-driven; explicit track version + checksum/hash for multiplayer and replays.
- `Race`: start countdown, running, finish, pause/abort, lap and checkpoint adjudication.
- `GameSession`: game mode, seed, participants, tick authority and reproducible event log.
- `Input`: front-end state sampling; clears stuck keys on focus loss/combat; keybind remapping requires API tests.
- `Renderer`: world-to-canvas transform; viewport/UI scale; textures from fixed pool; minimap optional.
- `Network`: transport rate budget, codec, protocol state machine, ACK/retry/recovery; not used by simulation tests.
- `Persistence`: schema v1 and migration; never serialize live per-frame state excessively.
- `Presentation`: pure render-pose interpolation and scalar HUD mapping; proposed scene navigation remains a separate future responsibility.
- `Diagnostics`: opt-in perf/FPS statistics, protocol rate metrics, error logs, feature gates.

## API interaction restrictions
`UI` and `Transport` are the **only layers** that call WoW APIs. No math library calls UI setters. Do not call secure/protected APIs or rely on secret-value readback. No special treatment of combat information is needed.

## Simulation clock
- Fixed dt = 1/60s; `OnUpdate` adds elapsed; execute at most 5 catch-up iterations/frame, then bound accumulator and record dropped simulation time.
- The simulation input sample for each tick is derived from current key state, not collected as raw frames.
- Active rendering interpolates previous/current positions using `clock.accumulator / clock.dt` and shortest-arc heading. This introduces at most one fixed step of visual delay, including frames without a simulation step. Start/Create and Stop draw the exact current pose; inactive updates and reopening retain it. Do not mutate physics through UI animation.
- Stop on focus loss/reload. Combat ends the game, closes the window and records an interrupted result once (ADR 0006); no automatic resume. Race results will freeze actual current standings when that engine exists. Anti-cheat timestamps cannot rely solely on mutable system time.

## Multiplayer architecture decision gates
- First local solo gameplay, then `NetworkProbe`, then synchronous lobby/ready/countdown without live karts.
- If capacity acceptable: host-authoritative room/session with locally predicted self kart and other-kart interpolation, measured bounded update cadence and snapshots; no naïve per-frame replication. Host may cheat or leave; communicate limitations.
- If not: asynchronous shared ghost challenges and personal bests, maintaining original modular gameplay.
- No eventual-consistency conflict should invent a race winner; if result cannot be verified, label "unverified".

## Visual performance budget
- Pool all kart/player sprite objects and HUD elements. No `CreateFrame`/`CreateTexture` per physics tick. No chat prints during motion.
- Data tables per tick are bounded and reused if Lua GC spikes; profile first, optimize second.
- For production tracks prefer atlas tiles at power-of-two dimensions and limited draw calls. Use no ripped assets.

## Public module APIs (proposed)
- `Physics.new(config, startPose)` -> state
- `Physics.step(state, heldInputs, dt, track)` -> state, collision flags
- `Track.isDrivable(track, x, y)` -> boolean; `Track.crossesGate(oldPos,newPos,gate)` -> bool, direction
- `Race.step(raceState, simState, events)` -> raceState/events
- `Protocol.encode(event)`/`decode(text)` validated under 255 bytes
- `Transport.send(session,msg,target)` with queue budget
- `Replay.record(inputs,seed,trackHash)` and `Replay.play(...)`

## Source map

An interrupted M0 drive keeps its terminal reason through repeated Close/toggle/hide/reopen. Rejected Start attempts show their refusal alongside the retained interruption note; they do not replace the result, state or timing sample. A successful fresh Start clears the note/result. This implements ADR 0006 using the existing UI objects, with offline regression coverage; the extended client sequence remains pending.

Combat-start events also hide a shown inactive window, including a completed sample or retained result. This path preserves the stopped clock/state/HUD/reason and emits no new interrupted-drive announcement. It handles events before the active-capture guard, safely ignoring combat before UI creation. Inactive OnUpdate remains idle, allowing deliberate combat-time reopen for note/Start-refusal inspection; combat ending never reopens or resumes the drive. This follow-up is tested offline, installed and loaded; actual combat verification remains deferred after the Oct19 stopped-window finding.

Current local M1: `Track.lua` (analytical road, surface classification and rectangular wall constraints), `Physics.lua` (version 5 progressive steering/drift/boost/grass response), `Input.lua` (physical held keys including Space, reused semantic samples), `Loop.lua` (fixed-step clock, cumulative elapsed and drop counters), `Performance.lua` (bounded scalar aggregates of injected timestamps), `Presentation.lua` (pure interpolation and meter mapping), `UI.lua` (client adapter/presentation), `Core.lua` (bootstrap/events/minimal schema marker). Both TOCs load these eight modules in that order. Pure modules optionally register into the explicit addon namespace passed by WoW and return their module for offline imports; they do not access `_G` or game APIs. Core alone exports `_G.AzerothKart` for manual diagnostics. M0 acceptance remains open; [ADR 0007](adr/0007-build-first-development.md) allows local mechanics development while long manual checks are deferred.

Physics stores normalized `steering` alongside the other thirteen state fields. It approaches a held turn at 8 units/s and centers at 16 units/s, resolving reversal through center before building the opposite sign; both raw turn directions force immediate zero. Raw input still cancels drift immediately, and new drift entry requires the progressive steering sign to agree. Wall contact resets steering; grass retains it. This adds no UI setting, object, input-capture behavior or client API dependency. Exact tuning and pending direct-play validation are recorded in [PHYSICS.md](PHYSICS.md).

`Presentation.pose(previous, current, alpha)` returns scalar x, y and heading, interpolating through the shortest heading arc without mutating either state or allocating a pose table. UI retains the actual state immediately before each fixed step, then renders between that and the latest state after catch-up. Input sampling, collision, drift, boosts, surface feedback and timing use actual simulation state; no interpolated coordinate becomes simulation input. Stop redraws the exact current pose without changing the frozen clock remainder. The renderer uses existing pooled objects and does not add per-frame chat.

Space samples a held drift intent. Physics alone owns charge, signed slip, boost ticks and current surface; rendering does not award boosts or resolve collisions. `Track.isDrivable` retains the road mask, while `surfaceAt` permits island/exterior grass within an 18-unit perimeter inset and `constrainPosition` preserves tangent motion by clamping each axis. Grass gradually reduces excess speed and clears drift/boost/slip; wall contact scrubs speed once per step. Pure test tracks without those optional helpers retain the predicate fallback.

The fourth pooled font string (`driftHud`) names Road/Grass/Wall and charge/tier/boost state at the existing quarter-second HUD cadence and immediately on Start/Stop. Kart tint changes only when its phase changes: orange normal, blue charging, gold tier 1, pink tier 2, cyan boost. Four pooled gray strips identify the perimeter. Stop freezes mechanics and prefixes retained feedback with `Last drive`; Start resets state. No tick creates UI objects or prints chat.

`Presentation.meter(state, Physics)` returns only a fill fraction and phase. Actual charge ticks determine readiness: 53 remains charging, 54 reaches Tier 1 at half fill and 108 reaches Tier 2 at full fill. Boost uses remaining ticks divided by the common 48-tick (0.8-second) capacity; shorter boosts therefore occupy less of the same scale. Grass/wall or cancelled charge maps to idle. UI draws a 300×12 meter using four textures and three font strings created once. Markers switch from Tier 1/Tier 2 to 0.4s/0.8s during boost, with a named phase caption and the existing text HUD retained. Fill follows actual ticks on active updates, without pose interpolation; unchanged phase/fill values avoid redundant setters, and zero fill is hidden. Stop freezes the meter and Start empties it. The window is 856×706; explicit allocations total six frames, 107 textures and seven font strings. New-layout/client appearance remains NOT RUN; historical 6/103/4 interpolation, 6/99/4 drift and 6/99/3 M0 counts describe prior source.

The primitive road uses the analytical Track radii directly: 64 gray outer-ellipse bands in BACKGROUND, then 32 grass island bands in BORDER, with the marker in ARTWORK and kart in OVERLAY. Construction retains the 96-road-texture budget; perimeter strips and the new meter bring the total to 107. Geometry is calculated only during UI creation; rendering a moving kart does not recreate the road or walls. Tests inspect actual mock texture geometry/layers against the unchanged road predicate. The raster approximation is documented in [TRACKS.md](TRACKS.md); it does not establish client performance.

Build 70450 exposed band seams and grass occlusion when snapping states differed within the default background sublayer. Isolated live hide/show and settings tests narrowed the earlier failure to this grass/road interaction; native batching mechanics are not established. `UI.Create` now places grass at `BACKGROUND,-1`, below the outer bands at default sublevel 0. Each of the 96 bands receives guarded bias `0`/snap `false` setters after color/geometry setup. These settings run only at construction, leaving grass snapping, marker/kart, geometry and the frame loop unchanged. Missing/throwing optional setters retain the basic renderer; explicit grass priority still applies. Normal reload, all 96 readbacks and seam-free appearance passed at effective scale 0.72452831268311. [Isolation and startup evidence](evidence/2026-10-19-m0-road-layer.md); full scale/performance acceptance remains open.

Profiling defaults off and is controlled separately by `/akart perf [on|off]`; no UI objects/settings persistence are added. While stopped, `on` validates one guarded `debugprofilestop` read and arms the next Start. A profiled Start creates a fresh scalar aggregate. The first 600 eligible active updates take three guarded readings around `Loop.advance`, then kart rendering plus the throttled HUD update; later callbacks make no profiler calls. The pure Performance module accepts timestamps in milliseconds, storing only attempt/valid/invalid counts and phase totals/maxima. Invalid, nonfinite, backwards or throwing readings consume the same attempt cap without affecting driving; failures in arithmetic validation are contained. No `debugprofilestart` reset is used. Stop/close/reopen freeze the aggregate; off retains it until a new Start. Reports are explicit, three lines, and the existing six-line `/akart probe` is unchanged.

Reported spans are advisory elapsed profiler milliseconds. They include instrumentation inside each span and omit input/focus guards, final aggregation/report formatting and native GPU work; they are not exclusive addon CPU attribution or a whole-OnUpdate benchmark. Shared timer resets can yield invalid backwards samples or occasionally plausible positive deltas that cannot be detected. A build-70450 stationary window supplied 600 valid samples and retained stopped/disarmed results; full performance acceptance remains pending. [CLIENT_API.md](CLIENT_API.md) records the generated contract, actual scoped results and remaining checks.

`Loop.advance(clock, elapsed, stepFn)` runs up to five 1/60s steps per render frame, drops only excess whole ticks and retains the fractional remainder. `clock.elapsedSeconds` sums valid elapsed values accepted by the clock. UI calls it only while driving, so the explicit probe labels this `activeFrameSeconds`; `simulatedSeconds` is `steps * dt`, and `callbackHz` is `frames / elapsedSeconds` (zero before elapsed time). These measure delivered callback time and cadence, not an independent wall clock, separately sampled whole-client FPS or addon CPU cost. `maxElapsed` records the largest accepted callback interval. Normal samples satisfy `elapsedSeconds ≈ steps * dt + droppedSeconds + accumulator` within floating-point/printed precision.

Tick input comes from `Input.sample(held, reusedOutput)`. UI sprites are created once; HUD text updates at a bounded cadence during driving and immediately at Start/Stop, so the stopped tick agrees with the probe and a fresh drive displays tick 0. The HUD's `Sample` duration is active callback time. Stop freezes every clock counter, including the fractional accumulator, without resuming simulation. Close/reopen retains that stopped sample; a deliberate Start creates a fresh clock. Probe output is explicit only, with no timed chat reports, automatic driving or additional UI objects. There is no production replay/PRNG yet. The offline seeded tape generator is test code, not a gameplay random mechanic. See PROGRESS for the next build task.

`UI` owns explicit capture and stop transitions. Unknown keys, text focus, any mouse click, hiding, world leave/logout and optional application-focus readback stop capture. Combat additionally records `UI.result` with interruption reason/tick, closes the window and emits one note; hide/reopen retains the result until a fresh Start. There is no M0 classification to freeze. Releasing on all clicks avoids assuming rectangle bounds identify an overlapping frame's focus. Missing required input APIs/global mouse event reject Start. Build 70450 has no observed `IsGameWindowFocused`; an idle Alt-Tab test stopped through the unknown-key path. The owner confirmed actual combat closure, interruption note and working WoW controls; repeated events, combat reopen and other unrun routes remain separate checks. Simultaneous W/Up is skipped at the owner's request for this keyboard, with offline alias coverage retained. Propagation restoration remains deferred in combat. `Race` and multiplayer remain reserved responsibilities.
