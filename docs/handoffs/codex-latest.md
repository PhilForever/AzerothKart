# Codex handoff — logged session bridge ready for menu integration

2026-10-21 09:10+02:00 Europe/Oslo. Branch `codex/session-transport`, base combined83c611c. Resolve resulting focused commit with `git log -1 codex/session-transport` (this handoff accompanies it). [SESSION_MENU_API](../SESSION_MENU_API.md) is the concise Claude integration guide; [API_CONTRACTS](../API_CONTRACTS.md#implemented-logged-whisper-session-adapter-and-menu-bridge) records exact implemented methods.

## Scope / parallel state

Owner requests controller->Forever logged route plus menu actions. Reserved08:50before edits. New SessionTransport/test, additive PeerSession.update budget gate, Probe lease/native-marker/arming safeguards, Core forwarding, accepted UI.Start hardStop(local_drive) only, loaders/TOCs/validators/docs. No visual/menu/persistence/physics/Race or live-coordinator implementation. Installed client/source distinction preserved; no install/clientinput/download/manualprobe/push/release.

Original combinedcodex/roster-integration83c611c, codex/peer-session3644084 and claude/track-ui b0b1f2e remain intact. Claude independently started claude/ui-flow from83c611c; reservationdfbd83e observed09:09. Its owned layout/Menu/HUD/assets/prefs proposal remains untouched. It explicitly excludes transport/Core/PeerSession and UI.Start; shared TOCs/testloader/count/contracts/docs need reviewed integration, not a whole-file replacement. Read its actual handoff from that worktree/shared Git before merging. Do not overwrite active visual work. Both branches install nothing; Codex remains deployment integrator.

## Implemented contract

`AK.SessionTransport` dot calls Init(coreFrame), Host(peer,code,trackId), Listen(peer,code), Join(), Ready(bool), Start(startTick,seed), Leave(), Stop(fixedReason), IsActive(), Update(), Message(prefix,payload,channel,nativeSender), HandleEvent(event), GetView(), TakeStartProposal(). Controller private; copied snapshots/proposals only. Explicit full first+surname/no realm and fresh6code; compatibility from actual source versions, fixed3laps.64accepted IDs remembered, no discovery or automatic rearm. Start still only a parameter proposal; no engine/clock/atomicGO behavior.

Strict existing logged API/event/nativeWHISPER route, separateAZKART2 prefix, source-matched enums, guarded secret/unknown/throwing results. No startup registration/sends, UI allocations, chat output or SavedVariables. Exclusive Coreframe lease/nativecall marker prevents probe/session co-use or inactive teardown. Probe verifies lease after allsetup hooks and blocks recursive arm. Native sends only in Update; allACK/retry/final calls count before invocation. Persistent0.5s/rolling1s2calls/158payload+prefixB local gate; pair4calls/316B working ceilings ifbothcompliant, not measured capacity or control of other addons. Probe remains exclusive standalone experiment, not racing traffic.

Hardstop lifecycle/clock/API/native failure drops pending output/controller/proposals, keeps copied diagnostic, releases onlyowned hooks. Leave/remoteCancel final notice/ACK is bounded best effort with lease held through drain. SoloStart ends control before inputcapture. No automatic resume. Additive `PeerSession.update(...,sendAllowed?)` false advancesclock/deadlines/finalexpiry with noattempts; oldomitted/true unchanged, strictbadflagrefused.

## Executed tests

- Real Lua5.1/pinned Lupa: `scripts/test_lua.py --runtime lua51 --tests session_transport peer_session transport_probe ui` PASS:40parsed/all4modules. Initial isolated adapter test passed, then root added cross-native Stop/guard cancellation and core/lease checks. UI mock's missing metadata corrected to nil. Independent review found/reproduced legacyprobe registration cancellation->lostlease; fixed3setupstages+recursivearm, finalfocusedrerunPASS.
- Two actual-codec/controller mocked peers exercise explicitjoin/ready/startproposal, scopes/versions/copies/64cap, API/enum/outcome refusal, retries/drop/pacing/rearm, drains, interrupts, presend/reentrantACK/Stop/update, and bothdirections native leasehandovers. No synthetic result is client delivery evidence.
- UI retained11/151/13 and same900frame authoritative/effectstrace. Structural validator PASS74paths/17moduleTOCs/links/ledger; whitespace PASS.12mechanics/presentation/codec modules +9runtimeassetbytes retain83c611c.22installedfiles/tree unchanged against existing verifiedmanifest.
- NOT RUN: currentLua5.4/fullbroadsuite, actualAZKART2 clientregistration/delivery, menu/sharedrace, start-clock/authority/finish/feel/socket/scale/release checks. No new manual request.

## Next single task

Codex: bounded start-clock/coordinator negotiation for the two-player candidate, with deadlines/explicitcancel/ambiguousdelivery and one-shot raceownership before any Race activation. Claude: visual flow against copied menu actions; do not read controller internals or consume TakeStartProposal from rendering, or expose tick/seed settings. Its current Coming-soon lobby is an owner-selected presentation plan; enabling native actions waits for shared integration review.

Use `git show codex/session-transport:docs/SESSION_MENU_API.md` from a stale checkout. Preserve activeclaude/ui-flow before any reviewed merge and keep bothagents' TOC/testloader/docs additions; no automatic merging/installation. Approximately700ms measured RTT, full socket recovery, synchronization/authority and nativegamefeel remain open underADR0013. Multiplayer priority unchanged; no M2 completion/productionarchitectureclaim.
