# Experimental start-clock and race handoff

Implemented on `codex/start-clock`, from `4f9246a`. Shared menu integration and actual Forever validation are pending. This is a bounded two-peer start foundation under [ADR 0013](adr/0013-two-player-experiment-scope.md), not opponent replication or a playable multiplayer claim. [ADR 0014](adr/0014-experimental-start-clock.md) records the timing assumptions and limits.

## Native actions and ownership

Use dot calls on `AzerothKart.SessionTransport`. Existing `Host`, `Listen`, `Start(startTick,seed)` and `TakeStartProposal` retain their legacy parameter-proposal behavior. The opt-in path is additive:

| Call | Implemented behavior |
|---|---|
| `HostCoordinated(fullPeerName,freshCode,trackId)` | Explicitly arm the same logged route plus the separate clock prefix; fixed three laps and actual compatibility versions. |
| `ListenCoordinated(fullHostName,freshCode)` | Explicit guest opt-in; `Join()` and `Ready(bool)` still require deliberate actions. |
| `PrepareStart(seed?)` | Host-only, both ready and local readiness acknowledged. Default seed metadata is zero. Queue START with the existing 180-tick metadata, then negotiate clocks; do not run another solo countdown. No tick/seed UI setting is needed. |
| `GetView()` | Adds `coordinated`, `canPrepareStart`, and copied `clock` diagnostics. `canStart` is false in coordinated mode. |
| `TakeRaceStart()` | **Backend only:** at mapped GO, yield one actual Physics/Race bundle, then release control transport hooks. No canvas, input capture, simulation updates or opponent is created. |

Actions retain `true` or `false,fixedReason`. Legacy `Start` in an active coordinated session refuses `coordinated_start_required`; `TakeStartProposal` refuses `coordinated_start_owned`. Rendering/menu code must consume neither one-shot backend method. Screen navigation never starts physics. `Leave`, hard Stop and lifecycle handling discard an unconsumed launch. New arming still requires a fresh code; mode selection does not bypass session history or the probe lease.

When a valid control proposal is available, `PeerSession.handoffStart(state,nowSeconds)` consumes it once and enters `coordinating` with a fixed 30-second deadline. Host proposal availability still requires its START ACK; guest receipt does not prove that ACK arrived. Duplicate START remains idempotent and re-ACKable; new START/READY transitions are refused. Legacy starting retains its ten-second timeout.

## Clock exchange

`ClockProtocol.lua` is pure, version 1, prefix `AZKCLK1`. It uses the same 11-byte version/kind/session/sequence header shape as the separate control codec, its own sequence space 1–46655, and exact canonical uppercase base36 fields. Seven-digit unsigned integer milliseconds span 0–`36^7-1` (about 906 days); overflow is refused, never wrapped. Signed offsets use a sign plus seven digits, with negative zero refused. Maximum codec envelope is 64 bytes; current messages are:

| Kind | Fields after header | Total bytes |
|---|---|---:|
| PING | sample 1–3, t1 | 19 |
| PONG | sample, t1, t2, t3 | 33 |
| PREPARE | host epoch, offset low, offset high | 34 |
| COMMIT | host epoch | 18 |
| ACK | PREPARE/COMMIT kind and sequence | 15 |
| CANCEL | closed reason | 12 |

`StartClock.new({role,session,seed},nowMS,ClockProtocol)` injects integer monotonic time. `update(state,nowMS,sendFn,sendAllowed?)` alone invokes `sendFn(payload)`, returning accepted/failed/throttled/unknown. `receive`, `view`, `cancel`, and `takeTicket` are pure. Views are copies; controller internals remain Codex-owned. There are no game, UI, input or wall-clock calls.

The host collects three sequential four-timestamp samples. `t1` is formed at the paced host send; `t2` at guest receipt; `t3` at the paced guest send; `t4` at host receipt. Guest queue time is removed:

```
corrected RTT = (t4 - t1) - (t3 - t2)
guest-minus-host offset interval = [t3 - t4 - 2, t2 - t1 + 2] ms
```

RTT outside 0–2000 ms, backward clocks, overflow and empty intersections close negotiation. The three offset intervals are intersected; the guest also checks PREPARE's upper bound against every locally observed `t2-t1+2`. The displayed midpoint is an estimate under an approximately constant offset during this short exchange. `uncertaintyMS=ceil(intervalWidth/2)`, at most 1002 ms, accounts for the interval and millisecond boundary allowance; it is not measured one-way latency, a clock-drift guarantee, authentication or a bound on actual launch skew. Asymmetric paths are allowed; no symmetric-route assumption is used to claim accuracy.

After calibration, the host chooses GO eight seconds ahead. The guest maps it using `floor((low+high)/2)` and requires 3–12 seconds of remaining local lead. PREPARE → ACK → COMMIT → ACK must finish at least one second before each peer's mapped epoch. Host arms after matching COMMIT ACK; guest arms after its own COMMIT ACK was accepted locally. **Final ACK loss can leave only the guest armed. No finite handshake guarantees atomic GO.** The host cancels best effort on failure; a lost cancellation cannot establish peer state.

Pending host commands retry at two seconds, up to three attempts. Payload timestamps stay fixed across retransmissions. A lost calibration packet can therefore make corrected RTT exceed the two-second limit and conservatively abort; recovery then requires a fresh explicit session. PREPARE/COMMIT ACK retries can recover within the finite lead. No automatic restart or socket rejoin exists. The coordinator caps queued/deferred entries at eight, seen sequences at 64 and scoped decoded events at 256; conflicting accepted sequence payloads close. Identical duplicates reuse responses without reapplying state or producing another ticket. ACKs are not ACKed. Reentrant receives are deferred until the native send outcome is accepted; nested updates cannot send or advance the clock.

All output shares SessionTransport's existing persistent local minimum 0.5-second spacing, two calls/158 payload-plus-prefix bytes per rolling second, including both prefixes, control, ACKs, retries and final notices. At most one native call occurs per Update, with no catch-up burst. No competing probe session is allowed. Clock stamps are produced at the paced Update; a native preflight over two milliseconds later refuses that send. These are candidate budgets and source guards, not measured capacity. Hard API/clock/lifecycle failures revoke pending launches. Clock failure uses the existing paced control CANCEL, rather than an additional clock notice stream.

## One-shot race initialization

`StartClock.takeTicket(state,nowMS)` returns only while armed and `localEpochMS <= nowMS <= localEpochMS+250`. A later callback closes; there is no large catch-up simulation. Tickets contain session, role, seed, both epochs, offset interval, uncertainty and `peerAcknowledged` (host true, guest false). Taking a ticket changes clock phase to `launched`; this means handed off locally, not a running network race.

`RaceStart.new(ticket,track,physicsVersion)` captures a validated ticket and copied geometry data behind an opaque local token. `RaceStart.take(token,nowMS,Physics,Race,Checkpoints,Laps)` observes the same GO/250 ms limits, validates dependencies/version, closes before initialization and returns once. Before GO it returns waiting; cancellation, backward time, late time, initializer errors or a second take cannot launch. Geometry functions keep their existing closures, so source factory/module geometry must remain read-only. This is local ownership protection, not a security boundary against other addons.

The bundle contains `session,role,seed,trackId,trackVersion,physicsVersion,localEpochMS,hostEpochMS,uncertaintyMS,peerAcknowledged,track,vehicle,race,fixedDt`. `vehicle=Physics.new(track)` starts at tick zero; additive `Race.newRunning(track,Checkpoints,Laps,0)` starts the actual three-lap race running at tick zero, with no countdown ticks or pre-GO progress. The first driving tick is one. Existing `Race.new` and solo UI behavior are unchanged. Seed is carried as metadata; current Physics has no seeded random subsystem. Identical-input replay tests do not imply gameplay randomness was added.

SessionTransport owns the internal ticket/gate. Its backend take transaction handles exceptions and reentrant Stop without returning a launch, then releases only its own hooks. The consumer owns the returned authoritative bundle; Claude renders borrowed state. A future live controller must preserve the candidate-wide persistent budget and establish race transport ownership, remote-state validation/presentation, correction, teardown and finish agreement. Ordinary `UI.Start()` still stops session transport and creates a solo race; do not call it to activate this bundle.

## Evidence and next boundary

Focused Lua 5.1 tests execute strict codec cases, asymmetric synthetic 700 ms RTT/independent clocks, queued reply subtraction, retries/duplicates/cancellation, inconsistent/late timing, final-ACK ambiguity, native shared budgets and actual Physics/Race initialization plus a 900-tick repeatable input tape. Mocked native peers also exercise delayed delivery and a five-second clock offset. See [PROGRESS](PROGRESS.md) for exact commands/results.

Actual `AZKART2`/`AZKCLK1` registration/delivery, real clock drift/skew, both-client menu/countdown, playable opponent movement, shared standings/finish, packet loss recovery during racing and full socket recovery are **NOT RUN** or not implemented. No new download or manual probe is requested here. Next: a bounded live-race controller and paced remote snapshots consuming this backend handoff, followed by reviewed Claude canvas/menu integration.

## Subsequent pure lifecycle slice

[LiveRace/LiveProtocol](LIVE_RACE.md) now implement the bounded bundle owner, local fixed-step driving and observational pose path on `codex/live-race-controller`. TakeRaceStart and all existing native methods retain their previous semantics. Nothing consumes GO automatically. Next is atomic native adoption retaining SessionTransport's same lease and persistent pacing history, then reviewed Claude canvas/menu binding; do not release/reacquire ownership around that transition.

## Native live adoption now wired

On `codex/live-multiplayer-integration`, explicit HostLive/ListenLive selects the
[opt-in native live path](LIVE_RACE.md#implemented-native-and-player-flow-integration).
Native Update consumes GO without releasing/reacquiring the frame or pacing
history; legacy TakeRaceStart remains compatible outside that mode. Menus never
consume GO. The first friend candidate is wired but actual timing/delivery/feel
checks remain NOT RUN.
