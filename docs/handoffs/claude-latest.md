# Claude handoff — Capital Cities Cup: Stormwind City Circuit

Prepared 2026-10-21 about 19:50 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner).

**Base:** `claude/ui-flow` at `1b2d3d5`, then the reservation `50d8bf6` on the new branch `claude/capital-cup` (the track screen and saved track live on `claude/ui-flow`). This session's commits on `claude/capital-cup`:

1. `ee75048` — the cup and Stormwind City Circuit: runtime, build pipeline, scenery, tests;
2. `4ffe184` — the fix for Codex's review finding (P2) on `claude/ui-flow`: explicit track and kart choices;
3. `6ad51a1` — the shared docs and the contract proposal;
4. `dec810c` — the build's development sprite cache is written atomically (no picture change);
5. this handoff.

`claude/ui-flow` stays at `1b2d3d5`. M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open.

## Owner instructions

- "Your next task is Capital Cities Cup maps: Stormwind City Circuit, Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway, Undercity Slime Circuit. I'll include an image of each map from WoW. Feel free to look them up yourself and I'm giving you creative freedom to design the tracks yourself of course with wc3 assets where possible - and it's important that players recognize where they are when they're playing the track."
- Mid-task: "it would be cool if players actually recognized even the path through the city. We're not going for generic tracks with city assets on the side, we're going for actual paths from the city. Stormwind f.ex could be going from the entrance/valley of heroes through trade quarter over the canal into old town > dwarven district > cathedral > the park > mage quarter and back to the trade district/entrance to end it (like the red line in the picture) cathedral square being the only quarter you actually drive through aside from the trade district to enter the city".
- Answers: Warcraft III source "Both, I believe they're here: C:\Program Files (x86)\Warcraft III" (Reforged 3.0.1.24371; read-only access granted); "Stormwind first (Recommended)"; "Solid landmarks (Recommended)" (changes the Test-Oval-only obstacle rule for city maps; Codex reviews the collision); "Track group for now (Recommended)".
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes from Windows and runs the client checks himself; Codex prepares coordinated installs.

## Delivered

[The Stormwind sheet](../art/tracks/stormwind.md) has the route, how it plays, the look, the files, the build and the provenance. In short:

- **The route is the owner's line:** the start grid on the Valley of Heroes approach, through the main gate into the Trade District (finish line), over the canal along Old Town, round the canal's head in the Dwarven District, across Cathedral Square past its fountain, over the canal onto the Park bank, past the Mage Quarter, back over the canal to the Trade District. The canals stay on the left all lap; six gates named for the districts ("Next gate: Old Town" on the HUD). Lap 3,766 units; approach 769.
- **A street circuit:** a 112-wide road, a 20-unit rough kerbside strip ("Slowing off the road"), then the city's walls; the walls are smooth, so karts slide along curves. Cathedral Square is an open paved plaza with the fountain as the one solid.
- **Recognisable districts**, drawn from Warcraft III Reforged art: blue-roofed timber houses and market stalls in the Trade District; red and blue roofs, SI:7 and the Pig and Whistle in Old Town; forges in the dark Dwarven District; the Cathedral of Light over a marble square; the Park's trees; violet Dalaran domes and the Wizard's Sanctum's spire in the Mage Quarter; the Valley's hero statues, lakes and gate towers with blue banners; canals with quays, islands with guard towers and arched bridges; a stone balustrade with pillars along every street edge.
- **Track screen:** the list is grouped by cup (*Proving Grounds*: Mirage Raceway, Test Oval; *Capital Cities Cup*: Stormwind City Circuit and five cities marked "(soon)", disabled), with Stormwind's own preview picture and facts. The bar's Track button cycles Test Oval → Mirage Raceway → Stormwind City.
- **Pipeline for the other five cities:** `scripts/build_city_tracks.py` + `city_layouts.py` (the authored layout as data) + `city_paint.py` + `wc3render.py`, all standard-library Python; `scripts/wc3casc.py` reads the Reforged archives without changing them. The generator validates the layout before painting and `--check` verifies the committed bytes.

Review pictures: `docs/art/tracks/stormwind_city-overview.png` (the whole city, 4× reduced) and two new shots in `docs/art/ui/front-end-review.png` (the track screen with Stormwind chosen; the Valley of Heroes in the race view).

## Reservation

Still **active** for the Capital Cities Cup, because the five other cities follow on this pipeline after the owner's Stormwind check:

- Claude: `Circuit.lua`, `CapitalCities.lua`, `Courses.lua`, `addon/AzerothKart/Assets/Tracks/<City>/`, `tests/test_circuit.lua`, the city scripts and `wc3casc.py`, `docs/art/tracks/`, `Menu.lua`'s track screen and preferences.
- `UI.lua`, visual regions: `layoutTrack`, `placeTrackMarkers`, the gate pool in `UI.Create`'s visual layout, the effects' dust colour, the HUD's off-road label.
- **Shared, for Codex review:** `UI.SelectTrack`'s course check and background load, the Track button's callback, both TOCs, `tests/run.lua`, `tests/test_ui.lua`, `scripts/validate_project.py`, the shared docs.
- **Not touched:** Physics, Track, MirageRaceway, Input, Loop, Checkpoints, Laps, Race, PeerSession, RaceProtocol, the clock and transport modules, Core, `step`, `UI.Start/Stop/InterruptCombat/ReleaseInput/OnUpdate/HandleEvent/OnCombatEnded`, `keyEvent`, Start refusals and clock/profiling wiring.

## Changes Codex must review

The proposal is in [API_CONTRACTS](../API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog).

1. **Collision beyond the Test Oval** (`Circuit.lua`, new, pure). The owner chose solid landmarks for the city maps. Surfaces: road within `roadRadius` of the course or on a plaza; `"grass"` to `wallRadius`; `"wall"` beyond and on a solid. `resolveMovement`: the perimeter clamp and the solids' swept boxes exactly as Track.lua's crates, then the street walls: an end point beyond them moves to the nearest drivable point (just inside the nearest capsule), reports a hit, and never moves further from the start than requested (otherwise it stays put), so `checkpointMaxStep=5` holds. A centre that starts outside the street, or inside a solid's clearance, is recovered as before. A 64-unit grid indexes the capsules (about 20,000 move+surface calls in 0.26 s in Lupa's Lua 5.5 in the cloud). **Physics is unchanged**; walls scrub speed as everywhere (×0.25 per contact step), which makes the street walls harsh. Tuning that is Codex's call; a softer wall response would be a Physics change.
2. **`UI.SelectTrack(id)`**: `Courses.available(id)` replaces the two hard-coded ids; the track comes from `Courses.build`. For a course with a background, the UV probe runs before the load (as before); one guarded `SetTexture` loads the course's picture only when it differs from the loaded one; a failed load restores the previous picture and refuses with "<name> background unavailable | Test Oval remains available". The stopped/out-of-combat checks, the state and sample reset and the failure behaviour are unchanged.
3. **Track button callback**: steps through `Courses.next`, skipping a course that refuses to load on that click; it stops if a run is active or combat starts.
4. **Counts**: 71 frames, 164 textures, 80 font strings (eight track buttons and two cup headings, four more gate strips), all created with the window. `tests/test_ui.lua` changed only its counts (`GATE_STRIPS=8`, menu 60/9/68), the gate-pool assertion (eight strips, the oval's extra four hidden) and a budget message with the actual numbers; `tests/test_menu.lua` its budget and the Track button's three-track cycle. No capture, lifecycle, clock or race assertion was relaxed.
5. **The P2 fix** (`4ffe184`), for Codex's review `a77fe73`: `Menu.Chose(kind, id)` records a successful track or kart choice from the menu screens even when it was already current, and a track choice (or a track change from the bar, now watched from creation) cancels a saved-track restore that is still waiting for an open out of combat. UI's transactions are unchanged; an untouched failed restore still keeps the saved choice. Regressions for the review's three paths plus the bar button fail without the fix (checked by reverting it locally) and pass with it.
6. **Multiplayer**: SessionTransport's supported track list is Codex's; `stormwind_city` is offered for it, not wired.
7. **Texture size**: Stormwind's scenery is a 2048×2048 TGA (16 MiB raw), the first texture this large in the addon. It is loaded only when the track is selected, replacing Mirage's in the one shared background texture. Whether build 70450 loads it is a client check; if not, the track refuses and a smaller or block-compressed picture is the fallback.

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8) and on the developer machine's Linux shell (Python 3.10.12, Lupa 2.8), at `6ad51a1`: 44 Lua files parsed per runtime; mock counts 71/164/80; `test_circuit`: street walls, plazas and solids, Stormwind's six gates in order, one solid |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** in the cloud with no sprite cache, and on the developer machine at `dec810c` from files freshly extracted from the owner's install with [the documented commands](../art/tracks/stormwind.md#rebuilding) (1,374 files): `CapitalCities.lua`, `Background.tga` 16,777,234 bytes sha256 `321e30c438d5641f7735e5a8b83b34c59a8b395da69873d6a23b407c018ec6c4`, `Preview.tga` 1,048,594 bytes sha256 `87c825150cb6f26c5b8213703b5245b4132138cf9b499429b036e7371a43742d`. The machine's shell stops each command after three minutes, so that run filled the sprite cache over three calls |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail, on both machines |
| `scripts/preview_ui.py` | Regenerated `docs/art/ui/front-end-review.png` with the two Stormwind shots; layout only, stand-in fonts |
| Layout validation in the generator | PASS: gates span wall to wall and guard one stretch; stretches keep a wall between them; spawn on the road; the fountain inside the square; the street inside the world; no landmark over the street |
| Review | Camera-sized crops along the whole lap and the overview were inspected; fixes made during the session: the street model (walls instead of rough water and open blocks), canals hugging the street, bridges, district density and palettes, the Mage Quarter's spires, the Dwarven District's tone |

**NOT RUN:**

- anything in WoW Forever: loading the 2048-square TGA, the preview, the drive, the walls' feel, the camera at the map's edges, frame rate and memory;
- any install of `claude/capital-cup`;
- a trial merge with Codex's latest (`codex/combined-review` `a77fe73` and the backend branches below it). The cup touches the same shared lists as `claude/ui-flow` (TOCs, `tests/run.lua`, the UI-test loader, the validator, API_CONTRACTS, ARCHITECTURE, CHANGELOG) plus `UI.SelectTrack` and the Track button; expect the same union conflicts as the reviewed `claude/ui-flow` trial, with the cup's three modules after `MirageRaceway`;
- multiplayer.

## Client check (owner; NOT RUN; after a coordinated install)

Fully restart the client: `Circuit.lua`, `CapitalCities.lua`, `Courses.lua` and the `Assets/Tracks/Stormwind/` pictures are new files. Then [the Stormwind check](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-stormwind-city-circuit-check-proposed-claudecapital-cup):

1. the track screen's cups, Stormwind's preview and the five disabled cities;
2. whether the 2048-square scenery loads (a refusal names the background);
3. a full lap: is every district recognisable? Anything drawn over the street, seams or misplaced walls?
4. the walls and the fountain: stop, slide, speed loss; the kerbside strip slows;
5. camera at the edges, frame rate on selection and while driving, Print Probe 71/164/80;
6. the Track button's cycle and the saved track after `/reload`.

## Deployment

Claude installed nothing and did not touch the live AddOns folder. Per INTEGRATION_STATUS, Codex prepares the next coordinated install from reviewed, integrated source, and the owner decides.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-21 ~19:50 CEST — Claude / `claude/capital-cup`, Capital Cities Cup: Stormwind City Circuit
>
> - From `claude/ui-flow` `1b2d3d5`: the Capital Cities Cup on the track screen; Stormwind City Circuit ready, five cities coming soon. Pure `Circuit.lua` street circuits (capsule road and walls, plazas, solids), generated `CapitalCities.lua`, `Courses.lua` catalog; `UI.SelectTrack` and the Track button generalised (Codex review). Scenery from Warcraft III Reforged: 2048² `Background.tga` sha256 `321e30c4…c6ec4`, 512² `Preview.tga` `87c82515…3742d`.
> - Fix for Codex's review `a77fe73` P2: explicit menu choices are remembered and supersede a waiting restore.
> - `test_lua.py --runtime both` PASS on both machines (44 files); `build_city_tracks.py --check` PASS in the cloud and on the developer machine from a fresh extraction of the owner's install; validator: only the 2 pre-existing PROGRESS links. Counts 71/164/80.
> - **NOT RUN:** client loading of the 2048² TGA, the drive and appearance; install; combined trial merge.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/capital-cup` at this commit |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/capital-cup` (the branch is not on origin yet) |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- `local-artifacts/third-party/wc3-reforged/` (git-ignored) holds an earlier, partial extraction (it lacks the tree texture the build now needs; use the documented commands for a complete one); `local-artifacts/bundles/` the transfer bundles. The check's extraction sat in the machine shell's own scratch space, outside the project.
- The untracked `Claude outputs/` folder, created by the desktop app, is still left for the owner.
- Commits are made in a cloud clone with this repository's local identity, then moved here as git bundles and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable.

## Next

1. The owner's Stormwind check in the client (above). Its answers decide the scale, wall feel and art direction for the other five.
2. Then Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit on the same pipeline, each traced on the owner's map of that city.
3. Codex: review the collision and `SelectTrack` items above, and integrate `claude/capital-cup` (which contains `claude/ui-flow` and the P2 fix) when approved.
