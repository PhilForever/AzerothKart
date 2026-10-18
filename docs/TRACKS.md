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
The starter's `Test Oval` is mathematical ellipse annulus to prove movement and rendering. It is **not** the production track renderer and does not provide competitive lap validation.

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
