# Codex handoff — shared visual-development baseline

Prepared 2026-10-20, Europe/Oslo. This task is documentation/contract preparation only; no gameplay, runtime API, asset or installed-addon change.

## Branches and starting point

| Item | Verified value |
|---|---|
| Canonical repository | `https://github.com/PhilForever/AzerothKart.git` |
| Published implementation baseline | `f923d15f5cc8f306a0b47ad082587474abd1af8d` on `main`/local `origin/main`; last runtime change `7acab18` |
| Preparation branch | `codex/handoff-contracts`; use its completed documentation checkpoint commit as Claude's starting point |
| Codex checkout | `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart` |
| Existing Claude checkout | `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude`, branch `claude/track-ui`, inspected at `f923d15` with clean status |

The final report gives the preparation commit hash. It can also be resolved with `git log -1 --format="%H %s" codex/handoff-contracts`; use the reviewed commit, not a moving branch tip after later work begins. Main and the Claude worktree were not merged, switched or reset by this preparation. The checkpoint remains local until a separately authorized push/integration.

At entry, the Codex checkout had untracked `CLAUDE.md` and four empty handoff placeholders: root `codex-latest.md`/`claude-latest.md`, plus `docs/handoffs/codex-latest.md`/`claude-latest.md`. The relevant Claude instructions are retained and extended; this requested Codex handoff fills its canonical placeholder. The other three empty placeholders remain untouched/untracked and are excluded from the checkpoint. They contain no hidden implementation work. Do not blindly stage or delete them.

## Verified implementation and evidence scope

| Area | Implemented/offline checked | Actual client evidence / limitation |
|---|---|---|
| Simulation | Pure Physics v6, fifteen state fields, fixed 60 Hz and five-step catch-up; progressive steering, drift tiers/correction grace, boosts, rough-ground slowdown, perimeter constraints | Earlier human drives were observed. New v6 handling acceptance remains pending; the owner found prior v5 drift difficult. |
| Race | Ordered directional gates, repeated laps, 180-tick 3–2–1, GO, exact three-lap finish, retained partial/interrupted results and current-run best lap | Latest countdown/full circuit/finish/restart play is NOT RUN. No persisted best, remote placing or competitive route guarantee. |
| Tracks | Test Oval default; Mirage v1 pure 1024-square capsule road, four gates, stopped selection and load-failure fallback | Opaque Mirage loading and stopped camera crop observed on 70450. Scenery/production track acceptance incomplete. |
| Presentation | Interpolated pose, meter/cues, pooled markers, clamped north-up Mirage camera with 60-world heading look-ahead at scale 1.5 | The stopped close view, larger kart, Start alignment and clipped West strip were observed; moving camera/edges and sustained performance NOT RUN. |
| Input/combat | Alias-aware booleans, deliberate Start, release paths, no automatic resume, once-only active combat interruption, guarded propagation | Prior owner combat smoke confirmed closure/message/normal controls. Full held-input Alt-Tab, repeated-event/taint and stopped-window combat follow-up remain pending; no new combat test is requested. |
| Networking/persistence | No runtime transport, lobby, synchronization, gameplay replay/PRNG, ghosts, AI, item engine or saved records. Core only initializes/preserves a minimal schema marker. | Two-client throughput/latency/loss/throttle/reconnect are unmeasured. A schema value is not persistence acceptance. |

M0/M1/M3 acceptance remains open. The build-first policy permits independent local visual work while manual gaps remain pending; it does not establish multiplayer viability. The owner said the closer view was better, without supplying a scoped moving-camera/handling acceptance result.

## Existing rendering implementation

- Twelve modules load in the same order in both TOCs; `_G.AzerothKart` is exported by Core for diagnostics. Read [API_CONTRACTS](../API_CONTRACTS.md) before using any state.
- `UI.lua` currently mixes the local simulation controller with rendering; there is no separate `Renderer` module or immutable render-snapshot API. Treat `UI.state`, previous state, race/lap/checkpoint aliases and track data as borrowed read-only values.
- Window 856×762, canvas 800×480. Test Oval retains 64 outer and 32 island raster Texture bands; they remain allocated but hidden on Mirage.
- Mirage uses one original opaque `Assets/Tracks/SaltFlats/Background.tga`, cropped through reusable camera offsets/UVs. Uniform scale 1.5 gives a 25.5×46.5 displayed placeholder kart and 168-wide road. Art is a geometry blockout, not final scenery.
- Kart is one orange/tinted primitive Texture, centered on the projected pose and rotated by `heading - math.pi/2`. **Sprite hazard:** `render` calls `SetColorTexture` when drift/boost phase changes; merely setting a sprite file will be overwritten. Adapt only the visual tint/fallback path when integrating the first sprite.
- Gates/walls reuse pooled Texture regions and manually clip projected axis-aligned rectangles. No general sprite clipping, atlas/animation, foreground or VFX subsystem exists.
- Explicit allocation baseline is 9 frames/111 textures/13 font strings, excluding Core's event frame, templates/native internals and other addons. No per-tick/render UI creation, asset loads or chat output. No measured general CPU/GPU/FPS limit has been established.

## Ownership and interfaces to preserve

[AGENTS.md](../../AGENTS.md) is the shared authority; `CLAUDE.md` begins with a valid `@AGENTS.md` reference to it. Import/reference was checked statically; no Claude Code session was launched for this checkpoint.

Claude owns Presentation math, artwork, drawing, HUD/layout, animation/VFX and visual feedback. Codex owns Physics/Track/Mirage collision geometry, Input, Loop, Race/Laps/Checkpoints, Core, timing diagnostics and future networking. Contract/architecture, integration coverage and performance budgets are shared.

`UI.lua` requires a function-level reservation: Claude may improve drawing/layout/render/HUD bodies; Codex owns `step`, `Start`, `Stop`, `InterruptCombat`, `ReleaseInput`, `OnUpdate`, key/event handlers and authoritative state/reset/failure behavior. `Create` and `SelectTrack` mix these scopes and need explicit coordination for cross-boundary edits. Do not silently refactor the controller into a new API during a sprite task.

Preserve these invariants:

- Physics state has `x/y/heading/speed` and drift/contact fields, **no** stored `vx/vy` or collision-normal/event API. `speed` is signed; heading is radians, +X east/+Y north and counterclockwise. Travel is heading minus slip; cosmetic derived velocity can differ from actual clamped displacement.
- Rendering never changes authoritative fields, input samples, gate order, geometry, lap awards, tick accounting or finish/stop rules. Camera and interpolated coordinates never feed simulation.
- Use 60 Hz, bounded catch-up and the existing previous/current interpolation; count race time from integer ticks, not UI elapsed or animation frames. Preserve the false callback on the exact finishing step.
- Track dimensions/origin, single uniform scale, north-facing art/pivot and directional gate semantics remain as documented. Painted terrain/props do not become colliders; Mirage's cached geometry cannot be safely edited in-place.
- Preserve failed map/sprite load fallbacks, deliberately stopped selection, active button guard and `trackClickBlocked` mouse-down latch. A click releasing capture must not discard its result by also switching maps.
- Preserve input/combat guards and existing tests. A new image/VFX cannot award boosts/laps, consume WoW movement or bypass restricted/secret APIs.

## Known bugs, debt and client limits

- Flat blockout and primitive vehicle are intentional unfinished visuals; no roster, production sprite alpha/pivot validation, animation, minimap or foreground layers.
- UI/controller coupling and public mutable diagnostic tables are integration hazards; the documented read-only rule is convention, not runtime access enforcement.
- Collision is a point-center perimeter clamp with an 18-unit inset; road edges are traversable rough terrain. No swept arbitrary shape/prop/kart collision. `impacts` counts contact ticks, not unique crashes.
- Latest v6 handling, moving camera/edge transitions, full current race UI, long driving sessions, memory/CPU/GPU/FPS and supported-scale matrix remain unaccepted. Same-runtime replay is not cross-client determinism or anti-cheat.
- On verified build 1.60.1/70450, interface16001/project18/Camelot, `IsGameWindowFocused` and `IsWindowFocused` are absent. Idle Alt-Tab is scoped historical evidence; held throttle released outside the app is not proven safe. Do not invent another focus API.
- Combat/text-focus/keyboard/propagation APIs and registered events were observed, but availability is not unrestricted call permission or a full taint pass. Keep propagation setters out of combat and defer restoration correctly.
- An earlier normal-scale attempt restored original CVars but changed effective scale; exact restoration review is unresolved. Do not change UI scale/CVars for visual work without a separate scoped review.
- Opaque TGA loading/cropping and primitive rotation have evidence; transparent-sprite alpha, atlas UVs, new asset formats/sizes and production pivot/facing need a small guarded actual-client check. File/API names alone do not prove semantics.
- WC3Vault/source candidates have unresolved individual import permissions; reference/tool licenses are not model rights. Author one original sprite and record provenance before runtime integration.

Evidence: [camera static](../evidence/2026-10-20-mirage-camera-static.md), [owner background screenshot scope](../evidence/2026-10-20-mirage-static-background.md), [FEASIBILITY](../FEASIBILITY.md), [CLIENT_API](../CLIENT_API.md), [scale finding](../evidence/2026-10-19-m0-scale.md). No personal screenshot was added to Git.

## Tests and reproducibility

Executed during this checkpoint on unchanged runtime baseline using Python 3.14 and pinned local Lupa:

```powershell
& C:/Python314/python.exe scripts/test_lua.py --runtime lua51
```

**PASS:** 29 Lua source/test files parsed; all 16 test modules executed. Includes the Physics-v6 10,000-tick seeded input tape comparing all fifteen state fields at 30/60/144 simulated render Hz, exact drift/grace boundaries and oval bend metrics, race/countdown/lap/checkpoint cadence tests, camera/clipping/UV tests and mocked lifecycle/pooling. These are offline assertions, not client FPS, game feel or multiplayer measurements.

Additional executed checks passed: `scripts/validate_project.py` (45 expected paths and existing structure), static `CLAUDE.md` import/local Markdown-link resolution, `scripts/build_mirage_layout.py --check`, `scripts/build_mirage_background.py --check`, and documentation whitespace checks. The background reproduces SHA-256 `27a5e56ac98bd5ef6185b10ba734cd90ba483887d8e17b64d6ed6c35075c7714`; the guide is still an authoring overview, not the camera framing. Independent source-to-contract review found no blocking mismatch. `git diff f923d15 -- addon scripts tests` was empty: runtime, assets and tests are unchanged. No new gameplay tests were added or weakened. Lua5.4/native CLI, actual Forever checks, two-client tests and broad performance/scale matrices were **NOT RUN** here. Use [TEST_PLAN](../TEST_PLAN.md) for integration scope and retain pending labels.

For a visual-only task, the normal focused commands are:

```powershell
python scripts/test_lua.py --runtime lua51 --tests presentation ui
python scripts/validate_project.py
git diff --check
```

Other machines need the pinned dependency from `requirements-dev.txt` (the `local-artifacts/python-deps` runtime is deliberately not tracked). Read `scripts/test_lua.py` for setup; missing runtimes mean NOT RUN, not pass. Run broader tests only when the changed scope or integration checkpoint warrants them.

## Recommended first Claude task

Reserve only Presentation/visual UI regions, the new kart asset/provenance and focused visual tests in `docs/handoffs/claude-latest.md`. Create/integrate **one original strict-overhead, north-facing Goblin drag-car sprite** at the current close-camera play size, stable center/padding/pivot and guarded once-only loading. Preserve primitive fallback and drift/boost feedback without replacing the image with `SetColorTexture`. Keep physics, collision clearance, camera/gameplay dimensions, tick/race logic, map geometry and capture behavior unchanged. Record provenance and offline alpha/format checks; mark the actual sprite client check pending unless executed. No full roster, new gameplay feature or milestone promotion.

No simulation feature blocks this bounded visual task. Operational dependencies are the reviewed documentation checkpoint in Claude's worktree, scoped shared-file reservation, rights-cleared/original art and the Lua dependency if testing. Deployment and actual client input must be scheduled with the other agent because the installed addon directory is shared.

## Manual synchronization after review

Both registered worktrees share the Git object database, so the local preparation commit needs no network fetch. Do **not** run these during another agent's work or with unexpected changes. First review the checkpoint and confirm the target branch/status:

```powershell
git log -1 --format="%H %s" codex/handoff-contracts
git diff f923d15..codex/handoff-contracts --stat
git -C ../AzerothKart-Claude branch --show-current
git -C ../AzerothKart-Claude status --short
```

Only when status is empty, the branch is still `claude/track-ui`, Claude is idle and integration is explicitly approved, use the exact reviewed checkpoint hash from the final report:

```powershell
git -C ../AzerothKart-Claude merge --ff-only <reviewed-checkpoint-hash>
git -C ../AzerothKart-Claude log -1 --oneline
git -C ../AzerothKart-Claude status --short
```

These are manual commands, **not executed by this handoff**. A non-fast-forward or untracked-file conflict means stop and coordinate; never reset/clean/rebase to force it. Then Claude should read `CLAUDE.md`/shared contracts and record its task scope in its own canonical handoff before editing. No automatic merge into main, push or release is configured.
