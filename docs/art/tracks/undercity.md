# Undercity Slime Circuit (Capital Cities Cup)

The fifth Capital Cities Cup track, by Claude (rendering/UI owner), on the city pipeline ([Stormwind](stormwind.md), [Ironforge](ironforge.md), [Orgrimmar](orgrimmar.md), [Darnassus](darnassus.md)).

**Version 2 (2026-10-23)** is the owner's revamp. He sent a new in-game map with a red line round the outer ring (his arrow on the southern stretch, heading east) and two screenshots of the canals. He wrote: "Let's make it a circular map through the outer ring. It's basically a river of slime with bridges at every section", then "Players should be crossing the bridges (sharp turns) to cross the slimey river. See the other screenshots for reference." Version 2 replaces version 1, a long loop round the outer ring and down into the sunken Trade Quarter.

![Undercity overview, 4x reduced](undercity_slime-overview.png)

**Status:** proposed on `claude/undercity-river` for Codex review and integration. **NOT RUN in the client:** the drive, the turns at the bridges, the look in the follow camera and performance. See [the client checklist](../../../tests/MANUAL_CLIENT_CHECKLIST.md).

![The loop, its direction and nine follow-camera views](undercity_slime-review.png)

## The route

The slime is the canal ring round the Trade Quarter: 610 units from the city's centre, 120 wide. The course runs counter-clockwise along its walkways, either the outer one (778 from the centre) or the inner one (442). It changes walkway on a bridge at every section, where his red line crosses the ring:

1. **The start.** There is no approach road. The grid is on the outer walkway below the Apothecarium, where his arrow points, facing east. The finish line is 136 units behind it.
2. **The Rogues' Quarter.** In over the first bridge, round the quarter's corner inside the slime, and out over the second. Gate: *Rogues' Quarter*.
3. **The Magic Quarter.** North up the outer walkway. Gate: *Magic Quarter*.
4. **Under the Ruins of Lordaeron.** In over a bridge and west along the inner walkway. The slime lies between the course and the stair up to the ruins, where Sylvanas stands before the old throne. Out over the next bridge. Gate: *Ruins of Lordaeron*.
5. **The War Quarter.** South down the outer walkway. Gate: *War Quarter*.
6. **The Apothecarium.** In over a bridge, round the quarter's corner inside the slime, and out over the last bridge onto the start straight. Gates: *Apothecarium*, then *The Canals* (the finish line).

Every bridge is the same chicane:

- a sharp turn onto it: radius 70 on the centerline, a little over 90 degrees;
- a 197-unit straight across the slime at right angles;
- a sharp turn off it the other way.

The lap is 5,797 world units, with six gates.

## How it plays

It uses the shared street circuit:

- the kart centre reaches 76 units from the centerline (`wallRadius`);
- full grip all the way to the walls (`fullSpeedToWalls`);
- the exposed-wall clearance (`wallClearance` 14, 1,340 generated junctions).

The street is paved from wall to wall. Following the owner (2026-10-23), no city map has shoulders any more.

The track has no plazas, solids, narrows or branches. The spawn lies on the loop itself (`branches={}`), which `Circuit.new` already accepts. At each turn, the inner corner is the bridge's abutment: a sharp corner of wall. The whole width of the street is drivable, so the line through each chicane is up to the driver. Collision comes from analytic Lua data in `CapitalCities.lua`.

The stone bridges' humps are only painted: the karts drive over them flat. Slopes you can feel are [proposed](../../API_CONTRACTS.md#proposed-track-elevation-claude-2026-10-23-for-codex-review), not built.

## Look

This is the Forsaken's city under the Ruins of Lordaeron. It uses Warcraft III's Dalaran-ruins, Dungeon and Black Citadel tiles, with the Scourge's buildings made Forsaken:

- **The canal ring:** the Dungeon's lava texture made into a glowing green ooze between stone quays. The slime lights the stone round it.
- **The bridges:** timber and stone by turns, as in his screenshots.
  - Timber bridges have plank decks on piles standing in the slime, with a timber railing.
  - Stone bridges have dark violet-grey stone decks with crenellated parapets, on arches over the slime. Each rises in a painted hump 6 units high.
  - A lantern post stands at each bridge's open corners, its lantern lighting the stone yellow.
- **Floors:** each quarter has its own stone on both sides of the slime: grey bricks in the War Quarter (north-west), violet tiles in the Magic Quarter (north-east), dark marble in the Rogues' Quarter (south-east) and green-grey slabs in the Apothecarium (south-west).
- **The Trade Quarter:** a round hall of dark octagonal tiles, sunk 30 below the ring round it. Its wall's dressed stone shows round its north side and its brink is lit round the south. A slime well stands at its heart.
- **Street:** green-grey slabs from wall to wall, with a kerb at the foot of an iron railing that has a spike every 22 units. Braziers burn green along it.
- **Rock:** the round city's hall, one hall per quarter in the corners, and the stair up to the ruins are floor. The earth beyond them is rock.
- **Districts:** each quarter draws its buildings on both sides of the slime:
  - the Scourge's buildings, their red fires made the Forsaken's green (crypts, graveyards, temples of the damned, tombs of relics, slaughterhouses, boneyards, altars of darkness, gargoyle spires, ziggurats), plus Northrend crypts and goblin merchants;
  - graves and tombstones, iron maidens, torture tables, chain posts, cages, cauldrons, bookshelves, tables, crystal lamps, sewer vents, weapon racks and skulls;
  - acolytes, ghouls, necromancers, skeletons, skeletal mages, banshees and rats.
- **Landmarks:**
  - the slime well;
  - Sylvanas and two banshees before Lordaeron's throne, at the stair to the ruins across the slime;
  - a temple of the damned, a slaughterhouse, an altar of darkness and a graveyard, one in each quarter's hall;
  - an obsidian statue in the Rogues' Quarter.

## Files

| File | What |
|---|---|
| `addon/AzerothKart/Assets/Tracks/Undercity/Background.tga` | 2048×2048 opaque BGRA32, uncompressed, bottom-left origin; 16,777,234 bytes. |
| `addon/AzerothKart/Assets/Tracks/Undercity/Preview.tga` | 512×512 (the background reduced 4×) for the track screen; 1,048,594 bytes. |
| `addon/AzerothKart/CapitalCities.lua` | The circuit data (with the other cities'), generated, including its proposed `elevation` heights. |
| [`undercity_slime-overview.png`](undercity_slime-overview.png) | The preview as a PNG, for review. |
| [`undercity_slime-sources.txt`](undercity_slime-sources.txt) | Every Warcraft III model and texture the picture uses, with placement counts. |
| [`undercity_slime-review.png`](undercity_slime-review.png) | The loop with its direction and nine follow-camera views, as sent to the owner. |

## Rebuilding

Extract the earlier cities' files first, then Undercity's:

```
python scripts/wc3casc.py %W3% models "^war3\.w3mod:(buildings/undead/[^/]+/[^/]+\.mdx|units/undead/[^/]+/[^/]+\.mdx|units/critters/rat/rat\.mdx|doodads/dungeon/props/.*\.mdx|doodads/northrend/(props|structures)/.*\.mdx|doodads/cityscape/props/(throne|citygrave|crystallamp)/.*\.mdx|doodads/lordaeronsummer/props/(grave|cage|cauldronwithheads|skullpile|ribbones|weapons|armorrack|brazier|lanternpost)/.*\.mdx|buildings/other/(merchant|barrelsunit|boxunit)/[^/]+\.mdx)$" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:terrainart/(dungeon|dungeon2|dalaranruins|blackcitadel)/" WC3
python scripts/build_city_tracks.py --wc3 WC3 --preview --city undercity_slime
python scripts/build_city_tracks.py --wc3 WC3 --check
```

The layout is `UNDERCITY` in `scripts/city_layouts.py`. It holds:

- the ring and its bridges (`uc_course`);
- the start and the gates;
- the canal ring;
- the districts and their palettes;
- the floors and the landmarks;
- the `elevation`: the sunken Trade Quarter and the stone bridges' humps.

Version 2 adds these painter options, all optional per city:

- **A bridge's `deck`:** "planks" gives a timber deck, railing and piles; anything else gives stone.
- **A bridge's `force`:** false for a bridge over water drawn whole, so it carries no canal strip of its own.
- **A bridge's `posts`:** its own corner lamps.
- **City-wide:** `deck_planks` and `deck_stone` (the decks' colours), `pile_every`, and `deck_shadow`.

## Provenance and rights

**Source:** Blizzard Entertainment's Warcraft III: Reforged, build 3.0.1.24371, from the owner's own install. `scripts/wc3casc.py` reads it without modifying it. The art is used under [ADR 0009](../../adr/0009-warcraft-iii-asset-reuse.md). Author: Blizzard Entertainment.

**Modifications** are as for the earlier cities:

- models posed and rendered as sprites with the project's light, shadows and lean, in a Forsaken violet team colour;
- the Scourge buildings' red fires and the braziers' flames recoloured green, and the slime well's pool given a green team colour;
- terrain atlases halved, shaded and desaturated;
- the Dungeon's lava tinted into slime;
- walls, quays, railings, the bridges' decks, piles and arches, shadows and the humps painted by the generator;
- everything composited into one picture.

**Redistribution rights are not established** and stay open for release review.

**Layout:** the route follows the owner's red line round the outer ring of his in-game map and his two screenshots of the canals. The ring, the walkways and the bridges were laid out by hand round the map's canal. None of the screenshots is stored.
