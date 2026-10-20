# Racing physics, deterministic time and game feel

The current `Physics.lua` is a pure version-7 local-handling prototype (v6 steering/drift tuning retained). The formulas and production state below remain targets beyond this implemented prototype.

## Implemented progressive keyboard steering

Physics stores signed `steering` in [-1,1]. At each fixed step, one held turn approaches full steering at 8 units/s: from center, full lock takes eight 60 Hz ticks (about 133 ms). Releasing both directions centers at 16 units/s, taking four ticks (about 67 ms) from full lock. A reversal first centers the old sign at that faster rate, then builds the new sign on following ticks; full lock to opposite full lock takes twelve ticks (200 ms). Holding both directions cancels steering immediately. These are simulation timings, not measured input-to-display latency or proven improvements in handling.

Yaw uses this progressive value with the existing speed/drift response; reverse motion still flips yaw. Wall contact clears steering; grass keeps it for recovery. A new drift requires the raw and progressive turn signs to agree. An existing held drift can pause its charge through a short correction while steering centers or changes sign; the grace rules below apply. Input capture and W/A/S/D, arrows and Space bindings are unchanged; no steering preset or setting is exposed.

## Implemented surfaces and wall response

`Track.isDrivable` retains its road-only analytical annulus predicate. `Track.surfaceAt` separately classifies road, grass and wall; both the island and grass outside the oval are traversable inside the perimeter. On grass, forward/reverse targets are 70/30 units/s, with 360 units/s² of drag toward those bounds after normal acceleration/braking. Overspeed is reduced gradually. Grass entry clears drift, charge, boost and slip; returning to road restores normal handling.

The canvas perimeter constrains the kart's center to an 18-unit inset. `Track.constrainPosition` clamps the attempted endpoint on each axis, preserving movement tangent to a wall. Contact multiplies speed by 0.25 once for that simulation step, including a corner touching both axes; there is no bounce. The inset keeps the rotated 17×31 primitive inside the canvas. Mirage retains this perimeter-only response. Test Oval additionally uses the swept solid-fixture resolver below; arbitrary production walls remain outside this slice. Pure test tracks without the optional surface/constraint helpers retain the earlier predicate fallback.

Focused surface coverage accompanies the implementation; exact executed results are recorded in `PROGRESS.md`. Client handling and the new perimeter appearance are **NOT RUN**.

## Implemented Test Oval solid fixtures

Test Oval v2 adds two physical 32×24 rectangles, at bottom-left (270,400) and (490,60). `resolveMovement(x,y,targetX,targetY)` sweeps the whole segment against the perimeter and rectangles expanded 18 units on every side. The conservative axis-aligned clearance encloses the rotated body; corners are square, not an exact rounded or oriented chassis. At most three contact iterations remove inward normal displacement and retain tangent motion. Exact face arrival and isolated corner grazing are free; pushing inward from contact reports a hit. Starting overlaps recover to the nearest face with stable left/right/bottom/top tie order, in at most four passes for the current disjoint fixtures. Overlapping future clusters need a separate recovery policy. The helper allocates no temporary tables.

Physics prefers this optional hook over `constrainPosition`; tracks without it keep their existing path. A solid impact uses the same once-per-step speed scrub, impact count and complete drift/grace/boost/slip/steering reset as the perimeter. Physics compatibility becomes v7; all fifteen state fields and handling constants remain unchanged. `isDrivable` is still the road mask, and only physical obstacle footprints override `surfaceAt`. Rendering reads the same rectangles for two pooled red markers; it never supplies collision geometry. Mirage gets no obstacle data or hook. Client feel is NOT RUN; executed offline results belong in PROGRESS.

## Implemented local drift slice

At 60 fixed ticks per second, hold Space with exactly one turn direction and forward road speed at least 90 units/s to begin drifting. Charging requires raw and progressive steering to agree. Tier 1 now takes 30 charging ticks (0.5 s), tier 2 takes 60 (1 s); charge caps at tier 2. Drift yaw uses 0.75 of normal steering yaw, reduced from 1.15, while ordinary steering remains unchanged. These changes target the owner's report that charging on Test Oval required leaving the intended turns and driving small circles; improved feel still needs direct play.

While Space stays held and road/speed conditions remain valid, a steering correction can retain the existing charge for up to 12 consecutive fixed ticks (0.2 s). Neutral steering, both turn directions or a reversal still centering the old sign pauses charging; these ticks add no charge and slip relaxes toward zero. Matching one raw turn to progressive steering resumes charging, resets the grace counter and can adopt the opposite direction without losing the accumulated tier. The thirteenth consecutive unqualified tick clears it. Grace requires an existing drift; it cannot start a drift from neutral or preserve charge indefinitely without valid turning.

Release Space while on the road at speed 90+ without braking to spend an existing tier, including during the correction grace. Tier 1 boosts for 30 steps (0.5 s), tier 2 for 48 (0.8 s), counting the release step. Boost adds 300 units/s² and raises the speed cap from 200 to 260; brake or leaving the road cancels it. Braking, low speed, rough ground or wall contact immediately clears drift and grace without reward; wall contact also clears active boost and slip. A cleared charge cannot be spent later. Active charging moves signed slip toward ±0.40 radians at 1.8 rad/s; release or correction recovers toward zero at 3 rad/s. Travel follows `heading - slipAngle`, separately from the kart's facing direction.

Implemented state is `x,y,heading,speed,tick,impacts,drifting,driftDirection,driftTicks,driftTier,driftGraceTicks,boostTicks,slipAngle,surface,steering`. `driftGraceTicks` is zero while charging and 1–12 during a retained correction. `surface` reports Wall on a contact step, otherwise the endpoint's road/grass classification. Version 6 introduced the drift handling and grace state; current compatibility v7 retains them and adds the swept movement hook. Focused checks target charge/grace boundaries, retained corrections and reversals, valid releases, immediate cancellation, unchanged normal steering, boost bounds and deterministic fixed-tick state. Exact executed checks belong in `PROGRESS.md`; latest client handling is **NOT RUN**.

## State and units
World units ~= UI logical pixels in the prototype. Production world units are independent of pixels, with camera transforming to screen. Coordinates: x right, y up; orientation radians counterclockwise. Kart state `x,y,heading,speed,steer,driftState,driftCharge,boostTicks,stunTicks,lap,checkpointIndex`, simulation tick as integer.

## Fixed-step control
`dt = 1/60`, bounded accumulator, no physics steps > fixed dt; optionally recompute from integer tick count for replay. `speed` in units/s, `steer` signed [-1,1], `throttle` 0/1, `brake` 0/1, discrete `useItem` event with sequence ID. Never use `GetTime()` in core physics.

## Base formulas (initial target)
- Longitudinal acceleration `dv = (throttle*a - friction(v) - brake*b)*dt` clamped into bounded reverse/top speed.
- Steering curvature `dHeading = steer * steerRate(speed,surface,drift) * dt`, with low-speed help and high-speed cornering limit.
- Drift: the implemented thresholds and boost durations above are initial tunings, pending direct play.
- Terrain controls grip and speed retention; grass slows, walls constrain penetration and scrub speed while preserving tangent movement.
- Box/circle swept collision when speed causes tunneling; stepping should remain deterministic and allow rescue from invalid positions.

## Deferred tuning workflow

Per [ADR 0007](adr/0007-build-first-development.md), do not run this full matrix on every slice. Use focused mechanics checks while building; schedule broader tuning at an integration checkpoint or for a concrete handling failure.
1. Straight-line 0–50%/100% accel test, full braking from max speed, 90-degree turn at 3 speeds.
2. Slalom at different speeds, impact against edge, recovery from grass, drift threshold and boost duration.
3. Repeated 2-minute race with keyboard focus changes; ensure no stuck steering.
4. Tune using measured lap times, time-in-grass, percent time above target speed, control reversals and subjective handling ratings.
5. Lock physics version and track hash before ghosts/network; version old ghost tapes and invalidate when handling parameters change.

## Replay & PRNG
- Deterministic seeded local PRNG for items/hazards; seed recorded per race (never use global `math.randomseed` in shared WoW Lua runtime).
- Store input deltas/runs rather than per-frame positions, but cap total data and validate decompressed size to avoid abuse.
- Replay determinism check: initial state + input tape -> expected per-checkpoint state and final tick. Floating point may diverge across platforms; mitigate with canonical fixed-point representation or periodic authoritative corrections if real multiplayer is viable.

## Safety
- Keep simulated speed/coordinates bounded.
- UI interpolation must not update collision geometry.
- Two frames rendered at 30 or 144 FPS must produce equivalent physics for equal input tick sequences.
