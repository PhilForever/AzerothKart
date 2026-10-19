# Art, sound, track tools, and license provenance

## Accepted direction and current status

The first production map is **Mirage Raceway**, depicting the dry, pre-flood Shimmering Flats. Vehicles should be recognizable Warcraft III-like fantasy machines and riders, rather than modern go-karts. [ADR 0008](adr/0008-mirage-raceway-art-direction.md) records the owner's direction; [the map brief](art/MIRAGE_RACEWAY.md) and [source ledger](art/ASSET_SOURCES.md) carry the working references.

This is an authoring plan. The installed Test Oval still uses placeholder primitives with 8 frames/110 textures/13 font strings. Its 96 road bands are **Texture regions**, not 96 Frames. The precomposed renderer is not implemented, and no runtime TGA has been imported or client-verified in this slice.

## Precomposed track pipeline

1. Keep editable art and PNG masters under `docs/art/concepts/`, outside the installed addon. Retain source layers, attribution and export settings so the map can be revised without repainting runtime files.
2. Compose static terrain, the road, markings, buildings and fixed scenery into `Background.tga`. Use optional `Foreground.tga` only for deliberate occlusion above racers, and `Preview.tga` for track selection. Keep vehicles, interactive props and VFX separate and pooled. Start with one background and an optional foreground, without introducing a tiled-world framework.
3. Author against explicit map bounds and register road edges, walls, gates and spawns in separate Lua geometry. Painted pixels never supply collision or checkpoint decisions; simulation stays deterministic at fixed steps. Export a common coordinate origin, dimensions and transform with the art.
4. A square PNG master at 1024×1024 or 2048×2048 is a candidate authoring format. A conservative initial runtime candidate is 1024×1024 RGBA32 TGA: its raw pixel payload is 4 MiB per image, excluding headers, mipmaps and runtime overhead. These are budget candidates, not verified client limits. Two such layers carry 8 MiB of raw pixels before sprites and previews.
5. Preserve the authored aspect ratio with a uniform world-to-canvas transform. The current canvas is 800×480; do not stretch a square or portrait map into it. Viewport size, letterboxing or camera framing remains an implementation decision, recorded with its eventual load/scale check.
6. Validate texture loading, alpha, dimensions, UV orientation and rotation in the actual installed client before promoting exports. Those checks are **NOT RUN**. Keep file paths/casing and an asset manifest explicit; claim performance only from measured results.

## Vehicle sprites

The planned eight archetypes preserve both tank variants: **Siege Tank**, **Steam Tank**, **Goblin Mortar Trike**, **Gyrocopter**, **Gryphon Rider**, **Gnome Drag Car**, **Goblin Drag Car**, and optional **Shredder**. They are a concept roster, not implemented selectable vehicles or established balance classes.

For a single sprite rotated by the UI, use a strict 90-degree overhead orthographic view, front facing north, with neutral steering and a consistent pivot/scale. A Warcraft III-like angled three-quarter view needs directional frames; rotating one angled billboard does not create a valid view from every heading. Test the chosen orientation/UV mapping rather than assuming it matches the current placeholder.

Aircraft initially use cosmetic hover and the same ground collision rules as other vehicles. Shadows are separate 2D sprites; no flight physics or altitude-dependent shortcuts are added. Keep drift sparks, exhaust, collisions and celebration VFX in bounded pools, with no per-tick widget creation.

## Provenance and sound

Record `asset path | author/source | license | permission | date | intended use` for every candidate and distributed asset. Archives and OpenRealm tools are research leads, not permission to redistribute the assets they expose. Verify each asset's permission before import or distribution; newly drawn fan art does not itself clear underlying IP. Do not copy game files, Mario Kart/CTR art or music into the addon.

Use owned or appropriately licensed audio for engines, pickups, checkpoints, drift charge, impacts and fanfare; honor mute and verify the supported audio API before integration. The source ledger records unresolved candidates without presenting them as rights-cleared assets. No art migration or milestone acceptance follows from this plan.
