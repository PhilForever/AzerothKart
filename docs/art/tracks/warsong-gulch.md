# Warsong Gulch (Battlegrounds Cup)

The Battlegrounds Cup's first course and the first on **two floors**, built on Codex's [LayeredTrack](../../LAYERED_TRACKS.md) ([ADR 0022](../../adr/0022-floors-and-boost-pads.md)), by Claude (rendering/UI owner). **Version 2** (2026-10-28, `claude/warsong-v2`) lays it out on the real gulch, measured from the owner's own World of Warcraft client. Three laps from mid through both bases: at each, in by the tunnel, round the flag, out by the door.

![Warsong Gulch version 2 overview, 4x reduced, covers on](warsong_gulch-overview.png)

**Status: built on `claude/warsong-v2`, not installed.** Version 1 is registered and installed (Codex `9b7d6df`); version 2 replaces its geometry (trackVersion 2, so its scores start a new board) and its pictures. **NOT RUN in the client:** the look, the covers and their fades, the arrow, the gate glow, the drive, a two-player race.

## Why version 2

The owner drove version 1 and wrote: "it was an honorable attempt, you did good - but it's not really driveable - I mean you can drive, and try to follow the arrow, but it's not really intuitive unfortunately. I think you should inspect the actual warsong gulch in the game files or something to figure this out. Not only is the map difficult to navigate the way you've made it, the way you've made it is good - close - but not close enough unfortunately."

Asked what confused him, he named all four:

| What confused him | Version 2 |
|---|---|
| **The arrow pointed through walls** | The arrow follows the reviewed route, aiming at the farthest point up to 110 units along it that the kart can drive to in a straight line, so it bends round corners with the way (`Presentation.guideHeading`, `Courses.route`). |
| **He could not see under the roofs** | No roof stands over a base: both are drawn open, their floors in sight. The only covers are the ground over each tunnel, which start to fade 32 units before the tunnel's mouth. |
| **Too many rooms and doors** | Each base is one way through: tunnel, flag room, one way out. Two ramps instead of eight; no optional way in. |
| **Unclear checkpoints** | Seven gates at obvious places (each tunnel's mouth, each flag, each base's door, mid), each painted as a threshold with chevrons in its side's colours; the next one is drawn wide and pulses. |

And he kept the lap traced on the real gulch: **"Front, as traced"** (the Alliance out of its lobby by the front door and down the east path; the Horde out of its west side door, over the rise by the west tower and down to the field).

## How it was made

`scripts/wow_map_survey.py` measures the battleground (map `PVPZone03`) from the owner's client files, read without modification by `scripts/wowcasc.py` (`--product` picks the client's installed product): each ground texture's weight and the terrain's height every four units, and every doodad's and building's place, turn and size. The numbers are in `scripts/warsong_gulch_survey.json`; no client file is copied. The course's world is the battleground's own ground at three units to the yard (a placement at (px, pz) yards stands at X = (px − 15430) × 3, Y = (16182 − pz) × 3).

The lap was first walked on the client's own walkable surfaces (the terrain and the buildings' collision, 0.5-yard cells) from mid round both flags: about 1,500 yards. The rooms follow that walk and the walkable ground round it, widened for karts: a tunnel 12 yards wide in the game is 120 units here (40 yards). The huts, the tunnels' mouths, the bases, the paths and the scenery keep their places.

![The survey's ground and relief with the rooms, gates and lap](warsong_gulch-route-sketch.png)

*The tracing: the client's ground textures as flat colours and its relief (the paths are the light trails), with the version 2 rooms (floor 0 green, floor 1 violet, ramps amber), gates (red) and lap (white).*

## The course

![Silverwing Hold, its tunnel seen through the faded cover, the Lumber Mill, and the floor plan](warsong_gulch-review.png)

**One lap,** from the grid at mid:

1. **North up the middle of the field** to the Alliance tunnel's arch in the field's north cliff: gate *Alliance tunnel*, at the mouth.
2. **Up the tunnel,** under the hill and the plateau (its cover fades as the kart drives in). The Boots glow under the plateau. At the hold the tunnel climbs (the only ramp up) into Silverwing Hold, floor 1.
3. **Round the flag:** the tunnel's top opens into the flag room; the Alliance flag stands on its dais at the end of the wall between the tunnel and the lobby. Round it to the west: gate *Alliance flag*, from the flag to the north wall.
4. **South down the lobby** on its blue runner and out of the front door: gate *Alliance front door*.
5. **East across the plateau,** right over the tunnel the kart came in by, and **down the east path** (the second ramp) into the field's north-east corner.
6. **South down the field's east side,** west of the Alliance's east hut, to the Horde tunnel's mouth in the middle of the field's south wall: gate *Horde tunnel*.
7. **Down the Horde tunnel** under the hill (its cover fades) into the Warsong Lumber Mill, **round the Horde flag** at the end of the wall between the tunnel and the west passage: gate *Horde flag*, from the south wall to the flag.
8. **North up the west passage** on its red runner and **west out of the side door**: gate *Horde side door*.
9. **North up the slope** below the west tower into the field's south-west corner, then **north-east across the field,** east of the Horde's west hut, to the finish: gate *Mid*, a chequered band across the whole field.

| Measure | Value |
|---|---|
| World | 1024 × 2048 units (one texel per unit), the gulch at three units to the yard |
| Floors | 0: the field and its two corners, the Alliance tunnel, the Horde tunnel, flag room, west passage, side door and slope (9 rooms); 1: Silverwing Hold's tunnel top, flag room and lobby, its front yard and the plateau (5 rooms) |
| Ramps | 2: the Alliance tunnel's climb into the hold; the east path down off the plateau |
| Gates | 7: *Alliance tunnel*, *Alliance flag*, *Alliance front door* (floor 1), *Horde tunnel*, *Horde flag*, *Horde side door*, *Mid* (the finish) |
| Boots | 2, one in each tunnel: radius 14, 78 ticks of boost |
| Solids | 6 round: the two flags (radius 14, each capping its wall) and the four huts at the client's places |
| Covers | 2: the ground over each tunnel |
| A lap | about 4,700 units along the reviewed route |

## How it plays

`LayeredTrack.new` builds it from the generated `Battlegrounds.lua`; the rules are Codex's ([LAYERED_TRACKS](../../LAYERED_TRACKS.md)).

- **Two floors, only at Silverwing Hold.** The plateau the lap crosses stands over the Alliance tunnel: the tunnel climbs into the hold, and the east path comes down. The Lumber Mill's tunnel runs under the hill, which no kart drives on: one floor.
- **The flags.** Each flag is a round solid at the end of the wall between its base's way in and way out; nothing passes between the flag and the wall, and its gate runs from the flag to the far wall, so rounding the flag the lap's way takes it and nothing else does.
- **The Boots.** Driving into a pad on its floor gives a tier-2 boost once; leaving re-arms it.
- **Full grip everywhere,** Physics 13 (floors and pads), its own board (trackVersion 2). Collision comes from the generated data, never from a pixel.

## Rendering

All of it reads the simulation's copied state and writes none of it.

- **Two pictures, one world.** The painter makes the battleground from above (UPPER) and, under each cover, the tunnel beneath (LOWER). `Background.tga` is UPPER with LOWER under the covers; `Roofs.tga` is UPPER within the covers' footprints, clear elsewhere: cover and ground are one picture, so they always meet. The Alliance tunnel's arch is clear in `Roofs.tga`: a kart driving in is seen through it.
- **Two covers.** Each is one pooled texture (of four), cropped from `Roofs.tga` as the camera moves, drawn over the karts on the ground and under the karts on floor 1 or a ramp. It starts to fade 32 units before its tunnel and is down to a quarter 24 units in (`Presentation.roofAlpha`). A friend in a tunnel the player is not in is hidden by its cover. If `Roofs.tga` does not load the course is refused, as before.
- **The guiding arrow** follows the reviewed route (`Courses.route`: its points and, per gate, the point it drives to as it crosses that gate, `routeGates` in `Battlegrounds.lua`), looked for between the previous gate's crossing and the next's: on the plateau it points east along it, not through the hill at the Horde tunnel. It aims at the farthest point up to 110 units along the route that the kart could drive to in a straight line on its floor, so round a bend it points down the way first (after Codex's review: at the front yard's turn the point 110 on lay across the corner). From every step of the reviewed lap, a straight run along the arrow to its point meets no wall (`test_warsong`).
- **The next gate** (`UI.glowGate`): its marker is drawn ten units wide and pulses between 0.55 and 1 opacity (`Presentation.gateGlow`). No new texture: the gate markers are the existing pool. Budget unchanged: 91 frames, 96 textures, 151 font strings.

## Look

- **The ground is the gulch's own.** Every texel takes the Warcraft III tile standing for one of the client's eleven ground textures (Kalidar ferns as Ashenvale grass, its rock as Ashenvale rock, the roads as Lordaeron dirt and Barrens desert, the Barrens' dirt, grey grass and rock as theirs), picked by the measured weights against smooth noise, so each keeps its share with a ragged edge; the paths drawn bolder than measured. The measured relief shades it all.
- **Floors and edges.** Outdoor floors keep the ground; beside them a band of the side's rock, dark at the drop, the ground beyond darkening with distance; where the camera sees a floor's north edge, a cliff face in the side's strata. Each base's floors lie between thick walls (Silverwing Hold's violet stone, the Mill's timber), their north walls' faces in view.
- **Silverwing Hold:** pale square tiles, a blue runner down the lobby, the tunnel's climb with treads and kerbs, four Silvermoon towers (their teal and gold made violet and silver) at its corners, the Human banner (Alliance blue) on a stone dais ringed in blue.
- **The Warsong Lumber Mill:** plank floors, a red runner up the west passage, the orc war mill east of it, its watch towers, the Orc banner (Horde red) on its dais.
- **The tunnels:** dark dirt between timber frames every 48 units, timber-lined walls; the Alliance's arch in the cliff with blue lanterns either side, the Horde's timber lintel with braziers.
- **The client's scenery** where its map has it, as the Warcraft III model that stands for each kind: trees, bushes, stumps, logs, palisade stakes, lanterns and braziers (with their pools of light), catapults, barrels, crates, tents and watch towers; any that would stand on a floor in view, across a cover's edge or in a base's walls is left out. The client draws the woods on the Alliance's hills as one canopy: there, Ashenvale trees every 44 units; on the Horde's hills, dry bushes and rocks.
- **Marks on the floor:** the gates' thresholds (white and blue for the Alliance, red and black for the Horde, chevrons pointing the way), the flags' daises, the Boots, the chequered finish.

## Files

| File | What |
|---|---|
| `addon/AzerothKart/Battlegrounds.lua` | The course's data (generated): rooms with their floor, ramps, gates, Boots, spawn, solids, laps, the covers with the boxes below each, the reviewed route and `routeGates`. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Background.tga` | UPPER with LOWER under the covers: 1024×2048 BGRA32, opaque; 8,388,626 bytes. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Roofs.tga` | The covers: 1024×2048 BGRA32 with alpha; 8,388,626 bytes. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Preview.tga` | UPPER, reduced 4× (256×512), for the track screen; 524,306 bytes. |
| `addon/AzerothKart/Assets/UI/GuideArrow.tga` | The arrow's 16 headings (unchanged; original). |
| `scripts/warsong_gulch_survey.json` | The survey's numbers (ground weights, relief, placements). |
| [`warsong_gulch-overview.png`](warsong_gulch-overview.png) | The preview as PNG, for review. |
| [`warsong_gulch-sources.txt`](warsong_gulch-sources.txt) | Every Warcraft III model and texture the pictures use, with placement counts. |
| [`warsong_gulch-review.png`](warsong_gulch-review.png) | Silverwing Hold, its tunnel seen through the faded cover, the Lumber Mill, and the floor plan. |
| [`warsong_gulch-route-sketch.png`](warsong_gulch-route-sketch.png) | The tracing: the survey's ground and relief with the rooms, gates and lap; a design reference, not shipped. |

## Rebuilding

The survey (once, with the client; its output is checked in):

```
python scripts/wowcasc.py "%WOW%" extract WOW <FileDataIDs of world/maps/pvpzone03/*> --product wow_classic_beta
python scripts/wow_map_survey.py WOW community-listfile.csv scripts/warsong_gulch_survey.json
```

The pictures need these Warcraft III files, then build:

```
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:(buildings/(orc/(trollburrow|warmill|watchtower)|other/(furbolghut2?|tent|barrelsunit))/|units/orc/catapult/|doodads/(ashenvale/(plants/ashenbush0|props/(ashenhollowstump|ashenlogstraight))|barrens/rocks/barrens_rocks|lordaeronsummer/(props/(bannerhuman|bannerorc|brazier|lanternpost)|terrain/crates)|silvermoon/structures/silvermoontowerdoodadsmedium|terrain/(ashentree|barrenstree))/|_de\.w3mod:doodads/lordaeronsummer/structures/palisade/)" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:(terrainart/(ashenvale|barrens|ruins|cityscape|lordaeronsummer)/|replaceabletextures/(ashenvaletree|barrenstree)/|textures/)" WC3
python scripts/build_battlegrounds.py --wc3 WC3 --preview
python scripts/build_battlegrounds.py --wc3 WC3 --check
```

`--geometry-only` writes only `Battlegrounds.lua`; `--schematic OUT.png` (with Pillow) draws a floor plan.

- **`scripts/battleground_layouts.py`:** the layout (rooms, ramps, gates, flags, Boots, covers, route), the painting data (the client's ground textures as Warcraft III tiles, each side's styles, the tunnels' mouths) and the scenery: by hand (the huts, the banners, the towers, the war mill, the mouths' lamps) and from the survey (`_dressing`, `_woods`; optional, left out where it may not stand).
- **`scripts/build_battlegrounds.py`:** the geometry and its checks, then the Lua. `validate` checks LayeredTrack's authoring rules, the dungeons' rules on each floor (no invisible wall, rooms that do not meet stay apart, gates from wall to wall) and the ramp rule (a room meets a ramp only where its own floor leaves it), walks the route through the gates in order and records where it crosses each (`routeGates`).
- **`scripts/battleground_paint.py`:** UPPER and LOWER, then the outputs. It stops on a model that is not solid where the karts drive in view or across a cover's edge, unless it is optional scenery, which it leaves out.

## Provenance and rights

**Pictures:** Blizzard Entertainment's Warcraft III: Reforged, build 3.0.1.24371, from the owner's own install, read without modification by `scripts/wc3casc.py`, used under [ADR 0009](../../adr/0009-warcraft-iii-asset-reuse.md): [the sources list](warsong_gulch-sources.txt). Modifications: models posed and rendered as sprites with the project's light, shadows and lean (team colours; the Silvermoon towers recoloured violet and silver; the Barrens' bushes tinted dry); terrain atlases halved and shaded, picked and mixed by the generator; everything else painted by the generator (cliff and wall faces from the cliff textures, walls, parquets, runners, timber, arches, lintels, thresholds, daises, the Boots, the finish, lights) and composited.

**Layout and ground pattern:** measured from World of Warcraft's Warsong Gulch (Blizzard Entertainment) in the owner's own client, read without modification by `scripts/wowcasc.py`: numbers only (placements, heights, texture weights), no World of Warcraft file or picture is stored or shipped. This is a tracing of the battleground's layout, like the cities' from the owner's screenshots; it is recorded here for the release review.

**Author:** Blizzard Entertainment. **Redistribution rights are not established** and stay open for release review. The arrow is original, drawn by `battleground_paint.py`.
