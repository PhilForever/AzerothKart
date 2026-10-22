# Active reservation — native live race and player flow

2026-10-22 Europe/Oslo. Explicit owner request: connect controller to Forever
transport, then wire lobby and race display. Own codex/live-multiplayer-integration
from7f80c2b. Reserve SessionTransport and native integration tests (root), UI.lua
lifecycle/display + focused UI tests (assigned UI agent), Menu.lua/lobby commands
+ menu tests (assigned menu agent), contracts/docs/load lists/PROGRESS (root).
Owner explicitly assigns this UI wiring; preserve Claude visuals/foreign branch.
No assets, physics or geometry edits. No main merge/force push/release. Native
adoption must retain the same persistent budget/frame lease. Reviewed offline
candidate, no client result claimed without execution. Deployment remains a
separate coordinated step if candidate checks expose a blocker.

## Previous handoff

# Codex handoff — pure live-race lifecycle and telemetry

2026-10-22 23:11 +02:00, Europe/Oslo. Owner requests multiplayer development toward a friend
race. Branch **codex/live-race-controller** from4544108 (reviewed Claude Orgrimmar
72b362f), reservation5008f44, implementation **b35946f**. This following handoff
commit contains documentation only. No foreign branch switch/merge, push,
installation, client input or milestone completion.

## Completed source slice

New LiveRace.lua consumes one copied tick-zero RaceStart bundle exactly once;
fixed-step Physics/Race/Loop driving, exact finish/stop/combat state and copied
render views. New LiveProtocol.lua provides strict34-byte observational packets
on AZKRUN1. Peer/session/channel/sequence/tick/map/progress validation, only two
remote poses,500ms output spacing/2calls/158B rolling cap, no ACK/history queue,
five-second peer silence/frozen-progress timeout and30-minute duration cap.
Received claims cannot correct physics, award local progress, establish a
winner or shared result. Completed reports remain unverified. No production
authority/contact/finish decision; this telemetry is within ADR0013's experiment.

[Full implemented API and next boundary](../LIVE_RACE.md). Module/test lists,
26-module TOCs, API/architecture/index/README/shared instructions aligned. All
17critical existing simulation/native/UI modules and all art remain unchanged.
Claude retains all visual/Menu/UI ownership; its worktree/handoff are untouched.
Public native APIs retain old behavior; loading new modules does nothing native.

## Actual checks

Actual Lua5.1/pinnedLupa2.8 via C:/Python314/python.exe and canonical
local-artifacts/python-deps: `scripts/test_lua.py --runtime lua51 --tests
live_protocol live_race race_start session_transport ui` PASS56parsed/five
modules. Synthetic20s two-peer tape, clocks5s apart/350ms one-way delivery:
1200equal-input driving ticks,41accepted snapshots per peer, rolling call/byte
caps verified. Existing900-tick GO replay/native adapter and UI regressions pass;
UI mock counts75/165/80 unchanged. Independent read-only review found four
constructor/liveness issues, reproduced/fixed/regression covered; no blockers
remain for this pure slice. Final focused live_race PASS after duration, injected
simulation-failure and callback Stop regressions. Whitespace/Python parse/TOC
checks PASS. Structural validator FAIL only on two pre-existing expired skill
links in PROGRESS; not reported as a passing validator. Full broad/Lua5.4/native
checks NOT RUN. Synthetic RTT is not a new network measurement.

All347 foreign file hashes/statuses/HEADs preserved; receipts in ignored
local-artifacts/live-race-controller-20261022/. Installed prior41-file2e75a3d is
unchanged. No friend download or test requested yet: gameplay is still unwired.

## Next exact task

Implement opt-in atomic LiveRace adoption inside SessionTransport at GO,
retaining its same frame lease and persistent attempts/lastAttempt/traffic.
Register live prefix only for that explicit mode; do not call legacy
TakeRaceStart then reacquire another sender. Preserve existing TakeRaceStart
release semantics and probe exclusivity. Share native budget across control,
clock, live snapshots and cancellation; account failed/unknown/throttled calls.
Test complete two mocked peers from invite/join/ready/clock through actual live
advance and delivery, including reentrant Stop/cleanup. Still only Test Oval and
Mirage are negotiated by the current control codec. Claude's reviewed menu/
canvas binding comes next; menu navigation never consumes GO or owns Physics.
Official results/corrections/contact and actual two-client race feel remain open.
