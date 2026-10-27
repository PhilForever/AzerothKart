# Two-floor driving and boost pads: implemented authoring contract

2026-10-27. Codex's answer to Claude's [Warsong request](adr/0022-floors-and-boost-pads.md).
This is a tested engine foundation, not a built/selectable Warsong map. The
installed game remains736ac2f. Claude owns the layout/art/roof overlays/arrow.

## Geometry

Load Dungeon before LayeredTrack. Use
`AK.LayeredTrack.new(definition, AK.Track.crossesGate)`. The definition keeps
Dungeon's id/version/name/width/height/wallInset/checkpointMaxStep/laps,
rooms, solids, gates and spawn. Rooms/solids/gates/spawn add optional `level`
(nil defaults0; false/unknown values reject). Floors are explicitly0 and1;
ordinary rooms at different floors may overlap. Every floor needs a room.
The constructor returns `layered=true`, `levelCount=2`, `validLevel(level)`.

Ramps are authored rectangles:

```lua
ramps = {
  {id="connector", x=140, y=100, width=80, height=40,
   axis="x", ascending=1, lowLevel=0, highLevel=1},
}
```

With ascending1 the low end is minX/minY and high end maxX/maxY; -1 mirrors
them. Entry is allowed from the endpoint belonging to the kart's current
floor. Side/wrong-end entry blocks. Stopping, turning or reversing inside
retains the entry floor; leaving through an end sets that end's floor.
Arrival exactly on an end plane retains the current floor until departure.
The remaining movement immediately uses destination-floor collision.

Authoring constraints:

- Both dimensions exceed2×wallInset. Longitudinal length is at least32 and
  greater than4×wallInset. Use a short straight transition joined to ordinary
  curved corridors/rooms for a banana path; no continuous slope/height model.
- Reserve the ramp interior from other floor rooms. End overlap may extend
  up to2×wallInset. No driving underneath a ramp itself in this first contract;
  driving below an upper roof/ordinary floor is supported. A required crossing
  below a ramp would need an additional explicit ramp-occupancy state review.
- Usable ramp corridors exclude expanded solids. Distinct ramps must be
  more than16units apart (including numerical margin), so one accepted step
  cannot enter a second ramp after changing floors.
- Movement requests are bounded to16units; longer requests return the unchanged
  start with contact. Runtime Physics max13units at its allowed50ms step fits.
- Spawn must be on its clear floor, outside ramps. Portal centres are validated
  against the actual connecting floors; the runtime checks each actual exit
  point. This does not prove the whole portal width connects.
- Gates must have a clear centre on their own floor and their full bounding
  segment plus checkpointMaxStep margin must stay outside ramp corridors.
- Pad centres must lie on their own floor; the whole disc must stay more than
 16units clear of ramps. Pad definition validation below remains required.

Queries and scalar results:

```lua
track.isDrivable(x, y, level?) -> boolean
track.surfaceAt(x, y, level?) -> "road" | "grass" | "wall"
track.resolveMovement(x, y, targetX, targetY, level?)
  -> resolvedX, resolvedY, hit, newLevel, switchX?, switchY?
```

The last two scalars exist only on a floor-changing step. Physics uses them
to split pad sweeps onto the correct old/new floor; no allocated movement trace
or guessed floor. Treat geometry as immutable during a run. Use
[test_layered_track.lua](../tests/test_layered_track.lua) for a complete valid
definition, mirrored/vertical ramps and rejected authoring cases.

## Simulation and checkpoints

Physics.new adds `state.level` only for layered tracks, from the validated spawn.
Every step passes it to collision/surface queries and adopts the resolver's
explicit result. There is no dropdown, jumping, gravity, kart altitude, forced
floor inference or change to existing handling profiles.

An ordered gate is awarded only when both consecutive poses are on its floor.
The ramp/gate spacing rule prevents a transfer step from losing a legitimate
gate crossing. Tick bounds, directional crossing, lap order and duplicate
protection remain unchanged. Existing flat poses with no level mean0.

## Boots / boost pads

```lua
pads = {
  {id="alliance_boots", x=80, y=40, radius=12,
   level=0, boostTicks=78},
}
```

`Physics.ValidatePads(pads)` requires a plain dense array of at most32pads,
unique1..32-character alphanumeric/underscore/hyphen IDs, finite coordinates
0..11663.75, radius1..256, optional level0/1 and integer boostTicks1..600.
Physics.new checks these definitions; an upper pad requires a layered track.
Run Physics.new during authoring validation as well as geometry construction.

Resolved movement sweeps each own-floor disc. Outside-to-outside crossings
count even for a small pad; remaining inside does not refresh the boost.
Leaving and reentering rearms automatically without a mutable contact registry.
Spawning/stopping inside does not award a boost. A valid entry retains
max(existing,pad.boostTicks), beginning on the next fixed tick. Brake, wall
contact and non-road cancellation keep precedence.78 is the current tier2
duration; a pad adds no new force/speed profile or telemetry boost field.

## Compatibility and presentation

- Physics.VERSION remains12. `Physics.FEATURE_VERSION=13`;
  `Physics.versionForTrack(track)` selects13 only for layered/nonempty-pad
  tracks. All current11maps remain12 with exact legacy state shape/scores.
- Native controller options include a copied complete per-course
  `trackPhysics` map. Offers/start bundles must match the captured track's
  version; legacy/global callers remain supported. Old clients reject feature13
  before GO. Layered grids preserve the explicit spawn floor for both roles.
- Layered telemetry uses `LiveProtocol.Layered`, version3/AZKRUN3. It packs
  `driftTier + 3*level` in the existing drift character, keeping40payload bytes
  plus7prefix bytes. Flat AZKRUN2/40-byte packets remain byte-compatible;
  pad-only tracks use that flat codec with feature13 admission. No send-rate/
  byte-budget increase. Conditional registration leaves current flat setup alone.
- LiveRace validates/copies the explicit received level. It does not infer it
  from x/y or claim the peer's report is trustworthy. Render prediction stops
  before an inferred floor transfer; x/y correction resets on explicit changes.
- Claude can consume local `UI.state.level or0`, grid pose.level, copied
  `UI.liveView.remote.level` and drawn `UI.opponentLevel` (nil when hidden).
  Implement roof sorting/fades with pooled overlays; no Physics writes.

## Remaining Warsong integration

Claude can build layout/art against this contract. Keep it off the playable
catalogue until Codex reviews actual route/grid geometry, assigns course/wire/
score IDs and updates score sharing for mixed Physics12/13 contexts (its
current catalogue assumes one physics version). The current eleven boards must
not disappear when adding Warsong. These admission changes need the actual map.

The owner has not settled flag-room door/route details, roof drop-offs or
separate base starts. The foundation supports the existing shared grid and
ramps only; it does not decide those product questions. Arrow stays Warsong-only.

## Evidence

Focused Lua51 passes cover isolated geometry, correct floor walls/gates,
portal/reverse/side/destination collision, pad swept entry/rearm/cancellation,
legacy720-tick goldens for all3profiles, and a real LayeredTrack/Physics/
Checkpoints720-tick tape identical at30/60/144renderHz. Layered codec/start/live
and delayed two-native-client mocks preserve the traffic budget. These are
offline checks. Actual Warsong, roof rendering, client feel/performance and
new map-native networking: NOT RUN. No map/install/release claim.
