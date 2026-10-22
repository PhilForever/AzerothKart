# Codex handoff — multiplayer candidate installed and packaged from AddOns

2026-10-22 23:52 +02:00, Europe/Oslo. Explicit owner request: install into AddOns and make ZIP
from there. Source c581a52950013263049cd82a44f83217556fc1c6 unchanged from tested
fb0df19 docs baseline. Own codex/live-multiplayer-integration; only deployment
receipts, PROGRESS and this handoff edited. No runtime source change.

PowerShell7 existing installer WhatIf PASS, then actual backup/install/hash
verification PASS49files in C:/Program Files (x86)/World of Warcraft/
_classic_beta_/Interface/AddOns/AzerothKart. Prior41files backed up/verified.
Manifest local-artifacts/live-multiplayer-install-20261022/backups/
20261022-235101-774-84c5285b8ea445aba58eaf5ceac28acf/install.json;
Verified/BackupVerified=true. No extras or other-addon/SavedVariables edits.

ZIP created from installed folder (not the workspace copy):
C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-c581a52.zip
49files,34,040,705bytes; SHA256
c19ea2fc005b4b643493f12245825c0587c8eaffcb96ff76fe4e8bd92300525a.
CRC/exactarchivepaths/allsource-target-ZIP hashes PASS; installed tree remained
stable during packaging. This is the current friend package. Preinstall hashes,
helper result and deployment-receipt.json are under ignored
local-artifacts/live-multiplayer-install-20261022/.

No gameplay suite rerun for byte-identical source copying; prior actualLua5.1
all30modules/57parsed pass retained. Actual WoW/native gameplay NOT RUN. No
client input, publication/release/main merge or milestone claim. Foreign worktrees
are not edited. Next exact task: full restart on both clients (new files), one
friend race through Multiplayer using MULTIPLAYER_PLAYTEST.md, record actual
GO/opponent movement/Stop and usability. No repeat standalone net probe.

Independent read-only audit PASS: source/target/manifest exact49files, backup/
before.csv exact41priorfiles, and both foreign worktrees'347file hashes/HEADs/
statuses unchanged. Receipt updated; no source/gameplay changes.

## Previous implementation checkpoint

# Codex handoff — wired two-player developer candidate

2026-10-22 23:39 +02:00, Europe/Oslo. Owner explicitly asks native controller connection then
lobby/race display. Own codex/live-multiplayer-integration from7f80c2b,
reservationc87fe29, implemented **c581a52950013263049cd82a44f83217556fc1c6**.
Following handoff commit changes documentation only. No main merge, force push,
release, foreign worktree edit, client input or installed-addon write.

## Implemented

SessionTransport HostLive/ListenLive opt-in, exactly-once private GO adoption,
same lease/hooks/persistent output budget across control/clock/live. Native
AdvanceLive returns copied current/final views; no second UI Physics loop.
PeerSession.beginRace clears negotiation deadline while retaining terminal
cancellation. All sends charged; refusal hard-stops without more output. Scoped
post-GO CANCEL uses normal sequence/conflict checks before retiring its unused
ACK/lease. Legacy native APIs and TakeRaceStart keep their prior behavior.

Core binds Menu's view/action bridge after creation. UI.MultiplayerAction owns
safety; deliberate Ready loads the supported offered track/arms the matching
session; GO checks focus/window/combat before capture. Full-name/fresh-code
lobby, Host/Listen/Join/Ready/Start/Leave,5Hz status, supportedMirage/Oval only.
One cyan marker/label consumes copied observations with bounded interpolation,
stale fade/clipping. Local finish freezes actual progress while native output
finishes; results/navigation stop/cancel correctly and are explicitly unverified.
No contact, authoritative remote correction, agreed winner or cosmetic exchange.
[Exact API](../LIVE_RACE.md#implemented-native-and-player-flow-integration),
[short user steps](../MULTIPLAYER_PLAYTEST.md). UI/menu changes were expressly
assigned by owner; Claude's visuals/checkout/authored handoff remain intact.

## Verification

Final actual Lua5.1/pinnedLupa2.8 full integration checkpoint PASS all30modules,
57parsedfiles, after focused six-module and native/cross-layer runs. Realall-TOC
mock peers use actualCore/menu/UI/native callbacks through700ms syntheticRTT,
5sclockoffset, GO,180drivingframes, moving observations and Stopcleanup. No
per-frame widgets; pool79/166/81. Tests cover32sliveLeave, one paced cancellation,
foreign/old-sequence packets, sendfailures, reentrant teardown, focus/loading/
preReadyclose, finishdrain and unchangedsolo/preferences. Whitespace/Pythonparse
PASS. Structuralvalidator FAIL only two pre-existing expired skill-file links
in PROGRESS; not counted as pass. Lua5.4/nativegame/delivery/feel/FPS NOT RUN.

347foreignfilehashes/statuses/HEADs preserved;20existing coremodules and every
asset unchanged. No direct Claude conversation claimed. The Git/common source
handoff is the coordination record; neither foreign checkout is switched.

## Artifact and next action

Local artifact release/AzerothKart-two-player-c581a52.zip,49files,34,040,705bytes,
SHA256 f4b9a91e68b48ffec27ef82330853388277f39ae9412f21652064e68c2ae1a04.
CRC/exactpaths/all49sourcehashes verified. No screenshots/personaldata/docs/tests
in package beyond existing addonREADME; build sourcec581a52. Ignored receipts:
local-artifacts/live-multiplayer-integration-20261022/ (final-lua51.txt,
focused.txt,structural.txt,preservation.json,package.json).

Not installed/published. Installed prior41-file2e75a3d is unchanged. Next exact
task is coordinated backup/hash-verified installation ofc581a52, fullrestart
(newfiles), then one actual two-client race using Multiplayer menu. The friend
needs this identical package. No standalone /akart net probe prerequisite.
Record both actual GO/movement/stop and usability before claiming acceptance.
Mirage follow-camera can clip a delayed observed opponent at high speed; this
is a known candidate limitation, not an invented transport result. No higher
traffic rate, shared-winner claim or automatic reconnect is authorized by source
passes. Fullsocket recovery/productionauthority/contact/finish agreement and
release remain open. Continue only after addressing actual playtest feedback.
