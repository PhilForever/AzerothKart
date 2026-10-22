# Claude handoff — Capital Cities Cup: Stormwind City Circuit

Prepared 2026-10-22 about 00:45 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the 2026-10-21 ~19:50 handoff at `5c7e5bb`.

**Base:** `claude/ui-flow` at `1b2d3d5`, then the reservation `50d8bf6` on the branch `claude/capital-cup` (the track screen and saved track live on `claude/ui-flow`). Commits on `claude/capital-cup`:

1. `ee75048` — the cup and Stormwind City Circuit: runtime, build pipeline, scenery, tests;
2. `4ffe184` — the fix for Codex's review finding (P2) on `claude/ui-flow`: explicit track and kart choices;
3. `6ad51a1` — the shared docs and the contract proposal;
4. `dec810c` — the build's development sprite cache is written atomically (no picture change);
5. `5c7e5bb` — the first handoff (**the version the owner may have tested on 2026-10-21 evening**, if Codex installed it);
6. `225b128` — the owner-directed street rework: bridges between districts, district paving, walls by what lies beyond them, closed side streets, people, and the street past the Cathedral's steps (no plaza, no fountain solid);
7. `349945c` — the docs for the rework;
8. `78f982f` — float sums added left to right in the model renderers, so the cloud (Python 3.13) and the developer machine (Python 3.10) build identical bytes;
9. this handoff.

`claude/ui-flow` stays at `1b2d3d5`. M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open.

## Owner instructions

- "Your next task is Capital Cities Cup maps: Stormwind City Circuit, Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway, Undercity Slime Circuit. I'll include an image of each map from WoW. Feel free to look them up yourself and I'm giving you creative freedom to design the tracks yourself of course with wc3 assets where possible - and it's important that players recognize where they are when they're playing the track."
- Mid-task: "it would be cool if players actually recognized even the path through the city. We're not going for generic tracks with city assets on the side, we're going for actual paths from the city. Stormwind f.ex could be going from the entrance/valley of heroes through trade quarter over the canal into old town > dwarven district > cathedral > the park > mage quarter and back to the trade district/entrance to end it (like the red line in the picture) cathedral square being the only quarter you actually drive through aside from the trade district to enter the city".
- Answers: Warcraft III source "Both, I believe they're here: C:\Program Files (x86)\Warcraft III" (Reforged 3.0.1.24371; read-only access granted); "Stormwind first (Recommended)"; "Solid landmarks (Recommended)" (changes the Test-Oval-only obstacle rule for city maps; Codex reviews the collision); "Track group for now (Recommended)".
- On the first build (2026-10-21): "Okay, I'll test it tonight. In the meantime. I want it to actually look like going over a bridge between the districts. Not elevation but I can tell from the image that it looks a bit like a normal track, you know what I'm saying? The cathedral in cathedral Square - you should pass right by it, skip the fountain in the middle of the square.Actually make it feel like you're driving through stormwind, not that we've forced an actual racetrack onto stormwind. Maybe you already have the right idea - but at least show me a mockup of what I'm trying to say"
- On the mockup: "Not bad! This is the cathedral. If possible you can brighten it up a bit (image 1) the track should go through like this in image 2. And we don't need purple in the runway, I see it in the mage quarter section. The purple is good but not directly on the runway" (image 1: the old Cathedral sprite; image 2: his screenshot of the Cathedral of Light, white stone, golden roofs, blue carpet up the steps, with a red line coming in from the right, passing the foot of the steps and curving away left round the houses).
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes from Windows and runs the client checks himself; Codex prepares coordinated installs.

## Delivered

[The Stormwind sheet](../art/tracks/stormwind.md) has the route, how it plays, the look, the files, the build and the provenance. In short:

- **The route is the owner's line:** the start grid on the Valley of Heroes approach, through the main gate into the Trade District (finish line), over the Old Town bridge, round the canal's head in the Dwarven District, along the foot of the Cathedral of Light's steps (Cathedral Square and its fountain across the street), over the Park bridge onto the Park bank, past the Mage Quarter, over the Trade District bridge to the finish. Six gates named for the districts. Lap 3,831 units; approach 769.
- **A street circuit:** a 112-wide road, a 20-unit rough kerbside strip ("Slowing off the road"), then the city's walls; the walls are smooth, so karts slide along curves. **No plazas and no solids** since `225b128`: the course's centerline never meets a wall. At the foot of the Cathedral's steps the street ends at the same line as everywhere, but no wall is drawn there (the bottom step is the edge): a client check.
- **Through the city, not a track over it** (`225b128`): three straight stone bridges between districts (slab decks, crenellated parapets with arches, corner lanterns, footmen at most ends); each district paves its own street (Old Town bricks, the Dwarven District's darker cobbles, the Valley's white marble; grey cobbles in the Mage Quarter, its violet only beside the street); pale kerbs and square-tiled pavement out to the walls; walls by what lies beyond them (canal parapets, house fronts, the Park's hedge, timber barriers across five closed side streets); citizens, peasants and the city guard watching.
- **The Cathedral as Stormwind has it:** ×1.68 its Warcraft III size, its moss slate recoloured gold and its dark stone brightened (`wc3render.render`'s new `stone` levels), painted steps with the blue carpet and gold edging up to its doors, two priests and two lamps; the square across the street in white marble with rings, the fountain, lamps, trees and benches.
- **Track screen:** unchanged apart from Stormwind's third fact ("The city's walls are solid; the kerbside slows you").
- **Pipeline for the other five cities:** `scripts/build_city_tracks.py` + `city_layouts.py` (the authored layout as data) + `city_paint.py` + `wc3render.py`, all standard-library Python; `scripts/wc3casc.py` reads the Reforged archives without changing them. New layout features: per-stretch paving, bridges, alleys, steps, squares, landmarks placed facing the course (`front`).

Review pictures: `docs/art/tracks/stormwind_city-overview.png` (the whole city, 4× reduced) and the two Stormwind shots in `docs/art/ui/front-end-review.png`. The owner was sent before/after crops, the steps at 3× and game-camera views of Cathedral Square in chat.

## Reservation

Still **active** for the Capital Cities Cup, because the five other cities follow on this pipeline after the owner's Stormwind check:

- Claude: `Circuit.lua`, `CapitalCities.lua`, `Courses.lua`, `addon/AzerothKart/Assets/Tracks/<City>/`, `tests/test_circuit.lua`, the city scripts and `wc3casc.py`, `docs/art/tracks/`, `Menu.lua`'s track screen and preferences; `scripts/build_wc3_kart.py`'s shared posing helpers (`total`, `matmul`, `track_value`; kart sheets unchanged).
- `UI.lua`, visual regions: `layoutTrack`, `placeTrackMarkers`, the gate pool in `UI.Create`'s visual layout, the effects' dust colour, the HUD's off-road label.
- **Shared, for Codex review:** `UI.SelectTrack`'s course check and background load, the Track button's callback, both TOCs, `tests/run.lua`, `tests/test_ui.lua`, `scripts/validate_project.py`, the shared docs.
- **Not touched:** Physics, Track, MirageRaceway, Input, Loop, Checkpoints, Laps, Race, PeerSession, RaceProtocol, the clock and transport modules, Core, `step`, `UI.Start/Stop/InterruptCombat/ReleaseInput/OnUpdate/HandleEvent/OnCombatEnded`, `keyEvent`, Start refusals and clock/profiling wiring.

## Changes Codex must review

The proposal is in [API_CONTRACTS](../API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog).

1. **Collision beyond the Test Oval** (`Circuit.lua`, new, pure; unchanged since `ee75048`). Surfaces: road within `roadRadius` of the course or on a plaza; `"grass"` to `wallRadius`; `"wall"` beyond and on a solid. `resolveMovement`: the perimeter clamp and the solids' swept boxes exactly as Track.lua's crates, then the street walls: an end point beyond them moves to the nearest drivable point (just inside the nearest capsule), reports a hit, and never moves further from the start than requested (otherwise it stays put), so `checkpointMaxStep=5` holds. A centre that starts outside the street, or inside a solid's clearance, is recovered as before. A 64-unit grid indexes the capsules. **Physics is unchanged**; walls scrub speed as everywhere (×0.25 per contact step), which makes the street walls harsh. Tuning that is Codex's call. Stormwind itself now uses no plazas or solids; the module keeps both (the test fixture exercises them) for the other cities.
2. **`UI.SelectTrack(id)`**: `Courses.available(id)` replaces the two hard-coded ids; the track comes from `Courses.build`. For a course with a background, the UV probe runs before the load (as before); one guarded `SetTexture` loads the course's picture only when it differs from the loaded one; a failed load restores the previous picture and refuses with "<name> background unavailable | Test Oval remains available". The stopped/out-of-combat checks, the state and sample reset and the failure behaviour are unchanged.
3. **Track button callback**: steps through `Courses.next`, skipping a course that refuses to load on that click; it stops if a run is active or combat starts.
4. **Counts**: 71 frames, 164 textures, 80 font strings (unchanged by the rework). `tests/test_ui.lua` changed only its counts (`GATE_STRIPS=8`, menu 60/9/68), the gate-pool assertion and a budget message; `tests/test_menu.lua` its budget and the Track button's three-track cycle. No capture, lifecycle, clock or race assertion was relaxed.
5. **The P2 fix** (`4ffe184`), for Codex's review `a77fe73`: `Menu.Chose(kind, id)` records a successful track or kart choice from the menu screens even when it was already current, and a track choice cancels a saved-track restore still waiting for an open out of combat.
6. **Multiplayer**: SessionTransport's supported track list is Codex's; `stormwind_city` is offered for it, not wired.
7. **Texture size**: Stormwind's scenery is a 2048×2048 TGA (16 MiB raw), the first texture this large in the addon, loaded only when the track is selected. Whether build 70450 loads it is a client check; if not, the track refuses and a smaller or block-compressed picture is the fallback.
8. **`test_circuit.lua`** (`225b128`): the fountain assertions became "no solids or plazas in Stormwind's street" and "the course's centerline never meets a wall"; the gate order, checkpoint walk and Physics drive are unchanged.

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8) at `349945c` and on the developer machine's Linux shell (Python 3.10.12) at `349945c` (no Lua change since): both runtimes; mock counts 71/164/80; `test_circuit`: Stormwind 3,831-unit loop, six gates in order, 0 solids |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** on the developer machine at `78f982f`, from files freshly extracted from the owner's install with [the documented commands](../art/tracks/stormwind.md#rebuilding) (now including the unit models) and a fresh sprite cache filled over three calls (the shell stops each command after three minutes): `CapitalCities.lua`, `Background.tga` 16,777,234 bytes sha256 `078a7805bccdadd8b88a909d5c37b013aa51e9d0d7981134c04f7a9db12f4ebb`, `Preview.tga` 1,048,594 bytes sha256 `63f85210560f666f2f8cb5f9a930a681a748ac90a4c4e8a7f523fa8348bedf24`. The cloud build at `78f982f` wrote the same bytes from a fresh `sprite-v3` cache |
| The same check at `349945c` | **STALE** on the developer machine by 14 texels (the two priests): Python 3.12 changed `sum()` for floats. Fixed in `78f982f` (left-to-right sums); the cloud's 3.13 priest render then matched the machine's 3.10 render exactly |
| `python scripts/build_wc3_kart.py --source … --check` | **CHECK PASS** on the developer machine (Python 3.10) for all five kart sheets before `78f982f`, and for the Goblin Mortar Trike and the Gyrocopter after it |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail, on both machines |
| `scripts/preview_ui.py` | Regenerated `docs/art/ui/front-end-review.png`; layout only, stand-in fonts |
| Layout validation in the generator | PASS: gates span wall to wall and guard one stretch; stretches keep a wall between them; spawn on the road; the street inside the world; no landmark over the street |
| Review | Crops of Cathedral Square, the steps at 3×, game-camera views along that stretch, the Mage Quarter and the overview inspected and sent to the owner |

**NOT RUN:**

- anything in WoW Forever: loading the 2048-square TGA, the preview, the drive, the walls' feel (and the undrawn edge at the Cathedral's steps), the camera at the map's edges, frame rate and memory;
- any install of `claude/capital-cup`;
- a trial merge with Codex's latest. The cup touches the same shared lists as `claude/ui-flow` (TOCs, `tests/run.lua`, the UI-test loader, the validator, API_CONTRACTS, ARCHITECTURE, CHANGELOG) plus `UI.SelectTrack` and the Track button;
- multiplayer;
- a kart `--check` in the cloud (the kart sources are on the developer machine only); by construction the left-to-right sums give the 3.10 bytes on every version.

## Client check (owner; NOT RUN; after a coordinated install)

Fully restart the client: `Circuit.lua`, `CapitalCities.lua`, `Courses.lua` and the `Assets/Tracks/Stormwind/` pictures are new files. Then [the Stormwind check](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-stormwind-city-circuit-check-proposed-claudecapital-cup):

1. the track screen's cups, Stormwind's preview and the five disabled cities;
2. whether the 2048-square scenery loads (a refusal names the background);
3. a full lap: is every district recognisable, do the bridges read as bridges between districts, does it feel like Stormwind's streets? Anything drawn over the street, seams or misplaced walls?
4. the walls: stop, slide, speed loss; the kerbside strip slows; the edge at the foot of the Cathedral's steps;
5. camera at the edges, frame rate on selection and while driving, Print Probe 71/164/80;
6. the Track button's cycle and the saved track after `/reload`.

## Deployment

Claude installed nothing and did not change the live AddOns folder. Per INTEGRATION_STATUS, Codex prepares the next coordinated install from reviewed, integrated source, and the owner decides.

**2026-10-22 ~01:00 CEST, owner:** he opened the game and found no Stormwind track. Read-only inspection of the live `AddOns\AzerothKart` folder: it holds the build from the night of 2026-10-20/21 (file contents match `8195da9` for `UI.lua`, `8f66c5a` for `Core.lua`/`TransportProbe.lua`, `c6e1b5e` for `Presentation.lua`, `b1cd42c` for `Physics.lua`, `de7a63e` for the TOCs); no `Menu.lua`, `Courses.lua`, `Circuit.lua` or `CapitalCities.lua`, no Stormwind pictures, two kart sheets. All five commits are ancestors of `claude/capital-cup`. Claude offered to install the branch; **the owner chose to wait for Codex's coordinated install.** That install needs a full client restart (new files).

## Pending PROGRESS ledger entries (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-21 ~19:50 CEST — Claude / `claude/capital-cup`, Capital Cities Cup: Stormwind City Circuit
>
> - From `claude/ui-flow` `1b2d3d5`: the Capital Cities Cup on the track screen; Stormwind City Circuit ready, five cities coming soon. Pure `Circuit.lua` street circuits (capsule road and walls, plazas, solids), generated `CapitalCities.lua`, `Courses.lua` catalog; `UI.SelectTrack` and the Track button generalised (Codex review). Scenery from Warcraft III Reforged: 2048² `Background.tga` sha256 `321e30c4…c6ec4`, 512² `Preview.tga` `87c82515…3742d`.
> - Fix for Codex's review `a77fe73` P2: explicit menu choices are remembered and supersede a waiting restore.
> - `test_lua.py --runtime both` PASS on both machines (44 files); `build_city_tracks.py --check` PASS in the cloud and on the developer machine from a fresh extraction of the owner's install; validator: only the 2 pre-existing PROGRESS links. Counts 71/164/80.
> - **NOT RUN:** client loading of the 2048² TGA, the drive and appearance; install; combined trial merge.
>
> ### 2026-10-22 ~00:45 CEST — Claude / `claude/capital-cup`, Stormwind through its streets
>
> - Owner-directed rework (`225b128`, docs `349945c`): bridges between districts, district paving, walls by what lies beyond, closed side streets, people; the street runs past the foot of a white, gold-roofed Cathedral's carpeted steps, the square and fountain across the street; no plazas or solids; Mage Quarter road grey. Lap 3,831. `Background.tga` sha256 `078a7805…f4ebb`, `Preview.tga` `63f85210…edf24`.
> - `78f982f`: renderers add float sums left to right (Python 3.12's compensated `sum()` broke cross-machine identity for skinned models); kart sheets unchanged.
> - `test_lua.py --runtime both` PASS on both machines; `build_city_tracks.py --check` PASS on the developer machine (fresh extraction incl. unit models, fresh cache) at `78f982f`; kart `--check` PASS there; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install; combined trial merge.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/capital-cup` at this commit |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/capital-cup` (the branch is not on origin yet) |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- `local-artifacts/third-party/wc3-reforged/` (git-ignored) holds an earlier, partial extraction; use the documented commands for a complete one. `local-artifacts/bundles/` holds the transfer bundles (`capital-cup-rework.bundle`, `capital-cup-sums.bundle` this session). The check's extraction and sprite caches sit in the machine shell's own scratch space (`akcheck/`), outside the project.
- The untracked `Claude outputs/` folder, created by the desktop app, is still left for the owner.
- Commits are made in a cloud clone with this repository's local identity, then moved here as git bundles and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable.

## Work in progress: Ironforge Grand Prix (mockup, not selectable)

The owner approved Stormwind ("Stormwind looks good. Start work on Ironforge.") and sent his in-game Ironforge map with his red line; asked, he chose a route "Through the Forge". The mockup commit after this handoff's adds:

- **The course** (`city_layouts.py`, `IRONFORGE`): his line, clockwise, from a short start spur inside the Gates (Dun Morogh's snow beyond them) up the Commons' ring, round the north (Mystic Ward, the Forlorn Cavern's lake, past the Hall of Explorers), into the Great Forge between its two forges and round the southern one, out past Tinker Town, through the Military Ward and back along the Commons. Seven gates named for the districts; the finish is in the Commons. Lap 7,077 units, approach 369. Where his line touches itself north-east of the Forge, the two passes are moved apart so a wall stands between them. Geometry validated; data generated into `CapitalCities.lua`; `Courses.lua` still lists `ironforge_gp` as coming soon, so nothing changes in the game.
- **Underground painting** (`city_paint.py`, all optional city keys, Stormwind's bytes unchanged): `rock` (the mountain outside open floors and a band round the course, cut-away tops darkening inward, masonry faces toward the camera), `lava` (pools, crust, rims, banks and glow), `rings` (stone ridges over water or lava), `lights` and per-model `light` pools, `wall_styles` per city, tile shading by channel and saturation, district `density` and per-model `limit`s in the fill.
- **Scenery** from Warcraft III Reforged's Dungeon, Underground, Lordaeron Winter, Northrend and Icecrown terrain and doodads, dwarven units and buildings (extraction commands to be documented with the Ironforge sheet). `--check` passes for both cities in the cloud.

**Open with the owner:** whether the 7,077-unit lap (about 1.8 × Stormwind's) is acceptable, and the north-east separation. Then: the Ironforge sheet and sources, the menu entry and preview, tests, the device check and docs.

## Next

1. The owner's verdict on the Ironforge mockup, then finish it (above); his Stormwind check in the client when an install exists.
2. Then Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit on the same pipeline, each traced on the owner's map of that city.
3. Codex: review the collision and `SelectTrack` items above, and integrate `claude/capital-cup` (which contains `claude/ui-flow` and the P2 fix) when approved.
