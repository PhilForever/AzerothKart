# Art, sound, track tools, and license provenance

## Accepted direction and current status

The first production map is **Mirage Raceway**, depicting the dry, pre-flood Shimmering Flats. Vehicles should be recognizable Warcraft III-like fantasy machines and riders, rather than modern go-karts. [ADR 0008](adr/0008-mirage-raceway-art-direction.md) records the owner's direction; [the map brief](art/MIRAGE_RACEWAY.md) and [source ledger](art/ASSET_SOURCES.md) carry the working references.

Mirage now has one original geometry-derived blockout background at `addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga`, selected through the stopped Track button. The existing placeholder kart and pooled gates/walls remain separate. Test Oval stays the reload default and fallback; its 96 road bands are **Texture regions**, not 96 Frames, and are hidden while Mirage is selected. Total explicit UI allocations are 9 frames/111 textures/13 font strings. Painterly scenery, foreground/preview art and vehicle sprites remain planned. Actual client texture loading/orientation is **NOT RUN**; see [the short first-load probe](FEASIBILITY.md#mirage-blockout-first-load-probe).

## Precomposed track pipeline

1. Keep editable art and PNG masters under `docs/art/concepts/`, outside the installed addon. Retain source layers, attribution and export settings so the map can be revised without repainting runtime files.
2. Compose static terrain, the road, markings, buildings and fixed scenery into `Background.tga`. Use optional `Foreground.tga` only for deliberate occlusion above racers, and `Preview.tga` for track selection. Keep vehicles, interactive props and VFX separate and pooled. Start with one background and an optional foreground, without introducing a tiled-world framework.
3. Author against explicit map bounds and register road edges, walls, gates and spawns in separate Lua geometry. Painted pixels never supply collision or checkpoint decisions; simulation stays deterministic at fixed steps. Export a common coordinate origin, dimensions and transform with the art.
4. A square PNG master at 1024×1024 or 2048×2048 is a candidate authoring format. The current blockout export is an uncompressed 1024×1024 RGBA32 TGA: its raw pixel payload is 4 MiB per image, excluding headers, mipmaps and runtime overhead. This is not a verified client limit. Two such layers would carry 8 MiB of raw pixels before sprites and previews.
5. Preserve the authored aspect ratio with a uniform world-to-canvas transform. Mirage occupies a centered 480×480 area of the 800×480 canvas, using scale 0.46875 and offset (160,0) for positions and dimensions. Future viewport or camera changes must preserve this geometry registration.
6. Validate texture loading, alpha, dimensions, UV orientation and rotation in the actual installed client before promoting exports. Those checks are **NOT RUN**. Keep file paths/casing and an asset manifest explicit; claim performance only from measured results.

## Vehicle sprites

The planned eight archetypes preserve both tank variants: **Siege Tank**, **Steam Tank**, **Goblin Mortar Trike**, **Gyrocopter**, **Gryphon Rider**, **Gnome Drag Car**, **Goblin Drag Car**, and optional **Shredder**. They are a concept roster, not implemented selectable vehicles or established balance classes.

For a single sprite rotated by the UI, use a strict 90-degree overhead orthographic view, front facing north, with neutral steering and a consistent pivot/scale. A Warcraft III-like angled three-quarter view needs directional frames; rotating one angled billboard does not create a valid view from every heading. Test the chosen orientation/UV mapping rather than assuming it matches the current placeholder.

Aircraft initially use cosmetic hover and the same ground collision rules as other vehicles. Shadows are separate 2D sprites; no flight physics or altitude-dependent shortcuts are added. Keep drift sparks, exhaust, collisions and celebration VFX in bounded pools, with no per-tick widget creation.

## Provenance and sound

Record `asset path | author/source | license | permission | date | intended use` for every candidate and distributed asset. Archives and OpenRealm tools are research leads, not permission to redistribute the assets they expose. Verify each asset's permission before import or distribution; newly drawn fan art does not itself clear underlying IP. Do not copy game files, Mario Kart/CTR art or music into the addon.

Use owned or appropriately licensed audio for engines, pickups, checkpoints, drift charge, impacts and fanfare; honor mute and verify the supported audio API before integration. The source ledger records unresolved candidates without presenting them as rights-cleared assets. The blockout imports no archived models or game textures and does not establish production art or milestone acceptance.
