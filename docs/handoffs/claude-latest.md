# Claude handoff — Undercity's slime river and no shoulders on city streets

Prepared 2026-10-23 at about 12:00 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner); updated about 14:50 CEST with the grimmer Undercity light.

This supersedes the Darnassus, Undercity and elevation handoff (`claude/darnassus-undercity` `9143949`). Codex reviewed that work and integrated it on `codex/two-city-integration` (merge `cac4290`, docs `505f054`), installed it as the combined candidate, and pushed it.

**Base:** Codex's `codex/two-city-integration` at `505f054`. The new branch is **`claude/undercity-river`**; its commits are listed under [Branch, commits and workspace](#branch-commits-and-workspace).

**Scope (changed):**

- `scripts/city_layouts.py`: Undercity version 2 (the ring course `uc_course`, its bridges, the canal ring, each quarter's districts on both sides of the slime, landmarks, elevation); Ironforge's `full_speed_to_walls` and version 4; the module docstring.
- `scripts/city_paint.py`:
  - City streets are paved from wall to wall unless a city sets `shoulders`.
  - Bridges gain a `deck` style (timber planks, or stone with its own colour), `force`, per-bridge `posts`, a timber side (edge beam, piles, the deck's shadow) and a timber `rail` wall.
  - A bridge's side over water drawn whole now hangs only below its deck.
- `addon/AzerothKart/CapitalCities.lua` (generated): Undercity version 2; Ironforge `version=4, fullSpeedToWalls=true`.
- All five cities' `Background.tga` and `Preview.tga`.
- `addon/AzerothKart/Menu.lua`: Undercity's catalog entry only (blurb and facts).
- `tests/test_circuit.lua`: the Undercity block; the Ironforge assertions.
- Docs: the five city sheets, `TRACKS.md`, `API_CONTRACTS.md`, ADR 0015, `ASSET_SOURCES.md`, `CHANGELOG.md`, `README.md` (one sentence), `tests/MANUAL_CLIENT_CHECKLIST.md`, plus the overview and review PNGs and the sources lists.

No Lua module outside the generated data and the catalog entry changed. `UI.lua`, `Presentation.lua`, `RaceGrid.lua` and the multiplayer modules are untouched.

## Owner instructions

- "Pushed by Codex. Actually I want to revamp the UC map. Let's make it a circular map through the outer ring. It's basically a river of slime with bridges at every section."
  - He sent a new in-game Undercity map with a red route round the outer ring and a start arrow at the bottom heading east.
  - He also sent two screenshots of the canals: timber plank bridges on posts, a humped stone bridge, and bright green slime.
- Mid-task: "Players should be crossing the bridges (sharp turns) to cross the slimey river. See the other screenshots for reference. - and honestly - doesn't make sense to have shoulders on citymaps. Just extend widen the drivable track to the width of the shoulders."
- After seeing version 2: "I want undercity to look more grim, do something about the lighting without making it too dark."
- Standing instructions:
  - no merge into `main`;
  - no claim of in-game verification without the actual client;
  - leave the simulation-control functions in `UI.lua` alone;
  - the owner pushes and runs the client checks; Codex prepares coordinated installs.

## Delivered

- **Undercity Slime Circuit version 2** ([sheet](../art/tracks/undercity.md), review picture sent to the owner).
  - The slime is the canal ring round the Trade Quarter: radius 610 from the city's centre, 120 wide.
  - From his arrow below the Apothecarium, the course runs counter-clockwise along the outer walkway (778 from the centre) and the inner one (442).
  - It changes walkway on a bridge at every section, as his red line crosses the ring. There are six bridges, timber and stone by turns. Each is a turn of radius 70 on the centerline (a little over 90 degrees) onto a 197-unit straight across the slime at right angles, then the same turn off the other way.
  - Six gates: Rogues' Quarter, Magic Quarter, Ruins of Lordaeron, War Quarter, Apothecarium, and The Canals (the finish).
  - A 5,797-unit lap (version 1 was 7,327), still with no approach road: the spawn is on the loop, 136 units past the finish gate.
  - Data: `fullSpeedToWalls`, `wallClearance` 14 with 1,340 junctions.
  - The Trade Quarter stays sunk 30 beside the course. The stone bridges rise in painted humps 6 high; karts drive them flat.
  - Each quarter now draws its buildings on both sides of the slime.
- **Grimmer Undercity light** (art only): a new optional painter pass, `grade` (`paint_grade`, with a chamfer distance field), over the finished picture.
  - Away from lights the city is dimmed to 62%, cooled toward violet, greyed by 30% and darker toward the cavern's far reaches.
  - The slime lights the walkways green for about 110 units; braziers and the slime well cast green pools; the bridges' lanterns (now brighter) cast yellow ones.
  - The street keeps at least 72% of its light. The slime itself is left untouched.
  - Only Undercity sets `grade`; the other cities' bytes are unchanged.
- **No shoulders on city maps.**
  - Every city's street is paved from wall to wall, to a kerb at the walls' foot. Stormwind's pavement, Ironforge's flagstones, Orgrimmar's gravel and Darnassus's moss strips are gone.
  - Stormwind, Orgrimmar, Darnassus and Undercity already had full grip to their walls, so for them only the paint changes.
  - Ironforge version 4 now has full grip to its walls too (`fullSpeedToWalls=true`). It is the one change of handling.
  - The generated `roadRadius` stays 56. Routes, gates, spawns, Ironforge's narrows, every wall and every junction are unchanged.

## Changes Codex must review

1. **Undercity version 2**, using existing fields only.
   - The new loop has turns tighter than the wall radius. The inner corner at each bridge's end is a sharp wall corner (the bridge's abutment). The offline probe below found no disagreement between `surfaceAt` and an independent disc-inside-union test round those corners.
   - The spawn is still on the loop. `RaceGrid.pose` on it gives host (996.2, 228.6) and guest (997.4, 264.6), both on road (checked offline with Lupa, as for the other four cities).
   - The version is 2 because the geometry changed completely.
2. **Ironforge version 4** (`fullSpeedToWalls=true`), at the owner's request.
   - The strip that version 3 kept rough is road now.
   - `tests/test_circuit.lua` now expects road at the gate-hall corner, along a straight wall and before the narrows.
   - The rough-tunnel regression sets `fullSpeedToWalls=nil` on its copy, so it still tests `Circuit.new`'s default rough policy.
   - `Courses.lua` still carries Ironforge's `rough` label, which nothing reaches now; I left it so a revert is one flag, the version and the tests.
   - This is a handling change: please judge it under your Physics/compatibility policy.
   - **Documented conflict:** `AGENTS.md`'s shared-city row says to "preserve … Ironforgev3/narrows and rough-shoulder exposed-wall metadata". The owner's instruction comes first under `AGENTS.md`'s own precedence rule. So version 4 keeps the narrows and every exposed-wall junction (`wallVertices` unchanged) and changes only the rough-shoulder policy. I did not edit `AGENTS.md`; please update that row at integration if you accept the change.
3. **Painter default:** no shoulders unless a city sets `shoulders`. All five pictures change.
   - The `grade` pass is a second, optional painter step: picture only, set by Undercity alone; no data or collision change.
   - Darnassus's sources list loses one texture (its old shoulder tile).
   - The other cities' model placements are unchanged.
4. **Install:** ten changed files (five backgrounds, five previews) at their existing paths, plus `CapitalCities.lua` and `Menu.lua`. No new files. Changed textures at the same paths need a full client restart.
5. **Contracts and docs:** `API_CONTRACTS.md` proposes Undercity version 2 and Ironforge version 4 under Capital Cities. ADR 0015's consequences note the humps. No new definition field and no Circuit change.

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8) and on the developer machine's Linux shell (Python 3.10.12, Lupa 2.8) at `48f571a`: 59 files parsed; the full suite on Lua 5.1 and 5.4 |
| `tests/test_circuit_boundary.py` | **PASS** (11 tests), in the cloud and on the developer machine |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** for `CapitalCities.lua` and all ten pictures, both in the cloud (Python 3.13) and on the developer machine at `48f571a` (Python 3.10.12, its own Warcraft III extraction, its own rendered sprites). The bytes are identical on both: Stormwind `8f48089c…`, Ironforge `c98c1a54…`, Orgrimmar `6ba18ce8…`, Darnassus `0e1267f7…`, Undercity `7868cc3e…` |
| Collision probe (offline, Lupa) | `surfaceAt` against an independent disc-inside-union test (a 14-unit disc inside the visual capsules), at points just inside and beyond the walls. Undercity: 15,120 points, round the bridges' sharp corners too, **no mismatch**. Ironforge: 18,600 points, **no mismatch** with the Forlorn Cavern's narrows modelled at their own radius; the probe's first run, which treated every capsule as 90, disagreed only inside those tunnels, where Circuit is right |
| `RaceGrid.pose` (offline, Lupa) | Host and guest slots on road for all five cities |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| Review | Undercity's overview and nine 533×320 follow-camera views (the review picture); before/after crops of Stormwind, Ironforge and Orgrimmar streets |

**NOT RUN:** the client (any city's look, the new Undercity drive and its turns, Ironforge's feel, performance), any install, and multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

Run [the Undercity version 2 and paving section of the client checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-undercity-version-2-and-wall-to-wall-paving-check-proposed-claudeundercity-river):

- Undercity's start, its six bridges and their turns, and its gates in order;
- every city paved from wall to wall, with full speed along every wall;
- Ironforge's feel without its rough strip;
- frame rate and Print Probe.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-23 ~12:00 CEST — Claude / `claude/undercity-river`, Undercity's slime river and no shoulders
>
> - Undercity version 2, the owner's revamp: the canal ring as the slime river and the course along its walkways, crossing it on six bridges (timber and stone by turns), each a sharp turn on, a straight across and a sharp turn off. Six gates, a 5,797-unit lap, spawn on the loop 136 past the finish, 1,340 junctions, `fullSpeedToWalls`. Painted stone-bridge humps; the Trade Quarter is still sunk. Existing fields only.
> - No shoulders on city maps (the owner): every city is paved from wall to wall. Ironforge version 4 gets `fullSpeedToWalls=true`, the one handling change, proposed for Codex review. All five pictures were rebuilt.
> - `test_lua.py --runtime both` PASS; `test_circuit_boundary.py` PASS; `build_city_tracks.py --check` PASS for all five cities, byte-identical in the cloud and on the developer machine (Python 3.10.12, its own extraction and sprites); collision probe 33,720 points, no mismatch; `RaceGrid.pose` on road for all five cities; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/undercity-river` (the worktree previously held `claude/darnassus-undercity` `9143949`, unchanged) |
| Commits | `claude/undercity-river` on `505f054`: Undercity version 2, the wall-to-wall paving, Ironforge version 4, catalog, tests, docs and this handoff; later commits only record checks |
| Push | Owner only, because this session's git proxy refuses the repository: `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/undercity-river` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- Commits are made in a cloud clone with this repository's local identity, then moved as git bundles (`local-artifacts/bundles/`), so the hashes are identical on the developer machine.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`. It never prunes or garbage-collects.
- The bridges' lantern posts (`doodads/lordaeronsummer/props/lanternpost/`) are already in both machines' Warcraft III extractions. Undercity's rebuild command in its sheet now names them.

## Next

1. The owner's reaction to the review picture: the bridges' turns (too sharp or too gentle?), the slime, the lap.
2. Codex: review Undercity version 2, the paving and Ironforge version 4, then install when the owner wants them.
3. If the owner wants the bridges to feel like bridges, the elevation proposal's slopes (ADR 0015) would make the stone humps physical. That remains Codex's decision.
