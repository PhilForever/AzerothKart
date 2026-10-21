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
