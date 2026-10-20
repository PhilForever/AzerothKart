# Claude handoff — drift and boost effects; vehicles next

Prepared 2026-10-21, Europe/Oslo, by Claude (rendering/UI/sprites owner).

The base is `7fcdd89`, Codex's `codex/menu-integration`, reached by an owner-approved fast-forward. This session's commits on `claude/track-ui` so far:

1. `f675610`, the scope reservation;
2. `c6e1b5e`, drift and boost effects;
3. this handoff.

The vehicles task that follows is still reserved (below). M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open. The previous handoff, covering the Goblin Mortar Trike and the owner's approval of it and the scenery shadows, is in Git at `812d132`.

## Owner instructions

- "Start with drift and boost effects, then implement more vehicles."
- Answers to Claude's questions:
  - fast-forward onto Codex's integration commit `7fcdd89`: "Yes, fast-forward (Recommended)";
  - effects style: "Sparks, smoke and flame (Recommended)".
- Earlier: the owner pushed `claude/track-ui` from Windows (`812d132`) and approved the trike and shadows ([evidence](../evidence/2026-10-20-trike-and-shadows-owner-approval.md)).

## Active reservation (from 2026-10-20, about 21:05 CEST)

**Task:** drift and boost effects (done in `c6e1b5e`), then more roster vehicles (next).

**Base:** `7fcdd89`, which already contains every earlier Claude commit.

**Reserved for Claude:**

- `addon/AzerothKart/Presentation.lua`: effect helpers, kart data and anchors in `KART_SPRITES`.
- `addon/AzerothKart/UI.lua`:
  - the visual layout part of `UI.Create`;
  - `loadKartSprite`;
  - the effect helpers placed before `layoutTrack`;
  - `layoutTrack`;
  - the kart block of `render`.
  - Not touched: `step`, Start/Stop, capture, events, the state transaction in `SelectTrack`, and race logic.
- `addon/AzerothKart/Assets/` (Effects, Karts), `scripts/build_effect_sprites.py`, `scripts/build_wc3_kart.py` and `scripts/preview_effects.py`.
- `tests/test_presentation.lua`; visual assertions and explicit counts in `tests/test_ui.lua` (shared).
- Docs:
  - `docs/art/effects/` and `docs/art/karts/`;
  - ASSETS, CHANGELOG, the API_CONTRACTS proposal and README_ADDON;
  - required paths in `validate_project.py`;
  - this handoff.

The vehicles need a stopped-only kart selector next to the Track button. That control callback in `UI.Create` will be proposed for Codex review before integration.

## Branch, commits and deployment

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui`: fast-forwarded from `812d132` to `7fcdd89`, then `f675610`, `c6e1b5e` and this commit |
| Install (owner-authorized) | `c6e1b5e` at 22:18 UTC on 2026-10-20. Before it, all 20 installed files matched `7fcdd89`. Copied: the two new atlases, `Presentation.lua`, `UI.lua` and `README_ADDON.md`; 22 files hash-verified. Backup and `install.json` under `local-artifacts/installs/20261020-221843/`. Afterwards `diff -rq` found the folder identical to `addon/AzerothKart` at `c6e1b5e` |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push origin claude/track-ui` |
| Not done | No merge into `main` (still `f923d15`), no tag or release, no client input. Codex's branches and worktrees were not touched |

**Shared deployment note for Codex:** the live AddOns folder now carries `c6e1b5e`, which is your `7fcdd89` plus the effects. Read `local-artifacts/installs/20261020-221843/install.json` in the Claude worktree before another install.

**Workspace notes:**

- `local-artifacts/third-party/goblin-mortar-trike/` (git-ignored) holds the trike's source files.
- `local-artifacts/bundles/` (git-ignored) holds the git bundles that carried commits from Claude's cloud clone to this worktree.
- The untracked `Claude outputs/` folder, created by the desktop app, is still left for the owner.

**Git environment note:**

- Commits are made in a cloud clone with this repository's local identity, then moved here as git bundles and fast-forwarded, so the hashes are identical.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`.
- **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths.
- Delete permission in this worktree and in `.git` was granted again this session, for git's own lock and file replacement.

## Completed: drift and boost effects (`c6e1b5e`)

Owner's chosen style: sparks, smoke and flame. Details and the client checklist are in [the effects sheet](../art/effects/drift-boost.md).

**What players see:**

- **Drifting:** pale dust puffs from alternating rear tyres, and a spark spray from behind the rear wheels in the meter's colours: blue while charging, gold at tier 1, magenta at tier 2. The spray thickens with the charge and thins while a correction holds it.
- **Boosting:** a flickering two-layer flame at each exhaust that shrinks as the boost runs out, plus trailing soot with a burst when the boost fires.

**Assets.** `Assets/Effects/Particles.tga` (256×128: four puffs, sixteen spark directions) and `Flame.tga` (512×256: 32 flame directions seen by the sheet camera). They are original, painted by the new `scripts/build_effect_sprites.py`, white or near-white, and coloured at runtime.

**`Presentation.lua`:**

- data: `EFFECTS` and `DEFAULT_EFFECT_ANCHORS`;
- pure helpers: `newEffects`, `clearEffects`, `advanceEffects`, `particleAt` and `effectCoords`;
- an `effects` field on both registered sprites.
- The trike's anchors are its model's own emitters, listed by the new `build_wc3_kart.py --emitters`.
- Effect time is the interpolated tick, and a seeded Park–Miller sequence makes identical states give identical particles. Only the effect state is written.

**`UI.lua` (Claude regions):**

- new local functions `createEffects`, `hideEffect`, `placeEffect`, `resetEffects` and `renderEffects`, placed before `layoutTrack`, with one call each in `UI.Create`, `layoutTrack` and `render`.
- 38 textures are created once with explicit sublevels:

  | Texture | Layer and sublevel |
  |---|---|
  | Smoke | ARTWORK 6 |
  | Sparks | OVERLAY −2 |
  | Flames, pipe facing the camera | OVERLAY 2/3 |
  | Flames, pipe on the far side | OVERLAY −4/−3 |

- Guarded atlas loads plus crop and tint probes; any refusal disables every effect without touching the kart or race.
- No `SetRotation` and no `SetBlendMode`.
- Quads that would cross the canvas edge are hidden, and map selection clears every effect.

**Tooling.** `scripts/preview_effects.py` runs the addon's Lua against a recording widget mock and composites [a review drive](../art/effects/drift-boost-review.png).

## Tests performed (`c6e1b5e`)

| Command / check | Result |
|---|---|
| `python3 scripts/build_effect_sprites.py --check` | **CHECK PASS** on Python 3.13 (cloud) and Python 3.10 (developer machine). Particles `15bf541f…2341`, Flame `98254d4b…f98f`: identical bytes on both |
| `python3 scripts/build_wc3_kart.py --source <trike> --check` | CHECK PASS (cloud); the trike sheet `a723b067…3208` is unchanged. `--emitters` lists the model's nine particle emitters |
| `python3 scripts/build_kart_sprites.py --check` | CHECK PASS |
| `python3 scripts/test_lua.py --runtime both` | **PASS** on both machines; 34 files parsed, full suite |
| What the suite now covers | The atlas layout, borders and directions. Emission per tier, boost flames and burst. No state writes, restart clearing and determinism. A Mirage drive showing dust, all three spark tiers and flames on both sides of the kart, at most 31 effect textures at once and always inside the canvas. A refused atlas. Simulation identical with effects on, refused or under the primitive kart |
| `python3 scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail |
| `python3 scripts/preview_effects.py` | Review image reviewed: dust, sparks, flames and soot read clearly on the Mirage lane, and flames point backward at every heading tried |
| Install verification | Backup verified, 5 files copied, 22/22 hashes matched; `diff -rq` agrees |

**NOT RUN:**

- the effects' appearance and cost in WoW Forever;
- `tests/test_install_local.ps1`;
- Windows `validate_project.py`;
- FPS or memory measurement;
- multiplayer.

## Client check (owner; NOT RUN)

Fully restart the client, because the atlases are new files. Then follow [the effects checklist](../art/effects/drift-boost.md#client-check-not-run), which covers:

- dust and tier-coloured sparks while drifting;
- flames and soot on release;
- flames in front of the kart or behind its body, depending on the camera side;
- no boxes, fringes or edge spill;
- no hitch;
- Print Probe 9/151/13.

## Changes Codex must review

- **`UI.lua`:** the effect helpers and their three call sites listed above. There is no change to `step`, Start/Stop, capture, events or `SelectTrack`'s transaction.
- **`tests/test_ui.lua` (shared):**
  - the mock records per-object `SetTexCoord`/`SetDrawLayer` writes;
  - counts use `EFFECT_TEXTURES` (38) and `UI_TEXTURES` (151);
  - the grass draw-layer, camera-crop and kart-crop assertions count only their own textures;
  - new blocks for effects and for a refused atlas;
  - the scripted drive also runs with effects refused and compares every snapshot field.
  - No capture, lifecycle, clock or race assertion was relaxed.
- **Shared budget:** +38 pooled textures, giving 9/151/13; the atlases add 640 KiB of raw texture data. Current-count statements were updated in README, ARCHITECTURE, TEST_PLAN, API_CONTRACTS, ASSETS, README_ADDON and MANUAL_CLIENT_CHECKLIST. Historical CHANGELOG and PROGRESS entries were not touched.
- **`docs/API_CONTRACTS.md`:** the proposed drift/boost effects contract.
- **Presentation:** new pure helpers and data, and the optional sprite `effects` field. Nothing simulation-facing changes.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-21 ~00:20 CEST — Claude / `claude/track-ui`, drift and boost effects
>
> - Owner-approved fast-forward to `7fcdd89`. Tier-coloured drift sparks and tyre dust; boost flames and soot. Two original atlases (`build_effect_sprites.py`). Pure Presentation effect helpers; 38 pooled UI textures (9/151/13).
> - Atlases byte-identical on Python 3.10 and 3.13. `test_lua.py --runtime both` PASS on both machines. Installed `c6e1b5e` (verified, backup `20261020-221843`).
> - **NOT RUN:** client appearance and cost.

## Next: more vehicles (reserved)

The release target is eight ready karts (ADR 0010).

**Candidates.** The ASSET_SOURCES rows for the Steam Tank, Gyrocopter and Gryphon Rider have unknown authors and list Warcraft III game-texture dependencies, which are not available here. The next step is to find vehicle models that ship their own textures, check their terms, and let the owner pick.

**Plan:**

1. Generalize `build_wc3_kart.py` to a vehicle table.
2. Register each sheet with effect anchors from its own emitters.
3. Add a stopped-only **Kart** button that cycles the registered karts. Vehicles are cosmetic; the kart choice is not saved.

New callbacks and counts go to Codex for review.
