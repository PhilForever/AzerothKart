# Claude handoff — Mirage scenery v1

Prepared 2026-10-20, Europe/Oslo, by Claude (rendering/UI/sprites owner). This session repainted the Mirage background from flat blockout art into original procedural scenery at the same path, size, format and registration. M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open. The previous handoff, for the first Goblin Drag Car sprite, is in Git at `46931e1`.

## Owner instructions this session

- "You can update the addon directly here: C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\AzerothKart And feel free to push to github as well https://github.com/PhilForever/AzerothKart Now, continue work on Mirage Raceway"
- Follow-up answers:
  - fast-forward `claude/track-ui` to Codex's review commit;
  - push **only** `claude/track-ui`, leaving `main` untouched;
  - the owner runs the in-game checks personally, so Claude sent no client input.

## Branch, commits and deployment

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui` |
| Base | `1f8f208` (`docs: approve Claude sprite review and Warcraft III asset direction`), fast-forwarded from `46931e1` with owner approval; clean at entry |
| Feature commit | `76af4aa71e1f6a310f2d6d3729e781abb1f5b9dd` — `feat: paint Mirage scenery v1 background` |
| Handoff commit | The commit containing this file; resolve with `git log -1 claude/track-ui` |
| Installs (owner-authorized) | 1) `1f8f208` at 11:41 UTC: 17 files hash-verified, backup in `local-artifacts/installs/20261020-114116/`. 2) `76af4aa` at 12:24 UTC: `Background.tga` and `README_ADDON.md` copied, all 17 installed hashes match the source, backup in `local-artifacts/installs/20261020-122432/`. Each folder holds an `install.json` manifest and is git-ignored. An independent `diff -rq` found the installed folder identical to `addon/AzerothKart` at `76af4aa` |
| Push (owner-authorized, branch only) | **Blocked:** neither the Linux shell on the developer machine nor the cloud workspace has a GitHub credential for `PhilForever/AzerothKart`. The owner can run `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/track-ui` |
| Not done | No merge into `main` (still `f923d15`), no tag or release, no client input. Codex's branches and worktree were not touched |

**Shared deployment note for Codex:** the live AddOns folder now carries `claude/track-ui` at `76af4aa`, including the sprite and scenery that are not on `main`. Installing from another checkout replaces them, so read the latest `install.json` first.

**Git environment note:** commits come from a Linux shell on the developer machine. It mounts this worktree and the shared `.git` folder and runs Git with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. `git worktree list` there marks this worktree prunable because its recorded gitdir is a Windows path. **Never run `git worktree prune` or `git gc` from that shell.** No lock file or temp object was left this session.

## Completed work

- **Scenery v1** ([asset sheet](../art/mirage-background.md)):
  - Ivory salt flats: domain-warped Voronoi crust plates with fading ridges and cracks, plus a bright crust and dust along the lane.
  - Packed-dirt lane: a worn center, berms, two wobbling racing lines of tire streaks, red/cream apex kerbs on sharp bends, and pebbles.
  - Two rows of start/finish checkers under the Start gate.
  - Static set pieces lit from the north-west, with south-east shadows and ink outlines:
    - the boulder rim and the north rock mound;
    - the goblin pit east of the start straight and the gnome dome camp west of the west straight;
    - an infield timing tower, start banners, bleachers, a tent camp with a campfire and a fuel tank tower;
    - a drag-car wreck, a crashed gyrocopter, a kodo skeleton, tire stacks and sparse rocks, shrubs and bones.
- **Build-time guarantees:**
  - road or salt for each pixel comes from the actual Lua `isDrivable`;
  - the build fails if scenery covers a road texel;
  - objects keep a 20-unit clearance (the start poles 6);
  - road interior luma must stay ≤ 180 and the rim ≥ 190 (actual ≤ 168 and ≥ 201);
  - ten landmarks must match their exact color.
- **Pipeline:**
  - New shared `scripts/paintkit.py`:
    - SDF shapes, a coverage-tracking canvas and soft ground decals;
    - materials and `hash32`, a full 32-bit hash (`hash2` keeps 16 bits, which had collapsed scattered props onto a line);
    - the exact integer resolve, TGA/PNG encoding and decoding, and bilinear sampling.
  - `scripts/build_kart_sprites.py` now imports it, and `--check` still passes byte-identically.
  - `scripts/build_mirage_background.py` was rewritten. It does one Lua geometry scan, giving the road flag, signed lateral offset and arc length for each pixel. Then come the ground layers, scenery, validation and previews.
- **Test:** `tests/test_presentation.lua` has a new background-registration block. It loads Track and MirageRaceway, reads `Background.tga` and samples every third texel against `isDrivable`. Interior road must be dark and the rim light, with minimum sample counts. A deliberately flipped image fails it.
- **Docs:**
  - a rewritten [background sheet](../art/mirage-background.md) with an overview and four play-view previews;
  - sentence-level current-state updates in README, README_ADDON, ASSETS, INDEX, MIRAGE_RACEWAY, ASSET_SOURCES and the drag-car sheet;
  - a CHANGELOG entry, and one more required path in `validate_project.py`.

## Files changed (feature commit `76af4aa`)

- **Runtime:**
  - `addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga` (same path, size and format);
  - `addon/AzerothKart/README_ADDON.md` (text only).
- **Tools:**
  - `scripts/paintkit.py` (new);
  - `scripts/build_mirage_background.py`;
  - `scripts/build_kart_sprites.py` (refactor, identical output);
  - `scripts/validate_project.py` (shared: +1 path).
- **Tests:** `tests/test_presentation.lua`.
- **Docs:**
  - `docs/art/mirage-background.md`;
  - `docs/art/mirage-background-overview.png` and `docs/art/mirage-background-views.png` (new);
  - `docs/art/karts/goblin-drag-car-review.png` (regenerated over the new background; the kart TGA is unchanged);
  - `docs/art/karts/goblin-drag-car.md`, `docs/art/MIRAGE_RACEWAY.md` and `docs/art/ASSET_SOURCES.md`;
  - `docs/ASSETS.md`, `docs/INDEX.md`, `README.md` and `CHANGELOG.md`.

`git diff --stat 1f8f208` confirms these are unchanged:

- every Lua module, including `UI.lua` and `Presentation.lua`;
- both TOCs, `tests/run.lua`, `tests/test_ui.lua` and every simulation test;
- `docs/PROGRESS.md`, `docs/API_CONTRACTS.md` and the Codex handoff;
- AGENTS.md and CLAUDE.md.

## Tests performed

These ran in the Linux shell on the developer machine (Python 3.10.12, pinned `lupa==2.8` outside the repo). The cloud workspace (Python 3.13) was used only for byte reproducibility.

| Command / check | Result |
|---|---|
| `python3 scripts/test_lua.py --runtime both` on committed `76af4aa` | **PASS**: 29 files parsed and the suite passed in both Lua 5.1 and 5.4. Includes `offline Mirage background: 18887 road / 1191 rim samples agree with isDrivable` |
| `python3 scripts/build_mirage_background.py --check` | **CHECK PASS**: 4,194,322 bytes; 10 landmarks; road ≤ 168 (169,984 px) vs rim ≥ 201 (11,089 px); no scenery on road; SHA-256 `470773847ebc9d4fbfed14d6656eccd5dd9726bfd996b672450c1d1f1802ac37` |
| The same build with Python 3.13 in the cloud workspace | Identical SHA-256 |
| `python3 scripts/build_kart_sprites.py --check` after the paintkit refactor | **CHECK PASS**, unchanged `cc7c1c69…126a` |
| `python3 scripts/build_mirage_layout.py --check` | CHECK PASS (unchanged) |
| Negative check during development | A vertically flipped `Background.tga` fails the Lua registration block |
| `python3 scripts/validate_project.py` | Only the **2 pre-existing** failures: absolute `C:/Users/bakke/.codex/...` links in PROGRESS.md that resolve only on Windows. Every other path and doc link passes, now including `scripts/paintkit.py` |
| `git diff --check`, `git diff --cached --check` | Clean |
| Visual review (offline emulation, not the client) | Inspected the whole-map overview and four emulated play views. No scenery on the lane, kerbs on the bend insides, checkers under the Start gate, a readable lane edge, and gates and kart unobstructed |
| Install verification | `install_ak.py`: backup verified, 2 files copied, 17/17 source hashes matched; independent `sha256sum` and `diff -rq` agree |

**NOT RUN:**

- WoW Forever checks (below);
- `tests/test_install_local.ps1` (no PowerShell in this shell);
- `validate_project.py` on Windows;
- FPS or performance measurement;
- multiplayer.

## Tests requiring WoW Forever (all NOT RUN; the owner is checking)

Both slices are installed. The kart sprite was a new file and the background is a replaced one, so **fully restart the client**. Detailed steps are in [the sprite check](../art/karts/goblin-drag-car.md#client-check-not-run) and [the scenery check](../art/mirage-background.md#client-check-not-run). In short:

1. The sprite shows on Test Oval and Mirage instead of the orange rectangle: transparent corners, nose leading in every direction, phase washes while drifting and boosting.
2. Mirage shows scenery v1, not the flat blockout, with no flip or offset.
3. The lane edge matches where the kart starts slowing on salt.
4. The checkers sit under the Start strip, and kerbs mark the bend insides.
5. Nothing covers the lane, a gate strip or the kart, and the gray wall strips sit over the boulder rim.
6. No seams, banding or blur appear while the camera moves or at the map edges.
7. Print Probe shows 9/111/13.

## Known limitations

- Static scenery only: no foreground occlusion layer, no animated props such as campfire smoke or flags, no VFX.
- Kerbs are placed from the turn sharpness at centerline vertices, so gentle bends have none.
- At scale 1.5 one texel spans 1.5 canvas units, so the art can look slightly soft on high-resolution displays. A 2048 master would need a reviewed memory change (16 MiB raw).
- The gray perimeter wall strips (inset 18) now overlay the painted boulder rim and read as a frame in previews. Restyling them is a `drawWalls` change for a later slice.
- `UI.SelectTrack` is Codex-owned and still shows `Mirage Raceway blockout | Start for 3 laps | Off-road: rough salt`. Proposed: `Mirage Raceway | Start for 3 laps | Off-road: rough salt`. No test asserts the string, and Claude did not edit it.
- Camp positions follow the brief's composition; this is not a surveyed reconstruction of the Shimmering Flats.

## Recommended next visual milestone

1. Record the owner's client results for the sprite and scenery in PROGRESS.
2. **Kart grounding and VFX:** a separate world-oriented shadow plus a pooled exhaust/boost flame. This adds 1–3 textures, a count change that needs review.
3. **Mirage polish:**
   - the status-text change above (Codex);
   - wall strips restyled to suit the boulder rim;
   - optionally a small foreground layer that never hides gates or the kart.
4. The contrasting Gnome Drag Car, through the same generator and registry.
5. Warcraft III material for props and VFX, after a specific source is inspected and logged in ASSET_SOURCES.

## Changes Codex must review

- `scripts/paintkit.py`, a new shared module, and the `build_kart_sprites.py` refactor. `--check` proves the output is byte-identical.
- `tests/test_presentation.lua`. The new block loads `Track.lua` and `MirageRaceway.lua` read-only and asserts only the art. No mechanics assertion was added or changed.
- `scripts/validate_project.py` (shared): one more required path.
- Shared docs: sentence-level updates in README, README_ADDON, ASSETS, INDEX and CHANGELOG.
- The status-text proposal above, which touches Codex's code.
- Deployment state: the AddOns folder is at `76af4aa`.
- Asset budget: the same 1024×1024 RGBA32 file (4 MiB raw). No texture, frame or region was added; counts stay 9/111/13.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was deliberately not edited)

> ### 2026-10-20 ~13:45–14:30 CEST — Claude / `claude/track-ui`, Mirage scenery v1
>
> **Implemented:**
> - Original procedural `Assets/Tracks/SaltFlats/Background.tga` at the same path, size and format: salt flats, a dirt lane with apex kerbs and start checkers, the goblin pit, the gnome camp and set dressing.
> - Registered per pixel to the Lua `isDrivable`. The build asserts no scenery on road, a 20-unit clearance, contrast limits and ten landmarks.
> - Shared `scripts/paintkit.py`; the kart generator was refactored with identical bytes.
> - An independent Lua background check.
> - Geometry, physics, UI code, TOCs, simulation tests and counts 9/111/13 unchanged.
>
> **Executed (Linux shell, Python 3.10, lupa 2.8):**
> - `test_lua.py --runtime both` PASS: 29 files; the background check covered 18,887 road and 1,191 rim samples.
> - `build_mirage_background.py --check` PASS (`47077384…2ac37`), with identical bytes on Python 3.13.
> - Kart and layout checks PASS.
> - `validate_project.py`: only the 2 pre-existing Windows-link failures.
> - `git diff --check` clean.
>
> **Deployment (owner-authorized):** `1f8f208` (17 files verified; backup `20261020-114116`), then `76af4aa` (2 files copied, 17 verified; backup `20261020-122432`).
>
> **NOT RUN:** client sprite and scenery appearance (the owner is checking), installer fixtures, performance. The `claude/track-ui` push is blocked by missing credentials in Claude's environments; the owner can push from Windows.
>
> **Next:** record the owner's client results, then kart shadow and exhaust VFX.

## Integration (manual, after review; not executed)

```powershell
git log --oneline 1f8f208..claude/track-ui
git diff 1f8f208..claude/track-ui --stat
python scripts/test_lua.py --runtime lua51 --tests presentation ui
python scripts/build_mirage_background.py --check
python scripts/build_kart_sprites.py --check
python scripts/validate_project.py
```

`claude/track-ui` builds on `1f8f208`, the tip of `codex/claude-assets-review`; `main` is still `f923d15`. A fast-forward of `main` needs explicit integration authorization. Do not reset, rebase or force anything to make it apply.
