# Claude handoff — Orgrimmar Canyon Rush (the third city)

Prepared 2026-10-22 about 22:00 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the four-kart handoff on `claude/kart-roster-wc3` at `8cc2031`, which is not yet reviewed; it remains in history and this branch builds on it.

**Base:** `claude/kart-roster-wc3` at `8cc2031` (the four Warcraft III karts, itself on Codex's `codex/ironforge-polish-review` `1a70d6e`). Orgrimmar touches `Menu.lua` too, so it is stacked on the karts rather than beside them: review and integrate the karts first, then this. New branch **`claude/orgrimmar`**:

1. Orgrimmar Canyon Rush: layout, painter options, picture, catalog, menu, tests, docs and this handoff (one commit).

`claude/kart-roster-wc3` stays at `8cc2031`. No milestone or multiplayer gate changed.

**Scope (reserved and changed):** `scripts/city_layouts.py` (the `ORGRIMMAR` layout; `prop()` gains optional `cut`/`alpha_shadow`), `scripts/city_paint.py` (optional `Strata`, `pits`, `rock.face_texture`, `land_wall`, the palisade/spike wall styles, per-model `cut`/`alpha_shadow`; pits painted before lava), `scripts/wc3render.py` (`render(..., alpha_shadow=False)`), `addon/AzerothKart/CapitalCities.lua` (generated: the `orgrimmar_canyon` entry added; Stormwind's and Ironforge's entries unchanged), `addon/AzerothKart/Assets/Tracks/Orgrimmar/{Background,Preview}.tga` (new), `addon/AzerothKart/Courses.lua` (the Orgrimmar entry: no longer `soon`), `addon/AzerothKart/Menu.lua` (`Menu.TRACKS` copy and `PREVIEW_CELLS.orgrimmar` only), `tests/test_circuit.lua` (catalog counts/cycle and a new Orgrimmar block), `tests/test_menu.lua` (the Track button cycle), `tests/test_ui.lua` (Orgrimmar added to the gate-pool fixture; a comment), `scripts/validate_project.py` (required files), `docs/art/tracks/orgrimmar*` (new), `docs/art/ui/front-end-review.png`, `docs/art/ASSET_SOURCES.md`, `docs/API_CONTRACTS.md`, `docs/TRACKS.md`, `docs/TEST_PLAN.md`, `docs/INDEX.md`, `docs/ASSETS.md`, `README.md`, `addon/AzerothKart/README_ADDON.md`, `CHANGELOG.md`, `tests/MANUAL_CLIENT_CHECKLIST.md`, this handoff. **Not touched:** `Circuit.lua`, Physics, collision code, `UI.lua`, the session/network modules, `Presentation.lua`.

## Owner instructions

- He chose Orgrimmar as the next city and sent his in-game Orgrimmar map with his route in red: "start" at the West Gate, out along the western canyon road, round the city (the Cleft of Shadow's west side, the north road, over the bridge round the Valley of Honor's lake and back, down the Drag, through the Valley of Strength) and back along the same canyon road to the gate.
- Then, while it was being traced: "I dont know how laps would work with that long start/end stretch - if its an issue: use the blue line here", with a copy of the map and a blue loop round the Cleft of Shadow.
- It was an issue (the out-and-back canyon and the double pass over the Valley of Honor's bridge could only lap as two one-way roads with a rock wall between them, a hairpin at the gate and a second bridge, at about half Ironforge's scale), so the course is the blue loop; he was told so before the work and sent the review picture after it.
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes and runs the client checks; Codex prepares coordinated installs.

## Delivered

[The Orgrimmar sheet](../art/tracks/orgrimmar.md) has the route, play, look, files, rebuild commands and provenance; [the review picture](../art/tracks/orgrimmar_canyon-review.png) (the loop's direction and nine follow-camera views) was sent to the owner.

- **The course:** the blue loop, counter-clockwise, traced on his half-size copy registered onto the full map by image correlation (1.904×). Start on the canyon road's last straight (a 734-unit approach from the west, Warcraft III's own Orgrimmar gate closing it behind the grid), join the loop in the Valley of Strength, finish line just round the corner; north up the Drag, west under the canyon's north wall past the Valley of Wisdom and Grommash Hold, south down the Cleft of Shadow's rim, back into the Valley of Strength. Four gates named for the districts (The Drag, Valley of Wisdom, Cleft of Shadow, Valley of Strength = finish); a 4,769-unit lap. Full grip to the walls, as the owner chose for Stormwind.
- **The look:** an open-air canyon city: valleys as floor, everything else red rock (Outland's rock tile) whose south faces show as cliffs in the Barrens cliff texture's strata; the Cleft of Shadow sunk below the city (a 46-row far wall, its shadow, a dark floor) with Ragefire's lava fissure; Barrens ground; a red-orange dirt road, gravel shoulders and a spiked timber palisade; the Horde's buildings, banners, props and people from Warcraft III (red team colour); Grommash Hold (the great hall at its fortress stage) with Thrall at its door, the bank (a stronghold), a wind riders' roost, goblin stalls and a kodo on the Drag, palms (with cut-out shadows) and spirit lodges in the Valley of Wisdom, spires and a rock arch on the canyon's rock, the Valley of Spirits' pool by the start.
- **Pipeline (art only, all optional per city):** `rock.face_texture` (a `Strata` region of a plain texture over the rock's faces), `pits` (sunken ground), `land_wall` (a city's own street wall: palisade with spikes), per-model `cut` (drop a Barrens doodad's square ground patch) and `alpha_shadow` (`wc3render.render`: the shadow follows the texture's cut-outs). Stormwind's and Ironforge's pictures and data are byte-identical (`--check` PASS).

## Changes Codex must review

1. **A new city definition**, data only: `CapitalCities.orgrimmar_canyon` (version 1) uses existing fields: `wallClearance` 14 with 1,222 generated `wallVertices`, **`fullSpeedToWalls=true`** (the reviewed Stormwind flag applied to a new city), no plazas, solids or narrows, one approach branch. No `Circuit.lua` change. `Courses.lua` makes `orgrimmar_canyon` available (three cities stay `soon`), so `Courses.next` and `UI.SelectTrack` accept it.
2. **Tests:** `tests/test_circuit.lua` (soon count 3, the five-track cycle, an Orgrimmar block: radii and four gates, clearance metadata, full grip, a walk of its gates in order with a wall-free centerline, both ends of every gate in wall, throttle from the grid on road); `tests/test_menu.lua` (one more Track button step); `tests/test_ui.lua` (Orgrimmar's four gates in the gate-pool switch fixture, a count comment). No mechanics, capture, lifecycle or clock assertion changed; explicit UI counts unchanged (75/165/80 with the karts).
3. **Install:** two new files (`Assets/Tracks/Orgrimmar/Background.tga` 16 MiB raw, `Preview.tga` 1 MiB): 47 files with the karts' four; a full client restart. The staging loader still holds at most two city pictures.
4. **Contract text** in `docs/API_CONTRACTS.md` marks Orgrimmar proposed (CapitalCities figures, the Courses note, the `SelectTrack` id list).

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8): full suite, both runtimes |
| `python tests/test_circuit_boundary.py` | **PASS** (11 tests) |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** in the cloud for `CapitalCities.lua` and all six pictures: Stormwind and Ironforge byte-identical to their committed bytes after the painter changes; Orgrimmar reproduces |
| Collision probe (offline, Lupa) | Orgrimmar's `surfaceAt` against an independent disc-inside-union test (14-unit disc inside the 90-unit visual capsules) at 13,440 points round the walls, concave junctions included: **no mismatch** |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| `python scripts/preview_ui.py` | Regenerated `docs/art/ui/front-end-review.png` (the track list with Orgrimmar ready); a one-off run with Orgrimmar selected showed its preview, blurb and facts fit and a mock drive from its grid (not committed) |
| Review | The overview and nine 533×320 follow-camera views (the review picture) |

**NOT RUN:** the client (Orgrimmar's load, look, drive, walls, camera, performance); any install; multiplayer. Developer-machine checks: see the next commit's update of this table if present.

## Client check (owner; NOT RUN; after Codex's coordinated install)

[The Orgrimmar section of the client checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-orgrimmar-canyon-rush-check-proposed-claudeorgrimmar): the track screen lists it with its preview; the picture loads; the drive from the canyon road through the four gates; palisade and cliffs stop the kart with full grip before them; frame rate and Print Probe 75/165/80.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-22 ~22:00 CEST — Claude / `claude/orgrimmar`, Orgrimmar Canyon Rush
>
> - The owner's Orgrimmar map: his red route's out-and-back canyon could not be lapped, so on his offer the course is his blue loop round the Cleft of Shadow, counter-clockwise, starting on the canyon road behind a gate of the city wall. Four gates, 4,769-unit lap, 734-unit approach, `fullSpeedToWalls` as Stormwind; an open-air canyon city in Warcraft III Barrens art with the Cleft as a sunken chasm. Painter options added (`Strata`/`face_texture`, `pits`, `land_wall`, `cut`, `alpha_shadow`); Stormwind and Ironforge byte-identical.
> - `test_lua.py --runtime both` PASS; `test_circuit_boundary.py` PASS; `build_city_tracks.py --check` PASS (all cities); collision probe 13,440 points, no mismatch; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/orgrimmar` at this commit (the worktree previously held `claude/kart-roster-wc3` `8cc2031`, which is unchanged) |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/orgrimmar` (and `claude/kart-roster-wc3` if not yet pushed) |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:** Orgrimmar's Warcraft III files were extracted on the developer machine into the shell's `akcheck/WC3` (commands in the Orgrimmar sheet) and copied as a git-ignored tar (`local-artifacts/og-wc3.tar`, outside Git). Commits are made in a cloud clone with this repository's local identity, moved as git bundles (`local-artifacts/bundles/`) and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable. The untracked `Claude outputs/` folder is still left for the owner.

## Next

1. The owner's reaction to the Orgrimmar picture (changes go on this branch).
2. Codex: review the four karts, then Orgrimmar (the city data, `fullSpeedToWalls` for it, tests, two new files), and install when the owner wants them.
3. The owner's drive of Orgrimmar and the four karts (client checks above).
