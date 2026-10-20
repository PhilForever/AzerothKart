# Mirage Raceway — asset-source ledger

Research date: 2026-10-20. This ledger separates inspiration, candidate media and tools. No third-party model/texture archive was downloaded, unpacked, rendered, imported or installed during this research. A public download or a source-code license is not an asset redistribution grant. Internal formats, animation quality and small-size readability remain untested unless explicitly stated.

## Owner references and map identity

- [Mirage Raceway](https://warcraft.wiki.gg/wiki/Mirage_Raceway): dry Classic-era racing settlement in the Shimmering Flats, with rival goblin/gnome teams and drag cars. The retrieved article distinguishes the original location from the later flooded ruins. Full-page opens were intermittent; its indexed article text was available. Treat the non-canon RPG section as separate from game geography.
- [Rocket car](https://warcraft.wiki.gg/wiki/Rocket_car): identifies the Gnome Drag Car and Goblin Drag Car associated with Mirage Raceway. These are the appropriate visual references for the owner's pod-racer-like machines.
- The owner's four attached images show the two engineering camps, a closer goblin drag car, and a circuit outline. They are visual references, not shipped texture files. Personal temporary screenshots were not copied into the repository.
- Blizzard's [Siege Engine](https://classic.battle.net/war3/human/units/siegeengine.shtml) and [Gryphon Rider](https://classic.battle.net/war3/human/units/gryphonrider.shtml) pages provide primary unit references. Their artwork is reference material, not licensed addon exports. Preserve the owner's distinct Siege Tank and Steam Tank roster entries even where historical unit terminology overlaps.

## Concrete WC3Vault candidates

Individual pages were reviewed by the source-research agent. Direct opens intermittently fail in the browser tool; the archive's homepage/Browse route was accessible. Package sizes are listing metadata, not independently inspected downloads.

| Candidate | Credited author on listing | Listed package | Proposed use | Import/redistribution status |
|---|---|---|---|---|
| [Goblin Mortar Trike](https://wc3vault.com/0fbe959f-489b-48f0-82bf-8c4322f1f060) | erwtenpeller and chriz | RAR, 284 KB | **Imported 2026-10-20 as the default kart**, rendered without mesh or texture edits ([asset sheet](karts/goblin-mortar-trike.md)) | Read Me forbids modification without the authors' permission; the owner calls it outdated. Credits given; redistribution unresolved for release review |
| [Steam Tank](https://wc3vault.com/c3bda868-1673-4042-b72b-81549a02a471) | Unknown (WC3C) | ZIP, 241 KB | Traditional heavy-engine reference; ITE project and texture dependencies listed | Unverified; attribution/underlying textures unresolved |
| [Gyrocopter](https://wc3vault.com/20900e69-d9dc-455a-a5e0-057cb36c4bdf) | Unknown (WC3C) | ZIP, 127 KB | Rotor/cockpit/tail silhouette; FlyingMachine BLP dependency listed | Unverified; capture/alpha/animation also untested |
| [Gryphon Rider](https://wc3vault.com/fad9e36c-199c-4463-825a-b2696199e970) | Unknown (WC3C) | ZIP, 345 KB | Wing, eagle head and rider silhouette; gryphon texture dependency listed | Unverified; suitable flap cycle not inspected |
| [Konous M8](https://wc3vault.com/3f21dab1-0519-4d5c-9cdf-b8b550e99d0b) | Anarchianbedlam | MDX, 115 KB | Alternative dwarf siege-machine reference | Unverified; does not replace both owner-requested tank variants |
| [Dwarven Biker](https://wc3vault.com/2bfa9372-652a-49a9-bebc-3919f867809d) | Unknown (WC3C) | ZIP, 136 KB | Optional dwarf counterpart reference; dwarfbike BLP listed | Unverified; outside initial required roster |
| [Buildings Part 1: Economy](https://wc3vault.com/35b217f1-e216-4016-b5f6-4c3d8c1b4af4) | Shadow_killer | RAR, 42 KB | Pit-area building silhouettes | Archived description permits editing/use; authorship chain, scope and underlying texture rights still unverified |
| [Walls Pack](https://wc3vault.com/5daffce9-46cf-411d-8f18-4fd1d1781acf) | Daelin | RAR, 19 KB | Barrier shapes; 26 walls listed | Unverified; uses game textures |
| [Archways pack](https://wc3vault.com/b1f1faf9-4c37-4a4b-a684-c3256cbbf288) | Daelin | RAR, 158 KB | Possible start-gate reference; seven structures listed | Unverified; uses game textures |

[Goblin Mortar Trike HD](https://wc3vault.com/048f6f1d-a4ea-4b7d-8d3a-f7e1103c63ef), credited to NiRVaNa_87, lists high/low-resolution BLP skins in a 288 KB ZIP. Its map-credit request does not establish permission for this different use. [WC3Vault](https://wc3vault.com/) is an archive; its archive-wide statements do not clear every uploader's material. No suitable Mirage drag-car or shredder candidate was located in the checked searches; this is not evidence that none exists.

**Disposition:** these remain candidates, not inspected runtime exports. Under accepted [ADR 0009](../adr/0009-warcraft-iii-asset-reuse.md), a selected Warcraft III source may proceed to local conversion and visual work without repeating project-direction approval. Record the creator, source terms, model/texture dependencies, modifications, credits and permission status for each imported file; honor incompatible author conditions and keep unresolved redistribution status explicit for release review. No candidate above is marked rights-cleared.

## Engines, viewers and offline render tools

| Source | Verified role | License / practical boundary |
|---|---|---|
| [OpenRealm](https://github.com/corepunch/open-realm) | Separate game engine and format tooling; explicitly excludes retail game data | [MIT code](https://github.com/corepunch/open-realm/blob/main/LICENSE); not a Warcraft art pack |
| [OpenRealm diagnostic tools](https://github.com/corepunch/open-realm/blob/main/docs/diagnostic-tools.md) | Documents MDX animation/camera/frame controls and frame-to-PNG capture; [implementation](https://github.com/corepunch/open-realm/blob/main/tools/mdxtool.c) writes RGBA PNG | Useful capture lead; actual top-down/transparent output, supplied-model dependencies and atlas workflow NOT RUN |
| [OpenRealm scene workflow](https://github.com/corepunch/open-realm/blob/main/docs/rendering-scene-workflow.md) | Documents bounded screenshots/hidden-window rendering | Requires a functioning graphics environment; no software-only/headless guarantee inferred |
| [warcraft-iii repositories](https://github.com/orgs/warcraft-iii/repositories) / [overview](https://github.com/warcraft-iii) | Scripting, build/UI tools, templates and map projects | No general-purpose licensed art collection identified; inspect each repository separately |
| [mdx-m3-viewer](https://github.com/flowtsohg/mdx-m3-viewer) | MDX/BLP viewing, parsers, animation and cameras | [MIT](https://github.com/flowtsohg/mdx-m3-viewer/blob/master/LICENSE); README says no longer actively maintained; ready-made atlas export not verified |
| [khalv/mdl-exporter](https://github.com/khalv/mdl-exporter) | Blender MDL import/export, documented older Blender branches and PNG texture inputs | [GPL-3.0](https://github.com/khalv/mdl-exporter/blob/2.8/LICENSE); current Blender compatibility unverified |
| [PavelBlend/Blender_WarCraft-3](https://github.com/PavelBlend/Blender_WarCraft-3) | MDX model/animation import; README specifies Blender 2.78 | [BSD-2-Clause](https://github.com/PavelBlend/Blender_WarCraft-3/blob/master/LICENSE); legacy compatibility risk |

Tool code licenses concern the tools. They do not grant rights to retail game data or third-party models opened with them. No external executable is needed by addon players, and no capture tool was installed or executed here.

## Explicitly licensed fallback art

- [Kenney Racing Pack](https://kenney.nl/assets/racing-pack): its primary page lists 420 2D top-down racing files under CC0. Potential generic markings/placeholder props; its modern vehicles do not satisfy the requested Warcraft roster.
- [Kenney Desert Shooter Pack](https://kenney.nl/assets/desert-shooter-pack): its primary page lists 500 16×16 pixel-art files under CC0. Potential terrain/prop blockout material; camera and painterly-style fit remain uninspected.

Neither pack was downloaded. A license match alone does not make a visual-style match. Prefer a coherent original salt-flat background over mixing incompatible asset styles.

## Newly authored concept artifact

[Selected concept board](concepts/mirage-raceway-direction-v1.png) — built-in imagegen generation plus one vehicle-panel refinement, 2026-10-20. [Exact prompts and limitations](concepts/mirage-raceway-direction.prompts.md); [file manifest](concepts/manifest.json). It is concept fan art, not a runtime atlas or a claim that underlying Warcraft IP is cleared. No retrieved model, Blizzard screenshot or archived texture was copied into the board. The generated image was visually reviewed; camera/facing, scale, silhouettes and shadows still require production sprite work.

## Next asset decision

The current runtime `addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga` is original procedural scenery (v1, 2026-10-20), painted by `scripts/build_mirage_background.py` against the repository's Mirage geometry. It replaces the earlier code-generated blockout at the same path. No archived model, game texture, screenshot, concept-board crop or generated image supplies its pixels. Authorship/source: Claude for Azeroth Kart; intended use: Mirage runtime background. [Its asset sheet](mirage-background.md) records format, SHA-256, registration checks, provenance and the pending client check. This does not clear third-party Warcraft assets.

The first runtime vehicle, `addon/AzerothKart/Assets/Karts/GoblinDragCar.tga`, is also original project art. It is painted procedurally by `scripts/build_kart_sprites.py` from its own shapes, palette and integer noise, with no Blizzard, WC3Vault, other third-party, concept-board or generated-image input. Authorship/source: Claude for Azeroth Kart; intended use: default runtime kart sprite, 2026-10-20. [Its asset sheet](karts/goblin-drag-car.md) records format, SHA-256, provenance and the pending client check.

The default runtime kart since 2026-10-20, `addon/AzerothKart/Assets/Karts/GoblinMortarTrike.tga`, is rendered from the Warcraft III **Goblin Mortar Trike** model and texture by erwtenpeller and Chriz (Vast Graphics). It was fetched from the WC3Vault listing above on the owner's request.

- **Files and hashes:** archive `GoblinMortarTrike_Updated_.rar`, SHA-256 `f0b4341c…b86b`; `GoblinMortarTrike[unit].MDX` and `GoblinMortarTrike.blp` are used.
- **Modifications:** none to the mesh, UVs or texture. The script poses the Stand frame, applies team color, scales, renders 64 three-quarter headings with the scenery's light and shadow, and filters.
- **Terms:** the archive's Read Me reads "meant for use, not modification" and asks users to contact the authors before editing. The owner answered that the Read Me is outdated and directed this use; the authors' current permission was not independently confirmed.
- **Credits:** the addon README and [the asset sheet](karts/goblin-mortar-trike.md). The source files are kept outside Git under `local-artifacts/`.
- **Status:** redistribution is **unresolved** for release review.

**Owner direction, 2026-10-20 (given to Claude, reaffirmed to Codex):** "Don't be afraid to use wc3 assets like this project has done", pointing at [WIIIUI](https://github.com/Fiurs-Hearth/WIIIUI), and "Of course, maintain the agreed upon design guidelines for Azeroth Kart - but we don't necessarily have to reinvent the wheel with everything we do." The owner listed [WC3Vault assets](https://wc3vault.com/assets), [OpenRealm](https://github.com/corepunch/open-realm), [warcraft-iii repositories](https://github.com/orgs/warcraft-iii/repositories) and [warcraft-iii](https://github.com/warcraft-iii) as sources. Codex accepted [ADR 0009](../adr/0009-warcraft-iii-asset-reuse.md) and reconciled AGENTS/ADR 0005 on `codex/claude-assets-review`; integration remains an explicit action. WIIIUI's README and implementation show Warcraft III faction themes and bundled texture paths; no applicable general asset license or Blizzard redistribution grant was established in the inspected root/README. The earlier categorical assertion about the entire repository's lack of a license was not established by that inspection. Keep a row and credits for every imported file, with unresolved status accurately labeled.

Mirage scenery v1 imports no Warcraft III file; it was painted procedurally so every road edge registers exactly to `isDrivable`. Warcraft III terrain, doodad, particle and UI material remains the preferred shortcut for props, VFX, HUD chrome and later scenery passes; inspect and log each imported file here first. A contrasting Gnome Drag Car can later use the same generator and registry. The searches so far found no suitable WC3 drag-car source; they do not establish that none exists.
