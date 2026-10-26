# Track pipeline and validation

## Developer-only Test Oval solid fixtures

As of2026-10-25, [the eight production courses](PRODUCTION_MAPS.md) are the only player-facing maps: eight solo courses and seven live-eligible lap circuits. Mirage is the actual default. Test Oval is retired from Courses, menu/default/fallback/start/score/network admission. The analytical Track module and the following fixture documentation remain for deterministic developer tests; production no longer creates its road/obstacle textures.

Test Oval is `id="test_oval"`, geometry version 2. Its ordered `obstacles` array contains bottom-left rectangles (270,400,32,24) and (490,60,32,24), painted as two pooled red primitives. The road/spawn/gates remain unchanged. Physical obstacle footprints classify as wall; movement sweeps against 18-unit expanded rectangles and the perimeter. Tangential movement is retained, and contact uses the existing wall response. Clearance is conservative and square; these fixtures do not establish arbitrary prop/polygon/vehicle collision support. Keep geometry read-only during a run. `constrainPosition` remains perimeter-only; Physics v7 prefers the optional `resolveMovement(previousX,previousY,targetX,targetY)` hook. See [physics details](PHYSICS.md#implemented-test-oval-solid-fixtures).

Mirage Raceway stays geometry version 1 and receives **no solid obstacles**. Its scenery is visual only. The two Oval markers are hidden there; existing camera/gates/physics behavior is retained.

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

The first production map is **Mirage Raceway**, set on the dry, pre-flood Shimmering Flats. Its selectable blockout now uses one original precomposed `Background.tga`; optional `Foreground.tga`, `Preview.tga`, vehicle sprites, interactive props and VFX follow later. Road, wall, gate, surface and spawn geometry stays explicit Lua data; no painted pixel determines collision. The stopped Track button switches maps only after a guarded texture load succeeds; failure preserves the current map/run/sample. A successful change resets those samples. Mirage is now the default after reload; there is no playable Oval fallback. A failed initial art load refuses Start until a valid production map loads. The owner's screenshot shows the opaque Mirage background and correct whole-map orientation. A separate stopped build-70450 check confirms the close UV crop and Start/West strip alignment/clipping. Camera motion/edges, transparent sprite alpha and production-sprite rotation checks are **NOT RUN**. See [the map brief](art/MIRAGE_RACEWAY.md), [asset pipeline](ASSETS.md) and [ADR 0008](adr/0008-mirage-raceway-art-direction.md).

The Test Oval simulation keeps `isDrivable` as the road-only annulus predicate, while `surfaceAt` separately reports road/grass/wall. The island and exterior grass inside the canvas are traversable with slowdown and drift/boost cancellation. A rectangular perimeter constrains the kart center to `wallInset=18`, independent of the road radii. `constrainPosition` clamps an attempted endpoint while retaining tangent motion; collision scrubs speed once per step even at corners. Four pooled gray perimeter strips identify that limit and are repositioned/scaled for the selected map. Including map selection/background, the meter, checkpoint indicators, lap HUD and result summary, current explicit UI counts are 9 frames/111 textures/13 font strings. Oval road geometry and spawn are unchanged. Client perimeter/checkpoint/finish appearance and off-road handling are **NOT RUN**; focused offline results are in `PROGRESS.md`.

Live build 70450 exposed horizontal seams and grass covering the road under mixed snapping states. The current renderer gives the grass explicit `BACKGROUND,-1` priority below the outer bands and disables sharpening/pixel snapping on the 96 bands only, once after geometry setup. Grass snapping and all geometry remain unchanged. A normal reload showed the complete road/island/marker/kart without seams at measured effective scale 0.72452831268311; read-only checks confirmed all 96 settings and grass priority. [Isolation and verified fix](evidence/2026-10-19-m0-road-layer.md). The supported-scale matrix and sustained performance remain pending.

Bands sample the ellipse at each row's midpoint. At the current dimensions their vertical boundary uncertainty is at most 3.40625 world units outside and 2.625 inside. This is a vertical raster approximation, not an exact vector edge or horizontal-error guarantee. Offline tests compare the actual mock rectangles with analytical road classification away from a 3.5-unit vertical boundary margin, including `(400,440)`, which the old tiles left unpainted despite being drivable. Client layout/scaling/performance acceptance is separate.

## Mirage geometry blockout v1

`MirageRaceway.new(crossesGate)` returns independent pure track data with an explicitly injected gate-crossing predicate. It is bundled after Track and selectable while stopped using its own geometry-derived background; the kart remains a placeholder primitive. The blockout defines a 1024×1024 world, a closed 16-vertex centerline and a road formed by the union of radius-56 capsules along its segments (112 units wide). This uses the authored polyline without spline smoothing. The perimeter clamps at an 18-unit inset; off-road rough salt uses the existing grass response. The closer camera leaves current Physics v6 and this geometry unchanged.

The north-facing spawn is (700,360). The four ordered gate centers/directions are North at (550,900), crossing toward −x; West at (410,520), toward −y; South at (540,140), toward +x; and Start at (700,360), toward +y. Gate geometry and crossing rules remain data, not painted pixels. This is a gameplay blockout rather than a surveyed reconstruction or completed route-validation guarantee.

Mirage play uses a north-up follow camera at scale 1.5 in the existing 800×480 canvas. It follows the interpolated kart pose with 60 world units of look-ahead along the heading, clamped to map bounds. The visible world rectangle is approximately 533.33×320 units. Cropped background UVs, sprite positions/dimensions and clipped gates/walls share the same transform. The 17×31 world-unit placeholder becomes 25.5×46.5 canvas units, and the road becomes 168 wide. The earlier whole-map fit made them about 8×14.5 and 52.5 respectively; it remains only the authoring overview through `Presentation.fitViewport/project/unproject`. Test Oval retains its fixed overview. No world dimension, wall inset, driving speed or checkpoint rule changes with camera scale.

Run `python scripts/build_mirage_layout.py` to load the actual factory plus Presentation through pinned Lupa and regenerate the [JSON geometry guide](art/mirage-layout.json) and [SVG layout](art/mirage-layout.svg). The guide draws the same closed, unsmoothed centerline with a 112-wide round stroke, annotates gates/spawn/walls, and inverts world Y exactly once for SVG. It is a whole-map authoring artifact; the separate runtime TGA is generated against the geometry without its labels/footer. The owner's screenshot confirms earlier whole-map loading/orientation. A separate stopped check confirms the close crop and marker alignment/clipping; camera motion/edges remain **NOT RUN**. Execution evidence belongs in PROGRESS.

## Capital Cities Cup: city street circuits (proposed, `claude/capital-cup`)

The owner's second cup races through Azeroth's capitals along their real streets, in Warcraft III art: Stormwind City Circuit, Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit. Stormwind, Ironforge, Orgrimmar, Darnassus and Undercity are built (Undercity's version 2 and the wall-to-wall paving are proposed on `claude/undercity-river`); Thunder Bluff is built too, proposed on `claude/thunder-bluff`. Each is a street circuit from `Circuit.new` (implemented contract in [API_CONTRACTS](API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog)): a smooth centerline traced on the in-game city map, a 112-wide capsule road and 20 units more to the kart centre's reach, then wall (the city); every city has full speed to its walls and is paved from wall to wall (the owner, 2026-10-23: no shoulders on a city map; Ironforge's change of handling is proposed for Codex review), plazas where the course crosses an open square, and solid boxes only inside the street. Data and pictures come from one generator, `scripts/build_city_tracks.py`, which validates the layout first (gates span the street wall to wall and guard one stretch; stretches keep a wall between them; spawn on the road; solids inside the street; nothing drawn over the street). The scenery is one 2048×2048 picture at one texel per world unit, so the follow camera shows the same scale as on Mirage Raceway; whether the client loads a texture this large is a pending client check. See [the Stormwind sheet](art/tracks/stormwind.md).

**Ironforge Grand Prix** (`ironforge_gp`, version 3): from the Gates up the Commons' ring, round the Mystic Ward, the Forlorn Cavern and the Hall of Explorers, through the Great Forge (round its southern forge), out past Tinker Town and through the Military Ward back to the Commons' finish. Clockwise; seven gates named for the districts; a 7,077-unit lap; no plazas or solids. Offline: the course walk passes the gates in order, completes the lap and never meets a wall (`tests/test_circuit.lua`). Reviewed version3 (Claude `9461f9c`, after the owner's version2 drive quoted in its handoff): tunnels with no shoulder in and out of the Forlorn Cavern (the wall at the paving's edge), dark iron walls round the lava without its ridges, and the Great Forge's floor between its forges cleared for the Great Anvil and pumps. The two tunnel segments limit the kart centre to 42 units either side, with no rough shoulder; outside them the existing 76-unit reach remains. V3 native handling/appearance/performance are NOT RUN. **Version 4** (proposed on `claude/undercity-river`, 2026-10-23, for Codex review): the owner asked for no shoulders on a city map, so the strip beyond the paving that version 3 kept rough has full grip (`fullSpeedToWalls=true`) and the paving runs from wall to wall; route, gates, spawn, narrows and walls are unchanged. See [the Ironforge sheet](art/tracks/ironforge.md).

**Orgrimmar Canyon Rush** (`orgrimmar_canyon`, version 1, `fullSpeedToWalls=true`; Codex-approved 2026-10-22 and integrated on `codex/live-multiplayer-integration`): the owner's blue loop round the Cleft of Shadow, counter-clockwise, after his first line's out-and-back canyon stretch proved unlappable: start on the canyon road behind a gate of the city wall, join the loop in the Valley of Strength, north up the Drag, west under the canyon's north wall past the Valley of Wisdom and Grommash Hold, down the Cleft's west rim and back. Four gates named for the districts; a 4,769-unit lap and a 734-unit approach; no plazas, solids or narrows. An open-air canyon city: the valleys are floor, the rest red rock with cliff faces, the Cleft a sunken chasm with Ragefire's lava fissure. Offline: the walk passes the gates in order and never meets a wall; throttle from the grid stays on the road (`tests/test_circuit.lua`). Native handling/appearance/performance are NOT RUN. See [the Orgrimmar sheet](art/tracks/orgrimmar.md).

**Darnassus Canopy Run** (`darnassus_canopy`, version 1, `fullSpeedToWalls=true`, proposed on `claude/darnassus-undercity`): the owner's red loop, counter-clockwise as his arrow points: start on the road in from the Warrior's Terrace, join the loop at the central terrace and turn north past the Craftsmen's Terrace, west along the upper tier, down past the Cenarion Enclave, south down the causeway by the Temple Gardens' lake, round the Temple of the Moon and up past the Tradesmen's Terrace. Six gates named for the districts; a 3,895-unit lap and a 206-unit approach; no plazas, solids or narrows. The city is painted on three terraces (the first painted elevation; the karts drive flat). Offline: the walk passes the gates in order and never meets a wall; throttle from the grid stays on the road. See [the Darnassus sheet](art/tracks/darnassus.md).

**Undercity Slime Circuit** (`undercity_slime`, version 2, `fullSpeedToWalls=true`, proposed on `claude/undercity-river`): the owner's revamp, "a river of slime with bridges at every section", the karts "crossing the bridges (sharp turns)". The slime is the canal ring round the Trade Quarter; from his arrow below the Apothecarium the course runs counter-clockwise along its outer and inner walkways and changes walkway on a bridge at every section (six: timber and stone by turns), each a sharp turn on, a straight across the slime and a sharp turn off: inside round the Rogues' Quarter's corner, outside up the Magic Quarter's side, inside under the Ruins of Lordaeron, outside down the War Quarter's side, inside round the Apothecarium's corner and out onto the start straight. Six gates named for the quarters (the finish is *The Canals*); a 5,797-unit lap; no approach road (the spawn is on the loop, 136 units past the finish line); no plazas, solids or narrows. The Trade Quarter is still painted 30 below the ring, and the stone bridges rise in painted humps (the karts drive flat). Version 1's loop down into the Trade Quarter is replaced. Offline: the walk from the loop passes the gates in order and never meets a wall. See [the Undercity sheet](art/tracks/undercity.md).

**Thunder Bluff Skyway** (`thunder_bluff_skyway`, version 2 on `claude/drive-fixes`, `fullSpeedToWalls=true`; version 1 is integrated and installed): the owner's blue line, clockwise, as his stroke runs. Start at the foot of the Lower Rise's west side, facing up it with the finish line ahead (version 1 started on the road in from the lift at his X, with a left turn at the junction that the camera did not show: the owner, after his client run, found it "pretty unexpected"), then up the west side, out over the west bridge and round the Spirit Rise, back over the north bridge, east along the north side, along the long bridge and round the Elder Rise, back over the lower bridge, down the east side, over the east bridge and across the Hunter Rise, back over the south-west bridge. Six gates named for the rises (the finish is *The Lift*); a 5,616-unit lap and a 285-unit approach from the lift (unused by the race since version 2); no plazas or solids. The six bridges are `narrows` (wall radius 54) over a painted drop to Mulgore's plain (the city's `chasm`); the course is on one level and the karts drive it flat. Offline: the walk passes the gates in order and never meets a wall; each bridge is road to its own wall. See [the Thunder Bluff sheet](art/tracks/thunder-bluff.md).

**Elevation** ([ADR 0015](adr/0015-track-elevation.md), proposed): the owner asked for elevation on the maps that need it and chose looks first, then slopes you can feel, then bridges over the track. Only the looks are built; the new cities' street heights are generated into `CapitalCities.lua` for the proposed physics.

Owner handling correction2026-10-22: Stormwind has full road grip and normal speed through both painted kerbside strips to the existing street walls. Drift/boost remain eligible there. The112-unit paving,76-unit wall radius, artwork/gates/spawn and wall impacts are unchanged. Other circuits default to rough shoulders; Mirage/Oval slowdown is unchanged. 2026-10-23: the owner wants no shoulders on any city map, so all five cities have full grip to their walls (Ironforge's is the one change of handling, proposed for Codex review) and are paved from wall to wall; `Circuit.new`'s default for other definitions is unchanged.

**Stormwind City Circuit** (`stormwind_city`, version 3, `fullSpeedToWalls=true`): start on the Valley of Heroes approach, through the gate into the Trade District, over the canal along Old Town, round the canal's head in the Dwarven District, along the foot of the Cathedral of Light's steps in Cathedral Square (the square and its fountain across the street), over the canal onto the Park bank, past the Mage Quarter and back over the canal to the Trade District's finish. Six gates named for the districts; three bridges between districts; no plazas or solids. Offline: the course walk passes the gates in order, completes the lap's checkpoints and never meets a wall; walls behave as specified (`tests/test_circuit.lua`). The owner confirms the reported Stormwind corner works (2026-10-22); wider camera, appearance and performance acceptance remains open.

## Scarlet Crusade Cup: dungeon sprints (proposed, `claude/scarlet-graveyard`)

The owner's third cup runs through the Scarlet Monastery's four wings, from the start of each dungeon to its end: Scarlet Graveyard, Scarlet Library, Scarlet Armory and Scarlet Cathedral (listed as "Scarlet Monastery" until it was built). He wrote that there is no need for "a traditional track here, just recreate the dungeon and let players find their way to the end."

Each is a **sprint**: one run from the entrance through its gates to the last, which is the finish ([ADR 0020](adr/0020-dungeon-sprints.md), proposed). The owner approved Claude adding the minimal rules for Codex's review:

- a course's `track.laps` sets the race's target, and every other course keeps three laps;
- a sprint keeps its own one-run boards.

The geometry is `Dungeon.new` ([contract](API_CONTRACTS.md#proposed-dungeon-sprints-the-scarlet-crusade-cup)):

- the floor is the dungeon's rooms, axis-aligned rectangles and round rooms, with no road to follow;
- stone has full grip, and lawns are rough ground;
- walls slide the kart along them, as on the city streets;
- graves, tombs and furniture are solid boxes, as on the test oval.

One generator, `scripts/build_dungeon_tracks.py`, writes the data (`ScarletCrusade.lua`) and the picture. It validates the layout first:

- the spawn stands on stone;
- every solid stands on the floor;
- the reviewed route crosses the gates in order without touching a wall or a solid;
- each gate spans its doorway from wall to wall, and a flood fill of the floor with that gate as a barrier proves it cannot be driven round (a solid may stand on a gate, as Herod does on the Armory's finish: the floor past the gate is checked all along it);
- wherever the karts' floor ends, a wall is painted beside it: no invisible wall (on `claude/drive-fixes`);
- nothing the karts drive over is left non-solid: a model that does not block keeps its drawn body off their floor (on `claude/drive-fixes`).

**Scarlet Graveyard** (`scarlet_graveyard`, version 2 on `claude/drive-fixes`; version 1 is integrated and installed): the owner's green route on his map of the wing, at karting scale.

1. From the instance portal in the entrance hall, the run turns north up the long hall.
2. It turns west through the east door of the Chamber of Atonement and passes its torture table.
3. It leaves by the west door, then goes down the stairs into the Forlorn Cloister.
4. It crosses the graveyard on the path round the ruined fountain, to Honor's Tomb.

- 2048 × 1024; 18 rooms (the cloister's lawn is rough); 59 solids.
- Three gates: *Chamber of Atonement*, *Forlorn Cloister* and *Honor's Tomb* (the finish).
- About 2,200 units from the portal to the finish line along the reviewed route.

Offline: the route walk crosses the gates in order and never meets a wall or a solid, and full throttle from the grid launches cleanly (`tests/test_dungeon.lua`). Version 2 answers the owner's client run: a wall either side of the chamber's west door, where the karts stopped at a wall the picture did not show, and nothing left on the floor for the karts to drive over (the ghost on the path is gone; the ghosts, the corpse and the benches on the floor block). See [the Scarlet Graveyard sheet](art/tracks/scarlet-graveyard.md).

**Scarlet Library** (`scarlet_library`, version 1, sprint; proposed on `claude/scarlet-library`): the owner's route on his map of the Library wing. "Everything is inside except the first courtyard with the fountain/statue in the middle", ending "in the iconic round library".

1. From the portal, north and east, then south down the long hall.
2. Round the Huntsman's Cloister, whose four roofed walks surround the open courtyard: a lawn, stone paths, the statue fountain, trees, huntsmen and hounds.
3. Into Houndmaster Loksey's kennel and back out: his gate spans the dead-end kennel, so the karts cross it inward, turn and leave.
4. North up the east hall into the Gallery of Treasures.
5. East through two columned halls, then south down the Athenaeum's bookshelves.
6. Through the last hall to Arcanist Doan's round library: a true circle, the first round room (`shape="disc"`).

- 2048 × 2048; 41 rooms (the courtyard's lawn is rough; the fountain's court and the round library are round); 65 solids (on `claude/drive-fixes`, where the bushes, cages, bones, hay and candles block and nothing else stands on the floor).
- Five gates: *Huntsman's Cloister*, *Houndmaster Loksey*, *Gallery of Treasures*, *Athenaeum* and *Arcanist Doan* (the finish).
- About 6,200 units from the portal to the finish line along the reviewed route.

Offline: the route walk crosses the five gates in order, crosses back over Loksey's line once on the way out (which counts nothing), and never meets a wall or a solid; full throttle from the grid launches cleanly. See [the Scarlet Library sheet](art/tracks/scarlet-library.md).

**Scarlet Armory** (`scarlet_armory`, version 1, sprint; proposed on `claude/scarlet-armory`): the wing's in-game map and battle map, at karting scale. "The Training grounds is the only outside you see on this map"; the final room is "the iconic round room with stairs leading down to herod". "Free driving through the whole map." The owner chose the finish down at Herod.

1. From the portal east along the entrance hall, north through the door into the Training Grounds.
2. Across the Training Grounds: four roofed walks round the one open yard (grass with stepping stones, archery targets, training dummies, the arcade's columns).
3. Up the stairs into the Footman's Armory, round its two great pillars, out by its east side room.
4. Up the stairs to the Crusader's side room and west through the Crusader's Armory.
5. Out of its north-west corner, north, then east along the long hall.
6. Into the round Hall of Champions, down its ring of stairs to the finish across its middle, either side of Herod.

- 2048 × 2048; 26 rooms (the yard is rough; the Hall of Champions is round); 38 solids.
- Five gates: *Training Grounds*, *Footman's Armory*, *Crusader's Armory*, *Hall of Champions* and *Herod* (the finish).
- About 4,200 units from the portal to the finish line along the reviewed route.

Offline: the route walk crosses the five gates in order and never meets a wall or a solid; full throttle from the grid launches cleanly; Herod blocks on the finish line. See [the Scarlet Armory sheet](art/tracks/scarlet-armory.md). On `claude/scarlet-cathedral` Herod takes a model of his own (Dagren the Orcslayer in crimson), since Renault Mograine stands at the Cathedral's altar.

**Scarlet Cathedral** (`scarlet_cathedral`, version 1, sprint; proposed on `claude/scarlet-cathedral`): the wing's in-game map and battle map, at karting scale. "Scarlet Cathedral next." The owner chose the finish at the altar and the gardens' pools as water the karts drive round.

1. From the portal west along the entrance hall, north through the garden gate into the Chapel Gardens, the open sky.
2. Round the lower garden's long pool, on the lawn or the walks.
3. Up the stairs either side of the falls, or across the platforms with the champions' statues, into the upper garden.
4. Round the round pool and its fountain, up the terrace's steps to the cathedral's door.
5. Up the nave between its pillars, across the transept, up the chancel's steps to the finish before the altar, where Mograine and Whitemane stand. Fairbanks' round chamber lies behind.

- 1024 × 2048; 24 rooms (the two lawns are rough; Fairbanks' chamber is round); 46 solids, the three pools among them. The round pool is the first round solid (`shape="disc"`, ADR 0020's fourth addendum).
- Four gates: *Chapel Gardens*, *Upper Gardens*, *Crusader's Chapel* and *High Altar* (the finish).
- About 2,500 units from the portal to the finish line along the reviewed route.

Offline: the route walk crosses the four gates in order and never meets a wall or a solid; full throttle from the grid launches cleanly; the pools block and a kart slides round the round pool's rim. With the Cathedral every course is ready; none is listed as coming soon. See [the Scarlet Cathedral sheet](art/tracks/scarlet-cathedral.md).

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
M0 `Test Oval` → M3 `Mirage Raceway` (dry, pre-flood Shimmering Flats) → M7 `Murloc Marsh` → M9 `Frost Gearway` and more based on performance metrics. Mirage replaces the planned Tinker Speedway name; no production-map acceptance is claimed. The owner's Capital Cities Cup (2026-10-21) comes first among the new maps: Stormwind, then Ironforge, Darnassus, Orgrimmar, Thunder Bluff and Undercity on the same pipeline. The Scarlet Crusade Cup's dungeon sprints follow (2026-10-25): the Graveyard, the Library, the Armory and the Cathedral.

Stormwind v3 wall alignment (2026-10-22): the white parapet is the exposed union of radius90 visual capsules. Collision now keeps14-unit centre clearance from that union, rather than separately shrinking every capsule to76 (which created invisible wedges at concave joins). Radius56 paving and normal straight-wall clearance are unchanged; generated exposed junctions/analytic projections provide the corner shape. Movement candidates obey the original step bound before nearest ranking. Artwork/gates/spawn and full-speed shoulders are unchanged.
