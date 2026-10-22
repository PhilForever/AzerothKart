# Claude handoff — four Warcraft III karts (ten in all)

Prepared 2026-10-22 about 20:45 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the forge-textures handoff at `2e75a3d`, which Codex reviewed, published and installed (`codex/ironforge-polish-review` `1a70d6e`); it remains in history. Codex's review notes one inaccurate sentence in it (the Lua suites last run fully at `82d57eb`: Codex ran selected modules); see its review report.

**Base:** `codex/ironforge-polish-review` at `1a70d6e` (Codex's review of Claude `2e75a3d`: the textured Great Forge, installed). New branch **`claude/kart-roster-wc3`**:

1. the four karts, their registration, tests, docs and this handoff (one commit).

`claude/ironforge-polish` stays at `2e75a3d`. No milestone or multiplayer gate changed.

**Scope (reserved and changed):** `scripts/build_wc3_kart.py` (Warcraft III vehicle sources), `addon/AzerothKart/Assets/Karts/{DwarfCar,OrcDemolisher,MeatWagon,GlaiveThrower}.tga` (new), `addon/AzerothKart/Presentation.lua` (`KART_SPRITES` entries and `KART_ORDER` only), `addon/AzerothKart/Menu.lua` (`Menu.KARTS` copy and credits only), `tests/test_presentation.lua` (coverage floors), `tests/test_menu.lua` and `tests/test_ui.lua` (the explicit frame budget only), `docs/art/karts/*`, `docs/art/ui/front-end*`, `docs/art/ASSET_SOURCES.md`, `docs/API_CONTRACTS.md` (counts and the kart order note), `README.md`, `CHANGELOG.md`, `tests/MANUAL_CLIENT_CHECKLIST.md`, this handoff. **Not touched:** Physics, collision, UI.lua, the session/network modules, the city tracks.

## Owner instructions

- After testing the textured forge: "Pushed and tested, loooks good. Next task?" Asked, he chose **two more karts (recommended: the release target is eight karts, there were six)** and, offered four of Warcraft III's own vehicles to pick two from, selected **all four**: Dwarf Car, Meat Wagon, Orc Demolisher, Glaive Thrower. For the next city he chose **Orgrimmar**.
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes and runs the client checks; Codex prepares coordinated installs.

## Delivered

[The roster](../art/karts/roster.md#warcraft-iiis-own-vehicles-2026-10-22) has the details and pictures; [the four karts on Ironforge's road](../art/karts/wc3-vehicles-review.png) were sent to the owner.

- **Four karts from Warcraft III itself** (Blizzard Entertainment's Reforged SD models in the owner's install, no community licence question): the Dwarf Car (`units/other/dwarfcar`), Orc Demolisher (`units/orc/catapult`), Meat Wagon (`units/undead/meatwagon`) and Glaive Thrower (`units/nightelf/ballista`), each a 1024×1024 sheet of 64 three-quarter headings like the other karts (player-1 red team colour, the scenery's sun and shadow). The Dwarf Car is fitted to the body's 31-unit length; the wider carts by width (24-26 units). All drive the same 17×31 body.
- **Pipeline:** `build_wc3_kart.py` gains `wc3` vehicles: `--wc3 WC3` reads the extracted MDX 1800 model and DDS textures through `wc3render.py` (the city scenery's reader; skinned geosets in bind pose), verifies every file by SHA-256, and renders with the unchanged kart renderer. `--all ROOT --wc3 WC3` builds all ten. The six existing sheets' code path is unchanged.
- **Effects:** anchors from the models' emitters and lowest geometry: the Dwarf Car's rear steam pipe and the Demolisher's two fire pots flame on boost; the Meat Wagon and Glaive Thrower have no engine and trail wind from their rear wheels (the Gryphon Rider's mechanism); drift dust from each cart's rear wheels.
- **Menus:** `KART_ORDER` is ten long (trike, Steam Tank, Dwarven Biker, Dwarf Car, Demolisher, Meat Wagon, Glaive Thrower, Gryphon Rider, Gyrocopter, Drag Car); each new kart has its blurb and the credit "Model: Blizzard Entertainment (Warcraft III)". The kart screens' list grows to five rows of two; the offline layout picture shows all ten fit above Back and Race!.

## Changes Codex must review

1. **Explicit UI budget: 71 → 75 frames** (textures 165 and font strings 80 unchanged): one list button per new kart in the kart/garage screen, created once with the window like the six before. `tests/test_menu.lua` and `tests/test_ui.lua` change only that number (`MENU_FRAMES` 60 → 64); no capture, lifecycle, clock or race assertion changed.
2. **Install:** four new files (`Assets/Karts/*.tga`, 4 MiB raw each, loaded only when chosen, one kart sheet held at a time as before): the install grows from 41 to 45 files and needs a full client restart.
3. No interface change: the new `KART_SPRITES` entries use the existing sheet and effect-anchor fields (`trails` as the Gryphon Rider does).

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8): full suite, both runtimes |
| `python scripts/build_wc3_kart.py --wc3 … --vehicle <id> --check` | **CHECK PASS** in the cloud for the four new sheets, sources verified by SHA-256. Sheets: Dwarf Car `b58da1e6…0fe0fb`, Orc Demolisher `7621c908…1a6875`, Meat Wagon `590c0c6b…f6f29c8`, Glaive Thrower `3e6eed6a…6390f4` |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| `python scripts/preview_ui.py` | Regenerated `docs/art/ui/front-end-review.png`: the kart screen lists ten karts in five rows (layout only, stand-in fonts) |
| Review | Every sheet's 64 frames and eight headings on the Mirage background (per-kart review PNGs) and six headings each on Ironforge's road |

**NOT RUN:** the client (the four karts' look while driving, their effects, the ten-button kart screen, Print Probe 75/165/80); any install; multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

[The roster's check](../art/karts/roster.md#client-check-not-run), the paragraph on the four Warcraft III vehicles: all ten buttons fit; each new kart spins on the turntable; a lap with each faces its travel; drift dust at the rear wheels; the Dwarf Car's pipe and the Demolisher's pots flame on boost, the Meat Wagon and Glaive Thrower trail wind; Print Probe 75/165/80.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-22 ~20:45 CEST — Claude / `claude/kart-roster-wc3`, four Warcraft III karts
>
> - The owner chose more karts and all four offered: Dwarf Car, Orc Demolisher, Meat Wagon, Glaive Thrower, rendered from Blizzard's own Reforged models in his install by `build_wc3_kart.py --wc3` (SHA-256-verified sources). Ten karts; explicit UI counts 75/165/80 (+4 list buttons). Next city chosen: Orgrimmar.
> - `test_lua.py --runtime both` PASS; kart `--check` PASS for the new sheets; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/kart-roster-wc3` at this commit (the worktree previously held `claude/ironforge-polish` `2e75a3d`, which is unchanged) |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/kart-roster-wc3` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:** the four models and their textures were extracted on the developer machine into the shell's `akcheck/WC3` and copied to the git-ignored `local-artifacts/third-party/wc3-karts/` (outside Git). Commits are made in a cloud clone with this repository's local identity, moved as git bundles (`local-artifacts/bundles/`) and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable. The untracked `Claude outputs/` folder is still left for the owner.

## Next

1. Codex: review the four karts (the +4 frame budget and four new files) and install when the owner wants them.
2. The owner's drive with the new karts.
3. **Orgrimmar Canyon Rush**, the owner's choice for the next city: on the same pipeline, traced on his in-game map of Orgrimmar with his route in red (needed from him).
