# ADR 0022 — Floors and boost pads (for the Battlegrounds Cup)

Status: **Proposed** by Claude, 2026-10-27, for Codex's decision. Nothing is implemented. The owner asked for two-level driving from Codex before Warsong Gulch is built.

## Context

The owner started a new cup: "Battlegrounds Cup - let's try Warsong Gulch first. It's going to be groundbreaking if we can make it work. The challenge is the two tunnels, and possibly floors." His screenshots name the places every Warsong player knows: the tunnel and its hut, the ramp, the fence and graveyard above the tunnel, the lobby, the flag room, the connector, the roof, the banana and its tunnel exit, the Boots in the tunnel, the zerker and leaf huts, mid.

Every track so far is flat: one level of 2D collision under one painted picture. Warsong Gulch has two kinds of overlap that a flat track cannot hold:

1. **Each tunnel runs under the plateau in front of its base.** The fence and the graveyard stand on the ground above it.
2. **Each base has two floors.** The lobby and the flag room are below; the roof is above them. The connector joins them inside. Outside, the banana climbs from the tunnel exit, a side door of the tunnel, to the roof.

Asked, the owner chose:

- **a fixed loop**: in by each base's tunnel, round its flag, out by its ramp, three laps;
- **wait for floors**: "Ask Codex for two-level driving first, then build Warsong with the banana and roof drivable";
- the **guiding arrow** to the next checkpoint on Warsong only;
- the tunnels' **Boots as boost pads**, proposed to Codex.

[ADR 0015](0015-track-elevation.md) step 4 proposed layered bridges for city streets; it is not accepted. This ADR asks for the same idea for room-and-corridor tracks first, because Warsong needs it. See [the Warsong Gulch plan](../art/tracks/warsong-gulch.md).

## Proposal (Codex's decision)

### 1. Floors

- **Levels.** Every floor area of a track (a room, a corridor, a path) may carry `level`, a small integer (0 the lowest; absent means 0). Solids and walls belong to a level too. Areas on different levels may overlap; on one level everything behaves as today.
- **Ramps.** A ramp is an area joining two levels, with a low end and a high end. It is drivable from both. A kart that leaves a ramp through its high end is on the higher level, through its low end on the lower; a kart that stays on the ramp keeps its level. Warsong's ramps: the outdoor ramp up to each base, the connector inside it and the banana outside it.
- **The kart's level** is part of Physics' state: set by the spawn, changed only by ramps as above. It depends only on the previous state and the step's movement, so it stays deterministic.
- **Collision.** A kart meets only its own level's walls and solids; a ramp belongs to both of its levels. `isDrivable`, `surfaceAt` and `resolveMovement` take the kart's level as an optional last argument; flat tracks ignore it.
- **Gates** may carry `level` and are crossed only by a kart on that level. Checkpoint order and lap rules are unchanged.
- **Drop-downs (optional, later).** A one-way edge where a kart leaves a higher level and lands on the lower one, as players jump from a base's roof.
- **Validation.** A track's generator proves that its levels meet only at ramp ends, and that every gate and spawn lies on one level.
- **Multiplayer.** A friend's level decides whether their kart is drawn above or below a roof. LiveProtocol's state could carry it (a protocol version change), or a receiver could infer it from position and their last known level (ambiguous where levels overlap). Codex's call.

### 2. Rendering (Claude, once floors are accepted)

- A track with levels gets a ground picture (everything you see from the lowest level: tunnel interiors, lobbies, flag rooms) and **roof overlays** (the plateau over each tunnel, each base's roof), drawn over karts on a lower level and under karts on a higher one.
- An overlay fades to about a quarter while the player's kart is under it, so you see yourself in a tunnel or a lobby. A friend under a roof you are not under is hidden by it; their name tag stays.
- One pooled texture per overlay, created with the window; nothing per frame.

### 3. Boost pads

- **Data.** `track.pads = {{id, x, y, radius, level?, boostTicks}}`.
- **Rule.** When a kart's centre enters a pad's disc on the pad's level, Physics sets `boostTicks = max(boostTicks, pad.boostTicks)`. The pad re-arms for that kart when it leaves the disc: one boost per pass. Proposed strength: a tier-2 drift boost.
- **Rendering.** A glowing boots mark on each pad (Claude); the boost itself shows with the existing flames and trails.
- **Multiplayer.** No new field: the live state already carries `boosting`.
- **Warsong:** one pad at the Boots in each tunnel. The tunnel is narrow and dark, but it pays.

### 4. The guiding arrow (Claude, presentation only)

A course may set `guideArrow`: a small arrow by the player's kart points at the next gate's middle, from the race's copied checkpoint progress. Warsong only, at the owner's choice. No Codex change.

## Consequences

- Flat tracks, their scores and multiplayer are unchanged: levels default to 0 and the new arguments are optional.
- Physics gains a state field and level-aware collision: a Physics version and compatibility review. Warsong is a new course with its own score context.
- Ordered gates and three laps stay; gates only gain an optional level.
- Warsong waits for floors, at the owner's choice. Thunder Bluff's mesas, Undercity and ADR 0015's bridges could use the same floors later.

## Evidence and limits

A proposal only: no code, art or test changed, and nothing was run in the client.
