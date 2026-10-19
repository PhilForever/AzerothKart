# ADR 0008 — Mirage Raceway and fantasy vehicle art

**Status:** Accepted owner direction, 2026-10-20; art/runtime implementation pending.

## Decision

The first production map is **Mirage Raceway**, on the dry, pre-flood Shimmering Flats, replacing the proposed Tinker Speedway. The owner wants recognizable Warcraft III-like vehicles and riders rather than modern go-karts.

Plan eight archetypes: **Siege Tank**, **Steam Tank**, **Goblin Mortar Trike**, **Gyrocopter**, **Gryphon Rider**, **Gnome Drag Car**, **Goblin Drag Car**, and optional **Shredder**. Preserve the two named tank variants. Aircraft use cosmetic hover and shared ground collision initially, with separate 2D shadows; this does not add flight physics.

Compose static terrain/scenery into `Background.tga`, optional occluding scenery into `Foreground.tga`, and a track-selection `Preview.tga`. Vehicles, interactive props and VFX remain separate pooled sprites. Keep source layers and PNG masters outside runtime under `docs/art/concepts/`; do not build a large tiled framework for the first map.

Use a strict 90-degree overhead orthographic view, vehicle front facing north, for a single freely rotated sprite. An angled three-quarter treatment needs directional frames instead of rotating one billboard. The art should remain recognizable at actual play size.

## Geometry, viewport and export boundaries

Track road/surface/wall/gate/spawn geometry remains explicit Lua data, independent of painted pixels and evaluated by fixed-step simulation. Register art and geometry with a common origin and uniform transform. Preserve aspect ratio: square or portrait map art must not stretch to fill the current 800×480 canvas. Viewport framing remains an implementation choice.

A 1024×1024 or 2048×2048 PNG master and initial 1024×1024 RGBA32 TGA exports are budget candidates, not verified client limits. Each 1024×1024 RGBA image has 4 MiB of raw pixels before overhead; optional layers and sprite storage must be budgeted separately. Actual loading, alpha, dimensions and UV/rotation checks are **NOT RUN**.

## Provenance and implementation status

Keep per-asset authorship, source, license, permission and intended-use records before importing or distributing artwork. Candidate archives and OpenRealm tools do not themselves grant asset rights, and newly drawn fan art does not automatically clear underlying IP. The [source ledger](../art/ASSET_SOURCES.md) distinguishes references from cleared files.

This decision approves planning and authoring direction. It does not claim a completed map, selectable roster, rights-cleared media, faster rendering or milestone acceptance. Current Test Oval code and its 8 frames/110 textures/13 font strings remain unchanged; its 96 road bands are Texture regions, not Frames. No runtime TGA is introduced by this planning slice.

See [the map brief](../art/MIRAGE_RACEWAY.md), [asset pipeline](../ASSETS.md) and [track responsibilities](../TRACKS.md). M0/M1/M3 acceptance and measured multiplayer gates remain open.
