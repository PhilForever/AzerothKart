# Racing physics, deterministic time and game feel

The current `Physics.lua` is a pure version-10 local-handling prototype (angle-aware wall response and parking-turn assistance; racing-speed drift tuning retained). The formulas and production state below remain targets beyond this implemented prototype.

## Implemented progressive keyboard steering

Physics stores signed `steering` in [-1,1]. At each fixed step, one held turn approaches full steering at 8 units/s: from center, full lock takes eight 60 Hz ticks (about 133 ms). Releasing both directions centers at 16 units/s, taking four ticks (about 67 ms) from full lock. A reversal first centers the old sign at that faster rate, then builds the new sign on following ticks; full lock to opposite full lock takes twelve ticks (200 ms). Holding both directions cancels steering immediately. These are simulation timings, not measured input-to-display latency or proven improvements in handling.

Yaw uses this progressive value with the existing speed/drift response; reverse motion still flips yaw. Version8 adds up to1.2rad/s of parking-turn assistance, fading linearly to zero at80units/s. Racing/drift speeds90+ keep their prior yaw formula. Wall and grass contact both retain steering for recovery; Start still resets it. A new drift requires the raw and progressive turn signs to agree. An existing held drift can pause its charge through a short correction while steering centers or changes sign; the grace rules below apply. Input capture and W/A/S/D, arrows and Space bindings are unchanged; no steering preset or setting is exposed.

## Implemented surfaces and wall response

`Track.isDrivable` retains its road-only analytical annulus predicate. `Track.surfaceAt` separately classifies road, grass and wall; both the island and grass outside the oval are traversable inside the perimeter. On grass, forward/reverse targets are 70/30 units/s, with 360 units/s² of drag toward those bounds after normal acceleration/braking. Overspeed is reduced gradually. Grass entry clears drift, charge, boost and slip; returning to road restores normal handling.

The canvas perimeter constrains the kart's center to an 18-unit inset. `Track.constrainPosition` clamps the attempted endpoint on each axis, preserving movement tangent to a wall. On first contact, speed is multiplied by the ratio of permitted to attempted travel, capped at1. Repeated contact uses40units/s² scrape drag instead of repeating that impact penalty. Fully blocked frontal/corner motion stops. There is no bounce or automatic heading alignment; held steering can turn away without reverse. The inset keeps the rotated 17×31 primitive inside the canvas. Mirage retains this perimeter-only response. Test Oval additionally uses the swept solid-fixture resolver below; arbitrary production walls remain outside this slice. Pure test tracks without the optional surface/constraint helpers retain the earlier predicate fallback.

Focused surface coverage accompanies the implementation; exact executed results are recorded in `PROGRESS.md`. Client handling and the new perimeter appearance are **NOT RUN**.

## Implemented Test Oval solid fixtures

Test Oval v2 adds two physical 32×24 rectangles, at bottom-left (270,400) and (490,60). `resolveMovement(x,y,targetX,targetY)` sweeps the whole segment against the perimeter and rectangles expanded 18 units on every side. The conservative axis-aligned clearance encloses the rotated body; corners are square, not an exact rounded or oriented chassis. At most three contact iterations remove inward normal displacement and retain tangent motion. Exact face arrival and isolated corner grazing are free; pushing inward from contact reports a hit. Starting overlaps recover to the nearest face with stable left/right/bottom/top tie order, in at most four passes for the current disjoint fixtures. Overlapping future clusters need a separate recovery policy. The helper allocates no temporary tables.

Physics prefers this optional hook over `constrainPosition`; tracks without it keep their existing path. A solid impact uses the same angle-aware first-contact response, continuous scrape drag, impact count and drift/grace/boost/slip cancellation as the perimeter. Steering remains available. Physics compatibility is8; all fifteen state fields and collision helper signatures remain unchanged. Collision severity uses admitted movement rather than a new normal/velocity stream. `isDrivable` is still the road mask, and only physical obstacle footprints override `surfaceAt`. Rendering reads the same rectangles for two pooled red markers; it never supplies collision geometry. Mirage gets no obstacle data or hook. Client feel is NOT RUN; executed offline results belong in PROGRESS.

## Implemented local drift slice

At 60 fixed ticks per second, hold Space with exactly one turn direction and forward road speed at least 90 units/s to begin drifting. Charging requires raw and progressive steering to agree. Tier 1 now takes 30 charging ticks (0.5 s), tier 2 takes 60 (1 s); charge caps at tier 2. Drift yaw uses 0.75 of normal steering yaw, reduced from 1.15, while ordinary steering remains unchanged. These changes target the owner's report that charging on Test Oval required leaving the intended turns and driving small circles; improved feel still needs direct play.

While Space stays held and road/speed conditions remain valid, a steering correction can retain the existing charge for up to 12 consecutive fixed ticks (0.2 s). Neutral steering, both turn directions or a reversal still centering the old sign pauses charging; these ticks add no charge and slip relaxes toward zero. Matching one raw turn to progressive steering resumes charging, resets the grace counter and can adopt the opposite direction without losing the accumulated tier. The thirteenth consecutive unqualified tick clears it. Grace requires an existing drift; it cannot start a drift from neutral or preserve charge indefinitely without valid turning.

Release Space while on the road at speed 90+ without braking to spend an existing tier, including during the correction grace. Tier 1 boosts for 30 steps (0.5 s), tier 2 for 48 (0.8 s), counting the release step. Boost adds 300 units/s² and raises the speed cap from 200 to 260; brake or leaving the road cancels it. Braking, low speed, rough ground or wall contact immediately clears drift and grace without reward; wall contact also clears active boost and slip. A cleared charge cannot be spent later. Active charging moves signed slip toward ±0.40 radians at 1.8 rad/s; release or correction recovers toward zero at 3 rad/s. Travel follows `heading - slipAngle`, separately from the kart's facing direction.

Implemented state is `x,y,heading,speed,tick,impacts,drifting,driftDirection,driftTicks,driftTier,driftGraceTicks,boostTicks,slipAngle,surface,steering`. `driftGraceTicks` is zero while charging and 1–12 during a retained correction. `surface` reports Wall on a contact step, otherwise the endpoint's road/grass classification. Version 6 introduced the drift handling and grace state; current compatibility v9 retains their high-speed tuning and v7’s swept hook while changing wall response and low-speed yaw. Focused checks target charge/grace boundaries, retained corrections and reversals, valid releases, immediate cancellation, unchanged normal steering, boost bounds and deterministic fixed-tick state. Exact executed checks belong in `PROGRESS.md`; latest client handling is **NOT RUN**.

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

Stormwind surface policy (2026-10-22): track version2 opts into Circuit.fullSpeedToWalls. Its whole street to the physical walls reports road, retaining normal speed and drift/boost eligibility; painted kerbs do not slow the kart. Physics compatibility remains7 and its wall-impact response is unchanged. Mirage/Oval and default Circuit shoulders still use the existing rough slowdown.

## Wall handling v8 — measured offline, native feel pending

The old repeated0.25speed/steeringzero response made even a glancing brush
collapse toward rest. Version8 keeps geometry authoritative and changes only
Physics response. Prior state.surface==wall identifies persistent contact; the
first free tick returns actualroad/grass and rearms initial impact treatment.
Zero permitted movement stops; invalid-pose recovery never awards speed because
the ratio is capped. Contact still clears drift/grace/boost/slip, including
release acceleration, and impacts still counts contactticks. Scalar speed is
requested longitudinal speed: actual tangent travel can be smaller while
pushing a wall. Remote forecasts remain estimates and can overpredict there.

Actual Lua5.1 before/after tapes: a45degree city-style slide over30ticks moves
4.306→60.744units and ends at0.861→197.005speed with held throttle; a frontal
crate contact with throttle+left turns6.12→88.76degrees in60ticks and now
releases at53ticks without reverse. Stationary left turns39.44→104.45degrees
in60ticks, with zero translation. These are simulation metrics, not direct
play/FPS/latency or a promise about every wall angle. tests/test_wall_slide.lua
protects frontal/corner blocking, glancing motion, mirrors/reverse/coasting,
actualsolid/perimeter/Stormwindwall, escape, racingyaw and deterministic tapes.

Both multiplayer peers must usePhysics8; incompatible7offers close beforegrid
orGO. No wirelayout/rate, wallgeometry, chassis, checkpoint or art change is
part of this Physics slice. Native usability remains NOT RUN.

## Light wall penalty v9 — native tuning pending

The owner found v8 nearly penalty-free. First contact now retains95% of the
previous angle-adjusted speed. Sustained contact caps speed at95% of the normal
maximum (190forward/52.25reverse);40units/s² scrape drag remains. This avoids
per-tick percentage decay and preserves active steering/recovery. Free driving
immediately uses normal caps. Native feel remains NOT RUN. Focused Lua5.1
checks retain53-tick frontal recovery and104.45degree stationary turning; the
30-tick45degree wall tape moves58.327units and ends at189.934speed. Physics9
compatibility prevents peers using older handling from starting together.

## Requested wall penalty v10

Owner found the5%/95% v9 tuning too mild. Initial wall retention is now90%
(`WALL_SPEED_RETAIN`); a separate80% cap (`WALL_SPEED_CAP`) applies on all
contact:160forward/44reverse. At normal top speed this cap also limits the
first impact; below it the initial10% loss can be measured independently.
The loss is not multiplied every tick. Drag40units/s², active steering,
53-tick recovery and parking yaw are unchanged; leaving contact removes the
cap immediately. Focused Lua5.1 tape:160speed/54.438travel after30ticks of
45degree contact. Physics10 rejects earlier handling versions. Native feel
is pending; v9's user-reported weak penalty is feedback, not live telemetry.
