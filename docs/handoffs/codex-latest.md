# Codex handoff — multiplayer grid/countdown and peer presentation

2026-10-23 09:05+02:00, Europe/Oslo. Owner asks to continue from first real
two-client feedback. Own **codex/multiplayer-grid**, base6ad66d1,
reservationf5e6918, tested/installed runtime **eb2055a22034bc63d3bfe01538f097f4cbfab4ba**.
Following handoff commit changes documentation only. No new milestone or push.

## What is implemented and verified

- Bounded pure RaceGrid/profile codec on AZKGRD1: chosen cosmetic IDs immutable,
  Ready/Start held until agreement, role-specific start slots36units apart.
- Deliberate Start shows both chosen sprites, GET READY then full3–2–1–GO.
  StartClock reserves3000ms before GO; no preGOsteps/laps. Held keys carry to
  actual single backend launch. Staged exit releases input; old finished
  summaries cannot return after a grid abort. Solo/legacy behavior retained.
- Exact40-byte AZKRUN2 snapshots add monotonic sampleMS. Copied sampleAgeMS is
  mapped-clock age, not measured one-way latency. Reuses existing peer texture,
  neutral art tint, atlas heading/pivot/rotation with guarded square fallback.
- Cached500ms/31-point display forecast follows bounded travel/yaw and stops
  at walls/solids; no extra interpolation interval. Offscreen direction/distance
  is not race position. Unknown steering/braking/clock error can cause corrections.
- Rate stays2Hz/94payload+prefixB per peer/188pair; all four prefixes share
  the same Core lease/persistent0.5s/2calls/158B local gate. Pool79/166/81.
  No art/Physics/geometry changes, kart contact or agreed winner added.

Final actual Lua5.1 **31testmodules/59parsedfiles PASS** after focused tests.
All-TOC mock peers traverse realCore/menu/UI/native flow at700ms syntheticRTT,
5sclockoffset, profiles, distinct sprites/slots, each3/2/1, zero preGOsteps,
held throttle afterGO and cleanup. Native profile-loss/gating,32sLeave,
failure/reentry, timestamp/syntax/copy, bounded wall prediction and old-result
regressions pass. Final independent native review found no further blocker.
`git diff --check` PASS. Structural validator FAIL only the historical two
expired skill links; do not call it passed. Lua5.4/full art rebuild/native
revised countdown/sprites/input/timing/feel/FPS **NOT RUN**. See
[PROGRESS](../PROGRESS.md) for commands/results and [owner evidence](../evidence/2026-10-23-first-live-race.md)
for earlierc581a52 local finishes35.42/36.42s and usability issues. Neither the
old local times nor new offline passes establish synchronized/shared results.

## Installation and archive

Backup/hash installer actually deployed50files to `_classic_beta_/Interface/AddOns/AzerothKart`.
Prior49files independently matchc581a52 receipt+before.csv; all50source/target/
manifest/ZIP paths+SHA256 match. Manifest `local-artifacts/multiplayer-grid-20261023/backups/20261023-090347-158-a74d717dd9c84f9184be9cbf9ff9a508/install.json`.
ZIP created directly from installed folder, CRC checked, trees unchanged:
`C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-eb2055a.zip`,
33,930,577bytes, SHA256 `83a1211c312f047d4f7aa905abfd8b6747d888386d882a06e8d7f00381e14c24`.
Ignored receipt/logs: `local-artifacts/multiplayer-grid-20261023/`.
Old archive retained; no otheraddon/WTF/SavedVariables/clientinput changes.

## Coordination and ownership

Read Claude’s latest authored handoff at **e96044b / claude/darnassus-undercity**,
which independently advances from6ad66d1 and explicitly acknowledges our active
reservation. Newcity Menu/test changes are catalog data only. Its checkout,
untracked outputs and authored handoff are untouched; the old Orgrimmar ref
72b362f remains. Canonical5570968 unchanged.370foreignfilehashes/HEADs/branches/
statuses preserved after that observed advancement;39critical core/art files
unchanged from6ad66d1. No newcity/elevation integration, history rewrite, main
merge, branch publication or direct Claude acknowledgment claimed.

Root reservation now complete. Changed native scope: LiveProtocol/LiveRace,
RaceGrid, SessionTransport and StartClock; coordinated UI/Menu/Presentation
scope: grid capture/cues, selectedpeertexture, bounded forecast/label and tests.
Both TOCs/runner/validator and shared contract/evidence/playtest docs aligned.
Contracts are in [API_CONTRACTS](../API_CONTRACTS.md),
[LIVE_RACE](../LIVE_RACE.md), [START_CLOCK](../START_CLOCK.md) and
[SESSION_MENU_API](../SESSION_MENU_API.md). Future city integration must retain
these newer Menu/UI/native changes instead of installing its standalone branch.
Do not switch/reset another worktree or automatically merge/push.

## Pending and next exact task

Both testers fully restart WoW with this identical updated build (new module,
new wire prefix). Follow [the short menu steps](../MULTIPLAYER_PLAYTEST.md);
verify visible shared grid/countdown, correct peer sprites and nearby driving
feel. No standalone net probe requested. Actual forecast corrections/clock skew,
final-ACK ambiguity, contact, trusted finish/authority, full socket reconnect,
production acceptance and redistribution review remain open. Record native
feedback before deciding the next replication/contact/results slice. Milestones
stay open; no claim that the lag is fixed from synthetic tests.
