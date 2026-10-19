# Racing physics, deterministic time and game feel

The current `Physics.lua` is a pure version-3 analytical oval-handling prototype. Production race, item and checkpoint state below remains planned.

## Implemented local drift slice

At 60 fixed ticks per second, hold Space with exactly one turn direction and forward speed at least 90 units/s to drift. Sustaining the same turn charges tier 1 at 54 ticks (0.9 s), tier 2 at 108 ticks (1.8 s); charge caps at tier 2. Release Space while that turn and speed remain valid to spend the charge. Tier 1 boosts for 30 steps (0.5 s), tier 2 for 48 (0.8 s), counting the release step. Boost adds 300 units/s² and raises the speed cap from 200 to 260; brake cancels it.

Losing steering, opposing turns, braking, slowing below the threshold or collision cancels a held drift without reward. Collision also clears active boost and slip. A cancelled turn cannot cash out its old charge. Drift increases yaw by 1.15 and moves signed slip toward ±0.40 radians at 1.8 rad/s; after release it recovers toward zero at 3 rad/s. Travel follows `heading - slipAngle`, separately from the kart's facing direction.

Implemented state is `x,y,heading,speed,tick,impacts,drifting,driftDirection,driftTicks,driftTier,boostTicks,slipAngle`. Compatibility version 3 prevents treating prior handling as the same replay contract. The focused drift test covers thresholds, cancellation, bounded boost and an identical 720-tick seeded tape at 30/60/144 render schedules. These are offline expectations; human handling quality is **NOT RUN**. Grass slowdown and a bounded outer-wall response are the next local build slice; the current oval boundary still rejects movement and scrubs speed.

## State and units
World units ~= UI logical pixels in the prototype. Production world units are independent of pixels, with camera transforming to screen. Coordinates: x right, y up; orientation radians counterclockwise. Kart state `x,y,heading,speed,steer,driftState,driftCharge,boostTicks,stunTicks,lap,checkpointIndex`, simulation tick as integer.

## Fixed-step control
`dt = 1/60`, bounded accumulator, no physics steps > fixed dt; optionally recompute from integer tick count for replay. `speed` in units/s, `steer` signed [-1,1], `throttle` 0/1, `brake` 0/1, discrete `useItem` event with sequence ID. Never use `GetTime()` in core physics.

## Base formulas (initial target)
- Longitudinal acceleration `dv = (throttle*a - friction(v) - brake*b)*dt` clamped into bounded reverse/top speed.
- Steering curvature `dHeading = steer * steerRate(speed,surface,drift) * dt`, with low-speed help and high-speed cornering limit.
- Drift: the implemented thresholds and boost durations above are initial tunings, pending direct play.
- Terrain controls grip and speed retention; grass slows, walls reject penetration and scrub speed.
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
