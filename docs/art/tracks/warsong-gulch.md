# Warsong Gulch (Battlegrounds Cup)

The Battlegrounds Cup's first course, by Claude (rendering/UI owner), 2026-10-27, and the first course on **two floors**, built on Codex's [LayeredTrack](../../LAYERED_TRACKS.md) ([ADR 0022](../../adr/0022-floors-and-boost-pads.md)). Three laps from mid through both bases: at each, in by the tunnel, round the flag, out by the ramp.

![Warsong Gulch overview, 4x reduced, roofs drawn](warsong_gulch-overview.png)

**Status: built, listed as coming soon, not playable.** The Battlegrounds Cup lists "Warsong Gulch (soon)", disabled. Before it can be raced, Codex reviews the geometry and the route, assigns its course, invite and score IDs, and lets score sharing hold a Physics 13 board beside the Physics 12 ones ([LAYERED_TRACKS](../../LAYERED_TRACKS.md#remaining-warsong-integration)). Then the integrator removes `soon=true` from its `Courses.lua` entry; the menu's copy and preview are ready. Nothing is installed. **NOT RUN in the client:** the look, the roofs, the arrow, the drive.

## The owner's request

"Battlegrounds Cup - let's try Warsong Gulch first. It's going to be groundbreaking if we can make it work. The challenge is the two tunnels, and possibly floors. I'm not sure how the route/track should go or if it should be open. If open we would need clearer checkpoints and possibly a guiding arrow to the next checkpoint."

He sent the in-game world map with his callouts and eleven screenshots naming the places Warsong players use, for both bases:

- **The field:** mid, east, west, each side's zerker hut and leaf hut.
- **Outside each base:** the tunnel and its hut, the ramp, the fence and the graveyard on the plateau above the tunnel, the top of the tunnel.
- **Inside each base:** the lobby, the flag room, and the connector, a ramp from the lobby up.
- **Behind each base:** the tunnel exit, a side door of the tunnel; the banana, a path that climbs from it to the roof; the roof.
- **In each tunnel:** the banana entrance and the Boots.

## His decisions

| Question | His choice |
|---|---|
| The race | **A fixed loop, three laps:** at each base, in by the tunnel, round the flag, out by the ramp. Each lap runs both flags. |
| Floors | **Wait for floors:** Codex built two-floor driving first ([ADR 0022](../../adr/0022-floors-and-boost-pads.md)). |
| Guiding arrow | **On Warsong only:** a small arrow by the kart points at the next gate. |
| The Boots | **A boost pad in each tunnel.** |
| The flag rooms | **Two doors, drive through:** in by one door, past the flag, out by the other. |
| The banana and the roof | **An optional way in:** straight up the tunnel into the base, or out of the tunnel's side door, up the banana and in from the terrace above. |
| The start | **At mid**, both karts on one grid, facing the Alliance base. |

Not built: drop-downs from a roof or the plateau (the contract has none) and a start in each base (the contract's grid is shared).

## The course

![The bases with roofs whole and faded, and the floor plan](warsong_gulch-review.png)

*Silverwing Hold with its roofs whole (left, top), faded as for a kart below them (left, middle), the Warsong Lumber Mill (left, bottom), and the floor plan (right; north up): floor 0 green, floor 1 violet, ramps amber with a dot at the high end, gates red, the Boots blue, the reviewed lap white.*

The gulch at karting scale, twice as tall as it is wide. Silverwing Hold, the Alliance base, is at the north end; the Warsong Lumber Mill, the Horde's, at the south. The floors are point-symmetric: the Horde's half is the Alliance's turned half a circle, so the Alliance ramp is on the east and the Horde ramp on the west, and the two runs across the field pass mid on opposite sides. The pictures are not symmetric: the camera always looks north, and each half has its own art.

**One lap,** from the grid at mid:

1. **North up the field's west side** to the Alliance tunnel's mouth, between its braziers. Gate *Alliance tunnel*.
2. **Up the tunnel,** under the hill: the plateau is overhead and its picture fades while the kart is below. The Boots glow near the tunnel's end.
3. **Into the base:** the entry hall, then through the east door into the flag room.
4. **West across the flag room,** past the Alliance flag on its blue ring: gate *Alliance flag*. The flag stands solid at the room's north wall; the karts pass south of it.
5. **Out by the west door** into the front hall and **up the front ramp** onto the plateau (floor 1).
6. **East along the plateau,** over the tunnel, between the graveyard and the fence, and **down the ramp** at the hill's east end into the gully: gate *Alliance ramp*.
7. **South across the field's east side,** past mid, to the Horde tunnel, and the same through the Lumber Mill: gates *Horde tunnel*, *Horde flag* (the run crosses its flag room east), *Horde ramp*.
8. **North up the west side to mid:** the finish, gate *Mid*, a chequered band from the field's west wall to the hollow stumps.

**The optional way in,** at each base: from the tunnel, out of its side door (the tunnel exit, still under the hill) to the banana's foot, up the banana onto the terrace beside the base (floor 1), and down the connector into the entry hall. It skips the Boots. From the terrace a walk runs along the top of the flag room's roof; it leads nowhere, since no drop-down leaves it.

| Measure | Value |
|---|---|
| World | 1024 × 2048 units (one texel per unit) |
| Floors | 0, the ground: the field and, at each base, the tunnel, the tunnel exit, the banana's foot, the gully, the entry hall, the flag room, its two doors and the front hall (19 rooms); 1, above: each base's plateau, terrace and roof walk (6 rooms) |
| Ramps | 8, four a base: the ramp (gully up to the plateau), the front ramp (front hall up to the plateau), the connector (entry hall up to the terrace) and the banana (its foot up to the terrace) |
| Gates | 7, all on the ground: *Alliance tunnel*, *Alliance flag*, *Alliance ramp*, *Horde tunnel*, *Horde flag*, *Horde ramp*, *Mid* (the finish) |
| Boots | 2, one in each tunnel near the base: radius 14, 78 ticks of boost (a tier-2 drift boost's length) |
| Solids | 15: 13 round (mid's hollow stumps, the four huts, four rocks, four trees) and 2 boxes (the flags, where their banners are drawn) |
| Roof overlays | 4: each base's hill (over its tunnel) and its roof (over its halls and flag room) |
| A lap | about 5,700 units along the reviewed route |

A crude offline autopilot on Codex's Physics (it steers at the route's next point and nothing more) drove three laps in about 36 seconds each, scraping a few door corners. That is a measure of length, not of feel.

## How it plays

`LayeredTrack.new` builds it from the generated `Battlegrounds.lua`; the rules are Codex's ([LAYERED_TRACKS](../../LAYERED_TRACKS.md)).

- **Two floors.** A kart is on floor 0 or 1. It meets only its own floor's walls and solids, so the tunnel runs under the plateau and the flag room under the roof walk. The ramps are the only way between floors: a kart changes floor by leaving a ramp through its other end. A ramp's sides are walls on both floors.
- **The gates** count only on the ground: a kart on the roof walk over a flag room does not take the flag. They are passed in order, as on every lapped course; the guiding arrow shows the next.
- **The Boots.** Driving into a pad on its floor gives a tier-2 boost once; leaving re-arms it.
- **Full grip everywhere.** Every room is `road`; nothing slows the karts but walls and solids.
- **Physics 13.** Floors and pads make this course use Codex's feature version (`Physics.versionForTrack`); the other eleven stay on Physics 12 and their boards are untouched. Its board, invite code and score code are Codex's to assign.
- **Collision** comes from the generated data, never from a pixel.

## Rendering

All of it reads the simulation's copied state and writes none of it.

- **Two pictures.** `Background.tga` is the ground as floor 0 sees it: the field, the tunnels, the halls and the flag rooms, with the walls' faces and the ramps. `Roofs.tga` is the same size, world-aligned and transparent except for what stands above the ground: each base's hill (the plateau, its slopes and rocky rim, its graveyard and its fence or stakes) and its roof (the terrace and the roof walk, the parapets, the pitched roofs and the walls' tops, the towers and the war mill).
- **Four roof overlays.** Each is one pooled texture, cropped from `Roofs.tga` to its box as the camera moves, drawn over the karts on the ground and under the karts on floor 1. The upper floor is drawn only in `Roofs.tga`, so it is scenery like the ground: if it does not load, the course cannot be chosen ("roofs unavailable", the previous course stays) or started (since Codex's review of `bf94d2b`).
- **The kart's draw set.** On the ground the player's kart, its outline and its effects draw below the roofs; on floor 1 or anywhere on a ramp, above them, its dust and wind puffs included. The friend's kart follows its reported floor the same way. A friend below a roof the player is not under is hidden by it. On any other course every one of them, the friend's kart included, is back on its flat course's layer.
- **The fade.** A roof fades to a quarter while the player's kart is on the ground in one of the rooms below it, over its first 24 units in, and stands whole again outside. On floor 1 or a ramp the roofs never fade.
- **The guiding arrow** (`guideArrow`, Warsong only): a gold arrow with a dark rim, 46 units from the kart toward the middle of the lap's next gate, over everything. It hides on the grid, within 46 units of the gate and where it would leave the canvas. Sixteen headings in one small sheet, `Assets/UI/GuideArrow.tga`.
- **Cost:** five textures more, created with the window and hidden on every other course: four roofs and the arrow. Flat courses keep their draw layers. The menu's new cup heading and coming-soon button add a frame and a font string: 91 frames, 96 textures, 151 font strings.

## Look

Warcraft III's Ashenvale for the night elf north and the Barrens for the orc south, under the camera's usual lean.

- **The field:** Barrens dirt in the south half, Ashenvale grass and dirt in the north, worn lanes between the tunnels, mid's hollow stumps, two Ashenvale and two Barrens rocks and trees, and the huts: two furbolg huts (in Alliance blue) on the north half, two troll burrows (in Horde red) on the south.
- **The gulch's sides:** woods of Ashenvale trees along the north half's edges, Barrens trees along the south's.
- **The hills:** braziers either side of each tunnel's mouth, and an earth face across the Alliance hill's front over its mouth (the camera, leaning north, sees no face on the Horde's); on top, the ground's own terrain, rock on the slopes and a rocky rim where the hill drops. The Alliance's hill has a village fence along its south rim and a graveyard (graves, tombstones, a sentinel statue) along its north; the Horde's, palisade stakes and a graveyard of bones, graves and a tauren totem.
- **The tunnels:** dark dirt between timber frames every 64 units.
- **Silverwing Hold:** its front wall faces the camera in ruins masonry; a violet roof shingled facet by facet with pale ridges, a crenellated parapet, the terrace and the roof walk paved in large ruins bricks; two Silvermoon towers, their teal and gold made violet and silver; inside, a parquet of violet-brown planks and blue runners; the Human banner, in Alliance blue, as its flag.
- **The Warsong Lumber Mill:** Barrens cliff-stone walls, a roof of brown shingles, plank walks, two orc watchtowers and the war mill on the roof; inside, a parquet of broad brown planks and red runners; the Orc banner, in Horde red, as its flag.
- **Marks on the floor:** each flag's ring in its side's colours, the Boots as a glowing ring with a winged boot in its side's lamp colour (blue, orange), the chequered finish across mid.
- **Shadows** of the hills and the roofs over the ground, from the light the models' shadows use.

## Files

| File | What |
|---|---|
| `addon/AzerothKart/Battlegrounds.lua` | The course's data (generated): rooms with their floor, ramps, gates, Boots, spawn, solids, laps, the roof overlays with the boxes below each, and the reviewed route. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Background.tga` | The ground: 1024×2048 BGRA32, uncompressed, bottom-left origin, opaque; 8,388,626 bytes. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Roofs.tga` | The roof overlays' picture: 1024×2048 BGRA32 with alpha, same layout; 8,388,626 bytes. |
| `addon/AzerothKart/Assets/Tracks/WarsongGulch/Preview.tga` | 256×512, the ground with the roofs, reduced 4×; for the track screen once the course is selectable; 524,306 bytes. |
| `addon/AzerothKart/Assets/UI/GuideArrow.tga` | The arrow: 128×128 BGRA32 with alpha, 16 headings in a 4 × 4 grid of 32 × 32 cells; 65,554 bytes. Original. |
| [`warsong_gulch-overview.png`](warsong_gulch-overview.png) | The preview as PNG, for review. |
| [`warsong_gulch-sources.txt`](warsong_gulch-sources.txt) | Every Warcraft III model and texture the pictures use, with placement counts. |
| [`warsong_gulch-review.png`](warsong_gulch-review.png) | Both bases at full size, roofs whole and faded, and the floor plan. |
| [`warsong_gulch-route-sketch.png`](warsong_gulch-route-sketch.png) | The plan's sketch over the owner's world-map screenshot (six checkpoints, before the floors); a design reference, not shipped. |

## Rebuilding

Extract the files the course draws on, then build:

```
python scripts/wc3casc.py %W3% models "^war3\.w3mod:(buildings/(orc/(trollburrow|warmill|watchtower)|other/furbolghut2?)/[^/]+\.mdx|doodads/(ashenvale/(plants/ashenbush0|props/(ashenhollowstump|brazier|sentinelstatue)|rocks/ashenrock)|barrens/(props/(barrens_bones|taurentotem)|rocks/barrens_rocks)|lordaeronsummer/props/(bannerhuman|bannerorc|brazier|grave)|northrend/props/northrendtombstone|silvermoon/structures/silvermoontowerdoodadsmedium|terrain/(ashentree|barrenstree)|village/props/village_fencelong)/[^/]+\.mdx|_de\.w3mod:doodads/lordaeronsummer/structures/palisade/[^/]+\.mdx)$" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:(terrainart/(ashenvale|barrens|ruins)/|replaceabletextures/(ashenvaletree|barrenstree)/)" WC3
python scripts/build_battlegrounds.py --wc3 WC3 --preview
python scripts/build_battlegrounds.py --wc3 WC3 --check
```

`--geometry-only` writes only `Battlegrounds.lua`; `--schematic OUT.png` (with Pillow) draws a floor plan.

- **`scripts/battleground_layouts.py`:** the layout. The Alliance half is written out (rooms with their floor and what covers them, ramps, gates, the Boots, the reviewed route); `mirror` turns it half a circle for the Horde, flipping each ramp's climb and each gate's direction. The painting data are beside it: terrain, districts and lanes, each side's styles, and the props, ground and roof.
- **`scripts/build_battlegrounds.py`:** the geometry and its checks, then the Lua. Solids come from the props that block (`blocks`, as in the dungeons), the Mid gate's end from the stumps. `validate` checks LayeredTrack's authoring rules before `LayeredTrack.new` does at load, and the dungeons' rules on each floor: no invisible wall, rooms that do not meet stay apart, gates from wall to wall, the spawn and the Boots on the floor. It walks the reviewed route across the floors, through the gates in order, never meeting a wall. One rule is new; it is [proposed to Codex](../../API_CONTRACTS.md#two-floor-presentation-warsong-gulch): a room may meet a ramp only where its own floor leaves the ramp.
- **`scripts/battleground_paint.py`:** the pictures. It paints the ground (terrain, the hills' and walls' faces, the rooms' floors, the runners, the ramps with their treads and rails, the Boots, the flags' rings, the finish), then the roof picture (the hills' tops and rims, the walks and their parapets, the shingled roofs' hips, the walls' tops), the shadows, and the models over each. It stops on a model that is not solid where the karts drive, or a roof's model outside its overlay. The preview composites the roofs over the ground as the addon draws them. It also draws the arrow's sheet.

## Provenance and rights

**Source:** Blizzard Entertainment's Warcraft III: Reforged, build 3.0.1.24371, from the owner's own install, read without modification by `scripts/wc3casc.py`. The files are used under [ADR 0009](../../adr/0009-warcraft-iii-asset-reuse.md). The palisade stakes come from Reforged's `_de.w3mod` set; the rest are the classic models and textures: [the sources list](warsong_gulch-sources.txt).

**Modifications:**

- models posed and rendered as sprites with the project's light, shadows and lean: the huts and the banners in Alliance blue and Horde red; the Silvermoon towers' teal and gold recoloured violet and silver;
- terrain atlases halved and shaded;
- painted by the generator: the faces of the hills and walls from the cliff textures, the parquets, runners, plank walks, shingled roofs, parapets and wall tops, the tunnels' timber frames, the ramps' treads and rails, the Boots' marks, the flags' rings, the chequered finish and the shadows;
- everything composited into the two pictures.

**Author:** Blizzard Entertainment. **Redistribution rights are not established** and stay open for release review. The arrow is original, drawn by `battleground_paint.py`.

The layout follows the owner's world-map screenshot and his eleven screenshots of the bases, redrawn at karting scale. None of them is stored.
