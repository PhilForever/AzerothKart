# Implemented simulation and rendering contracts

**Checkpoint:** 2026-10-21, `codex/peer-session` based on `d857ce2`, retaining combined rendering/runtime `8195da9` and Forever transport correction `8f66c5a`, plus the pure control codec and session controller. Physics compatibility version remains **7** (v6 handling retained). This describes the local solo prototype, measured transport experiment and offline control foundation; it does not claim a released engine or playable multiplayer. See [PROGRESS](PROGRESS.md) and [the latest handoff](handoffs/codex-latest.md).

## Status and ownership

The interfaces below exist in source today. `Renderer`, `GameSession`, collision-event streams, velocity vectors, a replay API and production synchronization adapters do **not** exist. The standalone NetworkProbe/TransportProbe experiment and the pure RaceProtocol/PeerSession control foundation described below are implemented; none feeds authoritative simulation state. There is no native session adapter or multiplayer menu yet. Proposed architecture sketches in [ARCHITECTURE](ARCHITECTURE.md) must not override the signatures here.

- **Codex:** Physics, collision/surface queries, Input sampling, Loop, Checkpoints, Laps, Race, deterministic simulation and their tests; experimental transport/accounting, RaceProtocol, PeerSession and future synchronization.
- **Claude:** visual rendering, camera/presentation helpers, track imagery, HUD, sprites, animations/VFX, asset tooling and their focused visual tests.
- **Shared:** public interface changes, accepted architecture decisions, integration coverage, performance budgets and TOC load-order changes. Coordinate explicitly before editing the other owner's code.

[`UI.lua`](../addon/AzerothKart/UI.lua) currently mixes both responsibilities. Its drawing/layout/rendering/HUD helpers belong to Claude; capture, Start/Stop/combat transitions, track-selection lifecycle, `step`, `OnUpdate` clock orchestration and authoritative-state assignment belong to Codex. Coordinate any shared-file edit by function area before working. `SelectTrack` includes both asset validation and lifecycle reset, so changes there require coordination. There is no standalone renderer entry point to call or replace yet. Extracting one would be a separately agreed change.

## Modules and data access

The two TOCs load `Track`, `MirageRaceway`, `Physics`, `Input`, `Loop`, `Performance`, `Presentation`, `Checkpoints`, `Laps`, `Race`, `UI`, `RaceProtocol`, `PeerSession`, `NetworkProbe`, `TransportProbe`, `Core` in that order. Pure modules receive `local _, namespace = ...`, optionally register their module on that explicit table, and return it for offline loading. They do not access WoW globals. Core exports the same namespace as `_G.AzerothKart` for diagnostics.

The current render path reads `AK.UI.state`, `.previousState`, `.race`, `.laps`, `.checkpoints`, `.track`, `.trackId`, `.clock` and `.active`. These are mutable Lua tables exposed for integration/diagnostics, **not enforced read-only objects or security boundaries**. Treat them as borrowed read-only references in rendering: do not add, remove or alter authoritative fields, normalize headings in place, alter input, call a simulation step, or assign interpolated/camera coordinates back to them.

`UI.laps` aliases `UI.race.laps` during a run; `UI.checkpoints` aliases `UI.laps.checkpoints`. A fresh state replaces those references after each accepted step. Cache scalar values for visuals when useful; do not retain an old table and assume it is live. `UI.result` is a small terminal summary (`status`, `reason`, `tick`, and terminal `totalTicks`/`completedLaps`), not the full race object. `UI.race` remains the source for lap details. `UI.previousState = UI.state` on Stop ensures an exact terminal pose.

## Implemented opt-in transport experiment

**Measured checkpoint, 2026-10-21:** AKT722/723 completed the scoped directed traffic windows. [AKT724/725](evidence/2026-10-21-akt724-akt725-recovery.md) then demonstrated listener addon reload to Idle, sender ACK-deadline stop and successful explicit fresh-session rearming (19 accepted DATA/unique receipts and 19 accepted/matched ACKs). This is not full socket-disconnect or automatic-rejoin evidence. [ADR 0013](adr/0013-two-player-experiment-scope.md) permits the bounded control implementation; production replication and gameplay acceptance remain open.

`/akart net help` prints six bounded local guide lines through `TransportProbe.Help()` without arming, registering, sending, or changing an existing experiment. There is no connection-test GUI. The [human-facing guide](NETWORK_QUICK_START.md) separates the two player roles from developer evidence requirements.

`NetworkProbe.lua` is pure injected-time/accounting code: `canonicalName(value) -> name|nil`, `new(options, now) -> state,error`, `update(state,now,sendFn)`, `receive(state,now,prefix,payload,channel,eventSender,sendFn)`, `stop(state,now,reason)`, `encode/decode`, `summary(state)` and `evidence(state,kind)`. Unlike immutable Physics snapshots, experiment state mutates bounded counters/maps in place. `sendFn(kind,payload)` returns explicit accepted/failed/unknown/throttled outcome plus a sanitized raw API result; the engine contains callback errors. Summary uses nearest-rank RTT/gap percentiles, sample counts and `NA` with no samples. Receipt, local enqueue and deadline evidence remain separate.

`TransportProbe.lua` is the WoW boundary: `Init(existingCoreFrame,reporter?)`, `Command(argument)`, `Update()`, `Message(prefix,payload,channel,eventSender,...)`, `HandleEvent(event)`, `Stop(reason)`, `Report()` and `Evidence()`. Core adds `/akart net ...` routing and forwards the complete addon event payload. Only the first four event arguments are consumed. The adapter reuses Core's existing non-UI event frame; its OnUpdate is probe-owned only while armed. It registers prefix/CHAT_MSG_ADDON_LOGGED on explicit arm, then removes its update/event subscription on stop. No new Frame, race capture, UI callback or simulation field is added. Inactive startup performs no prefix registration or packet calls.

Options: directed `send` or `listen`, complete Forever first-name/surname peer (no realm), fresh six-uppercase-alphanumeric session ID, rate 0.5/1/2/4, DATA bytes 16/64/128/220, integer duration10–120. Defaults 0.5/16/120. `canonicalName` caps the raw string at 96 bytes, rejects control/DEL/pipe characters and trims/collapses ASCII spaces only. Store the canonical full name; compare the complete event sender with ASCII case folding only, preserving punctuation/hyphens/UTF-8. Quoted names are recommended; unquoted names are accepted when the session is unambiguous, including all-numeric codes. Sender/listener must be explicitly armed; there is no peer negotiation/authentication. Same-process reuse of up to 64 remembered IDs is rejected; reload clears history and requires a genuinely fresh ID. PARTY, simultaneous bidirectional DATA, fan-out and replication are not implemented.

The adapter explicitly uses `C_ChatInfo.SendAddonMessageLogged` and `CHAT_MSG_ADDON_LOGGED`, following IOU's previously client-tested Forever route ([ADR 0012](adr/0012-forever-logged-transport.md)). `TransportProbe.ROUTE` and reports use `WHISPER_LOGGED`, also the CSV `channel` label; the native API channel remains `WHISPER`. There is no fallback. Actual chat lockdown, when available, refuses/stops the probe; absent APIs, unreadable/unknown results and native failures retain fail-closed behavior. IOU's basic round trips are not Azeroth Kart sustained capacity evidence.

At most 480 sequences, one due DATA per update/no catch-up bursts, one 16-byte ACK per unique valid DATA, four-token ACK bucket refilling 4/s, no retries. Codec/envelope details are in [PROTOCOL](PROTOCOL.md). Five-second ACK deadlines stop DATA and allow ten seconds of drain, anchored to original send/window time even after a callback hitch. Listener arming expires 30 seconds without first DATA; active unique-DATA idle expires 5 seconds, while normal completion has a separately bounded drain. Source-matched enum failures, unknown/throwing results, throttle, flood limits, invalid/backwards clocks, cancel, combat/world/logout/reload or local driving stop the probe. The [first completed live window](evidence/2026-10-21-akt722-network-window.md) demonstrates raw prefix/send success0 and 59 reconciled DATA/ACKs at 0.5/s,16 bytes; the later 2-DATA/s window and addon reload/fresh rearming are recorded in the current checkpoint below; unobserved result paths, full socket recovery and racing acceptance remain unverified.

Explicit reports contain raw registration/send categories and rejection reasons without peer identities, counters and timing aggregates/sample counts. `aggregate_attempted_bytes` is DATA+ACK **payload bytes** only; reported prefixBytes adds 7 bytes per API call separately, and transport overhead is unmeasured. Four evidence kinds `sent/received/acks_sent/acks_received` hold at most 480 positions, output in 160-character chunks. No packet logs, CSV/SavedVariables export, auto-output per packet or room discovery exists. Rendering must not mutate this accounting or use it as race state. Missing ACK is not proven DATA loss; reconcile both directions' sequence sets after the observation window.

## Implemented pure race-control codec

`RaceProtocol.lua` is an additive Codex-owned module, registered as `AK.RaceProtocol` and returned for offline loading. It has no clock, WoW API, transport, session-controller or renderer dependency. Loading it registers no prefix/event and sends nothing. Both TOCs include it before NetworkProbe.

```lua
Protocol.VERSION = 2
Protocol.PREFIX = "AZKART2"
Protocol.MAX_BYTES = 128
Protocol.MAX_SEQUENCE = 46655
Protocol.encode(message) -> payload | nil, errorCode
Protocol.decode(payload) -> message | nil, errorCode
```

Common fields are `kind` (the full uppercase kind name below), `session` (six uppercase ASCII letters/digits), and `sequence` (integer 1–46655). All input tables are borrowed read-only. Encode refuses metatables and unknown fields. Decode checks type, size, alphabet, version, kind, exact kind length and field bounds before returning a fresh table. Refusal codes are fixed bounded strings and do not echo packet contents.

| Kind | Additional fields | Exact payload bytes |
|---|---|---:|
| `INVITE` | `physicsVersion`, `trackId`, `trackVersion`, `laps` | 17 |
| `JOIN` | none | 11 |
| `READY` | `ready` (strict boolean) | 12 |
| `START` | `startTick`, `seed` | 23 |
| `CANCEL` | `reason` | 12 |
| `ACK` | `ackKind`, `ackSequence` | 15 |

Version fields are integers 1–1295; valid future values remain decodable for later explicit compatibility refusal. Track IDs are `test_oval` or `mirage_raceway`; laps are 1–9 at the wire layer (this adds no lap setting to the current three-lap game). `startTick` is 0 through 36^6-1; `seed` is 0 through 2147483647. Cancel reasons are `left`, `timeout`, `incompatible`, `combat`, `world_leave`, `error`. ACK accepts one of the five non-ACK kinds and a sequence 1–46655.

The 11-byte header and body use fixed uppercase base36 with no pipes, whitespace or user text. Prefix bytes are additional. [ADR 0013](adr/0013-two-player-experiment-scope.md) defines this experimental envelope. No deduplication, peer authentication, retry scheduler, rate limiter, clock agreement, automatic start or live synchronization is supplied by a codec. `START.startTick` is encoded data, not permission to mutate a race. PeerSession enforces identity/session/version/phase/sequence policy before accepting a proposal, while transport and live-race coordination remain separate. The existing AZKART1 probe and rendering contracts are unchanged.

## Implemented pure peer-session controller

`PeerSession.lua` registers `AK.PeerSession` and returns the module. It injects RaceProtocol and time; it calls no WoW, UI, Physics or Race API. Loading/constructing a controller creates no traffic. Its mutable internal tables are Codex-owned, private by convention; `view` returns fresh nested copies for Claude's presentation. This is an ownership contract, not enforced read-only storage or peer authentication. See [UI/flow ownership](UI_FLOW_OWNERSHIP.md).

```lua
Session.new(options, now, RaceProtocol) -> state | nil, errorCode
Session.invite(state, now, trackId) -> accepted, errorCode?
Session.join(state, now) -> accepted, errorCode?
Session.setReady(state, now, readyBoolean) -> accepted, errorCode?
Session.start(state, now, startTick, seed) -> accepted, errorCode?
Session.cancel(state, now, reason, notifyPeer?) -> accepted, errorCode?
Session.update(state, now, sendFn) -> attempted, outcomeCode?
Session.receive(state, now, prefix, payload, channel, nativeSender) -> handled, errorCode?
Session.view(state) -> copiedView
Session.takeStartProposal(state) -> copiedProposal | nil
-- sendFn(payload, completePeerName) -> "accepted" | "failed" | "unknown" | "throttled"
```

Options are `role="host"|"guest"`, complete Forever `peer`, fresh six-character uppercase-alphanumeric `session`, integer `physicsVersion`, supported `trackVersions={test_oval=2,mirage_raceway=1}` (one or both), and `laps` default3. Options/track versions are copied. Names cap96 raw bytes, reject controls/DEL/pipe, trim/collapse ASCII spaces and compare the entire native sender with ASCII case folding; punctuation/UTF-8/surnames remain intact, with no realm invention or first-name fallback. Session-ID lifetime/reuse management belongs to the future adapter. A compatible host offer selects track and valid laps1–9; guest default laps/local solo selection does not override it. Physics and offered-track versions must match exactly. The current solo Race still fixes three laps; an eventual live adapter must preserve that supported configuration until Race gains an agreed configurable-laps API.

| Phase | Entry and supported action |
|---|---|
| `idle` | New host; `invite(trackId)` queues INVITE. |
| `listening` | New guest; accepts only the configured peer/session's compatible offer. |
| `inviting` | Host awaits explicit peer JOIN; an INVITE ACK alone does not join. |
| `invited` | Guest sees the compatible offer; explicit `join()` is required. |
| `joining` | Guest awaits JOIN ACK; a later valid host READY can causally confirm a previously sent JOIN. |
| `lobby` | Both may set readiness, one pending command each. Readiness stays unconfirmed until its ACK. |
| `starting` | Host proposed parameters; guest received them. No simulation activation occurs. |
| `closed` | Terminal reason retained; no new action/restart. Create a fresh controller/session deliberately. |

Host `canStart` requires lobby, no pending command, local Ready acknowledged and peer Ready received. Guest cannot originate START. Host `startStatus` is `awaiting_ack`, then `acknowledged`; guest status is `received`. Accepted START can causally confirm the guest's previously sent Ready. A fresh unseen START in starting is refused; an identical retransmission is ACKed without reapplying it.

`takeStartProposal` yields `{session,startTick,seed,peerAcknowledged}` **once**: guest after accepting START (`peerAcknowledged=false`), host only after its matching ACK (`true`). Returned proposal/view edits cannot mutate the controller. Guest receipt does not prove the host received its ACK. These are control parameters, not atomic GO, an agreed clock epoch or permission to start a race. A separate live coordinator must address clocks, cancellation and ambiguous start delivery before any race integration. Both controllers stay starting until cancel/timeout; no running/finished state is claimed here.

The copied view contains `role,peer,session,phase,localReady,peerReady,localReadyConfirmed,startStatus,pendingKind,pendingAttempts,reason,deadline,canInvite,canJoin,canSetReady,canStart,canLeave,hasPendingOutput`, optional `offer/start`, and copied `stats`. Offer fields are physicsVersion/trackId/trackVersion/laps. Stats are sendAttempts/sendsAccepted/retries/received/rejected/duplicates/acksMatched. Capabilities describe permitted commands; pending output includes future retries and is not delivery evidence. Presentation maps capabilities to enabled controls and invokes commands; it never edits phase/readiness or authoritative simulation. Snapshot refresh/formatting must stay outside simulation ticks.

Reliability constants: SEND_INTERVAL0.5 seconds shared across ACK/control/retry output, RETRY_INTERVAL2 seconds, MAX_ATTEMPTS3, MAX_ACK_QUEUE8, MAX_SEEN64, MAX_EVENTS256 scoped decoded receives. One update attempts at most one callback, with no catch-up burst. Exact duplicate commands reuse their ACK and never repeat transitions/proposals. Conflicting accepted sequence payloads close; unseen stale commands are refused. ACK sequence arrival order does not incorrectly stale a later command; ACK must match a command actually attempted. Reentrant ACK is deferred until the send callback returns accepted; nested update cannot send recursively. Failed/unknown/throttled/throwing outcomes stop with a fixed diagnostic. Local acceptance is not remote delivery.

Injected time must be finite/nonnegative/monotonic. Invalid/backward time closes `clock_error`; no new output or automatic resume follows. Guest listening/invited and host inviting have30-second deadlines; joining10, lobby120, starting10. Duplicates/readiness do not extend the lobby deadline. Three unacknowledged attempts close two seconds after the last attempt. Queue/map/event/sequence limits close and clear output. Cancellation clears pending retries/proposals; optional local notification (default false) or remote final ACK gets at most one best-effort paced attempt within2 seconds. Automatic deadlines have no final notification. A future adapter must map fixed reasons to UI copy and lifecycle handling.

Per-controller output cadence is2 calls/s; two peers' current maximum23-byte messages plus7-byte prefix imply at most120 payload-plus-prefixB/s at that cadence. This is not a measured capacity or a global rate limiter: the future native adapter must count other traffic under ADR0013's separate pair-wide4-calls/s and316B/s working ceilings. AZKART1 probe, multiplayer menu, native registration, full socket recovery, live start clocks and race replication are not implemented by this unit.

## Authoritative vehicle state

Implemented in [`Physics.lua`](../addon/AzerothKart/Physics.lua):

```lua
Physics.VERSION = 7
Physics.FIXED_DT = 1/60
Physics.new(track) -> state
Physics.step(state, input, dt, track) -> nextState
```

`new` reads `track.spawn()`. `step` defaults omitted `dt` to `FIXED_DT`, asserts `0 < dt <= 0.05`, returns a new table and does not modify the supplied state/input/track. The UI always uses `FIXED_DT`; supporting another positive timestep in this function does not change the race's 60 Hz timing contract.

| State field | Type and meaning |
|---|---|
| `x`, `y` | Numbers; kart center in track world units, bottom-left origin, +X right/east, +Y up/north. |
| `heading` | Radians; 0 east, `math.pi/2` north, positive counterclockwise. Accumulates turns without normalization. Facing direction, not necessarily travel direction. |
| `speed` | Signed world units/second; positive forward, negative reverse. HUD currently displays rounded absolute speed. |
| `tick` | Integer starting at 0, incremented once per Physics step, including countdown steps. |
| `impacts` | Cumulative integer; increments once for each wall-contact step, including repeated contact. Not a collision-event ID or unique impact count. |
| `steering` | Smoothed signed control in [-1,1]; positive left, negative right. |
| `drifting` | Boolean; includes the short correction/charge-holding window. |
| `driftDirection` | -1, 0 or 1; signed drift direction, retained during correction grace. |
| `driftTicks` | Integer charge, capped at 60. Only eligible turning ticks increase it. |
| `driftTier` | 0, 1 or 2; thresholds 30/60 charge ticks. |
| `driftGraceTicks` | Integer consecutive correction pause, up to 12; no added charge during it. |
| `boostTicks` | Integer boost steps remaining **after** the returned step. Release step consumes the first of 30/48 awarded steps. |
| `slipAngle` | Signed radians, bounded by 0.40 in the current model; facing minus travel angle. |
| `surface` | `"road"`, `"grass"` or `"wall"`; `"grass"` means rough salt on Mirage. A clamped contact reports `"wall"` for that step. |

There are **15 fields**; no `vx`, `vy`, acceleration vector, collision normal, damage, chassis dimensions or per-step event list. For a cosmetic directional effect, nominal travel direction is `heading - slipAngle`, with velocity components `cos(direction)*speed`, `sin(direction)*speed`. Those components are derived, not stored; wall clamping can make actual displacement differ. Do not feed derived velocity into simulation.

Current limits: road speed 200, reverse 55, boosted speed 260; rough-ground forward/reverse targets 70/30, reached by gradual drag. Drift requires road, no brake and forward speed at least 90. Drift yaw is 0.75 times ordinary yaw. Releasing Space spends a ready tier if still eligible, including correction grace; braking, low speed, rough ground and wall contact clear charge. Read exported Physics constants for visual thresholds rather than inventing new ones.

Test Oval now sweeps center movement against its perimeter and two axis-aligned solid rectangles expanded by 18 units on each side. This conservative square clearance encloses the rotated 17×31 body; it is not an exact oriented-body or rounded-corner collision shape. Earliest contacts remove inward normal displacement while retaining tangent motion, using at most three movement iterations and no temporary tables. Recovery from a starting overlap is deterministic and bounded to four passes for these disjoint, perimeter-contained fixtures; arbitrary overlapping obstacle clusters are unsupported. Mirage retains its original endpoint perimeter clamp and no obstacles. Contact multiplies speed by 0.25 once per Physics step, clears steering/slip/drift/grace/boost and reports `surface="wall"`; `impacts` still counts contact ticks. No state fields, collision-normal stream, road-edge walls or vehicle-to-vehicle collision were added. Rendering may compare consecutive `impacts`, but must not increment it or treat it as a trustworthy network event.

## Input and fixed-step ownership

[`Input.lua`](../addon/AzerothKart/Input.lua): `new() -> held`, `set(held, key, down) -> supportedBoolean`, `clear(held)`, `sample(held, output?) -> output`. Held keys are W/Up, S/Down, A/Left, D/Right and Space, with independent aliases. `sample` writes five booleans: `accelerate`, `brake`, `left`, `right`, `drift`; UI reuses its output table. Both steering directions cancel. Incidental mouse clicks and unassigned keys do not stop the run or clear held driving keys; mouse buttons are not steering inputs. Explicit Stop, Escape and Close end the run; Enter/chat focus releases racing input for chat. Lifecycle and detected focus-loss stops remain separate from incidental input.

[`Loop.lua`](../addon/AzerothKart/Loop.lua): `new(dt?, maxSteps?) -> clock`, `advance(clock, elapsed, stepFn) -> executedSteps`. UI supplies `1/60` and 5. Loop mutates its clock, accumulates valid nonnegative frame elapsed and invokes `stepFn(dt)` at most five times. Callback `false` ends the batch **after** counting that step. Unexecuted whole steps become `droppedSeconds`; the fractional accumulator remains. Invalid elapsed returns zero. No render/network code may use the accumulator to execute extra physics steps.

Clock fields are `dt`, `maxSteps`, `accumulator`, `frames`, `steps`, `elapsedSeconds`, `droppedSeconds`, `hitchFrames`, `maxElapsed`, `lastSteps`. `elapsedSeconds` is delivered active callback duration, not exclusive CPU time. A bounded hitch drops simulation time; race time therefore excludes it. Stop freezes all counters; a successful Start creates a fresh clock. Inactive `OnUpdate` returns immediately.

UI samples input at each actual fixed step, saves the previous state, steps Physics, then Race, then refreshes the lap/checkpoint aliases. During countdown it samples real keys but passes a reused neutral table to Physics through the GO tick. Keep this order and the terminal callback return intact.

## Track geometry and assets

Each track supplies numbers `width`, `height`, `wallInset`, `checkpointMaxStep`, ordered `gates`, and these dot-call functions:

```lua
track.spawn() -> {x, y, heading}       -- fresh spawn table
track.isDrivable(x, y) -> boolean     -- road mask, not all traversable ground
track.surfaceAt(x, y) -> "road" | "grass" | "wall"
track.constrainPosition(x, y) -> constrainedX, constrainedY, hitBoolean
-- Optional on Test Oval; preferred by Physics when present:
track.resolveMovement(previousX, previousY, targetX, targetY) -> x, y, hit
track.crossesGate(previous, current, gate) -> boolean
```

Physics also supports small test tracks without `surfaceAt`/`constrainPosition`; that fixture fallback is not a replacement production track interface. Gate records use `name`, endpoints `ax,ay,bx,by`, and perpendicular forward normal `nx,ny`. Crossing requires negative to nonnegative signed side and an intersection inside the finite segment. Starting on/departing the line, reverse crossings and invalid geometry do not award.

- [`Track.lua`](../addon/AzerothKart/Track.lua) is singleton Test Oval, `id="test_oval"`, `version=2`: 800×480, elliptical road, spawn (666,240), north-facing. `obstacles` is a read-only-by-convention ordered array of physical rectangles `{id,x,y,width,height}` with bottom-left origin: (270,400,32,24) and (490,60,32,24). `isDrivable` remains the road mask; `surfaceAt` additionally classifies physical obstacle footprints including edges as wall. Only `resolveMovement` adds kart clearance. `constrainPosition` remains perimeter-only for compatibility. Finite endpoints/displacements are required. Exact arrival at a clearance face or isolated corner graze is free; inward movement from a face contacts. Keep geometry fixed during a run.
- [`MirageRaceway.new(crossesGate)`](../addon/AzerothKart/MirageRaceway.lua) returns a fresh track: `id="mirage_raceway"`, `version=1`, 1024×1024, a closed 16-point `centerline`, `roadWidth=112`, `roadRadius=56`, derived `length`, spawn (700,360), north-facing. The road is a union of capsules. Internal segment/radius caches are built once; mutating centerline/radius afterward would not rebuild them. Treat all geometry as immutable during use.
- Both have four ordered gates North, West, South, Start; `checkpointMaxStep=5`. Perimeter walls are separate from road/rough-ground boundaries. Scenery guide markers are not colliders.

Pixels are **not** collision authority. The existing `Assets/Tracks/SaltFlats/Background.tga` is original procedural scenery v1: a geometry-derived 1024×1024 opaque RGBA32 background with static props and shadows baked into one image. It replaces the earlier blockout at the same path. Editable guides/concepts live outside runtime. Claude may improve static art, but must preserve the geometry origin, orientation, road edges, gates, spawn and scale, or coordinate a versioned geometry change with Codex. Painted props add no colliders; Mirage has no obstacle fixtures. Foreground, preview, selectable roster and separate prop/VFX layers remain unimplemented. See [ASSETS](ASSETS.md), [the map brief](art/MIRAGE_RACEWAY.md) and [ADR 0008](adr/0008-mirage-raceway-art-direction.md).

## Race progress and timing

```lua
Checkpoints.new(track, tick?) -> progress
Checkpoints.step(progress, previous, current, track) -> progress
Laps.new(track, Checkpoints, tick?) -> laps
Laps.step(laps, previous, current, track, Checkpoints) -> laps
Race.new(track, Checkpoints, Laps, tick?) -> race
Race.step(race, previous, current, track, Checkpoints, Laps) -> race
Race.stop(race, reason?, interrupted?) -> race
Race.cue(race) -> "3" | "2" | "1" | "GO" | nil
```

These pure modules return new accepted progress, or the same reference for rejected/terminal operations; they do not mutate prior state. Checkpoint fields: `nextGate`, `passed`, `complete`, `lastTick`. Only consecutive previous/current ticks matching `lastTick` can advance, at most one expected gate per step. Duplicate/stale/gapped samples are ignored. Consecutive nonfinite positions or displacement above five units consume time without awarding a gate. This is local consistency, not multiplayer validation or competitive anti-cheat.

Lap fields: `checkpoints`, `completedLaps`, `lapStartTick`, `currentLapTicks`, `lastLapTicks`, `bestLapTicks`, `bestLapNumber`, `lastTick`, `lastFinishTick`. The fourth gate finishes a lap and rearms North on that same tick. Best values start nil, update only on a completed strictly faster lap, and keep the earlier lap on ties. They are in-memory, per-run values, not saved personal records.

Race fields: `status`, `laps`, `targetLaps`, `countdownTicks`, `startTick`, `lastTick`, `totalTicks`, `finishTick`, `reason`. Status is `"countdown"`, `"running"`, `"finished"`, `"stopped"` or `"interrupted"`. The current target is three laps; it is not a user setting.

Countdown starts at 180. Cues show 3 for remaining 180–121, 2 for 120–61, 1 for 60–1. At physics tick 180, Race becomes running and resets the lap origin; the kart remains at spawn. Held driving input first applies at tick 181. GO displays for `totalTicks` 0–59. Race/lap seconds are integer durations multiplied by `Physics.FIXED_DT`, excluding countdown, dropped time and stopped time; physics/loop/probe ticks include countdown. The third accepted lap fixes `finishTick`, returns finished and stops catch-up before another physics step. Terminal step/stop calls retain the same race object.

`UI.DismissSummary()` hides the terminal result panel without changing the retained race, pose, sample, HUD or input. The pooled **Close results** button calls it. The same terminal race stays dismissed across Stop, rejected Start and window close/reopen. A successful fresh Start or map change clears this presentation-only dismissal. This is not resume or an authoritative race field.

UI Start/Restart always creates a fresh countdown; there is no resume. Stop retains actual partial progress; combat interrupts, closes the window, releases controls and announces once. Reopen and rejected Start preserve the result. Successful map change or Start resets it. Rendering may show these results but must not infer extra laps, interpolate progress counters, count gate crossings itself or advance race time from wall clock.

## Presentation and camera

[`Presentation.lua`](../addon/AzerothKart/Presentation.lua) is pure math except the deliberate mutation of **presentation-owned view offsets** in `follow`:

```lua
pose(previous, current, alpha) -> x, y, heading
meter(state, Physics) -> fraction, phase
fitViewport(worldWidth, worldHeight, canvasWidth, canvasHeight) -> view
cameraViewport(worldWidth, worldHeight, canvasWidth, canvasHeight, scale?) -> view
project(view, x, y) -> canvasX, canvasY
unproject(view, canvasX, canvasY) -> x, y
follow(view, x, y, heading, lookAhead?) -> sameView
texCoords(view) -> left, right, top, bottom
clipRect(view, x, y, width, height) -> canvasX, canvasY, width, height | nil
kartFrame(sprite, heading) -> frame   -- nearest directional frame, 0-based
kartFrameCoords(sprite, frame) -> left, right, top, bottom
```

`pose` linearly interpolates position and uses the shortest heading arc; an exact half-turn chooses the negative arc. Missing/NaN alpha uses current pose, alpha ≤0 previous, alpha ≥1 current. During active rendering alpha is `clock.accumulator/clock.dt`; this is up to one fixed step behind simulation. Start/Stop/inactive drawing uses the exact current pose. Presentation values must never affect Physics, gates or lap time.

`meter` clamps a visual fraction to capacity and returns `"idle"`, `"charging"`, `"holding"`, `"tier1"`, `"tier2"` or `"boost"`. Rough ground/walls override stale charge. Boost uses the shared 48-tick capacity, so a shorter reward starts less full. Phase does not change simulation.

All project/unproject coordinates use bottom-left +Y-up, a **uniform** scale and offsets: `canvasX=offsetX+x*scale`, likewise Y. Scale dimensions as well as positions. No separate X/Y stretching. `unproject` does not clamp or authorize gameplay input.

Test Oval uses a fixed fit overview (800×480 into 800×480, scale 1). Mirage uses `cameraViewport(1024,1024,800,480,1.5)`, giving a 533⅓×320-world-unit visible area. The camera is north-up, follows the **interpolated** pose plus 60 world units along facing heading, and clamps against world edges. It does not rotate the map or change collision coordinates. `follow` reuses the view by changing `offsetX/offsetY` only. The minimum allowed camera scale covers the canvas.

`texCoords` converts +Y-up to top-origin texture V once and returns four arguments for `SetTexCoord(left,right,top,bottom)`, bounded to [0,1]. `clipRect` returns the visible canvas intersection for axis-aligned world rectangles, or nil when invisible. UI repositions/clips pooled gate and perimeter textures when camera offsets change; no native clipping API is assumed. Rotated kart clipping is not a general sprite-clip interface.

**Implemented and Codex-reviewed:** the original single-image path (`520275e`) and Claude's directional-sheet extension (`cf71394`) are combined on `codex/menu-integration`. Neither changes Physics/Race fields, authoritative coordinates or collision clearance.

- The physics body stays 17×31 **world** units, published for presentation as `Presentation.KART_FOOTPRINT_WIDTH/HEIGHT` (25.5×46.5 UI units on Mirage).
- `Presentation.KART_SPRITES[id]` is pure, read-only data: `path`, power-of-two `textureWidth/textureHeight`, and `quadWidth/quadHeight` in world units with square texels.
- A **single image** has no `frames` field. It is north-facing, centered at the projected pose and rotated by `heading - math.pi/2`. The registered `goblin_drag_car` is a 64×128 TGA drawn as a 20×40 world quad; every visible texel stays inside its 17×31 body.
- A **directional sheet** also supplies `frames`, `columns`, `pivotX` and `pivotY`. Its frames form an even grid, read left to right and top to bottom; frame k faces heading `k * 2pi / frames`, counterclockwise from east. Each frame covers `quadWidth x quadHeight` world units. Its center sits `pivotX/pivotY` world units east/north of the kart's projected position, scaled by the view. This screen-oriented pivot is not rotated with heading.
- `Presentation.DEFAULT_KART` is `"goblin_mortar_trike"`: a 1024×1024 sheet of 64 frames of 128×128 texels, quad 41×41, pivot (3, 0), rendered in three-quarter view from the Warcraft III model. The single-image drag car remains registered; there is no selectable garage UI.
- `Presentation.kartFrame(sprite, heading)` returns the nearest 0-based directional frame for a finite heading, wrapping positive and negative turns. `Presentation.kartFrameCoords(sprite, frame)` returns `left, right, top, bottom` for a valid frame of the registered sheet. These helpers consume trusted presentation metadata; they are not incoming-packet validators.
- UI loads the default sprite once in `UI.Create`. The guarded `SetTexture` must return exactly `true`; a sheet also requires `SetTexCoord` to exist and accept frame 0; a neutral `SetVertexColor` must then succeed. Only after these checks is the read-only diagnostic `UI.kartSprite` set and the pooled kart Texture sized to its quad times the view scale.
- Drawing a sheet displays its nearest frame without `SetRotation`; `SetTexCoord` is written only when that frame changes. Single images and the primitive keep continuous rotation. Phase changes tint loaded sprites with cached `SetVertexColor` calls.
- Any refused creation-time load/crop/tint keeps the 17×31 primitive and its `SetColorTexture` phase colors, with no load retry. Only the primitive path calls `SetColorTexture`, which would replace a loaded image.

The guarded fallback covers creation-time refusal only. Later crop and tint calls use the normal client API directly; recovery from a newly throwing API is not implemented or tested. The sheet is 4 MiB of raw pixels, compared with the drag car's 32 KiB; this changes texture storage, not the explicit UI object count. Height and baked shadow extend beyond the physics body, with possible visual overhang at the map boundary. This does not enlarge clearance or create a collision shape. See [the trike asset sheet](art/karts/goblin-mortar-trike.md) for dimensions, provenance and unresolved redistribution status.

The visual path reads simulation state only. An offline scripted drive compares every returned Physics field and selected race/checkpoint fields between sprite and primitive modes; it is not an exhaustive comparison of all nested race state. The owner approved the installed trike and scenery shadows at `cf71394`, without itemized timing or probe output ([evidence](evidence/2026-10-20-trike-and-shadows-owner-approval.md)). That approval does not establish combined-build counts, moving-camera edge behavior or sustained performance.

**Implemented and reviewed on `codex/results-dismiss` (2026-10-21), preserving Claude runtime `c6e1b5e`: drift and boost effects.** See [the effects sheet](art/effects/drift-boost.md).

- `Presentation.EFFECTS` is read-only data:
  - the two atlas paths and their cell layout;
  - pool sizes: 20 puffs, 14 sparks, and two flames of two layers;
  - spark colours per drift tier (the meter's blue, gold and magenta), and the soot and flame colours;
  - the flame's reach in world units.
- A kart sprite may carry `effects = {wheels, exhausts, view}`: anchors in the kart's frame (+x forward, +y left, z up; world units) and the art's camera tilt `(cos, sin)`. `Presentation.DEFAULT_EFFECT_ANCHORS` covers the primitive kart.
- `Presentation.newEffects() -> fx` allocates the fixed pools. `Presentation.clearEffects(fx)` deactivates every particle and flame.
- `Presentation.advanceEffects(fx, previous, current, alpha, options) -> now`:
  - emits for every new simulation tick from `drifting`, `driftTier`, `driftGraceTicks`, `driftDirection` and `boostTicks`, placing particles along the path travelled since the last tick;
  - updates the flames for the drawn heading;
  - returns the effect time: `previous.tick + alpha` while interpolating, otherwise `current.tick`. A tick that goes backward, or jumps by more than 30, restarts the effects;
  - takes `options = {anchors, dust, boostFullTicks}`;
  - writes only `fx`; both states are read-only.
- `Presentation.particleAt(p, now) -> x, y, size, alpha` (or nil) evaluates one particle in world units. `Presentation.effectCoords(kind, cell)` returns `SetTexCoord` arguments for a `"smoke"`, `"spark"` or `"flame"` cell.
- Effect randomness is a seeded Park–Miller sequence, exact in Lua 5.1 and 5.4, so the same states give the same particles.
- UI owns 38 effect textures, created once in `UI.Create`:

  | Texture | Layer and sublevel |
  |---|---|
  | Smoke | ARTWORK 6 |
  | Sparks | OVERLAY −2 |
  | Flames, pipe facing the camera | OVERLAY 2/3 |
  | Flames, pipe on the far side | OVERLAY −4/−3 |

  - Each atlas loads through guarded `SetTexture == true` plus `SetTexCoord`/`SetVertexColor` probes; any refusal disables all effects without touching the kart or race.
  - Drawing uses pre-rendered directional cells, never `SetRotation`, and normal alpha blending, never `SetBlendMode`.
  - Quads that would cross the canvas edge are hidden.
  - Map selection clears all effects.
- Particle repeatability applies to identical sampled-state/effect-update sequences, not different rendering cadences. Offline drives give identical returned Physics and selected race fields with effects on, refused or under the primitive kart. Client appearance and cost are NOT RUN.

## Rendering cadence, resources and lifecycle

Rendering currently runs once per delivered active `OnUpdate`, after zero or more fixed steps; it is not locked to 60 FPS and has no separate render timer. Meter, gate colors and countdown update through the render path with cached values. The numeric HUD refreshes every ≥0.25 **simulated** seconds, on lap/status changes and immediately at Start/Stop/selection. UI lifecycle events may draw outside `OnUpdate`; inactive updates do no work.

The window is 856×762 with an 800×480 canvas. Explicit UI allocations are **10 frames, 151 textures, 13 font strings** (two pooled Oval obstacle markers and one new pooled Close results button and 38 effect textures). This includes the 96 retained Oval bands, four gate strips, four perimeter strips, one Mirage background, one kart, two solid-fixture markers and pooled meter/result/cue elements. Markers render the physical rectangles in ARTWORK at Oval's fixed scale and stay hidden on Mirage, including camera updates. Counts exclude Core's event frame, template/native internals and other addons. They are offline-checked explicit allocations; the prior 9/111/13 baseline has scoped client observations. Neither count is a guaranteed client memory/FPS budget or a ban on reviewed pool changes.

Preserve creation-time pooling: no `CreateFrame`/`CreateTexture`/font-string creation, texture file loads or chat output per simulation tick or render callback. Current snapshots allocate bounded Lua tables per tick; there is no promise of zero Lua allocation. Profile before replacing their immutable-style behavior. Opt-in Performance collects at most 600 callback spans and includes instrumentation overhead; it is not exclusive CPU/GPU cost.

`UI.SelectTrack(id) -> boolean` accepts `"test_oval"` or `"mirage_raceway"` only with an existing shown window, while stopped and out of combat. Mirage's guarded `SetTexture` must return true; a guarded UV capability check must succeed before committing the switch. Failure preserves the old track/run/sample. Successful selection clears samples and creates a new spawn/lap state; loaded artwork is reused. The Track button is disabled while active; clicking a disabled selector does not stop a run. Test Oval is the default after reload; selection is not persisted.

Capture/release safeguards and combat/lifecycle handling remain controller-owned. Under the owner's revised input policy, incidental mouse clicks and unassigned keys leave the run active; there is no global-mouse event requirement for Start. Stop, Escape and Close deliberately end the run; Enter and detected chat/text focus release racing input, as do supported focus-loss and lifecycle paths. Required keyboard capture/propagation and text-focus capabilities still gate Start, and capture never automatically resumes. Build 70450 lacks `IsGameWindowFocused`/`IsWindowFocused`; full held-input focus-loss behavior remains unverified. Do not substitute guessed protected APIs or make global WoW movement bindings part of rendering. See [FEASIBILITY](FEASIBILITY.md) and [ADR 0006](adr/0006-combat-interrupted-results.md).

## Proposed changes require coordination

Possible future work includes an explicit render snapshot/scene boundary, collision feedback events, additional sprite atlases/animation, foreground occlusion, track hashes, saved records and multiplayer snapshots. None is a callable contract today. Do not implement an architecture sketch as though its fields already exist. Agree a contract/ADR update and compatibility impact before adding or renaming authoritative fields, changing units/tick semantics, track geometry or lifecycle callbacks. The optional Test Oval movement hook and version changes described above are implemented in this slice; the future boundaries listed here are not.

Offline state/geometry/UI-mock checks are evidence of those scopes only. Opaque Mirage texture loading and the stopped close-camera view were observed in the client; the owner subsequently approved the installed trike and scenery shadows. Combined-build menu behavior, moving camera edges, latest handling acceptance and sustained performance require their own evidence. No multiplayer transport measurements or replication architecture have been established.
