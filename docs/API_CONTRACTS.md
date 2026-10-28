# Implemented simulation and rendering contracts

## Registered Warsong and mixed-version scores — 2026-10-27

Warsong Gulch (`warsong_gulch`, geometry2, three laps) is enabled for solo,
Highscores and the existing two-peer lobby. Race invite code `C`, score code
`W`; these are independent alphabets. Current eleven flat courses keep
Physics12 and their exact board contexts. Warsong alone uses Physics13 and
AZKRUN3; AZKRUN2 and existing handling remain unchanged. Claude0794343's
reviewed tunnel covers, floor sorting, collision-clear route arrow and essential-roof load guards are
integrated without changing authoritative state. Production pool91/96/151
(frames/textures/fontStrings), measured in offline doubles only.

`ScoreSync.PREFIX="AZKSCR2"`, wire schema2, `MAX_BYTES=151` payload. HELLO:
`2 H <catalogue hash> <O M S I D R U T G L A C W digests>`, each digest/hash
exactly8 uppercase hexadecimal characters. Thirteen slots include mandatory
retired O=0; twelve active contexts contain all six exact fields, including
per-map physics, in the catalogue hash. No global physics version is assumed.
HELLO is136 prefix-plus-payload bytes even at maximum digest values. NEW/ROW
keep exact context fields; REQUEST/END bind their course code to the negotiated
catalogue. Direct NEW still requires the event sender to own the record and
match the exact local context, even before HELLO. Hashes detect change; they
are not authentication.

Wire context bounds: track/physics/rules versions1..1295, laps1..9, tickRate60.
Existing Highscores tick/date/name limits apply; a maximum legal NEW/ROW with
96-byte name is150 bytes including prefix. All families enforce151 payload
and the native adapter retains158 total bytes/attempt, one score attempt/s,
Core lease/combat/idle guards. Unsupported current stored rows refuse sharing
initialization without altering saves; historical noncurrent/retired boards
remain stored. No SavedVariables schema change or migration. AZKSCR1/schema1
peers cannot synchronize with this family; both players must update, while
all cached scores remain available. [Decision](adr/0023-mixed-version-score-sync.md).

## Opt-in floors and boost pads — 2026-10-27

[ADR0022](adr/0022-floors-and-boost-pads.md) is accepted for the tested foundation.
[Exact data/signatures/limits](LAYERED_TRACKS.md) govern LayeredTrack, Physics
level/pad state, floor-aware gates/grid and explicitly versioned live telemetry.
Current11tracks stay Physics12 and byte-compatible flat telemetry; opt-in
mechanics13 does not reset their boards. Registered Warsong is described above;
dropdowns and separate-base starts remain unsupported.

## All-course two-peer races and positional continuity — 2026-10-27

All twelve finished Courses are multiplayer eligible, including Warsong above. RaceProtocol adds stable
invite track codes8/9/A/B for Graveyard/Library/Armory/Cathedral, preserving1–7
and retired0, prefix/layout/length unchanged. Both clients must update for
sprint offers; older builds reject their unknown codes. Score codes/contexts
are independent and unchanged.

`PeerSession.new(options,now,codec)` adds optional plain `trackLaps` keyed by
every offered `trackVersions` ID, values integer1..9, copied on construction;
extra/missing keys reject. When omitted, legacy global `laps` behavior remains.
The native adapter always supplies geometry-derived targets (sprint1/circuit3),
and validates received offers/clock handoff against the captured geometry.
LiveRace.new requires `race.targetLaps == (track.laps or3)` in the supported1..3
range. Live.receive rejects completedLaps above target, wrong finished count
and terminal gate progress. No state packet, cadence or158-byte budget change.

`Presentation.remoteCorrection(offsetX,offsetY,elapsedMS)` returns two scalars:
bounded decay toward zero (80ms time constant, correction speed<=400units/s,
at most100ms per draw). Zero/invalid time cannot advance; invalid offsets clear.
UI caches only display scalars and continues the old path at the new packet's
current copied timestamp before rebasing onto the new forecast. Normal straight
prediction gains no receive-time interpolation delay. Corrected segments sweep
through existing track geometry; invalid oversized recovery is rejected.
Only a geometry-blocked episode has a600ms deadline, not renewed by packets;
when no smooth legal connection is possible, the display reseeds the latest
forecast rather than sticking forever. Ordinary continuous steering corrections
have no forced periodic reseed. Grid/session/Stop/stale/terminal views clear the
history. No authoritative state writes or UI object allocation; native feel
remains NOT RUN. [Focused check/evidence](MULTIPLAYER_PLAYTEST.md).

## Reviewed Claude visual integration — 2026-10-26

The Scarlet-v3/race-screens/Gryphon stack is accepted with the corrections in
the implemented sections below. No authoritative Physics, Race, room or wire
API changes. Current Scarlet versions are G3/L3/A2/C3; saved older contexts
remain intact. Production pool90frames/91textures/150fontStrings is counted
offline. Native appearance, sound and memory/hitch behavior remain NOT RUN.

`SoloRecords.Finish` adds `playerName` on a saved PB, captured once from the
same identity used in the stored record. Optional detached `placement` is the
exact successful finish transaction's `{rank,previousRank,tier,enteredTier,
knownPlayers,scope="known_board"}`. No placement means no ranked celebration;
matching ticks or newest cached rows must never infer the finisher. Existing
saved/message/totalTicks return fields and failure behavior remain compatible.
`ScoreSharing.Publish(record, priorPersonal?)` preserves its optional notice as first return
and adds detached placement as second return. A later board refresh does not
reinterpret or replay the captured finish. These are known community ranks,
not a complete authenticated global ranking. SoloRecords supplies its validated
pre-finish personal snapshot for lazy initialization, so the first save is not
preseeded as its own previous result. The already captured record name is reused
for this cold path. Existing one-argument callers remain supported.

Final multiplayer visuals consume `UI.multiplayerResults` from LiveRace.results,
retaining tied/pending/stopped semantics and the unverified notice. Only the
in-race progress estimate uses Presentation helpers. Quiet RefreshResults
updates late rows without another sound. Play Again/Change Map/Leave retain
the postrace commands below, including when the next room has no live view.

## Multiplayer postrace room — 2026-10-26

[ADR0021](adr/0021-multiplayer-postrace-room.md) and the
[implemented view/actions](MULTIPLAYER_POSTRACE.md) add local-observed result
rows and a bounded same-player room. `LiveRace.results(token)` returns detached
`{session,trackId,trackVersion,verified=false,complete,rows}`. Rank appears only
after both finishes, joint rank1 on equal ticks. Durations use local totalTicks
and the peer's terminal tick; missing finish is pending, sampleMS is not time.
UI refreshes rows without replaying fanfare; multiplayer never submits solo
records. `PeerSession.enterPostRace` clears readiness for a300-second idle room;
nextSession derives a fresh code with wrap/collision refused. Host-only
`SessionTransport.Rematch(trackId?)` and copied room/results/canRematch/
canChangeMap preserve identity, geometry checks, lease and pacing. Guest still
joins/readies explicitly. UI return_lobby/rematch retain mode; explicit Leave
restores public solo selectors/Start. No new widgets or packet formats.

## Scarlet Cup integration — 2026-10-26

The reviewed combination with Claude ea4425d retains all current Codex APIs
and retires no saved data. Courses exposes eleven production tracks: seven
three-lap circuits for solo/current two-peer races and four solo dungeon
sprints. Scarlet Library/Armory/Cathedral add score codes L/A/C. ScoreSync has
eleven active contexts and twelve HELLO digest slots; retired O must be zero
in both encode/decode. Maximum legal HELLO is155bytes including prefix, below
the unchanged158-byte native ceiling. Older nine-slot HELLOs cannot catch up
with this build; exact-context direct NEW admission is unchanged. Thunder Bluff
and Graveyard are geometry version2; their old-version saved boards remain.

Round solids use swept-circle contact in the movement resolver, including
paths with both endpoints outside. Contact reports hit for the existing wall
penalty, removes inward normal remainder and retains tangential slide within
the step budget. This replaces the endpoint-only proposal described in the
original Claude handoff. The exact algorithm and regressions are recorded in
[ADR0020](adr/0020-dungeon-sprints.md). There is no texture-derived collision,
new UI object, per-step allocation or change to local Physics/input/network
cadence. Native checks for the new courses remain pending.


## Score discovery fallback - 2026-10-26

`ScoreDiscovery.ReadGroup(api,selfName)` is an additive read-only source. Inject
`GetNumGroupMembers`, `IsInRaid`, `NameUtil.GetUnmodifiedUnitFullName`, and optional
`issecretvalue`. It returns `{peers,ready=true,members,raid}` or nil/reason. Solo0
is complete empty; groups1..40 preserve full native identities, exclude self,
deduplicate/sort deterministically, and recheck count/kind/identity set. Partial,
secret or replaced rows remain pending. No native UI selection, join or send.

`ScoreSharing.RememberPeer(name)` retains only a validated incoming session peer
introduced by SessionTransport's accepted control receive. Its own call queues
no traffic and cannot take the Core lease. Source union still caps32 recipients;
no arbitrary friend/target enumeration or inbound HELLO self-admission. Channel/
group partial snapshots have30/15second leases; confirmed peers expire30minutes
after confirmation/accepted activity. Expiry and explicit source invalidation
are enforced on receive and send as well as idle scans. No persistent contact
list or save/schema migration is added.

`GetView().discovery={channel,group,remembered}` supplies copied reason/count
metadata; Report prints it. The existing cached `Read` API, wire protocol,
contexts, score merge/ranks, pacing, notices and protected saves are unchanged.
Public channel discovery remains pending; grouped/confirmed native delivery is
NOT RUN in the current client. [Behavior and short check](AUTOMATIC_SCORES.md).


## Remote heading reconciliation — 2026-10-26

Owner-reported native evidence: straight-line opponent motion is smoother;
turns still appeared to advance in4–8 ticks. This follow-up changes only the
observational display. Translation still stops at the first wall/clamp; valid
running heading/yaw can continue while translation is stopped or speed is zero,
within the same bounded500..1250ms horizon. Terminal/invalid observations do
not extrapolate. No movement through walls or authoritative state is added.

Additive pure `Presentation.remoteHeading(previous,target,elapsedMS)` returns
a displayed heading along the shortest arc, capped at6rad/s. Elapsed time is
clamped0..100ms per render; invalid/negative time makes no progress. A missing
prior heading initializes to a finite target; an invalid target returns nil.
The UI owns only two scalar fields (heading and copied controller time), resets
them with the remote-path cache, and never advances from render-call count.
This bounds packet heading corrections without delaying local controls or
changing x/y prediction. Baked64-heading sprites keep their nearest-frame
selection and remain unrotated. No extra textures, frames, art or packets.
Native turning feel for this patch remains NOT RUN.

## Multiplayer display and group diagnostic - 2026-10-25

`Presentation.buildRemotePath(previous,current,track,horizonMS?)` keeps its
three-argument500ms default. The optional finite horizon is clamped500..1250ms;
invalid values use500. At most76precomputed points are built per observation.
`remotePose` samples the path's bounded horizon without per-render collision
calls. The valid displacement chord rotates by half the observed signed heading
change to estimate the current tangent. First wall contact freezes translation;
terminal samples freeze the pose. The26October addition above allows bounded
running yaw through stopped translation. No local simulation/race/input state
is changed.

UI chooses mapped sample age plus600ms (one500ms update interval plus100ms
jitter), capped by Presentation. Its cache includes receive time, sample time
and sequence, so batched native packets sharing a millisecond cannot retain an
old forecast. No send cadence, packet format or UI-object budget changes.
This reduces two measured source artifacts; unknown inputs, clock uncertainty,
loss and changing turn rates still cause observational corrections.

`GroupProbe` is a separate finite opt-in native diagnostic, not a race route.
[Commands, exact evidence and pending gate](GROUP_DELIVERY.md). It dynamically
leases Core's existing frame/events and stays idle on load/Init. The TOCs load
36modules with GroupProbe after SessionTransport. No extra frame or default
traffic is introduced. Native PARTY/RAID delivery remains NOT RUN.

`SessionTransport.ReserveDiagnosticSend(owner,nowSeconds,bytes)` reserves the
same persistent2call/158byte rolling window and0.5second cadence used by races.
It admits only the actual GroupProbe owner with no control/native send in
progress. False/budget means defer; false/unavailable means fail closed.
Reservations are charged before native calls. `DiagnosticTrafficQuiet(now)`
guards legacy experiments for one second after group traffic; GroupProbe waits
one second on entry. This does not redefine those historical experiments' rates.

## Current production catalogue — 2026-10-25

[Production courses and capacity](PRODUCTION_MAPS.md) supersedes older Oval/limited-map examples below. `Courses.DEFAULT_ID="mirage_raceway"`; `get/available/build/next` exclude Oval. Eight finished maps are admitted by UI and SoloRecords. Seven lap maps enter the two-peer controller; Graveyard is solo-only. Three further Scarlet dungeons are unavailable. UI initializes real Mirage geometry, loads guarded scenery on first open and refuses Start if that initial load failed. Invalid saved Oval selection falls back in memory without deleting saved history. Existing stopped-selection failure rollback and explicit preference-choice precedence remain required.

RaceProtocol preserves Mirage1 and city codes2–6, retires0 and assigns Thunder Bluff7. Graveyard has no live wire code. PeerSession validates the offered map/version; SessionTransport snapshots all multiplayer-eligible Courses at arm time. RaceGrid retains exactly two role-stable poses and validates them against each actual map. No extra opponents or eight-member sessions are enabled.

`SoloRecords.Context` refuses nonproduction courses. ScoreSync requires exactly eight active contexts, derived from its supported list, while retaining a nine-slot HELLO: retired `O` digest0, active `M/S/I/D/R/U` unchanged, new `T/G`, `retired:O` catalogue marker. Retired records/requests reject; historical saved rows remain intact. Physics12 and all packet sizes/cadence limits are unchanged. The production explicit UI pool is89frames/69textures/136fonts (offline counted), omitting the former96Oval road bands and2obstacle markers; native cost remains unmeasured.

## Automatic score sharing — source integration

The two TOCs now load 36 modules. Highscores/SoloRecords precede ScoreSync,
ScoreDiscovery and ScoreSharing; UI/Menu and the existing network modules follow.
[Full behavior, evidence and limits](AUTOMATIC_SCORES.md).

`ScoreSync.new({name,contexts,store},now)` returns an opaque token. Its pure API
is `discover(token,names,now)`, `publish(token,record,now)`,
`receive(token,peer,payload,now)`, `update(token,now,sendFn)`,
`snapshot(token)` and `view(token)`. Publish returns placement/change/reason;
receive/catch-up never emit a local achievement. HELLO digests detect changes,
not authenticity. Direct new records must match native sender identity; relayed
rows remain client-reported. There is no per-result delivery ACK.

`ScoreDiscovery.Read(api,channelName,selfName)` returns a detached complete
cached roster snapshot or nil/reason. It caps display entries at128 and members
at256, uses display indices, and never changes native channel selection.

`ScoreSharing.Init(coreFrame)` creates one fixed background receiver. It owns
the protected `communityScores` child and exposes `Publish(record)`,
`GetView(trackId)`, `Report()`, `Update()` and `Message(...)`. It yields sends to
Core's lease and marks transient native sends against reentrant arming.
Known compatible contexts only; 32-peer test limit is explicit, not a proven
capacity. `SoloRecords.PlayerName()` exposes its guarded native full-name read.
Successful eligible solo Finish queues sharing after local saving under pcall;
errors cannot prevent normal results/local persistence.

**Proposed for Codex (Claude, 2026-10-25, `claude/thunder-bluff`; extended on
`claude/scarlet-graveyard`, `claude/scarlet-library`, `claude/scarlet-armory` and
`claude/scarlet-cathedral`):** `ScoreSync` knows seven courses by one-letter code,
and `Sync.new` requires exactly seven contexts. `ScoreSharing` builds one context
per selectable course. With Thunder Bluff Skyway selectable it offers eight, nine
with Scarlet Graveyard, ten with Scarlet Library, eleven with Scarlet Armory and
twelve with Scarlet Cathedral. The sync then cannot start, for any course; local
saving is unaffected. A tested patch is in Claude's handoff:

- codes `T` for `thunder_bluff_skyway`, `G` for `scarlet_graveyard`, `L` for
  `scarlet_library`, `A` for `scarlet_armory` and `C` for `scarlet_cathedral`;
- a HELLO with one board hash per course, fourteen fields with all five.

Older builds would refuse the new HELLO, as they already refuse a different
catalogue. Codex's decision; not applied.

`SoloRecords.GetView` supplies the copied community view when initialized,
including rows/scope/publication/connected/queued and save problems; otherwise
the existing local view remains available. `Menu.OnScoresChanged()` refreshes
only an already visible Highscores screen. Existing result text consumes the
once-only notice, with no new widgets. UI pool remains86/167/135, plus Core and
the score receiver's two fixed frames. Native behavior is pending verification.

<a id="implemented-kart-handling--physics11"></a>

## Implemented kart handling — Physics12

Physics12 widens profile differences and increases charged boost rewards to
48/78ticks with420acceleration, keeping the260speed envelope and30/60tick charge
thresholds. New charging waits for the active boost to end. UI duration labels
derive from the configured maximum; no state fields or packet format change.
The observational forecast yaw bound is3.0rad/s, covering agile's2.808rad/s.
See [payoff evidence](PHYSICS.md#current-drift-payoff--physics12).

`Physics.GetHandling(kartId?) -> detachedProfile, error` returns
`{id,name,maxSpeed,accel,brake,steerRate,steeringRiseRate,maxSlipAngle,slipRecoverRate}`.
Nil/basic select balanced; an unknown ID returns nil/invalid_kart. Private
parameters are never writable through this view. Mapping/values belong to
Physics compatibility12; [ADR 0019](adr/0019-balanced-kart-handling.md) and
[tuning/metrics](PHYSICS.md#implemented-kart-profiles--physics11).

`Physics.step(state,input,dt,track,kartId?)` uses a captured kart-ID string;
it allocates no handling tables and retains the15-field state. Calls with no
ID remain balanced. UI.Start validates/captures the selected ID once and uses
it throughout that solo run, including neutral countdown steps. A stopped
selection changes only the next run. Menu shows the actual profile from this
read-only view. Reviewed integration of `claude/kart-stat-bars` e122120
(Claude, 2026-10-26, owner request): the
kart screen also shows the profile as four bars (Speed, Acceleration, Turning,
Braking) from this same read-only view, against the balanced profile's values
(`GetHandling(nil)`); Menu adds 8 textures and 4 font strings for them, and
nothing in Physics changes. `Menu.statFill(value,par)` maps the balanced value
to four of six windows and changes one window per4%, clamped to half a window
through six. `maxSpeed/accel/steerRate/brake` map to Speed/Acceleration/Turning/
Braking. Bars load only on first visit; a refused atlas load keeps the existing
text description and hides bars without retrying. Production pool is89/77/140.

`RaceStart.new(ticket,track,physicsVersion,kartId?)` captures an optional ID and
adds it to the once-only launch bundle. Take validates known handling before
initialization; LiveRace captures the ID privately and passes it into step.
SessionTransport supplies RaceGrid's acknowledged localKartId. Copied views,
bundle edits and later UI choices cannot retune that run. Legacy nil starts
remain balanced. Existing wire formats stay unchanged; negotiated Physics12
rejects peers running older mapping/parameters, and speeds remain within the
existing -55..260 live codec range.

Leaderboards remain one best per player per map/rules context, with no kart
column or filter. Existing kartId metadata remains internal. Old Physics10
boards are retained; current Physics12 contexts begin a new compatible board.

## Pure community merge and placement — 2026-10-25

Additive `Highscores` functions; no native traffic, community SavedVariables
child or popup is connected by these APIs. Keep existing local `Submit` and
`SoloRecords` ownership. [Direction and integration boundary](adr/0018-automatic-community-scores.md).

- `Merge(store, context, records) -> store, changed, reason`: atomically validates
  a dense batch of at most 50 records for exactly one six-field context. Choose
  each player's canonical best by ticks, earliest finish date, display-name
  bytes and kart bytes; sort and keep the best 50. A rejection or no-op returns
  the original store. Valid changed output is detached. Fixed-board union is
  associative, commutative and idempotent. The 32-board capacity is a separate
  admission limit: a native controller must use the agreed course catalogue,
  not arbitrary remote contexts. This function does not authenticate records.
- `Rank(store, context, playerName) -> rank, detachedRecord, error`: one-based
  ordinal on the stored board; `not_ranked` when absent. Name handling retains
  full Forever names and uses the existing ASCII-space/case identity rules.
- `FinishPlacement(beforeStore, afterStore, record) -> placement, error`:
  accepts only the exact retained record with a strictly improved prior known
  time. Output is `{rank, previousRank, tier, enteredTier, knownPlayers,
  scope="known_board"}`. Tier is 3, 10 or nil. Crossing both thresholds returns
  only `enteredTier=3`; improving within a tier leaves enteredTier nil.

Placement assessment is pure, not a consuming event queue. A caller must invoke
it only from the existing once-latched eligible local-finish transaction and
consume its notification once. Reusing the same before/after snapshots returns
the same assessment. Network receive, catch-up and UI redraw must never trigger
it. A replay against the already-updated store yields no new placement.
Known-board ranks are not proof of a complete global ranking; native delivery,
cache persistence and visible congratulations remain pending.

## Central persistence component — 2026-10-24

Python `services.leaderboard.store.LeaderboardStore(path, *, deployment_id,
allowed_boards)` is server-side code, not a new native addon API.
`submit(trusted_actor_name, record)` returns `{status,changed,best}`;
`query(context, *, limit=10, offset=0)` returns `{rows,total,limit,offset}`.
Records use the same10fields and6-field compatibility key as Highscores.
Atomic lower-tick-only updates make retries idempotent; server storage retains
all personal bests while pages are capped50. Actor identity comes from the
eventual trusted session adapter, not the record. No HTTP/native bridge exists
in this slice. See [full boundary](../services/leaderboard/README.md).

Current combined visual/score checkpoint, 2026-10-24: runtime77a1891 retains
the score/transport contracts below and adds Claude's optional local-kart
outline, saved `preferences.outline` and Pod Racer art under the existing
`goblin_drag_car` ID. Explicit pool is now **86/167/135** (frames/textures/fonts).
This supersedes earlier current-budget statements, preserving their historical
scope. See [review](reviews/2026-10-24-podracer-score-integration.md).

## Implemented solo finish records — 2026-10-23

`Highscores` is pure and owns no simulation/UI/transport state. `Load(raw)`
returns a detached valid store, writable flag and optional reason; absent data
starts version1, malformed/future data returns its original identity read-only.
`BoardKey(context)` uses `trackId:trackVersion:physicsVersion:lapCount:tickRate:rulesVersion`.
`Submit(store,record)` returns a new store/change flag/reason; `View(store,context)`
returns detached sorted rows. Both store and view inputs remain untouched.
Compatibility fields plus `playerName,totalTicks,finishedAt,kartId` form a row.
Maximum32boards/50bestplayers perboard; equal/slower totals preserve existingdate.
Unknown v1 fields refuse writes rather than being discarded. See
[full persistence/publication contract](HIGHSCORES.md).

`SoloRecords` is the native adapter. Core calls `Init()` after root initialization.
Only successful solo `UI.Start` calls `Begin(track,kartId)`; only its actual solo
finish transition calls `Finish(token,race,multiplayer)`. The token latches the
attempt before native calls. UI freezes active simulation before calling out,
protects the callback with pcall, and still performs ordinary result/input
cleanup after a saving error. Nonterminal running-time drops set the token's
timingLost flag; post-finish Loop remainder does not. No changes to Physics,
Race, Laps, Loop, authoritative geometry or multiplayer transport were made.

Rendering uses `SoloRecords.GetView(trackId)` (copied rows/context, scope=`local`,
publication=`Global publishing pending`, writable/problem), `FormatTime(ticks)`
and `FormatDate(epoch)`. Result presentation consumes `UI.scoreResult.message`;
it never saves a score. The eight-screen Menu adds reachable Highscores,
ten preallocated rows, track browsing and paging. Track browsing does not call
UI.SelectTrack or alter race state. Store/date reads happen only at finish or
explicit board actions, not every OnUpdate. Resultsheight336. New explicit
pool85/166/133 (frames/textures/fonts), replacing79/166/81 for this branch.
Native layout/performance/persistence remain NOT RUN.

Global publication/service/discovery is **not implemented**; no score packets
or new transport hooks exist. This local board must not be described as global,
complete, server-verified or cheat-proof. Immediate priority follows
[ADR0016](adr/0016-solo-records-and-global-score-gate.md).

**Checkpoint:** 2026-10-22, `codex/ui-backend-integration`: merge `6cd611a` combines reviewed Claude UI `1b2d3d5` with Codex backend `192c6de`; `9b22f12` applies Claude's isolated preference fix `4ffe184` without its city-track dependencies. Subsequent city merge f9f2af0 now preserves Claude capital-cup78d97a1 and those modules; the reviewed loader repair stages new backgrounds before changing the visible picture. The combined source retains the reviewed six-kart rendering, Forever transport correction, session adapter and start-clock foundation. That wall-penalty checkpoint used Physics10; current kart handling uses Physics11, documented above. This describes the local solo prototype, measured transport experiment and offline control foundation; it does not claim a released engine or playable multiplayer. See [PROGRESS](PROGRESS.md) and [the latest handoff](handoffs/codex-latest.md).

**Current multiplayer checkpoint, 2026-10-23:** the owner reports a completed two-client drive on `c581a52`, with GO-only startup, square peer markers and lag/clipping. The current `codex/multiplayer-grid` source adds profile agreement, a visible shared grid/countdown, selected peer art and time-aware bounded display prediction. These new changes are **NOT RUN in Forever**. Earlier unwired/Coming soon descriptions below are historical where superseded by the implemented contracts here; no production capacity, kart contact or agreed results are established.

## Status and ownership

The interfaces below exist in source today. `Renderer`, `GameSession`, collision-event streams, velocity vectors, a replay API and production synchronization adapters do **not** exist. The standalone NetworkProbe/TransportProbe experiment and the pure RaceProtocol/PeerSession control foundation described below are implemented; none feeds authoritative simulation state. The native SessionTransport boundary is implemented and tested with mocks; the opt-in start-clock coordinator now yields one backend Physics/Race initialization bundle. Menu screens and their solo commands are integrated. The pure live-race lifecycle and observational pose codec are now implemented on `codex/live-race-controller`; native live adoption and a deliberately armed lobby/canvas are now wired on `codex/live-multiplayer-integration`, with actual-client checks pending. See [LIVE_RACE](LIVE_RACE.md) and [START_CLOCK](START_CLOCK.md). Proposed architecture sketches in [ARCHITECTURE](ARCHITECTURE.md) must not override the signatures here.

- **Codex:** Physics, collision/surface queries, Input sampling, Loop, Checkpoints, Laps, Race, deterministic simulation and their tests; experimental transport/accounting, RaceProtocol, PeerSession and future synchronization.
- **Claude:** visual rendering, camera/presentation helpers, track imagery, HUD, sprites, animations/VFX, asset tooling and their focused visual tests.
- **Shared:** public interface changes, accepted architecture decisions, integration coverage, performance budgets and TOC load-order changes. Coordinate explicitly before editing the other owner's code.

[`UI.lua`](../addon/AzerothKart/UI.lua) currently mixes both responsibilities. Its drawing/layout/rendering/HUD helpers belong to Claude; capture, Start/Stop/combat transitions, track-selection lifecycle, `step`, `OnUpdate` clock orchestration and authoritative-state assignment belong to Codex. Coordinate any shared-file edit by function area before working. `SelectTrack` includes both asset validation and lifecycle reset, so changes there require coordination. There is no standalone renderer entry point to call or replace yet. Extracting one would be a separately agreed change.

## Modules and data access

The two TOCs load `Track`, `MirageRaceway`, `Circuit`, `CapitalCities`, `Courses`, `Physics`, `Input`, `Loop`, `Performance`, `Presentation`, `Checkpoints`, `Laps`, `Race`, `Highscores`, `SoloRecords`, `UI`, `Menu`, `RaceProtocol`, `PeerSession`, `ClockProtocol`, `StartClock`, `RaceStart`, `LiveProtocol`, `LiveRace`, `RaceGrid`, `NetworkProbe`, `TransportProbe`, `SessionTransport`, `Core` in that order, for 29 modules in each TOC. `Highscores` is pure; `SoloRecords` reads native identity/time and writes only its SavedVariables child. Other pure modules receive `local _, namespace = ...`, optionally register their module on that explicit table, and return it for offline loading. They do not access WoW globals. Core exports the same namespace as `_G.AzerothKart` for diagnostics.

The current render path reads `AK.UI.state`, `.previousState`, `.race`, `.laps`, `.checkpoints`, `.track`, `.trackId`, `.clock` and `.active`. These are mutable Lua tables exposed for integration/diagnostics, **not enforced read-only objects or security boundaries**. Treat them as borrowed read-only references in rendering: do not add, remove or alter authoritative fields, normalize headings in place, alter input, call a simulation step, or assign interpolated/camera coordinates back to them.

`UI.laps` aliases `UI.race.laps` during a run; `UI.checkpoints` aliases `UI.laps.checkpoints`. A fresh state replaces those references after each accepted step. Cache scalar values for visuals when useful; do not retain an old table and assume it is live. `UI.result` is a small terminal summary (`status`, `reason`, `tick`, and terminal `totalTicks`/`completedLaps`), not the full race object. `UI.race` remains the source for lap details. `UI.previousState = UI.state` on Stop ensures an exact terminal pose.

## Implemented pure live-race lifecycle and observational poses

`LiveRace` and `LiveProtocol` are additive Codex-owned modules, loaded inertly after RaceStart. [LIVE_RACE](LIVE_RACE.md) describes one-shot tick-zero bundle admission, copied views, 60Hz/five-step local advance, bounded finish/stop and scoped peer liveness. Current `LiveProtocol.VERSION=2` uses exact **40-byte** STATE packets on **AZKRUN2**, replacing the older 34-byte AZKRUN1 candidate. There is no mixed-version fallback: both players need the same build. Loading either module registers no prefix. All incoming progress remains unverified observational data, with no local correction, checkpoint award, kart contact or shared winner. Local and remote state are copied for rendering; presentation never calls advance or consumes GO.

`SessionTransport.HostLive(peer,code,trackId,kartId?)` and `ListenLive(peer,code,kartId?)` fix the cosmetic choice at deliberate arm (default trike); `AdvanceLive(input)` remains the single local driving bridge. Core binds copied views/actions to UI.MultiplayerAction. The same Core-frame lease and persistent native budget span control, profile, clock and driving: at least 500 ms between native calls, at most 2 calls and 158 payload-plus-prefix bytes per rolling second, with no per-frame broadcasts, extra sender or catch-up burst. Current telemetry costs 40+7=47 counted bytes per call; native/server overhead is unknown. Profile/clock/control share these ceilings, and per-run caps cannot replace them. All seven finished lap Courses entries are multiplayer compatibility entries for this two-peer controller; Oval is retired. There is no production-authority or release decision in this change.

STATE adds required integer `sampleMS` (0–1,800,000): the latest advanced local state's time since the sender's mapped GO, not its tick multiplied by dt or the time of a later packet send. Existing fields/quantization remain: quarter-unit positions, signed tenths speed and 46,656 heading bins. `LiveRace.receive` rejects a regressing sample stamp alongside existing sequence/tick/session/peer/bounds checks. `LiveRace.view` adds `elapsedMS=max(0,lastNow-localEpochMS)` and `remote.sampleAgeMS=max(0,elapsedMS-remote.sampleMS)`; `remote.receivedAtMS`, receive-based `remoteAgeMS` and `remoteStale` remain. Sample age is an estimate affected by clock-offset uncertainty, not a verified one-way latency. Remote progress and elapsed values never award a local checkpoint or select a winner.

## Implemented cosmetic agreement and visible starting grid

`RaceGrid` is pure and inert on load; the native adapter supplies full peer/channel authorization and its existing output gate. Its implemented dot-call API is:

```lua
RaceGrid.encode({kind="PROFILE"|"ACK",session=code,kartId=id}) -> payload | nil, error
RaceGrid.decode(payload) -> copiedMessage | nil, error
RaceGrid.new({session=code,role="host"|"guest",kartId=id},nowMS) -> token | nil, error
RaceGrid.update(token,nowMS,sendFn,sendAllowed?) -> attempted, reason?
RaceGrid.receive(token,nowMS,payload) -> accepted, reason?
RaceGrid.view(token) -> copiedView | nil, error
RaceGrid.stop(token,nowMS,reason) -> accepted, reason?
RaceGrid.pose(track,role) -> localPose, peerPose | nil, error
-- sendFn(payload) -> "accepted" | "failed" | "unknown" | "throttled"
```

AZKGRD1 carries strict 12-byte `1P/1A + six-character session + 001 + kart-code` envelopes. Only the ten registered kart IDs or `basic` are accepted; unknown fields/metatables, sizes, alphabet, version and fixed sequence are refused. Profiles are immutable for this session: a contradictory peer kart closes it. Private token state advances `exchanging -> ready` only after the peer profile, local PROFILE's matching ACK and a locally accepted ACK of the peer profile. Native acceptance is still not delivery. Sends are paced 500 ms, PROFILE retries 2 s/at most 3 attempts, agreement expires after 10 s; decoded scoped receives cap 64 total/8 per second with at most 8 deferred messages. Stop from a native callback wins. Duplicate PROFILEs get bounded re-ACKs through the same lease/budget, not an event-stack send.

For each of the seven live-eligible production circuits, `pose` derives role-stable slots 18 units to each side of the existing spawn (36 apart), with identical facing, finite bounds and road-mask checks. The track definition is not changed. `SessionTransport.GetView().grid` copies `localPose,peerPose,localKartId,peerKartId,ready` and presentation fields `staged,cue,remainingMS?,localEpochMS?`. Ready/PrepareStart are disabled/refused until agreement. The current grid is exactly two players; ten karts do not imply ten-player capacity.

After deliberate Ready, starting/coordinating stages both chosen karts on the canvas. Held input may be captured there, but Physics/race/checkpoint stepping does not occur before GO. `StartClock.new` now accepts `countdownMS=0|3000` (default 0); live mode chooses 3000, while legacy backend-only coordination retains 0. The clock requires arming before `localEpochMS-max(HANDSHAKE_MARGIN_MS,countdownMS)`. The copied armed clock exposes `countdownMS/countdownStartMS`; grid cue is `GET READY` before the final three seconds, then `3/2/1` derived from the mapped epoch. At GO the backend launches exactly once from its local role slot at tick zero, without replaying the solo countdown, and preserves staged held input. Stop/Escape/Close or failure release staged capture without inventing a completed race. Lost final ACK/CANCEL can still leave asymmetric arming/start; this is not an atomic-start guarantee.

UI uses the existing pooled opponent Texture for the agreed peer's sheet or rotated image, including its heading frame, pivot and scale. One guarded asset load per profile change falls back to the cyan primitive when refused; texture files/objects are not loaded/created per render. The local follow camera is unchanged. Off-screen peers get direction/distance text instead of an unexplained disappearance; estimates can be wrong and are not standings. Receive-stale observations retain the stale indication. The reviewed explicit UI object pool is unchanged at 79 frames/166 textures/81 font strings; this is an offline allocation count, not a measured native memory/FPS budget.

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

Version fields are integers 1–1295; valid future values remain decodable for later explicit compatibility refusal. Track IDs are the seven multiplayer-eligible production Courses IDs (wire codes1–6; retired0 refuses); laps are 1–9 at the wire layer (this adds no lap setting to the current three-lap game). `startTick` is 0 through 36^6-1; `seed` is 0 through 2147483647. Cancel reasons are `left`, `timeout`, `incompatible`, `combat`, `world_leave`, `error`. ACK accepts one of the five non-ACK kinds and a sequence 1–46655.

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

Options are `role="host"|"guest"`, complete Forever `peer`, fresh six-character uppercase-alphanumeric `session`, integer `physicsVersion`, supported `trackVersions` keyed by any nonempty subset of the seven multiplayer-eligible production course IDs, and `laps` default3. Options/track versions are copied. Names cap96 raw bytes, reject controls/DEL/pipe, trim/collapse ASCII spaces and compare the entire native sender with ASCII case folding; punctuation/UTF-8/surnames remain intact, with no realm invention or first-name fallback. Session-ID lifetime/reuse management belongs to the future adapter. A compatible host offer selects track and valid laps1–9; guest default laps/local solo selection does not override it. Physics and offered-track versions must match exactly. The current solo Race still fixes three laps; an eventual live adapter must preserve that supported configuration until Race gains an agreed configurable-laps API.

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

Host/Listen explicitly arm one full native Forever peer/fresh six-character code. Actual Physics.VERSION and each available Courses-built geometry version populate compatibility; fixed3laps match current Race support. Host queues the invite without sending; Listen alone never accepts it. No room discovery, identity/realm inference, automatic rearm, code generation or new slash command exists. Accepted sessions consume one of64remembered codes per addon lifetime; malformed/refused setup does not consume an ID. Reload clears history but still requires a genuinely fresh code.

The adapter exclusively leases Core's existing frame with addon-owned `akNetworkOwner`. Both adapters mark `akNetworkSending` during native calls, preventing handover even if Stop releases the ordinary lease from a send callback. Only the lease owner may change OnUpdate/CHAT_MSG_ADDON_LOGGED registration; Core retains OnEvent. Probe arming verifies ownership after each native setup step and blocks recursive arm. Inactive Stop cannot detach the other adapter. No two-adapter concurrency or packet sends from Message/actions occur. The separate AZKART1 experiment retains its schedule/measurements; it is not a race channel or simultaneous traffic allowance.

Registration accepts only source-matched Success/DuplicatePrefix enums. Send uses only C_ChatInfo.SendAddonMessageLogged with native WHISPER and full canonical peer, receives CHAT_MSG_ADDON_LOGGED and accepts only the source-matched numeric Success result. Known failure/throttle codes, unknown/nil/opaque results or throwing APIs terminate; there is no ordinary-whisper/unlogged fallback. Combat/actual chat lockdown, unreadable/backwards clocks, capability/hook failures, world/logout and local driving refuse/stop. Data is addon-owned printable control fields only; error strings are fixed and do not echo native failures or packet contents. Logged transport is not promised private or authenticated.

Every attempted native session call—including ACK, retries and final cancellation—is counted before the API invocation. Persistent local spacing0.5seconds, rolling1second2calls and 158 payload-plus-prefixB caps survive fresh-controller rearming. Current payload limit23bytes plus7prefix; no catch-up bursts. Budget waits advance pure deadlines without consuming attempts. With both endpoints compliant this stays under ADR0013's separate pair4calls/s and316B/s working ceilings before unknown overhead; it does not measure capacity or govern other addons. Standalone probing is exclusive and separate from the candidate.

GetView copies the pure view plus `canHost,canListen,transportBusy,route,lastError,traffic`. Host/Listen are disabled at the64-ID cap, during native calls, active controllers or any adapter's lease. These are structural capabilities; action preflight can still refuse combat/API state. Traffic counters are lifetime `attempts,accepted,failed,unknown,throttled,payloadBytes,prefixBytes,windowCalls,windowBytes`; window values reflect the last validated clock, and snapshots call no native APIs. Refresh at a modest menu cadence outside simulation ticks. None of these counters proves delivery.

Leave queues at most one paced best-effort CANCEL; remote CANCEL similarly gets one bounded final ACK. The lease remains held only through that bounded drain. Hard Stop drops controller/pending output/proposals, retains a copied closed diagnostic and releases owned hooks; no new command or delayed callback resurrects it. Accepted solo UI.Start calls Stop(local_drive) before capture. Core forwards lifecycle events to both adapters. GUI Leave/Close behavior belongs to Claude's future session flow; the existing solo presentation is unchanged.

Start forwards backend parameters and TakeStartProposal is a backend-only one-shot hook. No call activates Race/UI.Start/physics, aligns clocks or guarantees atomic GO; frontend rendering must not consume the proposal. Live-start/clock coordination and actual two-client control acceptance remain pending.

## Authoritative vehicle state

Implemented in [`Physics.lua`](../addon/AzerothKart/Physics.lua):

```lua
Physics.VERSION = 10
Physics.FIXED_DT = 1/60
Physics.new(track) -> state
Physics.step(state, input, dt, track, kartId?) -> nextState
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

Test Oval now sweeps center movement against its perimeter and two axis-aligned solid rectangles expanded by 18 units on each side. This conservative square clearance encloses the rotated 17×31 body; it is not an exact oriented-body or rounded-corner collision shape. Earliest contacts remove inward normal displacement while retaining tangent motion, using at most three movement iterations and no temporary tables. Recovery from a starting overlap is deterministic and bounded to four passes for these disjoint, perimeter-contained fixtures; arbitrary overlapping obstacle clusters are unsupported. Mirage retains its original endpoint perimeter clamp and no obstacles. Physics8 scales the first contact’s speed by permitted/attempted travel (capped at1); persistent contact uses40units/s² scrape drag. Fully blocked motion stops. Contact clears slip/drift/grace/boost, retains progressive steering and reports `surface="wall"`; `impacts` still counts contact ticks. Low-speed yaw adds1.2rad/s tapered to zero by80units/s; racing/drift90+ yaw is unchanged. No state fields, collision-normal stream, road-edge walls or vehicle-to-vehicle collision were added. Rendering may compare consecutive `impacts`, but must not increment it or treat it as a trustworthy network event.

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

- [`Track.lua`](../addon/AzerothKart/Track.lua) is developer-only singleton Test Oval (not selectable/negotiable), `id="test_oval"`, `version=2`: 800×480, elliptical road, spawn (666,240), north-facing. `obstacles` is a read-only-by-convention ordered array of physical rectangles `{id,x,y,width,height}` with bottom-left origin: (270,400,32,24) and (490,60,32,24). `isDrivable` remains the road mask; `surfaceAt` additionally classifies physical obstacle footprints including edges as wall. Only `resolveMovement` adds kart clearance. `constrainPosition` remains perimeter-only for compatibility. Finite endpoints/displacements are required. Exact arrival at a clearance face or isolated corner graze is free; inward movement from a face contacts. Keep geometry fixed during a run.
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

Race fields: `status`, `laps`, `targetLaps`, `countdownTicks`, `startTick`, `lastTick`, `totalTicks`, `finishTick`, `reason`. Status is `"countdown"`, `"running"`, `"finished"`, `"stopped"` or `"interrupted"`. The current target is three laps; it is not a user setting. (Proposed on `claude/scarlet-graveyard`: a course may set its target with `track.laps`; see [dungeon sprints](#proposed-dungeon-sprints-the-scarlet-crusade-cup).)

Countdown starts at 180. Cues show 3 for remaining 180–121, 2 for 120–61, 1 for 60–1. At physics tick 180, Race becomes running and resets the lap origin; the kart remains at spawn. Held driving input first applies at tick 181. GO displays for `totalTicks` 0–59. Race/lap seconds are integer durations multiplied by `Physics.FIXED_DT`, excluding countdown, dropped time and stopped time; physics/loop/probe ticks include countdown. The third accepted lap fixes `finishTick`, returns finished and stops catch-up before another physics step. Terminal step/stop calls retain the same race object.

`UI.DismissSummary()` hides the terminal result panel without changing the retained race, pose, sample, HUD or input. The pooled **Close results** button calls it. The same terminal race stays dismissed across Stop, rejected Start and window close/reopen. A successful fresh Start or map change clears this presentation-only dismissal. This is not resume or an authoritative race field.

UI Start/Restart always creates a fresh countdown; there is no resume. Stop retains actual partial progress; combat interrupts, closes the window, releases controls and announces once. Reopen and rejected Start preserve the result. Successful map change or Start resets it. Rendering may show these results but must not infer extra laps, interpolate progress counters, count gate crossings itself or advance race time from wall clock.

## Presentation and camera

[`Presentation.lua`](../addon/AzerothKart/Presentation.lua) is pure math except the deliberate mutation of **presentation-owned view offsets** in `follow`:

```lua
pose(previous, current, alpha) -> x, y, heading
buildRemotePath(previousObservation, currentObservation, track) -> path | nil
remotePose(path, sampleAgeMS) -> x, y, heading, predicted -- nil pose if invalid
remoteHeading(previousHeading, targetHeading, elapsedMS) -> displayedHeading | nil
meter(state, Physics) -> fraction, phase
fitViewport(worldWidth, worldHeight, canvasWidth, canvasHeight) -> view
cameraViewport(worldWidth, worldHeight, canvasWidth, canvasHeight, scale?) -> view
project(view, x, y) -> canvasX, canvasY
unproject(view, canvasX, canvasY) -> x, y
follow(view, x, y, heading, lookAhead?) -> sameView
texCoords(view) -> left, right, top, bottom
clipRect(view, x, y, width, height) -> canvasX, canvasY, width, height | nil
kartFrame(sprite, heading) -> frame   -- nearest directional frame, 0-based
kartFrameCoords(sprite, frame, phase?) -> left, right, top, bottom   -- phase: proposed, claude/gryphon-wings
wingPhase(sprite, time, gliding) -> phase                             -- integrated 2026-10-26
```

`pose` linearly interpolates position and uses the shortest heading arc; an exact half-turn chooses the negative arc. Missing/NaN alpha uses current pose, alpha ≤0 previous, alpha ≥1 current. During active rendering alpha is `clock.accumulator/clock.dt`; this is up to one fixed step behind simulation. Start/Stop/inactive drawing uses the exact current pose. Presentation values must never affect Physics, gates or lap time.

`buildRemotePath` is a separate display-only helper for copied LiveRace observations. UI caches it when receipt time, sample time or sequence changes, then calls allocation-free `remotePose` with `remote.sampleAgeMS` at render cadence. It starts at the newest observation, with no extra 500 ms receive-time interpolation buffer. The three-argument default keeps31points/500ms; the optional horizon extends to1250ms/76points for transit plus the next update. Both use fixed1/60s steps, absolute speed cap 260 units/s and heading-rate cap 3.0 radians/s. Current signed speed/facing supply the fallback; a valid positive sample interval of at most 2 s supplies measured travel direction advanced by half the signed heading change to estimate the current tangent, plus shortest-arc yaw. It does not predict unknown acceleration, braking or new steering. `resolveMovement` is used where present; contact, clamp or invalid/far recovery stops further projection. A road-mask-only track refuses outside endpoints. This preserves the current geometry hooks' limits; it is not a new continuous collision guarantee.

`remotePose` clamps finite age to the cached path's bounded horizon (500ms by default; at most1250ms), samples cached positions and freezes translation at the first contact or forecast end. Valid running yaw is sampled independently, so a stopped or wall-contact kart can keep turning within that horizon. Invalid/missing age draws the observation without guessed latency. Non-running or invalid-speed observations stay frozen; invalid current pose falls back to a valid previous pose without forecasting, and no valid pose yields nil. Inputs are never written. The boolean labels an estimated pose; it does not verify where the peer really is. The UI bounds subsequent heading corrections through `remoteHeading`; position, clock offset, unknown steering/braking and loss remain observational limitations. These helpers never feed local Physics/Race, award progress, compare standings or send packets. Native turning and visual edge behavior for this revision remain **NOT RUN**.

`meter` clamps a visual fraction to capacity and returns `"idle"`, `"charging"`, `"holding"`, `"tier1"`, `"tier2"` or `"boost"`. Rough ground/walls override stale charge. Boost uses the shared 48-tick capacity, so a shorter reward starts less full. Phase does not change simulation.

All project/unproject coordinates use bottom-left +Y-up, a **uniform** scale and offsets: `canvasX=offsetX+x*scale`, likewise Y. Scale dimensions as well as positions. No separate X/Y stretching. `unproject` does not clamp or authorize gameplay input.

The offline Test Oval fixture uses a fixed fit overview (800×480 into 800×480, scale 1). Mirage uses `cameraViewport(1024,1024,800,480,1.5)`, giving a 533⅓×320-world-unit visible area. The camera is north-up, follows the **interpolated** pose plus 60 world units along facing heading, and clamps against world edges. It does not rotate the map or change collision coordinates. `follow` reuses the view by changing `offsetX/offsetY` only. The minimum allowed camera scale covers the canvas.

`texCoords` converts +Y-up to top-origin texture V once and returns four arguments for `SetTexCoord(left,right,top,bottom)`, bounded to [0,1]. `clipRect` returns the visible canvas intersection for axis-aligned world rectangles, or nil when invisible. UI repositions/clips pooled gate and perimeter textures when camera offsets change; no native clipping API is assumed. Rotated kart clipping is not a general sprite-clip interface.

**Implemented and Codex-reviewed:** the original single-image path (`520275e`) and Claude's directional-sheet extension (`cf71394`) are combined on `codex/menu-integration`. Neither changes Physics/Race fields, authoritative coordinates or collision clearance.

- The physics body stays 17×31 **world** units, published for presentation as `Presentation.KART_FOOTPRINT_WIDTH/HEIGHT` (25.5×46.5 UI units on Mirage).
- `Presentation.KART_SPRITES[id]` is pure, read-only data: `path`, power-of-two `textureWidth/textureHeight`, and `quadWidth/quadHeight` in world units with square texels.
- A **single image** has no `frames` field. It is north-facing, centered at the projected pose and rotated by `heading - math.pi/2`; every visible texel stays inside its 17×31 body. No shipped kart is a single image since 2026-10-23, when the Goblin Pod Racer sheet replaced the 64×128 drag car in the `goblin_drag_car` slot; the path stays supported and the UI tests keep a test-only single image.
- A **directional sheet** also supplies `frames`, `columns`, `pivotX` and `pivotY`. Its frames form an even grid, read left to right and top to bottom; frame k faces heading `k * 2pi / frames`, counterclockwise from east. Each frame covers `quadWidth x quadHeight` world units. Its center sits `pivotX/pivotY` world units east/north of the kart's projected position, scaled by the view. This screen-oriented pivot is not rotated with heading.
- `Presentation.DEFAULT_KART` is `"goblin_mortar_trike"`: a 1024×1024 sheet of 64 frames of 128×128 texels, quad 41×41, pivot (3, 0), rendered in three-quarter view from the Warcraft III model. A stopped-only Kart button and the front end's kart screens cycle the registered cosmetic karts.
- **Outline (2026-10-23, proposed by Claude for review):** each directional sheet may name `outline`, a 512×512 white sheet of the same frame grid (`Presentation.KART_OUTLINE`: size and tint). `UI.SetKartOutline(enabled)` is the Settings switch (preference `outline`, off unless saved on). While on, the player's own kart's outline loads with the same guards, once per kart, and `render` draws it over the kart (OVERLAY sublevel 1) with the kart's frame crop, quad and position; a refused load hides it without retry. Presentation only: it reads no simulation input beyond the drawn pose and writes no simulation state. +1 texture, and the Settings check +1 frame and +2 font strings.
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
- `Presentation.KART_ORDER` lists the button's cycle (ten karts with the four Warcraft III vehicles proposed on `claude/kart-roster-wc3`: Dwarf Car, Orc Demolisher, Meat Wagon, Glaive Thrower; same sheet format and effect-anchor fields, no new interface). `Presentation.nextKart(id)` returns the next id, wrapping to the start; an unknown id returns the first.
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
- **Counts.** The original solo Menu brought the pool to65/160/79; the integrated city screen/gates and staging background bring it to71frames/165textures/80fonts, and the four Warcraft III karts' list buttons (proposed on `claude/kart-roster-wc3`, 2026-10-22) to **75 frames**/165 textures/80 fonts, all created with the window.

<a id="proposed-the-gryphon-riders-wingbeat-claude-claudegryphon-wings-2026-10-26"></a>

### Implemented: the Gryphon Rider's wingbeat (reviewed 2026-10-26)

The owner: "I want flapping during normal speed and gliding during boost." Presentation only; see [the roster](art/karts/roster.md#the-gryphon-riders-wingbeat). Additive: every other kart, the outline contract and the object counts (90/91/150) are unchanged.

- **Sheets with phases.** A directional sheet may carry `phases` (here 4): every heading once per phase, phase after phase, `columns` frames a row; frame k of phase p is cell `p * frames + k`. `kartFrameCoords(sprite, frame, phase)` takes the phase (0-based, default 0, so every existing call keeps its crop). Phase 0 is the rest pose, the one a freshly applied sheet shows. The outline sheet of a phased sheet is half its size and holds every phase in the same layout.
- **`wings`** on such a sheet: `cycle` (the phases of one beat, here rest, top, rest, bottom), `beat` (seconds a beat, 0.667, the model's own) and `glide` (the phase held while gliding, 3). `Presentation.wingPhase(sprite, time, gliding)` is pure: the glide while `gliding`, otherwise the beat's step at `time` seconds of the caller's clock; 0 for a sheet without wings or an unreadable time.
- **The Gryphon Rider:** `GryphonRider.tga` becomes 2048×2048 (16 MiB raw, from 4) with quad 58 and pivot (4.5, 0) (from 41 and (2.6, 0)): the raised wings and their shadow need the window. Its boost `trails` move to the glide's wingtips, (4, ±20.2, 13.5).
- **UI (visual body of `render`; `renderOpponent`/`opponentSprite`).** While a run is active, the player's gryphon beats on `(state.tick + alpha) * Physics.FIXED_DT` and glides while `state.boostTicks > 0`; with no run it shows phase 0. The crop is written only when the frame or the phase changes (six times a second while beating); the outline follows. A friend's gryphon beats on the live view's `elapsedMS`, half a beat apart, and glides while `remote.boosting` only for a fresh, non-grid running peer in a running live view. Grid, stale, terminal and non-running views rest at phase0, even with an old boost report. Both read copied state only.
- **Menu:** the garage turntable beats the wings for four seconds and glides for two (`Menu.STAGE_GLIDE`), once round.

<a id="proposed-race-screens-and-score-celebrations-claude-clauderace-screens-2026-10-26"></a>

### Implemented: race screens and score celebrations (reviewed 2026-10-26)

The owner asked for the "screen side of multiplayer such as race positions, name tags, and results" and "a bigger celebration when you get a top 10 and top 3 score". Reviewed visual code consumes copied state only. Codex adds exact finish metadata at the save boundary and preserves the existing backend results/rematch controls; no authenticated winner or agreement is created.

- **Presentation (pure, additive).**
  - `Presentation.raceProgress(track, completedLaps, passed, x, y) -> number|nil`: gates passed over the completed laps and this one, plus a fraction (0 to 0.999) of the straight distance from the previous gate toward the next. nil for unreadable input (`passed` must be below the gate count).
  - `Presentation.ahead(a, b) -> boolean` and `Presentation.standings(racers) -> list` order racers `{finishTicks?, progress?, out?}`: finished first by finishing tick, then racing by progress, then out of the race; ties keep their order; `standings` sets each racer's `place`. `ahead` allocates nothing (the HUD asks every frame).
  - `Presentation.ordinal(n)`: "1st", "2nd", "3rd", "11th", "21st"…
- **UI (visual, `renderOpponent` and `UI.Create`).** One new font string, `UI.opponentTag`: the friend's name over their drawn kart, or held inside the canvas edge toward it with "(N away)" when off screen, faded when stale. `renderOpponent` keeps the drawn pose in `UI.opponentWorldX/Y` for the HUD. The diagnostic `UI.opponentLabel` and its text are unchanged.
- **Menu.**
  - `Menu.liveRacers(mine, theirs)` fills two racer tables from copied views: the local `UI.race`/`UI.laps`/`UI.state`, and `UI.liveView.remote` (its own reported laps, gates, status and finishing tick), placed at the drawn pose. The friend is out on a stopped/interrupted report or a `peer_stopped`/`peer_timeout` close.
  - The race overlay shows an estimated place ("of 2 (est.)", gold/silver) once a live race runs, never on the grid. Final reported rank/tie comes from the retained backend result.
  - The results show the two copied backend rows, including pending/stopped peers. Both finishes are required for a rank; equal finish ticks retain joint first. A missing peer cannot produce a victory. Late RefreshResults/reopen are quiet. UI's unverified title/hint remain visible even with a medal/banner. Play Again, Change Map/Lobby and Leave Multiplayer preserve the same-player room; they never fall back into solo implicitly.
  - `Menu.scorePlacement(result, trackId)` consumes the exact detached `result.placement` and captured `result.playerName` described above, never scanning equal-time rows. Kinds `record` (#1 of several), `first` (#1 alone), `top3`, `top10` and `best`; missing placement falls back to plain PB. Ranked results use a banner, medal/wreath, bounded confetti and a guarded sound; a best outside the top ten turns the save notice gold. The original art is `Assets/UI/Celebration.tga`, generated by `scripts/build_celebration_art.py`, loaded once and not retried if refused.
  - A **Highscores** button in the results opens the run's board at the page with the player's own row, which the board shows in gold (`Menu.PlayerName`, read once through `SoloRecords.PlayerName` and kept for the session).
- **Integrated transaction metadata.** `SoloRecords.Finish` now carries the detached exact placement. This replaces the original row-matching proposal; no extra identity lookup or simulation/network state is introduced.
- **Policy point for Codex.** Codex's live display deliberately claims no race position (its off-screen label "does not invent a behind/ahead race position", which still holds). At the owner's request the HUD and results now show places from each racer's own reports. They are labelled as such and the "No agreed winner or standings" hint stays; no result is agreed, verified or sent.
- **Counts.** The HUD's place (2 font strings), the name tag (1), and in the results a Highscores button (1 frame), the sunburst, a medal and 12 confetti pieces (14 textures), the banner, its line, the wreath's rank and the racers' two rows (7 font strings): **90 frames, 91 textures, 150 font strings**, all created with the window. Nothing is created while driving or showing results.

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
- **`CapitalCities`** (generated data, `scripts/build_city_tracks.py`): `CapitalCities[id]` definitions for `Circuit.new`. Stormwind City Circuit: 2048×2048, road radius 56, wall radius 76, no plazas or solids (the 2026-10-22 rework removed the first build's plaza and fountain), six gates, a 3,831-unit loop and a 769-unit approach branch. Ironforge Grand Prix (`ironforge_gp`, version3): 2048×2048, the same radii, no plazas or solids, seven gates, a 7,077-unit loop and a 369-unit approach branch. Integrated version3 from `claude/ironforge-design` adds the two Forlorn Cavern `narrows` above; route, gates, spawn and the rest of the street are unchanged. Orgrimmar Canyon Rush (`orgrimmar_canyon`, version1; Codex-approved [2026-10-22](reviews/2026-10-22-orgrimmar.md) and integrated on `codex/live-multiplayer-integration`): 2048×2048, the same radii, `fullSpeedToWalls=true` (as Stormwind, the owner's choice there), `wallClearance`14 with1,222 generated junctions, no plazas, solids or narrows, four gates, a 4,769-unit loop and a 734-unit approach branch. It uses only existing definition fields; no Circuit change. **Proposed (`claude/darnassus-undercity`, for Codex review):** Darnassus Canopy Run (`darnassus_canopy`, version1): the same radii, `fullSpeedToWalls=true`, `wallClearance`14 with 931 junctions, no plazas, solids or narrows, six gates, a 3,895-unit loop and a 206-unit approach branch. Undercity Slime Circuit (`undercity_slime`, version1): the same radii and walls, 1,721 junctions, five gates, a 7,327-unit loop and **no branch**: its spawn lies on the loop itself, 131 units past the finish gate, as Mirage Raceway's does (`branches={}`; `Circuit.new` already accepts it). Both add the optional `elevation` table [proposed below](#proposed-track-elevation-claude-2026-10-23-for-codex-review), which `Circuit.new` ignores; nothing else new. **Proposed (`claude/undercity-river`, 2026-10-23, for Codex review):** Undercity version 2, the owner's revamp: the same radii, `fullSpeedToWalls=true`, `wallClearance` 14 with 1,340 junctions, six gates (Rogues' Quarter, Magic Quarter, Ruins of Lordaeron, War Quarter, Apothecarium, The Canals), a 5,797-unit loop round the canal ring that changes walkway on six bridges, each a sharp turn on (radius 70 on the centerline), a 197-unit straight and a sharp turn off; still no branch (the spawn 136 units past the finish gate) and `elevation` (the stone bridges' painted humps, 6 high, and the sunken Trade Quarter, which the course no longer enters). Ironforge version 4 sets `fullSpeedToWalls=true` at the owner's request for no shoulders on a city map: the only change of handling (its rough strip becomes road); its route, gates, spawn, narrows, junctions and walls are unchanged. Every city's picture is now paved from wall to wall (the generated `roadRadius` stays 56). Only existing definition fields are used; no Circuit change. Thunder Bluff Skyway (`thunder_bluff_skyway`, version 1, proposed on `claude/thunder-bluff`): 2048×2048, the same radii, no plazas or solids, six gates, a 5,616-unit loop, a 285-unit approach branch and six `narrows` (wall radius 54), one per rope bridge; no elevation. Version 2 (proposed on `claude/drive-fixes`) moves only the spawn: onto the loop, 70 units past the junction, facing up the west side, 75 units before the finish gate; the approach branch stays.
- **`Courses`** (new module, Claude: presentation data): `CUPS` (Proving Grounds, Capital Cities Cup); `LIST` in display order with `id, name, short?, cup, geometry ("oval" | "mirage" | "city"), background?, rough?, dust?, ground?, status, soon?`; `get(id)`, `available(id)`, `next(id)` (the next available course, wrapping), `build(id, crossesGate)` (the oval singleton, a fresh Mirage track, or `Circuit.new(CapitalCities[id])`; built once and kept). The other cities are listed `soon`: shown, not selectable (Thunder Bluff Skyway alone once Darnassus and Undercity, proposed on `claude/darnassus-undercity`, are ready). On `claude/thunder-bluff` (proposed) Thunder Bluff Skyway is selectable too and no course is listed `soon`; the mechanism stays for future courses.
- **`UI.SelectTrack(id)`** (**Codex: reviewed transaction**). Available IDs come from `Courses`; the track comes from `Courses.build`. The stopped/shown/out-of-combat and same-ID guards remain. A course background is UV-validated and loaded on a preallocated hidden staging texture. Only a successful guarded load swaps it into the visible slot; failed/throwing loads do not touch the old picture/crop/path or authoritative run. Both textures are pooled at window creation; no rollback load of the visible texture is required. The previous hidden picture can remain resident alongside the current one (up to32MiB of raw city pixels across two2048-square images, excluding preview textures/native overhead); this is bounded retention, not a memory benchmark. Catalog text supplies the button/status. Successful selection resets local run samples as before.
- **Track button** (**Codex**): steps through `Courses.next`, skipping a course that refuses to load on that click; still disabled while a run is active.
- **Visual (Claude):** eight pooled gate strips (the most gates a course has; unused ones hidden), the follow camera and ground colour for every course with a background, the effects' dust colour and the HUD's off-road wording from the catalog, the Oval's crate markers only on the Oval.
- **Menu (Claude):** the track screen lists the cups with their tracks, the coming-soon cities disabled; each track's preview comes from its own picture (cities: `Assets/Tracks/<City>/Preview.tga`, 512×512), loaded once per change with the usual guard. The saved track accepts any `Courses.available` id.

### Proposed: track elevation (Claude, 2026-10-23, for Codex review)

**Integration review, 2026-10-23:** Claude9143949’s two solo city definitions, painted levels and inert generated height arrays are accepted into codex/two-city-integration. Circuit still ignores elevation; no Physics/track-layer behavior changes. All slope/crest/bridge/kart-height proposals below remain unaccepted designs. Physical handling changes need a Physics compatibility review; bridges also need route/layer and replication contracts. Native newcity checks remain NOT RUN. The heading stays for existing links.

The owner asked for a way "to add elevation to maps, as some of our maps clearly need it" and chose all three steps offered: looks first, then slopes you can feel, then bridges over the track. [ADR 0015](adr/0015-track-elevation.md) (proposed) records the plan. Only the first step is implemented; the rest needs Codex's physics and a shared rendering change.

- **Implemented (art only, offline):** a city layout may carry `elevation` (`scripts/city_layouts.py`): a default ground height, level polygons with heights (later ones win, optionally with their own paving), the street's heights as loop-arc anchors joined by smoothstep ramps, and a constant height per branch. `scripts/city_paint.py` draws what those heights show from the karts' camera (looking north, the sun in the north-west): south-facing retaining walls where higher ground lies north of lower (hanging below the street's wall where the street is the higher side), lit brinks and shaded feet where ground drops away northward, sun shadows cast south-east from every rise, higher ground slightly brighter and lower darker, and ramps lit by their slope with paving joints laid across them. Darnassus has three tiers (the Craftsmen's and Warrior's at 44, the Tradesmen's at 22, the gardens and lake at 0; the street ramps down at up to 13.9% and back up at up to 9.9%); Undercity's Trade Quarter is sunk 30 below its rings (ramps of up to 15.9%). Cities without `elevation` paint byte-identically.
- **Proposed data (generated; nothing reads it yet):** `CapitalCities[id].elevation = {centerline={h1..hn}, branches={{...}...}}`, the street's height in world units at each centerline and branch point (tenths), in the same order and count as those points; linear interpolation along a segment matches the painted profile to within the 16-unit point spacing. Absent means flat; Stormwind, Ironforge and Orgrimmar carry none. `Circuit.new` copies named fields only, so the table is inert until accepted.
- **Proposed physics (Codex's decision):**
  1. *Slopes:* a grade term along the kart's heading, `a = -G * dh/ds`, with `dh/ds` from the nearest loop/branch capsule's endpoint heights and a tuning constant `G` (a gain under 1 keeps the painted 14-16% ramps playable). Uphill slows, downhill speeds up; fixed-step and deterministic like the rest of Physics. Off-course texels have no height: walls stay where they are.
  2. *Crests (optional, later):* where the grade drops faster than `v^2`-scaled curvature allows, a short airborne state (no steering or throttle, ballistic, landing on the street). Opt-in per anchor rather than automatic.
  3. *Bridges over the track:* the street may cross itself when the two passes differ in height by at least a clearance (proposed 40). Each capsule keeps its height; a kart belongs to the capsule it last drove on and ignores capsules more than a step (proposed 12) above or below it, so the lower pass runs under the deck. `validate_geometry` would accept a crossing only with that clearance; checkpoints are unchanged (gates stay on one pass). Rendering needs the deck as an overlay drawn over karts on the lower pass and under karts on the upper: a pooled texture per bridge in UI/Presentation, reserved by Codex at present.
  4. *Kart height (UI/Presentation):* optionally scale a kart's sprite and offset its shadow by its height. Deferred while Codex's multiplayer-grid reservation holds Presentation and UI.
- **Not claimed:** no game-client run, no physics change, no route that needs a bridge over the track yet (neither Darnassus nor Undercity crosses itself; Undercity version 2's bridges cross its slime, not the course).
- **Multiplayer:** SessionTransport's supported track list is Codex's; neither city is in its compatibility list; city multiplayer is not wired.
- **Current integrated counts:** 79 frames, 166 textures and 81 font strings; eight pooled track buttons now show seven available tracks and Thunder Bluff coming soon. On `claude/thunder-bluff` (proposed) the same eight buttons show eight available tracks. No per-city or per-frame widget allocation; native cost remains unmeasured.

### Proposed: floors and boost pads (Claude, `claude/warsong-plan`, 2026-10-27, for Codex)

The original Claude proposal below is retained for context and anchor stability.
Codex accepted and implemented the bounded foundation with changed ramp fields,
split movement coordinates, per-track mechanics compatibility and explicit
remote levels. [LAYERED_TRACKS](LAYERED_TRACKS.md) is the current contract;
[ADR0022](adr/0022-floors-and-boost-pads.md) and the [Warsong plan](art/tracks/warsong-gulch.md)
record the request. Proposed rendering/drop-down/registration work remains open.

- **Levels (track data).** A floor area (room, corridor, path), wall or solid may carry `level`, a small integer (absent: 0). Areas on different levels may overlap.
- **Ramps.** `{level={low, high}, lowEnd=edge, highEnd=edge, ...area}`: drivable from both levels; leaving through `highEnd` puts a kart on `high`, through `lowEnd` on `low`; staying keeps the level.
- **Kart state (Physics).** A new `level` field, set by the spawn (`track.spawn()` may return `level`) and changed only by ramps. Deterministic from the previous state and the step.
- **Track interface.** Optional last arguments, ignored by flat tracks:

  ```lua
  track.isDrivable(x, y, level?) -> boolean
  track.surfaceAt(x, y, level?) -> "road" | "grass" | "wall"
  track.resolveMovement(previousX, previousY, targetX, targetY, level?) -> x, y, hit, level
  ```

  `resolveMovement` returns the level after the move (a ramp's rule); a kart meets only its level's walls and solids, and a ramp belongs to both of its levels.
- **Gates.** An optional `level`; `crossesGate` awards only to a kart on that level. Order and laps unchanged.
- **Drop-downs (optional, later).** One-way edges from a higher level to a lower one.
- **Multiplayer.** The friend's level, sent in the live state (a protocol version change) or inferred by the receiver. Codex's call.
- **Boost pads.** `track.pads = {{id, x, y, radius, level?, boostTicks}}`. Entering a pad's disc on its level sets `boostTicks = max(boostTicks, pad.boostTicks)`; leaving re-arms it for that kart. Proposed strength: a tier-2 drift boost. No new live field (`boosting` exists).
- **Claude's side, after acceptance:** roof overlays drawn over karts below them and fading while the player is under one; karts drawn by level; the pads' boots marks; the guiding arrow (`course.guideArrow`, Warsong only), which needs nothing from Codex. Built on `claude/warsong-layout`: [the next section](#two-floor-presentation-warsong-gulch).

<a id="warsong-gulch-version-3"></a>

### Proposed: Warsong Gulch version 3, both bases alike (Claude, `claude/warsong-v3`, 2026-10-28, for Codex)

Additive to the version 2 section below; no LayeredTrack, Physics, Checkpoints, protocol or score code change. Client NOT RUN.

- **Data:** `Battlegrounds.warsong_gulch` is version 3: 15 rooms (floor 0: the field, its two corners, the two tunnels; floor 1: at each base its plateau, front yard, lobby, flag room and tunnel top), 4 ramps (each base's outside ramp and its tunnel's climb), 7 gates (*Alliance front door*, *Alliance flag*, *Alliance tunnel*, *Horde front door*, *Horde flag*, *Horde tunnel*, *Mid*), 2 pads, 7 round solids (the flags, mid's stumps, the huts), 2 overlays, `routeGates`. Both flags stand on floor 1. Same fields and rules as version 2; the owner's lap: each base up its outside ramp, in at the front door, round the flag, out down its tunnel.
- **Generator:** with a solid named `mid_stumps`, `build_battlegrounds.geometry` lays the finish (the last gate) across the stumps' middle from its first end (the field's wall) to the stumps' near side, east or west (version 1 had it west only).
- **Presentation:** new `onRamp(track, x, y) -> boolean` (within one of `track.ramps`' boxes); `drawnHigh(track, x, y, level)` is `level == 1 or onRamp(...)`, unchanged. `roofAlpha(roof, x, y, high)` is unchanged; the UI now passes `high` only for a kart on floor 1 off the ramps, so on a ramp a cover fades by its distance like on the ground (down a climb, the cover ahead fades before the kart drops below it). `guideHeading`'s clear line now keeps 3 units to spare: the line and its two parallels 3 units either side, each sampled every 3 units, must be drivable (a line only grazing a corner was taken as clear: 4 of 1,258 v3 lap steps). Per frame three times version 2's samples: measured offline (PUC Lua 5.1 via lupa, the cloud machine), `isDrivable` 0.73 µs, a `guideHeading` call about 0.13 ms in the open field and 0.17 ms at a bend (0.05 ms before); no allocation. Native frame cost NOT RUN.
- **UI (Claude's regions):** the visual body of `render` computes `onRamp` once: the kart's draw set from `level == 1 or ramp`, `placeRoofs(x, y, level == 1 and not ramp)`. No new texture (budget 91/96/151).
- **Version:** trackVersion 3 starts a new Warsong board (version 1 and 2 records stay); Codex's `test_peer_session` pin (trackVersion 3; 2 now incompatible) and `test_multiplayer_integration`'s floors (`0101010101010`, both pads each lap) follow it; `services/leaderboard/catalog.json` regenerated.

<a id="warsong-gulch-version-2"></a>

### Proposed: Warsong Gulch version 2, the route-following arrow (Claude, `claude/warsong-v2`, 2026-10-28, for Codex)

Additive to the section below; no LayeredTrack, Physics, Checkpoints or protocol change. Client NOT RUN.

- **Data:** `Battlegrounds.warsong_gulch` is version 2 (the real gulch: 14 rooms, 2 ramps, 7 gates, 2 pads, 6 round solids, 2 overlays). New field `routeGates = {i1, ..., i7}`: for gate k, the 1-based index of the `route` point the reviewed route was driving to when it crossed gate k (recorded by `build_battlegrounds.validate`'s walk; `test_warsong` checks it against Checkpoints).
- **Courses:** `Courses.route(id) -> {points=route, gates=routeGates}` for a layered course with `guideArrow`, else nil.
- **Presentation:** `GUIDE_ARROW.ahead = 110`; `guideHeading(track, progress, x, y, route?, level?) -> heading, distance, along`: with a route, toward a point along the route past the route's nearest point to (x, y), looked for on the segments from the previous gate's crossing to the next gate's (to the route's end at most). Given the kart's `level` and a track with `isDrivable`, the point is the farthest of `ahead` × {1, 0.82, 0.64, 0.46, 0.32, 0.18, 0.08} along the route to which every point of the straight line from the kart, each 3 units, is drivable on that floor (after Codex's review of `d5fabbf`: the point 110 on can lie across a corner); with no clear one, the nearest. `along` is true when the route was followed (the UI then shows the arrow at any distance). A route it cannot follow (too short, a crossing past its end, a malformed point) falls back to the gate's middle, as without one, and `along` is nil. Per frame: at most seven lines of `isDrivable` samples, no allocation. `ROOF_FADE_LEAD = 32`: `roofAlpha` starts fading `ROOF_FADE_LEAD` units before an under box and reaches `ROOF_FADED` `ROOF_FADE_DEPTH` units in. `gateGlow(seconds) -> 0.55..1`, a triangle pulse.
- **UI (Claude's regions):** `layoutRoofs` reads `UI.guideRoute = Courses.route(course.id)`; the render passes the kart's level (the grid pose's before GO) to `placeGuide`, which passes it and the route on and sets `UI.glowGate` (the next gate while a guided run is on): `placeTrackMarkers` draws that gate's marker 10 units wide (5 otherwise) and `placeGuide` pulses its alpha by `gateGlow` of the run's tick time. Only courses with `guideArrow`; no new texture (budget 91/96/151).
- **Version:** trackVersion 2 starts a new Warsong board; Codex's `test_peer_session` pin and `test_multiplayer_integration`'s per-lap floors follow it, and `services/leaderboard/catalog.json` is regenerated by `export_score_catalog.py`.

<a id="two-floor-presentation-warsong-gulch"></a>

### Proposed: two-floor presentation and Warsong Gulch (Claude, `claude/warsong-layout`, 2026-10-27, for Codex)

Claude's side of [LAYERED_TRACKS](LAYERED_TRACKS.md), on Codex's `5c481d4`, for review. No Codex-owned file changes. Warsong is listed as coming soon and cannot be selected, built, raced or scored ([the sheet](art/tracks/warsong-gulch.md)). Client NOT RUN.

- **Data (`Battlegrounds.lua`, generated by `scripts/build_battlegrounds.py`):** `namespace.Battlegrounds[id]` is a LayeredTrack definition (`laps=3`, `wallInset=18`, rooms with `level`, ramps, gates with `level=0`, pads, solids with `level`, spawn with `level=0`) plus two fields LayeredTrack does not read:
  - `overlays`: `{{id, name, x0, y0, x1, y1, under={{x0, y0, x1, y1}, ...}}, ...}`, each roof's box in its picture and the boxes of the rooms below it (clipped to the box);
  - `route`: the reviewed route's points, for the tests.
- **Courses:** a course with `geometry="layered"` builds with `LayeredTrack.new(Battlegrounds[id], crossesGate)`. Optional course fields: `roofs` (the roof picture's path) and `guideArrow` (true on Warsong only). `Courses.roofs(id)` returns the course's `overlays`, or nil for any other course. Warsong keeps `soon=true` until Codex's registration.
- **Presentation (pure; reads, never writes):**
  - `drawnHigh(track, x, y, level) -> boolean`: drawn over the roofs, on floor 1 or anywhere inside a ramp's rectangle;
  - `ROOF_FADED = 0.25`, `ROOF_FADE_DEPTH = 24`; `roofAlpha(roof, x, y, high) -> alpha`: 1 unless `high` is false and (x, y) is inside one of `roof.under`, fading to `ROOF_FADED` over the first `ROOF_FADE_DEPTH` units in;
  - `roofCrop(view, roof) -> left, bottom, width, height, u0, u1, v0, v1` on the canvas, or nil off camera; the roof picture is world-aligned and the world's size;
  - `GUIDE_ARROW = {path, frames=16, columns=4, size=26, reach=46}`; `guideHeading(track, progress, x, y) -> heading, distance` toward the middle of `track.gates[progress.nextGate]`, nil without one or once `progress.complete`; `arrowFrame(heading) -> 0..15` (counter-clockwise from east); `arrowCoords(frame) -> u0, u1, v0, v1`.
- **UI (Claude's regions only: `UI.Create`'s visual part, `layoutTrack`, the visual body of `render`, `renderOpponent`):**
  - reads the player's `UI.state.level` (the grid pose's level before GO), the friend's copied `remote.level` (as `UI.opponentLevel`), and `UI.checkpoints` for the arrow;
  - creates 4 pooled roof textures (`OVERLAY`, sublevel -1) and the arrow (`OVERLAY` 7) with the window, hidden on other courses; the roof picture loads once per path, guarded;
  - the roof picture is required scenery (after Codex's review of `bf94d2b`): `UI.SelectTrack` loads it after the background's staging load and before anything of the course shows, and refuses the course on a refusal ("roofs unavailable", previous selection retained; the multiplayer Ready refuses with it); `UI.Start` refuses a course whose `roofs` are not loaded, with the background's "Track scenery unavailable". These are one-condition additions to the shared SelectTrack loading hook and to Codex's Start refusals;
  - draw sets (`OVERLAY` sublevels of the kart, its outline, sparks and flames behind/in front): flat courses 0, 1, -2, -4, 2 as before; on a two-floor course, on the ground -5, -4, -6, -8, -3, and on floor 1 or a ramp 3, 4, 2, 0, 5; dust and wind puffs `ARTWORK` 6 as before, except on floor 1 or a ramp, `OVERLAY` 0; the friend's kart -5 or 3 by its floor, and back at 0 on any other course;
  - budget: 91 frames, 96 textures, 151 font strings (the roofs and the arrow, the menu's cup heading and coming-soon button).
- **Menu:** the Battlegrounds Cup's heading and "Warsong Gulch (soon)", disabled. Warsong's track-screen copy and tall preview cell are ready; `Menu.trackRows` lists a course still `soon` only as coming soon, and the Highscores cycle skips it.
- **Proposed LayeredTrack rule (Codex's file):** a room may meet a ramp's corridor only at the end plane its own floor leaves by, from beyond that end; otherwise its core stays at least `2 * checkpointMaxStep` (10) from the corridor. A floor-1 room touching a low end, a floor-0 room touching a high end, or any room touching a ramp's side lets a kart onto the ramp from a floor it does not connect to. `LayeredTrack.new` accepts such a layout today; `build_battlegrounds.py` refuses it, and Warsong satisfies it.
- **Needs Codex before Warsong is playable:** a review of the geometry, the route and the shared grid at mid; its course, invite and score IDs; score sharing for a Physics 13 board beside the Physics 12 ones; then `soon` removed.

<a id="proposed-dungeon-sprints-the-scarlet-crusade-cup"></a>

### Implemented: dungeon sprints (the Scarlet Crusade Cup)

Proposed by Claude on `claude/scarlet-graveyard`, 2026-10-25, for Codex's review. The owner approved Claude making the minimal Race and SoloRecords changes there for that review ([ADR 0020](adr/0020-dungeon-sprints.md)). Codex reviewed and integrated the source, including the score-sync and status-line fixes. Client NOT RUN. See [the Scarlet Graveyard sheet](art/tracks/scarlet-graveyard.md).

- **`track.laps`** (optional; implemented in Codex's `Race`). An integer from 1 to 9; absent means 3.
  - `Race.new` takes `targetLaps` from it and refuses anything else outside that range; `Race.newRunning` inherits it.
  - The finish `reason` is "Sprint complete" for 1, "Three-lap run complete" for 3 (unchanged), and "N-lap run complete" otherwise.
  - Checkpoints and Laps are unchanged. A sprint finishes on its first completed lap, at its last gate.
  - `LiveRace` still refuses a launch bundle whose `targetLaps` is not 3.
- **`SoloRecords.Context(track)`** (implemented): `lapCount = track.laps or 3`.
  - A sprint's board holds one-run totals under its own key: lap count 1.
  - `Finish` already requires `race.targetLaps == context.lapCount`.
- **`Dungeon.new(definition, crossesGate)`** (new pure module, written by Claude; geometry for Codex's review). It returns the [track interface above](#track-geometry-and-assets), plus copies of `rooms`, `solids`, `gates` and the optional `laps`.
  - **Definition:** `id, version?, name, width, height, wallInset, checkpointMaxStep?, laps?, rooms, solids?, gates, spawn`. Each room is `{x,y,width,height,surface,shape?}`, with surface `"road"` (stone) or `"rough"` (a lawn); each solid is `{id,x,y,width,height,shape?}`. Bottom-left origin, as every track.
  - **Round rooms** (proposed on `claude/scarlet-library`): `shape="disc"` makes a room the disc inscribed in its square, which must be square; `"rect"` or no shape is a rectangle. The kart centre stays `wallInset` inside the round wall.
  - **Round solids** (reviewed source integration): `shape="disc"` makes a solid the disc inscribed in its square, which must be square (a round pool); `"rect"` or no shape is a box. The kart centre stays `wallInset` outside its rim.
  - **The floor** is every room shrunk by `wallInset` on each side (a round room to its radius less the inset). Rooms that meet overlap by at least two insets, so the floor runs on through the doorway.
  - **`surfaceAt`:**
    - `"wall"` outside the inset perimeter, on a solid's footprint (edges included; a round solid's disc), or off the floor;
    - otherwise `"road"` wherever a stone room covers the point;
    - otherwise `"grass"` on a lawn: Physics' existing rough response, at most 70 units a second.
  - **`isDrivable`:** on the floor, clear of every grown solid, and on stone.
  - **`constrainPosition`:** the perimeter clamp only, as on Track.
  - **`resolveMovement`:**
    1. the perimeter, grown boxes and grown circles use earliest swept contact with bounded slide iterations; circles remove inward normal remainder and preserve tangential movement;
    2. then the floor/recovery guard: an endpoint off the floor, or within a round solid's reach, moves to the nearest allowed point no further from the step's start than the step was long, or stays at the start if none is found, and reports a hit. Round-room walls use radial projection. This fallback does not replace swept disc contact.

    A resolved step never moves further than requested, so `checkpointMaxStep=5` still holds. A centre that starts off the floor or inside a grown solid (never by driving) moves to the nearest allowed point, or back to the spawn.
  - **Refused at construction:**
    - missing fields;
    - a room not wider and taller than two insets;
    - an unknown surface;
    - an unknown shape, or a round room that is not square;
    - an unknown solid shape, or a round solid that is not square;
    - a non-finite solid;
    - `laps` out of range;
    - a spawn off the floor or inside a solid.
  - **Cost:** a 64-unit grid of rooms and solids is built once. A step of up to 16 units on either axis checks only its cell's lists. A longer step checks every solid, plus every room when it ends off the floor. No allocation per step.
- **`ScarletCrusade`** (generated data, `scripts/build_dungeon_tracks.py`). `ScarletCrusade.scarlet_graveyard`:
  - version 2 on `claude/drive-fixes` (version 1 is integrated), 2048 × 1024, `wallInset` 18, `laps` 1;
  - 18 rooms, 17 stone and the cloister's lawn, and 59 solids (version 2: the chamber's wings start 20 units east of the west hall, so a wall stands between them either side of the west door);
  - three gates: Chamber of Atonement, Forlorn Cloister, Honor's Tomb (the finish);
  - spawn (1945, 150), facing west;
  - `route`, the reviewed way through. It is data for the tests and the review; `Dungeon.new` does not read it.

  `ScarletCrusade.scarlet_library` (proposed on `claude/scarlet-library`):
  - version 1, 2048 × 2048, `wallInset` 18, `laps` 1;
  - 41 rooms: 38 stone rectangles, the courtyard's lawn, and two round rooms (the fountain's court and the round library);
  - 65 solids (on `claude/drive-fixes`);
  - five gates: Huntsman's Cloister, Houndmaster Loksey (across the dead-end kennel: in across it, then back out), Gallery of Treasures, Athenaeum, and Arcanist Doan (the finish);
  - spawn (80, 1668), facing north; and `route`.

  `ScarletCrusade.scarlet_armory` (proposed on `claude/scarlet-armory`):
  - version 1, 2048 × 2048, `wallInset` 18, `laps` 1;
  - 26 rooms: 24 stone rectangles, the Training Grounds' yard (a lawn) and one round room (the Hall of Champions);
  - 38 solids;
  - five gates: Training Grounds, Footman's Armory, Crusader's Armory, Hall of Champions, and Herod (the finish, across the round hall's middle; Herod is solid and stands on it, so the karts cross it either side of him);
  - spawn (500, 105), facing east; and `route`.

  `ScarletCrusade.scarlet_cathedral` (proposed on `claude/scarlet-cathedral`):
  - version 1, 1024 × 2048, `wallInset` 18, `laps` 1;
  - 24 rooms: 21 rectangles of stone or wood, the two gardens' lawns, and one round room (Fairbanks' chamber);
  - 46 solids, the gardens' three pools among them: the lower pool and the falls are boxes, the round pool a round solid;
  - four gates: Chapel Gardens, Upper Gardens (through the falls), Crusader's Chapel, and High Altar (the finish, across the chancel before the altar);
  - spawn (790, 110), facing west; and `route`.

  The generator refuses a layout unless every gate is unavoidable (a flood fill of the floor with the gate as a barrier) and the route crosses the gates in order without touching a wall or a solid. It counts a crossing only across the gate's own segment, as `Track.crossesGate` does. On `claude/scarlet-armory` it checks the floor just past a gate all along its length, not only at its middle, so a solid may stand on a gate. On `claude/drive-fixes` it also refuses an invisible wall (the karts' floor ending with no wall painted within the inset and 3 units, measured square, as where two rooms abut without a doorway) and, when painting, a model that is not solid with its drawn body more than 3 units onto the kart centre's floor. Neither rule changes the runtime contract. On `claude/scarlet-cathedral` a layout's `pools` become solids of their own shape, painted as water over exactly their footprints, and the invisible-wall rule counts the water as a visible edge.
- **`Courses`:**
  - `CUPS` gains `{id="scarlet", name="Scarlet Crusade Cup"}`;
  - geometry `"dungeon"` builds `Dungeon.new(ScarletCrusade[id], crossesGate)`;
  - Scarlet Graveyard is available; Scarlet Library, Scarlet Armory and Scarlet Monastery are listed `soon`. On `claude/scarlet-library` the Library is available too, and only the Armory and the Monastery are `soon`. On `claude/scarlet-armory` the Armory is available as well, and only the Monastery is `soon`. On `claude/scarlet-cathedral` the Monastery's place goes to Scarlet Cathedral (`scarlet_cathedral`), available, and no course is `soon`.
- **Load order (both TOCs):** `CapitalCities.lua`, `Dungeon.lua`, `ScarletCrusade.lua`, then `Courses.lua`.
- **Presentation (Claude's regions).** When `targetLaps` is 1:
  - UI `refreshCheckpoints` shows "Checkpoints: sprint complete";
  - `refreshSummary` shows "Sprint | Total: …" and "All N gates" at the finish, or "Sprint | Time: …" and "Gates: n/N" when stopped;
  - `refreshHud` shows "Sprint | Time: … | Last run: …";
  - Menu's race lines show SPRINT, the time and GATES n/N, and results show "Run" for the lap time;
  - the Highscores screen's rule line names a lap-count-1 board's times as sprints, reusing its label.

  The status line in `UI.Start` and `step` now says "Sprint" for this one-run course and retains "3 laps" for circuits.
- **Counts:** the Scarlet cup's heading and four track buttons brought the pool to89/69/136 after Oval retirement. Reviewed stat bars add8textures and4font strings at window creation: **89 frames,77 textures,140 font strings**. No driving-time creation is added. The proposed race screens (`claude/race-screens`, [above](#proposed-race-screens-and-score-celebrations-claude-clauderace-screens-2026-10-26)) bring it to **90/91/150**.
- **Score sync:** Codex's combined adapter admits all eleven active contexts with stable codes and an extended bounded HELLO; the retired O digest remains zero. The original standalone Claude branch retains the documented sync dependency; use the combined build.
- **Not claimed:** no client run, no multiplayer sprint, and no Physics change.

## Rendering cadence, resources and lifecycle

Rendering currently runs once per delivered active `OnUpdate`, after zero or more fixed steps; it is not locked to 60 FPS and has no separate render timer. Meter, gate colors and countdown update through the render path with cached values. The numeric HUD refreshes every ≥0.25 **simulated** seconds, on lap/status changes and immediately at Start/Stop/selection. UI lifecycle events may draw outside `OnUpdate`. Inactive `UI.OnUpdate` does no simulation work; a shown kart/garage preview has its own visual spin callback, independent of race ticks.

The window is 856×762 with an 800×480 canvas. Current integrated explicit allocations are **71 frames, 165 textures, 80 font strings** (**75** frames with the four Warcraft III karts proposed on `claude/kart-roster-wc3`: one list button each), including the pooled front end ([above](#implemented-front-end-menus-race-hud-and-results)). The preceding roster/results baseline was 11/151/13, including two Oval obstacle markers, Close results/Kart buttons and 38 effect textures. Production no longer allocates Oval road/obstacle textures. Eight gate strips (unused strips hidden), four perimeter strips, two background slots and kart regions remain pooled. Markers render the physical rectangles in ARTWORK at Oval's fixed scale and stay hidden on Mirage, including camera updates. Counts exclude Core's event frame, template/native internals and other addons. They are offline-checked explicit allocations; the earlier 9/111/13 baseline has scoped client observations. These counts are not a client memory/FPS measurement or a ban on reviewed pool changes.

Preserve creation-time pooling: no `CreateFrame`/`CreateTexture`/font-string creation, texture file loads or chat output per simulation tick or render callback. Current snapshots allocate bounded Lua tables per tick; there is no promise of zero Lua allocation. Profile before replacing their immutable-style behavior. Opt-in Performance collects at most 600 callback spans and includes instrumentation overhead; it is not exclusive CPU/GPU cost.

`UI.SelectTrack(id) -> boolean` accepts the eleven available production Courses IDs only with an existing shown window, while stopped and out of combat. The staging texture's guarded `SetTexture` must return true; its guarded UV check must succeed before committing the switch. Failure preserves the old track/run/sample. Successful selection clears samples and creates a new spawn/lap state; loaded artwork is reused. The Track button is disabled while active; clicking a disabled selector does not stop a run. Mirage is the default after reload; `UI` itself does not persist the selection. The integrated front end saves deliberate successful choices, including the already-current ID, and restores the saved choice through this function ([above](#implemented-front-end-menus-race-hud-and-results)). The same-ID return is allowed only after that map's scenery is loaded; an initial default load uses the guarded transaction. Failed loads preserve the current run/sample, and Start requires a valid loaded production map.

Capture/release safeguards and combat/lifecycle handling remain controller-owned. Under the owner's revised input policy, incidental mouse clicks and unassigned keys leave the run active; there is no global-mouse event requirement for Start. Stop, Escape and Close deliberately end the run; Enter and detected chat/text focus release racing input, as do supported focus-loss and lifecycle paths. Required keyboard capture/propagation and text-focus capabilities still gate Start, and capture never automatically resumes. Build 70450 lacks `IsGameWindowFocused`/`IsWindowFocused`; full held-input focus-loss behavior remains unverified. Do not substitute guessed protected APIs or make global WoW movement bindings part of rendering. See [FEASIBILITY](FEASIBILITY.md) and [ADR 0006](adr/0006-combat-interrupted-results.md).

## Proposed changes require coordination

Possible future work includes an explicit render snapshot/scene boundary, collision feedback events, additional sprite atlases/animation, foreground occlusion, track hashes, saved race records and multiplayer snapshots. None is a callable contract today. Do not implement an architecture sketch as though its fields already exist. Agree a contract/ADR update and compatibility impact before adding or renaming authoritative fields, changing units/tick semantics, track geometry or lifecycle callbacks. The optional Test Oval movement hook and version changes described above are implemented in this slice; the future boundaries listed here are not.

Offline state/geometry/UI-mock checks are evidence of those scopes only. Opaque Mirage texture loading and the stopped close-camera view were observed in the client; the owner subsequently approved the installed trike and scenery shadows. Combined-build menu behavior, moving camera edges, latest handling acceptance and sustained performance require their own evidence. AKT722–725 record the scoped transport/reload evidence; they do not establish playable replication or production architecture.

## Implemented opt-in start clock and backend race initialization

[START_CLOCK](START_CLOCK.md) is the exact additive contract for `ClockProtocol`, `StartClock`, `RaceStart`, `PeerSession.handoffStart`, `Race.newRunning`, and SessionTransport's `HostCoordinated/ListenCoordinated/PrepareStart/TakeRaceStart`. Existing control APIs and solo `UI.Start` are unchanged. Coordinated mode adds copied `clock` diagnostics and `canPrepareStart`, owns its proposal internally and yields one actual tick-zero Physics/Race bundle at mapped GO, without opening UI or running an opponent.

These interfaces are retained in the combined source; binding them to Claude's multiplayer menu still requires shared review. Frontend code invokes deliberate actions and reads copied views; it must not consume backend tickets/bundles or write authoritative state. A lost final ACK can leave only the guest armed. Clock uncertainty excludes separately allowed callback lateness; source/mock results do not establish actual synchronized race feel. Native clock traffic shares existing persistent budget/lease. Actual client checks and movement/finish integration remain open under [ADR 0014](adr/0014-experimental-start-clock.md).

### Experimental multiplayer integration checkpoint (2026-10-22)

The native and player-facing integration in [LIVE_RACE](LIVE_RACE.md#implemented-native-and-player-flow-integration) supersedes older unwired/Coming soon notes above for this branch. Existing solo APIs remain compatible. Additive backend PeerSession.beginRace consumes only coordinating state and keeps terminal cancellation after negotiation. UI.MultiplayerAction owns command safety; the menu invokes it through Core's registered view/action bridge. Input and local Physics have one owner. Explicit pool79/166/81. No agreed remote result, contact, production authority or actual-client acceptance is claimed. Owner explicitly assigned this wiring to Codex; Claude's worktree/art/handoff remain unchanged.

## Reviewed wall handling revision8 (2026-10-23)

The public state remains15fields, with no new normal/velocity/event API. Geometry
hooks remain read-only and unchanged. Physics8’s response replaces repeated
quarter-speed/steering reset with an admitted-motion first-impact ratio and
dt-scaled40units/s² persistent scrape; exact blocking still stops. Steering
remains held, with faster parking yaw below80. Existing native compatibility
uses Physics.VERSION, so v7 peers are refused before grid/countdown/GO. Both
players must update. Scalar speed can exceed actual tangent travel during
contact; remote forecasts remain approximate. Native handling NOT RUN.

Reviewed Claudeee144b5 adds Undercityv2’s six flat canal crossings/sixgates and
Ironforgev4 fullgrip to its existing walls. All city paving is wall-to-wall;
tunnels and exposed-wall vertices remain. These are solo city definitions;
multiplayer’s negotiated tracks remain Mirage/TestOval. Decorative humps are
not an accepted slope/layer implementation.

### Light wall penalty — Physics9 (2026-10-23)

Owner reports the v8 wall slide has too little penalty. Physics9 retains the
slide/recovery model but applies a0.95factor on first contact and a0.95normal
speed ceiling during all contact (190forward,52.25reverse). Continuous scrape
drag stays40units/s². The percentage is not multiplied again each contact tick.
Leaving the wall immediately removes the ceiling. Steering, geometry, drift
cancellation, parking assistance and15state fields are unchanged. Both peers
needPhysics9; v7/v8 offers are rejected before GO. Native tuning NOT RUN.

### Requested 10% / 80% tuning — Physics10

Current first-contact factor WALL_SPEED_RETAIN=0.90; separate contact maximum
fraction WALL_SPEED_CAP=0.80. Forward/reverse contact bounds160/-44, normal
free-driving bounds unchanged. At high speed the cap can exceed the initial
10% penalty. Steering, geometry, continuous40units/s² drag and15state fields
remain unchanged. Versions7/8/9 are refused before live GO. Native feel pending.

## Implemented score-channel diagnostic (2026-10-24)

`AK.ScoreChannelProbe` is a finite diagnostic, not the score-publishing service.
Core calls `Init(frame)`, forwards the complete nine-field logged event to
`Message(...)`, forwards lifecycle events to `HandleEvent(event)`, and routes
`/akart scores check|report|stop` through `Command(argument)`.
`Start()` returns an arming boolean; `Stop(reason)` terminates; `GetView()`
returns a detached scalar snapshot (`phase`, `reason`, `sent`, `accepted`,
`selfEchoes`, `peerHellos`, `peerAcks`, native result/build/channel diagnostics).
No queue/identity roster/native function is exposed. A future Claude diagnostic
action may call these methods; it must not interpret accepted sends as delivery.

It owns the same exclusive Core frame lease as both existing transports, with
no work at load/login. Runtime checks and cleanup are independent of physics,
Menu and Highscores. Public score APIs and schemas are unchanged. Native route
evidence and the remaining gate are in [SCORE_CHANNEL](SCORE_CHANNEL.md).
