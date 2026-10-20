# Claude handoff — Goblin Mortar Trike kart

Prepared 2026-10-20, Europe/Oslo, by Claude (rendering/UI/sprites owner). This session made five changes on `claude/track-ui`:

1. Mirage scenery v1 (`76af4aa`);
2. its shadow pass (`0bf6fd0`), after the owner's in-game check;
3. at the owner's request, the Warcraft III **Goblin Mortar Trike** as the default kart (`cf71394`);
4. this handoff (`064105f`);
5. this revision, recording the owner's approval of the trike and shadows.

M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open. Earlier handoffs are in Git: the drag-car sprite at `46931e1`, scenery v1 at `55c542d` and the shadow pass at `5734335`.

## Active reservation (2026-10-20, from about 21:05 CEST)

**Task:** drift and boost effects for the kart, then more roster vehicles. Owner request: "Start with drift and boost effects, then implement more vehicles." Owner answers: fast-forward `claude/track-ui` onto Codex's integration commit `7fcdd89` (done; it is the build installed in the AddOns folder), and the effects style "Sparks, smoke and flame".

**Base:** `7fcdd89` (`codex/menu-integration`), which already contains every earlier Claude commit.

**Reserved for Claude:**

- `addon/AzerothKart/Presentation.lua`: new pure effect helpers, plus emitter data in `KART_SPRITES`.
- `addon/AzerothKart/UI.lua`:
  - the visual layout part of `UI.Create`, where an effect texture pool is created after the kart texture;
  - `loadKartSprite`, for the effect texture loads;
  - `layoutTrack`, for effect sizes;
  - the kart block of `render`.
  - Not touched: `step`, Start/Stop, capture, events, the state transaction in `SelectTrack`, and race logic.
- New files under `addon/AzerothKart/Assets/Effects/`, a new effect-sprite build script, and `scripts/build_wc3_kart.py` (emitter points).
- `tests/test_presentation.lua`; visual assertions and the explicit counts in `tests/test_ui.lua` (shared).
- Docs:
  - a new effects art sheet;
  - ASSETS, CHANGELOG, an API_CONTRACTS proposal and README_ADDON;
  - required paths in `validate_project.py`;
  - this handoff.

The vehicles that follow will need a stopped-only kart selector next to the Track button. That control callback in `UI.Create` will be proposed for Codex review before integration.

## Owner instructions this session

- "You can update the addon directly here: C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\AzerothKart And feel free to push to github as well https://github.com/PhilForever/AzerothKart Now, continue work on Mirage Raceway"
  - Follow-up answers: fast-forward to Codex's review commit; push **only** `claude/track-ui`; the owner runs in-game checks personally.
- After the scenery check: "Looks aight … some issues with shadows on the assets around … Feel free to fix that next."
- Then: "Do you have any more plans for Mirage Runway? I'm fairly happy with it, so unless you have something in store for it, let's take a look at the kart you've made. It's decent, but I was more hoping for something like this: https://wc3vault.com/0fbe959f-489b-48f0-82bf-8c4322f1f060 feel free to fetch it and modify it to work in our addon, following our design guidelines of course."
- Answers to Claude's questions:
  - camera: **three-quarter view** with 32 or more directional frames (64 implemented);
  - the model's Read Me ("meant for use, not modification"): "Use it and do your intended edits to it, that readme is outdated."
- Then: "Github is good now, you can push. The trike and shadows are approved by me."

## Branch, commits and deployment

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui`, base `1f8f208` (Codex's review commit) |
| Commits | `76af4aa` scenery v1, `55c542d` docs, `0bf6fd0` scenery shadows, `5734335` docs, `cf71394` `feat: make the Warcraft III Goblin Mortar Trike the default kart`, `064105f` the trike handoff, then the commit containing this revision |
| Installs (owner-authorized) | Each install backed up the target and hash-verified it; backups sit under git-ignored `local-artifacts/installs/`, each with an `install.json`. 1) `1f8f208` (backup `20261020-114116`). 2) `76af4aa` (backup `20261020-122432`). 3) `0bf6fd0` (backup `20261020-165006`). 4) `cf71394` at 17:37 UTC: the trike sheet, `Presentation.lua`, `UI.lua` and `README_ADDON.md` copied, 18 files verified, backup `20261020-173759`. `diff -rq` found the installed folder identical to `addon/AzerothKart` at `cf71394` |
| Push (owner-authorized, branch only) | The owner pushed `claude/track-ui` from Windows; `origin/claude/track-ui` was `812d132`. This session's git proxy refuses `PhilForever/AzerothKart` ("not in this session's authorized repository set"), so later commits also need the owner's push: `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push origin claude/track-ui` |
| Not done | No merge into `main` (still `f923d15`), no tag or release, no client input. Codex's branches and worktree were not touched |

**Shared deployment note:** Codex then installed its combined build. At the start of this task, every file in the live AddOns folder matched `addon/AzerothKart` at `7fcdd89`. Claude installs only from commits that contain `7fcdd89`.

**Workspace notes:**

- `local-artifacts/third-party/goblin-mortar-trike/` (git-ignored) holds the downloaded archive and the extracted model, texture and Read Me used by the build.
- An untracked `Claude outputs/` folder appeared in the worktree. The Claude desktop app created it when a review image was shared, and it holds `shadows-before-after.png`. It is not project content; it was left untracked and uncommitted for the owner to delete or ignore.

**Git environment note:**

- Commits come from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`.
- **Never run `git worktree prune` or `git gc` there**: the recorded gitdir is a Windows path.
- Delete permission in `.git` was granted this session, so commits there no longer leave a stale `HEAD.lock`.

## Completed work: Goblin Mortar Trike (`cf71394`)

- **Source.** The [WC3Vault listing](https://wc3vault.com/0fbe959f-489b-48f0-82bf-8c4322f1f060) archive `GoblinMortarTrike_Updated_.rar` (SHA-256 `f0b4341c…b86b`) is by erwtenpeller and Chriz (Vast Graphics). Only the unit model and its paletted texture are used.
- **Author terms.** The Read Me forbids modification without the authors' permission. The owner says it is outdated and directed this use. The render edits no mesh, UV or texture data. Credits sit in `README_ADDON.md` and the [asset sheet](../art/karts/goblin-mortar-trike.md), and redistribution stays unresolved for release review (ADR 0009).
- **`scripts/build_wc3_kart.py` (new, standard library only):**
  - reads MDX v800 (sequences, materials, geosets, geoset animations, bones/helpers, pivots) and paletted BLP1 with its 8-bit alpha plane;
  - poses the skeleton at the first frame of `Stand` and keeps only the geosets visible there;
  - applies player-1 red team color;
  - renders 64 headings (5.625 degrees apart, from half-angle square roots) with an orthographic camera tilted 36.87 degrees, the scenery's north-west light and a soft shadow along the scenery's shadow vector;
  - uses 4×4 supersampling with paintkit's integer resolve, and gives each frame a transparent border and bled edges;
  - verifies input hashes, and supports `--check` and `--preview`.
- **Asset.** `Assets/Karts/GoblinMortarTrike.tga` is a 1024×1024 sheet, 8×8 frames of 128×128 texels. Each frame covers 41×41 world units with its center 3 units east of the kart. The trike is 21 wide by about 30.3 long, against the 17×31 physics body; visual only.
- **`Presentation.lua`:**
  - optional sheet fields `frames`, `columns`, `pivotX` and `pivotY`;
  - pure `kartFrame(sprite, heading)` (nearest frame, wraps turns) and `kartFrameCoords(sprite, frame)`;
  - `DEFAULT_KART = "goblin_mortar_trike"`, with `goblin_drag_car` still registered.
- **`UI.lua` (Claude regions only):**
  - `loadKartSprite`: for a sheet, `SetTexture` must return `true`, then the frame-0 `SetTexCoord` and a neutral `SetVertexColor` must succeed; otherwise the primitive is kept.
  - `render`, kart block: show the nearest frame, write the crop only when the frame changes, anchor at the pose plus pivot times scale, and do not rotate. Single images keep the old rotated path.
  - Comment updates in `layoutTrack`.
  - Not touched: `step`, Start/Stop, capture, events, `SelectTrack` and counts.
- **Tests:**
  - `test_presentation.lua` has a sheet branch: grid, square frames, transparent borders, minimum vehicle size, crops matching the layout, distinct opposite headings, nearest-frame lookup and wrap-around.
  - `test_ui.lua` (shared, visual assertions only):
    - the trike path, plus `DRAG_CAR_PATH`;
    - `kartAnchor`/`kartFaces` helpers used by the camera, terminal-pose and cadence checks;
    - a sheet block: frame per heading, crop written only on change, no rotation, pivot anchoring, quads 41 and 61.5;
    - a single-image block keeping the rotated drag-car path;
    - fallback modes `uv missing` and `uv throws`;
    - the interpolation test pinned to the rotating drag car so it still sees exact headings;
    - the simulation-equivalence drive unchanged.
- **Docs:**
  - the [asset sheet](../art/karts/goblin-mortar-trike.md) and review PNG;
  - an `ASSET_SOURCES` import record and row;
  - an `API_CONTRACTS` proposal for directional sheets;
  - status sentences in README, ASSETS, MIRAGE_RACEWAY and INDEX;
  - README_ADDON kart text and credits;
  - a CHANGELOG entry and three more required paths in `validate_project.py`.

## Tests performed (final code, `cf71394`)

| Command / check | Result |
|---|---|
| `python3 scripts/build_wc3_kart.py --source local-artifacts/third-party/goblin-mortar-trike --preview` | **GENERATED**, SHA-256 `a723b06721c5039c072f7c40c0223fc3ae774d91bca53f211eed249663ee3208` on Python 3.10 (developer machine), identical to Python 3.13 (cloud). 64 frames with 2,376–3,148 opaque texels each; the extent fits the frame window |
| `python3 scripts/test_lua.py --runtime both` (developer machine) | **PASS**: 29 files parsed; suites pass in Lua 5.1 and 5.4. Includes `offline kart sheet goblin_mortar_trike: 1024x1024 TGA, 64 frames of 128x128` and `mock kart sheet: 1 creation load, nearest-heading frames unrotated, vertex tints only, 8 refused-load fallbacks; single-image rotation path kept; 900-frame Mirage drive identical in sprite/primitive mode through tick 1275` |
| `python3 scripts/build_kart_sprites.py --check` | CHECK PASS (drag car unchanged) |
| `python3 scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail; the new required paths and doc links pass |
| `git diff --check`, `git diff --cached --check` | Clean |
| Visual review (offline) | Close-ups of 8 headings, the full sheet, in-context tiles at 1080p/1440p sizes, tints, and four emulated 800×480 camera views at the owner's 1.5 px per world unit |
| Install verification | `install_ak.py`: backup verified, 4 files copied, 18/18 hashes matched; independent `sha256sum` and `diff -rq` agree |

The scenery and shadow checks from earlier this session also passed: the background `--check` gave `cd5aecb9…c567e`, identical on both Pythons.

**NOT RUN:**

- a Claude-observed WoW Forever run (the owner's own approval of the trike and shadows is recorded below);
- `tests/test_install_local.ps1`;
- Windows `validate_project.py`;
- FPS, memory or load-time measurement of the 4 MiB sheet;
- multiplayer.

## WoW Forever checks (owner-approved; itemized results not reported)

**Owner approval, recorded 2026-10-20 ~20:15 CEST:** "The trike and shadows are approved by me." Evidence: [the approval record](../evidence/2026-10-20-trike-and-shadows-owner-approval.md). The items below were not reported one by one, and no Print Probe output or timing came with the approval, so item 5's counts and load cost stay unmeasured. The list stays as the re-check procedure for later kart or scenery changes.

**Fully restart the client**: a new file was added and Lua changed. On Mirage and Test Oval:

1. The kart is the goblin trike in three-quarter view, not the orange rectangle or the old drag car.
2. Turning steps smoothly through the headings. The mortar leads, with no mirroring, flipping, or slivers of neighboring frames.
3. The trike's shadow falls south-east, like the scenery's.
4. Drift/boost washes appear.
5. No hitch at load; Print Probe shows 9/111/13.
6. The scenery shadows touch their objects (the earlier check).

Details: [trike check](../art/karts/goblin-mortar-trike.md#client-check), [scenery check](../art/mirage-background.md#client-check).

## Known limitations

- Headings are quantized to 5.625 degrees; a 4 MiB sheet bought the 128-texel frames. No wheel or exhaust animation, and the team color is fixed red.
- The baked shadow is alpha-blended (darkened "over" the ground) rather than multiplied like the scenery shadows, and phase tints also tint the shadow. Both are subtle.
- The art extends past the 17×31 physics body: 2 units wider each side, plus height and shadow. Near the top map edge, about 2 canvas pixels can show past the canvas.
- This is the first `SetTexCoord` use on the kart texture (the background already uses it in the client). The guarded load falls back to the primitive if it refuses.
- `UI.SelectTrack` (Codex) still shows `Mirage Raceway blockout | …`; proposed `Mirage Raceway | …`.

## Recommended next visual milestone

1. Kart polish:
   - a few wheel and exhaust frames per heading, or pooled smoke and boost VFX (counts need review);
   - optionally, a multiplicative kart shadow like the scenery's (the owner approved the current one).
2. More roster vehicles through the same renderer, for example the Steam Tank, Gyrocopter or Gryphon Rider candidates in ASSET_SOURCES. It handles MDX v800 with paletted BLP1; JPEG-compressed BLPs would need a decoder.
3. Mirage polish: the status text (Codex) and wall-strip styling.

## Changes Codex must review

- `UI.lua`: `loadKartSprite` and the kart block of `render` (visual regions), plus comments.
- `tests/test_ui.lua` (shared): the visual assertions and helpers listed above. No capture, lifecycle, clock or race assertion was relaxed. The interpolation test now runs on the single-image kart, so it can still check exact headings.
- `docs/API_CONTRACTS.md`: the directional-sheet proposal and the `DEFAULT_KART` change.
- Presentation data: new optional fields and two pure helpers; no simulation-facing change.
- Asset budget: kart texture 4 MiB raw (was 32 KB); UI counts unchanged.
- Third-party art: provenance and status in the asset sheet and ledger.
- Deployment state: the AddOns folder is at `cf71394`.

## Pending PROGRESS ledger entries (integrator to append; PROGRESS.md was deliberately not edited)

> ### 2026-10-20 ~13:45–14:30 CEST — Claude / `claude/track-ui`, Mirage scenery v1
>
> - Original procedural `Background.tga`, registered per pixel to `isDrivable`, with no-scenery-on-road, clearance, contrast and landmark assertions; shared `paintkit.py`.
> - `test_lua.py --runtime both` PASS. Background `47077384…2ac37` identical on Python 3.13 and 3.10.
> - Installed `1f8f208` and `76af4aa` (verified).
> - The owner's screenshot shows scenery v1 and the drag-car sprite rendering; shadows flagged (evidence: `docs/evidence/2026-10-20-mirage-scenery-owner-check.md`).
>
> ### 2026-10-20 ~16:00–17:00 CEST — Claude / `claude/track-ui`, Mirage scenery shadows
>
> - Attached, height-swept, multiplicative shadows with max-combined overlaps; swallowtail banners and crisp oil splats.
> - Background `cd5aecb9…c567e` identical on both Pythons; suite PASS.
> - Installed `0bf6fd0` (verified).
>
> ### 2026-10-20 ~18:00–19:45 CEST — Claude / `claude/track-ui`, Goblin Mortar Trike kart
>
> - Default kart rendered from the Warcraft III model by erwtenpeller and Chriz (WC3Vault) as 64 three-quarter headings in a 1024×1024 sheet. No mesh or texture edits; credits given. The Read Me requests permission for modification and the owner calls it outdated; redistribution unresolved.
> - Presentation directional-sheet fields and helpers; UI nearest-frame display with guarded `SetTexCoord`.
> - Sheet `a723b067…3208` identical on Python 3.10 and 3.13; `test_lua.py --runtime both` PASS; installed `cf71394` (verified).
> - Claude did not run the client; the owner's approval follows. The push stays blocked by session credentials.
>
> ### 2026-10-20 ~20:15 CEST — Owner approval: Goblin Mortar Trike and scenery shadows
>
> - After the verified install of `cf71394`, the owner wrote: "The trike and shadows are approved by me." Evidence: `docs/evidence/2026-10-20-trike-and-shadows-owner-approval.md`.
> - Owner acceptance only: no screenshot, Print Probe output or timing figures, and Claude did not run the client. Camera motion, map edges and handling stay NOT RUN; redistribution of the Warcraft III model stays open for release review.

## Integration (manual, after review; not executed)

```powershell
git log --oneline 1f8f208..claude/track-ui
git diff 1f8f208..claude/track-ui --stat
python scripts/test_lua.py --runtime lua51 --tests presentation ui
python scripts/build_mirage_background.py --check
python scripts/build_kart_sprites.py --check
python scripts/validate_project.py
```

`build_wc3_kart.py --check` additionally needs the third-party source folder; see the asset sheet. `claude/track-ui` builds on `1f8f208`, and `main` is still `f923d15`. A fast-forward of `main` needs explicit integration authorization; do not reset, rebase or force anything to make it apply.
