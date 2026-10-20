# Claude handoff — first Goblin Drag Car sprite

Prepared 2026-10-20, Europe/Oslo, by Claude (rendering/UI/sprites owner). First deliverable of the Claude development track: one original Warcraft III-inspired goblin drag-car sprite, integrated with guarded loading and a primitive fallback. M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open.

## Branch and commits

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui` |
| Base | `5570968` (`docs: establish Codex and Claude handoff contracts`), clean status at entry, verified with `git branch -vv`, `git status --short`, `git log` |
| Feature commit | `520275e07990a626ac25818402eeee55ab956d0d` — `feat: add original Goblin Drag Car kart sprite with primitive fallback` |
| Docs commit | The commit containing this handoff and proposed ADR 0009; resolve with `git log -1 claude/track-ui` |
| Not done | No merge, fast-forward, push, tag, install or client input. `main`, `codex/handoff-contracts` and Codex's worktree were not touched |

**Git environment note for future sessions:** these commits were made from a Linux shell on the developer machine. That shell mounts the Claude worktree plus the shared `.git` folder and sets `--git-dir=.git/worktrees/AzerothKart-Claude`, with `core.createObject=rename`, `gc.auto=0` and `gc.worktreePruneExpire=never`.

From that environment, `git worktree list` marks this worktree **prunable**, because its recorded gitdir is a Windows path. **Never run `git worktree prune` or `git gc` there.**

One stale `HEAD.lock` and one temp object, both left by this session's git commands, were removed after the owner allowed deletion in `.git`. `git fsck --connectivity-only` passed afterwards.

## Completed work

- **Art:** an original strict-overhead, north-facing goblin dragster. It has a long red nose with a hazard stripe and iron ram on a narrow front axle, a big-eared goblin in brass goggles, red/yellow explosive canisters, and an oversized supercharged engine with glowing exhaust stacks. Huge rear slicks and a rocket bell sit at the tail. Narrow front versus wide rear keeps heading readable when rotated. Lighting is neutral and overhead, with no baked directional shadow.
- **Asset:** `addon/AzerothKart/Assets/Karts/GoblinDragCar.tga`, a 64×128, 32-bit straight-alpha, uncompressed, bottom-left-origin TGA (32,786 bytes, SHA-256 `cc7c1c69…126a`). It is drawn as a 20×40 world-unit quad, 3.2 texels per unit. Every visible texel is inside the 17×31 body, so the sprite cannot visually exceed the clearance of the 18-unit wall inset. Transparent texels carry bled edge color, which prevents filtering fringes.
- **Pipeline:** `scripts/build_kart_sprites.py` uses only the standard library and paints deterministically with layered SDF shapes, 4×4 supersampling and exact integer filtering. `--check` verifies exact bytes plus footprint, border, pivot, symmetry, north-facing landmarks and edge-bleed invariants; `--preview` writes the PNG master and an in-context review sheet. Python 3.13 (cloud) and 3.10 (local Linux shell) produced identical bytes.
- **Integration:**
  - `Presentation.KART_SPRITES/DEFAULT_KART/KART_FOOTPRINT_*` is pure, read-only data.
  - `UI.lua` loads the sprite once at creation: `SetTexture` must return `true` and a neutral `SetVertexColor` must succeed before `UI.kartSprite` is set.
  - The kart Texture is sized to the quad times the view scale: 20×40 on Test Oval, 30×60 on Mirage.
  - Drift/boost phases tint the sprite with `SetVertexColor`. This fixes the Codex-identified hazard: only the primitive path calls `SetColorTexture`.
  - Any refused load (false, nil, throw, missing `SetTexture`/`SetVertexColor`, throwing tint) keeps the original 17×31 orange primitive and phase colors, with no retry.
  - Rotation and anchoring are unchanged: the interpolated center, rotated by `heading - math.pi/2`.
  - Explicit counts stay 9/111/13.
- **Docs:** [asset sheet](../art/karts/goblin-drag-car.md) covering dimensions, format, transparency handling, reproduction, provenance and client check; review sheet and master PNGs; and factual "placeholder kart" updates in README, README_ADDON (including a full-restart note for new files), ASSETS, ARCHITECTURE, MIRAGE_RACEWAY and INDEX. Also a CHANGELOG entry and the API_CONTRACTS proposal.
- **Owner direction (mid-session):** the owner asked not to be afraid of reusing Warcraft III assets (precedent: WIIIUI) while keeping the design guidelines. Recorded verbatim in [ASSET_SOURCES](../art/ASSET_SOURCES.md) and as [proposed ADR 0009](../adr/0009-warcraft-iii-asset-reuse.md). The drag car stays original because no WC3 drag-car model was found to reuse.

## Files changed

Runtime and tools:

- `addon/AzerothKart/Assets/Karts/GoblinDragCar.tga` (new)
- `scripts/build_kart_sprites.py` (new)
- `addon/AzerothKart/Presentation.lua`: data appended before the namespace export; existing functions untouched.
- `addon/AzerothKart/UI.lua`: only `layoutTrack` (kart sizing), new local `kartColors`/`kartSpriteTints`/`loadKartSprite`/`tintKart`, the tint block in `render`, and one `loadKartSprite()` call in the visual-layout part of `UI.Create`. A diff audit found no change to `step`, `Start`, `Stop`, `InterruptCombat`, `ReleaseInput`, `OnUpdate`, `HandleEvent`, `OnCombatEnded`, `keyEvent`, `SelectTrack` or capture/clock wiring.

Tests and validation:

- `tests/test_presentation.lua`: registry checks plus the TGA re-read against the Lua metadata.
- `tests/test_ui.lua`, shared: mock and visual assertions only; see the review list below.
- `scripts/validate_project.py`, shared: +3 required paths.

Docs:

- `docs/art/karts/goblin-drag-car.md`, `-master.png`, `-review.png` (new)
- `docs/art/ASSET_SOURCES.md`, `docs/art/MIRAGE_RACEWAY.md`
- `docs/ASSETS.md`, `docs/ARCHITECTURE.md`, `docs/API_CONTRACTS.md`, `docs/INDEX.md`
- `README.md`, `addon/AzerothKart/README_ADDON.md`, `CHANGELOG.md`
- `docs/adr/0009-warcraft-iii-asset-reuse.md` (new, proposed)
- this handoff

Unchanged, verified by `git diff --stat 5570968` over those paths: Physics, Track, MirageRaceway, Input, Loop, Checkpoints, Laps, Race, Performance, Core, both TOCs, `tests/run.lua`, all simulation tests, `docs/PROGRESS.md`, the Codex handoff, AGENTS.md and CLAUDE.md.

## Tests performed

All were run from the developer machine's Linux shell with Python 3.10.12 and pinned `lupa==2.8` installed outside the repo.

| Command / check | Result |
|---|---|
| Baseline before edits: `python3 scripts/test_lua.py --runtime both` | PASS on `5570968` |
| `python3 scripts/test_lua.py --runtime both` | **PASS** — 29 Lua files parsed; all 16 modules in Lua 5.1 and 5.4. This includes the v6 10k-tick replay, plus the new checks below |
| Asset re-read (in the suite) | TGA header, size and alpha re-read against `Presentation.KART_SPRITES`: 3,190 visible/2,562 opaque texels inside the 17×31 body, centered, nose north, open front corners, rear slicks south |
| Sprite mode (in the suite) | One creation load, vertex tints for all five phases, no `SetColorTexture` on the sprite, no reload across starts/maps, unchanged-phase write caching, 9/111/13 |
| Six refused-load modes (in the suite) | Each keeps the primitive at 17×31 and 25.5×46.5, with the original colors, a playable Mirage session and no retry |
| Simulation equivalence (in the suite) | A 900-frame scripted Mirage drive with irregular frame times reached tick 1275 and passed through charge, both tiers and a real boost. Every Physics/race/checkpoint field matched at every frame between sprite and primitive mode, and every frame showed the tint for the actual state |
| `python3 scripts/build_kart_sprites.py --check` | **CHECK PASS**, SHA-256 `cc7c1c6928501bcb9943040c13c478efb7ac08ddab47e7fa527e11f7d3bb126a`. Identical bytes from Python 3.13 in the cloud workspace |
| `build_mirage_background.py --check`, `build_mirage_layout.py --check` | CHECK PASS (unchanged; SHA `27a5e56a…7714`) |
| `python3 scripts/validate_project.py` | All checks pass except **2 pre-existing** failures: absolute `C:/Users/bakke/.codex/...` links in PROGRESS.md, which only resolve on the Windows host. The same result appears at baseline `5570968` |
| `git diff --check`, `git diff --cached --check` | Clean |
| Package/install file walk | 17 addon files, sprite included. The installer and release builder enumerate the whole addon folder |
| Visual review | Generator review sheet emulating rotated straight-alpha bilinear quads over the real Mirage background at about 1080p/1440p sizes and eight headings, plus five tints and Test Oval. Inspected; no fringes, correct facing. This is an offline emulation, not the client |
| API documentation | Build-matched source pinned in MIRAGE_RACEWAY documents `SetTexture(...) -> success`, `SetColorTexture` and `SetRotation` on `SimpleTextureBaseAPI`, and `SetVertexColor(r,g,b,a?)` on `SimpleRegionAPI`. Calls remain guarded |

**NOT RUN:**

- WoW Forever client checks (below)
- `tests/test_install_local.ps1` (no PowerShell in this shell)
- `validate_project.py` on Windows
- installation
- multiplayer and performance measurement

## Tests requiring WoW Forever (all NOT RUN)

Follow [the asset sheet's client check](../art/karts/goblin-drag-car.md#client-check-not-run) after an authorized, Codex-coordinated install. **Fully restart the client**: the sprite is a new file. Check:

- sprite visible on Test Oval and Mirage instead of the orange rectangle;
- transparent corners, with no box, halo or fringe;
- nose north at spawn and leading in all directions while driving, with no mirror or flip;
- blue/gold/magenta/cyan phase washes, and the image never becomes a solid rectangle;
- `/dump AzerothKart.UI.kartSprite ~= nil` returns true;
- Print Probe shows 9/111/13.

Open client questions:

- Does `SetTexture` return `false` for a missing file?
- Is there minification shimmer at Test Oval scale 1, where `filterMode` might help?
- Does default pixel snapping make the moving sprite jitter?

## Known limitations

- Client semantics above are unverified; offline mocks cannot prove alpha, filtering or load behavior.
- Multiplicative tinting of a warm sprite is subtle by nature (Tier 1 gold is the weakest). The meter and HUD text still carry every phase.
- Single default kart: no roster or garage selection, no separate world-oriented shadow, no exhaust/boost VFX.
- At Test Oval's scale 1, the 64×128 texture is drawn about 3× minified with no guaranteed mipmaps, so some aliasing is possible. Mirage's scale 1.5 is the design target.
- `UI.kartSprite` is a public diagnostic field, read-only by convention only, like the other UI state.

## Recommended next visual milestone

1. **Run the short in-client sprite check above** with a coordinated install. It needs the client and an authorized deploy.
2. **Mirage scenery v1:** repaint `Background.tga` against the unchanged geometry (textured salt and dirt, worn road edges, tire marks, rock borders, pit camps baked in), reusing Warcraft III terrain and doodad material under ADR 0009 once accepted, with ledger rows per file.
3. **Kart grounding/VFX:** a separate world-oriented shadow plus a pooled exhaust/boost flame (+1–3 textures, a reviewed count change), then the contrasting Gnome Drag Car through the same generator and registry.

## Changes Codex must review

- **`tests/test_ui.lua` (shared):**
  - Mock gains `SetVertexColor` recording, `env.texturePaths`, per-path `env.textureModes`, and an `env.onCreateTexture` hook.
  - Six visual assertions changed:
    - texture-load counts are now per path: the kart once at creation, the background once on Mirage selection;
    - kart quad 25.5×46.5 → 30×60 on Mirage (body 25.5×46.5 still asserted via `KART_FOOTPRINT_*`);
    - 17×31 → 20×40 on Test Oval;
    - the drift-tint caching check now watches vertex-color writes.
  - New sprite, fallback and equivalence blocks.
  - No capture, lifecycle, clock or race assertion was changed or relaxed.
- **`UI.Create` (mixed function):** one call inserted after the kart Texture is created; event scripts, controls and initial state are untouched.
- **Public data/contract:** `Presentation` data additions and the marked proposal in `docs/API_CONTRACTS.md`.
- **Shared docs:** the sentence-level updates listed above, `validate_project.py` paths and the CHANGELOG entry.
- **Proposed ADR 0009:** it conflicts with ADR 0005/AGENTS "original/owned assets" wording until the owner and Codex reconcile it. Not applied to AGENTS.md.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was deliberately not edited)

> ### 2026-10-20 ~12:30–13:20 CEST — Claude / `claude/track-ui`, first Goblin Drag Car sprite
>
> **Implemented:**
> - Original procedural 64×128 straight-alpha `Assets/Karts/GoblinDragCar.tga`, drawn as a 20×40 world-unit quad with its visible body inside the 17×31 footprint. Deterministic standard-library generator `scripts/build_kart_sprites.py` (`--check`/`--preview`).
> - `Presentation.KART_SPRITES` metadata; a once-only guarded load in `UI.Create`; `SetVertexColor` phase tints; the primitive kept on any refused load.
> - Physics, race, input, camera and capture unchanged; counts 9/111/13.
>
> **Executed (Linux shell, Python 3.10, lupa 2.8):**
> - `test_lua.py --runtime both` PASS: 29 files, 16 modules, including new asset, sprite, six fallback and sprite/primitive simulation-equivalence checks.
> - `build_kart_sprites.py --check` PASS (`cc7c1c69…126a`); identical bytes on Python 3.13.
> - Background and layout checks PASS.
> - `validate_project.py`: only the 2 pre-existing Windows-path link failures.
> - `git diff --check` clean.
>
> **NOT RUN:** client sprite load, alpha, facing, tint and restart behavior; installer fixtures; installation. Commits `520275e` plus the handoff commit. No merge, push or install.
>
> **Next:** coordinated client sprite check, then Mirage scenery v1.

## Integration (manual, after review; not executed)

```powershell
git log --oneline 5570968..claude/track-ui
git diff 5570968..claude/track-ui --stat
python scripts/test_lua.py --runtime lua51 --tests presentation ui
python scripts/build_kart_sprites.py --check
python scripts/validate_project.py
```

`claude/track-ui` builds on `5570968` (Codex's checkpoint, not yet on `main`). A fast-forward of `main` to the reviewed hash would bring both, and it requires explicit integration authorization. Do not reset, rebase or force anything to make it apply.
