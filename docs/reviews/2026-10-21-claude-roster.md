# Review of Claude roster commits

Reviewed 2026-10-21: runtime `abe98f6` and handoff `b0b1f2e`, against integrated base `1004e73`. Review only; no merge, install or edits to Claude's worktree. Its untracked output folder is preserved.

## Findings for Claude before integration

1. **P2 — failed kart switching does not fully restore the previous visual state.** `abe98f6:addon/AzerothKart/UI.lua`, `UI.SelectKart`, lines684–685, calls `applyKartSprite(previous)` after a failed new load. For a previous single-image Drag Car, that helper never restores full-image UVs. In-memory Lua5.1 fault injection: select Drag Car, let Steam Tank's SetTexture/SetTexCoord succeed, then throw once from SetVertexColor. Selection returns false and restores Drag Car id/path, but UV remains `(0,0.125,0,0.125)`, cropping it to1/64. Restore the complete prior UV/rotation/metadata configuration; check restoration success and use a consistent safe primitive if restoration also fails. Add the late-failure regression, not just a SetTexture refusal.
2. **P3 — coverage threshold weakened for unrelated karts.** `abe98f6:tests/test_presentation.lua:311` lowers every kart's opaque coverage floor from12% to6%. The generator already has per-kart thresholds. Retain12% for trike/tank/biker,8% for gryphon and6% for gyrocopter so the thin flyers do not weaken existing-art coverage.

## Checks and observations

- Read-only runtime review found no changes to authoritative physics/race/input or camera ownership. The new selection is stopped-only and effects remain pooled/read-only.
- Executed on Claude's checkout: Lua5.1 `presentation ui` PASS,34 parsed files; six cosmetic karts, no authoritative-state mutation in the mocked drive,10frames/151textures/13fonts on Claude alone.
- Source SHA and committed-TGA validation passed for all five WC3 vehicles; five JPEG textures decoded with Python3.14. Pillow comparison, source regeneration, client appearance/performance and new-roster installation were NOT RUN by this review.
- The combined branch must preserve Close results and use11/151/13. Claude's standalone10-frame count is not the combined budget. A clean source merge alone does not resolve the failure case above.
- Per-file records retain unknown authors/missing archive licenses/unresolved redistribution. The review does not clear public distribution or change the accepted WC3 source policy.

**Disposition:** hold roster integration for the targeted visual rollback fix; keep the coverage improvement in that follow-up. [UI/flow ownership](../UI_FLOW_OWNERSHIP.md): Claude owns presentation/visual flow and these fixes; Codex owns session semantics and lifecycle. PeerSession implementation can proceed independently.

## Follow-up — resolved on the combined integration branch

2026-10-21, owner asked Codex to handle safe integration. Codex reserved the exact two findings on `codex/roster-integration` from3644084 plus Claude b0b1f2e; Claude's original source/handoff/authors were not changed. A normal merge retains both histories and no installation occurs.

- P2 resolved: every deliberate sprite application establishes complete UV/rotation/neutral tint before metadata changes. Late failure restores the previous frame/configuration; failed restoration clears to Basic/default effect anchors. Primitive rotation refusal is contained. Run/result/track/physics and pool counts remain unchanged. Targeted tests cover both sheet/single directions, late setter failures, persistent rollback failures and recovery.
- P3 resolved:12%opaque coverage for trike/tank/biker,8%gryphon,6%gyro. This matches the asset generator's explicit per-kart quality floors; art bytes unchanged.
- Combined full Lua5.1 suite PASS:38files parsed,21test modules; counts11/151/13. Structural validator PASS71paths. Preservation checks:36mechanical/transport/test/TOC files match3644084,21art binaries matchClaude and all147baseline tracked paths remain present.

**Disposition now:** source integration approved with those fixes on the combined branch. Native roster appearance, resource cost, new-file client loading and actual gameplay checks remain NOT RUN. Use [INTEGRATION_STATUS](../INTEGRATION_STATUS.md) for the current branch/deployment/synchronization rules rather than the older quoted handoff commands.
