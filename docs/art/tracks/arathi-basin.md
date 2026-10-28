# Arathi Basin (Battlegrounds Cup)

The Battlegrounds Cup's second course, by Claude (rendering/UI owner): a **circuit** round the basin on its real roads, laid out on the battleground measured from the owner's own World of Warcraft client, as Warsong Gulch version 2 and 3 were. One floor, heavy slopes: three laps down into the Gold Mine's hollow and up past the Lumber Mill.

![Arathi Basin overview, 4x reduced](arathi_basin-overview.png)

**Status: built on `claude/arathi-basin`, listed as coming soon, not installed.** It needs Codex's course, invite and score IDs before it can be chosen (as Warsong did); its data, pictures, catalogue entry, menu copy and tests are ready for that. **NOT RUN in the client:** the look, the drive, the arrow, the bridges, the Stables' yard.

## What the owner asked

With Warsong version 3 looking right, the owner (2026-10-28): **"Okay. Looks alright. Let's take what we learned creating this map and make Arathi Basin. (No insides here but heavy slopes)"**, with a way round drawn on the battleground's world map: a loop round the basin from beside Defiler's Den. Shown it on the game's own map, he gave the way round: **"East > DOWN to Gold Mine > Up to the stables > UP to the Lumbermill and then down to the farm and around"**.

He left three questions open; this version takes the recommended answers, to be confirmed:

| Question | Taken |
|---|---|
| The Stables, where he drew two lines round the barn | **Both ways round the barn:** the yard is open, the barn solid in it; north of it by the road to Trollbane Hall, south of it across the yard by the river. |
| The slopes | **Drawn from the real heights now, felt later:** the relief shades the ground and every centerline point carries its height (`elevation`, inert, [ADR 0015](../../adr/0015-track-elevation.md)); karts feeling the grade needs Codex's physics ([proposal](../../API_CONTRACTS.md#proposed-arathi-basin-a-battlegrounds-cup-circuit-claude-2026-10-28-for-codex)). |
| The grass beside the road | **Full speed to the fences,** as on the cities. |

## How it was made

`scripts/wow_map_survey.py` measures the battleground (map `PVPZone04`) from the owner's client files, read without modification by `scripts/wowcasc.py`; it now takes the world's size and relief range and records the water. The numbers are in `scripts/arathi_basin_survey.json`: the six Arathi Highlands ground textures' weights and the terrain's height (−133 to +141 yards, 1.4-yard steps) every four units, the river's depth, and 3,065 placements; no client file is copied. The course's world is the basin at three units to the yard, as Warsong's: a placement at (px, pz) yards stands at X = (px − 15760) × 3, Y = (16450 − pz) × 3, over 2048 × 2048 units.

The client paints its roads with one texture (its "rubble"); traced from the survey, they make the course: the ring road round the river, its bridges and forks, the bases where they stand. The street follows them, widened for karts as the cities' streets are (a road 10 yards wide in the game is a street 180 units wide between its fences here, 60 yards).

![The survey's ground, roads, water and relief with the street, gates and lap](arathi_basin-route-sketch.png)

*The tracing: the client's ground textures as flat colours, its roads, water and relief (contours every 10 yards), with the street (its fences dark red), the barn, the gates (red) and the lap (white, counter-clockwise).*

## The course

![The Stables' yard, the Gold Mine, the east bridge, the Lumber Mill, and the lap's heights](arathi_basin-review.png)

**One lap,** from the grid on the east road just north of its junction with the farm road (the owner's X lies on the road from that junction to Defiler's Den; the grid stands on the lap itself, as Thunder Bluff's does since version 2, so the race starts straight up the road with no turn to find):

1. **North up the east road** and over **the east bridge** (narrow: its deck, and 84 units of road either side, are walled at 42 from the middle).
2. **Past the pond to the river road's fork**, then **down the Gold Mine's road** along the lake's west shore into the mine's hollow, 110 yards below the basin's datum: the lap's lowest ground. Through its yard past the mine's mouth: gate *Gold Mine*.
3. **Up the north road** to the Stables, 55 yards up: gate *Stables* at the yard's east edge.
4. **Round the barn either way:** by the road to Trollbane Hall north of it and down the west road, or across the yard south of it by the river. Both meet at **the west bridge** (narrow like the east one).
5. **Down the west road** to its fork, then **up the hill** on the Lumber Mill's road (60 yards up in under 200), along the cliff top past the mill: gate *Lumber Mill*.
6. **Down the cliff road** (70 yards in about 160) to the junction at the south bridge (the road over it to the Blacksmith stays fenced off), **sharp back east** along the farm road past the Farm: gate *Farm*.
7. **Round the corner north** onto the east road: the finish, *Defiler's Den*, just behind the grid.

| Measure | Value |
|---|---|
| World | 2048 × 2048 units (one texel per unit), the basin at three units to the yard |
| The street | road radius 56, the karts' reach 76 from the middle, the fences 14 beyond (Circuit's city street); full grip to the fences |
| A lap | 5,073 units of centerline (322 points), the route 162 points (every other) |
| Gates | 5: *Gold Mine*, *Stables*, *Lumber Mill*, *Farm*, *Defiler's Den* (the finish) |
| Narrows | 2, the bridges: the karts' reach 42 over each deck and 84 units of road either side |
| Plazas | 1: the Stables' yard (radius 96) |
| Solids | 1: the barn (106 × 57) |
| Fences' junctions | 1,032 (the walls' 14-unit clearance where capsules meet) |
| Heights | 0 (the Gold Mine's hollow) to 372 world units (124 yards, the Lumber Mill's hill); the grid at 191 |

## How it plays

`Circuit.new` builds it from the generated `Battlegrounds.lua` (`Courses` geometry `circuit`); the rules are Codex's and the cities': the kart's centre stays within its reach of the course or inside a plaza, everything else is wall; a solid box blocks with Track's swept collision.

- **Full grip** from fence to fence, the cities' rule (the owner's choice for city streets, taken here for the grass).
- **The bridges** are narrows: 84 units wide where the street is 152, and so is the road 84 units either side of each, so the road's full width never reaches the water beside a deck.
- **The Stables' yard** is open (a plaza) with the barn solid in it: the lap's route goes north of the barn on the road, the yard south of it is the other way.
- **The slopes are drawn, not felt:** Physics is flat (version 12, three laps). Every centerline point carries the ground's height under it (`elevation`), for the grade term proposed in ADR 0015.
- Collision comes from the generated data, never from a pixel.

## Rendering

All of it reads the simulation's copied state and writes none of it.

- **One picture:** `Background.tga` (no roofs: the basin has no insides), `Preview.tga` for the track screen.
- **The guiding arrow** follows the reviewed route (the loop from the grid round to it, `routeGates` where it crosses each gate), as on Warsong (`Courses.route` now serves a guided circuit too); the next gate's marker glows. At the grid it points up the east road as it bends toward the bridge.
- **Gate markers** are the existing pool (five of eight). Budget: one more frame for the coming-soon button in the track list (92 frames, 96 textures, 151 font strings), and the list's rows step 30 units instead of 32 so thirteen fit above the Back button.

## Look

- **The ground is the basin's own.** Every texel takes the Warcraft III tile standing for one of the client's six Arathi Highlands textures (Lordaeron's summer grass made the Highlands' olive, its dirt greyed, its rock pale grey for the boulders, its rough dirt for the roads, the village's crops for the Farm's fields), picked by the measured weights against smooth noise.
- **The slopes:** the measured relief, evened (three 3 × 3 passes of the 1.4-yard steps), lights the ground from the north-west, exaggerated 1.7 times; the hollows are a little darker and the hills brighter (18% at the survey's extremes), so the Gold Mine's hollow reads low and the Lumber Mill's hill high.
- **The water** by its measured depth (evened, so the client's cell edges do not show): pale at the bank, dark in the deep river, a slow swell of light over it.
- **The street:** a grey-brown dirt road down its middle (about 100 wide, ragged edges, two worn ruts), grass to the fences; the Stables' yard in the road's dirt; a timber rail fence (posts every 30 units) along every edge. **The bridges:** stone decks from bank to bank with parapets; the two the course does not cross (the roads to the Blacksmith) as narrow as the client's, their parapets too.
- **The bases,** as the Warcraft III buildings that stand for them, at the client's places: the Stables a Lordaeron barn (solid in its yard), the Gold Mine the gold mine, the Lumber Mill the human lumber mill, the Farm a farmhouse with Lordaeron's windmill and granary among its fields, the Blacksmith the human blacksmith, Trollbane Hall and Defiler's Den town halls (Alliance blue; Horde red and darkened). Each node's flag (a Lordaeron banner) beside the course.
- **The client's scenery** where its map has it, as the Warcraft III model that stands for each kind: trees, bushes (the Highlands' olive), stumps, hay carts, barrels, crates, wheelbarrows, graves, rocks, lanterns, and a human banner on its pole for each scarecrow; the field fences drawn along their own line as rail fences; anything that would stand on the street or in the water is left out.
- **The finish:** a chequered band across the street.

## Files

| File | What |
|---|---|
| `addon/AzerothKart/Battlegrounds.lua` | The course's data (generated, beside Warsong's): centerline, narrows, the yard, gates, spawn, the barn, the fences' junctions, the heights, the reviewed route and `routeGates`. |
| `addon/AzerothKart/Assets/Tracks/ArathiBasin/Background.tga` | The basin from above: 2048×2048 BGRA32, opaque; 16,777,234 bytes. |
| `addon/AzerothKart/Assets/Tracks/ArathiBasin/Preview.tga` | The same, reduced 4× (512×512), for the track screen; 1,048,594 bytes. |
| `scripts/arathi_basin_survey.json` | The survey's numbers (ground weights, relief, water, placements). |
| [`arathi_basin-overview.png`](arathi_basin-overview.png) | The preview as PNG, for review. |
| [`arathi_basin-sources.txt`](arathi_basin-sources.txt) | Every Warcraft III model and texture the picture uses, with placement counts. |
| [`arathi_basin-review.png`](arathi_basin-review.png) | The Stables' yard, the Gold Mine, the east bridge, the Lumber Mill, and the lap's heights. |
| [`arathi_basin-route-sketch.png`](arathi_basin-route-sketch.png) | The tracing from the survey's numbers; a design reference, not shipped. |

## Rebuilding

The survey (once, with the client; its output is checked in):

```
python scripts/wowcasc.py "%WOW%" extract WOW <FileDataIDs of world/maps/pvpzone04/*> --product wow_classic_beta
python scripts/wow_map_survey.py WOW community-listfile.csv scripts/arathi_basin_survey.json --map pvpzone04 --origin 15760 16450 --size 2048 2048 --relief -140 1.4
```

The picture needs these Warcraft III files, then build:

```
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:(buildings/(human/(blacksmith|farm|humanlumbermill|townhall)|other/(barrelsunit|goldmine))/|doodads/(ashenvale/(plants/ashenbush0|props/ashenhollowstump)|lordaeronsummer/(props/(bannerhuman|grave|haycart|lanternpost|wheelbarrel)|rocks/lords_rock|structures/(barn|granary|windmill)|terrain/crates)|terrain/lordaerontree)/)" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:(terrainart/(lordaeronsummer|village)/|replaceabletextures/(lordaerontree|splats)/|textures/)" WC3
python scripts/build_battlegrounds.py --wc3 WC3 --course arathi_basin --preview
python scripts/build_battlegrounds.py --wc3 WC3 --check
```

`--geometry-only` writes only `Battlegrounds.lua`; `--schematic OUT.png` (with Pillow) draws each course's plan, the course's id added to the name.

- **`scripts/battleground_layouts.py`:** the Arathi section: the loop's control points on the real roads (smoothed, straight across each bridge), the bridges' decks and approaches, the yard, the gates, the grid; the painting data (the ground's tiles, relief, water, street, fences, the bridges off the course); the scenery by hand (the bases, the Farm's windmill and granary, the flags) and from the survey (`_ab_dressing`; optional).
- **`scripts/build_battlegrounds.py`:** `circuit_geometry` (the cities' street, the narrows as `build_city_tracks.narrow_segments` names them, the junctions as `circuit_boundary` finds them, the heights from the survey (evened over 48 units, straight across each bridge), the route); `validate_circuit` (the cities' rules, `build_city_tracks.validate_geometry`, then the route through the gates in order, recording `routeGates`); the circuit's Lua.
- **`scripts/battleground_paint.py`:** `build_circuit`: the ground, the water, the street, the fences and parapets, the bridges off the course, the field fences, the finish, the scenery north to south. It stops on a building or flag that would stand on the street (a flag `nudge`s off it), and leaves out optional scenery that would.

## Provenance and rights

**Pictures:** Blizzard Entertainment's Warcraft III: Reforged, build 3.0.1.24371, from the owner's own install, read without modification by `scripts/wc3casc.py`, used under [ADR 0009](../../adr/0009-warcraft-iii-asset-reuse.md): [the sources list](arathi_basin-sources.txt). Modifications: models posed and rendered as sprites with the project's light, shadows and lean (team colours; Defiler's Den darkened; the bushes tinted olive); terrain atlases halved and shaded, picked and mixed by the generator; everything else painted by the generator (the water, the road, its ruts, fences, decks, parapets, the finish) and composited.

**Layout and ground pattern:** measured from World of Warcraft's Arathi Basin (Blizzard Entertainment) in the owner's own client, read without modification by `scripts/wowcasc.py`: numbers only (placements, heights, texture weights, water depths), no World of Warcraft file or picture is stored or shipped. A tracing of the battleground's layout, like Warsong Gulch's; recorded here for the release review.

**Author:** Blizzard Entertainment. **Redistribution rights are not established** and stay open for release review.
