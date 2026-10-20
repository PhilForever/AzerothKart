# Claude handoff — Mirage scenery and shadows

Prepared 2026-10-20, Europe/Oslo, by Claude (rendering/UI/sprites owner). This session continued Mirage Raceway in three steps:

1. scenery v1 (`76af4aa`);
2. the owner's in-game check of it;
3. a shadow pass fixing what that check flagged (`0bf6fd0`).

M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open. Earlier handoffs are in Git: the first Goblin Drag Car sprite at `46931e1`, and scenery v1 in full detail at `55c542d`.

## Owner instructions this session

- "You can update the addon directly here: C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\AzerothKart And feel free to push to github as well https://github.com/PhilForever/AzerothKart Now, continue work on Mirage Raceway"
- Follow-up answers:
  - fast-forward `claude/track-ui` to Codex's review commit;
  - push **only** `claude/track-ui`, leaving `main` untouched;
  - the owner runs the in-game checks personally, so Claude sends no client input.
- After checking scenery v1 in the game: "Looks aight. I added github to claude - let me know if you still dont have access. Everything else looks and feels good, some issues with shadows on the assets around as you can see on the screenshot. Feel free to fix that next."

## Branch, commits and deployment

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui` |
| Base | `1f8f208` (Codex's review commit), fast-forwarded from `46931e1` with owner approval |
| Commits | `76af4aa` `feat: paint Mirage scenery v1 background`; `55c542d` `docs: hand off Mirage scenery v1`; `0bf6fd0` `feat: attach soft shadows to Mirage scenery`; then the commit containing this file (`git log -1 claude/track-ui`) |
| Installs (owner-authorized) | Each install backed up the target and hash-verified it. The backup folders sit under `local-artifacts/installs/`, each with an `install.json`, and are git-ignored. 1) `1f8f208` at 11:41 UTC: 17 files, backup `20261020-114116`. 2) `76af4aa` at 12:24 UTC: `Background.tga` and `README_ADDON.md`, backup `20261020-122432`. 3) `0bf6fd0` at 16:50 UTC: `Background.tga`, backup `20261020-165006`. `diff -rq` found the installed folder identical to `addon/AzerothKart` at `0bf6fd0` |
| Push (owner-authorized, branch only) | **Still blocked.** The owner connected GitHub to Claude, but this running session's git proxy still refuses `PhilForever/AzerothKart` as "not in this session's authorized repository set", and `gh` reports access is not enabled for this session. The owner can push from Windows with `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/track-ui`. A new session started with the repository attached should also be able to push |
| Not done | No merge into `main` (still `f923d15`), no tag or release, no client input. Codex's branches and worktree were not touched |

**Shared deployment note for Codex:** the live AddOns folder carries `claude/track-ui` at `0bf6fd0`, including the sprite, scenery and shadows that are not on `main`. Installing from another checkout replaces them, so read the latest `install.json` first.

**Git environment note:**

- Commits come from a Linux shell on the developer machine. It mounts this worktree and the shared `.git` folder and runs Git with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`.
- `git worktree list` there marks this worktree prunable because its recorded gitdir is a Windows path. **Never run `git worktree prune` or `git gc` from that shell.**
- Without delete permission in `.git`, a commit there leaves a stale `HEAD.lock`. The one left by `0bf6fd0` was removed after the owner allowed deletion; it was empty and created by that command.

## Owner's in-game check of scenery v1

Recorded in [the evidence note](../evidence/2026-10-20-mirage-scenery-owner-check.md), from one owner screenshot (Mirage selected, stopped at spawn) and the owner's words:

- scenery v1 and the Goblin Drag Car sprite render in WoW Forever;
- the sprite faces north on the start checkers, with no box or halo;
- the view matches the offline play-camera preview;
- the owner reports that everything apart from the shadows looks and feels good;
- the shadows were detached gray offset copies of their objects, which prompted the shadow pass.

The screenshot records no probe numbers, FPS, tints or rotation while driving.

## Completed work

**Scenery v1 (`76af4aa`)** repainted `Assets/Tracks/SaltFlats/Background.tga` from flat blockout art into procedural scenery. The path, size, format and registration stayed the same: road or salt for every pixel still comes from the Lua `isDrivable`. The `55c542d` handoff and the [background sheet](../art/mirage-background.md) cover it.

**Shadow pass (`0bf6fd0`):**

- **`scripts/paintkit.py`:**
  - `convex_hull`, `sd_hull`, `prism`, a `Shadow` piece set and `Canvas.enable_shadows`/`Canvas.cast`.
  - A shadow is the convex hull of an object's volume vertices, each moved along the shadow vector by its height.
  - It multiplies already-painted color toward a tint, with a contact rim and a penumbra that widens and fades toward the tip.
  - Each sample keeps its strongest shadow level, so overlaps never stack; `Canvas.draw` clears the level where it paints.
  - The kart canvas never enables shadows, and its output is byte-identical.
- **`scripts/build_mirage_background.py`:**
  - Every object now declares volumes with real heights: rocks as octagon frustums, barrels and stacks as columns, the workshop, tents and tower as gable or pyramid volumes, the bleachers as a wedge.
  - Shadow vector 0.95 × (0.6, −0.8) per unit of height, away from the north-west light; tint (0.46, 0.42, 0.55); core strength 0.64.
  - Raised parts lift away, joined to the ground by their poles, legs or cable: the banner cloth, crane boom, hook, fuel drum, raised awnings and gyrocopter rotor.
  - The chimney on the workshop roof casts onto the roof.
  - Multi-part objects (rocket, crane, fuel tower, gyrocopter, banners, wreck) cast one shadow each.
  - The goblin and gnome camps queue low props before tall ones.
  - Banners became swallowtail flags with trim stripes.
  - Oil stains became two drips and one pit-box splat with crisp lobed edges; the old soft gray blobs read as shadows.
  - The gnome chimney's soot blob was removed; the contact rim grounds it instead.
- **Docs:**
  - a new [evidence note](../evidence/2026-10-20-mirage-scenery-owner-check.md);
  - a Shadows section, new SHA and status in the [background sheet](../art/mirage-background.md);
  - the owner observation added to the [drag-car sheet](../art/karts/goblin-drag-car.md);
  - status sentences in README, ASSETS, MIRAGE_RACEWAY and INDEX;
  - a CHANGELOG entry;
  - regenerated previews and the kart review sheet.

## Files changed by `0bf6fd0`

- **Runtime:** `addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga`. Same path, size and format; SHA-256 `cd5aecb95daca106e3494c8ed72a2a6b227f49ca51680a8c6b403f766a1c567e`.
- **Tools:** `scripts/paintkit.py`, `scripts/build_mirage_background.py`.
- **Docs and review images:**
  - `docs/evidence/2026-10-20-mirage-scenery-owner-check.md` (new);
  - `docs/art/mirage-background.md`, `docs/art/mirage-background-overview.png` and `docs/art/mirage-background-views.png`;
  - `docs/art/karts/goblin-drag-car.md` and `docs/art/karts/goblin-drag-car-review.png`;
  - `docs/art/MIRAGE_RACEWAY.md`, `docs/ASSETS.md`, `docs/INDEX.md`, `README.md` and `CHANGELOG.md`.

`git diff --stat 1f8f208` confirms these are unchanged across the session:

- every Lua module, both TOCs, `tests/run.lua`, `tests/test_ui.lua` and every simulation test;
- `docs/PROGRESS.md`, `docs/API_CONTRACTS.md` and the Codex handoff;
- AGENTS.md and CLAUDE.md.

## Tests performed

These ran in the Linux shell on the developer machine (Python 3.10.12, pinned `lupa==2.8` outside the repo) and in the cloud workspace (Python 3.13, `lupa` 2.8).

| Command / check | Result |
|---|---|
| `python3 scripts/build_mirage_background.py --preview` (both environments) | **GENERATED**, identical SHA-256 `cd5aecb9…c567e` on Python 3.10 and 3.13. Covers 10 registration landmarks; road ≤ 168 (169,984 px) vs rim ≥ 201 (11,089 px); no scenery **or shadow** on any road texel |
| `python3 scripts/build_mirage_background.py --check` (cloud) | CHECK PASS |
| `python3 scripts/test_lua.py --runtime both` (developer machine, final code) | **PASS**: 29 files parsed; suites pass in Lua 5.1 and 5.4. Includes `offline Mirage background: 18887 road / 1191 rim samples agree with isDrivable` |
| `python3 scripts/test_lua.py --runtime lua51 --tests presentation ui` (cloud) | PASS; counts 9/111/13 |
| `python3 scripts/build_kart_sprites.py --check` after the paintkit change | **CHECK PASS**, unchanged `cc7c1c69…126a` |
| `python3 scripts/build_mirage_layout.py --check` | CHECK PASS |
| `python3 scripts/validate_project.py` | Only the **2 pre-existing** absolute Windows-path links in PROGRESS.md fail; every other path and doc link passes |
| `git diff --check`, `git diff --cached --check` | Clean |
| Visual review (offline, not the client) | Zoomed crops of the goblin pit, start area, gnome camp, rock mound, fuel tower, wreck, gyrocopter, kodo skeleton, tents and bleachers, plus the four play views. A before/after of the owner's screenshot view shows the detached gray squares and streaks replaced by attached soft shadows |
| Install verification | `install_ak.py`: backup verified, 1 file copied, 17/17 source hashes matched; independent `sha256sum` and `diff -rq` agree |

**NOT RUN:**

- the shadow pass in WoW Forever;
- `tests/test_install_local.ps1` (no PowerShell here);
- `validate_project.py` on Windows;
- FPS or performance measurement;
- multiplayer.

## Tests requiring WoW Forever (NOT RUN; the owner checks)

The background was replaced at an existing path, so **fully restart the client**, because `/reload` may show the cached image. Select **Track: Mirage Raceway**, drive a lap and follow [the scenery client check](../art/mirage-background.md#client-check-not-run). In short:

1. Shadows touch their objects: the timing tower, workshop, crates and barrels.
2. The banners' and crane boom's shadows sit offset but joined by thin pole or cable lines, with no detached gray squares or streaks.
3. The lane edge, checkers and kerbs still line up.
4. No seams appear while the camera moves.
5. Print Probe shows 9/111/13.

Sprite rotation and tints while driving ([drag-car check](../art/karts/goblin-drag-car.md#client-check-not-run), steps 3 and 5–7) also remain open.

## Known limitations

- Shadows fall only on what is painted before them. A low prop never shades a taller roof drawn earlier, and object-on-object shading depends on queue order.
- The flat, top-down banners are a stylization of cloth streaming in the wind; the shadow carries the flag shape.
- Kerbs are placed from centerline-vertex sharpness, so gentle bends have none.
- One texel spans 1.5 canvas units at scale 1.5, so the art can look slightly soft on large displays.
- `UI.SelectTrack` is Codex-owned and still shows `Mirage Raceway blockout | Start for 3 laps | Off-road: rough salt` (visible in the owner's screenshot). Proposed: `Mirage Raceway | Start for 3 laps | Off-road: rough salt`. No test asserts the string, and Claude did not edit it.
- The gray perimeter wall strips still overlay the boulder rim. Restyling them is a later `drawWalls` slice.

## Recommended next visual milestone

1. The owner's client look at the shadow pass, recorded in PROGRESS.
2. **Kart grounding and VFX:** a world-oriented kart shadow consistent with this light (offset south-east), plus a pooled exhaust/boost flame. This adds 1–3 textures, a count change that needs review.
3. **Mirage polish:** the status-text change (Codex), and wall strips restyled to suit the boulder rim.
4. The contrasting Gnome Drag Car, through the same generator and registry.
5. Warcraft III material for props and VFX, after a specific source is inspected and logged in ASSET_SOURCES.

## Changes Codex must review

- `scripts/paintkit.py`: the shadow caster is new shared toolkit code. The kart `--check` proves its output is unchanged.
- The evidence note and the status sentences in shared docs (README, ASSETS, INDEX, MIRAGE_RACEWAY, CHANGELOG) now cite the owner's screenshot.
- The status-text proposal above, which touches Codex's code.
- Deployment state: the AddOns folder is at `0bf6fd0`.
- Asset budget: the same 1024×1024 RGBA32 file (4 MiB raw); no texture, frame or region added; counts stay 9/111/13.

## Pending PROGRESS ledger entries (integrator to append; PROGRESS.md was deliberately not edited)

> ### 2026-10-20 ~13:45–14:30 CEST — Claude / `claude/track-ui`, Mirage scenery v1
>
> **Implemented:**
> - Original procedural `Background.tga` at the same path, size and format, registered per pixel to the Lua `isDrivable`.
> - Build assertions: no scenery on road, a 20-unit clearance, contrast limits and ten landmarks.
> - Shared `scripts/paintkit.py` (the kart generator keeps identical bytes) and an independent Lua background check.
>
> **Executed:**
> - `test_lua.py --runtime both` PASS.
> - `build_mirage_background.py --check` PASS (`47077384…2ac37`, identical on Python 3.13 and 3.10).
> - Kart and layout checks PASS.
> - `validate_project.py`: only the 2 pre-existing Windows-link failures.
>
> **Deployment (owner-authorized, verified):** `1f8f208`, then `76af4aa`.
>
> **Owner client check:** a screenshot shows scenery v1 and the sprite rendering at the Mirage start. The owner said "Everything else looks and feels good" and flagged the shadows (evidence: `docs/evidence/2026-10-20-mirage-scenery-owner-check.md`).
>
> ### 2026-10-20 ~16:00–17:00 CEST — Claude / `claude/track-ui`, Mirage scenery shadows
>
> **Implemented:** attached shadows from height-swept convex volumes, with a contact rim, a fading penumbra, a multiplicative tint and max-combined overlaps (`paintkit.Shadow`/`Canvas.cast`). Swallowtail banners and crisp oil splats. Registration and road checks unchanged.
>
> **Executed:**
> - Builds identical on Python 3.10 and 3.13 (`cd5aecb9…c567e`).
> - `test_lua.py --runtime both` PASS.
> - Kart (unchanged bytes) and layout checks PASS.
> - `validate_project.py`: only the 2 pre-existing failures.
>
> **Deployment:** `0bf6fd0` (1 file copied, 17 verified; backup `20261020-165006`).
>
> **NOT RUN:** the shadow pass in the client. The push stays blocked by session credentials; the owner can push from Windows.
>
> **Next:** the owner's look at the shadows, then the kart shadow and exhaust VFX.

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
