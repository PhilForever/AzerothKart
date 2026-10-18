# Technical architecture

## System boundaries

```
User input (WoW UI events)
        |
        v
 InputAdapter -> InputSample (bitmask per fixed tick)
        |                         |
        v                         v
 UIController/Scene        Pure Simulation (Physics/Track/Race/Items/PRNG)
        |                         |
        +<------ Immutable-ish render state / events
        |
 Renderer (pooled Texture/FontString objects, HUD and audio)

Optional multiplayer (behind measured gate):
 TransportAdapter -> ProtocolCodec -> Session/RaceAuthority -> state ingest
                               -> replay/anti-corruption checks
SavedVariables -> Schema/Migrations -> settings/personal-bests/ghosts
```

## Layering
- `Simulation`: math data only; pure-ish tick(state, input, track, parameters) -> new state/events. No game globals.
- `Track`: analytical/collision world, checkpoint gates, item/hazard spawn coordinates. Data-driven; explicit track version + checksum/hash for multiplayer and replays.
- `Race`: start countdown, running, finish, pause/abort, lap and checkpoint adjudication.
- `GameSession`: game mode, seed, participants, tick authority and reproducible event log.
- `Input`: front-end state sampling; clears stuck keys on focus loss/combat; keybind remapping requires API tests.
- `Renderer`: world-to-canvas transform; viewport/UI scale; textures from fixed pool; minimap optional.
- `Network`: transport rate budget, codec, protocol state machine, ACK/retry/recovery; not used by simulation tests.
- `Persistence`: schema v1 and migration; never serialize live per-frame state excessively.
- `Presentation`: scenes Lobby, Kart Garage, Track Select, Race, Pause, Results, Settings, Help.
- `Diagnostics`: opt-in perf/FPS statistics, protocol rate metrics, error logs, feature gates.

## API interaction restrictions
`UI` and `Transport` are the **only layers** that call WoW APIs. No math library calls UI setters. Do not call secure/protected APIs or rely on secret-value readback. No special treatment of combat information is needed.

## Simulation clock
- Fixed dt = 1/60s; `OnUpdate` adds elapsed; execute at most 5 catch-up iterations/frame, then bound accumulator and record dropped simulation time.
- The simulation input sample for each tick is derived from current key state, not collected as raw frames.
- Rendering interpolates previous/current state for smoothness; do not mutate physics through UI animation.
- Pause on focus loss/combat/reload; anti-cheat timestamps cannot rely solely on mutable system time.

## Multiplayer architecture decision gates
- First local solo gameplay, then `NetworkProbe`, then synchronous lobby/ready/countdown without live karts.
- If capacity acceptable: host-authoritative room/session with locally predicted self kart and other-kart interpolation, measured bounded update cadence and snapshots; no naïve per-frame replication. Host may cheat or leave; communicate limitations.
- If not: asynchronous shared ghost challenges and personal bests, maintaining original modular gameplay.
- No eventual-consistency conflict should invent a race winner; if result cannot be verified, label "unverified".

## Visual performance budget
- Pool all kart/player sprite objects and HUD elements. No `CreateFrame`/`CreateTexture` per physics tick. No chat prints during motion.
- Data tables per tick are bounded and reused if Lua GC spikes; profile first, optimize second.
- For production tracks prefer atlas tiles at power-of-two dimensions and limited draw calls. Use no ripped assets.

## Public module APIs (proposed)
- `Physics.new(config, startPose)` -> state
- `Physics.step(state, heldInputs, dt, track)` -> state, collision flags
- `Track.isDrivable(track, x, y)` -> boolean; `Track.crossesGate(oldPos,newPos,gate)` -> bool, direction
- `Race.step(raceState, simState, events)` -> raceState/events
- `Protocol.encode(event)`/`decode(text)` validated under 255 bytes
- `Transport.send(session,msg,target)` with queue budget
- `Replay.record(inputs,seed,trackHash)` and `Replay.play(...)`

## Source map
Current M0: `Track.lua` (analytical geometry), `Physics.lua` (version 2 steering probe), `Input.lua` (physical held keys and reused semantic samples), `Loop.lua` (fixed-step clock and drop counters), `UI.lua` (client adapter/presentation), `Core.lua` (bootstrap/events/minimal schema marker). Load order is identical in both TOCs. Pure modules optionally register into the explicit addon namespace passed by WoW and return their module for offline imports; they do not access `_G` or game APIs. Core alone exports `_G.AzerothKart` for manual diagnostics.

`Loop.advance(clock, elapsed, stepFn)` runs up to five 1/60s steps per render frame, drops only excess whole ticks and retains the fractional remainder. It records full frame elapsed and dropped seconds; `maxElapsed` is not addon CPU time. Tick input comes from `Input.sample(held, reusedOutput)`. UI sprites are created once; HUD text updates at a bounded cadence. There is no interpolation or production replay/PRNG yet. The offline seeded tape generator is test code, not a gameplay random mechanic.

`UI` owns explicit capture and stop transitions. Unknown keys, text focus, any mouse click, combat, hiding, world leave/logout and optional application-focus readback stop capture. Releasing on all clicks avoids assuming rectangle bounds identify an overlapping frame's focus. Missing required input APIs/global mouse event reject Start; optional focus API absence leaves Alt-Tab safety unresolved. Propagation restoration is deferred in combat. All of these semantics remain subject to F2 live acceptance, including whether `EnableKeyboard(false)` is legal and effective at combat onset. `Race` and multiplayer remain reserved responsibilities.
