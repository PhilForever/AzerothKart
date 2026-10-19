# Racing physics, deterministic time and game feel

The current `Physics.lua` is a pure version-5 analytical oval-handling prototype. Production race, item and checkpoint state below remains planned.

## Implemented progressive keyboard steering

Physics stores signed `steering` in [-1,1]. At each fixed step, one held turn approaches full steering at 8 units/s: from center, full lock takes eight 60 Hz ticks (about 133 ms). Releasing both directions centers at 16 units/s, taking four ticks (about 67 ms) from full lock. A reversal first centers the old sign at that faster rate, then builds the new sign on following ticks; full lock to opposite full lock takes twelve ticks (200 ms). Holding both directions cancels steering immediately. These are simulation timings, not measured input-to-display latency or proven improvements in handling.

Yaw uses this progressive value with the existing speed/drift response; reverse motion still flips yaw. Wall contact clears steering; grass keeps it for recovery. Drift validity checks the raw turn intent, so releasing or opposing a turn cancels charge immediately despite residual centering. A new drift additionally requires the raw and progressive turn signs to agree. Input capture and W/A/S/D, arrows and Space bindings are unchanged; no steering preset or setting is exposed.

## Implemented surfaces and wall response

`Track.isDrivable` retains its road-only analytical annulus predicate. `Track.surfaceAt` separately classifies road, grass and wall; both the island and grass outside the oval are traversable inside the perimeter. On grass, forward/reverse targets are 70/30 units/s, with 360 units/s² of drag toward those bounds after normal acceleration/braking. Overspeed is reduced gradually. Grass entry clears drift, charge, boost and slip; returning to road restores normal handling.

The canvas perimeter constrains the kart's center to an 18-unit inset. `Track.constrainPosition` clamps the attempted endpoint on each axis, preserving movement tangent to a wall. Contact multiplies speed by 0.25 once for that simulation step, including a corner touching both axes; there is no bounce. The inset keeps the rotated 17×31 primitive inside the canvas. This is a bounded rectangular prototype, not swept collision against arbitrary production walls. Pure test tracks without the optional surface/constraint helpers retain the earlier predicate fallback.

Focused surface coverage accompanies the implementation; exact executed results are recorded in `PROGRESS.md`. Client handling and the new perimeter appearance are **NOT RUN**.

## Implemented local drift slice

At 60 fixed ticks per second, hold Space with exactly one turn direction and forward road speed at least 90 units/s to drift. Sustaining the same turn charges tier 1 at 54 ticks (0.9 s), tier 2 at 108 ticks (1.8 s); charge caps at tier 2. Release Space while that turn and speed remain valid to spend the charge. Tier 1 boosts for 30 steps (0.5 s), tier 2 for 48 (0.8 s), counting the release step. Boost adds 300 units/s² and raises the speed cap from 200 to 260; brake or leaving the road cancels it.

Losing steering, opposing turns, braking, slowing below the threshold or collision cancels a held drift without reward. Collision also clears active boost and slip. A cancelled turn cannot cash out its old charge. Drift increases yaw by 1.15 and moves signed slip toward ±0.40 radians at 1.8 rad/s; after release it recovers toward zero at 3 rad/s. Travel follows `heading - slipAngle`, separately from the kart's facing direction.

Implemented state is `x,y,heading,speed,tick,impacts,drifting,driftDirection,driftTicks,driftTier,boostTicks,slipAngle,surface,steering`. `surface` reports Wall on a contact step, otherwise the endpoint's road/grass classification. Compatibility version 5 distinguishes progressive steering from earlier replays. The focused drift test covers thresholds, cancellation, bounded boost and an identical 720-tick seeded tape at 30/60/144 render schedules. Exact executed checks belong in `PROGRESS.md`; human handling quality is **NOT RUN**.

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
