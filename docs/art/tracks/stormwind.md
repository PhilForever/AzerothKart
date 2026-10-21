# Stormwind City Circuit (Capital Cities Cup)

The first of the six Capital Cities Cup tracks, by Claude (rendering/UI owner), 2026-10-21. The owner asked for city tracks "with wc3 assets where possible", where "it's important that players recognize where they are", and then refined the brief: "we're going for actual paths from the city", along his red line on the in-game Stormwind map.

![Stormwind overview, 4x reduced](stormwind_city-overview.png)

**Status:** built and checked offline. **NOT RUN in the client:** loading the 2048×2048 scenery (the first texture this large), the follow camera over it, the street walls and the fountain in a drive, the track screen's preview, the menu layout and performance. See [the client checklist](../../../tests/MANUAL_CLIENT_CHECKLIST.md).

## The route

The course follows the owner's line, counterclockwise, with the canals on the karts' left all lap and the districts on their right:

1. **Valley of Heroes.** The start grid is on the approach between the two lakes, below the heroes' statues; the main gate's towers stand where the approach enters the city.
2. **Trade District.** North up the main street, past the market stalls; the finish line is here.
3. **Over the canal into Old Town.** A bridge, then the north-east canal basin on the left (its island with four guard towers round a fountain) and Old Town's houses, SI:7 and the Pig and Whistle on the right. Gate: *Old Town*.
4. **Dwarven District.** Round the head of the canal, the forges on the right. Gate: *Dwarven District*.
5. **Cathedral Square.** The one open square on the course: the karts cross it past the fountain (solid), the Cathedral of Light to the north. Gate: *Cathedral Square* at the square's exit.
6. **The Park.** Over the second bridge onto the Park bank of the south-west basin, the Park's trees on the right. Gate: *The Park*.
7. **Mage Quarter.** Round the hairpin and east along the basin, the Mage Quarter's violet domes and the Wizard's Sanctum's spire on the right. Gate: *Mage Quarter*.
8. **Back to the Trade District** over the third bridge, through the gate junction, to the finish. Gate: *Trade District*, the finish line.

Lap: 3,766 world units; approach: 769. Six gates, named for the districts; the HUD names the next one ("Next gate: Old Town").

## How it plays

A street circuit. The road is 112 units wide (`roadRadius` 56, as on Mirage Raceway). Beyond it a 20-unit kerbside strip is rough ground (Physics' existing grass response: "Slowing off the road"), and at `wallRadius` 76 from the course's centerline the street ends: the canal parapets, district walls and houses drawn there are wall. The walls are smooth capsule edges, so a kart slides along a curving wall; each contact is a hit and Physics scrubs speed as at any wall. Cathedral Square is a paved plaza (a capsule of radius 140 along the course) with the fountain as its one solid box (71×68, with the usual 18-unit kart clearance); karts pass on either side. Nothing else is solid inside the street. Collision is Lua data in `CapitalCities.lua`; no pixel decides it.

The approach is a dead-end branch: the karts leave it on lap 1 and never return.

## Look

Everything is drawn into one picture from Warcraft III Reforged's classic (SD) art in the owner's install, at one texel per world unit, with the karts' camera lean (heights rise north, 0.6 per unit of height here). A model's body may not cover the street (its shadow may), so a kart is never drawn over a roof.

- **Ground:** Warcraft III terrain tiles on the game's own 32-unit corner grid and transition shapes. Each district has its tileset: Trade District square tiles, Old Town bricks, the Dwarven District's dark marble, Cathedral Square white marble, the Park grass, the Mage Quarter Dalaran's violet tiles, the canal islands cobbles.
- **Street:** cobbled road (Cityscape round tiles), kerbs striped Stormwind blue and white round corners, brick pavement on the kerbside strip, a gutter line, the walls' shadows, a chequered finish line; marble paving with two inlaid rings in Cathedral Square.
- **Walls:** a stone balustrade along both street edges, with taller pillars every 56 units.
- **Water:** the canal basins and the Valley's lakes, traced from the owner's map, plus canal bands that follow the course on the left; the Reforged water texture, tinted; stone rims; ashlar quay faces below every bank facing the camera, with the bank's shadow; bridges where the course crosses a canal, their faces pierced by arches.
- **Landmarks:** the Cathedral (scaled ×1.36, roofs recolored blue), the square's fountain, the Valley's knight and hero statues and the main gate's towers (blue banners), the guard towers on both canal islands, SI:7 (the barracks) and the Pig and Whistle, the Dwarven forges and braziers, the Wizard's Sanctum's spire and an arcane sanctum, Stormwind Keep (the castle) to the north-east, the Park's old trees.
- **Districts:** about 490 generated buildings and props (512 models placed in all), each district from its own palette, nearest the street first, turned to face it: the Lordaeron city houses with their green slate recolored Stormwind blue (and some red roofs in Old Town), market stalls in the Trade District, Dalaran buildings and violet roofs in the Mage Quarter, forges and workshops in the Dwarven District, trees in the Park; benches, flower beds, crates and carts in the strips the tall buildings must leave. Lamps and the kingdom's banners stand along the walls.

## Files

| File | What |
|---|---|
| `addon/AzerothKart/Assets/Tracks/Stormwind/Background.tga` | 2048×2048 opaque BGRA32, uncompressed, bottom-left origin; 16,777,234 bytes (16 MiB raw pixels: four times Mirage's). |
| `addon/AzerothKart/Assets/Tracks/Stormwind/Preview.tga` | 512×512 (the background reduced 4×) for the track screen; 1,048,594 bytes. |
| `addon/AzerothKart/CapitalCities.lua` | The circuit data, generated. |
| [`stormwind_city-overview.png`](stormwind_city-overview.png) | The preview as PNG, for review. |
| [`stormwind_city-sources.txt`](stormwind_city-sources.txt) | Every Warcraft III model and texture the picture uses, with placement counts. |

SHA-256 values are in [PROGRESS](../../PROGRESS.md) and the handoff for each build.

## Rebuilding

The Warcraft III files are not in this repository. Extract them from a Reforged install with the read-only reader, then build:

```
set W3="C:\Program Files (x86)\Warcraft III"
python scripts/wc3casc.py %W3% models "^war3\.w3mod:(doodads/(cityscape|dalaran|lordaeronsummer|terrain)|buildings/(human|other))/" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:terrainart/(cityscape|dalaran|lordaeronsummer)/" WC3
python scripts/wc3casc.py %W3% extract "^war3\.w3mod:replaceabletextures/(cliff|lordaerontree|water)/" WC3
python scripts/build_city_tracks.py --wc3 WC3 --preview      # writes the Lua data, pictures and previews
python scripts/build_city_tracks.py --wc3 WC3 --check        # verifies the committed bytes
```

`models` writes each matching model with the textures it names; [the sources list](stormwind_city-sources.txt) names exactly what the picture uses.

Standard library only (Python 3.10+). A full build renders about 300 model sprites and takes about five minutes; `CITY_SPRITE_CACHE=<folder>` keeps rendered sprites between runs (identical output). The layout is data in `scripts/city_layouts.py`: the route (traced map points), canal arcs and bridges, plazas, gates, districts and their palettes, landmarks. `build_city_tracks.py` validates it before painting: every gate spans the street wall to wall and guards one stretch; separate stretches keep a wall between them; the spawn is on the road; solids stand inside the street, clear of the paving unless on a plaza; the street stays inside the world; no landmark covers the street.

## Provenance and rights

Source: Blizzard Entertainment's Warcraft III: Reforged, build 3.0.1.24371, from the owner's own install (`C:\Program Files (x86)\Warcraft III`), read by `scripts/wc3casc.py` without modifying it. Used under [ADR 0009](../../adr/0009-warcraft-iii-asset-reuse.md) (Warcraft III art is an accepted project source by the owner's direction). Modifications: models posed and rendered as sprites with a fixed light, ground shadows and the karts' camera lean; some textures' hues moved (green and red slate to blue or violet), some districts tinted; terrain atlases halved to one texel per world unit and shaded; everything composited into one picture. Author: Blizzard Entertainment. **Redistribution rights are not established** and stay open for release review, as for every Warcraft III file in this project. The route was traced by hand on the owner's screenshot of the in-game map; the canal outlines with an offline tracing aid (low-saturation map texels), then simplified. The screenshot itself is not stored.
