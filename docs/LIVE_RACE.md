# Experimental live-race backend

The [postrace room extension](MULTIPLAYER_POSTRACE.md),2026-10-26, supersedes
older completion cleanup notes below. Clean completion retains selected players
and observed results for a bounded rematch interval; fresh sessions reuse the
existing control/grid/clock packets. No trusted winner, higher traffic budget
or native rematch acceptance is claimed.


Current source follow-up,2026-10-25: the opponent display covers mapped packet
age plus the next update interval, bounded to1250ms, and corrects the previous
chord to the current tangent. Same-millisecond packets are distinguished by
sample/sequence. Existing500ms callers remain compatible. Physics, wire budget,
first-wall freeze and unverified remote authority stay unchanged. Synthetic
straight/turn metrics are in FEASIBILITY; native feel remains NOT RUN. The
[eight-player fan-out check](GROUP_DELIVERY.md) is opt-in and does not activate
another race route or require grouping for the current two-player game.

Implemented on `codex/live-race-controller`, from4544108, within the accepted
[two-peer experiment](adr/0013-two-player-experiment-scope.md). This is a pure
backend lifecycle and observational pose path. The subsequent native/menu/canvas
integration on `codex/live-multiplayer-integration` now makes an opt-in friend-test
candidate. The [first owner-reported race](evidence/2026-10-23-first-live-race.md) completed locally on both peers, exposing countdown/sprite/delay issues. The revised grid/display candidate’s native checks are **NOT RUN**. No production
authority, kart contact, agreed results or release decision is made here.

## Ownership and activation

`LiveRace.lua` consumes an actual tick-zero running bundle from
[`RaceStart`](START_CLOCK.md). `LiveRace.new(bundle, fullPeerName, nowMS, modules)`
returns an opaque local token or `nil,fixedReason`. `modules` supplies existing
Physics, Race, Checkpoints, Laps, Loop and LiveProtocol modules. Admission is
between mapped GO and GO+250ms inclusive, with the negotiated Physics version12/fixed1/60dt,
three laps, one to eight gates and coordinates within the codec's bounds.

The bundle's data is copied; read-only geometry closures remain shared. One
bundle can be claimed only once. It is reserved before the injected clock
initializer, so an initializer exception, malformed return or reentrant attempt
cannot create a second owner. Token fields are not authoritative; this is local
ownership discipline, not a security boundary against other addons. A duplicate
copy of a bundle is not a second valid backend launch. The native adapter must
still be the sole consumer of the exactly-once GO gate.

No call opens UI, captures keys, creates widgets, prints chat or invokes a native
API. Claude's art, menu and renderer are unchanged. The module is loaded inertly
after RaceStart/LiveProtocol in both TOCs.

## Implemented calls

| Call | Behavior |
|---|---|
| `advance(token, nowMS, input)` | Samples only the five boolean driving fields; advances real Physics/Race with the existing 60Hz Loop and five-step catch-up cap. Returns executed count, or nil/reason. |
| `update(token, nowMS, sendFn, sendAllowed?)` | Sole output path. Injected callback receives payload, full target name, prefix and returns accepted/failed/throttled/unknown. At most one attempt; false external permission consumes nothing. Returns true on accepted output, otherwise false/reason. |
| `receive(token, nowMS, prefix, payload, channel, nativeSender)` | Requires exact live prefix, native WHISPER and complete scoped peer identity, then strict session/sequence/tick/bounds validation. Returns true or false/reason. Never sends from receipt. |
| `stop(token, nowMS, reason)` | Freezes actual partial state once and clears output. Combat records interrupted; other exits stopped. No resume/rearm. The future adapter owns any paced best-effort peer cancellation. |
| `view(token)` | Copied local/previous vehicle, Race, Loop/alpha, compatibility/clock metadata, last two received poses, their arrival times and local counters. No live mutable state references. |

Times are explicit nonnegative integer monotonic milliseconds. Backward or bad
time closes. Time starts at actual adoption, with no pre-GO simulation or late
catch-up. Input changes are sampled once per advance and used for its bounded
fixed ticks. Hitch drops stay accounted in Loop; they are not recovered through
network state. Local finish stops exactly at its finish tick, including inside
a multi-step callback. Rendering must not call advance or consume start bundles.

Phases are running, finishing and closed. A local finish retains a frozen exact
pose while outputting a finished observation. After at least three accepted
finished observations and a remote finished observation, the local run closes
as `completed_unverified`; `resultVerified=false` throughout. A received stopped
or interrupted pose closes with peer_stopped. No winner or shared standings are
calculated, and a remote progress claim never awards a local checkpoint/lap.

Peer silence, or frozen running ticks despite fresh sequence numbers, closes
at five seconds; stale/duplicate/wrong-session/invalid packets do not renew
liveness. Age over1500ms marks remoteStale. Presentation may forecast through the read-only geometry helper with a500ms default or optional1250ms maximum horizon; authoritative local simulation is never extrapolated from received poses. Translation stops at first contact; bounded running yaw continues independently even at zero speed. A display-only shortest-arc6rad/s limit reconciles packet heading changes using the copied controller clock, with no extra packet or UI object. Directional sprites remain unrotated. The owner reports smoother native straight-line movement; this turning follow-up is offline-tested only. At most the
latest two observations are kept; there is no packet history allocation. The
common update/advance deadline check enforces frozen-progress timeout even if
no further packet arrives. Duration is capped at30minutes/108000 driving ticks.
Scoped events are capped at eight per rolling second, including malformed and
duplicate traffic. No automatic recovery/rejoin is implemented.

## Observational wire format

`LiveProtocol.lua`: VERSION2, separate prefix `AZKRUN2`, exactly40 uppercase
ASCII/base36 bytes. Unknown fields, metatables, invalid types, noncanonical
lengths/alphabet, NaN/infinity, bad bounds and wrong versions are refused.

| Field | Bytes | Range/meaning |
|---|---:|---|
| version/kind/session/sequence | 11 | 2/S, six-character session, sequence1..46655; no wrap |
| tick | 6 | sender simulation tick0..108000, not a trusted timestamp |
| x/y | 3 each | quarter-unit positions0..11663.75; controller rounds, codec does not |
| headingQ | 3 | integer0..46655, one turn divided into46656 bins |
| speedQ | 3 | tenths of a world unit/second, -550..2600; encoded with +550 offset |
| driftTier/boosting | 1 each | 0..2, strict boolean |
| completedLaps/passed/status | 1 each | 0..3, 0..8, running/finished/stopped/interrupted |
| sampleMS | 6 | integer0..1800000, sender sample time relative to its mapped GO; monotonic |

The controller further restricts coordinates to this map, passed to the current
gate count and finished to completedLaps3/passed0. Backward ticks and attempts to
revert a finished observation are refused. These are corruption guards, not
physical trajectory validation, anti-cheat or trusted remote race progress.

Output is latest-only at most every500ms, two calls and158 payload-plus-prefix
bytes per rolling second, with no ACK per pose, queue replay or catch-up burst.
Each pose is47bytes including its7-byte prefix:94B/s per peer,188B/s per pair at
nominal2Hz, before unmeasured native overhead. All attempts, including failures,
are charged. Unknown/failed/throttled/thrown send outcomes close without retry.
Reentrant sends/advance are refused; reentrant Stop cannot be undone by a send
completion. Identical snapshot payloads with new sequences are heartbeat data,
not proof of movement; running progress timeout still applies.

These **per-run** guards do not replace SessionTransport's persistent native
budget. Do not create a separate native sender or call TakeRaceStart followed
by a fresh frame lease. Native integration must retain that same adapter owner,
send accounting and cross-prefix/cross-phase pacing atomically at GO; legacy
TakeRaceStart release semantics must remain compatible. Only then may the
player UI deliberately activate the adopted race through a reviewed API.

## Executed evidence and remaining boundary

Focused actual Lua5.1 tests use real Physics/Loop/Checkpoints/Laps/Race/RaceStart,
synthetic independent clocks five seconds apart and350ms one-way packet delay.
Both peers run1200 equal-input ticks over20seconds and41 accepted snapshot
attempts each; local rolling call/byte caps are asserted. Additional checks cover
one-shot/reentrant initialization, malformed data, unauthorized peers, aliases,
stale/reordered packets, flood/timeouts, hitches, exact finish, stop/combat and
send failures. These are offline tests, not measured network results.

That original backend-only checkpoint did not test native delivery or appearance.
Later native integration and owner feedback are recorded below; revised grid/sprite/forecast
behavior, start skew/drift and corrected game feel remain **NOT RUN** in the client. The session codec now negotiates all six finished production maps in the existing two-peer controller; Test Oval is retired. Native city multiplayer remains unverified.
Production authority/correction/finish reconciliation and socket recovery stay
open. No new manual probe or friend download is needed for this source slice.

Next single task: add opt-in atomic live adoption inside SessionTransport,
preserving its existing frame lease/persistent budgets and testing the complete
two-peer negotiated-GO-to-live path with mocked native delivery. Reviewed
Claude menu/canvas binding then makes a friend-testable candidate.

## Implemented native and player-flow integration

SessionTransport now exposes `HostLive(peer,code,trackId,kartId?)` / `ListenLive(peer,code,kartId?)` (default trike)
in addition to the unchanged legacy/coordinated actions. Join, Ready and
PrepareStart remain explicit. Live mode registers AZKRUN2 and AZKGRD1 only on explicit arm. Bounded immutable kart profiles must be agreed before Ready/Start are enabled. At GO,
the native Update consumes its private initializer once, creates LiveRace, then
calls backend-only PeerSession.beginRace. This removes the old30s negotiation
deadline while retaining control state solely for a paced final cancellation.
No hook/lease release or new sender occurs at GO. All four prefixes share the
same persistent0.5s/2calls/158B gate across modes/sessions. Failed/unknown/throttled
live sends close and release immediately, without attempting another notice.

`AdvanceLive(input)` is the UI backend's sole local step entry. It reads guarded
GetTime, samples the existing fixed input and returns a copied LiveRace view.
Terminal views stay available after teardown for input release/results; receipt
never steps local physics. GetView adds liveMode and live, with overall racing/
finishing/closed phases. TakeRaceStart refuses live_start_owned in live mode;
its legacy release behavior remains unchanged outside live mode. Incoming live
poses use the codec/controller guards. Post-GO control CANCEL still passes the
normal peer/session/sequence/conflict validation before retiring the lease.

Core binds the menu's copied view/action bridge after UI.Create. Multiplayer
now supplies full-name/code inputs, supported-track selection, Host/Listen/Join/
Ready/Start/Leave and5Hz visible status refresh. UI.MultiplayerAction validates
commands; deliberate Ready aligns the offered map and arms input eligibility.
Only a matching explicitly readied live session can stage/capture a shown, focused, out-of-combat canvas without text focus. GET READY and the full3–2–1 countdown show both role-specific karts; only GO activates real backend ticks. Host/guest start36units apart on the same line; these copied poses do not modify solo track data. No menu navigation consumes a ticket or starts Physics.

UI reuses its one pooled opponent texture and label for the peer’s chosen atlas (neutral tint; primitive fallback on load failure). A cached path uses sample timestamps, signed speed, measured direction and bounded heading change; rendering samples without allocation or another snapshot interval of delay. UI covers sample age plus600ms, capped1250ms/76points/speed260/yaw3.0rad/s, stopping at track walls/solids. sampleAgeMS is an estimate using the existing mapped epochs, not measured one-way latency. Unknown steering/braking, hitches and clock uncertainty can still cause corrections. Stale data fades; off-screen direction/distance is not a placement claim. Actual usefulness remains a playtest question. Explicit object
pool now79frames/166textures/81fonts, including four additional menu controls.
No widgets are created during driving.

Stop/Leave/Close release input before native cancellation checks. Pending
invitations close even before Ready. Combat/world/logout use hard teardown.
Local finish releases capture but allows final observations/drain; results are
labelled unverified. Restart waits for native closure; no auto-resume exists.
Changing solo track after closure hides old observations. [Simple friend-test
steps](MULTIPLAYER_PLAYTEST.md) are the next actual-client check, not another
standalone transport probe. All seven finished lap maps now negotiate through the same two-peer controller; native city multiplayer remains pending.

Actual Lua5.1 mocked integration loads both complete TOCs/Core/menu/UI/native
adapters, drives Listen/Host/Join/Ready/Start through700ms synthetic RTT and5s
clock offset, captures at GO, advances180 real window frames and displays moving
observations, then Stop freezes both and releases input/lease. Native adapter
regressions additionally run32s and assert one paced cancellation after the old
negotiation deadline. These are offline evidence, not client delivery/feel.
