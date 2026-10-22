# Experimental live-race backend

Implemented on `codex/live-race-controller`, from4544108, within the accepted
[two-peer experiment](adr/0013-two-player-experiment-scope.md). This is a pure
backend lifecycle and observational pose path. **Not connected to the native
transport or menus yet; it is not a playable friend-race build.** No production
authority, kart contact, agreed results or release decision is made here.

## Ownership and activation

`LiveRace.lua` consumes an actual tick-zero running bundle from
[`RaceStart`](START_CLOCK.md). `LiveRace.new(bundle, fullPeerName, nowMS, modules)`
returns an opaque local token or `nil,fixedReason`. `modules` supplies existing
Physics, Race, Checkpoints, Laps, Loop and LiveProtocol modules. Admission is
between mapped GO and GO+250ms inclusive, with Physics version7/fixed1/60dt,
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
liveness. Age over1500ms marks remoteStale without extrapolation. At most the
latest two observations are kept; there is no packet history allocation. The
common update/advance deadline check enforces frozen-progress timeout even if
no further packet arrives. Duration is capped at30minutes/108000 driving ticks.
Scoped events are capped at eight per rolling second, including malformed and
duplicate traffic. No automatic recovery/rejoin is implemented.

## Observational wire format

`LiveProtocol.lua`: VERSION1, separate prefix `AZKRUN1`, exactly34 uppercase
ASCII/base36 bytes. Unknown fields, metatables, invalid types, noncanonical
lengths/alphabet, NaN/infinity, bad bounds and wrong versions are refused.

| Field | Bytes | Range/meaning |
|---|---:|---|
| version/kind/session/sequence | 11 | 1/S, six-character session, sequence1..46655; no wrap |
| tick | 6 | sender simulation tick0..108000, not a trusted timestamp |
| x/y | 3 each | quarter-unit positions0..11663.75; controller rounds, codec does not |
| headingQ | 3 | integer0..46655, one turn divided into46656 bins |
| speedQ | 3 | tenths of a world unit/second, -550..2600; encoded with +550 offset |
| driftTier/boosting | 1 each | 0..2, strict boolean |
| completedLaps/passed/status | 1 each | 0..3, 0..8, running/finished/stopped/interrupted |

The controller further restricts coordinates to this map, passed to the current
gate count and finished to completedLaps3/passed0. Backward ticks and attempts to
revert a finished observation are refused. These are corruption guards, not
physical trajectory validation, anti-cheat or trusted remote race progress.

Output is latest-only at most every500ms, two calls and158 payload-plus-prefix
bytes per rolling second, with no ACK per pose, queue replay or catch-up burst.
Each pose is41bytes including its7-byte prefix:82B/s per peer,164B/s per pair at
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

Native AZKRUN1 delivery, bidirectional race traffic, input/canvas/menu activation,
remote sprite interpolation/appearance, start skew/drift and actual game feel
are **NOT RUN/unimplemented**. Test Oval and Mirage remain the existing session
codec's only negotiated tracks; five solo maps do not imply five network maps.
Production authority/correction/finish reconciliation and socket recovery stay
open. No new manual probe or friend download is needed for this source slice.

Next single task: add opt-in atomic live adoption inside SessionTransport,
preserving its existing frame lease/persistent budgets and testing the complete
two-peer negotiated-GO-to-live path with mocked native delivery. Reviewed
Claude menu/canvas binding then makes a friend-testable candidate.
