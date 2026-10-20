# ADR 0010 — Multiplayer priority and release target

**Status:** Accepted owner direction, 2026-10-20. Supersedes earlier automatic ghost-fallback and solo-first release-priority language where it conflicts; does not waive client feasibility or acceptance gates.

## Context

The owner assigned Codex continued mechanical development while Claude completes Mirage Raceway and the first kart. The owner clarified that multiplayer has much higher priority than time trials/ghosts, that new obstacle work belongs on the oval test track rather than Mirage, and that release is intended after Codex's work through multiplayer plus Claude's three maps and eight karts.

The project has local driving/race foundations and a prepared transport experiment ledger, but no measured multiplayer capacity or working live-race transport. Existing milestone numbers and documents must not be read as requiring dedicated ghost/time-trial work before networking.

## Decision

- Codex owns handling, collision, deterministic simulation, race/checkpoint rules and multiplayer/synchronization with their tests. Complete the necessary mechanical and race foundations, then prioritize actual-client network feasibility and genuine multiplayer. Dedicated time trials/ghosts are deferred and are not networking or release prerequisites.
- The current solid-obstacle slice uses **Test Oval only**. Add no solid obstacles to **Mirage Raceway**. Visual scenery is separate from collision data; decoration does not become an obstacle implicitly.
- Claude's release content target is **three ready maps and eight ready karts**. Coordinate track registration, collision footprint and public interfaces under the existing shared-ownership workflow. Content counts alone do not prove integrated readiness.
- The release target combines Codex's required mechanical/race/network work **through verified multiplayer** with Claude's ready content and shared release checks. This does not add unrelated AI, championships or dedicated ghost/time-trial systems as prerequisites.
- Retain the actual Forever `C_ChatInfo` gate: measured sends/receives, loss, throughput/budget, throttling, ordering, latency and two-client disconnect/reconnect behavior before selecting a live-race replication architecture. Respect bounded packet budgets; do not broadcast every simulation tick/frame.
- Establish the advertised player count from evidence. Eight karts is a roster requirement, not a promise of eight simultaneous players; 2/4/8-client scale work remains subject to real testers and measured gates.
- If transport cannot support acceptable racing, stop and present the evidence for owner review. Ghost/time-trial multiplayer remains a possible degradation path, but does not silently satisfy the agreed live multiplayer release target.
- No new authorization to merge agent branches, push, deploy, tag or publish is inferred. Follow existing review/integration and explicit release authorization rules.

## Consequences and evidence

Local solo handling and race rules remain useful foundations for multiplayer. Existing best-lap display is retained; no feature removal is implied. Build-first focused validation remains in effect under ADR 0007, with unexecuted client checks labeled NOT RUN and incomplete milestones left open.

The immediate independent task is deterministic oval obstacle collision. The next network step is a focused actual-client transport probe/test harness using the existing experiment ledger, not a broad lobby/replication implementation before its feasibility gate. No transport, client, content-readiness or release criterion is passed by accepting this priority decision.

See [ROADMAP](../ROADMAP.md), the [pending release target](../RELEASE.md#current-release-target-pending), [FEASIBILITY](../FEASIBILITY.md) and the [current Codex handoff](../handoffs/codex-latest.md) for execution state.
