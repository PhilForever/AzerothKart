# Racing physics, deterministic time and game feel

This describes desired production physics; initial `Physics.lua` is just an analytical oval-handling prototype.

## State and units
World units ~= UI logical pixels in the prototype. Production world units are independent of pixels, with camera transforming to screen. Coordinates: x right, y up; orientation radians counterclockwise. Kart state `x,y,heading,speed,steer,driftState,driftCharge,boostTicks,stunTicks,lap,checkpointIndex`, simulation tick as integer.

## Fixed-step control
`dt = 1/60`, bounded accumulator, no physics steps > fixed dt; optionally recompute from integer tick count for replay. `speed` in units/s, `steer` signed [-1,1], `throttle` 0/1, `brake` 0/1, discrete `useItem` event with sequence ID. Never use `GetTime()` in core physics.

## Base formulas (initial target)
- Longitudinal acceleration `dv = (throttle*a - friction(v) - brake*b)*dt` clamped into bounded reverse/top speed.
- Steering curvature `dHeading = steer * steerRate(speed,surface,drift) * dt`, with low-speed help and high-speed cornering limit.
- Drift: press at sufficient speed + sustained turn -> slip angle builds; charge thresholds (e.g. ~0.9/1.8s) award capped boost; release grants deterministic boost. Tunings are placeholders until tested.
- Terrain controls grip and speed retention; grass slows, walls reject penetration and scrub speed.
- Box/circle swept collision when speed causes tunneling; stepping should remain deterministic and allow rescue from invalid positions.

## Recommended tuning workflow
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
