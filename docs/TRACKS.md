# Track pipeline and validation

## Track data v1 (proposed)
```lua
return {
  id = "tinker_speedway",
  version = 1,
  bounds = {width=1200, height=800},
  spawnGrid = {{x=320,y=420,heading=1.2}},
  roadRegions = {...}, -- polygon or tile bitmap, standardized collision geometry
  walls = {...},       -- line segments/polygons
  gates = {...},       -- ordered directional checkpoint segments
  items = {...},
  surfaceZones = {...}, -- asphalt/mud/ice/boost
  visuals = {atlas="...", tiles={...}},
}
```

## Prototype vs production
The starter's `Test Oval` is mathematical ellipse annulus to prove movement and rendering. It now has repeatable practice laps over ordered checkpoints, but is **not** the production track renderer and does not provide competitive lap validation.

The placeholder road derives its footprint from the same `Track` center and outer/inner radii used by `isDrivable`. It fills the outer ellipse with 64 horizontal gray bands and masks the island with 32 grass bands. All 96 textures are created once; the centerline is not used as a substitute road boundary.

The simulation keeps `isDrivable` as the road-only annulus predicate, while `surfaceAt` separately reports road/grass/wall. The island and exterior grass inside the canvas are traversable with slowdown and drift/boost cancellation. A rectangular perimeter constrains the kart center to `wallInset=18`, independent of the road radii. `constrainPosition` clamps an attempted endpoint while retaining tangent motion; collision scrubs speed once per step even at corners. Four pooled gray perimeter strips identify that limit; including the drift/boost meter, checkpoint indicators and lap HUD, current explicit UI counts are 6 frames/110 textures/9 font strings. Road geometry and spawn are unchanged. Client perimeter/checkpoint/lap appearance and off-road handling are **NOT RUN**; focused offline results are in `PROGRESS.md`.

Live build 70450 exposed horizontal seams and grass covering the road under mixed snapping states. The current renderer gives the grass explicit `BACKGROUND,-1` priority below the outer bands and disables sharpening/pixel snapping on the 96 bands only, once after geometry setup. Grass snapping and all geometry remain unchanged. A normal reload showed the complete road/island/marker/kart without seams at measured effective scale 0.72452831268311; read-only checks confirmed all 96 settings and grass priority. [Isolation and verified fix](evidence/2026-10-19-m0-road-layer.md). The supported-scale matrix and sustained performance remain pending.

Bands sample the ellipse at each row's midpoint. At the current dimensions their vertical boundary uncertainty is at most 3.40625 world units outside and 2.625 inside. This is a vertical raster approximation, not an exact vector edge or horizontal-error guarantee. Offline tests compare the actual mock rectangles with analytical road classification away from a 3.5-unit vertical boundary margin, including `(400,440)`, which the old tiles left unpainted despite being drivable. Client layout/scaling/performance acceptance is separate.

## Local checkpoint sequence

`Track.gates` defines four ordered finite segments: North, West, South, then Start, following counterclockwise motion from the right-hand spawn facing north. The Start strip now runs horizontally across the right-hand road at `y=240`, from `x=570` to `770`; it is the fourth gate rather than an immediate spawn award. The other gates cross the road at its north, west and south extremities. Four pooled strips show pending, next and passed gates; a separate text HUD names the next target and the passed count.

`Track.crossesGate(previous, current, gate)` uses actual movement-segment intersection and a signed gate direction. It accepts only a strictly negative starting side followed by a nonnegative ending side, with the intersection within the finite gate segment. Starting on the line and departing, parallel or zero movement, backward crossing, nonfinite coordinates and crossings beyond an endpoint do not count. Reaching a gate line can count once; leaving it cannot award the same crossing again.

The separate pure `Checkpoints` module returns progress `{nextGate, passed, complete, lastTick}`. Each consecutive fixed step considers only its next expected gate and can award at most one. Duplicate, stale, out-of-order or gapped tick reports return the same progress unchanged; there is no automatic gap recovery. A consecutive sample with nonfinite positions or movement longer than five units consumes its current tick without an award, allowing the next valid consecutive step to recover. These local consistency guards are not anti-cheat or proof of an entire valid road route. Standalone checkpoint progress remains terminal at `4/4`; the Laps adapter handles repeated circuits.

## Practice lap timing

The pure `Laps` module wraps Checkpoints with immutable state containing `checkpoints`, `completedLaps`, `lapStartTick`, `currentLapTicks`, `lastLapTicks`, `lastTick` and `lastFinishTick`. Its first lap starts at the deliberate Start Test Drive tick, including acceleration. An accepted fourth gate increments `completedLaps` once, records `lastLapTicks = finishTick - lapStartTick`, sets the next lap start to that same finish tick and rearms North. The new lap begins at zero elapsed ticks with no lost or double-counted finish tick. Practice continues without a fixed lap limit.

Duplicate, older or gapped reports leave all lap state unchanged. A consecutive rejected movement still consumes the tick and advances current lap time without an award; the next valid step can continue. All times stay integer ticks in simulation and become seconds only for display using the fixed 1/60-second step. They exclude dropped simulation time and stopped time; they are not independent wall-clock measurements. No best record, save, countdown, win result or competitive route guarantee is implemented.

UI advances laps immediately after each physics step using its previous and current simulation positions, never interpolated display coordinates. `UI.checkpoints` aliases the active lap's checkpoint progress. The gate cue rearms immediately after a finish; the separate lap HUD shows completed count, current time and last completed time at the normal text refresh cadence and on Stop. Stop, combat interruption and normal close/reopen retain the frozen sample; a fresh Start resets it. Gate geometry and the lap font string are constructed once, with no per-tick texture creation or chat. Client driving/appearance remains **NOT RUN**.

## Geometry responsibilities
- Track-local spawn positions, bounds, road/walls, surface grip, collision and recovery points.
- Checkpoint ordering must prevent reversed driving and teleport skipping; segment intersection tests must confirm correct gate direction.
- No automatic lap increment from polar-angle wrap alone in production.
- Track version and deterministic content hash must be transmitted to peers and recorded in ghost/replay metadata.
- Map supports normal and mirrored direction only if gate/spawn orientation defined.

## Content authoring
- Build a simple external Python asset/track validation pipeline producing read-only Lua tables; no external executable is needed by addon users.
- Lint spawn outside collision, gates out of order, isolated road islands, item pickup unreachable, wall intersection, max tiling and texture dimensions.
- Document copyright/ownership of every texture, icon, music/sound asset. Start from plain colored tiles where feasible.

## Initial track sequence
M0 `Test Oval` → M3 `Tinker Speedway` → M7 `Murloc Marsh` → M9 `Frost Gearway` and more based on performance metrics.
