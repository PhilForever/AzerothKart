# Multiplayer results and same-player rematches

Implemented on `codex/multiplayer-rematch` for the existing two-player mode.
Both players need the matching build. Native acceptance remains pending.

## Player flow

1. Finish: controls release immediately. A missing peer finish stays pending,
   without an invented rank. Both observed finishes produce local placements.
2. **Play Again** keeps the selected friend, roles and kart. The host offers
   another race on the same map. The guest joins that offer; both Ready, host
   Start. Names and codes need no retyping.
3. **Change Map** opens the retained lobby for the host. Cycle the seven lap
   maps, then Play Again to offer the staged choice. The guest sees the actual
   offered map after the invitation; its results button is **Lobby**.
4. Guest Play Again joins an already-arrived offer. Before the host offers,
   it opens the room; use Join Received Invite when available, then Ready.
5. **Close results** keeps the room. Solo Start and independent map/kart
   selectors stay blocked. **Leave Multiplayer** explicitly restores them.

Postrace idles for at most300seconds. Error/expiry/combat/world exits close
the backend room with no automatic driving or interrupted-race resumption.
Kart changes are deferred from this rematch slice. As of2026-10-27, all eleven
courses, including four one-run Scarlet sprints, use this two-peer room. The
host can rematch from a circuit to a sprint with the target validated anew.
This is not eight-player support.

## Copied observations

`LiveRace.results(token)` returns detached
`{session,trackId,trackVersion,verified=false,complete,rows}`. Each of two rows
has `name` (You or the complete native peer), `localPlayer`, `status` (finished,
pending, stopped), `completedLaps` and finished-only `totalTicks`. Local time
is frozen Race.totalTicks; peer time is its validated terminal simulation tick.
Both start at tick0 after GO. sampleMS is a callback stamp, not a finish time.

Ranks appear only when both finish. Equal ticks share rank1 and `tie=true`;
complete rows are ordered by local rank. Missing/stopped results never receive
fabricated times. These are unverified local observations of reported state,
not authenticated winners. Late finishes refresh rows without changing the
local race object or replaying fanfare. Multiplayer never publishes solo scores.

## Backend contract and bounds

- `PeerSession.enterPostRace(state,now)`: actual racing→postrace; clears ready,
  start and pending ACK state; idle deadline300seconds. Existing joined-lobby
  timeouts remain unchanged.
- `PeerSession.nextSession(code)`: next six-character base36 code. Refuse wrap,
  used-code collisions and native64-session exhaustion; never skip differently
  on each peer or reuse a round identifier.
- `SessionTransport.Rematch(trackId?)`: host-only postrace; rebuild current
  geometry/version metadata and atomically commit a fresh controller/offer with
  the same peer/role/kart. No simulation or capture. Retain Core lease, hooks
  and persistent send accounting.
- Guest next-offer admission requires the expected fresh code, scoped native
  peer and logged WHISPER. Validate the candidate before swapping/consuming its
  code. A locally finished guest may still be draining poses; a running guest
  cannot be interrupted. Join/Ready/Start remain explicit.
- Candidate attempts are bounded before geometry copies. Dependency exceptions
  close safely and cannot strand busy; nested native-send markers unwind under
  their original owner.
- GetView adds copied `room`, `results`, `canRematch`, `canChangeMap`. The next
  pre-GO lobby has `live=nil` with prior results retained. UI adopts a fresh
  session only at deliberate Ready/grid/GO.
- UI actions `return_lobby`, host `rematch(trackId?)`, and explicit `leave`
  preserve mode. Staged map choices are offered only by Rematch. Capabilities
  are revalidated per action; solo selectors cannot dissolve the room.
- Postrace retains the Core lease until rematch/leave/expiry; score sends yield
  to it. No heartbeat is added. All existing packets keep2attempts/second,
 0.5second spacing and158-byte rolling ceiling. Layout/prefix/version unchanged.

## Validation and next check

Actual Lua51 tests cover copied/tied/pending results, exits/expiry, stale/foreign
offers, session exhaustion, dependency failure/reentry, and two completed races
through actual Core/Menu/UI/transport callbacks with a map change and new full
countdown. A bounded waypoint finish tape uses actual Race/Checkpoints/Laps;
it is a flow/rules test, not a native handling/network measurement. No additional
UI widgets or solo scores appear; cross-round traffic bounds remain tested.

Native rematch/placement/latency feel and turning verification are **NOT RUN**.
Next friend check: one normal race, Play Again, then Change Map. No standalone
transport probe is required. No M6/M7/eight-player/release gate closes here.
