# Claude handoff — Goblin Pod Racer, start signs and the kart outline

Prepared 2026-10-23 at about 19:45 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner).

This supersedes the Undercity river handoff (`claude/undercity-river` `e83c889`). Codex approved that work, pushed it and integrated it (merge `d3fd99d`, docs `de4b291`).

**Base:** `de4b291`, Codex's docs commit on `d3fd99d`, the installed runtime. The new branch is **`claude/podracer-arrows-outline`**; its commits are listed under [Branch, commits and workspace](#branch-commits-and-workspace).

## Owner instructions

He wrote "Looks good. Codex has approved and is now working on enhancing the single player experience. Your Next tasks:", then:

1. "On tracks that start outside of the "loop" - add an arrow indicator for left or right outside the track (wc3 asset?) helping users take the correct turn at the start of a race."
2. "Create/add the goblin pod racer (see image) - replace it with our first kart (the only one that's not a wc3 asset)". His picture shows two red, rope-bound rocket pods with shark faces, roped to a goblin on a two-wheeled cart.
3. "Visually it can sometimes be difficult to see your cart, add an option in the settings to enable an outline of your own cart when driving (like a bright yellow line or something)".

The standing instructions still hold:

- no merge into `main`;
- no claim of in-game verification without the actual client;
- leave the simulation-control functions in `UI.lua` alone;
- the owner pushes and runs the client checks; Codex prepares coordinated installs.

## Scope (reserved and changed)

Codex's `codex/solo-highscores` reservation covers `UI.lua`'s successful Start context and solo `OnUpdate` finish accounting, `Menu.lua`'s home/Highscores/result notice, `Core.lua`, the TOCs, `tests/run.lua` and parts of `tests/test_menu.lua`/`test_ui.lua`. My regions stay clear of those:

- **`addon/AzerothKart/UI.lua`, visual regions only:**
  - `sizeKart`;
  - the new local `applyKartOutline`, called from `loadKartSprite` and `UI.SelectKart` after the selection;
  - the new `UI.SetKartOutline`;
  - the outline's placement in the visual body of `render`, next to the kart's;
  - one texture created in `UI.Create` beside `UI.kart`.

  No `step`, `Start`/`Stop`, `OnUpdate`, input, clock, lifecycle or selection-transaction change.
- **`addon/AzerothKart/Menu.lua`:**
  - the pod racer's blurb and credit (`Menu.KARTS`) and the How to Play credits;
  - the Settings screen: a new check, with the checks below it moved down;
  - `Menu.SetOutline`;
  - one line each in `readPreferences`, `save` and `Menu.Create`.
- **`addon/AzerothKart/Presentation.lua`:** the kart table (`goblin_drag_car` is now a sheet; each sheet names its `outline`; `KART_OUTLINE`). The drag car's effects override is removed.
- **Assets:**
  - new: `Assets/Karts/GoblinPodRacer.tga` and `Assets/Karts/Outlines/*.tga` (ten);
  - removed: `Assets/Karts/GoblinDragCar.tga`;
  - replaced: the Stormwind, Ironforge, Orgrimmar and Darnassus `Background.tga`/`Preview.tga`.
- **Scripts:**
  - new: `wowcasc.py`, `wowmodel.py`, `build_kart_outlines.py`;
  - changed: `build_wc3_kart.py` (`--wow`, `WOW_VEHICLES`, the review helpers), `city_layouts.py` (start signs), `build_mirage_background.py` (review views only), `validate_project.py`;
  - removed: `build_kart_sprites.py`.
- **Tests:** `tests/test_presentation.lua`, `tests/test_ui.lua`, `tests/test_menu.lua`. Details are under [Tests performed](#tests-performed).
- **Docs:**
  - new: kart sheets `goblin-pod-racer.md` and `outlines.md`;
  - updated: `goblin-drag-car.md` (retired), `roster.md`, `goblin-mortar-trike.md` (one line), the four city sheets, `ASSET_SOURCES.md`, `ASSETS.md`, `ARCHITECTURE.md`, `API_CONTRACTS.md`, the ADR 0009 addendum, `drift-boost.md`, `MIRAGE_RACEWAY.md`, `mirage-background.md`, `ui/front-end.md`, `README.md`, `README_ADDON.md`, `CHANGELOG.md` and `tests/MANUAL_CLIENT_CHECKLIST.md`;
  - images: the review PNGs, the four overview PNGs and sources lists, and the Mirage views PNG (now drawing the default kart).

`RaceGrid.lua`, `CapitalCities.lua`, `Circuit.lua`, `Courses.lua`, the physics and the multiplayer modules are untouched.

## Delivered

### 1. Start signs

Stormwind, Ironforge, Orgrimmar and Darnassus start on a road off the loop. Where it joins the loop, Warcraft III's goblin racing arrow post stands beyond the far wall, its red arrow pointing the race's way ([review](../art/tracks/start-signs-review.png)). The posts are `war3.w3mod:_de.w3mod:doodads/lordaeronsummer/props/goblinracingarrowpost/goblinracingarrowpost{0,2}.mdx`.

- **The four signs:**
  - Stormwind: in the corner of the bend, north-east.
  - Ironforge: across the street from the gate hall's road, north-west.
  - Orgrimmar: on the tip of the island where the canyon road merges, north-east (keep right).
  - Darnassus: straight ahead of the Warrior's Terrace road, north-west.
- **Why diagonal arrows:** a board facing the karts' north-looking camera can point east, west or diagonally north, but not straight north. Each sign takes the nearest of those to the loop's direction at the junction.
- **Readability:**
  - four times the scenery size;
  - the arrow's dark red paint brightened (`recolor` on that saturated red only);
  - a 50-unit clearing kept free of generated buildings, trees and trim (`reserved`).
- **No data change:** pictures only; `CapitalCities.lua` is unchanged. Undercity starts on its loop and has no sign.

### 2. Goblin Pod Racer

It is World of Warcraft's own goblin rocket car, Mirage Raceway's: `creature/goblinrocketcar/goblinrocketcar.m2`, from the owner's WoW Forever client. It takes the drag car's slot ([asset sheet](../art/karts/goblin-pod-racer.md)).

- **New tools:**
  - `scripts/wowcasc.py` reads the client read-only, by FileDataID.
  - With `--cdn` it fetches files the client has not downloaded, through the install's own CDN indices, as the client does. Four of the six files needed it, on both machines.
  - `scripts/wowmodel.py` reads M2 and BLP2.
  - `build_wc3_kart.py --wow` renders the car like every kart: 64 headings, quad 44, pivot (1.2, 0), 36 units long.
- **Effects:** drift dust from the cart's wheels; boost flame and soot from the pods' tails.
- **Slot:** the id `goblin_drag_car` is kept, so saved choices and RaceGrid's kart code 9 still work. It is shown as **Goblin Pod Racer**.
- **The old drag car:** its 64×128 sprite and `build_kart_sprites.py` are removed (still in history at `de4b291`). Two of that script's review helpers moved into `build_wc3_kart.py`.

### 3. Outline my kart

A new Settings check, off by default and saved as `preferences.outline` ([sheet](../art/karts/outlines.md)).

- **Outline sheets:** each kart sheet has a 512×512 white outline sheet, derived by `scripts/build_kart_outlines.py` from the sheet alone. The line is 5 kart texels wide plus a 1-texel fade round the opaque body, never over it.
- **Drawing:** `UI.kartOutline` is drawn over the kart (OVERLAY sublevel 1, under the front flames) in bright yellow, with the kart's frame crop, quad and position.
- **Loading:** the current kart's sheet loads once per kart while the setting is on. A refused load hides the line and is not retried.
- **No outline:** single images and the primitive show none, and neither does any opponent.

## Changes Codex must review

1. **Object counts:** +1 texture (the outline) and +1 frame +2 font strings (the Settings check). The explicit budget becomes 80/167/83 on this branch.
   - **Expected textual conflict with `codex/solo-highscores`:** the budget assertion in `tests/test_menu.lua` (that branch says 85/166/133). Merged, it should read **86/167/135**.
   - `tests/test_ui.lua` keeps the outline's counts in new lines (`UI_TEXTURES` 112, `OUTLINE_CHECK_FRAMES/FONTS`), away from that branch's `MENU_*` line.
   - The draw-layer assertions now expect two explicit scene sublevels: the grass and the outline.
2. **`UI.lua`:** see the reserved regions above. Please check the outline's placement next to the kart's in `render` and the call order in `SelectKart` (outline, then size, effects, render).
3. **A single kart path without a shipped kart:** no kart is a single image any more. The UI tests register a test-only single image (`singleImageKart`) where they used the drag car, keeping the rotated path and the sheet/single-image rollback covered. The drag car's landmark assertions in `test_presentation.lua` are removed.
4. **Kart id:** `goblin_drag_car` now names the pod racer. Renaming it would touch `RaceGrid.lua`'s codes and your tests; I left it.
5. **Assets and rights:** a World of Warcraft model is a new source.
   - The ADR 0009 addendum and the source ledger rows are proposed: same terms, Blizzard, redistribution unresolved.
   - The start signs are Warcraft III's own, as for the cities.
6. **Install:** these files change.
   - New: `GoblinPodRacer.tga` and ten `Outlines/*.tga`.
   - Removed: `GoblinDragCar.tga`.
   - Replaced: eight city pictures, `Menu.lua`, `UI.lua` and `Presentation.lua`.
   - New files need a full client restart. The removed file should be deleted from the installed folder.

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8): 60 files parsed; the full suite on Lua 5.1 and 5.4. New checks: every outline sheet; the outline's UI behaviour (off and unloaded by default, one load per kart, follows frame/quad/pose through a drive, refusal hidden and not retried, single image none, switch-off); the setting, its save and its return after reload. The pod racer's sheet passes the sheet checks with its coverage floor (0.08) |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** in the cloud for `CapitalCities.lua` and all ten pictures: Stormwind `ec016e7e…`, Ironforge `5cf1e688…`, Orgrimmar `3abf44b2…`, Darnassus `80a6715e…`; Undercity unchanged `caedb2c9…` |
| `python scripts/build_wc3_kart.py --wow WOW --vehicle goblin_drag_car` | Sheet `88a0dfbd…af5c2ccb`, 1,548–1,807 opaque texels per frame. The six source files' hashes match on both machines (the developer machine extracted them with this `wowcasc.py --cdn`) |
| `python scripts/build_kart_outlines.py` | Ten sheets; every frame has a line, a clear border and no line over the kart |
| `python scripts/build_mirage_background.py --check` | **CHECK PASS** (its review views now draw the trike's sheet) |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| Review | Follow-camera views of the four junctions with the pod racer; the pod racer beside three other karts; every kart with and without its outline |

The developer machine's check (Python 3.10.12, its own Warcraft III and WoW extractions) is recorded in the next commit.

**NOT RUN:** the client (the pod racer, the signs, the outline, performance), any install, and multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

See [the new section of the client checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-goblin-pod-racer-start-signs-and-kart-outline-check-proposed-claudepodracer-arrows-outline):

- the pod racer at every heading, with its effects;
- whether each start sign's arrow reads in time to choose the turn;
- the outline: on, off, kept after `/reload`, and following kart changes;
- Print Probe's counts.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-23 ~19:45 CEST — Claude / `claude/podracer-arrows-outline`, pod racer, start signs, kart outline
>
> - Goblin Pod Racer: World of Warcraft's goblin rocket car (Mirage Raceway's), from the owner's Forever client via the new read-only `wowcasc.py` (`--cdn` for files the client streams) and `wowmodel.py`. It takes the drag car's slot (id kept); the drag car sprite and its painter are removed.
> - Start signs: Warcraft III goblin racing arrow posts beyond the far wall where Stormwind's, Ironforge's, Orgrimmar's and Darnassus's start roads join the loop, pointing the race's way. Pictures only.
> - Outline my kart: a Settings check (off by default, saved). Each kart sheet has a 512×512 outline sheet; the player's own kart gets a bright yellow line. +1 texture, +1 frame, +2 font strings (80/167/83).
> - `test_lua.py --runtime both` PASS; all city `--check` PASS; the outline and sheet builds validate; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/podracer-arrows-outline` (the worktree previously held `claude/undercity-river` `e83c889`, unchanged) |
| Commits | `claude/podracer-arrows-outline` on `de4b291`: the pod racer, the start signs, the outline, tests, docs and this handoff; later commits only record checks |
| Push | Owner only, because this session's git proxy refuses the repository: `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/podracer-arrows-outline` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- Commits are made in a cloud clone with this repository's local identity, then moved as git bundles (`local-artifacts/bundles/`), so the hashes are identical on the developer machine.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`. It never prunes or garbage-collects.
- **Warcraft III files:** the goblin racing arrow posts come from the same Reforged install; each city sheet's rebuild commands now name them.
- **World of Warcraft files:** `wowcasc.py` read them from the owner's `World of Warcraft` folder without writing to it. They are not stored in Git.

## Next

1. The owner's reaction:
   - the pod racer's size (it is the longest kart);
   - whether the signs read in time;
   - the outline's colour and width (one constant and one script setting).
2. Codex: review, then install when the owner wants it; resolve the one expected counts conflict with `codex/solo-highscores`.
3. Optionally rename the `goblin_drag_car` id (Codex's grid codes and tests).
