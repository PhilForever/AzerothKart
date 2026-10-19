# Mirage Raceway — map and vehicle brief

Owner direction accepted 2026-10-20 in [ADR 0008](../adr/0008-mirage-raceway-art-direction.md). This replaces the proposed Tinker Speedway as the first production map. The current playable build remains Test Oval; this document is the art/geometry brief, not a completed map or acceptance result.

## Place and composition

Depict the dry, Classic-era Shimmering Flats, before the later flooding. The owner's screenshots and [Mirage Raceway reference](https://warcraft.wiki.gg/wiki/Mirage_Raceway) establish the salt lake bed, rival workshops, drag cars and elongated circuit. Build an adaptation with playable width and readable corners; do not claim surveyed reconstruction from the minimap.

- Warm ivory cracked salt, dusty pale racing lane, sparse tire scuffs and ochre rock edges. Avoid asphalt and dense high-contrast ground noise under racers.
- An elongated loop with rounded ends, its northern bend near a rocky mound and a pit/start area near the lower portion. Retain the broad route identity in the supplied circuit image; final geometry is authored separately.
- Opposing engineering camps: a crooked goblin workshop, green patchwork roof/awnings, red canisters and scrap; a rounded gnomish riveted workshop, orange/brass chimney, workbenches and gears. Final camp positions require alignment with the chosen track blockout; the board is a mood/composition draft.
- Scatter wreckage, spare machinery, small tents, bones and low marker barriers away from the driving lane. Keep an unobstructed view of approaching gates and the next corner.
- Bake immobile scenery into the background. Reserve foreground occlusion for a few deliberate elements; a roof/banner must not hide the next checkpoint or the whole player sprite.

## Concept board and its limits

![Mirage Raceway concept board](concepts/mirage-raceway-direction-v1.png)

Built with the imagegen skill's built-in tool; [exact prompts/provenance](concepts/mirage-raceway-direction.prompts.md) and [manifest](concepts/manifest.json) are preserved. This is a concept draft outside the addon. It illustrates eight roster silhouettes and a scenery direction; it is not a texture to install or a set of cutouts to slice directly. Some unit viewpoints/facing remain inconsistent with strict overhead north-facing production art, especially the mech/trike treatment. Rebuild individual sprites with consistent camera, pivot, padding and separate shadows. Tank forms must continue to read as traditional fantasy siege/steam machines, with no modern go-kart substitutions. No user approval of this specific generated image is inferred.

## Recognizable roster

| Owner-facing archetype | Features that must survive the overhead silhouette |
|---|---|
| Siege Tank | Heavy armored siege-engine cabin, broad steel running gear, chunky gun/ram silhouette and riveted faction plates |
| Steam Tank | Distinct boiler body, smokestack, heavy iron-rimmed wheels and old-fashioned cannon; preserve it as a separate concept from Siege Tank |
| Goblin Mortar Trike | Three wheels, conspicuous mortar tube, small goblin driver and improvised mechanical frame |
| Gyrocopter | Large rotor, compact pilot cockpit, tail boom and gnomish mechanical detailing |
| Gryphon Rider | Feathered wings, eagle head/beak, lion-like rear body, dwarf rider/saddle; retain the creature rather than turning it into a vehicle chassis |
| Goblin Drag Car | Mirage-style paired rocket pods, braces and exposed/suspended small cockpit; reference the actual goblin drag-car silhouette |
| Gnome Drag Car | Distinct compact gnomish cockpit, brass engineering and rocket nacelles; readable contrast with the goblin drag car |
| Shredder, optional after initial pair | Goblin mech torso/cockpit, two legs, saw arm and claw arm |

The [source ledger](ASSET_SOURCES.md) contains actual candidates and their unverified permissions. The requested roster is a content target, not eight implemented balance classes. Start with the two drag cars. Aircraft use cosmetic hover over the same local ground collision/checkpoint rules initially; no flying shortcuts or flight simulation are implied.

## Rendering contract

Agree with one precomposed background and a limited sprite pool. The prototype's 96 road bands are Texture regions on one canvas, not hundreds of Frames; replacing those regions is still a sensible authoring simplification. Performance gains remain unmeasured.

Planned runtime paths, not files already delivered:

```text
addon/AzerothKart/Assets/
  Tracks/SaltFlats/Background.tga
  Tracks/SaltFlats/Foreground.tga   # optional transparent occlusion
  Tracks/SaltFlats/Preview.tga
  Karts/GoblinDragCar.tga
  Karts/GnomeDragCar.tga
  Props/OilBarrel.tga
  Props/Wreckage.tga
  Props/BoostPad.tga
  UI/Countdown.tga
  UI/CheckeredFlag.tga
```

Countdown and flags can continue using existing text/primitives until an asset improves readability. A planned prop image does not implement its gameplay behavior. Expand filenames to the other roster entries as each asset is authored.

Keep editable source/layers and PNG masters outside runtime. Author against a common map origin and explicit world bounds; transform art, simulation positions, gates and props with one uniform scale and offset. Do not stretch the portrait circuit into the current 800×480 canvas. Decide the first framing/blockout before painting final road edges; square 1024/2048 masters and a 1024 runtime export are candidates, not a client-verified maximum or a viewport decision.

For freely rotated single sprites use a strict 90-degree overhead orthographic camera, front facing north, consistent pivot, padding and neutral diffuse lighting. Keep world-oriented shadows separate. A stronger Warcraft III three-quarter camera needs directional frames; rotating one angled image does not change which side faces the camera. Start with separate images to establish facing/alpha before adding atlas UVs or animation. Check readability at intended play size and rotation endpoints before producing a full roster.

Texture methods are supported by build-matching source: parent-workspace `research/upstream/wow-ui-source-forever-70450/version.txt` is `1.60.1.70450`; `SimpleTextureBaseAPIDocumentation.lua` defines `SetRotation(radians, optionalPivot)` at line 527, `SetTexCoord` at 580 and `SetTexture(textureAsset, ...) -> success` at 604. [Pinned source](https://github.com/Gethe/wow-ui-source/blob/172a387e3ab85b26e6640d3058d5ec1e6ccd4c63/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua#L527). The current kart already uses rotation, with earlier live movement/rotation observations. Actual custom TGA loading, alpha, dimensions, UVs, pivot/sign and this art's appearance are **NOT RUN**; source signatures do not establish them.

An uncompressed 1024×1024 RGBA32 image has 4 MiB of raw pixel payload; two full layers have 8 MiB before preview/sprites/overhead. Export-format and file-size checks must distinguish raw pixels from TGA headers/compression and actual client memory. Do not create textures during simulation ticks.

## Geometry and first build slice

Pure track data owns road/surface regions, walls, start pose, ordered directional gates and the version. Artwork never supplies lap or collision decisions. Replace the analytical oval only after the new geometry and picture share the same coordinate contract; keep Test Oval as a fallback while the first background is checked.

**Next executable task:** author a pure Mirage circuit blockout and a matching layout guide, with explicit bounds, road width, spawn and directional gates. Use a uniform preview transform that preserves the vertical loop; keep the current input/drift/race lifecycle. This precedes a clean background export plus one drag-car sprite, rather than producing eight finished assets at once. Test the geometry offline with focused order/containment checks; perform one scoped custom-texture preview later and record its actual result.

M0/M1/M3 acceptance and the multiplayer transport gate remain open. No runtime map, new collision logic, roster selection, asset loader, save migration or multiplayer was added by this research/art-direction slice.
