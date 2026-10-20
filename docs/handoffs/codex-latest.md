# Codex handoff — Test Oval swept solids and multiplayer priority

Prepared 2026-10-20, 19:06 CEST (Europe/Oslo). Current milestone M1; M0/M1/M3 acceptance remains open. This is one local collision slice plus the owner's release-priority clarification, not multiplayer implementation or a release.

## Branch, source and preserved work

| Item | Verified state |
|---|---|
| Repository | `https://github.com/PhilForever/AzerothKart.git` |
| Feature branch / worktree | `codex/oval-obstacle-collision` in `../AzerothKart-Codex-Review` (reused Codex checkout) |
| Base | `1f8f20868a08f43678d83d858362123344e7bfea`, reviewed Goblin sprite/policy state |
| Priority commit | `7b6c6a7` — `docs: prioritize verified multiplayer and release content target` |
| Feature commit | Resolve the completed `feat: add swept Test Oval obstacle collisions` with `git log -1 codex/oval-obstacle-collision`; final report gives its immutable hash |
| Main / local origin/main | `f923d15`; not integrated/pushed |
| Canonical Codex checkout | `../AzerothKart` on `codex/handoff-contracts` at `5570968`; three pre-existing empty untracked handoff placeholders preserved |
| Claude inspected checkout | `../AzerothKart-Claude`, `claude/track-ui` at `5734335`; untracked `Claude outputs/` preserved, not read/staged/edited |
| Shared installed addon | Claude's handoff reports `0bf6fd0` scenery/shadow deployment; this feature branch was not installed over it |

No merge, rebase, reset, cherry-pick, force push, client control, deployment or release occurred. Do not synchronize either other checkout on its owner's behalf. The canonical untracked `docs/handoffs/claude-latest.md` collides with the tracked handoff during a later integration: inspect/preserve it first. Do not run Git worktree pruning/GC in Claude's Linux mount environment.

## Owner direction and responsibilities

[ADR 0010](../adr/0010-multiplayer-release-priority.md) is accepted: multiplayer has much higher priority than dedicated ghosts/time trials. Codex completes the necessary handling/collision/race foundations and prioritizes actual-client transport evidence and genuine multiplayer. Release targets this work through verified multiplayer plus Claude's **three ready maps/eight ready karts** and integrated acceptance. Eight kart assets do not establish eight simultaneous players. No automatic publishing/integration authorization is created.

If actual Forever transport is insufficient, report measurements and stop for owner review; do not silently substitute ghosts for the current release target. Keep the loss/throttle/order/latency/budget/reconnect gate, bounded traffic and sender/session validation. There is still no runtime lobby, transport, synchronization, ghost, AI or item engine.

Codex owns Physics, Track geometry/collision, race/checkpoints, deterministic simulation, transport and tests. Claude owns presentation/UI/artwork/assets/VFX. Shared contracts/budgets/integration remain coordinated. WC3 sources are accepted under ADR0009 with per-file provenance/status/credits; no asset was imported by this slice.

## Implemented collision slice

- `Track.lua` adds `id="test_oval"`, geometry `version=2` and two physical 32×24 rectangles at bottom-left **(270,400)** and **(490,60)**. Road mask, spawn and gates remain unchanged. `surfaceAt` additionally returns wall for the physical rectangles including edges.
- New optional `track.resolveMovement(previousX,previousY,targetX,targetY) -> x,y,hit` sweeps the whole segment against the perimeter and solids expanded by 18 units on each side. This is conservative axis-aligned square clearance enclosing the rotated 17×31 body, not an exact chassis shape.
- Earliest contacts remove inward normal displacement and retain tangent motion; exact blocking planes avoid repeated numerical penetration. Exact face arrival, face sliding, moving away and isolated corner grazing remain free. Three movement iterations suffice after at most two axis components are removed.
- Starting overlaps recover deterministically to a nearest face, with left/right/bottom/top tie order and at most four recovery passes. The guarantee is scoped to these disjoint perimeter-contained fixtures. Arbitrary overlapping clusters, dynamic colliders, polygons and kart-to-kart collision are not implemented.
- Physics compatibility **v7** dispatches to the optional sweep when present, otherwise retains the previous constraint/predicate path. All fifteen fields, handling constants and fixed-step/input/race behavior remain intact. A hit uses the existing one-per-step impact increment, speed×0.25 scrub and drift/grace/boost/slip/steering cancellation; no boost acceleration is retained on contact.
- MirageRaceway source/geometry remains version1 with **no obstacles or sweep hook**. Its movement, art and camera code are unchanged by this slice.

## Minimal visual integration / shared review

The owner assigned this Oval-only obstacle work. Reserved edits were recorded in this handoff before implementation. `UI.lua` changes only `drawTrack` and `layoutTrack`: two red ARTWORK Texture regions created once from Oval's physical rectangles, placed through the existing projection helper, hidden on Mirage and reused when returning to Oval. No render/step/lifecycle/input/controller hook or Presentation helper changed. Richer obstacle art remains Claude's scope.

Pool change: **9 frames / 113 textures / 13 font strings**, two textures above the previously observed 9/111/13 baseline. The extra regions stay allocated but hidden on Mirage. No new Frames, per-tick UI objects, texture file loads or chat output. This is offline allocation evidence, not a new client FPS/memory acceptance result.

Shared `tests/test_ui.lua` changes update the five explicit texture-budget expectations and add physical marker registration, actual fixed-step collision, hidden-on-Mirage and pooled switching assertions. Existing capture, lifecycle, race/clock and sprite-fallback assertions remain. `tests/run.lua` registers the new simulation test; TOCs/source load order remain unchanged. Physics/drift tests only update compatibility assertions in addition to the new collision module tests.

The [API contract](../API_CONTRACTS.md), architecture, physics, tracks, feasibility, README/changelog and focused test/manual docs now describe this branch. Minimal shared visual/contract changes require Claude/integrator review before integration, under AGENTS. No other worktree was merged or edited.

## Tests actually executed

Windows Python `C:/Python314/python.exe`, Lua5.1 through pinned Lupa2.8. This process supplied the canonical checkout's ignored `local-artifacts/python-deps` via PYTHONPATH; no global dependency install.

| Check | Result / scope |
|---|---|
| `scripts/test_lua.py --runtime lua51 --tests track obstacles physics drift surface determinism mirage ui` | PASS — 30 Lua files parsed, all eight selected modules executed. Includes long sweeps/tangent/corner/recovery, guaranteed obstacle hits in a 900-tick seed 1729 tape at 30/60/144 simulated render Hz across all 15 fields, existing 10k-tick seed 1729 replay, drift/grass/perimeter regressions, Mirage synthetic race and pooled UI/capture/lifecycle. |
| Final `scripts/test_lua.py --runtime lua51 --tests obstacles` | PASS after adding a narrow charged+boosted contact case: single scrub, no boost reward, complete cancellation, immutable prior state and immediate release. No runtime code changed after the eight-module pass. |
| `scripts/validate_project.py` | STATIC PASS — 48 required paths; synchronized TOCs, local docs links, protocol and header-only network ledger. Does not execute Lua. |
| `git diff --check` / staged equivalent | PASS — reviewed scope and whitespace. |
| Independent read-only runtime/test review | No blocking issue found; conservative clearance/recovery scope documented. No tests weakened to accept collision failures. |
| Delegated geometry implementation check | Agent additionally ran Lua5.1 `--tests obstacles track`: PASS, 30 parsed files, before root's combined run. This is attributed execution, not a third root suite. |
| Actual client obstacle appearance/handling, integrated latest Claude visuals, deployment/reload, Lua5.4/full current suite, broad performance and all multiplayer transport measurements | NOT RUN this slice. No client availability assertion or milestone completion inferred. |

The combined output retained oval drift tiers at 30/60 ticks and 49.78°/105.64°, on road throughout; Mirage's 1890-tick synthetic countdown/race; sprite/primitive equality through tick 1275; mock pool 9/113/13 through 1,001 updates with 0 combat propagation calls. These are offline checks, not human game feel, client latency or network evidence.

## Risks and client check

Clearance can look conservative near corners. Initial recovery may move an invalid pose farther than a checkpoint's5-unit sanity bound; that step awards nothing under existing rules. Keep authored collider geometry fixed; no dynamic relocation or generic overlapping-cluster guarantee. Same-runtime determinism is not cross-client floating-point identity or anti-cheat.

The [short manual Oval check](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-short-test-oval-obstacle-check-physics-v7) remains NOT RUN. Coordinate a reviewed integration with Claude's current deployed art before installing; never replace the latest background/sprites with this branch's older copies. Do not repeat long combat/scale/profiling matrices for this slice. Current source changes add no new runtime file or API dependency.

## Next single executable Codex task

**Build a bounded two-client addon-transport probe/test harness for M2**, using the existing [feasibility gate](../FEASIBILITY.md), [network checklist](../../tests/MANUAL_NETWORK_CHECKLIST.md) and [ledger](../experiments/network-ledger.csv). It must measure actual send outcomes, receive/duplicate/order/loss counts, round-trip latency, throttling and disconnect/reconnect; keep rate/size/duration caps and explicit opt-in peer/session scope. Prepare deterministic offline accounting tests. Actual two-client results stay pending until executed; do not choose broad replication or build a lobby first.

Review/integration of this collision feature can proceed independently of the transport harness. Do not resume dedicated time-trial/ghost development ahead of multiplayer. Claude continues maps/karts/visuals without any Mirage obstacle requirement.
