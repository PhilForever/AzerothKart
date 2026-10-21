# Latest checkpoint — GitHub and parallel-work safety

2026-10-21 13:52+02:00, Europe/Oslo. Documentation-only `codex/github-safety` from `e10d3ef`; result is the accompanying commit. [Audit](../reviews/2026-10-21-github-safety.md) records exact source refs, preserved hashes, verified all-ref recovery bundle and Windows Git access. Claude is1b2d3d5, source tracked clean with existing untracked outputs; sharedbase83c611c intact. Native Windows explicit claude/ui-flow dry-run publication succeeds; no actual push/merge/reset/config/auth/install changes. Repo connectivity PASS. Three worktrees' complete tracked/untracked snapshots unchanged after read-only checks.

Executed against Claude source: real Lua5.1 menu/ui PASS40parsed/counts65/160/79; structural validator PASS77paths on Windows (Linux link issue not reproduced); preview --check PASS/exact bytes. Codex approves first-open saved-track restore through the inactive/out-of-combat transaction for later integration. Source mechanics/Core/transport and mechanical assertions preserved. Current Lua5.4/fullbroad/combinedscratch/client checks NOT RUN by Codex; multiplayer remains unwired. Shared loader/UI/docs integration remains reviewed work, not a whole-file replacement or standalone install.

Only this handoff, PROGRESS, INTEGRATION_STATUS and the safety review changed. No Claude/canonical file changed. Next: owner-authorized feature-branch publication if requested, separately reviewed UI/backend integration, then live-race controller/paced remote state. The source implementation remains2232f82 with Gemini-review documentatione10d3ef; previous handoffs below retain their scoped evidence. A prior push authorization is not reused automatically.

---
# Latest review — Gemini feedback

2026-10-21 12:25+02:00, Europe/Oslo. Documentation-only `codex/gemini-feedback` from `2232f82`; result is the accompanying review commit. [Assessment](../reviews/2026-10-21-gemini-feedback.md) records useful suggestions and corrected networking/timing/asset claims. Only this handoff, the review note and the appended PROGRESS entry changed. No gameplay/API/art/Claude/install changes. Actual Lua5.1 Loop micro-experiment demonstrates dropped hitch time; broad suite/client checks NOT RUN for this review. Structural validator PASS82paths/TOCs/links/ledger; whitespace PASS. Next development task is unchanged: bounded live-race control and paced remote snapshots, preserving budgets and a read-only Claude render boundary. The implementation handoff below remains authoritative for source2232f82.

---
# Codex handoff — start-clock foundation and backend race initialization

2026-10-21 12:18+02:00, Europe/Oslo. Branch `codex/start-clock`, base `4f9246a`; result is the accompanying commit (`git log -1 codex/start-clock`). Protected combined source remains `83c611c`. [START_CLOCK](../START_CLOCK.md) is the exact new contract; [SESSION_MENU_API](../SESSION_MENU_API.md) records the unchanged legacy bridge plus opt-in additions.

## Completed scope

Reserved before edits at09:24; resumed quota-interrupted files at12:04. New ClockProtocol/StartClock/RaceStart and tests; additive PeerSession.handoffStart/Race.newRunning; native coordinated actions, shared-budget clock output, copied diagnostics and one-shot backend bundle. Both TOCs, runner, validator, shared contract/architecture/evidence-status docs, candidate ADR0014 and PROGRESS aligned. No UI.lua/Presentation/Physics/Track/Mirage/art/Core/TransportProbe source edits, preferences, remote movement, new assets or live client changes.

Explicit `HostCoordinated/ListenCoordinated` opt in to AZKCLK1 alongside AZKART2. Existing Join/Ready remain deliberate; host PrepareStart uses fixed180-tick metadata plus backend seed (default0). Legacy Host/Listen/Start/TakeStartProposal retain parameter semantics. Coordinated canStart is false; canPrepareStart and copied clock reflect actual backend state. Renderers consume neither TakeStartProposal nor TakeRaceStart.

The private controller transfers a valid proposal once into a finite coordinating phase. Three paced four-timestamp samples intersect offset intervals, remove guest queue time and make no symmetry/one-way guarantee. PREPARE/COMMIT negotiate GO eight seconds ahead, with one-second handshake margin. Host arms after matching COMMIT ACK; guest after its own ACK accepted locally. Last-ACK/cancel loss may leave only the guest armed. Clock uncertainty is not observed launch-skew or drift assurance; each peer separately permits at most250ms callback lateness. A lost calibration sample can conservatively exceed the2s RTT ceiling after retry and require a fresh explicit session. No automatic rejoin.

All clock/control/retry/ACK/final calls retain the same native lease, persistent0.5s spacing and rolling2calls/158payload+prefixB local ceiling. No callback bursts. Native timestamp preflight delays>2ms fail closed. Hard cancellation clears an unconsumed launch. Backend TakeRaceStart at mapped GO yields actual Physics/Race state once at tick0 and releases control hooks; no canvas/input/drive loop/opponent/finish is created. Seed remains metadata. Existing solo UI.Start still cancels control; never use it to activate the bundle. The next live controller must preserve budget/ownership across this handoff.

## Executed evidence

- Real Lua5.1/pinned Lupa: `scripts/test_lua.py --runtime lua51 --tests clock_protocol start_clock race_start race peer_session session_transport` PASS,46parsed/all6.
- `scripts/test_lua.py --runtime lua51 --tests session_transport transport_probe ui` PASS,46parsed/all3. Final session_transport/peer_session rerun PASS after callback-clock cleanup; session_transport rerun PASS after negotiated-version retention at launch. Tests include independent/asymmetric clocks, native delayed delivery/5s offset, failure/late/duplicate/reentry cases, final-ACK ambiguity and actual900-tick deterministic Physics/Race replay. UI retains11/151/13 and its900-frame drive/effects trace.
- Static validator PASS82paths/20modules/links/ledger; whitespace PASS. Read-only installed manifest22/22 matches the previous8f66c5a build. Protected visual/mechanics/art/Core/probe source diff frombase empty.
- Independent review found/fixed stale callback timestamp at handoff, missing initializer exception cleanup and guest PREPARE upper-bound consistency. Clock-sample retry limitation is documented and tested.
- NOT RUN: currentLua5.4/fullbroad matrix, native new-prefix delivery/registration, real drift/skew/menu/feel/sharedrace, socket recovery/scale/release. No manual request, client input/install, merge, push or release.

## Parallel work and integration

Claude is still `claude/ui-flow` at `dfbd83e` from83c611c, with untracked `Claude outputs/`; read her current actual handoff through that worktree/shared Git before integration. This branch preserves its predecessor's roster/effects/results/transport fixes. Claude's visual reservation and untracked outputs are untouched. Canonical `codex/handoff-contracts`5570968 retains its existing untracked root/canonical handoff files. No checkout reset/repoint/merge/rewrite/prune performed. Both agents' shared TOC/loader/docs edits must be combined by reviewed integration, never whole-file replacement. Installed target stays the old22-file verified build; no standalone branch install.

Claude can inspect this backend API without switching her active worktree: `git show codex/start-clock:docs/START_CLOCK.md` and `git show codex/start-clock:docs/SESSION_MENU_API.md`. No synchronization/merge command should be run over her active reservation. New UI activation and remote-render contract require coordination; no code from another owner's task was silently adopted here.

## Next single task

Implement a bounded live-race controller and paced two-peer remote snapshot path consuming the new GO bundle, preserving persistent output accounting/native ownership and exposing remote state read-only to Claude. Integrate menu/canvas hooks only after reviewing her current committed visual work. Remote corrections, finish agreement and real game feel remain open; do not advertise live multiplayer yet. No new download/manual test needed now. Multiplayer remains ahead of ghosts; no milestone checkboxes advanced.
