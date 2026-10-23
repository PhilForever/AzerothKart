# Claude handoff — Darnassus, Undercity and painted elevation

Prepared 2026-10-23 about 03:30 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the Orgrimmar handoff (`claude/orgrimmar` `72b362f`), which Codex approved ([review](../reviews/2026-10-22-orgrimmar.md)), integrated on `codex/live-multiplayer-integration` and installed with the multiplayer candidate; the owner has pushed it.

**Base:** Codex's integrated `codex/live-multiplayer-integration` at `6ad66d1` (the installed multiplayer candidate `c581a52` plus its docs). New branch **`claude/darnassus-undercity`**; the commits are listed in [Branch, commits and workspace](#branch-commits-and-workspace).

**Scope (changed):** `scripts/city_layouts.py` (the `DARNASSUS` and `UNDERCITY` layouts; `Profile`, `street_heights`, `loop_length`, `along_loop`), `scripts/city_paint.py` (optional `elevation` layer: `Relief`, `paint_relief`, `fill_polygon_value`; optional `water_tile` and `water_glow`; `Strata.tile` and `rock.top_texture`), `scripts/build_city_tracks.py` (emits and validates the proposed `elevation` heights), `addon/AzerothKart/CapitalCities.lua` (generated: `darnassus_canopy` and `undercity_slime` added; the other three entries unchanged), `addon/AzerothKart/Assets/Tracks/{Darnassus,Undercity}/{Background,Preview}.tga` (new), `addon/AzerothKart/Courses.lua` (both entries ready), `addon/AzerothKart/Menu.lua` (**only** two `Menu.TRACKS` entries and two `PREVIEW_CELLS`), `tests/test_circuit.lua` (catalog counts and cycle, the walk helper accepts a city without an approach, Darnassus and Undercity blocks, the heights), `tests/test_menu.lua` (two more Track button steps; Thunder Bluff as the coming-soon example), `scripts/validate_project.py` (required files), `docs/adr/0015-track-elevation.md` (new, proposed), `docs/art/tracks/{darnassus,undercity}*` (new), `docs/art/tracks/orgrimmar.md` (the trailing space Codex's review noted), `docs/art/ui/front-end-review.png`, `docs/art/ASSET_SOURCES.md`, `docs/API_CONTRACTS.md`, `docs/TRACKS.md`, `docs/TEST_PLAN.md`, `docs/INDEX.md`, `docs/ASSETS.md`, `README.md`, `addon/AzerothKart/README_ADDON.md`, `CHANGELOG.md`, `tests/MANUAL_CLIENT_CHECKLIST.md`, this handoff. **Not touched:** `Circuit.lua`, Physics, collision, `UI.lua`, `Presentation.lua`, `tests/test_ui.lua`, the session/network modules, `docs/PROGRESS.md`.

**Codex's active reservation** (`codex/multiplayer-grid` `f5e6918`) delegates UI/Menu, the UI tests and Presentation to Codex. This branch keeps out of them except pure catalog data in `Menu.lua` (the two track entries and their preview cells, the same edit Orgrimmar made) and the Track-cycle and coming-soon lines of `tests/test_menu.lua`. Kart height rendering, which elevation would eventually want, is deferred to after that work.

## Owner instructions

- "Orgrimmar is pushed. Let's do Darnassus and Undercity maybe something like this, start at blue line in apothecarium. What would be cool is if you could figure a way to add elevation to maps, as some of our maps clearly need it." With his in-game Darnassus and Undercity maps, each with a red route and a blue arrow.
- Elevation: offered three steps, he chose all three: "Looks only first (Recommended)", "Slopes you can feel", "Bridges over the track".
- Darnassus start: asked whether the karts should start on the road in from the Warrior's Terrace at his red marks, join the loop and turn north at the blue arrow: "Yes, like that (Recommended)".
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes and runs the client checks; Codex prepares coordinated installs.

## Delivered

The sheets have the route, play, look, files, rebuild commands and provenance: [Darnassus](../art/tracks/darnassus.md), [Undercity](../art/tracks/undercity.md). Each has a review picture (the loop's direction and nine follow-camera views) sent to the owner.

- **Darnassus Canopy Run** (`darnassus_canopy`): start on the road in from the Warrior's Terrace, join the loop at the central terrace, then counter-clockwise past the Craftsmen's Terrace, the Cenarion Enclave, the Temple Gardens' causeway, the Temple of the Moon and the Tradesmen's Terrace. Six gates (finish: Warrior's Terrace), a 3,895-unit lap, a 206-unit approach, `fullSpeedToWalls`, `wallClearance` 14 with 931 junctions. Ashenvale and Ruins art, Silvermoon's houses in Darnassus violet, the World Tree's bark round the city.
- **Undercity Slime Circuit** (`undercity_slime`): the grid on the loop below the Apothecarium heading east, where his arrow points (no approach road; the finish line 131 units behind the grid); counter-clockwise round the outer ring past the Rogues', Magic and War Quarters, a hairpin into the inner city, clockwise round the Trade Quarter, out to the south and round the southern canal's end. Five gates (finish: Apothecarium), a 7,327-unit lap, `fullSpeedToWalls`, `wallClearance` 14 with 1,721 junctions. Each quarter in its own stone, the Scourge's buildings recoloured Forsaken green, glowing green slime canals, Sylvanas before Lordaeron's throne, a slime well at the centre.
- **Elevation, looks first** ([ADR 0015](../adr/0015-track-elevation.md), proposed; [contract proposal](../API_CONTRACTS.md#proposed-track-elevation-claude-2026-10-23-for-codex-review)): a city may declare levels and street heights; the painter draws retaining walls, raised-street walls, brinks, sun shadows, height's light and ramps lit by their slope with joints across them. Darnassus stands on three terraces (44, 22, 0); Undercity's Trade Quarter is sunk 30. The karts drive flat. The other cities have no `elevation` and paint byte for byte as before.

## Changes Codex must review

1. **Two new city definitions**, existing fields only: `CapitalCities.darnassus_canopy` and `CapitalCities.undercity_slime` (version 1 each; `wallClearance` 14 with generated `wallVertices`, `fullSpeedToWalls=true`, no plazas, solids or narrows). **Undercity has `branches={}`**: the first city whose spawn lies on the loop itself, as Mirage Raceway's does; `Circuit.new` already accepts it, but please check the multiplayer grid you are building places its slots on a loop start (the finish gate is 131 units behind the spawn; a slot behind it crosses the finish line before gate 1, which `Checkpoints` ignores because only `gates[nextGate]` counts). `Courses.lua` makes both available; Thunder Bluff stays `soon`.
2. **A proposed, inert data field:** both new entries carry `elevation={centerline={...}, branches={{...}}}`, the street's height at every point. `Circuit.new` copies named fields only, so nothing reads it. Accept, rename or drop it with the proposal; slopes, crests, bridges and kart height are Codex's to decide (details in the contract proposal and the ADR).
3. **Tests:** `tests/test_circuit.lua` (soon count 1; the seven-track cycle; the walk helper now accepts `branches[1] == nil`; Darnassus and Undercity blocks: radii, gates, clearance, full grip, gate order with wall-free centerlines, both ends of every gate in wall, throttle from each grid on road, one finite height per point, no heights on the flat cities); `tests/test_menu.lua` (two more Track steps, the coming-soon example). No mechanics, capture, lifecycle, clock or count assertion changed; explicit UI counts unchanged (79/166/81).
4. **Install:** four new files (two 16 MiB backgrounds, two 1 MiB previews): 53 files with the installed 49; a full client restart. The staging loader still holds at most two city pictures.
5. **Contract and docs:** `docs/API_CONTRACTS.md` (Orgrimmar marked approved and integrated; the two new cities proposed; the elevation proposal), the new ADR 0015 (number chosen as the next free one on this base; renumber freely if yours lands first).

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8) and on the developer machine's Linux shell (Python 3.10.12, Lupa 2.8) at `e96044b`: 57 files parsed, the full suite on Lua 5.1 and 5.4 |
| `tests/test_circuit_boundary.py` | **PASS** (11 tests), in the cloud and on the developer machine |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** in the cloud for `CapitalCities.lua` and all ten pictures: Stormwind `078a7805…`, Ironforge `258bc9be…` and Orgrimmar `5b00f6cf…` byte-identical to their committed bytes after the painter changes; Darnassus `70b3bb8c…` and Undercity `2c367c03…` reproduce. **CHECK PASS on the developer machine** at `e96044b` (Python 3.10.12, its own Warcraft III extraction, its own rendered sprites) for all five cities, with the same SHA-256 values |
| Collision probe (offline, Lupa) | `surfaceAt` against an independent disc-inside-union test (a 14-unit disc inside the 90-unit visual capsules), every 1/4 degree round the walls: Darnassus 10,200 points, Undercity 18,240 points, **no mismatch** |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| `python scripts/preview_ui.py` | Regenerated `docs/art/ui/front-end-review.png` (the track list with five cities ready); one-off runs with each new city selected showed their previews, blurbs and facts fit, and a mock drive from each grid (not committed) |
| Review | Each city's overview and nine 533×320 follow-camera views (the review pictures) |

**NOT RUN:** the client (both cities' load, look, drives, walls, camera, performance); any install; multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

[The Darnassus and Undercity section of the client checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-darnassus-and-undercity-check-proposed-claudedarnassus-undercity): the track screen lists both with previews; the pictures load; both drives through their gates; whether the terraces and the sunken Trade Quarter read as levels; walls; frame rate and Print Probe 79/166/81.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-23 ~03:30 CEST — Claude / `claude/darnassus-undercity`, Darnassus, Undercity and painted elevation
>
> - The owner's Darnassus and Undercity maps: Darnassus counter-clockwise from the Warrior's Terrace road (six gates, 3,895-unit lap, 206-unit approach); Undercity from his blue arrow below the Apothecarium, the spawn on the loop (five gates, 7,327-unit lap, no branch). Both `fullSpeedToWalls`, `wallClearance` 14; no Circuit change.
> - Elevation, the owner's first of three chosen steps: painted levels (retaining walls, raised streets, brinks, sun shadows, height's light, lit ramps with joints); Darnassus three terraces, Undercity's sunken Trade Quarter. Proposed inert `elevation` heights in `CapitalCities.lua`; slopes/crests/bridges/kart height proposed for Codex (ADR 0015, API_CONTRACTS). Unchanged cities byte-identical.
> - `test_lua.py --runtime both` PASS; `test_circuit_boundary.py` PASS; `build_city_tracks.py --check` PASS (all five cities), in the cloud and on the developer machine (Python 3.10.12, its own extraction and sprites); collision probe 28,440 points, no mismatch; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/darnassus-undercity` (the worktree previously held `claude/orgrimmar` `72b362f`, unchanged) |
| Commits | `claude/darnassus-undercity` on `6ad66d1`: the two cities, the elevation layer, catalog, menu data, tests, docs and this handoff; later commits only record checks |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/darnassus-undercity` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:** the two cities' Warcraft III files were extracted on the developer machine into the shell's `akcheck/WC3` (commands in the sheets) and carried to the cloud as a git-ignored tar under `local-artifacts/`. Commits are made in a cloud clone with this repository's local identity, moved as git bundles (`local-artifacts/bundles/`) and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable. The untracked `Claude outputs/` folder is still left for the owner.

## Next

1. The owner's reaction to the two review pictures (changes go on this branch): the slime's brightness, the terraces' strength, Undercity's lap length.
2. Codex: review the two cities (data, the loop start, tests, four new files) and the elevation proposal; install when the owner wants them.
3. If the proposal is accepted: Codex's slope physics on the generated heights; then bridges (layered capsules and a deck overlay) with a route that needs one (Thunder Bluff's mesas), and kart height in Presentation after the multiplayer-grid work.
