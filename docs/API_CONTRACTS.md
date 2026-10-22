# Implemented simulation and rendering contracts

**Checkpoint:** 2026-10-22, `codex/ui-backend-integration`: merge `6cd611a` combines reviewed Claude UI `1b2d3d5` with Codex backend `192c6de`; `9b22f12` applies Claude's isolated preference fix `4ffe184` without its city-track dependencies. Subsequent city merge f9f2af0 now preserves Claude capital-cup78d97a1 and those modules; the reviewed loader repair stages new backgrounds before changing the visible picture. The combined source retains the reviewed six-kart rendering, Forever transport correction, session adapter and start-clock foundation. Physics compatibility version remains **7** (v6 handling retained). This describes the local solo prototype, measured transport experiment and offline control foundation; it does not claim a released engine or playable multiplayer. See [PROGRESS](PROGRESS.md) and [the latest handoff](handoffs/codex-latest.md).

## Status and ownership

The interfaces below exist in source today. `Renderer`, `GameSession`, collision-event streams, velocity vectors, a replay API and production synchronization adapters do **not** exist. The standalone NetworkProbe/TransportProbe experiment and the pure RaceProtocol/PeerSession control foundation described below are implemented; none feeds authoritative simulation state. The native SessionTransport boundary is implemented and tested with mocks; the opt-in start-clock coordinator now yields one backend Physics/Race initialization bundle. Menu screens and their solo commands are integrated. Multiplayer menu wiring, remote kart replication and a playable live-race controller remain unimplemented; see [START_CLOCK](START_CLOCK.md). Proposed architecture sketches in [ARCHITECTURE](ARCHITECTURE.md) must not override the signatures here.

- **Codex:** Physics, collision/surface queries, Input sampling, Loop, Checkpoints, Laps, Race, deterministic simulation and their tests; experimental transport/accounting, RaceProtocol, PeerSession and future synchronization.
- **Claude:** visual rendering, camera/presentation helpers, track imagery, HUD, sprites, animations/VFX, asset tooling and their focused visual tests.
- **Shared:** public interface changes, accepted architecture decisions, integration coverage, performance budgets and TOC load-order changes. Coordinate explicitly before editing the other owner's code.

[`UI.lua`](../addon/AzerothKart/UI.lua) currently mixes both responsibilities. Its drawing/layout/rendering/HUD helpers belong to Claude; capture, Start/Stop/combat transitions, track-selection lifecycle, `step`, `OnUpdate` clock orchestration and authoritative-state assignment belong to Codex. Coordinate any shared-file edit by function area before working. `SelectTrack` includes both asset validation and lifecycle reset, so changes there require coordination. There is no standalone renderer entry point to call or replace yet. Extracting one would be a separately agreed change.

## Modules and data access

The two TOCs load `Track`, `MirageRaceway`, `Circuit`, `CapitalCities`, `Courses`, `Physics`, `Input`, `Loop`, `Performance`, `Presentation`, `Checkpoints`, `Laps`, `Race`, `UI`, `Menu`, `RaceProtocol`, `PeerSession`, `ClockProtocol`, `StartClock`, `RaceStart`, `NetworkProbe`, `TransportProbe`, `SessionTransport`, `Core` in that order. The integrated front end loads `Menu` right after `UI`, for 24 modules in each TOC ([below](#implemented-front-end-menus-race-hud-and-results)). Pure modules receive `local _, namespace = ...`, optionally register their module on that explicit table, and return it for offline loading. They do not access WoW globals. Core exports the same namespace as `_G.AzerothKart` for diagnostics.

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
Session.update(state, now, sendFn, sendAllowed?) -> attempted, outcomeCode?
Session.receive(state, now, prefix, payload, channel, nativeSender) -> handled, errorCode?
Session.view(state) -> copiedView
Session.takeStartProposal(state) -> copiedProposal | nil
Session.handoffStart(state, now) -> copiedProposal | nil, errorCode? -- opt-in coordinator only
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

`takeStartProposal` yields `{session,startTick,seed,peerAcknowledged}` **once**: guest after accepting START (`peerAcknowledged=false`), host only after its matching ACK (`true`). Returned proposal/view edits cannot mutate the controller. Guest receipt does not prove the host received its ACK. These are control parameters, not atomic GO, an agreed clock epoch or permission to start a race. A separate live coordinator must address clocks, cancellation and ambiguous start delivery before any race integration. Legacy controllers stay starting until cancel/timeout. Additive `handoffStart` consumes an available proposal once and enters `coordinating` with a fixed 30-second deadline for StartClock; duplicates still re-ACK, new READY/START are refused. No running/finished state is claimed by PeerSession.

The copied view contains `role,peer,session,phase,localReady,peerReady,localReadyConfirmed,startStatus,pendingKind,pendingAttempts,reason,deadline,canInvite,canJoin,canSetReady,canStart,canLeave,hasPendingOutput`, optional `offer/start`, and copied `stats`. Offer fields are physicsVersion/trackId/trackVersion/laps. Stats are sendAttempts/sendsAccepted/retries/received/rejected/duplicates/acksMatched. Capabilities describe permitted commands; pending output includes future retries and is not delivery evidence. Presentation maps capabilities to enabled controls and invokes commands; it never edits phase/readiness or authoritative simulation. Snapshot refresh/formatting must stay outside simulation ticks.

Reliability constants: SEND_INTERVAL0.5 seconds shared across ACK/control/retry output, RETRY_INTERVAL2 seconds, MAX_ATTEMPTS3, MAX_ACK_QUEUE8, MAX_SEEN64, MAX_EVENTS256 scoped decoded receives. One update attempts at most one callback, with no catch-up burst. Additive optional `sendAllowed=false` still advances deadlines/clocks and expires final output, but never invokes the send callback or consumes an attempt; omitted/true retains existing behavior. Non-boolean non-nil flags are refused. Exact duplicate commands reuse their ACK and never repeat transitions/proposals. Conflicting accepted sequence payloads close; unseen stale commands are refused. ACK sequence arrival order does not incorrectly stale a later command; ACK must match a command actually attempted. Reentrant ACK is deferred until the send callback returns accepted; nested update cannot send recursively. Failed/unknown/throttled/throwing outcomes stop with a fixed diagnostic. Local acceptance is not remote delivery.

Injected time must be finite/nonnegative/monotonic. Invalid/backward time closes `clock_error`; no new output or automatic resume follows. Guest listening/invited and host inviting have30-second deadlines; joining10, lobby120, starting10. Duplicates/readiness do not extend the lobby deadline. Three unacknowledged attempts close two seconds after the last attempt. Queue/map/event/sequence limits close and clear output. Cancellation clears pending retries/proposals; optional local notification (default false) or remote final ACK gets at most one best-effort paced attempt within2 seconds. Automatic deadlines have no final notification. A future adapter must map fixed reasons to UI copy and lifecycle handling.

Per-controller output cadence is2 calls/s; two peers' current maximum23-byte messages plus7-byte prefix imply at most120 payload-plus-prefixB/s at that cadence. This pure module is not a measured capacity or global rate limiter. SessionTransport supplies its candidate-wide output gate while holding an exclusive lease against the standalone probe. Multiplayer menu, full socket recovery, live start clocks and race replication are not implemented by PeerSession.

## Implemented logged-whisper session adapter and menu bridge

`SessionTransport.lua` is the Codex-owned WoW boundary over the existing controller and separate AZKART2 prefix. `AK.SessionTransport` exposes dot-call methods below; its raw controller remains private. Loading/Init performs no prefix/event registration, native sends, chat output, race mutation or UI allocation. Actual AZKART2 client traffic is **NOT RUN**; tests inject native APIs. [Claude's menu guide](SESSION_MENU_API.md) records flow and ownership.

```lua
SessionTransport.Init(coreFrame) -> accepted, errorCode?
SessionTransport.Host(completePeer, freshCode, trackId) -> accepted, errorCode?
SessionTransport.Listen(completeHost, freshCode) -> accepted, errorCode?
SessionTransport.Join() -> accepted, errorCode?
SessionTransport.Ready(readyBoolean) -> accepted, errorCode?
SessionTransport.Start(startTick, seed) -> accepted, errorCode?
SessionTransport.Leave() -> accepted, errorCode?
SessionTransport.Stop(fixedReason) -> wasActive
SessionTransport.IsActive() -> boolean
SessionTransport.Update() -> attempted, outcomeCode?
SessionTransport.Message(prefix,payload,channel,nativeSender) -> handled, errorCode?
SessionTransport.HandleEvent(event)
SessionTransport.GetView() -> copiedView
SessionTransport.TakeStartProposal() -> copiedProposal | nil, errorCode?
```

Host/Listen explicitly arm one full native Forever peer/fresh six-character code. Actual Physics.VERSION, Test Oval.version and a separate Mirage factory instance's version populate compatibility; fixed3laps match current Race support. Host queues the invite without sending; Listen alone never accepts it. No room discovery, identity/realm inference, automatic rearm, code generation or new slash command exists. Accepted sessions consume one of64remembered codes per addon lifetime; malformed/refused setup does not consume an ID. Reload clears history but still requires a genuinely fresh code.

The adapter exclusively leases Core's existing frame with addon-owned `akNetworkOwner`. Both adapters mark `akNetworkSending` during native calls, preventing handover even if Stop releases the ordinary lease from a send callback. Only the lease owner may change OnUpdate/CHAT_MSG_ADDON_LOGGED registration; Core retains OnEvent. Probe arming verifies ownership after each native setup step and blocks recursive arm. Inactive Stop cannot detach the other adapter. No two-adapter concurrency or packet sends from Message/actions occur. The separate AZKART1 experiment retains its schedule/measurements; it is not a race channel or simultaneous traffic allowance.

Registration accepts only source-matched Success/DuplicatePrefix enums. Send uses only C_ChatInfo.SendAddonMessageLogged with native WHISPER and full canonical peer, receives CHAT_MSG_ADDON_LOGGED and accepts only the source-matched numeric Success result. Known failure/throttle codes, unknown/nil/opaque results or throwing APIs terminate; there is no ordinary-whisper/unlogged fallback. Combat/actual chat lockdown, unreadable/backwards clocks, capability/hook failures, world/logout and local driving refuse/stop. Data is addon-owned printable control fields only; error strings are fixed and do not echo native failures or packet contents. Logged transport is not promised private or authenticated.

Every attempted native session call—including ACK, retries and final cancellation—is counted before the API invocation. Persistent local spacing0.5seconds, rolling1second2calls and158payload-plus-prefixB caps survive fresh-controller rearming. Current payload limit23bytes plus7prefix; no catch-up bursts. Budget waits advance pure deadlines without consuming attempts. With both endpoints compliant this stays under ADR0013's separate pair4calls/s and316B/s working ceilings before unknown overhead; it does not measure capacity or govern other addons. Standalone probing is exclusive and separate from the candidate.

GetView copies the pure view plus `canHost,canListen,transportBusy,route,lastError,traffic`. Host/Listen are disabled at the64-ID cap, during native calls, active controllers or any adapter's lease. These are structural capabilities; action preflight can still refuse combat/API state. Traffic counters are lifetime `attempts,accepted,failed,unknown,throttled,payloadBytes,prefixBytes,windowCalls,windowBytes`; window values reflect the last validated clock, and snapshots call no native APIs. Refresh at a modest menu cadence outside simulation ticks. None of these counters proves delivery.

Leave queues at most one paced best-effort CANCEL; remote CANCEL similarly gets one bounded final ACK. The lease remains held only through that bounded drain. Hard Stop drops controller/pending output/proposals, retains a copied closed diagnostic and releases owned hooks; no new command or delayed callback resurrects it. Accepted solo UI.Start calls Stop(local_drive) before capture. Core forwards lifecycle events to both adapters. GUI Leave/Close behavior belongs to Claude's future session flow; the existing solo presentation is unchanged.

Start forwards backend parameters and TakeStartProposal is a backend-only one-shot hook. No call activates Race/UI.Start/physics, aligns clocks or guarantees atomic GO; frontend rendering must not consume the proposal. Live-start/clock coordination and actual two-client control acceptance remain pending.

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

Pixels are **not** collision authority. The existing `Assets/Tracks/SaltFlats/Background.tga` is original procedural scenery v1: a geometry-derived 1024×1024 opaque RGBA32 background with static props and shadows baked into one image. It replaces the earlier blockout at the same path. Editable guides/concepts live outside runtime. Claude may improve static art, but must preserve the geometry origin, orientation, road edges, gates, spawn and scale, or coordinate a versioned geometry change with Codex. Painted props add no colliders; Mirage has no obstacle fixtures. A shared track-preview atlas, six-kart cosmetic roster and pooled drift/boost effects are implemented. A foreground and separate interactive prop layers remain future work. See [ASSETS](ASSETS.md), [the map brief](art/MIRAGE_RACEWAY.md) and [ADR 0008](adr/0008-mirage-raceway-art-direction.md).

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
- `Presentation.DEFAULT_KART` is `"goblin_mortar_trike"`: a 1024×1024 sheet of 64 frames of 128×128 texels, quad 41×41, pivot (3, 0), rendered in three-quarter view from the Warcraft III model. The single-image drag car remains registered; a stopped-only Kart button cycles the six registered cosmetic karts (not a full garage screen).
- `Presentation.kartFrame(sprite, heading)` returns the nearest 0-based directional frame for a finite heading, wrapping positive and negative turns. `Presentation.kartFrameCoords(sprite, frame)` returns `left, right, top, bottom` for a valid frame of the registered sheet. These helpers consume trusted presentation metadata; they are not incoming-packet validators.
- UI loads the default sprite once in `UI.Create`. The guarded `SetTexture` must return exactly `true`; full-image/sheet `SetTexCoord`, explicit rotation (zero for sheets) and neutral `SetVertexColor` must all succeed. Only after these checks is the read-only diagnostic `UI.kartSprite` set and the pooled kart Texture sized to its quad times the view scale.
- Drawing a sheet leaves the explicit load/selection-time zero rotation unchanged; `SetTexCoord` is written only when that frame changes. Single images and the primitive keep continuous rotation. Loaded sprites were tinted per phase until 2026-10-21; now they stay at the neutral `SetVertexColor` (see the effects contract below).
- Any refused creation-time load/crop/rotation/tint keeps the 17×31 primitive and its `SetColorTexture` phase colors, with no load retry. Only the primitive path calls `SetColorTexture`, which would replace a loaded image.

Guarded fallback covers creation and deliberate stopped selection, including complete rollback or a consistent Basic fallback. If primitive rotation refuses, that presentation rotation path is disabled until a successful deliberate selection. Later per-frame crop and loaded-sprite tint calls still use the normal client API directly; arbitrary mid-drive API failure recovery is not implemented or tested. The sheet is 4 MiB of raw pixels, compared with the drag car's 32 KiB; this changes texture storage, not the explicit UI object count. Height and baked shadow extend beyond the physics body, with possible visual overhang at the map boundary. This does not enlarge clearance or create a collision shape. See [the trike asset sheet](art/karts/goblin-mortar-trike.md) for dimensions, provenance and unresolved redistribution status.

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
- Loaded kart art is no longer tinted per phase (owner direction, 2026-10-21); the effects carry drift and boost feedback. Only the primitive fallback keeps its `SetColorTexture` phase colours.

**Reviewed integration on `codex/roster-integration` (2026-10-21): kart roster and Kart button.** See [the roster](art/karts/roster.md).

- `Presentation.KART_SPRITES` gains `steam_tank`, `dwarven_biker`, `gryphon_rider` and `gyrocopter`: directional sheets like the trike, each with its own `quadWidth/quadHeight` and `pivotX`.
- Every sprite has a display `name`. Effect anchors may include `trails`: wingtip points that emit pale puffs while boosting. An empty `exhausts` list shows no flame.
- `Presentation.KART_ORDER` lists the button's cycle. `Presentation.nextKart(id)` returns the next id, wrapping to the start; an unknown id returns the first.
- `UI.SelectKart(id) -> boolean` (Claude, visual):
  - It is refused while a run is active, for an unknown id, or without the kart texture.
  - It loads the art with the creation-time guarded checks. On refusal it restores the previous art, exact frame/full UVs, rotation, dimensions, neutral tint, effect anchors and label, returning false. If restoration also refuses, it clears sprite/frame/id metadata and uses the17×31 Basic primitive/default effect anchors; stopped run/result/track/physics remain unchanged.
  - It resets rotation when changing to a sheet and the crop when changing to a single image.
  - It resizes the quad, moves the effect anchors and redraws.
  - It never writes the run, result, track or simulation state. The choice is not saved by UI; the integrated front end remembers changed IDs through `Menu.OnKartChanged` and explicit successful choices through `Menu.Chose`.
- `UI.Create` adds a **Kart** button (one Frame) beside the Track button, whose click selects `nextKart(UI.kartId)`. The callback is reviewed and integrated alongside Close results; session/navigation ownership stays as documented above. `refreshHud`, Claude's HUD region, disables the button whenever `UI.active` is true.
- Every kart drives the same 17×31 body; the art may overhang it as the trike's does. The four new sheets add 16 MiB of raw texture data when all are loaded.

<a id="proposed-front-end-menus-race-hud-and-results"></a>

### Implemented: front-end menus, race HUD and results

Reviewed Claude UI `1b2d3d5` is integrated with the Codex backend by `6cd611a` on `codex/ui-backend-integration`; isolated Claude preference fix `4ffe184` is retained as `9b22f12`. The [integration review](reviews/2026-10-21-ui-backend-integration.md) records the original finding; the explicit-choice regressions now cover its correction. See [the front-end sheet](art/ui/front-end.md). Client appearance and behavior are **NOT RUN** for this combined source.

- **Module.** `Menu.lua` (Claude, presentation) loads after `UI` in both TOCs and registers `AK.Menu`. `UI.Create` ends with `pcall(AK.Menu.Create, UI)`. On failure, `Menu.Disable(err)` reports once in chat and leaves the basic bar.
- **Notifications added to `UI.lua`.** They leave authoritative simulation, capture, timing and selection transactions unchanged:
  - `refreshHud` → `Menu.Sync()` (scene, bar visibility, lap times, track memory);
  - the end of `render` → `Menu.RefreshRaceHud()`;
  - a changed countdown cue → `Menu.OnCue(cue)` (sounds);
  - the end of `UI.SelectKart` → `Menu.OnKartChanged()` (memory);
  - a new window `OnShow` script → `Menu.OnWindowShown()`.
- **`UI.SetEffectsEnabled(enabled)`** (Claude, visual). Off clears and hides every effect and skips emission; on resumes from the next simulation tick. Simulation never reads it.
- **Commands the menus call:**
  - `UI.Start()` only from a **Race!**, **Start Race** or **Restart** click;
  - `UI.SelectKart(id)`;
  - `UI.DismissSummary()` before leaving results for a menu;
  - `UI.SelectTrack(id)` from the track screen, and once per session to restore the saved track at the first out-of-combat open. Codex approved this restoration through the existing inactive/out-of-combat transaction; it never starts a race. A successful deliberate track choice supersedes any deferred restoration.
  - Menus refuse to open over a live run and never write run, race, physics, input or session state.
- **Window.** It becomes movable by a top drag handle and takes its scale from Settings. A child watcher frame's `OnHide` tells a real close from a hidden parent (Alt+Z). It is not added to `UISpecialFrames`: the Escape that stops a run can reach the game's Escape binding.
- **Bar.**
  - Start is relabelled **Start Race**, and Stop moves to x=618, away from it.
  - Track, Kart and a new **Main Menu** show only in the track view.
  - Print Probe and the timing line show only with developer info.
  - Codex's Start/Stop still enable and disable the same buttons; their callbacks are unchanged.
- **Results.** `UI.summary` grows to 460×312 and sits above the race overlay.
  - Three new buttons, **Change Kart**, **Change Track** and **Main Menu**, each call `UI.DismissSummary` and then open a menu.
  - Title, detail and hint text, Restart and Close results are unchanged.
- **SavedVariables (implemented preference record).** `AzerothKartDB.preferences` is `{version=1, track, kart, effects, devInfo, scale, sound}`.
  - Values are validated on read.
  - A save keeps unknown fields; a record with a newer `version` is read but never overwritten.
  - Saves happen on deliberate successful choices or settings changes, never per tick. `Menu.Chose("track"|"kart", id)` records successful menu selections even when the selected ID is already current. The track case marks restoration complete, so an old deferred saved choice cannot override the player. It is bookkeeping after a guarded UI command, not a selection or simulation API.
  - An untouched failed restore retains the old saved ID. Quick-bar changes are observed from menu creation; restoration is excluded from that change observer. Newer-version records are still never overwritten, while explicit choices update the current in-memory preferences. Same-ID choices preserve vehicle/race/clock/lap/checkpoint references and input. Focused regressions cover deferred restoration, failed track/kart loads, quick-bar precedence and future-version protection.
- **Multiplayer.**
  - `Menu.lobbyPresentation(view)` maps a copied PeerSession view (the fields in [the controller contract](#implemented-pure-peer-session-controller)) to copy and enabled flags.
  - `Menu.SetSessionBridge({view=function})` is an implemented optional copied-view registration point. It does not bind transport actions or handle the newer coordinated clock phases; actual backend wiring still requires review.
  - No command is wired. Without a bridge, Host, Join, Ready, Start and Leave stay disabled and marked Coming soon.
- **Sounds.** `PlaySound(SOUNDKIT[name])`, guarded and muted by a setting: menu open/click/check, 3-2-1-GO, and one fanfare per finished run.
- **Counts.** The original solo Menu brought the pool to65/160/79; the integrated city screen/gates and staging background bring the current total to71frames/165textures/80fonts, all created with the window.

<a id="proposed-capital-cities-cup-city-circuits-and-the-course-catalog"></a>

### Implemented: Capital Cities Cup, city circuits and the course catalog

Integrated from `claude/capital-cup`78d97a1 on2026-10-22 after Codex collision/transaction review. New background loads use a pooled staging texture; failed loads leave the current texture/crop, track and stopped run unchanged. The owner has driven Stormwind and confirmed the reported corner correction works (2026-10-22); comprehensive native acceptance remains open. Ironforge from Claude `de2fa5f` is now integrated with the existing exposed-wall correction, without changing its art/route. Claude's current handoff quotes the owner's drive of version2 and subsequent design requests. Version3 native appearance, tunnel width/handling and performance remain NOT RUN. See [the Stormwind sheet](art/tracks/stormwind.md) and [Ironforge review](reviews/2026-10-22-ironforge-integration.md).

- **`Circuit.new(definition, crossesGate)`** (new pure module; **Codex: collision reviewed**). Builds a street circuit from data with the track interface above (`spawn`, `isDrivable`, `surfaceAt`, `constrainPosition`, `resolveMovement`, `gates`, `checkpointMaxStep`). Definition: `id, version, name, width, height, wallInset, roadRadius, wallRadius?, fullSpeedToWalls?, wallClearance?, wallVertices?, narrows?, centerline` (closed), `branches?` (open roads, such as a start grid's approach), `plazas?` (`{ax,ay,bx,by,radius}` paved capsules), `gates, spawn, solids?` (`{id,x,y,width,height}`).
  - Surfaces: within `roadRadius` of the course (or on a plaza) is `"road"`; within `wallRadius` is `"grass"` (Physics' existing rough response); beyond is `"wall"`; so is a solid's footprint. Without `wallRadius` the ground beyond the road stays rough to the perimeter, as on Mirage Raceway.
  - `resolveMovement`: the perimeter clamp and the solids' swept boxes exactly as Track.lua's test-oval crates (18-unit clearance), then the street walls: an end point beyond them moves to the nearest drivable point (a smooth slide along a curving wall) and reports a hit; Physics scrubs speed as at any wall. A resolved step never moves further than requested (it stays put instead), so `checkpointMaxStep=5` still holds. A centre that starts outside the street (never by driving) is moved to the nearest drivable point.
  - Optional `fullSpeedToWalls=true` classifies the entire non-wall corridor as road for Physics/isDrivable; default false retains rough shoulders. Stormwind version3 retains it: full normal speed, drift and boost up to the existing wall. Painted roadRadius and collision wallRadius are unchanged, and other tracks retain their surfaces.
  - Optional `wallClearance` plus generated `wallVertices` enables clearance from the exposed union of visual capsules (radius wallRadius+wallClearance). The old individual-radius union remains a safe fast path; exposed arc/line projections and generated junctions determine added usable concave-corner space. Stormwind version3 uses14-unit clearance and1,025 precomputed junction candidates, retaining version2 full road grip. Ironforge version3 uses14-unit clearance and1,682 junctions, retaining rough shoulders outside its two tunnels (version2 had1,745 junctions). Other definitions without the optional metadata retain their original surface boundary.
  - **Implemented and reviewed (2026-10-22, Claude `9461f9c` integrated on `codex/ironforge-narrows`): optional `narrows={{name?, first, last, wallRadius}...}`** (requires `wallRadius`). Loop segments `first..last` (segment k joins `centerline[k]` to `centerline[k%n+1]`; integers, `1 <= first <= last <= n`) are drivable to the narrows' own `0 < wallRadius <= definition.wallRadius` and paved to `min(roadRadius, wallRadius)`, so a narrows below `roadRadius` has no rough strip at all. Everything else is the existing per-capsule machinery: the visual capsule is the narrows' radius plus `wallClearance`, `scripts/circuit_boundary.py` (`loop_radii`) generates `wallVertices` from the same per-segment radii, the painter paints the street from them, and the track exposes a copy as `track.narrows`. Additive: definitions without `narrows` build exactly as before (Stormwind's generated data and picture are byte-identical). Invalid entries are refused at construction; overlapping entries take the minimum radius. Branches/plazas are unchanged. Only explicit all-road narrowed capsules mark their valid added exposed-corner clearance space as road; ordinary/plaza corners and the existing wide-shoulder fast path retain prior surfaces. The exact entrance-tunnel corner regression prevents a hidden rough pocket. The Python helper also rejects boolean indexes/radii, matching Lua numeric validation. Closing-segment, overlap and independent metadata-copy regressions cover the added contract. Ironforge version3 uses two (the Forlorn Cavern's entrance and exit, `wallRadius` 42: the painted wall at the paving's edge, 56, minus the 14-unit clearance), per the owner's request after driving version2. Evidence: `tests/test_circuit.lua` (a narrowed square side: road to 15 then wall, untouched shoulders elsewhere, exact free movement, wall contact, six invalid definitions; Ironforge's narrows road/wall either side, shoulders before them, a steer-into-the-tunnel-wall drive), `tests/test_circuit_boundary.py` (narrow/wide join vertices, invalid narrows), and Claude's separately reported offline probe comparing `surfaceAt` with an independent disc-inside-union test at 21,761 points round the four tunnel ends: no mismatch.
  - A64-unit grid indexes capsules and boundary vertices at construction; no geometry generation, UI allocation or asset sampling occurs per step. Generated coordinates use exactly the rounded runtime capsules; artwork remains separate. This revision changes only Ironforge artwork, preserving Stormwind and every other runtime asset.
  - Street endpoint resolution considers allowed projection candidates inside the requested displacement bound before ranking, including movement/vertex-clearance circle intersections for a bounded concave slide. Perimeter/solids sweeps are unchanged. This is still the existing endpoint-based street model with radial clearance, not a new oriented-body or continuous-street sweep guarantee.
  - The factory supports solid scenery for future reviewed definitions, following the city direction recorded in Claude's handoff. The shipped Stormwind definition has no solids or plazas. Mirage remains obstacle-free; this integration adds no solid fixture outside Test Oval.
- **`CapitalCities`** (generated data, `scripts/build_city_tracks.py`): `CapitalCities[id]` definitions for `Circuit.new`. Stormwind City Circuit: 2048×2048, road radius 56, wall radius 76, no plazas or solids (the 2026-10-22 rework removed the first build's plaza and fountain), six gates, a 3,831-unit loop and a 769-unit approach branch. Ironforge Grand Prix (`ironforge_gp`, version3): 2048×2048, the same radii, no plazas or solids, seven gates, a 7,077-unit loop and a 369-unit approach branch. Integrated version3 from `claude/ironforge-design` adds the two Forlorn Cavern `narrows` above; route, gates, spawn and the rest of the street are unchanged.
- **`Courses`** (new module, Claude: presentation data): `CUPS` (Proving Grounds, Capital Cities Cup); `LIST` in display order with `id, name, short?, cup, geometry ("oval" | "mirage" | "city"), background?, rough?, dust?, ground?, status, soon?`; `get(id)`, `available(id)`, `next(id)` (the next available course, wrapping), `build(id, crossesGate)` (the oval singleton, a fresh Mirage track, or `Circuit.new(CapitalCities[id])`; built once and kept). The four other cities are listed `soon`: shown, not selectable.
- **`UI.SelectTrack(id)`** (**Codex: reviewed transaction**). Available IDs come from `Courses`; the track comes from `Courses.build`. The stopped/shown/out-of-combat and same-ID guards remain. A course background is UV-validated and loaded on a preallocated hidden staging texture. Only a successful guarded load swaps it into the visible slot; failed/throwing loads do not touch the old picture/crop/path or authoritative run. Both textures are pooled at window creation; no rollback load of the visible texture is required. The previous hidden picture can remain resident alongside the current one (up to32MiB of raw city pixels across two2048-square images, excluding preview textures/native overhead); this is bounded retention, not a memory benchmark. Catalog text supplies the button/status. Successful selection resets local run samples as before.
- **Track button** (**Codex**): steps through `Courses.next`, skipping a course that refuses to load on that click; still disabled while a run is active.
- **Visual (Claude):** eight pooled gate strips (the most gates a course has; unused ones hidden), the follow camera and ground colour for every course with a background, the effects' dust colour and the HUD's off-road wording from the catalog, the Oval's crate markers only on the Oval.
- **Menu (Claude):** the track screen lists the cups with their tracks, the coming-soon cities disabled; each track's preview comes from its own picture (cities: `Assets/Tracks/<City>/Preview.tga`, 512×512), loaded once per change with the usual guard. The saved track accepts any `Courses.available` id.
- **Multiplayer:** SessionTransport's supported track list is Codex's; neither city is in its compatibility list; city multiplayer is not wired.
- **Counts:** 71 frames, 165 textures and 80 font strings (eight track buttons, two cup headings and four more gate strips than the front end's 65/160/79), still created once with the window.

## Rendering cadence, resources and lifecycle

Rendering currently runs once per delivered active `OnUpdate`, after zero or more fixed steps; it is not locked to 60 FPS and has no separate render timer. Meter, gate colors and countdown update through the render path with cached values. The numeric HUD refreshes every ≥0.25 **simulated** seconds, on lap/status changes and immediately at Start/Stop/selection. UI lifecycle events may draw outside `OnUpdate`. Inactive `UI.OnUpdate` does no simulation work; a shown kart/garage preview has its own visual spin callback, independent of race ticks.

The window is 856×762 with an 800×480 canvas. Current integrated explicit allocations are **71 frames, 165 textures, 80 font strings**, including the pooled front end ([above](#implemented-front-end-menus-race-hud-and-results)). The preceding roster/results baseline was 11/151/13, including two Oval obstacle markers, Close results/Kart buttons and 38 effect textures. The 96 retained Oval bands, eight gate strips (unused strips hidden), four perimeter strips, two background slots and one kart remain pooled. Markers render the physical rectangles in ARTWORK at Oval's fixed scale and stay hidden on Mirage, including camera updates. Counts exclude Core's event frame, template/native internals and other addons. They are offline-checked explicit allocations; the earlier 9/111/13 baseline has scoped client observations. These counts are not a client memory/FPS measurement or a ban on reviewed pool changes.

Preserve creation-time pooling: no `CreateFrame`/`CreateTexture`/font-string creation, texture file loads or chat output per simulation tick or render callback. Current snapshots allocate bounded Lua tables per tick; there is no promise of zero Lua allocation. Profile before replacing their immutable-style behavior. Opt-in Performance collects at most 600 callback spans and includes instrumentation overhead; it is not exclusive CPU/GPU cost.

`UI.SelectTrack(id) -> boolean` accepts available Courses IDs (`"test_oval"`, `"mirage_raceway"`, `"stormwind_city"`, `"ironforge_gp"`) only with an existing shown window, while stopped and out of combat. The staging texture's guarded `SetTexture` must return true; its guarded UV check must succeed before committing the switch. Failure preserves the old track/run/sample. Successful selection clears samples and creates a new spawn/lap state; loaded artwork is reused. The Track button is disabled while active; clicking a disabled selector does not stop a run. Test Oval is the default after reload; `UI` itself does not persist the selection. The integrated front end saves deliberate successful choices, including the already-current ID, and restores the saved choice through this function ([above](#implemented-front-end-menus-race-hud-and-results)). UI's same-ID early return and guarded failure/reset transaction are unchanged.

Capture/release safeguards and combat/lifecycle handling remain controller-owned. Under the owner's revised input policy, incidental mouse clicks and unassigned keys leave the run active; there is no global-mouse event requirement for Start. Stop, Escape and Close deliberately end the run; Enter and detected chat/text focus release racing input, as do supported focus-loss and lifecycle paths. Required keyboard capture/propagation and text-focus capabilities still gate Start, and capture never automatically resumes. Build 70450 lacks `IsGameWindowFocused`/`IsWindowFocused`; full held-input focus-loss behavior remains unverified. Do not substitute guessed protected APIs or make global WoW movement bindings part of rendering. See [FEASIBILITY](FEASIBILITY.md) and [ADR 0006](adr/0006-combat-interrupted-results.md).

## Proposed changes require coordination

Possible future work includes an explicit render snapshot/scene boundary, collision feedback events, additional sprite atlases/animation, foreground occlusion, track hashes, saved race records and multiplayer snapshots. None is a callable contract today. Do not implement an architecture sketch as though its fields already exist. Agree a contract/ADR update and compatibility impact before adding or renaming authoritative fields, changing units/tick semantics, track geometry or lifecycle callbacks. The optional Test Oval movement hook and version changes described above are implemented in this slice; the future boundaries listed here are not.

Offline state/geometry/UI-mock checks are evidence of those scopes only. Opaque Mirage texture loading and the stopped close-camera view were observed in the client; the owner subsequently approved the installed trike and scenery shadows. Combined-build menu behavior, moving camera edges, latest handling acceptance and sustained performance require their own evidence. AKT722–725 record the scoped transport/reload evidence; they do not establish playable replication or production architecture.

## Implemented opt-in start clock and backend race initialization

[START_CLOCK](START_CLOCK.md) is the exact additive contract for `ClockProtocol`, `StartClock`, `RaceStart`, `PeerSession.handoffStart`, `Race.newRunning`, and SessionTransport's `HostCoordinated/ListenCoordinated/PrepareStart/TakeRaceStart`. Existing control APIs and solo `UI.Start` are unchanged. Coordinated mode adds copied `clock` diagnostics and `canPrepareStart`, owns its proposal internally and yields one actual tick-zero Physics/Race bundle at mapped GO, without opening UI or running an opponent.

These interfaces are retained in the combined source; binding them to Claude's multiplayer menu still requires shared review. Frontend code invokes deliberate actions and reads copied views; it must not consume backend tickets/bundles or write authoritative state. A lost final ACK can leave only the guest armed. Clock uncertainty excludes separately allowed callback lateness; source/mock results do not establish actual synchronized race feel. Native clock traffic shares existing persistent budget/lease. Actual client checks and movement/finish integration remain open under [ADR 0014](adr/0014-experimental-start-clock.md).
