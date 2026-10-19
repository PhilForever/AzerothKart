# Track pipeline and validation

## Track data v1 (proposed)
```lua
return {
  id = "mirage_raceway",
  version = 1,
  bounds = {width=1024, height=1024}, -- candidate art-aligned world bounds
  spawnGrid = {...}, -- authored start poses supplied by the geometry blockout
  roadRegions = {...}, -- capsules in current blockout; other geometry may follow
  walls = {...},       -- line segments/polygons
  gates = {...},       -- ordered directional checkpoint segments
  items = {...},
  surfaceZones = {...}, -- asphalt/mud/ice/boost
  visuals = {
    background=".../Background.tga",
    foreground=".../Foreground.tga", -- optional static occlusion
    preview=".../Preview.tga",
    artBounds={width=1024,height=1024}, -- candidate, not a client limit
    preserveAspect=true, -- one uniform map-to-canvas transform
  },
}
```

## Prototype vs production
The starter's `Test Oval` is mathematical ellipse annulus to prove movement and rendering. It now has three-lap solo runs over ordered checkpoints, while the standalone Laps module supports repeated practice circuits. It is **not** the production track renderer and does not provide competitive lap validation.

The placeholder road derives its footprint from the same `Track` center and outer/inner radii used by `isDrivable`. It fills the outer ellipse with 64 horizontal gray bands and masks the island with 32 grass bands. All 96 Texture regions are created once; they are not 96 Frames. The centerline is not used as a substitute road boundary.

The first production map is **Mirage Raceway**, set on the dry, pre-flood Shimmering Flats. Its selectable blockout now uses one original precomposed `Background.tga`; optional `Foreground.tga`, `Preview.tga`, vehicle sprites, interactive props and VFX follow later. Road, wall, gate, surface and spawn geometry stays explicit Lua data; no painted pixel determines collision. The stopped Track button switches maps only after a guarded texture load succeeds; failure preserves the current map/run/sample. A successful change resets those samples. Test Oval remains the default after reload and a working fallback. The owner's screenshot shows the opaque Mirage background and correct whole-map orientation. A separate stopped build-70450 check confirms the close UV crop and Start/West strip alignment/clipping. Camera motion/edges, transparent sprite alpha and production-sprite rotation checks are **NOT RUN**. See [the map brief](art/MIRAGE_RACEWAY.md), [asset pipeline](ASSETS.md) and [ADR 0008](adr/0008-mirage-raceway-art-direction.md).

The Test Oval simulation keeps `isDrivable` as the road-only annulus predicate, while `surfaceAt` separately reports road/grass/wall. The island and exterior grass inside the canvas are traversable with slowdown and drift/boost cancellation. A rectangular perimeter constrains the kart center to `wallInset=18`, independent of the road radii. `constrainPosition` clamps an attempted endpoint while retaining tangent motion; collision scrubs speed once per step even at corners. Four pooled gray perimeter strips identify that limit and are repositioned/scaled for the selected map. Including map selection/background, the meter, checkpoint indicators, lap HUD and result summary, current explicit UI counts are 9 frames/111 textures/13 font strings. Oval road geometry and spawn are unchanged. Client perimeter/checkpoint/finish appearance and off-road handling are **NOT RUN**; focused offline results are in `PROGRESS.md`.

Live build 70450 exposed horizontal seams and grass covering the road under mixed snapping states. The current renderer gives the grass explicit `BACKGROUND,-1` priority below the outer bands and disables sharpening/pixel snapping on the 96 bands only, once after geometry setup. Grass snapping and all geometry remain unchanged. A normal reload showed the complete road/island/marker/kart without seams at measured effective scale 0.72452831268311; read-only checks confirmed all 96 settings and grass priority. [Isolation and verified fix](evidence/2026-10-19-m0-road-layer.md). The supported-scale matrix and sustained performance remain pending.

Bands sample the ellipse at each row's midpoint. At the current dimensions their vertical boundary uncertainty is at most 3.40625 world units outside and 2.625 inside. This is a vertical raster approximation, not an exact vector edge or horizontal-error guarantee. Offline tests compare the actual mock rectangles with analytical road classification away from a 3.5-unit vertical boundary margin, including `(400,440)`, which the old tiles left unpainted despite being drivable. Client layout/scaling/performance acceptance is separate.

## Mirage geometry blockout v1

`MirageRaceway.new(crossesGate)` returns independent pure track data with an explicitly injected gate-crossing predicate. It is bundled after Track and selectable while stopped using its own geometry-derived background; the kart remains a placeholder primitive. The blockout defines a 1024×1024 world, a closed 16-vertex centerline and a road formed by the union of radius-56 capsules along its segments (112 units wide). This uses the authored polyline without spline smoothing. The perimeter clamps at an 18-unit inset; off-road rough salt uses the existing grass response. The closer camera leaves current Physics v6 and this geometry unchanged.

The north-facing spawn is (700,360). The four ordered gate centers/directions are North at (550,900), crossing toward −x; West at (410,520), toward −y; South at (540,140), toward +x; and Start at (700,360), toward +y. Gate geometry and crossing rules remain data, not painted pixels. This is a gameplay blockout rather than a surveyed reconstruction or completed route-validation guarantee.

Mirage play uses a north-up follow camera at scale 1.5 in the existing 800×480 canvas. It follows the interpolated kart pose with 60 world units of look-ahead along the heading, clamped to map bounds. The visible world rectangle is approximately 533.33×320 units. Cropped background UVs, sprite positions/dimensions and clipped gates/walls share the same transform. The 17×31 world-unit placeholder becomes 25.5×46.5 canvas units, and the road becomes 168 wide. The earlier whole-map fit made them about 8×14.5 and 52.5 respectively; it remains only the authoring overview through `Presentation.fitViewport/project/unproject`. Test Oval retains its fixed overview. No world dimension, wall inset, driving speed or checkpoint rule changes with camera scale.

Run `python scripts/build_mirage_layout.py` to load the actual factory plus Presentation through pinned Lupa and regenerate the [JSON geometry guide](art/mirage-layout.json) and [SVG layout](art/mirage-layout.svg). The guide draws the same closed, unsmoothed centerline with a 112-wide round stroke, annotates gates/spawn/walls, and inverts world Y exactly once for SVG. It is a whole-map authoring artifact; the separate runtime TGA is generated against the geometry without its labels/footer. The owner's screenshot confirms earlier whole-map loading/orientation. A separate stopped check confirms the close crop and marker alignment/clipping; camera motion/edges remain **NOT RUN**. Execution evidence belongs in PROGRESS.

## Test Oval checkpoint sequence

`Track.gates` defines four ordered finite segments: North, West, South, then Start, following counterclockwise motion from the right-hand spawn facing north. The Start strip now runs horizontally across the right-hand road at `y=240`, from `x=570` to `770`; it is the fourth gate rather than an immediate spawn award. The other gates cross the road at its north, west and south extremities. Four pooled strips show pending, next and passed gates; a separate text HUD names the next target and the passed count.

`Track.crossesGate(previous, current, gate)` uses actual movement-segment intersection and a signed gate direction. It accepts only a strictly negative starting side followed by a nonnegative ending side, with the intersection within the finite gate segment. Starting on the line and departing, parallel or zero movement, backward crossing, nonfinite coordinates and crossings beyond an endpoint do not count. Reaching a gate line can count once; leaving it cannot award the same crossing again.

The separate pure `Checkpoints` module returns progress `{nextGate, passed, complete, lastTick}`. Each consecutive fixed step considers only its next expected gate and can award at most one. Duplicate, stale, out-of-order or gapped tick reports return the same progress unchanged; there is no automatic gap recovery. A consecutive sample with nonfinite positions or movement longer than five units consumes its current tick without an award, allowing the next valid consecutive step to recover. These local consistency guards are not anti-cheat or proof of an entire valid road route. Standalone checkpoint progress remains terminal at `4/4`; the Laps adapter handles repeated circuits.

## Practice lap timing

The pure `Laps` module wraps Checkpoints with immutable state containing `checkpoints`, `completedLaps`, `lapStartTick`, `currentLapTicks`, `lastLapTicks`, `bestLapTicks`, `bestLapNumber`, `lastTick` and `lastFinishTick`. Its first lap starts at the supplied origin tick; UI Race resets that origin to GO, including acceleration afterward. An accepted fourth gate increments `completedLaps` once, records `lastLapTicks = finishTick - lapStartTick`, sets the next lap start to that same finish tick and rearms North. The new lap begins at zero elapsed ticks with no lost or double-counted finish tick. Practice continues without a fixed lap limit. `bestLapTicks`/`bestLapNumber` stay nil until the first accepted completed lap. Only a strictly shorter completed duration replaces them; equal times keep the earliest lap number, and incomplete laps never become the best. New Laps state, including the GO reset, starts empty.

Duplicate, older or gapped reports leave all lap state unchanged. A consecutive rejected movement still consumes the tick and advances current lap time without an award; the next valid step can continue. All times stay integer ticks in simulation and become seconds only for display using the fixed 1/60-second step. They exclude dropped simulation time and stopped time; they are not independent wall-clock measurements. The standalone Laps module does not own countdown or saved personal records; these local checks do not establish a competitive route guarantee.

UI advances Race immediately after each physics step using its previous and current simulation positions, never interpolated display coordinates. Race wraps Laps, and `UI.checkpoints` aliases the active lap's checkpoint progress. The separate lap HUD shows completed count, current time, last completed time and `Best: --` or `Best: %.2fs (lap %d)`; running status and the result summary identify the three-lap target. Gate geometry and all HUD/summary objects are constructed once, with no per-tick texture creation or chat. Client driving/appearance remains **NOT RUN**.

## Three-lap solo result

The pure Race module starts a 180-tick countdown on a successful deliberate Start. At 60 Hz the cue shows 3 for remaining ticks 180–121, 2 for 120–61 and 1 for 60–1. On tick 180, GO resets the Race/Laps timing origin; actual held driving input first applies on tick 181. GO remains visible for racing ticks 0–59 and hides at tick 60. The kart remains at spawn throughout countdown, while input is sampled normally and physics receives neutral input. A dropped hitch tick does not skip countdown progress, so wall time may exceed three seconds. On the third accepted lap, it records `finishTick` and `totalTicks = finishTick - startTick` once. Terminal step/stop calls return the same result unchanged. The Laps core still rearms internally at each circuit, but Race accepts no fourth lap.

The fixed-step callback stops after counting the finish step; no remaining catch-up step can move the kart or advance time. Remaining whole ticks from that callback are reported as dropped time, with its fractional accumulator retained. The result uses simulation time at the exact finish tick, rather than the full render callback duration. An early finish within the normal budget does not count as a hitch.

UI releases capture, draws the exact finish pose and shows a pooled `RUN COMPLETE` summary with total/last-lap times, a third line for the current-run best completed lap and a Restart button. An early Stop shows actual partial progress as `RUN STOPPED`; combat records `GAME INTERRUPTED BY COMBAT` and closes the window. Normal close/reopen and rejected Start attempts retain the frozen result and its best completed lap. Stopped/interrupted summaries also show that best, even when the current lap is incomplete. The summary is 380×190; it reuses existing text and frame objects. A successful explicit Restart or fresh Start resets progress, begins a new countdown and hides the summary; a rejected Start retains it. Stopping, losing focus or combat during countdown cancels it with zero race elapsed time and no automatic resume. Physics/loop/probe ticks include countdown; race/lap time excludes those 180 ticks, dropped time and stopped time. The in-memory best resets on a successful fresh Start/Restart; it is not a personal record across runs. There is no remote placement, winner comparison or persistence. M0/M1/M3 acceptance remains open.

## Geometry responsibilities
- Track-local spawn positions, bounds, road/walls, surface grip, collision and recovery points.
- Checkpoint ordering must prevent reversed driving and teleport skipping; segment intersection tests must confirm correct gate direction.
- No automatic lap increment from polar-angle wrap alone in production.
- Track version and deterministic content hash must be transmitted to peers and recorded in ghost/replay metadata.
- Map supports normal and mirrored direction only if gate/spawn orientation defined.

## Content authoring
- Build a simple external Python asset/track validation pipeline producing precomposed track exports and read-only geometry tables; no external executable is needed by addon users. Editable PNG masters remain outside runtime under `docs/art/concepts/`.
- Lint spawn outside collision, gates out of order, isolated road islands, item pickup unreachable, wall intersection, max tiling and texture dimensions.
- Document copyright/ownership of every texture, icon, music/sound asset. Start from plain colored tiles where feasible.

## Initial track sequence
M0 `Test Oval` → M3 `Mirage Raceway` (dry, pre-flood Shimmering Flats) → M7 `Murloc Marsh` → M9 `Frost Gearway` and more based on performance metrics. Mirage replaces the planned Tinker Speedway name; no production-map acceptance is claimed.
