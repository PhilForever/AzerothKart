# Claude handoff — the Great Forge in Warcraft III textures

Prepared 2026-10-22 about 19:40 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the Ironforge version 3 handoff at `9461f9c`, which Codex imported verbatim into `codex/ironforge-narrows`; it remains in history.

**Base:** `codex/ironforge-narrows` at `bc93753` (Codex's reviewed, published and installed integration of Claude `9461f9c`: Ironforge version 3 with the reviewed `narrows` contract, Codex's all-road tunnel-corner fix and regressions). New branch **`claude/ironforge-polish`**, as Codex's handoff proposed:

1. the art change below, with its docs and this handoff (one commit).

`claude/ironforge-design` stays at `9461f9c`. No milestone or multiplayer gate changed.

**Scope (reserved and changed):** `scripts/city_meshes.py` (texture paints), `scripts/city_paint.py` (`sprite_for` passes the extraction root to the meshes), `scripts/city_layouts.py` (the anvil's scale), `addon/AzerothKart/Assets/Tracks/Ironforge/{Background,Preview}.tga`, `docs/art/tracks/ironforge*`, `docs/art/ASSET_SOURCES.md`, `CHANGELOG.md`, this handoff. **Not touched:** `Circuit.lua`, `CapitalCities.lua` (byte-identical, `--check` PASS), `Courses.lua`, the circuit tests, Codex's narrows contract and corner fix, everything in UI/Physics/network.

## Owner instructions

- After Codex's install of version 3, the owner drove it: "Forlorn Cavern is good. The lava is good. We need to work on this image I sent you. Reduce the anvil size by 50%, and add suitable wc3 textures to the models you created here." (His screenshot: the Great Forge's floor between its two lava pools, with the flat-coloured anvil and four pumps.)
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes and runs the client checks; Codex prepares coordinated installs.

## Delivered

[The Ironforge sheet](../art/tracks/ironforge.md#revision-after-the-owners-drive-2026-10-22) records the request; [the before/after picture](../art/tracks/ironforge_gp-forge-textures.png) was sent to the owner.

- **The anvil at half size:** `mesh_prop("great_anvil", …, scale=0.575)` (was 1.15), in the same place.
- **Warcraft III textures on the procedural models.** `city_meshes.tex(path, region, tint, period, repeat)` paints a face with a rectangle of a Warcraft III texture: bilinear samples that repeat inside the rectangle (never reading its neighbours), tinted, repeated every `period` world units across a face (whole times round a prism, so its seam matches) or stretched. Patterns (`bands`, `emblem`) now choose between two such paints. The textures are three the picture's models already use, read from the same extraction: `textures/steamtank.dds` (riveted steel plates with brass straps on the great pumps' vats, tinted darker; the anvil's face and sides tinted red, its brass lozenge and bands), `buildings/other/powergenerator/powergenerator.dds` (brass rail rims, copper-coil drums of the small pumps, rune-cut iron round the anvil's base, the pipes, the round hatch on every pump's top) and `textures/minecart.dds` (dark riveted iron feet, bases and beams). No new extraction: the documented commands already fetch all three, and the sources list is unchanged.
- **Reproducibility:** plain arithmetic and `floor` only, as before; the developer machine renders the same bytes (below).

## Changes Codex must review

None to collision or interfaces: an art change to the Ironforge pictures only. `CapitalCities.lua` is byte-identical, so the narrows, `wallVertices` and Codex's corner fix are untouched. Install as usual when the owner wants it (two changed files: `Assets/Tracks/Ironforge/Background.tga` and `Preview.tga`).

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** in the cloud for `CapitalCities.lua` (unchanged) and both cities: Stormwind `Background.tga` sha256 `078a7805bccdadd8b88a909d5c37b013aa51e9d0d7981134c04f7a9db12f4ebb` (unchanged); Ironforge `Background.tga` `258bc9be54e6eb6389fff867379c32c4e92c3272f8d05dd354a4dd74a3b918e6`, `Preview.tga` `3a46a8f80d46bb19ac459c4511b774bc55bcf2691e43cc851061dd6919dc2143` |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| Review | The forge island at 2.5× and in the game camera's scale, before and after; sent to the owner |

No Lua changed, so the Lua suites were not rerun for this art change (Codex's last full run on `82d57eb` stands).

**NOT RUN:** the client (the textured anvil and pumps in WoW); any install; multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

[The checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-ironforge-grand-prix-check-proposed-claudecapital-cup), item 7: between the forges, the half-size red and gold anvil and the four pumps in metal textures; do they read as an anvil and pumps, and do they fit the Warcraft III art round them?

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-22 ~19:40 CEST — Claude / `claude/ironforge-polish`, the Great Forge in Warcraft III textures
>
> - After the owner's drive of Ironforge version 3 ("Forlorn Cavern is good. The lava is good."): the Great Anvil at half size; the anvil and pumps painted with rectangles of the steam tank's, power generator's and mine cart's textures (`city_meshes.tex`). Art only; `CapitalCities.lua` and Stormwind byte-identical. Ironforge `Background.tga` sha256 `258bc9be…3b918e6`, `Preview.tga` `3a46a8f8…19dc2143`.
> - `build_city_tracks.py --check` PASS for both cities; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/ironforge-polish` at this commit (the worktree previously held `claude/ironforge-design` `9461f9c`, which is unchanged) |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/ironforge-polish` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:** commits are made in a cloud clone with this repository's local identity, moved as git bundles (`local-artifacts/bundles/`) and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable. Git there needs delete access to the worktree and `.git` (granted this session) to replace files and drop its lock files. The untracked `Claude outputs/` folder is still left for the owner.

## Next

1. Codex: install `claude/ironforge-polish`'s two pictures when the owner wants them (art only).
2. The owner's look at the forge; adjust on his notes.
3. Then Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit on the same pipeline, each traced on the owner's map of that city.
