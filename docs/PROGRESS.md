# PROGRESS — persistent project handoff

## 2026-10-26 21:14 +01:00 — combined Claude visuals installed and packaged

Reviewed merge/runtime `3f1b3fe` on `codex/claude-race-integration` is committed
and installed in the existing classic_beta AzerothKart folder. Merge parents
preserve Codex's rematch work and Claude e3c82ad unchanged. Independent preflight
confirmed prior installed94d4d1e; normal WhatIf/approved helper then backed up
all85prior files and verified all85new source/installed hashes. Installed tree
has86files, retaining the legacy GoblinDragCar extra unchanged. No deletes,
SavedVariables/WTF edits, other-addon changes or native input.

Ignored deployment root `local-artifacts/deploy-20261026-claude-visuals/` holds
preflight, audit/package script, receipt and backup manifest
`backups/20261026-211330-182-12bf1d52b9d04a30aa045823e40bd41e/install.json`.
The independent audit reread all prior backup and current source/target files.
ZIP from the tested installed paths: `../AzerothKart-ClaudeVisuals-3f1b3fe.zip`,
85entries/71,169,577bytes, SHA256
`A79B1F35CD6040BAD37F3FF58B0354267748D0F57D91D145FF406F4D5ABA8683`.
Every entry read back and hashed. New Celebration.tga/resized Gryphon sheets
require a full restart on both clients; reload is insufficient.

Executed source checks and open native limitations are in the reviewed entry
below. Native visual/sound/wing/hitch/rematch checks remain NOT RUN. No branch
publication, release, main merge or milestone completion; other worktrees and
untracked outputs remain unchanged. The review request authorizes integration,
not a new automatic GitHub push.

**Next exact task:** after full restart, select Gryphon Rider, check beat/glide,
then finish a solo run and inspect its score/result screen. When a friend is
available, use the matching ZIP for one race→Play Again→Change Map, confirming
same players and quiet pending/tied result updates. No standalone probe.

## 2026-10-26 21:09 +01:00 — Claude visual stack reviewed and integrated

Owner authorizes conditional integration. From clean7cd2aed/installed94d4d1e,
`codex/claude-race-integration` combines unchanged Claude tips a4fe2d5/8511d8c/
e3c82ad with current rematch work. [Review](reviews/2026-10-26-claude-visual-integration.md)
records accepted source, corrections and exact tests. Other worktrees and their
untracked files are untouched. The Menu overlap was resolved around the current
room controls, preserving both branches' regressions.

Includes Scarlet courtyard/landing/full-grip fixes, HUD/name tags/results/score
celebrations and Gryphon wingbeat/glide. Graveyard now3 (Library3/Armory2/
Cathedral3), keeping all historical boards. Exact finish identity/placement
metadata replaces row guessing, including a tested cold-first-save fix.
Final MP visuals preserve pending/tied retained backend results and quiet late
refresh/reopen, Play Again/map/Leave commands. Stale/terminal peers rest their
wings. No mechanics, wire, live-controller or send-budget change.

Focused Lua51 dungeon/presentation/menu/ui/solo_records/score_sharing/
multiplayer_integration PASS7modules, all80sources/tests parse. Final metadata
checks rerun PASS after cold-initialization correction. Agent menu Lua54 PASS.
Celebration byte check, all10outline checks and11board export PASS. Structural
validator retains only the2historical expired skill links; no full pass claimed.
Review notes record initial stale assertions/fixture failures and corrections.
No redundant broad suite or image rebuild. Native client checks NOT RUN.

Production pool90/91/150; Gryphon sheet/outline add15MiB raw, Celebration0.5MiB;
all preallocated, actual native memory/hitches unmeasured. Full restart needed.
No milestone gate closed, push, release, force or main change. Prepare backed-up
combined install and matching ZIP next; exact runtime/receipt follows below.

## 2026-10-26 20:49 +01:00 — multiplayer rematch build installed and packaged

Owner resumes the pending task. Source remains clean tested `94d4d1e` on
`codex/multiplayer-rematch`. The earlier actual install did not execute because
automatic approval review reached a usage quota; it created no protected copy
or backup. This run rechecked the unchanged prior da292f6 installation, reran
WhatIf, then completed the normally approved backup/copy/hash operation.

Independent preflight and post-copy Python readback verify all84source/installed/
manifest hashes, all85complete prior backup files, and the unchanged legacy
GoblinDragCar.tga extra. Installed tree remains85files. No source changes since
the recorded focused Lua51 passes, so those suites were not repeated. No native
input, SavedVariables/WTF, other-addon, deletion, push or release.

Ignored deployment root: `local-artifacts/deploy-20261026-multiplayer-rematch/`;
backup manifest `backups/20261026-204850-439-ec75c19688c84acb9438ab1e8695b76a/install.json`.
Receipt and reproducible audit/package script are stored there. Matching ZIP
from tested installed paths: `../AzerothKart-MultiplayerRematch-94d4d1e.zip`,
84entries/69,360,087bytes, SHA256
`FA0A41B01F507F26D184B5216E36AA2AA32C31757C711D5429E5656E44CE48CA`.
Every ZIP entry read back and hashed. No new runtime paths; reload suffices from
the preceding Scarlet-stat-bars build. Older clients missing its atlas need a
full restart after updating. Native rematch/turning checks remain NOT RUN.

Claude now has `claude/gryphon-wings`e3c82ad, carrying its race screens and
Scarlet-v3. Its results layout overlaps the already-recorded rematch boundary;
all that source/art stays separate for a reviewed integration. Its worktree,
the canonical checkout and existing untracked files are unchanged. This local
feature branch has not been published; no milestone acceptance was added.

**Next exact task:** both matching clients update/reload when available, finish
one race, use Play Again, then host Change Map→Play Again with the same friend.
Guest Join, both Ready, host Start. Check observed placements/Close results and
explicit Leave Multiplayer. No standalone transport probe is required.

## 2026-10-26 16:33 +01:00 — multiplayer postrace room and rematch implemented

Owner prioritizes local multiplayer placements and same-player Play Again/map
changes. Own `codex/multiplayer-rematch` from clean caab661; installed source
was da292f6. Read Claude's separate Scarlet-v3 reservation86efbca, touching only
map data/Menu.TRACKS here; did not integrate or edit that worktree. Reserved
results/lobby/control regions in the Codex handoff. [ADR0021](adr/0021-multiplayer-postrace-room.md)
and [implemented API/player flow](MULTIPLAYER_POSTRACE.md) document the slice.

Actual race completion retains the selected peer/roles/kart in a bounded300s
postrace room. Host rematch/map offer reuses current handshake/grid/clock flow
with a fresh next session; guest Join, both Ready and host Start remain explicit.
Late old-round traffic is rejected. Core lease/traffic history stays continuous,
with unchanged0.5s/2attempts/158-byte ceiling and no new wire message or heartbeat.
Dependency exceptions now close safely without a stuck busy flag, including
guest candidate failure inside a native send callback.

Copied local results compare local Race.totalTicks with received terminal peer
tick, joint rank1 on ties; missing finish stays pending. Rows update after late
peer finish without replacing the local race/fanfare. Results use Play Again,
Change Map/Lobby and explicit Leave Multiplayer; Close results keeps the room.
Solo Start/track/kart cannot silently dissolve it. Explicit Leave restores all
selectors. No MP result enters solo Highscores. No trusted winner or8-player
claim, and existing turning/physics/track/art data is unchanged.

Actual Lua51 combined command for peer_session/live_race/session_transport/ui/
menu/multiplayer_integration/score_sharing PASS7modules/80parsedfiles. Final
exception-guard regressions plus real two-round menu integration also PASS.
That integration finishes two races through actual Race/Checkpoints/Laps using
a bounded waypoint tape, changes Mirage→Stormwind with same full peer names,
fresh code/full countdown, opposite second finisher, pending→ranked rows and
Close results, checking no solo scores/newwidgets or native budget reset.
Earlier runs exposed obsolete solo-fallback assertions and a mock5Hz-refresh
race; corrected targeted assertions preserve genuine solo behavior. Independent
reviews found a missed Kart re-enable and constructor-error busy leak; both
fixed with regressions. Final backend review reports no remaining blocker.

Catalogue check PASS11boards; diffcheck PASS. Structural validator retains only
the two historical expired skill links, not a full pass. Production pool stays
89/77/140; legacy Oval fixture89/175/140. Full-suite/Python-service repetition,
Lua54 and native postrace/rematch/turning checks NOT RUN for this slice. No
roadmap checkbox closed. New source stays local; no new push/release authorized
by this task. Both original worktrees and existing untracked files preserved.

**Next exact task:** commit the tested source, complete the usual backed-up
installation and matching friend ZIP. With both clients updated/reloaded, later
test one race→Play Again→Change Map using the same players. No standalone probe.

## 2026-10-26 14:19 +01:00 — Scarlet v2/stat bars published and installed

Approved combined runtime `da292f6` is published and installed. Atomic dry-run
and actual create-only push succeeded for `codex/scarlet-stats-review`da292f6,
`claude/scarlet-fixes`8889aa4 and `claude/kart-stat-bars`e122120. Exact remote
hashes read back; main remainsf923d15. Both original worktrees/untracked outputs
are preserved. No force, author rewrite or release.

Independent preflight confirmed the previous installed9c80746 tree and unchanged
Codex systems. PowerShell7 WhatIf and actual backed-up copy/hash helper PASS.
Separate Python readback verifies all84source/installed/manifest hashes, all84
prior backup files and the unchanged legacy extra. Installed tree85files. No
SavedVariables/WTF, other addon, client input, deletion or source change during
deployment. Focused source tests remain the preceding entry; no redundant run.

Ignored deployment root: `local-artifacts/deploy-20261026-scarlet-stats/`;
backup manifest `backups/20261026-141854-261-1618a06611c94a1c99bb1834936918c8/install.json`.
Receipt and reproducible audit/package script are in the same root. Matching
friend ZIP from installed tested paths: `../AzerothKart-ScarletStats-da292f6.zip`,
84entries/69,355,566bytes, SHA256
`A1813106D2A986D317838ADBFA94D636B18E1822311BE2FDB21EA4F45A4ECE9F`.
Every ZIP entry was read back and hashed. New path `Assets/UI/StatBars.tga`
requires full client exit/relaunch for both users. Native checks NOT RUN.

**Next exact task:** owner fully restarts, inspects the chooser/Garage stat bars
and drives Library/Armory/Cathedral v2, especially full-grip yards and the two
Cathedral stairs. Friend updates this matching ZIP/restarts before score catch-up.
Version1 history stays saved separately; no milestone or multiplayer-scale
acceptance is added by publication/installation.

## 2026-10-26 14:16 +01:00 — Scarlet v2 and stat bars approved in combined source

Owner requests review and conditional install/push of Claude's latest work.
Reviewed the six-commit stack through e122120 (Scarlet fixes8889aa4 plus kart
bars), based on the installed Codex98f433e/runtime9c80746. Own
`codex/scarlet-stats-review` from clean98f433e/reservation2a14f49; combination
has no merge conflict. Two independent reviewers found no blocking issue.
[Review, scope, executed checks and limits](reviews/2026-10-26-scarlet-fixes-stat-bars.md).

Library/Armory/Cathedral become version2, with matching catalogue contexts.
Library removes Loksey's checkpoint/path NPC; Armory yard and Cathedral gardens
have full grip; Cathedral's plinths leave the two stairs as the way up. Explicit
generated collision follows selected drawn props. Graveyard and all current
Codex collision, input, handling, transport/score and remote-display runtime
remain unchanged. Old version1 scores stay saved separately; no migration.

Kart chooser/Garage add four read-only handling bars. Actual Balanced4/4/4/4,
Heavy5/2/2/6 and Agile3/6/6/2 values use the documented4%-per-window scale.
Guarded atlas load once, text fallback on refusal; reviewed production budget
89frames/77textures/140fontStrings (+8textures/+4labels), all created once.

Executed combined Lua51 dungeon/menu/ui/circuit/score_sharing/presentation:
PASS all6modules/80parsedfiles. Catalogue check PASS11boards; original stat
atlas byte-exact rebuild PASS (SHA256f1528efd…6131). Diff checks PASS. Structural
validator still reports only2historical expired links; not a full pass. Full
suite/Python-service repetition, Lua54, map image rebuild and native checks
NOT RUN for this slice. No new milestone, global or multiplayer-scale claim.

**Next exact task:** commit/publish the approved combination and both original
Claude tips; back up/verify the existing installation and build a matching friend
ZIP. New stat texture requires full client restart. Preserve both worktrees,
legacy extra and player saves; no main update, force push or release.

## 2026-10-26 10:16 +01:00 — combined Scarlet build installed and packaged

Owner explicitly requests the addon installation for testing. Installed tested
runtime `9c80746` from published documentation head `4d725a3` into the existing
`_classic_beta_/Interface/AddOns/AzerothKart` target. Independent preflight
confirmed no runtime changes since the43-module Lua51/24Python passes and an
exact prior installed01bd880 tree. PowerShell7 WhatIf and actual backed-up
copy/hash helper PASS; separate Python readback verifies all83source/installed/
manifest hashes and all78prior backup files. The known legacy extra remains
unchanged. Installed tree has84files. No deletion, SavedVariables/WTF, other
addon, client input or parallel-worktree changes.

Ignored deployment root: `local-artifacts/deploy-20261026-scarlet-integration/`.
Backup manifest: `backups/20261026-101557-482-e75adc6299df4e0b828e45e64ec8b259/install.json`.
Audit script and receipt are stored in the same deployment root. Matching
friend ZIP, built from the tested installed paths and fully read-back hashed:
`../AzerothKart-ScarletCup-9c80746.zip`,83entries/69,380,311bytes, SHA256
`D99637FECCC1E8FE0C84CAD78D2920E54F3B1A75367A29971DB5794BC20F4492`.

Six new Library/Armory/Cathedral background/preview paths were added; a full
client exit/relaunch is required, rather than only reload. No runtime source
changed during deployment, so the recorded full source tests were not repeated.
Native map loading, pool feel and matched-build score delivery remain NOT RUN.

**Next exact task:** owner fully restarts WoW, opens `/akart`, selects the new
Scarlet sprints and drives Cathedral beside the round pool; friend installs the
matching ZIP and also restarts before checking score catch-up. Preserve all
saved scores. No milestone, eight-player or release acceptance is added.

## 2026-10-26 10:10 +01:00 — authorized Scarlet publication verified

Atomic dry-run and actual normal atomic push succeeded for all five branches.
Independent `git ls-remote --heads` readback matched every local tip:

- `codex/scarlet-integration`: tested merge/runtime source `9c80746`.
- `claude/scarlet-library`: `8b09309`.
- `claude/drive-fixes`: `fb8b296`.
- `claude/scarlet-armory`: `559cc4f`.
- `claude/scarlet-cathedral`: `ea4425d`.

Remote `main` remains `f923d15`; no forced update, author rewrite or release.
Both original worktrees and their untracked files are unchanged. This entry
adds documentation only; the full combined source checks in the preceding
entry still apply. The final documentation commit is published on the same
integration branch after this verified runtime-source publication.

Installed addon remains `01bd880`: source publication did not copy addon files
or touch player data. Native checks for new courses remain NOT RUN.
**Next exact task:** deploy the tested combined source with a complete prior
addon backup/hash verification and matching friend ZIP, then fully restart
both clients for the new asset paths and check Cathedral pool sliding/score
catch-up. Main integration and release remain separate, unperformed actions.

## 2026-10-26 10:06 +01:00 — Scarlet fixes integrated and combined checks passed

Owner authorized fixing the two review findings and publishing the queued work.
Own `codex/scarlet-integration` from2f04f3a/reservation1ae33e6, combined with
reviewed Claude ea4425d. Four merge conflicts resolved while preserving retired
Oval and both sides' assertions. [Full integration review](reviews/2026-10-26-scarlet-integration.md).

Swept-disc first contact now registers the production4.3-unit grazing repro;
minimum resolved-segment clearance158.003751800 exceeds required158. Tangent
slide, rim escape,360rotated grazes, long sweeps and circle/box ties are covered.
Rectangle-only resolution retains three passes; disc tracks have eight bounded
contacts, no per-step allocations and the same Physics wall-penalty signal.

ScoreSync appends L/A/C with11activeboards/12slots and mandatory retiredO=0.
Max legal HELLO155bytes incl prefix (Physics12 max147), under unchanged158.
All11 production boards catch up in adapter mocks; new L/A/C finishes publish
at the existing pace. Test Oval cannot re-enter publication or selection.
The four sprints stay solo; the seven lap maps keep the existing two-peer flow.
Thunder Bluff/Graveyard v2 retain old saved contexts. No save migration/deletion.

Executed: full Lua51 suite PASS43modules/80parsedfiles; focused geometry/score
and combined UI/menu/circuit/adapter/multiplayer checks PASS; Python24tests PASS;
catalogue check PASS11boards; matching36moduleTOCs/83runtimefiles and six TGA
header/length/hash checks PASS; staged/working diffcheck PASS. First full Lua
run found a stale unavailable-Library assertion; its unknown-course guard and
new sprint positives now pass in the corrected full run. Independent review
found no remaining blocker. Structural validator has only the two historical
expired skill links, not a full pass. Lua54/rebuild/native checks NOT RUN.

UI/Presentation/Physics/SessionTransport/ScoreDiscovery/ScoreSharing runtime
files are unchanged from the Codex base. Production pool89/69/136 unchanged.
Claude's worktree and canonical/untracked outputs are preserved. No main merge,
release or install. Installed runtime remains01bd880. Authorized regular branch
publication follows after committing this reviewed combination.

**Next exact task:** publish/verify the combined branch and all four original
Claude tips; then prepare the separately coordinated backed-up install and
matching friend package. Native checks require full restart for new image paths.

## 2026-10-26 — Claude Scarlet queue reviewed; integration held for two fixes

Reviewed all13queued commits through Claude`ea4425d`, including Library,
drive-fixes and Armory, against clean Codex`0edaf2c`/installed`01bd880`.
Own`codex/scarlet-review`; source/installed addon, Claude's checkout and the
canonical checkout remain untouched. No merge/push/install/release.
[Findings, exact reproductions and integration plan](reviews/2026-10-26-scarlet-queue.md).

Visual/menu/earlier drive work has no blocking finding. New round solids skip
the sweep and test only endpoints: actual production Cathedral4.3-unit segment
crosses the required pool clearance but returns hit=false. Fix swept-circle
contact before accepting the primitive. Claude's known score dependency also
needs adaptation to current retired-Oval source:11activecourses/12HELLOslots,
L/A/C appended to stable codes, retiredO=0. Actual in-memory Lua51 codec proof:
naive full-bound HELLO164bytes exceeds158; enforcing retiredzero yields155
maximum,147with Physics12. No traffic-budget increase is accepted.

Actual focused Claude Lua51 dungeon and menu/circuit PASS,78files parsed;
catalogue check PASS12standaloneboards (includes oldOval). Six new TGA headers,
raw lengths and SHA256 match the handoff. These checks do not approve the
standalone tree or replace the failing collision reproduction. Conflict-only
merge-tree preview identifies4files, with no refs/index/worktree changes.
Full combined suite, native/newassetloading, asset rebuild and Lua54 NOT RUN.
Old score contexts and all current networking/handling/turning fixes must stay.

Claude's reported temporary archive deletion is recorded in the review; this
run deletes nothing. The absent archive was not tracked, and its previous
contents/actions are not independently certified. No source data was removed
by this review.

**Next exact task:** fix swept-disc contacts and extend bounded score mappings
with regressions, then prepare the combined review branch preserving all current
assertions and regenerate11activeboards. Native validation and installation
follow only after those checks; leave both original worktrees untouched.

## 2026-10-26 09:18 +01:00 — turn smoothing installed and friend ZIP verified

Runtime`01bd880` is now installed in the existing AzerothKart AddOns directory.
PowerShell7 backup/copy/hash helper reported Verified; independent Python
readback confirms77source/installed/manifest hashes, all78prior backup files
and the preserved legacy GoblinDragCar.tga extra. No SavedVariables/WTF, other
addon, client input, push, release or other worktree was changed.

Ignored deployment root: `local-artifacts/deploy-20261026-remote-turns/`;
backup manifest `backups/20261026-091809-456-4768dfeab000436c8025ab41db6b5f65/install.json`.
Receipt and reproducible installed-file/ZIP audit script are in that root.
Matching friend package `../AzerothKart-SmoothTurns-01bd880.zip` has77entries,
61,240,587bytes; SHA256
`048CA20C14E8310C504BDD4E55DA53D65A517D5891986DEE21F0045B4CD40239`.
Every entry was read back and hashed against the tested source/installed files.
There are no new runtime paths; `/reload` suffices from the preceding build.
Focused source checks/review remain the preceding entry; native turning is
NOT RUN. No acceptance checkbox changed.

**Next exact task:** friend installs this matching ZIP, both clients reload,
and compare remote motion through a few normal corners. Record turning feel;
no standalone probe or score reset is needed. Score discovery/public sharing,
shared result authority and eight-racer delivery remain separate open work.

## 2026-10-26 09:17 +01:00 — remote turn corrections at render cadence

Owner's actual friend playtest confirms smoother straight-line opponent motion,
with no observed straight-line stutter, but turns still appeared as4–8 distinct
ticks. This is qualitative native evidence for the preceding movement patch;
it does not establish scale, packet-loss, shared results or complete acceptance.
Own `codex/remote-turn-smoothing` from clean`890c351`; read current handoffs and
preserved Claude's separate Cathedral983f4e2 reservation/worktree and all scores.

Diagnosis/source change: wire heading precision is adequate. New snapshots can
replace the inferred yaw abruptly, and zero-speed/wall forecasts previously
froze rotation as well as position. Presentation now retains bounded running
yaw independently while x/y still stop at the first collision. The UI reconciles
heading changes on the short arc at up to6rad/s, using copied controller time
and two resettable scalars. It keeps the64-direction sprites unrotated. Local
physics/input, translation paths, packet format/cadence/budget, art and UI-object
counts are unchanged. No per-frame allocations, loads, geometry calls or sends
are added. Terminal/invalid samples stay exact; stale yaw stops at the existing
500..1250ms horizon and the displayed heading settles to that frozen target.

Executed actual Lua5.1 commands (Python314 with existing pinned Lupa path):
`scripts/test_lua.py --runtime lua51 --tests presentation` PASS;
`scripts/test_lua.py --runtime lua51 --tests ui multiplayer_integration` PASS.
Both parse all80Lua source/test files. The synthetic2Hz/350ms-transit/60Hz
onset/release replay reduces maximum angular step113.961°→5.730°; the retained
straight replay still has0held frames/3.333unit maximum step and1.465unit
steady-turn error. New UI coverage verifies between-packet stationary turning,
clock-based progress, state isolation, no repeated art loads and unchanged pool.
Production pool remains89frames/69textures/136fontStrings (legacy Oval fixture
reports167textures). `git diff --check` and PowerShell7 install WhatIf PASS.
Independent focused review found no blocker. Lua54 and new native turning
checks NOT RUN; no milestone checkbox, eight-racer or score-delivery claim.

API_CONTRACTS and LIVE_RACE now describe the additive angular behavior and
helper. No Claude source merge/push/release or client input. Deployment of this
follow-up is next, with complete prior-addon backup and installed-file/ZIP hash
verification. Scores and the legacy extra file must remain intact.

**Next exact task:** both updated clients reload and drive a few normal corners;
compare the friend's turn motion with the previous ticking. No standalone
transport probe is needed. Native score sharing/public discovery and eight-peer
transport acceptance remain separately pending.

## 2026-10-26 08:03 +01:00 - score discovery correction installed and packaged

Runtime`1c62f3a` is installed in the existing AzerothKart AddOns directory as the
follow-up correction for the reported separate boards. WhatIf passed; actual
PowerShell7 backup/copy/hash helper reported Verified. A separate Python readback
confirms all77source/installed/manifest hashes, all78complete prior backup files,
and the unchanged legacy extra. Installed tree has78files; no deletion, player
WTF/SavedVariables access, other-addon changes, client input, pushes or release.

Ignored manifest: `local-artifacts/deploy-20261026-score-discovery/backups/
20261026-080056-125-1263d25437c74691b1a857e7fe40fa23/install.json`.
Independent audit/script/receipt are in that deployment root. FriendZIP built
from installed tested source paths: `../AzerothKart-ScoreDiscovery-1c62f3a.zip`,
77entries/61,239,970bytes, SHA256
`9CD2E9C877E1E1D8FB0A93B0F481D1AF8CCB76BB8AC2B1B291F54EC3DF83488A`.
AllZIPentries were read back and rehashed. No new runtime path compared with the
previous installedc9build: `/reload` is sufficient from that build. Older clients
missing earlier modules/assets still need a full restart after updating.

Focused source passes/review remain the preceding checkpoint; deployment adds
no code change. Native delivery remains NOT RUN because WoW is closed. The
correction covers current groups/validated race peers; broader public-channel
roster discovery remains pending, and no complete global-board guarantee is made.
Current ClaudeArmory559cc4f and canonical5570968/untracked work remain separate.

**Next exact task:** both updated clients reload, join the same ordinary party,
open matching Graveyard Highscores while stopped/out of combat, and wait roughly
30seconds. Existing saved times should catch up without another race or copying
results. Record reciprocal native board updates before marking delivery passed.


## 2026-10-26 07:58 +01:00 - scores discover native groups and validated racing partners

Owner screenshots show separate own-only Graveyard records with channel member
list pending/zero connected. Saving works; recipient discovery never completed.
Own `codex/score-peer-discovery` from clean installed`d480373`/runtime`c9ebf03`.
Read both handoffs and preserved Claude's independent Library/drive/Armory work;
current observed checkout is`claude/scarlet-armory`559cc4f. No new map integration.

Pinned70450native source confirms the existing channel tuple/display index.
Its UI selects a channel before roster reads; no documented request-only method
was found. Existing mocks incorrectly populated the cache automatically on join.
No native selection borrowing, ordinary/unlogged fallback or global-route claim.
An initial CUA observation found an active drive and issued no game input; the
current26October app inventory shows no open WoW. Native receipt NOT RUN.

Implemented additive ScoreDiscovery.ReadGroup: bounded complete native party/
raid full names, noUI/join/send, stable copied/deduped identities and repeated
shape/identity checks. ScoreSharing unions channel/currentgroup/validated native
racer sources under the same32recipient cap and existing paced logged whispers.
SessionTransport introduces a peer only after accepted scoped incoming control;
configured names, targets, friends lists and arbitrary inbound HELLOs do not
admit recipients. Callback errors/reentrant Stop cannot damage the game lease.

Partial channel/group data retains last good snapshots for30/15seconds, not
forever and not an immediate empty reset. Confirmed racing peers last30minutes
in memory, refreshed by already-admitted valid score traffic. Complete leave/
empty replaces its source; expired admission is checked again on receive/send,
even while a race/combat blocks idle scanning. This closed a review finding
where a late HELLO could otherwise revive expired contact before Update.
Pending group events also preserve their bounded lease/urgent queue; complete
membership invalidation takes effect immediately. Copied discovery reason/
count fields and `/akart scores` explain each source. No contacts save/schema
migration, score deletion, UI allocation, wire/physics/course/art changes.

Executed actual pinned Lua5.1: `scripts/test_lua.py --runtime lua51 --tests
score_discovery score_sharing session_transport solo_records score_sync menu
multiplayer_integration` PASS7modules/80files. After final admission/event guards,
`--tests score_sharing` PASS again. New native-mocked permanent-empty-channel
case exchanges the reported638/865tick Graveyard records between full UTF8-named
group peers, preserves rows/ranks across repeated pending reads, and never asks
for UI selection. Tests also cover group/race union, known ungrouped partners,
source expiry before Update/under a Core lease, true leave, partial group events,
protected saves and native callback errors/reentry. Independent review found no
remaining practical blocker after the expiry fix. Whitespace PASS; validator
retains only2historical expired skill links. BroadLua54/native delivery NOT RUN.

All77installed files still match the previousc9manifest, with the one knownextra;
no unexpected installed work. Source is ready for the requested follow-up fix
install with full backup/hash verification and updated friendZIP. Public
stranger discovery remains pending. This does not claim complete/global ranking
or actual two-client delivery. Both clients must update; `/reload` suffices from
the previous combined build because no runtime file is added.

**Next:** install this reviewed correction, then both players reload, join the
same ordinary party and open matching Highscores while stopped. Existing times
should seed/sync without another race; record actual receipt before native pass.


## 2026-10-25 22:58 +01:00 - all reviewed updates installed and packaged

Owner explicitly requests installation of all missing updates. Tested runtime
`c9ebf03` (documentationHEAD`a964a12`) is now actually installed in the existing
`_classic_beta_/Interface/AddOns/AzerothKart`. It includes reviewed Thunder Bluff
and solo Scarlet Graveyard, score-sync/catalogue fixes, retired Oval, seven-map
experimental two-peer eligibility, smoother opponent motion and the finite
opt-in GroupProbe. Claude's unfinished Library reservationb56d227 stays separate.
No unreviewed source or other-worktree changes were deployed.

Before installation, independent read-only audit confirmed all70previous source
files still matched the priorbb085ac manifest; only the known legacy drag-car
extra existed. PowerShell7 installer WhatIf PASS, followed by actual authorized
backup/copy/hash verification. A separate Python readback verifies all77source/
installed/manifest files, all71complete prior backup files, and the unchanged
legacy extra (78installed files total). No deletions, WTF/player-data/other-addon
changes, native client input or packets, push/release or milestone completion.

Manifest: ignored `local-artifacts/deploy-20261025-all-updates/backups/
20261025-225742-759-34351ea7d848497f9f3050bc89e79eb1/install.json`.
Independent audit script and receipt are in the same deployment root. Friend
ZIP from installed tested paths: `../AzerothKart-Combined-c9ebf03.zip`,77entries,
61,237,736bytes, SHA256
`8F563519F3DDDE25CE3C6CFADF9D4991D864CA4AC859EC3D42F77741F9B5E819`.
Every ZIP entry was read back and matched against the tested source; the old
unreferenced extra is preserved locally but excluded from the clean package.

Source/runtime tests remain the actual previously recorded Lua51 passes; no
runtime source changed for deployment. Catalogue8boards/whitespace checks PASS;
structural validator retains only the2historical expired skill links. Installed
file verification is not a native gameplay or group-delivery result.

**Next:** both players update and fully exit/relaunch WoW (seven new files from
the prior installed build), then check normal driving/nearby opponent motion.
The short optional consenting PARTY/RAID procedure is in GROUP_DELIVERY.md;
actual group receipt and8racer capacity remain NOT RUN. Existing two-player mode
requires no group. Eight-player racing and live Graveyard remain unimplemented.


## 2026-10-25 22:52 +01:00 - smoother opponent motion and bounded group route check

Tested source commit: `c9ebf03` (see Git for the full hash), on
`codex/multiplayer-smoothing`.

Owner asks to proceed toward smooth multiplayer. Own branch
`codex/multiplayer-smoothing` from clean`f6c6338`; explicit handoff reservation
preceded source edits. Preserves integrated Claude courses, eight solo boards,
seven two-peer lap maps, retired Oval, Physics12 and actual whisper limits.

Fixed two reproducible display artifacts: the old500ms forecast exhausted
itself during transit before the next2Hz snapshot, and the displacement chord
lagged the current direction on a turn. Presentation retains500ms defaults but
accepts an optional500..1250ms horizon/at most76points. UI uses sample age+600ms
and caches by receipt/sample/sequence, including equal-millisecond packets.
Valid chord direction advances by half the measured turn angle. First contact,
terminal/stale freezing and observational-only state remain. No physics, input,
clock negotiation, wire cadence or extra UI object changes. Unknown braking,
steering changes, packet loss and clock uncertainty can still cause corrections.

Actual Lua5.1 synthetic straight,2Hz/350mstransit/60Hz at200speed: old160held
frames out of249/70unitmaxjump/66.667unitpeaklag; current0held/3.333unitmaxstep/
~0peaklag. Steady200speed/2.6rad/s turn error falls from41.788unit old reference
to1.465units including steady0.4radslip. These are reproducible source metrics,
not measured native smoothness, ping or universal prediction accuracy.

New GroupProbe is a finite explicit PARTY/RAID delivery check, never an enabled
race route. Fixed2..8fullnative roster, ten single-sender groupDATA slots over
20s, paced whisperreceipts and4sdrain; perpeer masks/RTT/duplicate/reorder/error/
throttle and missed local slots. No registration or sends on load/Init. The
shared Core lease gains only diagnostic-time events; no frame is created.
Actual native acceptance is separate from receipt. Native opaque fields,
roster/lifecycle/time/lease changes and callback reentry fail closed. A preflight
lease-overwrite review finding was corrected before final acceptance.

Group/race attempts share persistent2calls/158prefix+payloadB per rolling second
and0.5second cadence via ReserveDiagnosticSend. Standalone historical probes
retain their rates, separated by a1second quiet handoff; scores already yield
and wait2sidle. Root coverage checks immediate group-to-race budget persistence.
[Simple command procedure, source/API evidence and limits](GROUP_DELIVERY.md).
A low-rate single-sender route check is not an eight-racer capacity proof.

Executed pinned actual Lua5.1:
- Agent`--tests presentation` PASS, including straight/turn metrics, horizon caps,
  invalid values, wall/terminal/stale paths and no input mutation.
- Root`--tests ui session_transport transport_probe` PASS for the first integration.
- Final root`--tests transport_probe score_channel_probe group_probe ui menu
  multiplayer_integration` PASS,80Lua files parsed. Another focused run passed
  group_probe/presentation/session_transport before a new fixture-name typo was
  caught; the typo was fixed and the affected final six modules passed.
- GroupProbe final focused check PASS, including2memberPARTY and mocked8member
  RAID:10multicasts/70distinctreceipts,300msRTT, budgets/identity/roster/callback
  guards. These are API doubles, not native delivery.
- Whitespace PASS; actual source diff confirms Physics/Input/Race/Courses,
  scores and all assets unchanged fromf6c6338. Structural validator still reports
  only2historical expired skill links; not a full validator PASS.

Independent final source review found no remaining practical blocker. Broad
Lua5.4/stress/profiling, native group receipt and native new motion/8racer
aggregate capacity NOT RUN. No install, push, client input, native packets,
release or milestone completion. Installed source remainsbb085ac. New candidate
has36modules; it needs a full restart after future install for GroupProbe.

Concurrent Claude work was observed, not changed: `claude/scarlet-library`
`b56d227` adds its reservation only, with existing untracked outputs preserved.
Its Dungeon/Menu/Courses/art scope does not overlap this network/display slice.
Canonical checkout remains5570968 and its untracked work is intact.

**Next exact task:** deploy this tested combined candidate for ordinary two-player
feel feedback and one short consenting group-delivery check. Resolve native
fan-out evidence/grouping policy before enabling an eight-member room. Existing
ungrouped two-player racing remains available; Graveyard live support is pending.


## 2026-10-25 22:24 +01:00 — Claude courses integrated and feature branches published

Tested source merge `b98296c232ae014bf0531cbd9cbbaff10077a801` on
`codex/claude-courses-integration` combines map checkpoint `d30b582` with
Claude `1bc3ac8` (including Thunder Bluff `a7aeb66`). Reviewed the canonical
Claude handoff, geometry/Race/record changes, assets and shared contracts.
Four merge conflicts were resolved preserving both agents' work.
[Exact review and evidence](reviews/2026-10-25-claude-new-courses.md).

Eight production solo/score courses now include Thunder Bluff and Graveyard.
Test Oval stays retired. Seven lap circuits have two-peer lobby/grid/GO support;
Graveyard stays solo until live sprint support is reviewed. Solo sprint target
and score lapCount are1; countdown/running status now says Sprint. ScoreSync's
catalogue-count blocker is fixed: eight active contexts, nine HELLO slots,
newT/G, stable old codes, retiredOzero. History remains saved. Production pool
89frames/69textures/136fonts,35TOCmodules; Physics12 remains unchanged.

Executed `scripts/test_lua.py --runtime lua51`: full suite PASS,78files parsed.
New sprint finish/status/save, eight-board catch-up/new-best sharing, seven-map
grid/GO and complete mocked two-client flow pass. City geometry-only check PASS;
export/check PASS8boards; Python boundary11tests/store13tests PASS; whitespace
PASS. Initial integration fixture/count/unknown-code failures were fixed before
this final full pass. Structural validator retains only2historical expired
links. Dungeon model-based check could not run against`--wc3 .` because extracted
models are absent. Independent checked-in footprints plus source layout serialize
exactly to runtime, with route/gap/three-unavoidable-gate flood-fill validation
PASS. Full art rebuild, Lua5.4, native new maps/delivery/city multiplayer and
8participant capacity NOT RUN here.

Owner-authorized ordinary push published `claude/thunder-bluff` at
`a7aeb6648d0adc51249729702a1b3e6ed38df71f` and `claude/scarlet-graveyard` at
`1bc3ac8db34e40599377d458971e3b70ad7c3ae6`; exact remote readback verified.
No main update, forced push, release, install, client input or player-data access.
Original Claude branches retain their documented sync dependency; use the fixed
combined source for a future install. Installed runtime remains`bb085ac`.
Clean combined checkout; other worktrees still`1bc3ac8`/`5570968`, with their
existing untracked work preserved. No milestone completion or8player claim.

**Next exact task:** establish an eight-racer fan-out/grouping route before the
bounded room controller with one common GO epoch. Raid grouping remains
undecided; preserve the working ungrouped two-peer mode. Live sprint support
is also outstanding.


## 2026-10-25 22:09 +01:00 — production maps checkpoint before Claude integration

Owner reports Physics12 feels good, requests Oval retirement/all-map multiplayer
and eight racers, then reconsiders raid grouping. Grouping is undecided; the
current ungrouped two-peer route remains available. Eight-player transport,
room/clock/roster behavior and native capacity are not enabled or accepted.
[Catalogue and capacity rationale](PRODUCTION_MAPS.md) records the exact scope.

On `codex/production-map-catalogue` from `aac1bdd`, removed Oval from selectable
Courses, menus, defaults, score contexts/publication and protocol admission.
Mirage is actual initial geometry/scenery, with guarded first-open loading and
Start refusal on missing art. Obsolete saved selection/history remain intact.
Production omits96road+2obstacle textures; the explicit mock pool is85frames/
69textures/135fonts. Offline fixture injection preserves old ellipse/collision/
input/lifecycle regression assertions without a shipped test switch.

All six finished courses negotiate through the existing two-peer flow, with
real map-version snapshots and legal role-stable grids. Mirage wire1 remains;
Oval0 is retired; cities2–6. ScoreSync keeps a zero retiredO HELLO slot and a
catalogue marker, with six active contexts. Physics12, geometry, art, packet
sizes/cadence and player data are unchanged. Exported store catalogue has6boards.

Executed pinned actual Lua5.1: `scripts/test_lua.py --runtime lua51 --tests ui
menu solo_records multiplayer_integration` PASS4modules/75parsedfiles; followed
by `--tests race_protocol peer_session session_transport score_sync score_sharing
race_grid circuit` PASS7modules. Covers actual production default, missing-art
refusal, retired-save preservation, all-map Ready/GO and two-slot geometry.
`scripts/export_score_catalog.py --check` PASS6boards; `git diff --check` PASS.
Structural validator still fails only the2historical expired skill links.
Lua5.4, actual client/map multiplayer and eight-player capacity NOT RUN.

No install, push, release, main/other-worktree change or milestone completion.
Claude has since supplied Thunder Bluff and Scarlet Graveyard on separate
branches. Next: review those exact commits and sprint/geometry proposal, adapt
score sync/catalogue without restoring Oval, then publish the reviewed branches
under the owner's new explicit request. The eight-player route decision stays
open during this independent integration.


## 2026-10-25 16:55 +01:00 — Physics12 tuning installed and packaged

Runtime commit `bb085acab4158b6a5f5e28e6b95b05bd076c25cf` is actually installed
with the existing PowerShell7 backup/hash helper. Independent readback verifies
all70source/installed/manifest hashes; all71prior files exactly match the backup.
The one unreferenced GoblinDragCar.tga extra remains unchanged. Installed Physics
is12 with48/78tick rewards,420acceleration and the no-recharge-during-boost guard.
No deletion, WTF/player-data access, other-addon change or native automation.

Ignored manifest: `local-artifacts/deploy-20261025-drift-tuning/backups/
20261025-165422-164-d76442ca7bdc4e77bb3f06a83ef74680/install.json`;
independent receipt `local-artifacts/deploy-20261025-drift-tuning/receipt.json`.
Friend ZIP built from installed tested paths and every entry rehashed:
`../AzerothKart-DriftTuning-bb085ac.zip`,70entries/50,964,398bytes,
SHA256`4495DE2FBAE3B8349757719DD0F80CAAC3E04A99F0758215DBE9A2A57645FFB2`.

**Next:** both players update and `/reload` from the automatic-scores build,
then give ordinary handling/boost feedback. No new addon files require a full
restart for this update. Old scoreboards remain saved under earlier handling;
Physics12 uses fresh compatible boards. New native feel/competitive balance
remains pending. No push, release, milestone completion or other-worktree change.

## 2026-10-25 16:51 +01:00 — wider kart tradeoffs and useful drift reward

Owner reports the installed automatic-scores/profile build tested "all good",
then asks for slightly larger kart differences and a more worthwhile drift/boost.
The non-drifting friend comparison is qualitative play feedback, not controlled
lap telemetry. No detailed native discovery/latency/scale evidence was supplied.
Own `codex/drift-reward-tuning` from `65cb646`, with reservation before edits.

Physics12 widens heavy/agile cruising caps from204/196 to208/192, acceleration/
yaw from±4% to±8%, steering build from±10% to±15%, and slip/recovery to±10%.
Balanced remains200/155/2.6 baseline. All keep common body, wall90%/80% rules,
reverse55 and boost260. Charge30/60ticks is unchanged; reward30/48 becomes48/78
ticks (0.8/1.3seconds), boost acceleration300→420. New charge waits for active
boost expiry, preventing continuous self-renewal/hidden charging; held Space
starts charging on the following tick. No input, geometry, score transport or
packet-format change. Version12 rejects older peers and separates compatible
scoreboards while preserving historical saves.

UI boost labels now derive half/full capacity (0.65/1.3seconds) rather than
hardcoded0.4/0.8. Presentation forecast yaw bound3.0 covers agile2.808 without
changing authority or the260speed envelope. No new UI objects/assets/runtime
files. Current physics/API/ADR/user copy and seven-board catalogue/example are
aligned. Shared leaderboards remain without kart columns/filters.

**Executed:** pinned real Lua5.1:

- `scripts/test_lua.py --runtime lua51 --tests kart_handling drift physics
  presentation ui session_transport solo_records`: agent PASS7modules/75files,
  including current-version checks, profile tradeoffs, 15-field10k seeded
  replays at30/60/144FPS, meter capacity and actual agile forecast.
- `--tests drift_payoff live_race multiplayer_integration score_sharing`:
  root PASS4modules/75files. Pure/native-mocked sharing and live codec remain
  compatible with the new handling version.
- Review found Lua5.4 lacks math.atan2; the new payoff fixture now uses the
  established atan2-or-atan fallback. `--runtime both --tests drift_payoff`:
  PASS in actual Lua5.1/5.4 with identical958/956/911tick results.
- After adding the active-boost charging guard, final `--runtime lua51 --tests
  drift drift_payoff kart_handling ui`: PASS4modules/75files. Holding drift
  during boost cannot bank charge; charging resumes automatically after expiry.
- Catalogue export/check PASS7canonical Physics12boards; whitespace PASS.
  Structural validator retains only the2historical expired skill-link failures.

Controlled actual Test Oval/Race/Checkpoints/Laps3lap fixture: no drift958ticks/
15.967s; current handling with prior reward-only constants956/15.933s; new
reward911/15.183s, a0.783s/4.91% gain over plain driving. All0grass/impacts.
Same ellipse/steering policy adapts to pose; inputs/trajectories differ, so this
is one repeatable feasible payoff, not universal/optimal human lap balance.
Profiles measured balanced/heavy/agile:0–10039/43/36ticks;2,000units639/621/659;
turning radius76.923/86.957/68.376. New tuning's native feel is NOT RUN.

Source review found no remaining runtime blocker; its boost-chain caveat was
addressed by the charging guard. No main/Claude branch merge, push or native
automation. Other worktrees/untracked work preserved. Tested source is ready
for the requested verified backup/install/package; deployment result follows.
**Next exact task:** owner/friend update and reload, compare normal corner exits
and charged releases, then tune only from new handling feedback. No new probe
series or unrelated gameplay feature is required.

## 2026-10-25 16:08 +01:00 — combined update installed and packaged

Committed runtime `6b4dc16d33004715714d072471bc3b1c99a8f6af` on
`codex/automatic-score-sync`. Owner's requested installed-menu correction and
combined synchronization build are now actually deployed with the existing
PowerShell7 backup/hash helper into the existing `_classic_beta_/Interface/AddOns/AzerothKart`.
No forced rollback, deletion, other-addon/WTF access or client automation.

Installer reported Verified; independent readback confirms all70source files
match installed bytes and manifest SHA256. All68prior files exactly match the
verified backup. The harmless unreferenced legacy GoblinDragCar.tga remains
unchanged as the single extra target file. Installed Menu no longer contains
the identical-handling sentence; it has the current profile description control,
and installed Physics is11. This verifies files, not an already-running UI.

Manifest: ignored `local-artifacts/deploy-20261025-auto-scores/backups/
20261025-160602-790-5d1f7ee188514b838bf6caeeaeb82490/install.json`.
Independent receipt: `local-artifacts/deploy-20261025-auto-scores/receipt.json`.
Package built from the70tested installed paths, then every ZIP entry rehashed:
`../AzerothKart-AutomaticScores-6b4dc16.zip`,50,964,109bytes,
SHA256`3F125C691C2157EBC8B38643ACD97AFF9151E8BC3B80BE53EB4561F2D112952C`.
It contains only addon files, not backup data or player files.

Other worktrees/HEADs/untracked work remain preserved. No push, release or
native acceptance claimed. **Next:** fully exit/restart both updated clients
(3newLua files), enter the world normally, and observe Highscores during an
ordinary completed race. No manual result exchange/extra software/probe series.
Native roster population, actual latency and capacity remain NOT RUN; the UI
reports waiting/connected/capacity state instead of assuming delivery.

## 2026-10-25 16:03 +01:00 — automatic score delivery/notifications integrated

Owner requested the automatic discovery/whisper synchronization, visible
notifications and correction of installed garage copy. Own
`codex/automatic-score-sync` from `1c029f8`, reservation before edits. Installed
readback confirmed the old Menu sentence and Physics10; the newer profile
descriptions/Physics11 were committed but had not been installed.

Implemented ScoreDiscovery, ScoreSync and ScoreSharing, loaded in both33module
TOCs before UI/Menu. Cached/event-fed roster discovery uses display indices and
retains full names without native selection changes. The automatic adapter joins
its dedicated channel, performs compatible HELLO/digest catch-up and sends
priority new personal bests through logged WHISPER. Lost rows reconcile later;
local accepted sends are not delivery ACKs. Personal and community save children
remain independent. Root/child replacement, future/malformed schemas and valid
in-place changes are preserved and stop community writes/traffic.

Successful once-latched solo Finish saves first, then queues sharing under pcall.
Top10/top3 entry and a move to first place produce one known-shared-score chat/
result notice. Receive, replay, catch-up and reload do not congratulate again.
Menu refreshes only an already-visible board, reusing all rows/result labels.
The board reports actual discovery/connection/capacity status. One background
frame is added; UI pool stays86/167/135, with Core and receiver2fixed extra frames.
All karts still share a board with no kart column/filter.

Scores yield to combat/chat restrictions/another Core lease, wait2idle seconds,
and attempt at most1send/s and158prefix+payload bytes. Registration failures
back off30seconds, send failures back off after bounded attempts. Peer admission
is capped32; excess roster clears stale connections and reports the test limit.
Unrelated messages are rejected before cache parsing, idle polls use cheap
save guards, and rate rejection precedes expensive dirty-write validation.

**Executed:** actual Lua5.1 via pinned local Lupa. Final combined
`scripts/test_lua.py --runtime lua51 --tests score_sync score_discovery
score_sharing menu solo_records multiplayer_integration` PASS,74Lua files
parsed/all6modules. Final score_sharing-only rerun PASS after registration retry
and native channel-lookup coverage. Earlier UI-only check PASS. The first
Menu run caught the deliberately added receiver outside UI's pool; accounting
now explicitly includes both fixed bootstrap/receiver frames, with no allocation
assertion removed. Individual focused agent checks passed too.

Mocked clients automatically join/discover/connect; a valid saved finish reaches
the other board within2simulated seconds. Coverage includes UTF8 names, priority
publication during handshake/catch-up, lost-row recovery, quiet fresh-namespace
reload, third-client catch-up, actual rank12→10→3→1 notices, visible menu refresh,
lease/reentry/pacing guards, native API failures and protected saves. Independent
source review found capacity handling, a handshake race and cache parsing work;
all were fixed with regressions before this checkpoint. This is offline evidence.

`git diff --check` PASS. Structural validator still FAILS only on the same2
historical expired skill links. Installer WhatIf under cached PowerShell7 PASS.
Quota interrupted the prior attempt before its pending patch executed; work
resumed from disk and that patch was applied normally once execution returned.
No native tests/client input/server change or push performed. Native roster
population, real delivery latency, cross-faction/scale and persistence remain
NOT RUN. No milestone acceptance is changed.

[Current player flow and limits](AUTOMATIC_SCORES.md). Source is ready for the
requested combined backup/install/hash verification; deployment result follows.
Other worktrees remain at Claude`0afeedf`/canonical`5570968` with their existing
untracked files preserved. **Next single task:** verify the installed update
after a full client restart during ordinary play, rather than manual score
exchange or repeated transport probes. Pending native discovery is shown honestly.

## 2026-10-25 12:56 +01:00 — balanced/heavy/agile kart handling

Owner approved modest kart attributes and explicitly keeps one shared
leaderboard without kart columns or filters. Own `codex/kart-handling` from
`81ef556`; reservation preceded edits. [ADR 0019](adr/0019-balanced-kart-handling.md),
[parameters/metrics](PHYSICS.md#implemented-kart-profiles--physics11),
[run-latching contract](API_CONTRACTS.md#implemented-kart-handling--physics11).

Physics11 adds private balanced/heavy/agile profiles. Balanced retains the
previous baseline. Heavy trades launch/turning response for2%cruising speed
and stronger brakes; agile trades2%cruising speed/braking for quicker launch
and tighter turns. Mapping covers all10karts; Pod Racer stays balanced in this
first pass. Reverse55, boost260, drift charging/rewards, shared17×31body and
90%wall retention/80%profile-speed scraping rules remain. No collision mass,
damage or functional tankyness was added.

`Physics.GetHandling` returns copied data; step takes an optional kart-ID string.
Solo Start captures it once; a future stopped choice affects only the next run.
SessionTransport passes RaceGrid's agreed local ID through RaceStart's optional
context/bundle into LiveRace's private state. Unknown IDs refuse/fail initialization;
nil/basic preserve balanced internal callers. Authoritative state remains15fields
and the live speed envelope/wire format is unchanged. Physics11 negotiation
rejects old peers and uses new compatible score keys; historical saved scores
remain intact. No leaderboard column/filter/store-key change per kart.

Menu reuses its existing green description text for the actual selected
profile. No new widget, asset, track or camera change. UI still refuses active
kart changes. The once-latched ID survives an unrelated display-ID mutation
and sprite fallback. Stale cosmetic-only copy and public API docs are aligned.
The deferred server catalogue/example now use7actual Physics11contexts.

**Executed:** actual Lua5.1 via pinned local Lupa:

- `scripts/test_lua.py --runtime lua51 --tests kart_handling physics drift
  wall_slide surface steering ui menu race_start live_race session_transport
  multiplayer_integration solo_records`:68Lua files parsed; first6modules PASS,
  then UI stopped on its synthetic unregistered `single_image` fixture. That
  fixture now uses the registered balanced `basic` identity with the exact same
  synthetic art, retaining all rotation/fallback assertions and strict unknown-ID
  refusal. No production guard was relaxed.
- `scripts/test_lua.py --runtime lua51 --tests ui menu race_start live_race
  session_transport multiplayer_integration solo_records`: all7remaining modules
  PASS after that fixture correction. Explicit UI pool remains86/167/135.
  Agents' earlier focused handling/backend runs also passed; these are not
  native-client observations.
- Handling metrics balanced/heavy/agile:0–100 in39/41/38ticks;2,000units in
  639/629/649ticks; braking47/45/48ticks; full-cruise turning radius
  76.923/81.731/72.485units. All reach tier2 on the60tick Test Oval opening
  drift with0impacts. Each profile replays all15fields exactly for10,000seeded
  ticks at30/60/144FPS. These bound tradeoffs, not human/per-track balance.
- `scripts/export_score_catalog.py` and `--check`: PASS7canonical contexts.
  Actual synthetic operator CLI submit/query in separate processes: PASS on
  new Physics11board. SQLite artifacts remain ignored; no real player data used.
- `scripts/validate_project.py`: FAIL only on the same2historical expired skill
  links. `git diff --check`: PASS. Independent source review found no blocker.

Native handling, picker layout and competitive lap balance are **NOT RUN**;
full Lua5.4/broad suite deferred under the focused build-first policy. Existing
automatic community transport/discovery remains open. No install, push, native
traffic, SavedVariables migration or other-worktree change. Claude remains at
`0afeedf` with existing untracked outputs; canonical checkout remains`5570968`
with its existing untracked handoffs. No roadmap acceptance box changed.

**Next single executable task:** resume bounded channel-roster discovery/readout
for automatic community score exchange. The handling build is committed for
review/deployment; actual feel can be tuned after an installed client drive.

## 2026-10-25 10:56 +01:00 — automatic community ranking foundation

Owner clarified addon-only automatic sharing, prompt updates and top-3/top-10
congratulations; manual result exchange is not acceptable. Selected that
direction in [ADR 0018](adr/0018-automatic-community-scores.md), superseding the
disconnected central store as the active path. Python storage is preserved but
deferred; no uploader or permanently logged-in character is required or enabled.
Own `codex/community-scores` from `7595d0b`, with prior scope reservation in the
Codex handoff. Claude's checkout remains at `0afeedf` with its existing untracked
outputs; the canonical checkout remains at `5570968` with its existing handoffs.

Implemented additive pure `Highscores.Merge`, `Rank` and `FinishPlacement`.
Whole batches validate before mutation. Canonical per-player minima and bounded
top-50 unions converge for a fixed admitted context despite duplicates, reorder
or differently grouped catch-up. Equal-time shared records use earliest date
and stable byte tie-breaks; local Submit still preserves its original equal-time
record. Explicit byte ordering also removes locale dependence from tied names.
Placement assessment identifies top-10/top-3 entry for an exact retained
improved local finish. It is pure: the future integration must use the existing
once-only finish latch and never notify from receive, catch-up or redraw.

**Executed:** `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests
highscores community_scores solo_records`, using the pinned local Lupa path:
**PASS**, 67 Lua files parsed and all three focused modules executed. Coverage
includes bounded union convergence/truncation, canonical Unicode/name/kart ties,
retries, atomic invalid batches, detached values, future-save preservation,
context/capacity isolation, unchanged local equal-time semantics and placement
thresholds. Independent read-only review found no blocker within this scope.
`git diff --check` PASS. `scripts/validate_project.py` still FAILS only on the two
historical expired computer-use skill links in this log; no new structural
failure was reported. Full Lua 5.4/broad suite, native sharing, persistence and
visible congratulations are **NOT RUN**. No WoW process was found on this run.

Source investigation does not establish a channel fix. Upstream TrinityCore
[chat routing](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Handlers/ChatHandler.cpp)
and [channel delivery](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Chat/Channels/Channel.cpp)
preserve logged CHANNEL messages; actual AnoCore handler code/logs are unavailable.
The previous channel payload used `1|H|...`, unlike the plain-text whisper
control. This is an unisolated variable, not evidence of a markup bug; do not
change transport/filter semantics speculatively. The failed receipt gate remains.

An alternative discovery candidate is the dedicated channel's native roster,
followed by the verified logged-WHISPER route. The retained Blizzard source uses
`GetNumDisplayChannels`, `GetChannelDisplayInfo(displayIndex)` and
`C_ChatInfo.GetChannelRosterInfo(displayIndex, rosterIndex)`, with asynchronous
`CHANNEL_ROSTER_UPDATE`. Display indices are not local send-channel IDs.
Cached roster availability, full Forever names and non-invasive refresh still
need native evidence. No channel join, client input, messages, install, push,
server change or new friend test was performed/requested.

**Still incomplete:** automatic discovery/delivery, publication/catch-up
controller, separate community persistence, UI refresh and actual congratulations.
The installed board remains local. No global completeness, near-instant measured
delivery, multiplayer capacity or milestone completion is claimed.
**Next single task:** implement bounded channel-roster discovery/readout using
the existing diagnostic boundary, preserving native chat selection and full
names; inspect its result when a client is available before enabling shared
delivery. Automatic peer exchange must share Core's existing network budget.

## 2026-10-24 20:54 +02:00 — central persistence built; live bridge remains open

Owner approved the central persistent leaderboard direction. Own clean
`codex/central-score-store` fromed52ce4; new server-side source/CLI/catalogue/
example, focused Python tests and aligned docs. [ADR0017](adr/0017-central-score-store.md),
[component/usage](../services/leaderboard/README.md). Implemented atomic strictly-
better submit, full personal-best retention, consistent bounded query pages,
ASCII identity rules/full UTF8 names, compatibility allowlist and application/
schema/deployment safeguards, including changes after opening. No migration,
native adapter, public endpoint or in-game global claim. Catalogue is generated
from7actual Lua course/record contexts; the CLI is an operator tool, not auth.

**Executed:** Python3.14 `-W error::ResourceWarning -m unittest discover -s tests
-p test_leaderboard_store.py -v` **PASS13tests**: persistence/retry/order/names,
identity/inputs/catalogue, >50players/paging, COMMIT-denied rollback, concurrent
writers, unknown/future/live-changed schema/deployment refusal. Initial attempt
failed due inaccessible default AppContainer temp paths; tests now use resolved
and containment-checked ignored workspace temp paths, then passed. Actual five-
process CLI smoke PASS: synthetic submit, replay, reopened query and duplicate-
JSON/wrong-deployment refusal without DB mutation. Catalogue --check PASS7;
changed Python syntax PASS. Raw blob/file audit initially flagged existing
TOC CRLF normalization; Git-filtered runtime source/file-set check PASS.
No new Lua/native/global checks run. Validator still reports two historical
expired skill links. No actual game SavedVariables data used.

Primary642-generated-file70450API plus Camelot-callers audit found no generic
HTTP/custom RPC/remote addon-store endpoint; not exhaustive70532runtime absence
proof, but no supported route to wire. Empty RPC constants, purchases, fixed
browser targets and game-specific leader APIs do not provide one. No hidden
server, listener, account/secret, uploader, native workaround or dead menu was
added. All addon runtime files remain unchanged; no install/push/release/server
configuration or other-worktree changes. No milestone completed.

Owner's addon-only versus desktop-uploader constraint remains pending; no
dependent adapter chosen. **Global publication remains INCOMPLETE.** Next exact
task: resolve that constraint and implement the actual supported client/server
bridge. Keep local records usable; no more friend packet probes requested.

## 2026-10-24 20:18 +02:00 — score prefix reached receiver; channel integration remains blocked

Owner supplied both control screenshots. Recipient completed its score window:
CHANNEL_LOGGED,3sends/accepted3,channel6/native0/build70532,membership_preserved,
selfEcho0/peerHello0/peerACK0. Crucially, matching-prefix incoming metadata now
shows **WHISPER/localID0/nameunavailable/rejected=event_fields**. This is an
expected non-CHANNEL rejection after receipt, not a bug. At least one AZKSCP1
event reached the actual receiver; local prefix/event/Core forwarding works on
that recipient. Sender shows several accepted manual invocations; no received
count/sequence/RTT/reverse-new-prefix evidence, so no complete-delivery claim.
[Evidence and actionable server handoff](evidence/2026-10-24-score-prefix-whisper-control.md).

Continued clean `codex/whisper-control-evidence` fromd918b49. Reserved new
evidence, prior AKW001 note status, SCORE_CHANNEL/FEASIBILITY/PROGRESS/handoff
only. No runtime, server/config/GM, packet-budget, other-worktree or installed
file change; no new native traffic/computer input/suite rerun by Codex. The
positive is owner-executed. Documentation diff/link checks only; two historical
expired skill links remain the known structural-validator failures. No push,
install, release or milestone completion.

Both whisper controls are now narrow positives; do not repeat them or relax
the score receiver. Shared membership, server recipient-prefix state, channel
target mapping/fanout and public Forever scope remain unverified. Actual
AnoCore handler source/effective runtime state were unavailable; upstream
TrinityCore's recipient-prefix filter is a comparison, not a verified cause.
Global publishing remains disabled. Next exact task: inspect those server-side
paths using actual source/observability, then retest only after an identified
fix or when the public Forever route is available. Stop repeated friend trials.

## 2026-10-24 — AKW001 private whisper control passed; global channel still gated

Owner supplied both private-server native reports. Sender4DATAcalls/accepted4,
listener4unique receipts/ACKcalls/accepted4, sender4matched ACKs. Bothwindow_complete;
no reported reject/duplicate/reorder/throttle/error/timeout/late/outstanding.
Planned5 includes sender missedSlots1, an unattempted opportunity rather than
network loss. Payload64/prefix28bytes per endpoint. Sender RTTn4,p50162ms,
p95/p99/max292ms; listener gapsn3,p501946ms,p95/p99/max2211ms. No exact sequence
maps, build/interface or captureUTC supplied in these reports. Two ledger rows
retain those unknowns. [Evidence and limits](evidence/2026-10-24-akw001-private-whisper-control.md).

Own clean `codex/whisper-control-evidence` from1e480db, scope: new evidence,
network ledger, SCORE_CHANNEL/FEASIBILITY/PROGRESS/Codex handoff. No runtime,
packet budget, art, server/config or other-worktree changes. No repeated Lua
tests or new native traffic by Codex; validation is documentary/CSV structural.
Owner subsequently reports both characters' UnitFactionGroup returnsHorde/Horde.
Local AZKSCP1 prefix query returnedtrue but ListChannelByName printed no roster;
endpoint scope of that last reply is not separately attested. Do not treat no
roster output as an empty or shared roster. General logged receive works with
AZKART1; global/new-prefix CHANNEL delivery still has no proof.

Primary upstreamTrinityCore comparison found server-side recipient prefix
filtering for channel fanout, a distinction from whispers. This is not actual
AnoCore handler verification. Local registered=true need not prove the server's
registration state. No evidence-backed codec bug was found; no speculative
delimiter change or ordinary/unlogged fallback was introduced. No push/install/
release/milestone completion. Public Forever behavior remains separate.

Next exact task: one plain-ASCII directed logged WHISPER underAZKSCP1 while
the recipient's existing score check is active, inspecting its matching-event
metadata. This new-prefix control is NOT RUN, needs no package and awards no
score. Do not rerun AKW001 or escalate throughput; review that narrow result
before further channel work or selecting a shared distribution architecture.

## 2026-10-24 19:48 +02:00 — both score-channel reports have no observed receipt

Owner supplied two client screenshots for the installed score-channel check.
Both stopped/check_complete; sent3/accepted3, selfEcho0,peerHello0,peerACK0;
CHANNEL_LOGGED/channel6/native0/build70532/membership_preserved. Neither shows
matching-event metadata. [Transcribed evidence, limits and next control](evidence/2026-10-24-score-channel-no-receipts.md).
Reciprocal receipt gate NOT MET in this private-server window. No inferred
packet-loss percentage, public Forever verdict, milestone completion or global
publishing claim. Exact overlap, zone/faction and callback delivery are unmeasured.

Own clean branch `codex/score-channel-receipts` from2ae3f7a. Reserved evidence
note/SCORE_CHANNEL/FEASIBILITY/PROGRESS/Codex handoff only. Read-only source/API
review found no clear bootstrap/filter bug: eventCount is recorded before
route/localID/name/payload checks; both screenshots lack that diagnostic line.
The local AnoCore pack advertises70532 and its template AddonChannel=1; that
does not prove running configuration/handler support. No server source handler
was available. No code/runtime changes, new native traffic, computer input,
repeated Lua suite, server/config/GM changes, installation, push or release.

Installed readback **matches all67tested77a1891source files**, plus one
unreferenced legacy GoblinDragCar.tga from the overlay copy. Preserved that
extra file. No other addon or WTF/SavedVariables access/write. Claude's branch
and outputs remain intact. Documentation diff/link checks accompany the record;
the two historical expired skill links remain a known validator failure.

Next exact task: one short existing logged-WHISPER positive control between
the same two private clients, 0.5DATA/s/16bytes/10second send plus10second drain;
then both net reports. It needs no new package and is **NOT RUN**. If positive,
discriminate CHANNEL/new-prefix behavior; if no incoming messages, investigate
private server addon-message handling before further channel checks. Keep
global publication off and do not substitute an unverified architecture.

## 2026-10-24 18:44 +02:00 — approved/published Claude visuals; combined score-check package

Owner requested latest Claude review/push plus second-client steps. Read the
canonical Claude handoff and complete0afeedf/de4b291 diff. Runtime, pipeline,
provenance and generated preview review found no blocker. Own branch
`codex/podracer-score-review` from98b3ce2, reservationde229b7; reviewed merge
**77a1891** preserves both agents' work. Sole merge conflict: test_menu pool
assertion resolved additively to measured86frames/167textures/135fonts.
Highscores/menu version guards, score eligibility, control, both TOCs, all
network modules, Physics10 and geometry remain intact. Existing
goblin_drag_car save/wire ID now displays the Pod Racer. Original authored
Claude branch0afeedf remains unchanged. WoW art source use accepted for the
requested project asset; Blizzard redistribution remains unresolved for release.

Executed `scripts/test_lua.py --runtime lua51 --tests presentation ui menu
highscores solo_records score_channel_probe multiplayer_integration`:
**PASS7modules/66parsed**. `scripts/build_kart_outlines.py --check`: **PASS10**
exact rebuilds. Read-only changed-Python syntax and TGA format/size checks
PASS. `scripts/validate_project.py` FAIL only two known historical expired
skill links; `git diff --check` PASS. No full source-model/city rebuild,
Lua5.4, native art/performance or second-client transport check run. No
milestone/release gate marked complete.

Authorized atomic Git push succeeded; fresh remote readback matches exact
`claude/podracer-arrows-outline`**0afeedf8f185d4c4a2f5eeee434540e54b361e1f**
and initial combined `codex/podracer-score-review`
**77a18912a028db249cc4e45be1df597e2ecad879**. Following documentation updates
change no runtime files and are pushed to the same combined feature branch.
Main, both foreign worktrees' branch/HEAD/status/400hashes and installed54files
remain unchanged. No native input, install, forced push, tag or release.

Prepared `AzerothKart-ScoreChannel-77a1891.zip` in the project-pack directory:
67runtime files,50,949,416bytes, SHA256
`99145cdf76689f363a061afb36885496a286a932aa4c9c92d7277d907305543c`.
Verified CRC, exact archive path set, every decompressed member against source
and both TOC lists. Contains the new art, local scores and channel probe; no
development/private data or retired drag sprite. **Not installed**; existing
install remains d3fd99d. Receipts under ignored
`local-artifacts/podracer-score-review-20261024/`.

[Review](reviews/2026-10-24-podracer-score-integration.md) and
[simple two-client setup/check](SCORE_CHANNEL.md) are updated. Next exact task:
load this same ZIP on two consenting clients, fully restart, then both run
`/akart scores check` within five seconds. After30s collect both terminal
reports. Global publication stays off pending reciprocal receipt; no inference
of public Forever delivery from the private-server acceptance-only result.

## 2026-10-24 18:34 +02:00 (Europe/Oslo) — resume and finalize saved route checkpoint

Confirmed clean `codex/score-channel-route` at implementation/evidence commit
**317ace6**. The previous quota failure prevented only the final documentation
reference update; the source, tests and native observations were already
committed. Recorded that reference in the Codex handoff. Claude remains at
`claude/podracer-arrows-outline`0afeedf with its existing untracked outputs;
its checkout was not edited. No new runtime changes, test reruns, client input,
installation, publishing or milestone acceptance. The executed results below
remain the evidence. Next task remains reciprocal logged CHANNEL receipt with
two consenting clients; the owner last reported none available.

## 2026-10-24 00:34 +02:00 (Europe/Oslo) — score-channel candidate; private native acceptance

Owner explicitly requests establishing the shared publication route. Continued
on own `codex/score-channel-route`, base30ab625; no milestone completed.
Selected a dedicated logged CHANNEL candidate with eventual community caches,
documented in [SCORE_CHANNEL](SCORE_CHANNEL.md). This is not a complete central
board or a verified public-server transport. Source70450 plus installed Chomp
provided primary API/implementation references; source declarations alone did
not establish Forever delivery. The earlier UI inventory attempt hit an
approval-review quota failure and executed nothing; resumed after the owner
opened the game on October24.

Implemented `ScoreChannelProbe`: deliberate `/akart scores check|report|stop`,
30-second finite window, eight-second join limit, three HELLOs/up to three peer
ACKs, six-send ceiling and two-second minimum send spacing. Uses the existing
exclusive Core lease, preserves prior membership, leaves its own join, stops on
native refusal/lifecycle/drive/clock problems, and never sends scores or writes
SavedVariables. Reentrant native cancellation cannot reacquire/overwrite
another transport's callbacks; fractional/protected enums refuse startup.
Bounded first-event metadata prevents silent loss of diagnostic context when
the native event shape differs. Core forwarding, TOCs/load lists and focused
regressions updated; no Menu/UI behavior, art, geometry or Physics10 change.

**Executed native check:** owner says public Forever beta is closed until
November4, and authorized the currently open private AnoCore server instead.
Desktop inventory resolved its client to the existing `_classic_beta_/WowB.exe`.
GetBuildInfo returned1.60.1/70532/interface16001; required API functions exist.
Owner personally accepted WoW's custom-script prompt. Verified UI/probe/session
inactive, then used a temporary one-packet API receiver rather than install or
restart the addon. Prefix registration0; dedicated channel ID6; logged CHANNEL
pcall returned true,0; native Success0/InvalidChatType4. Matching logged receipt
count remained0. Timed/explicit cleanup removed the handler and joined channel;
final lookup0,nil,0,false. No ordinary chat send, score upload, movement input,
other-addon change or filesystem persistence. Exact scope/results in the guide.
This proves native call acceptance only, not delivery, loss, peer reach or
public Forever behavior. The new module itself has not been run natively.

**Executed offline:** actual Lua5.1 `scripts/test_lua.py --runtime lua51 --tests
score_channel_probe` PASS (including follow-up cancellation/enum regressions);
`--tests ui menu multiplayer_integration` PASS3modules. 66Lua files parsed.
Core retains all nine native event arguments; startup has no new network work;
explicit UI pool stays85/166/133. `git diff --check` PASS after removing added
trailing blank lines. `scripts/validate_project.py` FAIL only the two known
historical expired computer-use skill links in this ledger. No broad suite,
second client, score exchange/persistence or public-server check was run.

**Parallel/deployment audit:** original checkout5570968 and installed54files
still match the baseline. The overnight foreign-checkout comparison detected
Claude's own new branch `claude/podracer-arrows-outline` at0afeedf, three commits
over de4b291. Read its updated handoff and left its branch, files and untracked
outputs untouched; this is not a preservation PASS against its older e83c889
snapshot. No automatic integration, push, install, ZIP or release.

Owner confirms no second client is available and asks to save the checkpoint.
Global publication remains **INCOMPLETE**. Next exact task: reciprocal receipt
with two consenting clients using the short score-channel check; public
Forever scope must be verified separately when available. Proceed to bounded
score synchronization only after that evidence, preserving versioned boards
and self-reported/incomplete-cache labeling.

## 2026-10-23 15:52 +02:00 (Europe/Oslo) — solo totals and saved Highscores; global route open

Latest owner direction: happy with handling; finish single player before more
multiplayer tests, saving full finish total/name/date and publishing a global
board. The owner delegates the efficient reliable architecture choice. Own
clean `codex/solo-highscores` from `de4b291`, reservation `18d5eb6`. This is the
next M3 persistence slice; no milestone completion or multiplayer acceptance.
[ADR0016](adr/0016-solo-records-and-global-score-gate.md) records the current
priority and [HIGHSCORES](HIGHSCORES.md) the exact implemented scope/dependency.
Runtime committed **f50fa7c**; subsequent handoff-only commit changes no addon
files. Source is local and is not the currently installed candidate.

Implemented pure bounded `Highscores` and native `SoloRecords`, loaded before
UI in both TOCs (29modules). Completed solo three-lap races save exact total
ticks, full Forever name, finish timestamp and compatibility metadata. Personal
bests are partitioned by track/version/Physics10/laps/60Hz/scoring rules; cosmetic
karts share a board. Equal/slower runs retain the earlier best/date. Bounds:
32boards,50bestplayers/board, no unbounded run/ghost history. Root schema and
preferences/custom fields preserved; malformed/future data refuses writes.
Checks repeat after native callbacks to protect concurrent root/child changes.

UI creates one token only on accepted Start, submits once at actual solo finish
and freezes before callback. Close/reopen/Stop/combat/partial/live runs cannot
award records. A saving exception leaves results and control release usable.
Genuine lost running-time ticks exclude the score; discarded post-finish frame
remainder does not. Native full-name APIs preserve Forever first+surname, with
no realm inference; guarded GetServerTime/date UTC reads remain new/unverified
in this addon. Missing identity/date yields an explicit saving refusal.

Narrow supporting menu integration adds reachable Highscores (home entry6),
track browsing without changing selected geometry, ten pooled rows/pages,
name/total/UTCdate and saved-result notice. Six frames/52fonts added; measured
explicit pool **85/166/133**, textures unchanged. Resultsheight336 separates
the saving note. Preferences now also recheck root/current child versions at
write time. Physics10, rendering primitives, art, geometry and multiplayer
transport source are unchanged; Claude's worktree/handoff were not edited and
no direct acknowledgment is claimed.

Executed actual `python scripts/test_lua.py --runtime lua51 --tests highscores
solo_records ui menu race loop multiplayer_integration`: **PASS7modules,
64Lua files parsed**. Includes bounded schema/ranking/UTF8, full-name/date,
native callback write races/reentry, exactly-once capture, terminal remainder vs
earlier hitch, stopped/live exclusions, menu pages/readonly/empty/tail clearing,
no per-tick score reads/allocations and two delayed mocked peers. Initial
integration checks exposed old hardcoded79/166/81 and312height assertions; these
were updated to the measured new pool/336height, then the seven-module run
passed. Fullsuite/Lua5.4/native new layout/date/persistence/globaldelivery:
**NOT RUN**, respecting focused validation. `git diff --check` PASS.
`python scripts/validate_project.py` **FAIL only the same two pre-existing
expired computer-use skill links in historical PROGRESS**; current module/load
order and added documentation produce no additional validator findings.

Source audit: both foreign branches/HEADs/statuses and377tracked/untracked file
hashes preserved; installed54files remain exactly the prior `d3fd99d` runtime.
Ignored evidence `local-artifacts/solo-highscores-20261023/{baseline,preservation}.json`.
No installation, ZIP, push, release, client input, other addon or WTF/SavedVariables
file writes occurred. Test builds need explicit install coordination and full
restart for the two new Lua files.

**Open global dependency:** local records are not global publication. Audits of
current transport/IOU/build70450 source found no implemented/verified all-player
endpoint, uploader or addon broadcast route. Only named-peer logged WHISPER has
client evidence; generic chat API declarations do not establish global/offline
delivery. No score traffic/service/hidden companion was enabled. Scores remain
client-reported, without server/anti-cheat guarantees. Native score persistence
and appearance checks are also pending; owner handling approval is not those
checks. The requested global scope remains incomplete and flagged for review.

Next exact task: establish a supported persistent global publication/query route
with Forever capability evidence before wiring score distribution. A shared
community cache must be explicitly described as eventual/incomplete, not a
complete all-player board. Further live-race tests remain deferred by the owner.

## 2026-10-23 15:00 +02:00 (Europe/Oslo) — requested10%/80% penalty and latest Undercity

Owner found5%/95% too mild and explicitly requests10% initial wall loss,80% scraping top speed, plus pushing Claude's latest Undercity. Own clean codex/wall-penalty-10 from455d233, reservationd96557f. Tuning **c70c8b8** separates initial retention0.90 from contact maximum0.80 (160forward/44reverse). At high speed the cap also limits the first hit; below it the10% initial loss is tested independently. No repeated percentage decay; drag40units/s², active steering, parking turns, geometry and15state fields retained. Physics10 rejects7/8/9 before live GO.

Actual Lua5.1 `scripts/test_lua.py --runtime lua51 --tests wall_slide physics drift session_transport` **PASSfourmodules/60parsedfiles**: shallow below-cap hit, exact160top contact, reverse44bound, immediate cap release, deterministic replay and prior-version refusal.30tick45degree tape now160speed/54.438travel; frontal escape remains53ticks, stationary1.823rad/60ticks unchanged. Tests ran before the image-only merge; all runtimeLua/testLua remain identical afterward. Fullsuite/Lua5.4/native newfeel NOT RUN for this narrow tuning. Whitespace PASS; validator FAIL only the same two historical expired local skill links.

[Claude lighting review approved](reviews/2026-10-23-undercity-lighting.md) exact **e83c8895c3d8032a7cdf941915e5ff99971d5f52** (f0810ca/e83c889 over reviewedee144b5). Before/after camera sheets show readable roads/bridges with darker/cooler scenery and light pools. PythonAST/TGA format/dimension/length/hash/scope checks PASS. Runtime art changes only Undercity Background/Preview; no Lua/geometry/native or new imported assets. Full art rebuild/client look/load/FPS NOT RUN; Claude's two-machine rebuilds are attributed evidence. WindowsGit normal fast-forward dry-run/push **succeeded**, remoteclaude/undercity-river exactlye83c889, mainunchangedf923d15. Clean two-parent merge **d3fd99d1d154d45f4d882c9f8cd6759a5944de28** combines it with currentPhysics10. Later Codex tuning branch remains local, no main merge/release.

Installed combined runtime **d3fd99d**,54files exact source/target/manifest/ZIP,54priorfiles verified against58925eb baseline/before.csv. Existing helper WhatIf and actual backup/hash install PASS. Manifest `local-artifacts/wall-penalty-10-20261023/backups/20261023-145931-919-febd065f4ce44ece99686fb7d193219f/install.json`. ZIP from actual installed folder: `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-d3fd99d.zip`,49,601,326bytes, SHA256 **56b8fe1c43401c7158bce19e5a3fd733ef6f4c26b4db91c214e292605fa3f1ce**; CRC/path/hash checks PASS, source/target unchanged during packaging and oldZIPs preserved. Four runtime files differ;50unchanged. All377foreignfile hashes/HEADs/branches/statuses preserved; no foreign checkout/authoredhandoff edits or otheraddon/WTF/SavedVariables/clientinput writes. Ignored evidence under `local-artifacts/wall-penalty-10-20261023/` includes push/live refs, focus log, baseline/preservation, install/deployment receipts. Following handoff commit is docs only.

**Next exact task:** owner fully restarts WoW for the changed Undercity textures, then judges a wall scrape with the requested stronger penalty. Both friends need this Physics10 package for their next race. No new network probe; native tuning/appearance and broader release gates stay pending.

## 2026-10-23 14:44 +02:00 (Europe/Oslo) — slight wall penalty

Owner reports Physics8 feels nearly penalty-free and requests a very slight slowdown. Own clean `codex/wall-penalty` fromdc52148, reservation07ec5a2, implementation **58925eb08095f7a227ee96fcbc8f9bf68922856b**. Added a5% loss on first contact plus a95% normal-speed ceiling during contact (190forward/52.25reverse). Percentage loss never compounds per tick; existing40units/s² scrape drag, held steering, parking assist, wall geometry and all15state fields stay unchanged. The ceiling clears immediately away from the wall. Physics9 prevents mixed tuning; old7/8 peers are rejected before GO. No new gameplay scope or milestone acceptance.

Actual focused Lua5.1 `scripts/test_lua.py --runtime lua51 --tests wall_slide physics drift session_transport` **PASSfourmodules/60parsedfiles**, with shallow first-hit/sustained forward/reverse penalty, immediate ceiling release, no renewed sticking, deterministic cadence and old-peer refusal regressions. The45degree30tick tape now ends at189.934speed/travels58.327units (v8:197.005/60.744); frontal recovery remains53ticks and stationary turning1.823rad/60ticks. Read-only design review found no blocker. Whitespace PASS; structural validator FAIL only the same two historical expired local skill links. Broad/fullLua5.4/native handling checks NOT RUN for this small tuning. User's v8 feel is reported feedback, not measured live metrics.

Installed58925eb with existing PowerShell7 WhatIf/backup/hash workflow:54files exact source/installed/manifest/ZIP,54priorfiles independently verified againstdf21866 baseline/before.csv. Manifest `local-artifacts/wall-penalty-20261023/backups/20261023-144309-479-bad5857506594201b033234abc56d846/install.json`. Installed-folder friend ZIP `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-58925eb.zip`,47,241,206bytes, SHA256 **24e97807dc336d90e2372b8b7c9be5fc4e6bfc358452474e98b1172eeaaf4b88**; CRC/exactpaths/hash checks PASS, source/installed unchanged through packaging. OldZIP retained.52runtime files unchanged; onlyPhysics/addonreadme differ. All376foreignfile hashes/HEADs/branches/statuses preserved; no Claude/art/otheraddon/WTF/SavedVariables/clientinput edits. Ignored receipts/logs in `local-artifacts/wall-penalty-20261023/`. No push/release. Following commit changes docs only.

**Next exact task:** owner `/reload` and retry a wall brush; record whether the light penalty feels right. Both racers need this Physics9 build for the next friend race. No fullrestart is needed for this Lua-only follow-up, assuming the preceding city texture build was restarted.

## 2026-10-23 14:11 +02:00 (Europe/Oslo) — Claude river publication and wall handling v8

**Request and source:** owner asks to review/push Claude's latest, then fix sticky angled/side wall contact and slow stationary turning. Own `codex/wall-slide` starts505f054, reservation04db93e. Read canonical Claude handoff at **ee144b5d26fd8522ffdd3b1f7826151a049af074**, implementation48f571a plus evidence commits. [Review approved](reviews/2026-10-23-undercity-river.md): Undercityv2's six flat canal crossings/six gates/5,797-unit lap and wall-to-wall city paving; Ironforgev4 full grip changes only version/policy, preserving two narrows and all1,682wall vertices. Other three city definitions are identical. No UI/renderer/network rollback. The stale AGENTS rough-shoulder rule now records the reviewed policy. Decorative bridge humps remain art-only; no overpass/layer physics added.

**Publication actually executed before handling implementation:** Windows Git non-force dry-run and push published exact **ee144b5** to `origin/claude/undercity-river`; live remote SHA matches. Main remainsf923d15. Queried prior combined/city branch refs were absent, so the handoff's statement that Codex had already pushed that candidate is not treated as verified publication. Claude's authored handoff remains unchanged. Normal two-parent merge **feba3f8** integrates the approved branch into own work, preserving both histories. No main merge or later Physics-branch push/release.

**Handling implementation df2186697439b307055072be0a990137ce379660:** Physics8 replaces repeated75% speed loss and steering reset with first-contact loss proportional to permitted/attempted travel (capped1), then40units/s² continuous scrape drag while contact persists. Fully blocked movement stops. Held progressive steering survives; low-speed yaw adds up to1.2rad/s tapered to zero by80speed. Racing/drift90+ yaw,8/4/12steering ramps and drift thresholds/boost durations remain. Contact still clears drift/grace/boost/slip and release acceleration; no bounce, automatic heading alignment, new velocity fields or geometry changes. All15state fields, fixed1/60step and existing resolver signatures retained. Native compatibility automatically negotiates Physics8; explicit regression refuses v7 before grid/countdown/GO.

**Executed tests/evidence:** actual Lua5.1 through pinnedLupa2.8/WindowsPython3.14. Focused handling six-module, native session and UI checks PASS. Final single integration checkpoint `scripts/test_lua.py --runtime lua51` **PASS32test modules/60parsed Lua files**, including deterministic tapes, current native two-peer grid/GO/held inputs/peer art/pacing/cleanup, preference/selection and all geometry regressions. UI pool remains79frames/166textures/81fonts. New `test_wall_slide` covers sustained45degree/shallow contact, mirrors, reverse, no coasting speed gain, actual Oval solids/perimeters/Mirage/Stormwind, blocked frontal/corner stops, escape without reverse, stationary turning and all15fields across30/144FPS fixed-step delivery. The first test run corrected an unmeasured29-unit travel estimate to a25-unit lower bound (actual28.172); no implementation failure was hidden. Independent Physics review found no blocker.

**Measured comparison, same explicit offline tapes:** oldv7 versus newv8 city-style45degree contact over30ticks: travel **4.306→60.744units**, ending speed **0.861→197.005** with throttle. Frontal Oval crate contact with throttle+left releases at **53ticks** in v8; v7 does not release within60ticks. Its60-tick facing change is6.12→88.76degrees. Stationary left60ticks turns **39.44→104.45degrees**, with zero translation. Reproducible in-memory old/new script and JSON: ignored `local-artifacts/wall-slide-20261023/metrics.py`/`handling-metrics.json`. These are simulation metrics, not direct play, latency or FPS results. Scalar speed remains requested longitudinal speed, so remote forecasts may overestimate actual tangent travel during wall pressure; native feedback remains necessary.

**Other executed checks:** `scripts/build_city_tracks.py --wc3 . --geometry-only --check` PASS after merge. Review's two pipeline AST parses,10TGA format/dimension/alpha/hash checks and provenance comparison PASS; Claude's full two-machine image rebuilds/suites remain separately attributed author evidence. Whitespace PASS. Structural validator **FAIL only two pre-existing expired local skill links in historical PROGRESS**, not a pass. All27TOC modules and required new test path retained. Lua5.4/full art rebuild/native new city loading, tight bridge turns, handling, networking feel and performance **NOT RUN**. No milestone checkbox completed.

**Preservation:** both foreign worktrees' **376file hashes/HEADs/branches/statuses** match the new baseline (canonical5570968, Claude ee144b5 plus its pre-existing untracked outputs). Sixteen current rendering/geometry/native production modules and every asset match reviewedee144b5; only Physics and addon readme change in the runtime handling slice. Claude checkout is not switched/edited/reset; no direct Claude acknowledgment claimed. Source/contracts/own handoff coordinate the agents. Local code branch remains unpublished.

**Installed and packaged:** tested source **df21866** installed with existing PowerShell7 helper after WhatIf/preflight,54files. All54priorfiles match earliercac4290 receipt and independently verified backup/before.csv. Manifest `local-artifacts/wall-slide-20261023/backups/20261023-141009-111-f42c06aa0c944f65a9a4927419acab14/install.json` is Verified/BackupVerified=true. Tested source/current source/installed/manifest/ZIP exact54paths+SHA256, no extras or deletion, other-addon/WTF/SavedVariables/client-input writes. Installed-directory ZIP `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-df21866.zip`, **47,241,029bytes**, SHA256 **40884600082c3e0d04fce0ace33f2a9573a634a6a61d82aafeb24aeeab22b92a**. CRC/exactpaths/hash checks PASS; source/target unchanged through packaging, oldZIPs preserved. Logs/snapshots/push/metrics/install/deployment receipts are ignored under `local-artifacts/wall-slide-20261023/`. Following handoff commit changes docs only.

**Next exact task:** owner fully restarts WoW for revised city textures and drives one short wall-recovery check: angled throttle/steer-away scrape, then frontal contact with throttle+turn and stationary turning. Record actual feel before further tuning. Both friends need this exact Physics8 build for their next menu race; no separate network probe. Trusted results/contact authority, full socket recovery, slope/layer mechanics and production/release gates stay open.

## 2026-10-23 10:28 +02:00 (Europe/Oslo) — reviewed Claude two-city integration and install

**Authorization/source:** owner explicitly requests review of Claude’s recent work and integration if worthy. Read full canonical handoff at **91439490703c67ff7e90efbfc74e6eff8b66bc72** on claude/darnassus-undercity (implementatione96044b, evidence9143949), commonbase6ad66d1. Own clean codex/two-city-integration from1733eac, reservation381cb46. [Review APPROVED](reviews/2026-10-23-two-city-integration.md). Normal two-parent merge **cac4290dd8421457196a96985135511a96948431** preserves Claude9143949 and current multiplayer eb2055a. One README conflict resolved to retain newer multiplayer status and add new cities; Menu/API/validator/test lists auto-merged and their narrow unions reviewed. No main/foreign branch switch/reset/rewrite or push/release.

**Changes:** Darnassus Canopy Run (sixgates/3895-unitlap/206-unitapproach) and Undercity Slime Circuit (fivegates/7327-unitlap/spawnonloop/noapproach) plus four precomposed TGA files, previews/catalog/provenance and offline pipeline. Sevenavailable solo tracks/ten cosmetic karts; ThunderBluff remains comingsoon. Existingcity geometry/art retained. ADR0015 accepted only for painted levels and inert generated height arrays: Circuit ignores elevation, karts drive flat. Slopes/crests/bridges/kartheight remain proposals, not an adopted physical/replication design. Corrected inaccurate Darnassus shortest-city claim, stale counts and the proposal’s multiplayer-compatibility caveat. No new gameplay feature/milestone acceptance. Native multiplayer remains onlyMirage/TestOval, with full eb2055a grid/profile/countdown/peerart/prediction intact.

**Review/evidence:** independent read-only geometry/gates, art/pipeline/provenance and menu reviews found no blocker. Both panoramic visual review sheets inspected. Four new TGAs exact32-bitBGRA/uncompressedtype2/opaque255/bottomleft/dimensions+bytes; existing sixcityimageblobs and old definitions unchanged. Heights finite/aligned;931/1721boundaryvertices.29models/311placements/58textures and45/325/73 provenance match. Imported authoredClaudehandoff is unchanged. Claude’s reported two-machine dual-runtime/full-picture rebuilds are attributed evidence, not new Codex executions. Physical slopes would requirePhysicscompatibility review; bridge layer/route/replication remain undecided. Rights unresolved for release, as before.

**Actually executed:** C:/Python314/python.exe with pinnedLupa2.8/canonicaldependencies. Final `scripts/test_lua.py --runtime lua51 --tests circuit menu ui race_grid session_transport multiplayer_integration` **PASSsixmodules/59parsedfiles**. New menu regressions on both savedcityids verify deferred restoration/preview/inactive tickzero and false/throwing newbackground preservation of actual prior interruptedresult, vehicle/race/clock/laps/checkpoints, picture/crop/preferences/counts. Existing native/E2E gridcues/heldGO/peerart/pacing/cleanup retained; pool79/166/81. Isolated Claude-source circuit and gridpose/read-only-inertmetadata checks PASS; no citymultiplayer whitelist added. Agent focusedmenu PASS beforefinalcombinedrun. `scripts/build_city_tracks.py --wc3 . --geometry-only --check` **PASS** (completeLua, noartwrite). `tests/test_circuit_boundary.py -q` **PASS11tests**. ThreepipelinePythonASTparses and whitespace **PASS**. Structuralvalidator **FAILonlythetwo pre-existing expired local skill links in historicalPROGRESS**; no newerror,27moduleTOCs retained. FullLua5.4/repeatedbroadfullsuite/fullartrebuild/nativecityloading/look/drive/wall/performance/preferences and newmultiplayerfeel **NOT RUN**.

**Preservation:** PASS370foreignfilehashes/HEADs/branches/statuses (canonical5570968, Claude9143949 plus preexisting untracked outputs);46existingaddonfiles byte-identicaleb2055a. Only CapitalCities/Courses/Menu catalog/readme differ and fourartfiles added. All current simulation/input/collision/clock/network/UI/Presentation files and priorart retained; shared Menu/test changes combined rather than replacing newer files. Public contract/ownhandoff coordinate the agents; no direct Claude acknowledgment claimed.

**Installed combined developer build:** existing PowerShell7 helper WhatIf and actualbackup/overwrite/hashinstall **PASS54files**, source **cac4290**. Prior50installedfiles exactlymatch eb2055a receipt/before.csv and verified backup. Manifest `local-artifacts/two-city-integration-20261023/backups/20261023-102735-053-4fa3216003b74641bd0466db614bcfb2/install.json`; Verified/BackupVerifiedtrue. Independent source/installed/manifest/ZIP exact54paths+SHA256, noextras/deletion/WTF/SavedVariables/otheraddon/clientinput changes. New54-filecandidate includes bothcities and prior multiplayerfixes. Followinghandoffcommitchangesdocsonly.

**ZIP from actual installed folder:** `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-cac4290.zip`,54files/46,956,754bytes, SHA256 **3e1ba05309ccefc548050106c8d7654d66cc2d9a21738f3abb2d0e5d1885254d**. CRC/path/hashchecks PASS; source/installed trees unchanged through packaging; oldZIPs retained. Ignored receipts/logs/snapshots in `local-artifacts/two-city-integration-20261023/`, with baseline/preservation/install/deployment JSON and focused Lua/geometry/boundary/structural logs.

**Next exact task:** fully restart WoW and inspect/drive the two new solo city selections on this combined build using the existing short city checklist; record actual loading/feel before declaring city acceptance. The next friendrace uses this identical package and existing Multiplayer guide; no standalone netprobe requested. Slopes/bridges, inter-kartcontact, trustedfinish/authority, fullsocketrecovery and production gates remain open. Claude can branch from local codex/two-city-integration after checking its worktree; exact commands are in the Codex handoff. No publication is authorized by this integration alone.

## 2026-10-23 09:05 +02:00 (Europe/Oslo) — shared grid/countdown and selected peer karts

**Scope/evidence:** continue the owner’s first friend-race feedback, not a new roadmap milestone. [Evidence](evidence/2026-10-23-first-live-race.md) records both independent local three-lap finishes36.42/35.42seconds, GO-only startup, peer squares and reported lag/clipping. No quantitative latency/start skew or agreed placements inferred. Own codex/multiplayer-grid from6ad66d1, reservationf5e6918, implementation **eb2055a22034bc63d3bfe01538f097f4cbfab4ba**. Screenshots/names remain private.

**Implemented:** pure bounded RaceGrid profile agreement before Ready, immutable chosen kart IDs, matching native peer/session/channel guards and deterministic role slots36units apart. Live Start stages both sprites before GET READY→3→2→1→GO; reserved3000ms arming margin prevents abbreviated negotiation countdowns. No pre-GO Physics/Race stepping. Held controls carry through GO; staged Stop/Escape/chat/combat/world/close release capture. A prior finished solo result survives failed/prestage actions but is reset on first legitimate grid; grid abort cannot resurrect old laps/summary. Actual launch remains exactly once through the existing backend owner. Legacy coordination/solo unchanged.

**Presentation/transport:** exact40-byte AZKRUN2 STATE adds monotonic sampleMS and copied sampleAgeMS/elapsedMS. Both players must update; no mixed-version fallback. Agreed peer sprites reuse the existing opponent texture, neutral art tint and heading/rotation/pivot rules, with guarded primitive fallback. Removed the extra received-interval display buffer. Cached forecast caps500ms/31points, speed260/yaw2.6rad/s and stops at track walls/solids; sample age is an uncertain clock-mapping estimate, not measured one-way delay. Off-screen direction/distance is not placement. No extra native sender, packet rate or widgets:2Hz nominal,47payload+prefixB/pose (94B/s per peer,188pair), all four prefixes still share persistent0.5s/2calls/158B local budget. AZKGRD1 startup messages12+7bytes share that gate. UI pool remains79frames/166textures/81fonts. No inter-kart contact, authoritative correction/agreed winner, reconnect or production guarantee added.

**Executed verification:** actual Lua5.1/pinnedLupa2.8 via C:/Python314/python.exe and canonical local dependencies. Focused protocol/live/grid/clock, UI/menu, presentation and native/E2E runs passed. New negative clock test initially expected timeout but observed the intended earlier late cutoff; corrected assertion and rerun start_clock PASS. Final single integration checkpoint `scripts/test_lua.py --runtime lua51` **PASS31testmodules/59parsedLua files**. Complete all-TOC/Core/Menu/UI/native synthetic peers at700msRTT/5sclockoffset show both selected karts, GET READY and3/2/1 once each, zero preGOsteps/laps, held throttle afterGO and correct cleanup. Regressions cover profile loss/retry/gating, stale/foreign input, timestamp bounds, wall/solid forecast, role spawns, prior results,32sLeave, native failure and reentry. A final review fixed stale now after reentrant profile receipt before clock advance; no remaining source blocker found. Whitespace PASS. Structural validator **FAIL only the same two pre-existing expired local skill links in historical PROGRESS**; current27-module TOCs/new requiredpaths otherwise checked. Lua5.4/repeated broad matrices/full art rebuild/native revised UI, timing, traffic, FPS and feel **NOT RUN**. No acceptance checkbox changed.

**Preservation/coordination:**39critical core/art files byte-identical6ad66d1, including all assets and Physics/track/collision definitions. Canonical checkout remains unchanged. Claude independently advanced to **e96044b / claude/darnassus-undercity**, based on6ad66d1; read its authored handoff, which acknowledges this multiplayer reservation and restricts Menu/test changes to catalog additions. No new cities/elevation imported. Its existing Orgrimmar ref72b362f is retained. Snapshot/recheck PASS both foreign worktrees’370files/HEADs/branches/statuses after that observed advancement; no foreign edits, reset, switch or claimed direct Claude conversation. Public contracts and own handoff are the coordination record. No push/main merge/tag/release.

**Deployment for the continuing owner test:** PowerShell7 existing installer WhatIf PASS; actual backup/overwrite/hash installation PASS50files. Prior49files match the last deployedc581a52 receipt and are independently verified in backup/before.csv. Manifest `local-artifacts/multiplayer-grid-20261023/backups/20261023-090347-158-a74d717dd9c84f9184be9cbf9ff9a508/install.json`; Status/StageVerified, BackupVerified=true. Tested source/currentsource/installed/manifest exact50paths+SHA256. No extra files/deletion/WTF/SavedVariables/otheraddon/clientinput changes. Earlier raw-Git-blob audit comparison was unsuitable for Windows line endings; independent installation check uses the prior actual tested-file hash receipt, not normalized blobs.

**Friend ZIP from installed directory:** `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-eb2055a.zip`,50files/33,930,577bytes, SHA256 **83a1211c312f047d4f7aa905abfd8b6747d888386d882a06e8d7f00381e14c24**. CRC/exactpaths/all source-installed-ZIP hashes PASS; installed/source trees unchanged across packaging. OldZIP preserved. Ignored logs/snapshots/helper results/deployment receipt in `local-artifacts/multiplayer-grid-20261023/`. Runtime commit eb2055a; following handoff commit changes docs only.

**Next exact task:** both players fully restart WoW with this identical candidate, then one short Mirage race via [the updated menu guide](MULTIPLAYER_PLAYTEST.md). Check shared grid,3–2–1–GO, both chosen sprites and nearby visibility/corrections. No standalone net probe needed. Record actual usability before further replication/contact/result-authority work; do not declare the lag solved from mocks.

**Latest authorized multiplayer installation (2026-10-22 23:52 +02:00, Europe/Oslo):** owner explicitly requests direct addon installation, then a ZIP created from that installed directory. Runtime remains tested **c581a52950013263049cd82a44f83217556fc1c6**, docs basefb0df19, own codex/live-multiplayer-integration. Existing PowerShell7 installer WhatIf PASS; actual overwrite/install PASS49source files, with all41priorfiles backed up/verified first. Target `_classic_beta_/Interface/AddOns/AzerothKart`; no SavedVariables, other-addon or client-input changes. Exact manifest `local-artifacts/live-multiplayer-install-20261022/backups/20261022-235101-774-84c5285b8ea445aba58eaf5ceac28acf/install.json`. Manifest Verified/BackupVerified=true; prior installation preserved under its before/ folder.

Independent read-only audit PASS: tested source/current source/installed/manifest exact49files, backup/before.csv exact41priorfiles, and both foreign worktrees'347file hashes/statuses/HEADs unchanged.

**Installed-directory package:** created directly from the actual installed tree at `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-c581a52.zip`,49files/34,040,705bytes. SHA256 **c19ea2fc005b4b643493f12245825c0587c8eaffcb96ff76fe4e8bd92300525a**. CRC, exact49archivepaths and source/installed/ZIP SHA256 values PASS; installed tree unchanged across packaging. This replaces the previous source-built ZIP as the file to share. Receipt `local-artifacts/live-multiplayer-install-20261022/deployment-receipt.json`; preinstall/source hashes and helper result retained alongside it. Runtime unchanged; prior full Lua5.1 all30-module/57parsed results remain scoped to this exact candidate, not rerun for copying. Actual client/native multiplayer delivery and game feel **NOT RUN**. No push/release/main merge or milestone completion. Next single task: both players fully restart WoW (new files) and try one race through the new Multiplayer menu using [the short guide](MULTIPLAYER_PLAYTEST.md), with no standalone network probe prerequisite.

**Latest experimental two-player candidate (2026-10-22 23:39 +02:00, Europe/Oslo):** owner explicitly asks to connect LiveRace to Forever transport and wire lobby/race display. Own clean `codex/live-multiplayer-integration` from7f80c2b, reservationc87fe29, implemented **c581a52950013263049cd82a44f83217556fc1c6**. [Simple friend-test steps](MULTIPLAYER_PLAYTEST.md), [implemented contract](LIVE_RACE.md#implemented-native-and-player-flow-integration). Native/player flow is wired source now; actual Forever delivery/feel **NOT RUN**. No milestone acceptance is closed.

**Changes:** opt-in HostLive/ListenLive, automatic exactly-once GO adoption retaining the same Core frame owner/hooks/persistent0.5s/2calls/158B gate, copied AdvanceLive state and normal control/clock API compatibility. Additive PeerSession.beginRace removes the old30s negotiating deadline while retaining the paced final cancellation. Post-GO CANCEL passes normal peer/session/highwater/conflict checks; send refusals stop without further sends. Core binds the menu view/action bridge. Full-name/fresh-code inputs, supported track choice, explicit Listen/Host/Join/Ready/Start/Leave,5Hz lobby refresh and fixed feedback. Deliberate Ready aligns the map/arms eligibility; matching-session GO activates capture/real backend ticks without a solo countdown or second loop. Cyan pooled observation marker+label, one-interval interpolation/stale fade/offscreen clipping. No opponent collision, authoritative correction, remote kart-art exchange or agreed winner. Local finish stays unverified; Stop/Close/navigation release/cancel, results navigation leaves a still-finishing session. Creation-time pool **79/166/81**; all art/physics/geometry unchanged.

**Executed:** pinnedLupa2.8/actual Lua5.1 with C:/Python314/python.exe and canonical local dependencies. Focused `scripts/test_lua.py --runtime lua51 --tests peer_session live_protocol live_race session_transport ui menu` PASS57parsed/sixmodules; native+cross-layer focused rerun PASS after sequence-conflict fix. Final integration checkpoint `scripts/test_lua.py --runtime lua51` **PASS all30 modules/57source-test files**. Complete two isolated all-TOC/Core/Menu/UI/native clients click through the real flow under700ms synthetic RTT/5s clock offset, capture at GO, drive180real windowframes, show moving observations, stop/cancel/freeze both and release input/lease without per-frame widgets. Other native tests cover32sLeave/exactlyonepacedCANCEL, shared prefix budgets, old-sequence CANCEL, wrong-peer/session/duplicate isolation, send outcomes/lifecycle/reentrant GO initialization. UI regression covers offered-map refusal, focus/armed matching, pre-Ready close, finish drain/frozen results, cancellation ordering and unchanged solo mechanics/preferences. Source review fixed old30sdeadline and postGOCANCEL bypass; no remaining source blocker found. `git diff --check` PASS; validator Python parse PASS. `scripts/validate_project.py` **FAIL only on two pre-existing expired local skill links in PROGRESS**, not a pass. Lua5.4/full art rebuild/real client/native delivery/timing/FPS **NOT RUN**.

**Preservation/package:** other worktrees'347file hashes/statuses/HEADs unchanged;20existing core simulation/protocol modules plus all images byte-identical to7f80c2b. Claude authored handoff/checkout retained; ownership coordination is shared source/handoff plus explicit owner assignment, not a claimed direct Claude conversation. `scripts/build_release.py` produced a local developer ZIP; independently checked CRC, exact49-path set and all49source/ZIP SHA256 values. Versioned artifact `release/AzerothKart-two-player-c581a52.zip`,34,040,705bytes, SHA256f4b9a91e68b48ffec27ef82330853388277f39ae9412f21652064e68c2ae1a04. Receipts/logs in ignored `local-artifacts/live-multiplayer-integration-20261022/`. **Not installed or published**; installed prior41-file2e75a3d remains unchanged. Both testers need this identical49-file package and a full restart before the menu test. Only Test Oval/Mirage are network-negotiated; other maps stay solo. Delayed observations may fall outside Mirage's follow camera at speed; actual usability is pending, not a verified responsiveness claim.

**Next single task:** coordinated installation of the exact candidate on the owner's client, then one real friend race through the new Multiplayer menu using the short guide; record both-client GO/visible movement/Stop and failure text, with no repeat of the old standalone network probe. Shared winner/contact/production authority, full socket recovery and release gates remain open.

**Latest multiplayer backend slice (2026-10-22 23:11 +02:00, Europe/Oslo):** owner asks to continue toward testing multiplayer with a friend. Own clean `codex/live-race-controller` from4544108, reservation5008f44; implementation **b35946f**. [Implemented contract](LIVE_RACE.md). Added pure LiveRace owner and LiveProtocol observational pose codec; no native transport/menu/UI activation, publication, install or new manual probe in this slice. M2/M6 acceptance stays open; it is not yet a friend-testable build.

**Implemented:** one tick-zero RaceStart bundle claimed once before injected initialization, copied authoritative data/view boundaries, actual60Hz Physics/Race through five-step Loop, exact local finish and partial stop/combat state. Scoped34-byte poses on inert AZKRUN1, monotonic sequence/tick bounds, two remote observations only, stale indicator and five-second silence/frozen-progress timeout. Output is latest-only, nominal2Hz/41payload+prefixB each, local2calls/158B rolling ceiling and no ACK per snapshot. All send refusals close; no production authority, local corrections, kart contact, shared winner or trusted remote laps. Native integration must retain SessionTransport's existing persistent budget/lease across GO rather than create a second sender. Existing native and UI APIs are unchanged.

**Executed:** actual Lua5.1 via pinnedLupa2.8/canonical local dependencies: `scripts/test_lua.py --runtime lua51 --tests live_protocol live_race race_start session_transport ui` PASS,56source/test files parsed/five modules. New two-peer synthetic20-second tape produces1200equal-input ticks and41accepted pose attempts per peer with clocks5seconds apart/700ms simulated RTT; rolling caps asserted. Actual Physics/Loop/Checkpoints/Laps/Race/GO used. Regressions cover malformed/scoped/stale packets, reordering, copy isolation, duplicate owners, hitches, finish tick, stop/combat, throttled/failed/unknown/thrown sends and reentrant stop. Independent review reproduced double-owner, frozen-progress timeout, missing-checkpoint and nil-clock issues; all fixed with regressions. Final `--tests live_race` PASS after duration/simulation-failure/callback-stop cases. `git diff --check` PASS; validator Python parses; both26-module TOCs agree. `scripts/validate_project.py` FAIL only on the same two pre-existing expired local skill links in PROGRESS, not counted as pass. Lua5.4/full broad suite/native gameplay/transport/performance **NOT RUN**.

**Preservation and next task:** all347 foreign tracked/untracked file hashes/statuses/HEADs match the prior snapshot;17critical runtime modules plus every asset unchanged. Claude worktree and authored handoff untouched; mock UI pool remains75/165/80. Installed source remains prior41-file2e75a3d. Ignored receipts under `local-artifacts/live-race-controller-20261022/`. Next single task: opt-in atomic live adoption in SessionTransport with a complete mocked negotiated-GO-to-live test, preserving its frame lease and persistent pacing. Reviewed Claude lobby/canvas binding follows; no repeated low-rate connection probe prerequisite.

**Latest Orgrimmar publication review (2026-10-22 22:56 +02:00, Europe/Oslo):** owner requests review of Claude's handoff and push if good. APPROVED and published exact **72b362fc4a7926624c5ceaf648056595c8b0e080** to `origin/claude/orgrimmar`, normal non-force push/live SHA match. Reviewed stacked four-kart dependency8cc2031 first, then Orgrimmar's three commits. [Review](reviews/2026-10-22-orgrimmar.md). Main remainsf923d15; no merge, production edits, release or installation. Own branch `codex/orgrimmar-review`, reservation505ec2e; Claude handoff unchanged.

**Verified:** focused actual Lua5.1 presentation/circuit/menu/ui PASS (52parsed, four modules); geometry-only generated check PASS; Python boundary11tests PASS; five changed Python files parse; twenty runtime TGA packaging checks PASS; six renderer-shadow smoke comparisons PASS. Mock pool75/165/80, ten cosmetic karts, five ready solo tracks. All22 critical Lua/TOC modules, prior city definitions and14 existing runtime images retained byte-identically. Structural validator FAILS only on two pre-existing expired local skill links in PROGRESS; whitespace check FAILS one incoming documentation trailing space. Both nonblocking documentation issues are recorded, not counted as passes. Full suite/Lua5.4/art rebuild/native client checks NOT RUN by Codex; Claude's two-machine results attributed separately. No multiplayer/milestone completion claim.

**Deployment/next:** installed source remains prior41-file2e75a3d; published candidate47files is not installed. Foreign worktree preservation is checked against the347-file pre-review snapshot. New art requires a full restart after a future coordinated, verified install. Next single independent Codex task remains bounded live-race lifecycle around RaceStart; Claude owns visual follow-up.

**Latest approved/published Ironforge polish (2026-10-22 17:50 +02:00, Europe/Oslo):** user requests review of `claude/ironforge-polish` and push if approved. Reviewed both new commits b34a225/2e75a3d from published bc93753. **APPROVED**: half-size anvil and existing Warcraft III metal texture regions on the procedural forge meshes; only Ironforge Background/Preview change in the addon. All39 other runtime files (including every Lua/TOC), all tests/geometry,12 other art assets and the tunnel-corner fixes are byte-identical. [Review](reviews/2026-10-22-ironforge-polish.md).

**Published:** exact **2e75a3dc461fd76859b766c95eaab692bfd75282** to `origin/claude/ironforge-polish`, normal non-force push and live-ref match. Main remainsf923d15; prior Codex/Claude branches and foreign329files/status/HEAD preserved. Own documentation branch `codex/ironforge-polish-review` starts at the approved source (reservation1db81dd); Claude's handoff is retained unchanged.

**Executed:** structural validator104paths PASS; geometry-only generated check PASS; three changed Python files parse; whitespace PASS. Independent sampler/mesh review PASS130 wrapped/negative UV cases, exact texel/bilinear checks and three meshes at eight headings retaining geometry/normals. No Lua suite rerun because all Lua/tests/data are unchanged. Clarification:82d57eb had focused six-module dual-runtime checks plus a three-module final run, not a full suite as Claude's latest handoff says. Codex full art rebuild NOT RUN; Claude's separately attributed two-machine rebuild evidence retained. New textured-forge client appearance NOT RUN. Its quoted owner approval covers the previous tunnels/lava only.

**Installation:** prior user-authorized review/push/install workflow retained. PowerShell7 installer copied41 source files, verified their hashes and preserved41 prior files under `local-artifacts/ironforge-polish-review-20261022/install-backups/20261022-174831-565-c80be06d79a847959274bb136099ff6d/install.json`. Independent final verification PASS: all41 committed/source/installed/manifest files exact2e75a3d;41 backups exactbefore.csv, baseline and82d57eb, no extras. Manifest Verified/BackupVerified=true. Both foreign worktrees'329 files/statuses/HEADs and all prior refs are preserved. Ignored receipt `local-artifacts/ironforge-polish-review-20261022/deployment-receipt.json`. Installation is complete; following review documentation changes no addon files. No UI/physics/network changes, main merge, release or milestone completion. Next Codex task remains bounded live-race lifecycle; owner may fully restart WoW and inspect the half-size textured anvil/pumps during a normal Ironforge drive.


**Latest authorized GitHub publication and coordination (2026-10-22 16:38 +0200, Europe/Oslo):** user explicitly requests GitHub publication, installed addon and alignment with Claude. Published reviewed combined `codex/ironforge-narrows` at **c6bb0e5699b5f30d9f684d50283c76b5fd4d4a8b** using a normal non-force Windows Git push; live remote ref exactly matches. GitHub main remainsf923d15. All three Claude commits5a56e90/289ad3d/9461f9c are ancestors; Claude remains on its clean tracked branch9461f9c with pre-existing untracked outputs untouched. Its canonical handoff is imported unchanged; CLAUDE.md imports AGENTS.md. Alignment checked through Git/shared contracts/handoffs, not a claimed direct conversation.

Installed source remains **82d57eb11e23eb2417a323ba0c714c23514a50af**: independent recheck verifies41 committed/source/target/manifest files plus41 backup files exact, and both other worktrees'326files/status/HEADs unchanged. No recopy or repeated gameplay suite was needed for unchanged runtime. The prior Lua/geometry results below remain scoped to that tested source; v3 client checks are still NOT RUN. The publication handoff records exact safe fetch/new-branch commands for Claude. Following documentation is published on the same feature branch; the final remote-tip/install receipt is ignored under `local-artifacts/ironforge-v3-integration-20261022/`. No main merge, force push, tag or release.

**Next exact task:** owner fully restarts WoW and tries Ironforge; Codex's next independent implementation remains the bounded live-race lifecycle around RaceStart. Claude continues visuals from the combined published baseline on its own new feature branch, preserving the corner/rough-pocket fixes.


**Latest installed Ironforge v3 integration (2026-10-22 16:33 +0200, Europe/Oslo):** from clean `d5817a8` / reservation `69dc2dd`, review and normal merge of Claude `9461f9c` on `codex/ironforge-narrows`. Accept additive per-loop-segment narrows after independent collision/authoring review. Two Forlorn Cavern tunnels use42-unit centre reach /56-unit painted edge, without shoulders; wider streets retain rough response. Revised lava/dark walls and original anvil/pumps imported. Route, seven gates, spawn, Stormwindv3/full-speed, twelve other runtime assets and all UI/global Physics/network behavior remain intact. [Review and exact commands](reviews/2026-10-22-ironforge-narrows.md).

**Executed:** focused `scripts/test_lua.py --runtime both --tests circuit physics surface ui menu determinism` PASS six modules/52 parsed files each; Python boundary11 PASS; geometry-only check PASS; validator104paths/24-module TOCs/links/ledger PASS; six Python files parse; whitespace PASS. Added closing-segment/min-overlap/copy/branch and boolean-validation regressions. Final review found a tiny rough pocket at(790.1041330568827,1652.2604655230214) inside an otherwise fully paved tunnel; corrected only the valid exposed-corner surface using a private narrowed-capsule flag, with unchanged clearance/shape/default shoulders. Exact point, default-rough negative and wall-clearance regressions added; final dual-runtime circuit/physics/surface PASS after this fix. Explicit pool71/165/80 unchanged. Reviewer's5,960 bounded transition steps and279 recoveries passed. Full suite/art rebuild NOT RUN by Codex (Claude's results attributed separately). V3 client checks NOT RUN; the quoted owner drive was v2, not v3.

**Preservation/deployment:** verified all-ref bundle, canonical103 + Claude223 tracked/untracked files and statuses/HEADs; installed41-file baseline exactac4ae23. Normal two-parent merge **82d57eb11e23eb2417a323ba0c714c23514a50af**, parents69dc2dd/9461f9c, is committed and installed. Independent verification:41 committed/source/target/manifest files exact;41 prior files backed up and exact against before.csv, pre-install snapshot andac4ae23, with no extras. Manifest `local-artifacts/ironforge-v3-integration-20261022/install-backups/20261022-163127-637-2915c11e90644cd9ae1a21f6037226c3/install.json`; ignored `local-artifacts/ironforge-v3-integration-20261022/deployment-receipt.json` records all hashes. Both foreign worktrees'326 files/statuses/HEADs and all prior refs remain preserved. Following deployment documentation changes no addon files. No push/main merge/release/milestone completion. Current multiplayer acceptance and content targets remain open.

**Next exact task:** Codex resumes the bounded live-race lifecycle controller around RaceStart. After the coordinated install/full restart, the owner may try Ironforge's two tunnel transitions and Forge during a normal drive; no additional network probe or manual matrix required.


**Latest installed integration (2026-10-22 13:27 +02:00, Europe/Oslo):** owner confirms "The corner works good now"; record the reported Stormwind corner as client-passed, with broader acceptance still open. On `codex/ironforge-integration`, from clean899d04d/reservation7fe251e, reviewed and combined Claude's Ironforge `de2fa5f` without changing either foreign checkout or losing Stormwindv3/full-speed, the staged background loader, preference/Stop/results regressions or session/start-clock work. Four solo tracks/six cosmetic karts; multiplayer stays Coming soon. [Review and exact checks](reviews/2026-10-22-ironforge-integration.md).

Ironforge's7,077-unit route, seven gates and artwork are retained. Its version2 data reuses the existing14-unit exposed-wall clearance to remove a gate-hall phantom corner; rough shoulders remain. All14 runtime art files match Claude, including12 existing files. No global Physics/Circuit/UI/network change. Current explicit pool71/165/80; two background slots can retain32MiB raw city pixels, plus previews/native overhead.

**Executed:** full `scripts/test_lua.py --runtime both` PASS27 modules/52 parsed files each; focused Lua5.1 UI/menu/circuit PASS; Python analytic9 PASS; geometry-only generated check PASS; structural103paths/24-module TOCs/links/ledger PASS; whitespace PASS. Native Ironforge checks and Codex art regeneration **NOT RUN**. Pre-install installed39 files verified81cc0ed; recovery bundle and both other worktrees'305-file snapshot verified. Normal two-parent implementation merge **ac4ae23db79d02b48e55b4b1b3dddaa315e4b0be** is committed and installed. All41 committed/source/installed/manifest files match SHA256; all39 prior files are backed up and independently match before.csv and81cc0ed, with no extras. Manifest: `local-artifacts/ironforge-integration-20261022/install-backups/20261022-132604-865-804f0c60ebb042a7bc3e340f5eb40463/install.json`; independent receipt `local-artifacts/ironforge-integration-20261022/deployment-receipt.json`. Both other worktrees'305files, statuses and HEADs remain unchanged. Following deployment documentation changes no addon files. No push, main merge, release or milestone completion.

**Next exact task:** owner fully restarts WoW and tries Ironforge through Single Player. Codex can independently resume the bounded live-race lifecycle controller around RaceStart; no repeated transport probe or ghost/time-trial prerequisite.


**Latest collision correction (2026-10-22 10:46 +02:00, Europe/Oslo):** owner screenshot reports an invisible wall inside the Park/Mage paved corner. Reproduced at(442,849)→(445,846) and(450,850); corrected and installed **81cc0ed** on `codex/stormwind-wall-alignment` fromf62e708. Stormwind trackv3 keeps14-unit centre clearance from the exposed painted wall union rather than shrinking each primitive separately. Full-speed shoulders, normal straight-wall padding, artwork/gates/spawn/othertracks/globalPhysics7 remain unchanged. Reachable corner/arc slide candidates respect the movement bound. Python9analytic tests PASS; Lua5.1 focusedcircuit/physics/surface/obstacles/ui PASS, finalcircuit PASS after arc fix (52files parsed); geometry-onlycheck/98path validator/whitespace PASS. Installed39files exactcommittedsource;39priorfiles backed up/verified. Owner native `/reload` retest **NOT RUN**. No push/main merge/release; prior branch/worktrees/history preserved. Next: owner retests that same corner, then resume bounded live-race work.


**Previous handling correction (2026-10-22 10:11 +02:00, Europe/Oslo):** owner requests full speed to Stormwind's edges. Implemented and installed **c4b430d** on `codex/stormwind-full-speed` from clean deployedc59a607: Stormwind trackv2 enables Circuit.fullSpeedToWalls, removing shoulder drag and preserving drift/boost eligibility to the existing walls. Painted road/radii/gates/spawn/artwork/wall collisions and other tracks/globalPhysics7 are unchanged. Focused Lua5.1 circuit/surface/drift/menu/ui PASS (52files parsed); geometry-only generator/check and structural96paths/24TOCs/links/ledger PASS. Installer and independent hash check:39source/targetfiles exact;39priorfiles backed up/verified. **Owner `/reload` check NOT RUN**. Original combined branch/main/Claude checkout/history preserved; no push/release in this correction. Next: owner tests the full-width Stormwind handling, then Codex resumes bounded live-race control. The checkpoint below records the prior integrated deployment.


**Prior source/deployment checkpoint (2026-10-22 08:37 +02:00, Europe/Oslo):** user authorized latest-Claude-handoff review, push and install before his own test. Read complete city handoff **78d97a1**; reviewed Circuit/Courses/track loading, merged it normally as **f9f2af0** while preserving the earlier combined UI/backend and preference regressions. **e748b60** fixes a discovered background rollback failure with one preallocated staging texture. [City review](reviews/2026-10-22-city-integration.md), [integration/deployment status](INTEGRATION_STATUS.md), [Codex handoff](handoffs/codex-latest.md).

**Installed/published:** tested code **e748b60** is installed: **39/39 source/target/manifest SHA256 exact**, verified prior22-file backup, no extras or other-addon/SavedVariables changes. Normal non-force push created `codex/ui-backend-integration` on GitHub; the following deployment-documentation commit is on that same branch. Main/origin-main remainf923d15; original Claude refs/worktree/history and canonical checkout remain unchanged. All297 other-worktree tracked/untracked files were independently rechecked unchanged.

**Executed checks:** final full suite **27 tests/52 parsed files in each of Lua5.1/5.4 PASS**; focused Lua5.1 UI/menu/circuit PASS. Validator **96 paths/24-module TOCs/links/ledger PASS**. Exact runtime-art comparisons PASS (12files matchClaude78d97a1);18 preexisting Codex modules byte-identical77581b9; six authoring Python scripts parsed. Independent collision review/targeted tests passed; actual game feel is not inferred. Explicit mock pool **71frames/165textures/80fonts**. Both scenery slots may retain an image; this adds bounded texture memory and no per-frame creation/load. City art regeneration NOT RUN here; Claude's reproducibility evidence remains separately attributed in its handoff.

**Current milestone/open acceptance:** M2 remains experimental. Three solo tracks and six cosmetic karts are available in this integrated developer build; neither content acceptance nor any milestone is declared complete. Multiplayer commands/replication/finish, actual AZKART2/AZKCLK1 flow, start-clock feel, socket reconnect, scale and release acceptance remain OPEN. Native frontend/2048texture loading/drive/walls/fonts/sound/settings persistence/performance are **NOT RUN**.

**Next single task:** owner's integrated-client smoke after a full WoW restart: `/akart` → Single Player → Capital Cities Cup → Stormwind → kart → Race!, then Stop/Restart/Close results. Resume Codex's bounded live-race controller and paced opponent snapshots after this deployment handoff; no repeated low-rate probe or ghost/time-trial detour.

## Canonical checkout and commits

**GitHub publication, 2026-10-20 11:48 CEST:** the owner explicitly requested pushing the existing project. `main` through implementation commit `7acab18` was pushed successfully to `https://github.com/PhilForever/AzerothKart.git` and now tracks `origin/main`. This is source publication only; no tag, release, distribution package or automatic future-push authorization was created. The publication handoff below follows in a documentation commit.

Work in this directory: `C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart`.
Remote: `https://github.com/PhilForever/AzerothKart.git`; branch `main`. The pack originally had no `.git` history; remote inspection returned no refs. The original pack was preserved before changes.

The canonical checkout remains on `codex/handoff-contracts` at `5570968`; `main`/local `origin/main` remain `f923d15`. Codex uses the existing `AzerothKart-Codex-Review` checkout on `codex/ui-backend-integration`, with tested/installed codee748b60 and its following deployment-documentation commit. Previous roster83c611c, backend192c6de and Claude UI1b2d3d5 remain preserved. Claude is independently on `claude/capital-cup` at78d97a1; that history is now integrated in Codex's branch without switching its checkout. No other checkout was synchronized. The2026-10-21 publication of the two exact approved feature tips is historical; today's authorized combined feature branch is also published, with main unchanged.

- `98bd16a` — `chore: preserve initial Azeroth Kart M0 project pack`.
- `be33176` — `fix: harden M0 driving probe and feasibility checks`.
- `c2ecadf` — `docs: record M0 validation evidence and client handoff` (initial offline session).
- `6e20ec0` — `fix: close kart sessions when combat interrupts`.
- `3b02641` — `docs: record live M0 checks and owner combat results`.
- `2825ba3` — `fix: preserve complete M0 timing samples`.
- `fc7f339` — `fix: verify and back up repeatable local installs`.
- `2a5b8e8` — `fix: retain combat outcome through rejected restarts`.
- `364a245` — `docs: record updated M0 install and live baseline`.
- `ae6fed0` — `fix: close stopped kart windows when combat begins`.
- `865e187` — `fix: align primitive road with analytical track bounds`.
- `38faab2` — `feat: add bounded opt-in performance probe`.
- `ce1b78c` — `docs: record stationary profiler results and renderer review blocker`.
- `fbd3cc8` — `fix: remove road seams with explicit grass layering`.
- `68c243c` — `docs: record M0 idle stability and prepare scale probe`.
- `0108b4e` — `docs: record incomplete scale probe and restoration mismatch`.
- `e4610b6` — `feat: add charged drift and mini-boost to solo driving`.
- `ef09433` — `feat: add recoverable grass and perimeter collisions`.
- `f6ab761` — `feat: interpolate kart presentation between simulation steps`.
- `092e397` — `feat: add pooled drift charge and boost meter`.
- `d42fb92` — `feat: add progressive keyboard steering with fast centering`.
- `a7326e9` — `feat: track ordered directional checkpoints on the test oval`.
- `e10e869` — `feat: add repeatable practice laps and tick-based timing`.
- `e3a6523` — `feat: finish three-lap solo runs with retained results`.
- `5c4c135` — `feat: add fixed-step countdown before solo races`.
- `3ebb60f` — `feat: show the best completed lap within each run`.
- `7b6ee69` — `docs: prepare Mirage Raceway assets and art direction`.
- `5237f7a` — `feat: add Mirage geometry blockout and layout guide`.
- `c019ad2` — `feat: add selectable Mirage blockout track`.
- `0ed33c2` — `fix: make drift charging usable through steering corrections`.
- `7acab18` — `feat: bring Mirage racing into a close follow camera`.

Repository-local identity is `PhilForever <philfluenser@gmail.com>` with `user.useConfigOnly=true`; verified in config and commit authors. Global identity was left unchanged. Earlier implementation sessions performed no push, tag, distribution or automation; the owner's first authorized GitHub push is recorded above. The initial client-check session installed only AzerothKart in the local Forever AddOns folder and verified all nine files against source SHA-256; current sixteen-file installation evidence is in the latest implementation handoff. Ignored `local-artifacts/` contains developer dependencies/logs and synthetic install fixtures/backups; it is not staged.

## Completed and evidenced

- [x] Inspected all original source, tests/scripts and documents from `docs/INDEX.md`, including ADRs; preserved initial content in Git.
- [x] Structural validation of paths, synchronized TOC source order, discovery markers, local Markdown links and network-ledger fields.
- [x] Earlier M0 source: all seven addon modules and nine Lua test/runner files parsed under both Lua 5.1 and Lua 5.4; eight tests executed in each runtime. The later handoffs preserve focused results for their source versions. The 2026-10-20 parallel-development checkpoint separately ran the current full Lua 5.1 suite: 29 files parsed, sixteen modules passed, including the v6 10k-tick replay. Current Lua 5.4/client acceptance is not inferred.
- [x] Removed `_G` dependency from pure Track/Physics modules; introduced pure Input and Loop modules with explicit addon namespace registration/returned offline imports.
- [x] Corrected inverted left/right steering in physics v2; v3 added deterministic drift, two charge tiers and a release boost; v4 separated road/grass/walls with gradual slowdown and tangent-preserving wall constraints. Current v5 adds progressive steering with faster centering. Production collision/race engine and handling acceptance remain pending.
- [x] Physical-key alias tracking prevents W/Up and equivalent steering/brake releases from canceling another held alias. Sampling reuses a semantic input table; stop clears held/sampled controls in place.
- [x] Fixed 60 Hz loop, at most five catch-up steps per frame; preserves fractional remainder and records full elapsed, executed ticks, dropped seconds and hitch frames.
- [x] Earlier v2 seed `1729` generated a repeatable 10,000-tick input tape with every state field matching at every tick under 30/60/144 simulated FPS. The extended current v5 long tape is NOT RUN this slice; focused 720-tick drift, 360-tick surface/steering and 120-tick UI cadence replays passed Lua 5.1 across all 14 fields. These are same-runtime checks, not cross-client proof or a gameplay PRNG.
- [x] Mocked UI/Core lifecycle coverage includes hidden/chat/combat/missing-capability Start refusal; key aliases; Escape/unknown/Enter; Stop/Close/Hide/toggle; all mouse clicks; text/application focus; leaving world/logout; combat event and OnUpdate fallback; deferred propagation; no automatic resume; minimal save-field preservation.
- [x] Explicit `/akart probe` / Print Probe reports identity, input capabilities, event-registration failures, clock metrics, last stop reason and explicit UI object counts. No per-tick chat or UI object creation.
- [x] Source timing aid: cumulative valid active frame seconds, executed simulation seconds and callback cadence; complete stopped elapsed/drop/remainder accounting and immediate Start/Stop HUD refresh. Offline tested and installed; zeroed live baseline observed, with timed/final-sample acceptance pending.
- [x] 2026-10-19 installation/reload baseline: prior addon backed up, two changed files copied and all nine installed SHA-256 values verified twice; updated zeroed timing/HUD fields rendered inactive. Timed drive/final-sample acceptance remains pending.
- [x] Two human drives: ticks 3492/3756, active seconds 58.2120/62.6020, no dropped time, matching HUD and explicit counts 6/99/3. Delayed probes remained frozen; sample 1 also retained numbers across slash close/reopen. Third sample/external durations/full F1 remain pending.
- [x] Primitive road follows unchanged analytical Track bounds with the same 96 road textures. Dense actual-rectangle regression covers 92,853 points outside a 3.5-unit vertical edge margin and the old mismatch at `(400,440)`. Isolated grass occlusion led to explicit grass priority plus creation-only band snapping. Normal reload verified seam-free appearance and all 96 settings at effective scale 0.72452831268311; counts remain 6/99/3. [Evidence](evidence/2026-10-19-m0-road-layer.md); full supported-scale/performance acceptance remains pending.
- [x] Optional bounded profiler passes offline tests and produced 600 valid stationary readings on build 70450. Scoped averages/maxima, continued simulation after cap, frozen stopped/reopen/disarm output and counts 6/99/3 recorded in [stationary evidence](evidence/2026-10-19-m0-stationary-profile.md). Fresh unprofiled Start and full performance acceptance remain pending; this is not exclusive CPU cost.
- [x] Scoped stopped/open idle check: 917.598 wall-clock seconds with frozen timing/tick 852 and counts 6/99/3, unchanged effective scale, readable sampled renderer, endpoint FPS points and normal close/reopen retention. Finished hidden/inactive/profiling off. [Exact evidence](evidence/2026-10-19-m0-idle.md) distinguishes the earlier owner-interrupted attempt. No sustained FPS/memory/CPU/taint acceptance follows. The subsequent scale attempt below does not replace this historical result.
- [x] Normal scale control discovered and incomplete attempt recorded without a false pass. Original CVars/checkbox/stored value returned after timed reversion; effective-scale mismatch remains flagged for review. [Scale evidence](evidence/2026-10-19-m0-scale.md). Pure/source tests and installed files unchanged; read-only geometry probe prepared, NOT RUN.
- [x] Stopped-window combat source gap reproduced and fixed: combat-start event hides inactive window while preserving its sample/result/reason, without another interruption announcement. New never-started/stopped/interrupted fixtures pass Lua 5.1/5.4. Source installed and reloaded; actual combat behavior NOT RUN at owner direction.
- [x] Retained interruption note through repeated Close/toggle/reopen, inactive Stop and rejected Start; actual refusal text is also visible. Regression checks retain the same result/state/clock/HUD and clear the note only on a successful fresh Start. Offline only; extended client sequence pending.
- [x] Local installer fixture slice: direct per-file repeat copies, verified old-file backup before target writes, copied SHA-256 verification, explicit overwrite/preview and failure records. PowerShell 7: 18 cases passed, 3 junction fixtures skipped; PowerShell 5.1 syntax passed, runtime blocked. No live install performed.
- [x] Exact installed-client manual probes and header-only F4 experiment ledger prepared; no network code/traffic or multiplayer claim.

## Pending acceptance / blockers

- [x] Live `GetBuildInfo()` returned `1.60.1 70450 Oct 15 2026 16001`; runtime project ID is `18`; selected TOC metadata is `Camelot`; addon `0.0.1` loads and appears enabled without an out-of-date warning.
- [x] Core client control smoke: Start mouse-down/OnClick ordering, Escape/menu, Close/reopen, Enter/chat, Stop, idle Alt-Tab, map binding, canvas click, UI hide/show and clean inactive reload observed. This does not mark every held-input/overlapping-panel/world-transition case passed; see the checklist's exact scope.
- [x] Owner's real combat smoke: window closed, interruption message appeared, WoW controls worked. Once-only handling and retained results pass offline; exact repeated-notification count, reopen and full taint audit remain live follow-ups. Restricted propagation setters remain guarded; no bypass is used.
- [ ] `IsGameWindowFocused` and `IsWindowFocused` are both absent on build 70450. An idle Alt-Tab trial stayed stopped after >=5 seconds away through the unknown-key path. Held-key release outside the application and other application-switch routes remain unverified; do not mark full F2 passed.
- [ ] Remaining UI-scale/layout, sustained FPS/CPU cost, long-session behavior and memory. Basic kart movement/rotation is observed; mock/live counters measure explicit addon allocations only, not client/template internals or whole-client performance.
- [ ] Full optional-profiler acceptance: availability/guarded arming/one bounded stationary sample/retention observed; fresh unprofiled Start and errors/handling/stress checks remain unrun. No sustained performance or exclusive CPU/GPU claim.
- [ ] Stopped-window combat-close live follow-up: source fixed/offline tested and reloaded, combat check deferred at owner direction to continue elsewhere. Do not ask for another combat test as the next development task. Prior observations remain scoped in the evidence; no combat API contradiction is established.
- [ ] Supported-scale renderer matrix and long-session behavior. The prior grass/road configuration blocker is resolved for the recorded startup case with explicit priority; native batching mechanics are not established. Do not infer all-scale correctness or a sustained-performance pass from the clean reload.
- [ ] Scale restoration review: original 1.000000/0 preferences returned after normal Apply reversion, but effective scale changed 0.72452831268311 → 0.71111112833023. No baseline physical dimensions were measured; no native-scale explanation or API contradiction established. Keep settings unchanged. The guarded read-only geometry review is deferred under ADR 0007, not a blocker to independent M1 work.
- [ ] Logout/full restart and isolated sentinel persistence. Clean inactive `/reload` is observed; minimal schema initialization is not proof of a save, migration or settings/ghost support.
- [ ] Positive M1 handling acceptance: owner reported v5 drift on Test Oval was too tight to charge naturally and corrections erased the meter. The v6 response is installed/offline checked; new direct-play feedback remains pending. Analytical metrics do not establish game feel.
- [ ] Production simultaneous-racing capacity, full socket reconnect and replication architecture acceptance. AKT722–725 now record scoped two-client traffic, RTT and addon-reload/fresh-session evidence under ADR 0013; these do not establish live racing or larger rooms.

Initial file-only evidence: `_classic_beta_\WowB.exe` reports `1.60.1.70450`; `.flavor.info` contains `wow_classic_beta`; the initial scan had no running `Wow*` process. A later actual client session confirmed runtime identity and Camelot selection as above. After the owner instructed proceeding with sections 1–2, this addon was installed for those checks. No prior AzerothKart installation existed; status and all nine hash matches are recorded in workspace `artifacts/AzerothKart/20261018-170909/`. No other addon or SavedVariables files were edited by deployment.

## Next exact task

**Next exact task:** owner performs the integrated-client smoke after a full restart using the installed e748b60 build. Codex then continues the bounded live-race controller and paced remote snapshots from the existing backend GO handoff, preserving budgets/lease/teardown and read-only remote presentation. Multiplayer commands/canvas binding and actual client acceptance remain pending; do not repeat AKT723 or insert dedicated ghosts/time trials.

## Session handoff log

### 2026-10-18 13:18 CEST (Europe/Oslo) — Codex / main

**Milestone:** M0; one local input/timing/lifecycle feasibility slice, plus reproducible probes.

**Files changed:** `addon/AzerothKart/{Track,Physics,Input,Loop,UI,Core}.lua`, both TOCs and addon readme; test runner and seven test files; Python validation/Lua harnesses, pinned test dependency and text attributes; README/CHANGELOG; architecture/API/feasibility/test/roadmap/progress docs; manual client/network checklists and the empty network CSV ledger. Existing roadmap gates remain open except the executed offline-validator criterion.

**Tests actually run and final results:**

| Command/check | Result and scope |
|---|---|
| `python scripts/validate_project.py` | PASS — 25 expected paths, TOC order/discovery markers, protocol docs, local links and ledger structure; no Lua runtime executed by this command |
| `python scripts/test_lua.py` | PASS — Lua 5.1 and 5.4 via Lupa 2.8; 14 files parsed and 7 tests run in each; includes 10k-tick/three-cadence replay and mocked lifecycle tests |
| `python -m compileall -q scripts` | PASS — Python script parsing |
| `git diff --check` / staged equivalent | PASS — whitespace checks after consistent text endings |
| Documentation check by delegated agent | PASS — 27 manual command lines fit 255 characters, local links resolve, CSV has 60 unique header fields and no measurement rows |
| `python scripts/test_with_lua54.py` | Optional Linux shared library unavailable on Windows; runtime execution NOT RUN through this path. Full Lua 5.4 suite executed through Lupa above. |
| Native `lua tests/run.lua` | Native interpreter absent from PATH; standalone CLI NOT RUN. The same entry point was executed in both actual embedded Lua runtimes above. |
| WoW F0/F1/F2/F5 and network F4 | NOT RUN / PENDING — no live client session or peer measurements |

**Measured offline baseline:** physics v2 on an open analytical plane: 50% speed in 39 ticks (0.650 s), top speed in 78 ticks (1.300 s); brake from 200 units/s crosses zero after 47 ticks (0.7833 s), path length 75.322 units including that final step. These are simulation measurements, not client handling ratings. UI test double: 6 UI frames, 99 textures, 3 font strings; counts unchanged through 1,001 updates and reopen cycles; 0 propagation setter calls in mocked combat. Bootstrap frame and template internals excluded.

**Evidence:** ignored `local-artifacts/m0-2026-10-18-validation.txt` and `local-artifacts/m0-2026-10-18-lua.txt`; reproducible tests in the committed source. A new handling assertion initially used exact x equality despite `cos(pi/2)` floating error; it was corrected to a small numeric tolerance, then both complete suites passed. A mixed-line-ending whitespace failure was corrected; final diff checks pass. Initial system runtime/dependency discovery failures did not execute Lua; the pinned local runtime then enabled both suites.

**Limitations:** manual tests and F4 gates remain pending as listed above. Any mouse-down now stops capture because a rectangle hit-test cannot identify an overlapping UI's focus. Actual Start/event ordering and combat release are client acceptance requirements. M0 does not imply production race timing, laps, ghosts, multiplayer or content readiness.

**Next exact task:** installed-client M0 identity and input/combat safety smoke (client checklist sections 1–2), then record observations before selecting another slice.

**Git implementation:** `be33176`; original scaffold `98bd16a`; local only, no force push or release.

### 2026-10-18 17:23 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** proceed with M0 client-checklist sections 1–2 and apply the owner's clarified rule: combat ends the game, closes the window and labels current results interrupted. No broad race/multiplayer engine was added.

**Implementation commit:** `6e20ec0` — `fix: close kart sessions when combat interrupts`.

**Files/behavior:** UI.lua now records one terminal `UI.result` (interrupted status, reason, stopped tick), closes on combat from event/key/OnUpdate paths and emits `Game interrupted by combat` once. OnHide preserves a prior terminal reason; deliberate reopen retains the note, new Start clears it. Actual standings do not exist in M0, so placements are not fabricated; the future final-placement rule is recorded in ADR 0006, DECISIONS/GAME_DESIGN/AGENTS and related scoped docs. Added regression assertions for closure, frozen tick, duplicate notifications, retained reason/reopen, no auto-resume and zero mocked combat propagation calls.

**Deployment:** owner instructed proceeding with live sections 1–2; the tested probe was installed directly into `_classic_beta_/Interface/AddOns/AzerothKart` using the normal filesystem approval mechanism. There was no prior AzerothKart install. All nine source/installed SHA-256 values matched both on install and the later read-only verification. Evidence is in workspace `artifacts/AzerothKart/20261018-170909/`; no other addon or SavedVariables file was edited by deployment. No push, tag, release or network traffic.

**Actually executed:**

- `python scripts/validate_project.py`: PASS, 25 expected paths plus TOC/docs links/ledger.
- `python scripts/test_lua.py`: PASS, 14 parsed Lua files and seven executed tests in each of Lua 5.1/5.4 (Lupa 2.8), including the new terminal-combat regressions.
- `git diff --check` and staged equivalent: PASS.
- Read-only installed/source SHA-256 verification: PASS, nine files.
- Actual Forever UI/commands through the [computer-use skill](C:/Users/bakke/.codex/plugins/cache/openai-bundled/computer-use/26.1013.40934/skills/computer-use/SKILL.md): successful addon startup/metadata, basic rendering/Start, idle Escape/Close/reopen/Enter-chat/Stop/Alt-Tab checks. Detailed sanitized output: [live evidence](evidence/2026-10-18-m0-client.md). Personal screenshots/chat were not committed or published.
- Human actual-combat test: owner reported, "Window closed on combat and game interrupted by combat appears. wow controls work." Record as a user-observed combat smoke, not an independently instrumented taint or duplicate-message audit.

**Client findings:** `GetBuildInfo()` = `1.60.1 70450 Oct 15 2026 16001`; project ID 18; Camelot TOC; addon version 0.0.1; enabled without an out-of-date notice. Required keyboard/text-focus/combat APIs and registered events available. IsGameWindowFocused and IsWindowFocused are nil. Existing unknown-key handling stopped an idle Alt-Tab trial after >=5 seconds away; no guessed focus getter was substituted. Local build-matching UI/API source was inspected read-only to confirm no known public application-focus getter/event; it was not copied into this repository or addon.

**Metrics/scope:** short stopped-run live sample: frames=1871, ticks=534, maxElapsed=0.0310, droppedSeconds=0, hitchFrames=0, explicit UI counts 6/99/3. One closed-window whole-client FPS sample was 207.6124420166 at uiScale=1/useUiScale=0. These are not sustained driving, addon CPU, scaling or long-session performance passes. HUD throttling left 528 visible when stopped probe/state had 534; this small display lag is recorded as a known M0 observation. A single synthetic key tap gave no clearly measurable movement, so the agent did not mark held driving/handling passed.

**Pending/coordination:** the agent stopped UI input for the owner's manual test. Real combat closure/message/working controls are confirmed by the owner's direct report. The owner then instructed skipping simultaneous W/Up because the keyboard cannot hold that pair; record SKIPPED, not pass/fail, with offline coverage retained. No further special combinations were requested. Repeat-notification count, combat reopen/retention, explicit in-combat Start refusal and full taint auditing are not inferred from the brief report. The subsequent ordinary checks below cover more UI/lifecycle behavior; unrun cases remain distinguished.

**Next exact task:** the M0 timed driving/performance sample in client-checklist section 3, before selecting an M1 slice.

### 2026-10-18 17:33 CEST — completion of this client-check run

After the owner's test reply, the agent performed ordinary M/map-key release, canvas-click release, Alt-Z hide/show and `/reload`. The map opened on the first M while capture stopped; canvas click stopped; UI hide/show did not resume racing. Reload completed with the kart window hidden. A local `/akart probe` then reported frames=0/ticks=0, active=false, stopReason=Not started, UI counts 6/99/3, no event-registration failures and input APIs available. Chat accepted and executed the local probe after reload. No character movement/combat or third-party chat was automated.

Updated README, client checklist, API/feasibility ledgers, architecture and [actual-client evidence](evidence/2026-10-18-m0-client.md) distinguish observed core startup/control/combat/reload smoke from remaining unrun cases. Simultaneous aliases are skipped by owner instruction, not a blocker. Actual logout/login/world transition and persistence sentinel work were not performed; no claim of full M0 completion. The existing combat implementation remained unchanged during live checks and still matches all nine installed files by SHA-256.

Final structural/doc-link/ledger and whitespace checks passed. Lua code has not changed since the complete Lua 5.1/5.4 suite passed and implementation commit `6e20ec0`. The session leaves the live kart window hidden and capture inactive. No push or release.

### 2026-10-19 01:28 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, one timing-evidence slice while the actual-client driving gate is unavailable. Confirmed canonical remote `https://github.com/PhilForever/AzerothKart.git`, branch `main`, clean initial status and prior head `3b02641`. Read canonical docs/ADRs and existing source/tests/scripts. No `Wow*`/`Battle*` process was found; no client was launched or controlled.

**Changes:** `Loop.lua` accumulates valid delivered elapsed in `elapsedSeconds`. The explicit six-line probe adds `activeFrameSeconds`, `simulatedSeconds=steps*dt` and `callbackHz=frames/elapsedSeconds` (zero before elapsed). `UI.Stop` freezes the clock including its fractional remainder; fresh Start creates a new clock. Thus stopped samples retain `elapsedSeconds ≈ steps*dt + droppedSeconds + accumulator`. Start/Stop immediately refresh the existing HUD, addressing the prior visible 528/probe 534 discrepancy. During driving the HUD remains bounded at quarter-second simulation intervals. No new frames/textures/font strings, automatic driving or periodic chat reports were added.

**Documentation:** architecture/API/feasibility/testing docs and client-checklist section 3 now define exact duration/cadence semantics and three independent-timer samples, immediate stopped tick agreement, unchanged delayed/reopened probes and fresh Start reset. Corrected stale feasibility prose that still requested the owner's skipped simultaneous W/Up case. README/CHANGELOG distinguish the source update from the historical installed probe. Roadmap acceptance boxes remain unchanged.

**Actually executed:**

| Command/check | Result and scope |
|---|---|
| `python scripts/test_lua.py` | PASS — Lua 5.1 and 5.4 through pinned local Lupa; 14 files parsed and all seven tests executed in each runtime. Synthetic 60-second schedules at 30/60/144 Hz each execute exactly 3,600 ticks with complete elapsed/drop/residual accounting. |
| New mocked timing/HUD assertions in `tests/test_ui.lua` | PASS within both complete suites — zero metrics before Start; immediate fresh/final HUD; frozen stopped/reopened clock and probe; retained fractional remainder; fresh clock replacement; five-step hitch bound; no periodic chat. Existing allocation regression remains 6 UI frames / 99 textures / 3 font strings across 1,001 updates and reopen cycles. |
| `python scripts/validate_project.py` | PASS — 25 expected paths, synchronized TOCs, protocol docs, local links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Read-only delegated timing/code review | No blocking findings; preserved accumulator cannot advance while inactive and is replaced on Start. |
| `Get-Command lua,luajit,luac -ErrorAction SilentlyContinue` | No native executable found; standalone `lua tests/run.lua` NOT RUN. Both actual embedded Lua runtimes above executed the same entry point. |
| WoW F1/F2/F5 and network F4 | NOT RUN — no client process or peer experiment. New timing/HUD layout, three timed drives, scaling/stress, held-input/lifecycle edge cases and persistence remain pending. |

The first integration run exposed a test-double instrumentation error: its fallback returns a function for unknown fields, so the new HUD-write counter needed `rawget`. Corrected that fixture counter; both full runtime suites then passed. No production change was required for that failure.

**Risks/limits:** cumulative delivered callback time and callback cadence are not an independent wall clock, separately sampled whole-client FPS or addon CPU cost. Simulation time excludes dropped time. No handling/performance rating is inferred from synthetic schedules. The prior 2026-10-18 installation remains unchanged and does not contain these source changes. No migration, transport, race/standings, content or deployment work occurred. No API contradiction or new product decision arose.

**Git:** focused commit intended as `fix: preserve complete M0 timing samples`; see `git log` for its hash. Repository-local PhilForever identity was reverified. No push, tag, release, deployment or automation was performed.

**Next exact task:** harden the local install helper against nested repeat copies with backup/hash verification and workspace fixture tests; preserve the manual M0 gate above.

### 2026-10-19 02:06 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, complete the prior handoff's repeatable developer-install task using workspace fixtures only. Confirmed correct remote, branch `main`, clean initial status and prior head `2825ba3`. Read the current canonical handoff, acceptance criteria, architecture/ADRs and relevant source/tooling. No `Wow*`/`Battle*` process was found; no client was launched or controlled.

**Changes:** rewrote `scripts/install_local.ps1` as an explicit AddOns-target installer with `-Overwrite` for existing targets and standard `-WhatIf`/`-Confirm`. It copies source files directly into the addon folder, preserves unknown extras and verifies source/installed SHA-256 values. Existing addon files and empty directories are copied into an isolated backup and verified before target writes. Ignored run directories contain `source.csv`, optional `before.csv`/`before/` and `install.json`; status, stage, backup verification and copy-start markers distinguish successful verification from failure. Missing/overlapping/conflicting paths and observed reparse entries are rejected; source/target snapshots are rechecked before copying. A target appearing after fresh-install preflight is rejected rather than overwritten without a backup.

The helper performs no deletion or automatic rollback. A failure after copying starts can leave a partial target, so its error points to the retained backup and manifest. Added `tests/test_install_local.ps1` with literal-path and isolated AddOns/WTF sentinel fixtures, preflight/preview refusal, repeated installs, empty prior target, preserved extras, locked-file failures, injected backup/target hash failures, concurrent-target refusal, and a manual recovery rehearsal that preserves the failed target and verifies restored old files while acknowledging new files left behind. No real WTF or installed addon files were touched. Updated README/CHANGELOG, release/test documentation and structural validation (now 27 required paths). No roadmap boxes changed.

**Actually executed:**

| Command/check | Actual result and scope |
|---|---|
| `pwsh -NoProfile -NonInteractive -File tests/test_install_local.ps1` | PASS — PowerShell 7.6.5, 18 cases; 3 junction fixtures SKIPPED because `New-Item -ItemType Junction` returned Access denied in the sandbox. No junction rejection pass is claimed. |
| `powershell.exe -NoProfile -NonInteractive -File tests/test_install_local.ps1` | Runtime NOT RUN — Windows PowerShell returned `AuthorizationManager check failed` before the suite executed. No execution-policy change or bypass was attempted. |
| Windows PowerShell `Parser.ParseFile` on helper and fixture suite | PASS — both scripts parsed in 5.1.26100.9711. This is syntax evidence, not a 5.1 runtime pass. Read-only `Get-ExecutionPolicy -List` also reported registry access denied, so the effective policy was not established. |
| `python scripts/test_lua.py` | PASS — 14 Lua files parsed, all seven tests executed in each of Lua 5.1/5.4 through local Lupa. No addon Lua changed in this slice. Standalone native `lua` was absent; native CLI NOT RUN. |
| `python scripts/validate_project.py` | PASS — 27 expected paths, TOCs, protocol docs, Markdown links and network ledger. |
| `python -m compileall -q scripts` | PASS — Python script parsing. |
| `git diff --check` | PASS — whitespace checks. |
| WoW F1/F2/F5, live installation and network F4 | NOT RUN — no client process, no installation or peer experiment. Historical client results are unchanged. |

**Evidence:** ignored `local-artifacts/install-tests-ps7-20261019.log` and `install-tests-ps51-20261019.log`. Final successful fixture root: `local-artifacts/install-tests/c0c483a78c6746439aa7ed5f7ba3475f/`. Synthetic prior/failed installs and manifests are retained there for inspection. Early runs exercised smaller subsets before the final 18-case run; they do not substitute for the explicit skipped/runtime limits above.

**Risks/limits:** file overlay with verified backup, not an atomic deployment or concurrency/security guarantee. Unknown extra files are retained; restoring old files does not remove newly added files. Stop other editors/installers during a real operation. Junction rejection remains unexecuted in this sandbox, PowerShell 5.1 runtime acceptance remains pending, and client behavior still requires direct play. No API contradiction, migration or product decision arose. Source timing/HUD changes are still not installed.

**Git:** focused commit intended as `fix: verify and back up repeatable local installs`; inspect `git log` for its hash. PhilForever repository-local identity reverified; global config unchanged. No push, tag, release, actual deployment or automation.

**Next exact task:** the M0 F1 actual-client timing sample described above: three human-controlled 60-second drives after an authorized source install, with honest pending status while no client/tester is available.

### 2026-10-19 02:11 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, one existing lifecycle defect while the actual-client timing gate is unavailable. Confirmed canonical remote, branch `main`, clean initial status and prior head `fc7f339`; read current handoff, acceptance criteria, architecture/ADRs and relevant source/tests. No `Wow*`/`Battle*` process was found. No client was launched or controlled.

**Reproduction:** after a mocked combat interruption, the first reopen retained the note, but a second toggle close or Close button called `UI.Stop("Closed")`, replacing the visible reason while leaving `UI.result` intact. Start refusal for combat, text focus or missing input capability likewise replaced the note. This contradicted the already accepted ADR 0006 retention rule; no new product decision or API behavior was needed.

**Changes:** `UI.Stop` keeps an interrupted result's reason authoritative. A small Start-refusal formatter displays the retained note plus the actual refusal. Existing guards, controls, terminal result and fixed-step simulation are unchanged; only a fresh accepted Start clears the result/note. `tests/test_ui.lua` now exercises repeated toggles/Close, hidden/inactive stops, combat/text/event/API refusals, frozen result identity/tick/state/clock/HUD, stable object counts, one unsolicited interruption message, no automatic resume, and a fresh Start followed by ordinary Stop/Close with no stale note. Updated architecture/feasibility/test docs, README/CHANGELOG and a precise pending manual follow-up. No new module, UI objects, race placements, transport or migration.

**Actually executed:**

| Command/check | Actual result and scope |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before the UI fix | Expected FAIL — added regression reproduced `toggle close 1: interruption stays visible and authoritative` in `test_ui.lua`; other six tests passed. |
| `python scripts/test_lua.py` after the fix | PASS — all 14 Lua files parsed and all seven tests executed in each of Lua 5.1/5.4 through Lupa, including the retained-note regressions and existing 10k-tick replay/timing tests. Mock UI allocation counts remain 6 frames / 99 textures / 3 font strings; no mocked propagation setter in combat. |
| `python scripts/validate_project.py` | PASS — 27 expected paths, TOCs, protocol docs, Markdown links and header-only network ledger. |
| `git diff --check` | PASS — whitespace checks. |
| Native `lua tests/run.lua` | NOT RUN — no `lua`, `luajit` or `luac` executable found. The actual embedded Lua runtimes above executed the same suite. |
| Actual-client F1/F2/F5 and network F4 | NOT RUN — no client process or peer measurement. Historical owner combat smoke remains observed; repeated-note/rejected-restart client behavior is not inferred from mocks. |

**Limits:** all 2026-10-19 source changes remain uninstalled; the existing 2026-10-18 addon install is untouched. The longer refusal-plus-note layout still needs client observation. No fresh PowerShell installer runtime claim is made in this Lua-only slice; the preceding session's 18-pass/3-skipped PowerShell 7 evidence and blocked PowerShell 5.1 runtime remain scoped to that tooling task. Roadmap acceptance boxes are unchanged.

**Git:** focused commit intended as `fix: retain combat outcome through rejected restarts`; inspect `git log` for its hash. PhilForever repository-local identity reverified; no global config change, push, tag, release, deployment or automation.

**Next exact task:** M0 F1, three human-controlled 60-second client samples after an authorized source install. The precise retained-note close/reopen/refused-Start follow-up is also prepared in client-checklist section 2 and remains pending. Do not request the owner's skipped simultaneous W/Up combination.

### 2026-10-19 02:26 CEST (Europe/Oslo) — Codex / main, live continuation

**Objective:** continue the existing M0 client gate after the owner reported WoW running. Confirmed clean `main`, canonical remote and HEAD `2a5b8e8`; read the handoff/acceptance criteria and [computer-use skill](C:/Users/bakke/.codex/plugins/cache/openai-bundled/computer-use/26.1013.40934/skills/computer-use/SKILL.md). The shell process scan again returned no matches, but the desktop inventory returned one running `WowB.exe` client window. Activated that returned window and observed the logged-in client. Added the discovery limitation to AGENTS so future runs do not declare the desktop unavailable from an empty shell scan alone.

**Deployment:** validated source first. Only installed `Loop.lua`/`UI.lua` differed; the other seven files matched. The PowerShell helper `-WhatIf` could not load because the script was unsigned. No execution-policy change was made and that script was not executed. Using the normal filesystem approval mechanism, a one-off Python file operation backed up the full prior AzerothKart tree, verified the backup, copied only those two files, then verified all nine installed hashes against source. Artifact: workspace `artifacts/AzerothKart/20261019-022106-763673/install.json`, with source/before/installed hash maps and prior files under `before/`. Independent read-only verification at 02:24:17 +02:00 confirmed nine matches. No other addon or WTF/SavedVariables files were edited for deployment.

**Actually observed:** normal local `/reload` completed; `/akart` opened the primitive track/kart inactive with `Sample: 0.0s`. A grouped read-only `/run` baseline plus explicit `UI.ReportProbe()` showed client `1.60.1`, build `70450`, interface `16001`, selected TOC `Camelot`, focus API false, all timing counters zero, active false/Not started, UI counts 6/99/3, no event-registration failures and required input capability flags true. One whole-client FPS sample with the stopped kart window open was `230.10543823242`; uiScale=1/useUiScale=0, combat=false, capture resolution 1920×1080. This is not CPU profiling, sustained driving or full F1/F2 acceptance. No AzerothKart error popup was visible; a full taint audit was not run. Sanitized evidence is in [2026-10-19 client observations](evidence/2026-10-19-m0-client.md); no personal captures/chat were committed.

**Executed checks:**

| Command/check | Actual result |
|---|---|
| `python scripts/validate_project.py` | PASS — 27 expected paths/TOCs/docs links/ledger; rerun after evidence/doc updates. |
| `python scripts/test_lua.py` | PASS — 14 Lua files parsed, all seven tests in each of Lua 5.1/5.4 via Lupa. No addon source changed during the live run. |
| Backup/source/installed SHA-256 checks | PASS — verified old addon backup and nine installed matches, followed by an independent nine-file comparison. |
| PowerShell installer preview | NOT RUN — unsigned-script SecurityError prevented loading; no policy change. This is distinct from the prior fixture results. |
| Normal client reload and stopped new-HUD/probe baseline | OBSERVED — precise scope above; no new gameplay/performance pass. |
| Three human-controlled timed drives; extended combat-note sequence; scaling/stress; F5 sentinel/logout/restart; F4 peer tests | PENDING / NOT RUN — no completed result recorded. |
| `git diff --check` | PASS — final whitespace check. |

**Handoff:** asked the owner to perform the first normal 60-second kart drive and report completion/responsiveness. Keyboard/mouse input remains untouched while waiting. Blank drive rows in the evidence ledger mean unmeasured. Do not infer results, repeat the skipped W/Up combination, synthesize combat, or automate character movement. No gameplay milestone/roadmap checkbox advanced. No push, tag, release, network traffic or automation.

**Git:** focused documentation/evidence commit intended as `docs: record updated M0 install and live baseline`; inspect `git log` for its hash. The installed addon source remains the tested files from `2a5b8e8`.

**Next exact task:** capture the owner's first stopped timed-drive probe, then complete samples 2 and 3 before choosing further M0 work.

### 2026-10-19 02:35 CEST (Europe/Oslo) — Codex / main, first human drive

**Objective:** capture the owner's `Done` reply to the first requested near-minute kart drive. Confirmed clean `main`, prior HEAD `364a245`, read current handoff/checklist, selected the unique returned WoW desktop window and activated it. No installed/source code changed, no reload or new deployment.

**Observed sample 1:** owner-confirmed completion, with no separately reported handling rating or external timer. Stopped probe: frames=13171, ticks=3492, maxElapsed=0.0700, droppedSeconds=0.0000, hitchFrames=0, accumulator=0.01200, activeFrameSeconds=58.2120, simulatedSeconds=58.2000, callbackHz=226.26; UI=6 frames/99 textures/3 font strings; active=false, stopReason=Mouse click released controls, event failures=none. Build 70450/interface16001/Camelot and capability flags unchanged. Kart displacement/rotation from spawn was visible; stopped HUD tick matched 3492. Actual stop reason is mouse-click release; held Escape is not inferred from the brief reply.

**Delayed lifecycle check:** ordinary `/akart` closed the window, which was visibly hidden; a second `/akart` reopened it inactive. A subsequent `/akart probe` retained all numeric fields and the same HUD tick without auto-resume. Only the ordinary stop reason changed to `Closed`. Local chat commands worked; no WoW character movement/combat was automated. Personal screenshots/chat were not committed.

**Evidence/checks:**

- Python arithmetic on printed values: PASS — `3492 / 60 = 58.2000`; `58.2000 + 0.01200 = 58.2120`; `13171 / 58.2120` rounds to `226.26`. This verifies printed internal accounting, not independent wall-clock accuracy or addon CPU cost.
- `python scripts/validate_project.py`: PASS — 27 expected paths, TOCs, links and ledger.
- `python scripts/test_lua.py`: PASS — actual embedded Lua 5.1/5.4, all 14 Lua files parsed and seven tests each; no Lua source changes this session.
- `git diff --check`: PASS — whitespace.
- Sample 2/3, external timer/handling rating, scaling/stress, extended combat-note/remaining F2 routes, F5 persistence and F4 networking: PENDING / NOT RUN; not established by one drive.

Updated the sanitized [evidence ledger](evidence/2026-10-19-m0-client.md), F1 notes and manual checklist. Checked only the roadmap's basic render-and-drive criterion, supported by the owner's completion and actual moved/rotated kart with advancing ticks. Frame-performance/focus/full M0 gates remain unchecked.

**Known visual follow-up:** the stopped kart was beyond the gray primitive road. Existing source confirms the painted tile oval and analytical drivable annulus differ: for example `(400,440)` is drivable while the gray tiles reach at most y=425. Keep visual/collision alignment as a prototype follow-up; no road/grass handling acceptance is claimed. Do not change the installed probe between the remaining measurement samples.

**Handoff:** second near-minute drive requested, UI input left untouched. Source remained `2a5b8e8` at this point; no tag, push, release, deployment or network traffic. These first-sample documentation edits were still uncommitted when the second reply arrived; they are preserved in the focused follow-up below.

**Next exact task:** capture sample 2's stopped probe, then request/capture sample 3 and update the F1 evidence before choosing further work.

### 2026-10-19 02:43 CEST (Europe/Oslo) — Codex / main, second drive and stopped-window combat fix

**Objective/state:** owner replied `Done.` to sample 2. Confirmed canonical `main`, HEAD `364a245`, and five existing first-sample documentation edits; preserved them. Selected the unique returned WoW window through the computer-use skill. Sample 2 showed a displaced/rotated kart and stopped HUD speed 179, tick 3756, Sample 62.6 s. Probe: frames=14326, ticks=3756, maxElapsed=0.0700, droppedSeconds=0.0000, hitchFrames=0, accumulator=0.00200, activeFrameSeconds=62.6020, simulatedSeconds=62.6000, callbackHz=228.84, UI counts=6/99/3, active=false, stopReason=Mouse click released controls; identity/capabilities unchanged. A delayed local `/akart probe` retained the same numbers/reason. External duration and handling feedback were unreported.

**Unplanned live failure:** during this stopped readback the character was attacked and died while the window stayed visible. No character movement/combat or death-dialog action was automated. The event was not instrumented, so do not declare an API contradiction or claim the active-drive path failed. Source inspection found `HandleEvent` discarded combat-start events whenever inactive, and `InterruptCombat` returned before hiding an inactive window. Stopped-window closure is a real missing path consistent with the observation. Further driving is on hold for user review/live verification; no third drive was requested.

**Plan/change:** preserve both measured samples, reproduce the inactive closure failure offline, then repair that path without changing physics or timing. Handle combat-start events before the active guard; inactive interruption hides an existing shown window, preserving the completed sample/result/HUD/reason and printing nothing. Existing active-drive terminal result/once-only note remains unchanged. Inactive OnUpdate remains idle so deliberate combat-time reopen can inspect the note and Start refusal. Added regressions for pre-load/nil window, never-started/stopped/interrupted UI, duplicate event/direct calls, every clock/state field, UI counts, guarded propagation, no duplicate output and no reopen/resume. Architecture/checklist/feasibility/evidence/README/changelog aligned. Only the basic render-and-drive roadmap box advances; M0 remains open.

**Actually executed:**

| Command/check | Actual result |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before production fix | Expected FAIL — `never started: combat hides stopped window`; new regression reproduced the gap. Other six tests passed. |
| `python scripts/test_lua.py` after fix | PASS — 14 Lua files parsed, seven tests each in actual embedded Lua 5.1/5.4; seeded 10k-tick replay/timing/active combat plus new inactive fixtures. Counts 6/99/3; zero mocked propagation setters in combat. |
| Python arithmetic on both printed samples | PASS — sample 2: `3756/60=62.6000`; `62.6000+0.00200=62.6020`; `14326/62.6020` rounds to `228.84`. Sample 1 accounting also rechecked. Not independent timing/CPU evidence. |
| `python scripts/validate_project.py` / `git diff --check` | PASS — final structural/docs/ledger and whitespace checks. |
| Read-only delegated code/test/evidence review | No blocking findings; narrow stopped-result preservation and pending live scope verified. |
| Backup/install SHA-256 verification | PASS — prior entire AzerothKart backed up/verified; only UI.lua copied, all nine installed files matched tested source. An independent read-only nine-file hash comparison also passed at 02:42 CEST. Manifest below. |
| Native `lua tests/run.lua` | NOT RUN — no standalone runtime available; actual embedded runtimes above executed the suite. |
| Reload/live verification of this fix; sample 3; held-input/extended combat/scale/stress/F5/F4 | NOT RUN / PENDING. Running client still has previous in-memory code. |

**Deployment:** normal filesystem approval granted. Reused the inspected one-off verified Python file copier because the PowerShell helper's historical unsigned-script block remains; no policy/security change. Artifact: workspace `artifacts/AzerothKart/20261019-024015-566233/install.json`, verified prior files in `before/`. No other addon or WTF/SavedVariables edited. No reload after fix; client input left untouched for owner recovery. The timing/physics code was not changed, so both old-source samples remain valid with their recorded version context.

**Git/handoff:** PhilForever repository-local identity reverified; focused commit intended as `fix: close stopped kart windows when combat begins` (inspect `git log` for hash). Includes the preserved first-sample evidence edits. No push, tag, release, network traffic or automation. Next exact task is the reload/stopped-window combat check above before sample 3; visual/collision alignment remains a separate M0 prototype follow-up.

### 2026-10-19 02:51 CEST (Europe/Oslo) — Codex / main, primitive road alignment

**Owner steering/objective:** owner said to continue elsewhere instead of focusing on combat/dying. Confirmed canonical remote, clean `main`, HEAD `ae6fed0`; read handoff/acceptance/docs and existing source. Selected one independent M0 fix: the visible centerline-tile road did not match the analytical drivable annulus. Prior client checks remain unrun and are not falsified or discarded. No further drive/combat test requested.

**Plan/change:** retain physics and the object budget, replace the static road drawing with bands derived from Track radii, compare actual generated rectangles with collision geometry, then install tested source and document actual scope. UI.lua fills 64 outer gray ellipse bands (BACKGROUND), masks the island with 32 grass bands (BORDER), and keeps marker/kart in ARTWORK/OVERLAY. Total remains 6 frames/99 textures/3 font strings. Geometry is built once during Create; moving updates do not recreate it. The vertical raster uncertainty is at most 3.40625 world units outside and 2.625 inside, not an exact vector boundary or horizontal-error guarantee. Track/Physics/Input/Loop/Core and TOCs are unchanged.

**Tests/evidence:**

| Command/check | Actual result |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before renderer fix | Expected FAIL — new test reproduced `road uses 64 outer bands and 32 island bands`; other six tests passed. |
| `python scripts/test_lua.py` after fix | PASS — 14 Lua files parsed, seven tests in each embedded Lua 5.1/5.4. Actual mock rectangles agree with `Track.isDrivable` at 92,853 grid points outside a 3.5-unit vertical boundary margin; `(400,440)` is painted road. Existing 10k-tick replay, timing, lifecycle and 1,001-update/reopen allocation checks pass. |
| `python scripts/validate_project.py` | PASS — 27 paths, synchronized TOCs, docs links/protocol and header-only transport ledger. |
| `git diff --check` / staged equivalent | PASS — whitespace checks. |
| Backup/install source SHA-256 checks | PASS — entire prior AzerothKart backed up/verified, only UI.lua copied, all nine installed files matched tested source. Independent read-only comparison also performed. |
| Native `lua tests/run.lua` | NOT RUN — standalone interpreter absent; actual embedded runtimes above executed the suite. |
| Client reload/new renderer display/scale/performance | NOT RUN — WoW was available in desktop inventory, but input actions were rejected by the helper's user-input freshness check. Refreshed once; ongoing interference remained. No reload command was typed/submitted; client left alone. |
| New driving/combat/F5/F4 checks | NOT RUN — outside this owner-directed slice. No character or peer actions automated. |

Delegated geometry design/test authoring supported the parent implementation. A later delegated review attempt failed because model capacity was unavailable; no successful final independent-review claim is made. Parent inspected code/tests and executed the complete suites. Updated architecture, track raster bounds, test plan, feasibility/manual steps, README and changelog; roadmap acceptance boxes stay unchanged.

**Deployment:** normal filesystem approval granted. Inspected one-off Python copier preserved the prior addon under workspace `artifacts/AzerothKart/20261019-024844-773041/before/`; hashes/status recorded in `install.json` beside it. Only AzerothKart UI.lua changed in the installed addon; no other addon or WTF/SavedVariables touched. Source is installed on disk, not observed reloaded. Existing live drive evidence remains historical under its original renderer.

**Handoff:** focused commit intended as `fix: align primitive road with analytical track bounds`; inspect `git log` for hash. No push, tag, release, network traffic or automation. Next exact task is the bounded opt-in render-cost probe above; do not resume repeated combat testing as the next task.

### 2026-10-19 07:35 CEST (Europe/Oslo) — Codex / main, bounded optional profiling

**Objective/state:** continued the existing M0 handoff on clean `main`, canonical remote, HEAD `865e187`. Inspected current docs/ADRs/source/tests; retained the owner's direction to continue independent work instead of combat/death testing. One slice: optional bounded simulation/render timer spans with a pure aggregator and exact client probe steps. No physics/input/track/loop behavior or roadmap acceptance boxes changed.

**API evidence/plan:** local primary generated build-70450 documentation (`research/upstream/wow-ui-source-forever-70450/.../FrameScriptDocumentation.lua:528–539` in parent workspace), pinned mirror commit `172a387e3ab85b26e6640d3058d5ec1e6ccd4c63`, defines `debugprofilestop` as elapsed milliseconds since the shared `debugprofilestart` reference. Implement guarded read differences without resetting that reference; keep disabled by default, cap attempts, preserve stopped results and report only on request. Runtime availability remains unprobed; provenance/steps are in CLIENT_API and the manual checklist.

**Changes:** added pure `Performance.lua` with nine scalar count/total/max fields and a 600-attempt cap; rejects malformed/nonfinite/negative/backwards readings and finite-total overflow. Both TOCs load it before UI. Core routes `/akart perf [on|off]` separately from the unchanged six-line ordinary probe. Arming while stopped validates one guarded read; a successful fresh Start creates a new window. Eligible updates take three reads around `Loop.advance`, then render/HUD work. After 600 attempts there are no more profiler reads; simulation continues. Stop/close/reopen retain aggregates; off retains them until the next Start. Active configuration changes are refused. Protected calls contain reader/validation failures, count them against the cap and never change driving. No new UI widgets, per-frame chat, sample arrays, saved settings or timer resets.

These are instrumented elapsed spans, including probe overhead. They omit preceding input/focus guards, final aggregation/report formatting and native GPU work, and do not establish exclusive addon CPU or whole-client FPS. Backwards checks cannot detect every external shared-timer reset; output is advisory. No counterfeit performance or timer-security claim is made.

**Actually executed:**

| Command/check | Actual result |
|---|---|
| Local generated API contract/provenance inspection | VERIFIED SOURCE — milliseconds/shared reference as above; no live availability pass. |
| `python scripts/test_lua.py` | PASS — 16 Lua files parsed and eight tests each in Lua 5.1/5.4 through pinned Lupa. Pure totals/maxima/zero-resolution/overflow/error budgets, full existing determinism/geometry/lifecycle suites and new UI profiling integration all execute. |
| New UI integration checks | PASS in both runtimes — zero reads off; one arm read + at most 1,800 window reads; 600 valid/invalid cap; no completion chat; stable 6/99/3 counts; frozen/restarted windows; same every-field state after identical 650-update profiled/unprofiled tape; throwing read/validation cannot stop driving. Mock phase values test accounting only. |
| `python scripts/validate_project.py` | PASS — 29 required paths, synchronized seven-module TOC order, docs links, protocol and header-only network ledger. |
| `git diff --check` / staged equivalent | PASS — whitespace checks. |
| Normal filesystem backup/install verification | PASS — old entire addon preserved/hash-verified; five changed/new files copied; all ten installed hashes matched source. Independent read-only comparison passed at 07:35. |
| Native `lua tests/run.lua` | NOT RUN — no standalone lua/luajit/luac command found. Actual embedded runtimes above ran the suite. |
| Actual client load, optional profiler availability/cost and analytical-band appearance | NOT RUN — desktop app/window inventory at 07:32 returned no WoW client; no launch/input/new drive attempted. |
| PowerShell installer fixtures, F5 persistence, F4 transport and additional combat | NOT RUN this slice — helper code unchanged; no peer/character/combat actions. |

Delegated API research, pure aggregator/tests and scoped manual docs; parent integrated/reviewed and ran both complete suites. Read-only integration review found no additional blocker after the parent fixed the thrown-validation attempt budget: errors before module commit must increment the UI attempt counter too. Added a specific regression; full suites then passed. No intentionally failing pre-implementation test run is claimed for this slice.

**Deployment:** source included two TOCs, Core.lua, Performance.lua and UI.lua; all other addon files unchanged. Normal filesystem approval granted; inspected one-off Python file copier updated its explicit ten-file/allowed-change guard and verified prior backup before writes. Artifact: parent workspace `artifacts/AzerothKart/20261019-073146-820718/install.json`, previous addon in `before/`. No other addon or WTF/SavedVariables modified. No runtime reload was possible/attempted because no client was returned. No push, tag, release, packet traffic or automation.

**Git/handoff:** PhilForever repository-local identity reverified, global settings untouched. Focused commit intended as `feat: add bounded opt-in performance probe`; inspect `git log` for hash. Next exact task is the actual-client startup/one optional profile window above. M0 and all unrun acceptance checks remain open; do not turn them into invented passes.

### 2026-10-19 ~09:02 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, actual startup and one bounded stationary performance window under the owner's explicit unattended-client authorization. Confirmed canonical remote/branch, clean initial tree, HEAD `38faab2` and local PhilForever identity. Read persistent handoff/criteria and inspected the affected source, tests and pinned build-matching API documentation. No avatar movement, resurrection/death-dialog action, combat setup or peer traffic was automated.

**Actual client evidence:** build 1.60.1/70450, interface 16001, Camelot TOC. Initial 1920×1080 capture, uiScale=1/useUiScale=0, separately read effective scale=0.71111112833023; one stopped whole-client FPS read=226.84307861328. The profiler armed successfully. Automated Start clicks did not start; the existing Start refused chat focus, then a single guarded delayed invocation started after chat closed. No input guard was changed or bypassed. No driving keys were supplied, so this is not human handling or the third F1 drive.

The first 600 eligible callbacks produced 600 valid readings, zero invalid: simulation avg/max 0.0119/0.0363 ms, render/HUD 0.0145/0.2027 ms, total 0.0264/0.2111 ms including instrumentation. Simulation continued past the cap, ending on Enter/`Other key released controls`: 7334 callbacks, 1959 ticks, 32.6520 active seconds, 32.6500 simulated, 0.00200 residual, zero drops/hitches, maxElapsed=0.0700 s, counts 6/99/3. Stopped/delayed/reopen results stayed frozen; disarming retained them. Fresh unprofiled Start was NOT RUN. [Full sanitized transcription](evidence/2026-10-19-m0-stationary-profile.md).

**Renderer failure and review stop:** observed thin horizontal seams. Build-matching generated signatures and NineSlice use supported guarded literal snapping setters; a one-off preview across all 99 existing canvas textures removed seams. An attempted source change applying them to only 96 road bands hid the road after reload. The all-99 preview restored it after that first failure. Moving the creation calls after color/geometry initialization still hid the road on a second reload; no second recovery preview was run. Initialization order is not established as the cause. Texture population/layer and timing differ, so no particular public API contract violation is proven. Stopped promotion and flagged the unresolved client behavior for review under the owner's policy. Removed only this run's UI/test experiments, restoring their exact HEAD content; no renderer change or experimental mock fixture is retained.

**Deployment/recovery:** each install preserved/hash-verified the current entire AzerothKart addon before replacing only UI.lua, then verified all ten source hashes. Parent-workspace manifests: `artifacts/AzerothKart/20261019-085011-749932/install.json` (first experiment), `20261019-085434-186481/install.json` (reordered experiment), `20261019-085619-881590/install.json` (restored original). Independent final comparison at 08:58:33 confirmed all ten files match restored source. Third normal reload restored the original road/island/marker/kart without another preview; probe and performance were fresh/zero/inactive. Final explicit readback: active=false, shown=false, performanceEnabled=false. Other addon/WTF/SavedVariables files were not edited by deployment; no push/tag/release/automation.

**Tests actually executed:**

| Command/check | Result and limits |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before experimental setters | Expected FAIL at new per-band snapping assertion; seven other tests passed. |
| Same command with new initialization-order assertion | Expected FAIL against the first implementation, then reordered. That asserted order did not establish client correctness. |
| `python scripts/test_lua.py` on both experimental variants | PASS — 16 files parsed/eight tests each in Lua 5.1/5.4; geometry 92,853 points, replay, allocation, missing/throwing setter fixtures. Actual reload still failed; these fixtures were removed with the rejected change. |
| `python scripts/test_lua.py` after restoring original source/tests | PASS — 16 files parsed/eight tests each in Lua 5.1/5.4 through local Lupa; final tested source matches installed files. |
| `python scripts/validate_project.py` | PASS — 29 expected paths, synchronized TOC order, docs links, protocol and header-only network ledger. |
| `git diff --check` and staged equivalent | PASS — final documentation whitespace checks. |
| Native `lua tests/run.lua` | NOT RUN — lua/luajit/luac absent from PATH; actual embedded runtimes above ran the suite. |
| Human handling/third F1 drive, fresh unprofiled Start, scale/stress/taint/F5/F4 | NOT RUN this slice; no invented pass. Further combat checks remain owner-deferred. |

**Final changes:** documentation and sanitized evidence only: README/CHANGELOG, architecture/track/API/feasibility/testing docs, manual client checklist and this handoff. Roadmap unchanged. Local focused evidence commit intended as `docs: record stationary profiler results and renderer review blocker`; use `git log` for its hash. **Next single task:** review the prepared isolated texture-population/timing probe before resuming renderer experiments. M0 stays open.

### 2026-10-19 09:07–09:20 CEST; resumed 13:54–14:07 CEST — Codex / main

**Milestone/objective:** M0, complete the reviewed road seam/visibility slice. The owner instructed continuing after the review stop and again after quota interruption. Canonical remote and branch `main` confirmed; initial HEAD `ce1b78c` was clean before the slice. Resume preserved this slice's uncommitted UI/tests/evidence. Repository-local PhilForever identity remains verified; no unrelated work was reset.

**Isolation:** changing only 96 existing bands to bias 0/snap false reproduced disappearance without reload. Hiding just the unique full-canvas grass exposed the gray road; showing it covered the road. Matching grass snapping also restored the road. In an independent fresh session, lowering only grass to `BACKGROUND,-1`, then applying band settings, kept the road visible without seams. These observations establish a grass occlusion/configuration problem; they do not prove native renderer batching mechanics or a public API violation. [Exact evidence and measured scales](evidence/2026-10-19-m0-road-layer.md).

**Implementation:** 11 presentation-only lines in UI.lua: explicit grass draw priority below the outer road, and optional guarded bias/snap setters after each band's color/geometry initialization. Geometry, Track/Physics/input/timing and marker/kart remain unchanged; no new objects or per-update configuration/output. Tests inspect relative priority, exactly 192 setter calls for 96 bands, unchanged grass snapping, missing/throwing optional APIs, unchanged geometry and no reconfiguration during updates/reopening.

**Actual validation:**

| Command/check | Result and scope |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before implementation | Expected RED at the new band assertion; 16 files parsed, other seven tests passed. |
| `python scripts/test_lua.py` before install and again after resume | PASS each time — Lua 5.1/5.4 through local Lupa, 16 files parsed/eight tests in each; includes 92,853-point geometry, 10k-tick replay, lifecycle, profiler and pooling regressions. |
| `python scripts/validate_project.py` | PASS — 29 paths, TOC order, Markdown links, protocol/header-only network ledger. |
| `git diff --check` and staged equivalent | PASS — final whitespace checks. |
| Installed/source SHA-256 | PASS — all ten files on install and independent comparisons at 09:20:08 and 13:54:48 CEST. |
| Controlled normal reload + read-only getters | PASS for recorded appearance — full road/island/marker/kart/controls, no horizontal seams, effective scale 0.72452831268311; all 96 bands bias 0/snap false; grass `BACKGROUND,-1`, unchanged bias 0.30000001192093/snap true. No texture preview after reload. |
| Native `lua tests/run.lua` | NOT RUN — lua/luajit/luac absent from PATH; both actual embedded runtimes above executed the suite. |
| Supported scales, idle/stress, full taint/input, third F1/handling, F5/F4 | NOT RUN this slice; M0 remains open and combat checks stay owner-deferred. |

**Installation:** only UI.lua replaced after verified prior-addon backup; ten source hashes verified. Parent-workspace manifest `artifacts/AzerothKart/20261019-091849-478523/install.json`, prior addon in `before/`. No other addon/WTF/SavedVariables edited by deployment. No push/tag/release/automation or network traffic.

**Quota/resume accounting:** quota interrupted the first post-install readback; the owner's later cropped image records a zeroed probe, not full appearance. After resuming, an already stopped 1,237-tick/20.6300-second sample was observed and transcribed before reloading. Its input history and independent duration are unknown; it is not this agent's drive or the third F1 sample. No progress or timed idle pass is inferred for the gap. A new controlled normal reload then verified the installed fix with fresh zero counters and counts 6/99/3. Close/reopen retained inactive counts; final readback active=false/shown=false/profiling=false. No avatar movement, combat or recovery was automated.

**Handoff:** code/tests, rendering/API/feasibility/testing documentation and sanitized evidence are aligned; roadmap unchanged. Focused local commit intended as `fix: remove road seams with explicit grass layering`; inspect `git log` for the hash. **Next exact task:** the 15-minute stopped/open idle sample in client-checklist section 3b. Keep remaining M0 gates pending; do not repeat the skipped W/Up or deferred combat checks.

### 2026-10-19 15:23–15:51 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, execute the prepared stopped/open idle check. Correct canonical remote/main and clean starting tree at `fbd3cc8` confirmed. Existing source/installed files were preserved; no installation or reload was needed. Repository-local PhilForever identity/useConfigOnly verified. One coherent evidence/probe-preparation slice; no new game mechanics.

**Client execution:** the first baseline at 15:24:38.330 retained a stopped 5,410-tick sample. A changed 488-tick sample appeared by 15:26:29.723 without agent input. The measurement stopped rather than inventing a duration/pass or attributing an API failure. The owner confirmed their use and freed the client. A fresh baseline at 15:29:48.901 preserved the owner's stopped 852-tick sample, with capture/profiling off. The uninterrupted no-agent-input interval ended at 15:45:06.499: **917.598 wall-clock seconds / 917.608019 monotonic seconds**. Passive views stayed readable; normal AFK occurred without disconnect, with no anti-AFK action. Endpoint probe retained every clock counter, tick 852 and counts 6/99/3; effective scale stayed 0.72452831268311. Whole-client FPS points were 206.00857543945 / 198.3470916748. Normal close/reopen and the fresh 15:47:11.963 probe retained all numeric values; stop reason became `Closed`. Final 15:47:57.844 readback was active=false/shown=false/profiling=false, chat closed. [Exact commands, chronology and limits](evidence/2026-10-19-m0-idle.md).

**Independent preparation:** client-checklist section 3c now defines a one-setting supported-scale comparison through the actual normal control, recording original settings, changed/restored readbacks, appearance/counts and exact restoration. No arbitrary CVar writes or assumed range/menu; unavailable settings remain pending. This probe is prepared, NOT RUN.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 29 expected paths, synchronized TOCs, protocol/docs links and header-only ledger; repeated after documentation changes. |
| `C:\Python314\python.exe scripts/test_lua.py` | PASS — Lua 5.1/5.4 through pinned local Lupa; 16 files parsed/eight test modules each, including 10k-tick replay, 92,853-point geometry, lifecycle/pooling and profiler regressions. |
| Independent installed/source SHA-256, 15:24:59–15:25:01 CEST | PASS — all ten addon files match; zero writes/installations. |
| Native `lua tests/run.lua` | NOT RUN — lua/luajit/luac absent from PATH; actual embedded runtimes above executed the suite. |
| Stopped/open interval, endpoint and close/reopen | PASS for this workload/build/scale; prior interrupted attempt excluded. Explicit counts cover this UI module, not templates/client memory. |
| Independent evidence/command review | PASS — elapsed arithmetic, scoped claims, pending gates and reversible procedure aligned; all 45 reviewed slash lines fit 255 characters (maximum 192). |
| `git diff --check` and staged equivalent | PASS — final whitespace checks. |
| Ten-minute driving, handling/full focus, supported-scale execution, memory/CPU/continuous hitch/taint, F5/F4 | NOT RUN this slice; existing pending status retained. No extra combat or simultaneous W/Up test. |

**Changes/limits:** sanitized idle evidence, client checklist, API/feasibility/testing docs and this handoff only; addon code/tests/ROADMAP unchanged. FPS points are not sustained performance or addon cost; no zero-taint guarantee follows from sampled screenshots. Owner driving samples have no independent measured duration or complete input history. No personal screenshot/chat is committed. No avatar movement/combat, peer traffic, push/tag/release or automation was performed.

**Commit/handoff:** focused local commit intended as `docs: record M0 idle stability and prepare scale probe`; inspect `git log` for hash. **Next exact task:** the reversible one-setting supported-scale comparison in client-checklist section 3c. M0 remains OPEN; full F1/F2/F5/F4 and later milestones are not promoted by the idle result.

### 2026-10-19 16:14 CEST session; client observations through 16:27 CEST — Codex / main

**Milestone/objective:** M0, attempt one normal supported-scale comparison and exact restoration. Confirmed canonical remote/main, clean starting HEAD `68c243c` and repository-local PhilForever identity/useConfigOnly. Installed addon source stayed `fbd3cc8`; no code/test/install changes. The computer-use skill was used for the actual returned WoW window; no character input was automated.

**Actual client results:** Options search `UI Scale` exposed Use UI Scale, unchecked with stored 100% and disabled slider. No numeric slider range/steps were measured. `/akart` opened the preserved stopped sample. Baseline at **16:19:31.385 CEST**: CVars 1.000000/0, effective scale 0.72452831268311, tick 852, frames 2844, active frame seconds 14.2110, simulation 14.2000, remainder 0.01100, zero drops/hitch frames, max elapsed 0.0470, counts 6/99/3, inactive/profiling off. Full road/controls readable without apparent seams.

The kart was closed normally to expose the overlapping Options control. Checked 100% at 16:22:20.597; Apply at 16:22:39.732 showed a larger Options layout and timed Okay/Cancel acceptance with 8 seconds remaining. The action did not complete acceptance before reversion. Two subsequent normal-control attempts also reverted before confirmation completed, including a later fresh capture of the countdown. No changed-state effective scale/probe/addon renderer was measured. No arbitrary setters, confirmation bypass, reload, Start or driving keys were used. This is tool-roundtrip failure to complete the probe, not an established addon/API failure.

**Restoration review stop:** final readback at **16:27:47.152 CEST** retained every ordinary probe value and counts 6/99/3, original checkbox/stored100%/CVars1.000000/0 and hidden/inactive/profiling off. Effective scale was **0.71111112833023**, differing from baseline **0.72452831268311**. Full effective-scale restoration is therefore unverified; this was flagged for review and further setting/client mutations stopped under client-checklist section 3c step 4. No post-reversion reopen/appearance or accepted-alternative pass is claimed. [Sanitized exact evidence](evidence/2026-10-19-m0-scale.md).

**Independent review/preparation:** the locally pinned build-70450 PixelUtil source uses 768/physicalHeight for pixel conversion. It does not prove UIParent's default-scale implementation or the old physical dimensions. The 1060/1080 resemblance remains an explicitly unproven hypothesis; no API contradiction was found. Prepared five guarded read-only CVar/physical/default/local/effective-scale and UIParent dimension commands in checklist section 3d, NOT RUN. Unavailable/error/secret outcomes must be recorded without coercion. No settings mutation is part of that next task.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 29 expected paths, TOCs, docs/protocol/ledger; repeated after final documentation edits. |
| `C:\Python314\python.exe scripts/test_lua.py` | PASS — actual Lua 5.1/5.4 through pinned local Lupa; 16 parsed files/eight tests each, including deterministic replay, geometry, pooling/lifecycle and profiler regressions. |
| Independent installed/source SHA-256, ~16:14–16:15 CEST | PASS — all ten addon files match; no writes/installations. |
| Native `lua tests/run.lua` | NOT RUN — standalone lua/lua51/lua54/luajit/luac absent from PATH; embedded runtimes above executed the suite. |
| Normal scale control/baseline/final probe | OBSERVED — exact source/build identity, original preferences, frozen counters/counts, final hidden state; effective-scale mismatch unresolved. |
| Accepted alternative renderer / exact effective-scale restoration | INCOMPLETE / REVIEW NEEDED — no invented pass. |
| New guarded geometry commands | NOT RUN — prepared for the next read-only review task. |
| `git diff --check` and staged equivalent | PASS — final documentation whitespace checks. |
| Driving/handling/full input/taint, fresh unprofiled Start, sustained performance/memory/CPU, F5/F4 | NOT RUN this slice; existing pending status retained. |

**Files/scope:** sanitized scale evidence, manual client checklist/probe, API/feasibility/testing docs and this handoff. Source/tests/ROADMAP unchanged; M0 remains OPEN. No personal screenshots/chat, other-addon/WTF/SavedVariables file edits, combat/recovery, packets, push/tag/release or automation. The existing idle pass remains historical evidence at its measured settings; it does not resolve this later scale difference.

**Commit/handoff:** focused local commit intended as `docs: record incomplete scale probe and restoration mismatch`; inspect `git log` for hash. **Next exact task:** one guarded read-only screen/default-scale/UIParent geometry snapshot at unchanged settings for restoration review, checklist section 3d. Do not repeat timed scale changes or force the old effective value.

### 2026-10-19 18:36–18:45 CEST (Europe/Oslo) — Codex / main, build-first drift slice

**Milestone/direction:** M1 local mechanics development; M0 acceptance stays OPEN. Canonical checkout/remote/main and clean initial HEAD `0108b4e` confirmed; repository-local PhilForever identity/useConfigOnly verified. The owner requested about 80% less testing and building now. Accepted ADR 0007 updates the working policy: focused validation alongside a playable slice; defer repeated broad suites and long client probes. This explicitly permits local M1 work without declaring the remaining M0 gates passed. No transport/lobby/AI scope added.

**Implementation:** physics compatibility version 3. Space plus a single turn at forward speed >=90 starts a directional slide with bounded slip. Hold the same turn to charge tier 1 at 54 ticks or tier 2 at 108 ticks; release Space while continuing the turn for 30/48 boosted steps, including the release step. Boost speed cap 260 versus normal 200. Brake, lost/opposite steering, insufficient speed or impact cancels charge; impacts clear boost/slip too. These are tunable prototype values, not accepted game feel. Physical Space state participates in the existing clear/release path.

**Presentation:** preallocated fourth FontString shows controls, drift charge/tier and remaining boost. Existing quarter-second HUD cadence and immediate Start/Stop refresh are reused; stopped feedback is labeled `Last drive`. Kart tint changes only when the drift/boost phase changes. No UI objects or chat messages are created per simulation tick. Window height increased to fit feedback; explicit UI counts are now 6 frames/99 textures/4 font strings, excluding bootstrap/template internals. Fresh Start resets all mechanics. Combat/focus behavior retained.

**Focused verification actually executed:**

| Command/check | Result and scope |
|---|---|
| One-off pinned Lupa Lua 5.1 execution of `dofile("tests/test_drift.lua")` | PASS — charge boundaries/cap, slip signs, exact boost duration/expiry/speed cap, steering/brake/slow/reverse cancellation, collision clearing; seeded 720-tick replay compares all 12 state fields at 30/60/144 render Hz. |
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests physics input ui` | PASS — 17 Lua files parsed, three selected modules executed. Space reaches actual-track fixed-step physics, HUD/tint phases and input release/reset pass; unchanged-phase tint is cached and pooled counts stay 6/99/4. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 29 expected paths, synchronized TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Short read-only integration review | No concrete blocker found; no additional test run. |
| Verified backup/direct local installation | PASS — only Input.lua, Physics.lua and UI.lua copied after complete prior-addon backup/hash verification; all ten installed source hashes match. |
| Full suite, extended 10k-tick v3 tape, Lua 5.4, native Lua CLI, actual-client reload/drift/handling, long scale/profiling/stress checks | NOT RUN this slice — deliberately deferred under the owner's build-first priority. Prior results remain historical and are not promoted to v3 acceptance. |

`scripts/test_lua.py` now accepts `--tests <module>...` for repeatable focused runs while still parsing all sources; omitting it retains the full suite. Added a drift module and extended the existing long replay's field/input coverage, without claiming that long replay was executed this slice.

**Installation:** normal filesystem approval used for the existing AzerothKart installation. Manifest: parent workspace `artifacts/AzerothKart/20261019-184501-352871/install.json`; verified prior files in `before/`. The client was left untouched; the updated disk build needs a normal `/reload` at the owner's convenience. No other addon/WTF/SavedVariables files edited, character controls automated, packets sent, push/tag/release or automation performed.

**Handoff:** focused local commit intended as `feat: add charged drift and mini-boost to solo driving`; inspect `git log` for hash. Remaining risks: client handling/layout are unverified, existing road-edge collision is still the M0 position-rejection model, scale restoration review remains deferred/unresolved, and no race/lap/placement or multiplayer engine exists. **Next single task:** road/grass slowdown with bounded outer-wall collision and a surface HUD indicator; one focused Lua 5.1 pass, broader playtesting later.

### 2026-10-19 18:53–18:58 CEST (Europe/Oslo) — Codex / main, grass and perimeter slice

**Milestone/scope:** M1, following the build-first policy. Correct canonical remote/main, clean starting HEAD `e4610b6` and local PhilForever identity/useConfigOnly confirmed. Inspected existing modules, affected tests and persistent docs; preserved all work. M0 and M1 acceptance remain open; no roadmap checkbox promoted.

**Built:** Physics v4 distinguishes the road mask from traversable island/exterior grass and rectangular walls. Grass eases inherited speed toward 70 forward/30 reverse with drag 360 after normal controls, applied at most once per step. Leaving road clears drift/charge/boost/slip, including a charged release. Review caught a boost-acceleration reward surviving the entry step; removed it before drag and added a narrow assertion before the single validation run. Grass permits returning to road without an impact. Perimeter contact clamps the center to an 18-unit inset, retains tangent movement and scrubs speed by 0.25 once per contact step, including corners. This is an endpoint-clamping prototype, not arbitrary swept wall collision.

The existing pooled HUD names Road/Grass/Wall and retains `Last drive` feedback. Four creation-only gray perimeter strips increase explicit allocation counts to 6 frames/103 textures/4 font strings. The 96 road bands, grass layering, spawn, input and fixed-step clock are unchanged; no tick creates UI objects or prints chat. New `surface` state is included in replay comparisons. Legacy pure open-plane/solid-wall fixtures remain supported.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests track physics drift surface ui` | PASS once — 18 Lua files parsed, five modules executed. Road/grass reentry, gradual 260→70 slowdown, reverse limit, drift/boost cancellation, tangent/corner/recovery and HUD/pooling checks passed. Seeded 360-tick surface and 720-tick drift replays matched all 13 fields at 30/60/144 render Hz. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 29 expected paths, synchronized TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — only Physics.lua, Track.lua and UI.lua copied; complete prior backup verified before writes, all ten installed hashes match source. |
| Full suite/10k-tick v4 replay, Lua 5.4, native Lua CLI, actual-client reload/layout/handling, scale/stress/performance | NOT RUN this slice — focused build-first cadence; no new client availability claim or input attempt. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-185838-921432/install.json`; verified prior addon in `before/`. Updated disk files need normal `/reload` at the owner's convenience. No other addon/WTF/SavedVariables files modified, character actions automated, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add recoverable grass and perimeter collisions`; use `git log` for hash. Client feel/perimeter appearance and prior M0 scale/focus/performance checks remain deferred. There is still no lap/placement or multiplayer engine. **Next single build task:** interpolate rendered kart poses between fixed states with shortest-arc heading and exact Start/Stop poses, never feeding presentation back into simulation.

### 2026-10-19 19:01–19:04 CEST (Europe/Oslo) — Codex / main, interpolated presentation

**Milestone/scope:** M1 under ADR 0007. Canonical remote/main, clean starting HEAD `ef09433` and local PhilForever identity/useConfigOnly confirmed. Read the handoff, current criteria, architecture/decisions and affected source/tests. M0/M1 acceptance remains open; roadmap checkboxes unchanged.

**Built:** pure `Presentation.pose(previous,current,alpha)` returns three scalars, clamps interpolation, handles missing/invalid alpha and rotates along the shortest arc. UI retains the actual previous fixed-step state and renders using accumulator/dt, including frames with zero simulation steps. It adds at most one fixed step of visual delay, without extrapolation or feeding coordinates back into physics. Create/Start/Stop collapse history and show the exact reset/final pose; inactive updates do not animate, and reopen retains the frozen pose/clock. No new UI objects, per-frame pose tables or chat output. Physics version 4, input, Track and Loop are unchanged; explicit counts stay 6/103/4. Both TOCs and mock loading include the new module before UI; the structural validator checks it.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests presentation ui` | PASS once — 20 Lua files parsed, two modules executed. Pure endpoints/clamps/angle wrap/no mutation passed. UI half/zero-step blend, exact Stop/reopen/Start and pooling passed; 120-tick direct simulation versus UI at 30/60/144 render Hz matched all 13 state fields and clock accounting. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 31 expected paths, synchronized eight-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — both TOCs, Presentation.lua and UI.lua copied after complete prior-addon backup/hash verification; all eleven installed source hashes match. |
| Full suite/10k-tick replay, Lua 5.4, native Lua CLI, actual-client reload/interpolation/handling, scale/stress/performance | NOT RUN this slice — deferred build-first cadence. Interpolation math/mock evidence is not a client smoothness or latency measurement. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-190358-313163/install.json`; prior ten-file addon preserved in `before/`. Updated disk build needs normal `/reload` at the owner's convenience. Client input/settings were untouched; no other addon/WTF/SavedVariables changes, character actions, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: interpolate kart presentation between simulation steps`; inspect `git log` for hash. Client feel/appearance and earlier M0 checks remain deferred. **Next single build task:** a pooled two-tier drift charge and remaining-boost meter using actual mechanics state, text/threshold cues and the existing reset/freeze lifecycle.

### 2026-10-19 19:10–19:13 CEST (Europe/Oslo) — Codex / main, drift/boost meter

**Milestone/scope:** M1 under the owner's build-first priority. Confirmed canonical remote/main, clean starting HEAD `f6ab761` and repository-local PhilForever identity/useConfigOnly; read the handoff, criteria and affected source/tests. M0/M1 acceptance remains open; no roadmap checkbox promoted.

**Built:** `Presentation.meter(state,Physics)` maps actual charge/remaining-boost ticks to a scalar fraction and named phase without mutating simulation. Charge 54/108 reaches half/full Tier 1/Tier 2 marks. Boost uses one shared 48-tick/0.8-second capacity, switching marker labels to 0.4s/0.8s; a shorter boost occupies less of that scale. The 300×12 bar has phase captions as well as color and retains the existing text HUD. Four pooled textures and three font strings bring explicit counts to 6/107/7 in an 856×706 window. Empty fill is hidden; phase/fill caching avoids repeated setters on unchanged frames. Stop freezes the meter with `Last drive`, and Start clears it. Physics v4, input, clock, interpolation and TOC order are unchanged; no new client API or per-tick UI creation/chat.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests presentation ui` | PASS once — 20 Lua files parsed, two modules executed. Pure 53/54/107/108 boundaries, boost capacity, surface cancellation and no mutation; UI marker geometry/captions/width, zero-step cached setters, stopped/fresh-Start state and pooling passed. Existing short UI replay still compares all 13 simulation fields at 30/60/144 render Hz. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 31 expected paths, synchronized eight-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — only Presentation.lua and UI.lua copied after complete prior-addon backup/hash verification; all eleven installed source hashes match. |
| Full suite/10k-tick replay, Lua 5.4, native Lua CLI, actual-client reload/meter appearance/handling and broad performance/scale checks | NOT RUN this slice — intentionally deferred. No client smoothness, layout or game-feel pass is implied by mocks. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-191323-722306/install.json`; verified prior addon in `before/`. Disk build needs normal `/reload` at the owner's convenience. No client input/settings mutation, other-addon/WTF/SavedVariables edits, character actions, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add pooled drift charge and boost meter`; inspect `git log` for hash. Client appearance/handling and earlier M0 checks remain deferred. **Next single build task:** fixed-step progressive keyboard steering with fast centering, preserving reverse/input semantics and adding a focused response metric/replay.

### 2026-10-19 22:28–22:31 CEST (Europe/Oslo) — Codex / main, progressive steering

**Milestone/scope:** M1 under the build-first priority. Confirmed canonical remote/main, clean starting HEAD `092e397` and local PhilForever identity/useConfigOnly. Read the handoff, criteria, relevant design/architecture and affected source/tests. No work is inferred for the gap since the prior run. M0/M1 acceptance remains open; roadmap checkboxes unchanged.

**Built:** Physics v5 adds signed `steering` in [-1,1]. Turn buildup at 8/s reaches full lock in eight 60 Hz ticks; release centering at 16/s takes four. Reversal finishes centering before building the opposite sign, taking twelve ticks from lock to lock. Both keys cancel immediately. Yaw uses the filtered value, while raw input still cancels drift immediately; new drift requires actual/raw signs to agree. Reverse flips yaw as before. Walls clear steering and grass preserves it for recovery. Stop retains the complete frozen state; fresh Start resets steering to zero. Existing bindings, UI interpolation/meter, clock and TOCs are unchanged; counts remain 6/107/7. These are prototype response timings, not measured input latency or proven game-feel improvements.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests physics steering drift surface ui` | PASS once — 21 Lua files parsed, five modules executed. Observed 8/4/12-tick response; mirror/reverse/opposing keys, raw drift cancellation/re-entry sign gating, wall reset/grass retention and no state mutation passed. Steering/surface 360-tick, drift 720-tick and UI 120-tick cadence checks compare all 14 fields at 30/60/144 render Hz. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 31 expected paths, synchronized TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — only Physics.lua copied after complete prior-addon backup/hash verification; all eleven installed source hashes match. |
| Full suite/10k-tick v5 replay, Lua 5.4, native Lua CLI, actual-client reload/steering/handling and broad scale/performance checks | NOT RUN this slice — intentionally deferred under ADR 0007. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-223121-797921/install.json`; verified prior addon in `before/`. Disk build needs normal `/reload` at the owner's convenience. No client input/settings mutation, other-addon/WTF/SavedVariables edits, character actions, packets, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add progressive keyboard steering with fast centering`; inspect `git log` for hash. Direct game feel and earlier M0 checks remain pending. **Next single build task:** ordered directional checkpoint progress on the existing test oval, with pure order/direction/duplicate checks and a pooled HUD indicator. No lap winner, networking or milestone acceptance is implied.

### 2026-10-19 22:33–22:37 CEST (Europe/Oslo) — Codex / main, ordered checkpoint foundation

**Scope:** independent solo course groundwork alongside open M1 direct-play acceptance. Canonical remote/main, clean starting HEAD `d42fb92` and local PhilForever identity/useConfigOnly confirmed; inspected current criteria, handoff and relevant source/design. M0/M1/M3 acceptance stays open; no roadmap checkbox promoted.

**Built:** four radius-derived finite directional gates, North → West → South → Start, across the actual road. Strict negative-to-nonnegative plane crossing accepts the intersection within the gate span, rejecting backwards/parallel/on-line-departure awards. New pure `Checkpoints` state stores next gate, passed count, completion and last consumed tick. Only the expected gate can award, at most once per consecutive fixed step. Duplicate/stale/out-of-order/gap tick reports return unchanged progress. Consecutive malformed or >5-unit motion samples consume their tick without an award; later valid consecutive motion can recover. Four gates complete one terminal course pass; no loop, lap, timer, winner or competitive validation is claimed.

UI passes actual physics poses after each fixed step, independently of render interpolation. It corrects the right-side Start strip to span the road horizontally, adds three other pooled strips and one next-gate/progress label, and caches tint/text changes. Stop/reopen retains progress; Start resets it. Counts are 6/110/8 in an 856×734 window. Nine-module TOCs load Checkpoints before UI; Physics remains v5. No per-tick UI object creation or chat output.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests track checkpoints ui` | PASS once — 23 Lua files parsed, three modules executed. Direction/span/endpoints, tick/order/duplicate/gap/movement guards, recovery and terminal retention passed. A 900-tick synthetic centerline path matched checkpoint state at 30/60/144 render Hz; this is not a player-input replay or client drive. UI uses injected crossing poses followed by real Physics steps to verify immediate cue updates, cached colors/text, course completion, frozen Stop/reopen, fresh Start and pooling. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 33 expected paths, synchronized nine-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — Track.lua, Checkpoints.lua, UI.lua and both TOCs copied after complete prior-addon backup/hash verification; all twelve installed source hashes match. |
| Full suite/10k-tick replay, Lua 5.4, native Lua CLI, actual-client reload/course drive/layout and broad scale/performance checks | NOT RUN this slice — intentionally deferred. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-223715-373497/install.json`; prior eleven-file addon preserved in `before/`. Disk build needs normal `/reload` at the owner's convenience. No client input/settings mutation, other-addon/WTF/SavedVariables edits, character actions, packets, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: track ordered directional checkpoints on the test oval`; inspect `git log` for hash. Client appearance/course handling and earlier M0 gates remain pending. **Next single build task:** repeatable ordered circuits with simulation-tick lap count/current/last times, deduplicated course completion and the existing reset/freeze lifecycle.

### 2026-10-19 22:38 start; resumed 23:56–23:58 CEST (Europe/Oslo) — Codex / main, practice laps

**Scope:** repeatable solo practice laps, with M0/M1/M3 acceptance still open. Canonical remote/main, clean starting HEAD `a7326e9` and PhilForever local identity/useConfigOnly confirmed. Inspected handoff, criteria and existing checkpoint/clock/UI source before integration. A documentation subagent hit quota after partial edits; parent preserved and completed them on resume. No execution or client activity is inferred for the time gap, and no milestone checkbox was promoted.

**Built:** pure immutable `Laps` wraps the existing Checkpoints module through explicit dependency injection. A newly completed course records `finishTick - lapStartTick`, increments completed laps once and immediately rearms North at that same tick. The next lap starts at zero. Duplicate/older/gapped reports leave both clocks unchanged; accepted consecutive invalid movement advances practice time without a gate award. Start-line jitter still requires all four gates for another lap. No wall clock, saved record, countdown, finite race target or winner is added.

UI consumes actual fixed-step poses, keeps `UI.checkpoints` as the nested progress alias and displays completed count/current/last times from ticks × 1/60. Text uses the existing quarter-second cadence plus immediate finish/Start/Stop refresh. Stop/combat/reopen freezes the sample; fresh Start clears it. One preallocated font string brings counts to 6/110/9 in an 856×762 window. Physics v5, input capture and track geometry are unchanged. Both TOCs load Laps after Checkpoints, for ten modules total; no per-tick UI creation/chat.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests checkpoints laps ui` | PASS once at 23:56 — 25 Lua files parsed, three modules executed. Repeated finishes/jitter, wrong direction/order, invalid tick/movement, offset/reset and immutable state passed. A connected 1,800-tick synthetic three-circuit path compared all lap/nested checkpoint values at 30/60/144 render Hz. UI injected crossing fixtures verify two different lap durations, immediate rearm/time feedback, periodic current time, frozen retention/reset and stable pooling; no real-client lap result is claimed. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 35 expected paths, synchronized ten-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Verified prior-addon backup and direct install | PASS — Laps.lua, UI.lua and both TOCs copied after complete prior-addon backup/hash verification; all thirteen installed source hashes match. |
| Full suite/10k-tick replay, Lua 5.4, native Lua CLI, client reload/lap driving/layout and broad scale/performance | NOT RUN this slice — build-first priority retained. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261019-235702-109038/install.json`; prior twelve-file addon in verified `before/`. Disk build needs normal `/reload` at the owner's convenience. No client input/settings mutation, other-addon/WTF/SavedVariables edits, character actions, packets, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add repeatable practice laps and tick-based timing`; inspect `git log` for hash. Client feel/layout and earlier M0 checks remain pending. **Next single build task:** a three-lap solo finish flow with frozen final timing, input release, reachable summary/restart and deduplicated terminal state.

### 2026-10-20 00:00–00:06 CEST (Europe/Oslo) — Codex / main, three-lap solo finish

**Scope:** one local solo slice under the owner's build-first priority. Canonical remote/main, clean starting HEAD `e10e869` and local PhilForever identity/useConfigOnly confirmed. Reviewed the handoff, criteria and affected source before changes; preserved the ongoing slice through context continuation. M0/M1/M3 acceptance stays open; roadmap checkboxes unchanged.

**Built:** pure immutable `Race` wraps Laps through explicit dependencies. A successful Start creates a running three-lap session; the third accepted ordered circuit records the exact finish/total ticks once. Later step/stop calls return the same terminal object. Early Stop or combat freezes actual partial progress without awarding a finish. Physics remains v5, with no new client API, countdown, persistence, best record, ghost or transport code.

`Loop.advance` now counts a callback returning exactly `false` as its final executed tick and stops catch-up immediately. Remaining whole ticks from that callback become dropped time; the fractional accumulator and full elapsed duration remain accounted. Only incoming work over the five-step budget increments hitch frames, so a normal terminal frame does not invent a hitch. UI releases input after the finish, renders the exact final pose and retains the clock/result across Stop/Close/reopen or a rejected Start. A preallocated summary shows total/last-lap times when finished or actual partial progress when stopped/interrupted, with a deliberate Restart. Main Start Test Drive remains available. Two frames and three font strings bring explicit allocations to 8/110/12 in the unchanged 856×762 window; no per-tick UI creation or chat. Both TOCs load Race after Laps, for eleven modules. Updated source/install README and canonical docs match current behavior.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests race loop ui` | PASS once — 27 Lua files parsed, three modules executed. Pure terminal/reset/invalid-tick behavior passed; a connected synthetic 1,800-tick three-lap run compared all Race/Laps/checkpoint fields at 30/60/144 render Hz, with fourth-circuit and duplicate-finish rejection. Loop checks cover terminal whole/fractional/hitch accounting. UI fixtures use injected poses followed by actual Physics steps and verify exact tick-12 finish, cancellation of two remaining catch-up ticks, release, exact pose/timing, summary/Restart, partial Stop/combat, terminal retention and stable 8/110/12 pooling. Synthetic/mock results are not client handling or finish observations. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 37 expected paths, synchronized eleven-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check; existing CRLF-to-LF notices are informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — complete prior thirteen-file addon backup verified before writes; Race.lua, Loop.lua, UI.lua, both TOCs and README_ADDON.md copied; all fourteen installed source SHA-256 values match. |
| Full suite/10k-tick v5 replay, Lua 5.4, native Lua CLI, client reload/finish/restart/layout/handling and broad scale/performance checks | NOT RUN this slice — focused build-first cadence. No client availability conclusion or input attempt was made. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261020-000615-459134/install.json`; prior addon preserved in verified `before/`. Disk build needs normal `/reload` at the owner's convenience. No other addon/WTF/SavedVariables edits, character actions, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: finish three-lap solo runs with retained results`; inspect `git log` for hash. Client appearance/direct play and earlier M0 scale/focus/performance risks remain deferred, with no new blocker established. **Next single build task:** a fixed-step 3–2–1–GO countdown that holds spawn, starts lap/run timing at GO, displays a pooled cue and retains existing cancellation/restart semantics.

### 2026-10-20 00:07–00:12 CEST (Europe/Oslo) — Codex / main, fixed-step countdown

**Scope:** one local solo slice under ADR 0007. Canonical remote/main, clean starting HEAD `e3a6523` and repository-local PhilForever identity/useConfigOnly confirmed. Read persistent handoff, milestone criteria, accepted decisions and relevant source/tests before editing. M0/M1/M3 acceptance remains open; no roadmap checkbox promoted.

**Built:** pure Race starts in `countdown` with 180 remaining ticks and no racing start tick. It validates consecutive finite integer tick pairs independently of lap progress, ignoring duplicates/gaps/invalid reports. Cues are fixed strings: 3 for remaining 180–121, 2 for 120–61 and 1 for 60–1. GO at tick 180 enters running, sets `startTick` and creates fresh Laps at that origin, still with zero race elapsed time. Race.cue retains GO for racing ticks 0–59 and hides it at tick 60. Countdown Stop/combat records an immutable terminal partial result with zero racing time; later calls retain it.

UI samples held input into the existing reused table throughout countdown but supplies a separate reused neutral table to Physics. At the current zero-speed spawn, all fourteen physics fields except tick stay at their initial values. Tick 181 applies the actual held input; a multi-step callback crossing GO preserves this ordering. Physics/Loop/probe ticks stay unified and include countdown, while race/lap durations exclude it, dropped time and stopped time. A hitch that drops fixed steps can extend countdown wall time; no timer shortcut skips simulation. One preallocated centered font string shows phase changes outside the quarter-second HUD cadence with cached text writes, using an available large built-in font or the existing normal-font fallback. Counts are 8/110/13 in the unchanged 856×762 window. Stop hides the cue/releases input, canceled results stay frozen on reopen, and explicit Start/Restart begins all 180 countdown ticks again. Physics v5, input bindings, track geometry, Loop and eleven-module TOC order are unchanged. No new client API, UI allocation per tick, chat spam, persistence, ghosts or transport.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests race ui` | PASS once — 27 Lua files parsed, two modules executed. Pure cue boundaries, exact GO origin, invalid/duplicate/gapped ticks, pre/post-GO cancellation/reset/nonzero origins and terminal retention passed. A connected synthetic 1,980-tick countdown plus three-lap run compared every Race/Laps/checkpoint field and cue at 30/60/144 render Hz. UI mocks check unchanged spawn fields through tick 180, sampled held/released inputs, first movement at 181, a three-step callback crossing GO, cached cue writes/hiding, zero-time cancellation via Stop/Escape/focus/combat, reopen/Restart and stable pooling. Existing driving fixtures now execute the real countdown; exact global-tick-192 finish still reports twelve racing ticks and stops remaining catch-up. No real-client countdown, input latency or handling result is claimed. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 37 expected paths, synchronized eleven-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check; CRLF-to-LF notices are informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — complete prior fourteen-file addon backup verified before writes; only Race.lua, UI.lua and README_ADDON.md copied, all fourteen installed source SHA-256 values match. |
| Full suite/10k-tick v5 replay, Lua 5.4, native Lua CLI, actual-client reload/countdown/finish/restart/layout/handling and broad scale/performance checks | NOT RUN this slice — deferred build-first cadence. No client availability conclusion or input attempt was made. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261020-001127-759404/install.json`; prior addon preserved in verified `before/`. Disk build needs normal `/reload` at the owner's convenience. No other addon/WTF/SavedVariables edits, character actions, packets, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add fixed-step countdown before solo races`; inspect `git log` for hash. Direct play/layout and earlier M0 scale/focus/performance checks remain deferred; no new blocker established. **Next single build task:** best completed lap within the current three-lap run, with lap number, earliest-lap ties, frozen partial/result retention and fresh-run reset; no persistence yet.

### 2026-10-20 00:19–00:22 CEST (Europe/Oslo) — Codex / main, best completed lap within a run

**Scope:** one solo timing/feedback slice under the owner's build-first priority. Canonical remote/main, clean starting HEAD `5c4c135` and local PhilForever identity/useConfigOnly confirmed. Read handoff, criteria, relevant accepted decisions and affected source/tests before changes. M0/M1/M3 acceptance stays open; roadmap unchanged.

**Built:** pure immutable Laps adds `bestLapTicks` and `bestLapNumber`, initially nil. Only an accepted completed lap can establish or improve the best. Strictly shorter integer duration replaces it and records that one-based lap number; equal durations retain the earlier lap. Current/incomplete laps, rejected/invalid movement and duplicate/gapped reports cannot establish or improve it. Ordinary steps carry both fields unchanged. Race retains the same nested lap state on Stop/combat/finish, and its existing new-run/GO initialization resets it. No Race, Physics, countdown, checkpoint or clock behavior was changed.

The existing lap HUD and finished/stopped/interrupted summary text display `Best: --` before any completion, then `Best: %.2fs (lap %d)`. They use one shared formatter at the existing HUD/summary refresh points; no per-tick formatting or new objects. The summary grows from 380×170 to 380×190 for its third line, while the outer window and explicit counts remain 856×762 and 8/110/13. Stop/reopen and refused Start retain the record; successful Start/Restart clears it. This is the best lap of the current run only, with no saved personal record, persistence/schema/migration, settings, new client API, ghosts or networking.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests laps race ui` | PASS once — 27 Lua files parsed, three modules executed. Variable completed durations 8→10→6→6 ticks verify first/slower/faster/tie behavior, unfinished faster-so-far laps, invalid/order/duplicate/gapped samples, reset/nonzero origins and immutable prior states. Connected synthetic 1,800-tick Laps and 1,980-tick countdown/Race replays compare the new best fields with all prior lap/checkpoint/race state at 30/60/144 render Hz. UI fixtures exercise slower retention and 6/4/4 lap durations (best lap 2), global-tick-194 exact finish/drop accounting, HUD/summary formatting, partial/combat/reopen/refused Start retention, explicit Restart reset and unchanged pooling. These are synthetic/mock results, not real-client timing or layout observations. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 37 expected paths, synchronized eleven-module TOCs, protocol/docs links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check; CRLF-to-LF notices are informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — complete prior fourteen-file addon backup verified before writes; only Laps.lua, UI.lua and README_ADDON.md copied; all fourteen installed source SHA-256 values match. |
| Full suite/10k-tick v5 replay, Lua 5.4, native Lua CLI, actual-client reload/best-lap layout/handling and broad scale/performance checks | NOT RUN this slice — focused build-first cadence. No client availability conclusion or input attempt was made. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261020-002117-926175/install.json`; prior addon preserved in verified `before/`. Disk build needs normal `/reload` at the owner's convenience. No other addon/WTF/SavedVariables edits, character actions, packets, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: show the best completed lap within each run`; inspect `git log` for hash. Direct play/layout and earlier M0 scale/focus/performance checks stay deferred; no new blocker established. **Next single build task:** bounded three-lap split data and recap in retained results, with no persistence or full input recording.

### 2026-10-20 00:44 start; resumed 00:50–00:55 CEST (Europe/Oslo) — Codex / main, Mirage asset research and art brief

**Owner steering/scope:** the owner supplied Mirage Raceway scenery/circuit images and asset links, requested recognizable Warcraft III-like fantasy units instead of modern karts, and proposed precomposed scenery with separate sprites. This newer priority defers the lap-split recap. Canonical remote/main and clean starting HEAD `3ebb60f` confirmed; local PhilForever identity/useConfigOnly verified. Read current handoff, relevant design/asset/architecture docs and roadmap. A documentation subagent hit quota after writing its scoped planning files; after the owner resumed, the parent preserved/reviewed that work and completed the remaining documents. No execution or client activity is inferred for an interruption. M0/M1/M3 acceptance stays open.

**Research completed:** browsed all supplied sources and concrete candidates. WC3Vault listings include Goblin Mortar Trike (erwtenpeller/chriz), Steam Tank, Gyrocopter and Gryphon Rider, with additional siege/building/barrier references. Authors, package formats/sizes, uninspected archive contents and permission gaps are recorded in `docs/art/ASSET_SOURCES.md`; none is marked cleared for rendered-addon redistribution. Site access was intermittent, with the homepage/Browse route available to the researcher. OpenRealm is MIT engine/tool code and explicitly excludes retail data; documented MDX/PNG capture is a tooling lead, not an asset license or an executed render pipeline. The warcraft-iii organization is chiefly tooling/templates. Kenney's Racing/Desert Shooter primary pages explicitly list CC0, but visual fit is uninspected and modern vehicles do not satisfy the roster. No third-party archives, binaries or retail art were downloaded/imported/executed.

**Art/direction prepared:** ADR 0008 accepts Mirage Raceway on the dry Shimmering Flats as the first production-map target, replacing proposed Tinker Speedway. Updated the roadmap's planned name without promoting a checkbox. ASSETS/TRACKS/ARCHITECTURE/UI_UX/GAME_DESIGN, README and the new map brief align on precomposed Background/optional Foreground/Preview, independent geometry and pooled dynamic sprites. Preserve both tank variants, mortar trike, gyrocopter, gryphon rider, both Mirage drag cars and optional shredder. A true overhead sprite can rotate; angled units need directional frames. Aircraft initially use cosmetic hover/shared ground rules. Art/geometry registration and aspect-preserving viewport framing precede final export; no stretching of the vertical loop into the current landscape canvas. The existing 96 road pieces are Texture regions, not 96 Frames, and no performance gain is claimed without measurement.

Used the imagegen skill's built-in tool for one concept generation plus one vehicle-panel refinement. Selected concept saved under `docs/art/concepts/mirage-raceway-direction-v1.png`, with both exact prompts and `manifest.json`. This is a generated fan-art concept board, not runtime art or blanket clearance of underlying Warcraft IP. Some vehicle camera/facing/silhouette treatment still needs individual production work; the board is not an atlas to slice into shipping sprites. User-supplied temporary screenshots were not copied into Git. No approval of the generated image itself is inferred.

**Build-matching source inspected:** parent-workspace `research/upstream/wow-ui-source-forever-70450/version.txt` is `1.60.1.70450`; generated SimpleTextureBase signatures define SetRotation at line 527, SetTexCoord at 580 and SetTexture/string path/success at 604. This supports the proposed API direction; it does not establish TGA encoding/dimension limits, correct UVs/rotation sign, alpha or live appearance. No new texture API was executed.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 37 required paths, unchanged eleven-module TOC order, local documentation/image/manifest links, protocol docs and header-only network ledger. |
| Inline Python 3.14 stdlib PNG signature/IHDR/hash inspection (`struct`, `hashlib`, `json`) | PASS — selected image is 1536×1024, 8-bit RGB PNG, 2,850,753 bytes; SHA-256 `ec3e3eabd90d01c9a0e4abc9ea9c37d86a50da3d43753fdc2989aaf854187042`. Manifest written; this is header/hash inspection, not a new PNG decoder test or a runtime alpha result. |
| Visual review of both generated concept outputs | Executed — selected refinement better separates tracked siege and wheeled steam silhouettes; projection/facing consistency and actual-size sprite readability remain pending. |
| `git diff --check`; `git diff --name-only -- addon scripts tests` | PASS whitespace; runtime/script/test diff empty. |
| Lua/native runtime suites, asset archive extraction/conversion/render tools, custom TGA loading/alpha/dimensions/UV/rotation, new map/vehicle client checks | NOT RUN — this slice changes docs and concept artifacts only. No new client availability claim or input attempt. |

**Installation:** none this slice. Last verified fourteen-file local install remains the `3ebb60f` best-lap build. No runtime asset folder/files, addon loader, collision changes, new selectable vehicles, other addon/WTF/SavedVariables edits, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `docs: prepare Mirage Raceway assets and art direction`; inspect `git log` for hash. Candidate-art permissions, viewport/framing and actual custom-texture behavior remain unresolved; current play/scale/focus/performance acceptance stays deferred. These limits do not block independent geometry authoring. **Next single executable task:** pure Mirage circuit blockout plus a matching uniformly scaled layout guide, before a clean original background and one drag-car sprite. The three-lap split recap remains deferred.

### 2026-10-20 00:57–01:06 CEST (Europe/Oslo) — Codex / main, Mirage geometry and matching guide

**Scope:** one independent first-map foundation slice under the owner's art priority and ADRs 0007/0008. Canonical remote/main, clean starting HEAD `7b6ee69` and local PhilForever identity/useConfigOnly confirmed. Read current handoff, criteria, brief and affected source/tests before editing. Preserved the art/source ledger and generated concept; no new art generation or third-party import. M0/M1/M3 acceptance remains open; no roadmap checkbox promoted.

**Built:** `MirageRaceway.new(crossesGate)` is a pure factory with explicit dependency injection and a fresh 1024×1024 world per call. Sixteen closed centerline segments form a union of radius-56 capsules (112-unit lane); construction caches segment values once, with no query-time table allocation. Closed centerline length is 1949.325 units at printed precision. All road capsules fit inside perimeter inset 18. The north-facing spawn is on the Start gate at (700,360), so lap one and later laps have the same route length. Gate order/directions: North (550,900)/−x, West (410,520)/−y, South (540,140)/+x, Start (700,360)/+y. Walls use axis constraints; traversable rough salt reuses Physics' grass token. The art mound/pit markers are scenery notes, not obstacle collisions. This is not full competitive route validation.

`Presentation.fitViewport/project/unproject` supplies pure bottom-left/up scalar mapping with a cached transform, validation, inverse and no coordinate clamping. The 1024-square map fits 800×480 at scale 0.46875 with offset (160,0); future UI work must scale dimensions too. Existing interpolation/meter behavior is unchanged. `scripts/build_mirage_layout.py` reads the actual Lua factory/helpers via pinned Lua 5.1 and emits matching `docs/art/mirage-layout.json` and `.svg`; closed round stroke matches capsule geometry without independently smoothing the road. Export flips world Y once. The guide labels gates, spawn, perimeter and separate scenery notes, and `--check` detects stale outputs without writing. A PNG preview rendered with bundled Sharp was visually inspected and kept in ignored `local-artifacts/`.

Both TOCs load MirageRaceway after Track, for twelve modules/fifteen addon files. Mock load order, suite runner and structural requirements include it. The new factory is bundled but UI still uses the original Track; no map selector/texture loader or new WoW API is added. Test Oval, Physics v5, existing input/countdown/laps/results and UI allocations 8/110/13 stay unchanged. Updated the developer README and affected canonical docs. This is not playable Mirage or a production background.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests track mirage presentation ui` | PASS once — 29 Lua files parsed, four modules executed. Mirage geometry covers centerline/closing segment/edges/finite rejection/perimeter containment/fresh instances/spawn, gate order/direction/dedup and lap integration. A connected 1,890-tick countdown plus three-circuit synthetic route compares every Race/Laps/checkpoint field at 30/60/144 render Hz; a separate actual 360-tick input tape matches all fourteen physics fields at those cadences. Projection/inverse endpoints, outside points, invalid inputs and original UI lifecycle/pooling pass. These are same-runtime offline checks, not client handling or rendering results. |
| `C:\Python314\python.exe scripts/build_mirage_layout.py` and the same command with `--check` | GENERATED then CHECK PASS — 16 vertices, four gates, matching source geometry/transform; exports reproduce without changes. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 42 expected paths, synchronized twelve-module TOCs, local documentation/guide links, protocol docs and header-only network ledger. |
| Bundled Node/Sharp SVG-to-PNG render plus `view_image` | Executed — inspected 1024×1216 guide preview (110,756 bytes), readable labels/road/markers/legend. Authoring artifact only; no client appearance claim. |
| `git diff --check` | PASS — whitespace check; CRLF-to-LF notices informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — complete prior fourteen-file addon backup verified before writes; MirageRaceway.lua, Presentation.lua, both TOCs and README_ADDON.md copied, all fifteen installed source SHA-256 values match. |
| Full/10k-tick v5 suite, Lua 5.4, native Lua CLI, custom TGA/alpha/UV/facing, client reload/handling/viewport and broad scale/performance checks | NOT RUN this slice — focused build-first cadence. No client availability conclusion or input attempt. |

**Installation:** normal filesystem approval used. Parent-workspace manifest `artifacts/AzerothKart/20261020-010512-164863/install.json`; prior addon in verified `before/`. Disk build needs normal `/reload` at the owner's convenience and still opens Test Oval. No other addon/WTF/SavedVariables edits, character actions, transport traffic, push/tag/release or automation.

**Handoff:** focused local commit intended as `feat: add Mirage geometry blockout and layout guide`; inspect `git log` for hash. Candidate-art permissions, production sprite projection, map readability/framing and actual custom-texture behavior remain pending, alongside earlier M0 checks. **Next single executable task:** precomposed geometry-aligned Mirage blockout background plus guarded stopped-state map selection with Test Oval fallback; painterly scenery and first drag-car sprite remain subsequent slices.

### 2026-10-20 01:08–01:14 CEST (Europe/Oslo) — Codex / main, selectable playable Mirage blockout

**Scope:** owner wants to try Mirage now. Confirmed canonical remote/main, clean starting HEAD `5237f7a` and repository-local PhilForever identity/useConfigOnly. One vertical slice adds a geometry-aligned background and stopped-state map selection; physics stays v5. No acceptance checkbox was promoted.

**Built:** `scripts/build_mirage_background.py` samples every world pixel center through the actual Lua road predicate. It writes original pale cracked salt/tan road art to `Assets/Tracks/SaltFlats/Background.tga`: 1024×1024 uncompressed BGRA32, bottom-left origin, fully opaque, 4,194,322 bytes. SHA-256 `27a5e56ac98bd5ef6185b10ba734cd90ba483887d8e17b64d6ed6c35075c7714`. The road has no baked gates/kart/guide labels. Provenance is in `docs/art/mirage-background.md`; no screenshot, model, concept crop or third-party texture supplies pixels. An ignored PNG preview was visually inspected; this is blockout art, with scenery/vehicle sprites still pending.

`UI.SelectTrack` and the Track button toggle Test Oval/Mirage while stopped and out of combat. Test Oval remains the default after reload; selection is not saved. A guarded `SetTexture` call must return true before a first Mirage selection commits; missing/false/nil/error results retain the previous track, stopped sample and terminal result with visible refusal. Successful loads are cached. Successful map changes reset state/laps/results/timing to ready, with no automatic Start. A global mouse-down latch prevents the same click from both stopping driving and discarding its result by switching maps.

The existing 800×480 canvas stays fixed. Mirage fits at scale 0.46875, offset (160,0), making a centered 480-square map; kart, four gate strips and four perimeter strips scale positions and dimensions together. Existing 96 oval regions are pooled/hidden on Mirage and restored for Test Oval. One background region and one button bring explicit allocations to **9 frames/111 textures/13 font strings**; bootstrap/template internals excluded. No per-update object creation, file-texture load or chat output. Rough salt uses the unchanged grass mechanic with salt labels. Existing countdown, drifting, three-lap finish and current-run best-lap behavior remain in place; the kart is still a primitive.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests mirage presentation ui` | PASS once — 29 Lua files parsed, all three modules passed. Includes geometry/projection and deterministic cadence checks; actual countdown/input plus synthetic three-lap UI completion; texture failure/retry with retained interrupted sample; uniform anchors/dimensions; click ordering, active/combat refusal, cached load and unchanged pooled allocations through switches. No client result inferred. |
| `C:\Python314\python.exe scripts/build_mirage_background.py` and the same command with `--check` | GENERATED then CHECK PASS — exact reproducibility, header/payload size, fully opaque alpha and eight asymmetric actual-Lua road/orientation landmarks. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 45 expected paths, synchronized twelve-module TOCs, local links, protocol docs and header-only network ledger. |
| Bundled Node/Sharp raw TGA preview plus `view_image` | Executed — inspected the generated 1024-square background, with road alignment/contrast and subtle salt detail; client orientation is not established. |
| `git diff --check` | PASS — whitespace check; CRLF-to-LF notices informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — all prior fifteen addon files backed up/verified before writing; UI.lua, README_ADDON.md and the new nested TGA copied; all sixteen installed source SHA-256 values match. |
| Computer-use skill `sky.list_apps()` then `sky.list_windows()` | Executed — no targetable WoW window returned; Battle.net was present. No client input or launch attempted. |
| Actual TGA loading/orientation/viewport/handling, transparent sprite alpha/atlas/facing, full suite/Lua 5.4, broader scale/performance and multiplayer | NOT RUN this slice. No new transport traffic or performance/handling acceptance. |

**Installation:** normal filesystem approval used. Backup and hash record: parent-workspace `artifacts/AzerothKart/20261020-011313-178335/install.json`; prior addon in verified `before/`. No other addon/WTF/SavedVariables edits. Owner can `/reload`, `/akart`, click **Track: Test Oval** to select **Track: Mirage Raceway**, then **Start Test Drive**. Precise short first-load probe is in FEASIBILITY; it does not request combat or a long test matrix.

**Handoff:** focused local commit intended as `feat: add selectable Mirage blockout track`; resolve hash from `git log`. No push/tag/release/automation. Client readability and custom texture behavior remain pending; M0/M1/M3 and measured multiplayer gates remain open. **Next single executable task:** create/integrate one original overhead north-facing Goblin drag-car sprite for Mirage with documented provenance, correct alpha/pivot and primitive load fallback. Painterly scenery and the rest of the roster follow separately.

### 2026-10-20 01:14–01:19 CEST (Europe/Oslo) — Codex / main, drift handling correction

**Owner feedback and scope:** v5 Test Oval gave almost no practical drift opportunities; charging required small circles and steering corrections reset the meter. Prioritized one M1 handling adjustment ahead of the next sprite. Confirmed canonical remote/main, clean starting HEAD `c019ad2`, current docs/criteria and affected source/tests; no other work overwritten. M0/M1/M3 acceptance stays open.

**Built:** Physics compatibility v6 reduces drift yaw multiplier **1.15 → 0.75**, keeping ordinary yaw/progressive steering unchanged. Tier 1 now needs **30** valid charging ticks (0.5 s), Tier 2 **60** (1 s), replacing 54/108. Forward entry threshold remains 90 units/s; acceleration, top speed, boost durations and map geometry are unchanged. New fifteenth field `driftGraceTicks` retains charge for up to **12** consecutive correction ticks (0.2 s) while Space is held and road/speed conditions remain valid. Neutral/opposing input or steering still centering adds no charge; qualified steering in either direction resumes it and resets the counter. The thirteenth held invalid tick clears it. Slip relaxes during the pause. Releasing Space from the retained state can spend an earned tier even with neutral/correcting steering; braking, insufficient speed, rough ground or walls clear drift/grace without reward. This does not change input bindings or mouse capture.

Presentation exposes the held-charge phase; existing UI regions retain fill/tier color and show `CHARGE HELD`, with correction text in the HUD. No new objects, settings, APIs or per-tick output; counts remain **9 frames/111 textures/13 font strings**. Updated mechanics docs, both READMEs, changelog and deferred manual steps. Race/countdown/lap behavior and the selectable Mirage/Test Oval path remain intact.

**Measured motivation:** at full speed the old steady drift yaw was 2.99 rad/s (turn radius 66.890 units); the new value is 1.95 rad/s (radius 102.564), while ordinary steering remains 2.6 rad/s. A read-only Lua 5.1 baseline probe from the oval spawn with speed 200 and held throttle/left/Space reached old Tier 1 at tick 54/~144.86° heading change, then entered grass at tick 70 before Tier 2. The committed v6 regression uses the same actual oval and inputs: Tier 1 at tick 30/**49.78°**, Tier 2 at tick 60/**105.64°**, every one of those 60 endpoints on road. These are one scripted bend and scalar simulation metrics, not a completed human lap or proof of enjoyable handling.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests physics drift steering surface presentation ui mirage handling` | PASS once — 29 Lua files parsed, all eight modules passed. Exact charge/grace/expiration boundaries, no neutral free-charge, corrected-direction resume, neutral release, immediate cancellation, wider drift yaw, on-road oval tiers, deterministic seeded drift/steering/surface tapes at 30/60/144 Hz across all fifteen fields, held-meter colors/caption, existing map/countdown/lap/result lifecycle and pooled allocations. |
| Handling module in that command | v6 straight baseline unchanged: accel50 39 ticks, accel100 78, brake-to-zero 47, braking path 75.322 units. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 45 paths, TOCs, local links, protocol docs and header-only ledger. |
| `git diff --check` and staged equivalent | PASS — whitespace check; CRLF-to-LF notices informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — previous sixteen-file addon backed up/verified; Physics.lua, Presentation.lua, UI.lua and README_ADDON.md copied; all sixteen installed SHA-256 values match tested source. |
| Version-6 human/client handling, long/full 10k-tick v6 suite, Lua 5.4, custom texture/scale/performance and multiplayer | NOT RUN this slice; no client input or availability check attempted. The earlier negative v5 human feedback is evidence, not a v6 pass. Updated the 10k-tape field list but did not execute that module. |

**Installation:** normal filesystem approval used; parent-workspace `artifacts/AzerothKart/20261020-011850-809969/install.json`, with verified prior tree in `before/`. Owner can `/reload`, `/akart` and drive either map; hold Space through brief A/D or arrow corrections, then release Space to boost. No other addon/WTF/SavedVariables files changed. No push/tag/release/network traffic/automation.

**Handoff:** focused local commit intended as `fix: make drift charging usable through steering corrections`; resolve hash from `git log`. New handling remains a first tuning pass pending owner feedback. **Next single independent executable task:** the previously scoped original overhead Goblin drag-car sprite for Mirage with alpha/pivot/provenance and primitive fallback. Record v6 handling feedback when supplied before deciding on another tuning change; no new combat or long manual matrix is requested.

### 2026-10-20 01:25–01:34 CEST (Europe/Oslo) — Codex / main, closer Mirage racing view

**Owner feedback and scope:** the supplied screenshot showed working opaque Mirage art, but the whole-map framing made the kart tiny and left dark side margins, losing racing intensity. Prioritized a close racing camera before sprite art. Confirmed canonical remote/main, clean starting HEAD `0ed33c2` and PhilForever local identity/useConfigOnly; read current memory/criteria and affected source/tests. No milestone acceptance promoted.

**Built:** pure `Presentation.cameraViewport/follow/texCoords/clipRect` support a north-up scale-**1.5** view, clamped to the 1024-square world with **60 world units** of heading look-ahead. Mirage fills the existing **800×480** canvas through a crop of the same pooled TGA, exposing approximately 533.33×320 world units. Kart dimensions become **25.5×46.5**, versus 7.97×14.53 in the previous overview: **3.2× larger linearly**. The road is **168** canvas units wide versus 52.5. The view follows the interpolated render pose; the camera never feeds back into simulation. Offset updates and clipping return scalars/reuse the existing view rather than allocating render-time tables.

UI repositions/crops existing gate and perimeter rectangles to the canvas, hiding fully off-screen pieces without introducing a clipping-frame API. Background UVs update only when camera offsets change. A guarded first `SetTexCoord` call preserves the current track/result if cropping is unavailable; the fallback Test Oval stays at its existing fixed overview. Build-matching CalendarFrame texture usage supplied the four-coordinate convention, then actual stopped rendering below checked it. Physics **v6**, drift tuning, input capture, countdown, three-lap timing/results, source geometry/TGA and explicit **9/111/13** allocations are unchanged. Placeholder kart and flat scenery remain future art work; no claim that this finishes the visual identity.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51 --tests presentation ui mirage` | Final PASS — 29 Lua files parsed, three modules passed. Camera scale/look-ahead/world-edge clamps, bounded upright UVs, scalar marker clipping and transform immutability; actual pooled UI geometry, fractional interpolation, frozen Stop/reopen, restart, map switches, texture/crop failure retention/retry and existing race lifecycle. Mirage deterministic synthetic race/actual-input checks remain passing. |
| Initial focused attempts | Presentation-only attempt exposed a test expecting unclamped x=310 at the right edge; fixture moved to an interior pose. First combined attempt then reached an old Oval assertion still expecting CENTER anchors; updated it to the equivalent BOTTOMLEFT rectangle. Rerun above passed. No failed attempt is recorded as a pass. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 45 paths, TOCs, local links, protocol docs and header-only network ledger. |
| `git diff --check` and staged equivalent | PASS — whitespace checks; text normalization notices informational. |
| `C:\Python314\python.exe local-artifacts/install_verified_files.py` | PASS — full prior sixteen-file backup verified; Presentation.lua, UI.lua and README_ADDON.md copied; all sixteen installed hashes matched source. Documentation readme synchronization is recorded below if a later manifest supersedes this one. |
| Actual client through computer-use skill, ~01:30–01:32 CEST | Executed `/reload`, `/akart`, stopped Track selection and Print Probe. Oval loaded normally; Mirage filled the full canvas with a larger north-facing kart and Start strip aligned across the right-hand straight. A partially visible left-side gate clipped at the canvas edge. No visible Lua error dialog. Probe: build1.60.1/70450/interface16001/Camelot; frames/ticks/elapsed/drop/hitches all zero, active=false, stopReason=Track selected, track=mirage_raceway, explicit counts9/111/13; event failures none, focusApi=false, combat/text-focus/keyboard/propagation APIs true. This is static load/UV/alignment evidence only. |
| Moving follow camera, edge transitions while driving, v6 handling, transparent sprites, sustained timing/performance, Lua5.4/full suite and multiplayer | NOT RUN this slice. No Start/driving keys or character-movement automation. Static client display and one allocation readback do not prove motion, game feel or sustained stability. |

**Installation/evidence:** initial camera install manifest is parent-workspace `artifacts/AzerothKart/20261020-013013-732647/install.json`, with verified prior tree in `before/`. After the live check, the installed readme was synchronized with observed static results: final manifest `artifacts/AzerothKart/20261020-013336-810308/install.json`, only README_ADDON.md changed, prior backup verified and all sixteen source/installed hashes matched again. The supplied personal screenshot was not copied into the repo; sanitized scopes are in `docs/evidence/2026-10-20-mirage-static-background.md` and `docs/evidence/2026-10-20-mirage-camera-static.md`. No other addon or WTF/SavedVariables files were edited directly. No scale changes, combat tests, network traffic, push/tag/release or automation. Client left open on Mirage, stopped at tick zero and ready for the owner's Start.

**Handoff:** focused local commit intended as `feat: bring Mirage racing into a close follow camera`; resolve hash from `git log`. Static camera load/alignment is observed on70450; motion/edge/feel acceptance remains pending. **Next single executable task:** create/integrate one original north-facing Goblin drag-car sprite, readable at 25.5×46.5 play size, with alpha/pivot/provenance and primitive fallback. Painterly pit scenery follows, registered to unchanged geometry. M0/M1/M3 and measured multiplayer gates remain open.

### 2026-10-20 11:47–11:49 CEST (Europe/Oslo) — Codex / main, authorized GitHub push

**Scope:** owner explicitly requested pushing to `https://github.com/PhilForever/AzerothKart`. Confirmed the existing canonical checkout, clean `main` at `7acab18`, exact fetch/push remote and repository-local PhilForever identity/useConfigOnly. No gameplay, asset, installation, test expectation or acceptance changes.

**Executed:** inspected `git status --short`, `git branch -vv`, remote URLs and recent commits. A read-only audit of tracked/history paths and obvious secret patterns found no publication blocker: no tracked personal screenshots, exports, installed backups or credentials; network ledger remains header-only and generated concept art has provenance. The default-sandbox `git ls-remote --heads origin` failed with a resolver/thread error; the normally approved network call then succeeded with no remote branches. `git push --set-upstream origin main` succeeded, created `main` and configured its upstream. Local HEAD and `origin/main` both resolved to `7acab189eaa8771c5c52e2cd94e44e7bb08c6ac2` afterward. The handoff documentation is committed and pushed afterward as the final fast-forward update; final remote-ref verification belongs to the command result.

**Validation:** no Lua/client tests rerun for this publication-only task; source/runtime assets are unchanged from the recorded implementation checks. Documentation whitespace is checked before the handoff commit. No force push, tag, release, distribution upload, client input, installer write or scheduled automation. Existing milestone/manual risks remain pending without promotion.

**Next single executable task:** the original overhead Goblin drag-car sprite at the closer Mirage play size, with alpha/pivot/provenance and primitive fallback. Push authorization applies to this requested publication; future automatic publishing is not configured by it.

### 2026-10-20 12:03–12:15 CEST (Europe/Oslo) — Codex, multi-agent documentation checkpoint

**Scope/baseline:** prepare safe Codex/Claude parallel work; no new gameplay or milestone work. Inspected `main`/local `origin/main` at `f923d15f5cc8f306a0b47ad082587474abd1af8d`, last runtime commit `7acab18`, repository identity/history and both worktrees. Existing `AzerothKart-Claude` was clean on `claude/track-ui` at the same baseline. Created the Codex documentation branch `codex/handoff-contracts` in the existing checkout. No other worktree was switched, edited, merged or reset.

**Existing work preserved:** initial Codex status contained untracked `CLAUDE.md` and four empty handoff placeholders. Read them before changes, reported them and confirmed the three unrelated placeholders remain zero-byte/untracked. The relevant existing Claude instructions are retained/extended, and only the explicitly requested `docs/handoffs/codex-latest.md` placeholder is filled. Root `codex-latest.md`, root `claude-latest.md` and `docs/handoffs/claude-latest.md` are not staged. No ambiguous runtime changes were present.

**Documents/contracts:** added `docs/API_CONTRACTS.md` with the actual fifteen-field Physics-v6 state, scalar speed/derived velocity distinction, drift/contact semantics, source signatures, fixed-step/alias ownership, race/countdown/lap timing, interpolation, camera/UV/clipping and geometry-versus-art boundary. Proposed Renderer/GameSession/event-stream/replay/network interfaces remain explicitly unimplemented. The contract describes read-only render consumption as a convention, not enforced immutability/security. No source API changed.

AGENTS now defines Codex/Claude/shared file ownership, function reservations within mixed `UI.lua`, separate branches/worktrees, review and explicit-only integration, no rewriting other work, per-agent handoffs, shared-ledger coordination and serialized installed-client access. `CLAUDE.md` keeps `@AGENTS.md` and now references the shared contracts and canonical handoffs. Added the detailed Codex handoff with verified/pending scopes, API limitations, debt, first Claude task and manual synchronization commands. Updated README/index/architecture links and repaired stale documentation summaries (boolean input versus bitmask, Core's API boundary, actual Physics signatures, v6/counts, implemented local laps and historical publication wording). Roadmap checkboxes are untouched.

| Command/check actually executed | Result and scope |
|---|---|
| `C:\Python314\python.exe scripts/test_lua.py --runtime lua51` | PASS — 29 Lua source/test files parsed; all sixteen modules executed. Includes the v6 10,000-tick seed1729 tape comparing every one of fifteen fields at 30/60/144 simulated render Hz, mechanics/collision/input/loop tests, race/lap/checkpoint/camera tests and mocked lifecycle/pooling. Same-runtime offline evidence, not client timing or multiplayer proof. |
| `C:\Python314\python.exe scripts/build_mirage_layout.py --check` | CHECK PASS — existing sixteen-vertex/four-gate authoring guide reproduces; no files written. Its 0.46875 overview fit is separate from the runtime 1.5 camera. |
| `C:\Python314\python.exe scripts/build_mirage_background.py --check` | CHECK PASS — existing 1024-square BGRA32 asset reproduces, 4,194,322 bytes/eight road-orientation landmarks, SHA-256 `27a5e56ac98bd5ef6185b10ba734cd90ba483887d8e17b64d6ed6c35075c7714`. |
| `C:\Python314\python.exe scripts/validate_project.py` | PASS — 45 expected paths, TOCs, local docs links, protocol and header-only ledger. |
| Read-only Python handoff checks | PASS — first non-empty Claude instruction imports an existing AGENTS.md; local Markdown links resolve; the three unrelated handoff placeholders remain empty. This is static import/reference verification, not an executed Claude Code session. |
| `git diff --check` / staged equivalent; source-to-contract review | PASS — documentation whitespace and independent review found no blocking mismatch. `git diff f923d15 -- addon scripts tests` was empty: runtime/assets/tests are unchanged. |
| Lua5.4/native Lua, Claude Code runtime/import execution, actual Forever/client install and manual acceptance, multiplayer and broad performance/scale checks | NOT RUN this checkpoint. Prior scoped client evidence is linked in the handoff; no new client pass or milestone completion inferred. |

**Integration state:** documentation committed locally on `codex/handoff-contracts` (resolve the completed checkpoint with `git log -1` there). Main and Claude remain at `f923d15`; no automatic merge/fast-forward/cherry-pick/rebase, push, tag, release, deployment or client input. The final report supplies the exact reviewed commit for a manual `git -C ../AzerothKart-Claude merge --ff-only <hash>` after clean-status/branch checks, review and authorization. If Claude has since begun work or diverged, stop and coordinate; do not force synchronization.

**Handoff/readiness:** Claude can begin bounded visual development after that reviewed checkpoint is present and its file/function scope is reserved. First recommended task: one original overhead Goblin drag-car sprite with stable alpha/pivot, once-only load/fallback and sprite-safe drift/boost tint, leaving simulation/collision/race/capture unchanged. Current UI/controller coupling, v6 handling and moving-camera acceptance, scale review, transparent sprites, full current race UI/performance and measured multiplayer gate remain outstanding. M0/M1/M3 stay open. This task ends at the handoff; no sprite or next-milestone implementation started.


### 2026-10-20 13:26 CEST (Europe/Oslo) — Codex review of Claude sprite and WC3 asset direction

**Scope/branches:** owner supplied Claude's changes for review and reaffirmed Warcraft III asset use. Inspected canonical identity, branches/status/worktrees and both Claude commits: `520275e07990a626ac25818402eeee55ab956d0d` plus `46931e16de940e0ab0dc59057b0484c93f78670e`. Created isolated `codex/claude-assets-review` in `AzerothKart-Codex-Review` from immutable `46931e1`. Main/local origin/main remain `f923d15`, the canonical Codex checkout remains `5570968` and Claude's clean checkout remains `46931e1`. Preserved the canonical checkout's three untracked zero-byte handoff placeholders. No rewriting, automatic integration or edits in Claude's checkout.

**Claude implementation recorded from its handoff:** one original procedural 64×128 straight-alpha Goblin Drag Car, deterministic standard-library generator, source sheet/preview, additive presentation metadata, once-only guarded kart load and cached vertex tints. The padded quad is 20×40 world units (30×60 on Mirage); visible body stays inside 17×31 (25.5×46.5 on Mirage). No extra regions; explicit counts remain 9/111/13. No archived/game texture was imported.

**Review disposition:** approved the shared visual assertions in `tests/test_ui.lua`, one creation-time load call in `UI.Create` and additive contract metadata. No blocking regression or source correction found. Capture/lifecycle/clock/race assertions were retained; protected simulation/input/geometry/race/bootstrap/TOC source is unchanged from the prior checkpoint. The six fallback cases cover initialization-time refusal, not future errors in phase tint calls. The 900-frame equivalence test compares all Physics fields plus selected race/checkpoint fields, not all nested state. The contract now states those exact limits. Client appearance is not inferred from the preview.

**Accepted direction:** ADR0009 accepts Warcraft III game/community assets as project sources, superseding ADR0005's original-only preference for that material. Updated AGENTS, README, DECISIONS, ASSETS, index and source ledger to agree, following existing owner authorization. Future WC3 visual tasks do not need repeat art-source approval. Preserve per-file author/source/terms/status/modifications/credits and community conditions; prefer suitable existing WoW texture paths. WIIIUI is technical/community precedent; a blanket redistribution grant was not established. Corrected the unsupported categorical claim about the entire WIIIUI repository lacking a license to the limited inspection finding. No third-party asset was downloaded/imported by this review. Existing release authorization and accurate file status still apply.

| Command/check actually executed by Codex | Result and scope |
|---|---|
| `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests presentation ui` | PASS — 29 Lua files parsed; both selected modules executed with canonical ignored Lupa2.8 dependencies supplied via this process's PYTHONPATH. Once-only load, cached tints, six initialization failures, 900-frame sprite/primitive equality through tick 1275 and existing lifecycle/camera/race/pooling assertions. |
| `C:/Python314/python.exe scripts/build_kart_sprites.py --check` | CHECK PASS — 32,786 bytes, 64×128 BGRA32 straight alpha, 3,190 visible/2,562 opaque pixels; SHA-256 `cc7c1c6928501bcb9943040c13c478efb7ac08ddab47e7fa527e11f7d3bb126a`. |
| `C:/Python314/python.exe scripts/validate_project.py` | STATIC PASS — 48 expected paths, TOCs/docs/protocol/header-only network ledger on Windows. Repeated after documentation reconciliation. |
| Preview inspection and independent source review | No blocking visual-contract regression found; source PNG board viewed, not a client rendering check. |
| `git diff --check` / staged equivalent | PASS — final documentation whitespace. |
| Actual Forever sprite load/alpha/filtering/facing/tints, deployment/reload/restart, full current Lua suite/Lua5.4, sustained performance/scale and multiplayer | NOT RUN by Codex in this review; no client availability assertion or new acceptance result. |

**Attributed Claude evidence (not independently rerun here):** its Linux Python3.10/Lupa2.8 session reports all sixteen modules/29 files in Lua5.1 and Lua5.4, sprite/background/layout reproduction, identical sprite bytes on Python3.13 and clean diff whitespace. Its structural run reported two pre-existing Windows-path link failures; Codex's Windows run above passes. Claude reported no installation/merge/push and left sprite client checks pending. Its original handoff is preserved; this entry incorporates its requested shared-ledger update with attribution.

**Handoff/outstanding:** latest Codex handoff records review approval, actual tests, accepted source rules, unchanged source boundaries and exact conditional synchronization commands. This review is documentation only on top of Claude's committed implementation; resolve its completed commit with `git log -1 codex/claude-assets-review`. No merge, push, tag, release, deployment, CVar change, client control or new gameplay work. M0/M1/M3 and multiplayer gate remain open.

**Next single task:** coordinated short client sprite check using Claude's procedure; while access waits, Claude can prepare Mirage scenery v1 under accepted ADR0009 against unchanged geometry and pooling budgets. Integration into main or another agent worktree still requires explicit authorization under the shared workflow.

### 2026-10-20 18:53–19:06 CEST (Europe/Oslo) — Codex / Test Oval swept solids

**Owner scope/priority:** continue the collision plan, place fixtures on Test Oval only and add no Mirage obstacles. Multiplayer now has much higher priority than dedicated ghosts/time trials. Release target: Codex's mechanical/race/network responsibilities through verified multiplayer plus Claude's three ready maps/eight ready karts. Accepted ADR 0010 and aligned AGENTS/ROADMAP/DECISIONS/RELEASE/MULTIPLAYER/README; no acceptance box checked or release/push permission inferred. Priority commit `7b6c6a7`.

**Repository/preservation:** confirmed canonical remote, branches/worktrees, local PhilForever identity/useConfigOnly and clean Codex review checkout at `1f8f208`. Created `codex/oval-obstacle-collision` there and reserved exact file/function scope in the Codex handoff before implementation. Claude advanced independently to `5734335`, with untracked `Claude outputs/`; preserved without reading/staging/editing. Canonical Codex remains `5570968` with its three pre-existing zero-byte untracked placeholders. Main/local origin/main remain `f923d15`. No merge/reset/rebase/cherry-pick/force push or unrelated edit.

**Built:** Test Oval v2 has two physical 32×24 rectangles at bottom-left (270,400) and (490,60). Its road mask, spawn and gates remain unchanged. `surfaceAt` classifies physical obstacle footprints including edges as wall; only new `resolveMovement(previousX,previousY,targetX,targetY)` applies conservative 18-unit square center clearance. Whole-segment earliest-contact sweeps include the perimeter and expanded solids, retain tangent movement and snap blocked axes to exact planes. Face arrival/grazing/moving-away are free; inward motion hits. Three movement iterations, at most four recovery passes and no temporary tables; nearest-face overlap recovery is guaranteed for these disjoint perimeter-contained fixtures, not arbitrary clusters.

Physics v7 prefers the optional movement hook and otherwise retains prior behavior. All fifteen state fields, v6 steering/drift constants, 60 Hz/five-step loop and race/input rules remain unchanged. Contact uses one impact increment and speed×0.25 scrub per step, clears drift/grace/boost/slip/steering and retains no boost acceleration reward. MirageRaceway v1 receives no obstacle data/hook or source edit. No vehicle-to-vehicle, dynamic/polygon collisions, network code or new gameplay framework.

**Visible slice/shared scope:** only `UI.drawTrack/layoutTrack` changed, adding two pooled red ARTWORK markers from the authoritative physical rectangles and hiding them on Mirage. Current explicit allocations 9 frames / 113 textures / 13 font strings, exactly two more textures and no extra Frames. No per-tick UI creation, file loads or chat. Capture/controller/race/clock bodies and Presentation are unchanged. Shared UI tests update five explicit budget expectations and add marker geometry, actual fixed-step collision, hidden-on-Mirage and pooled-switch coverage; prior mechanics assertions remain intact. Registered `test_obstacles` in the existing runner; no TOC/load-order change. API/architecture/physics/track/test/feasibility/manual docs describe the branch and conservative clearance. Independent read-only review found no blocking regression.

| Command/check actually executed | Result / scope |
|---|---|
| `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests track obstacles physics drift surface determinism mirage ui` | PASS — 30 Lua files parsed, all eight selected modules. New sweep/tangent/corner/graze/recovery cases and 900-tick guaranteed-obstacle-hit seed1729 tape across all 15 fields at 30/60/144 simulated render Hz; existing 10k-tick seed 1729 replay, handling/drift/surface, Mirage synthetic race and mocked UI lifecycle/capture/pooling. Pinned Lupa2.8 supplied through process-local PYTHONPATH from canonical ignored dependencies. |
| Final `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests obstacles` | PASS after a narrow additional regression: charged+boosted solid contact loses boost reward, scrubs once, clears all contact state, preserves prior state and immediately releases when moving away. Runtime code unchanged after combined pass. |
| Delegated geometry implementation check | Agent independently ran Lua5.1 `--tests obstacles track`, PASS, 30 parsed files, before root's combined run; no additional full suite. |
| `C:/Python314/python.exe scripts/validate_project.py` | STATIC PASS — 48 expected paths, synchronized TOCs, docs links/protocol/header-only ledger; no Lua executed by this validator. |
| Independent runtime/test review; protected-source diff | No blocking issue found. Diff from 1f8f208 is empty for MirageRaceway, Presentation, Assets, Input/Loop/Core/Race/Laps/Checkpoints; other worktrees preserved. |
| `git diff --check` / staged equivalent | PASS — reviewed file scope and whitespace before focused commits. |
| Actual Forever obstacle appearance/feel, deployment/reload, integrated latest Claude visuals, Lua5.4/full current suite, broad performance/scale and all multiplayer transport measurements | NOT RUN this slice. No client-availability claim, milestone completion or live-network result inferred. |

**Observed offline output:** oval drift tiers remain 30 ticks / 49.78° and 60 ticks / 105.64°, on road throughout. Mirage synthetic countdown/race remains 1890 ticks; sprite/primitive scripted Mirage comparison matches through tick 1275 with all five phase tints. Mock UI 9/113/13 through 1,001 updates; 0 mocked combat propagation calls. These are same-runtime offline checks, not actual client timing, handling acceptance or cross-client determinism.

**Risks/integration:** conservative square clearance may look generous at corners; future overlapping obstacles require an authored recovery policy. Starting invalid poses can recover farther than checkpointMaxStep, which the existing checkpoint guard consumes without an award. The shared marker/contract additions await Claude/integrator review before authorized integration. Feature source descends from the shared sprite review, not Claude's latest installed scenery/shadows; no deployment was attempted and no art was overwritten. Claude's handoff reports the current install at 0bf6fd0; no new client test was requested/performed. The short 3-step obstacle probe is prepared and NOT RUN in the manual checklist. M0/M1/M3 and measured multiplayer gates remain open.

**Commits/handoff:** focused feature intended as `feat: add swept Test Oval obstacle collisions`; resolve its completed hash with `git log -1 codex/oval-obstacle-collision`. Updated `docs/handoffs/codex-latest.md` with exact scope, contract/budget changes, actual tests and integration limits. No push, tag, release, client control, installation or changes to SavedVariables/other addons.

**Next single executable task:** build the bounded opt-in two-client addon-transport probe/accounting harness for M2, covering send outcomes, receive/loss/duplicate/order counts, round-trip latency, throttling and disconnect/reconnect with explicit rate/size/duration caps. Keep actual two-client results pending until executed; choose replication from evidence, and defer dedicated ghosts/time trials.

### 2026-10-20 17:33 UTC — Codex / bounded opt-in WHISPER probe

**Scope/baseline:** owner authorized the next M2 harness task. Confirmed remote/branches/worktrees and clean `codex/oval-obstacle-collision` at `b1cd42c`, then created `codex/transport-probe` in the same Codex checkout. Reserved pure codec/accounting, guarded adapter/Core wiring, TOCs/tests/validator and network/memory docs before implementation. Canonical checkout/empty placeholders and Claude's checkout were preserved. At final inspection Claude remained at 5734335 with active Presentation/UI/test edits and untracked `Claude outputs/`/`scripts/build_wc3_kart.py`; these were neither read as authoritative commits nor modified/staged. Local identity remains PhilForever with useConfigOnly. No external peer message, client input, deployment, merge, push or release.

**Implemented:** pure `NetworkProbe.lua` with injected time/send callbacks and bounded counters/maps; `TransportProbe.lua` with explicit `/akart net start|listen Peer-Realm Session [rate] [bytes] [seconds]`, `stop/report/evidence`. Directed WHISPER only: separate reverse windows, no simultaneous bidirectional DATA, PARTY, lobby, state replication or capacity promise. Both testers explicitly arm the same fresh six-uppercase-alphanumeric token and expected full event identity. ASCII case comparison only; realm normalization/actual event spelling remain unverified.

Ten-byte printable envelope, exact DATA 16/64/128/220 bytes and 16-byte ACKs; rates 0.5/1/2/4, integer duration 10–120 s, max 480 sequences. One dueDATA/update/no catch-up burst; one ACK per unique DATA, four-token/four-per-second ACK guard, no retries/ACK-of-ACK. Bound receive/rejection/result/timing maps; remember up to 64 local IDs and reject reuse. Listener arm expires 30 s; active-listener unique DATA idle expires 5 s; normal window has 10 s drain. Sender 5 s ACK deadline / 10 s drain anchor to original send/window time, including during receive and after long callback hitches. No resumption after terminal state.

Guard API/enum registration/send returns; unknown/throwing/failed/throttled/opaque results stop rather than guess legacy success. Reports retain raw categories/rejection reasons without identities; counters and nearest-rank same-clock RTT/arrival gaps use NA with no samples. Frozen elapsedSeconds includes arm/wait/drain, distinct from configured DATA duration. Four capped 160-character bitmap chunks per set (`sent/received/acks_sent/acks_received`, at most 480 positions each) support forward/ACK reconciliation. Missing ACK alone is not DATA loss. Byte totals distinguish attempted payloads from 7 prefix bytes/call; transport overhead remains unmeasured. No per-packet chat, automatic CSV/SavedVariables export or personal logs.

**API evidence:** inspected local primary build70450 `ChatInfoDocumentation.lua` prefix/register/send/event declarations and `ChatConstantsDocumentation.lua` enum names, under the pinned 1.60.1.70450 source tree. No upstream code/assets copied. Source expects registration Success/DuplicatePrefix and named SendAddonMessageResult values; installed-client calls/enums and sender/realm behavior were not executed. Any contradiction requires review.

**Integration boundary:** Core reuses its existing bootstrap frame, forwards full CHAT_MSG_ADDON arguments and routes net commands without toggling the kart. Network registration/update work exists only while explicitly armed and stops on cancel/combat/world/logout/reload/local-driving/error conditions. No UI input/capture/geometry/physics/race/render source changes. Both TOCs insert NetworkProbe/TransportProbe between UI and Core (14 modules); structural validator and test runner/mock order aligned. Pool remains 9/113/13. Shared contracts/architecture/manual/network docs updated; no acceptance checkbox promoted.

| Command/check actually executed | Result / evidence |
|---|---|
| `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests network_probe transport_probe ui` — final | PASS — 34 Lua files parsed, all three selected modules. Codec bounds, pacing/skips/caps, outcome/error/unknown/throttle classes, same-clock timing/NA/nearest rank, long-hitch anchored sender/listener expiry, exact final slot, late ACK/deadline retention, ACK flood cap, malformed/stale/duplicate/reordered traffic, reconnect via explicit fresh state, bounded maps/bitmaps and frozen elapsed. Pinned Lupa2.8 via process-local canonical dependency PYTHONPATH. |
| Adapter/Core/UI coverage in that command | PASS — no startup API/event/update/UI allocation; guarded capability/registration/event failures; lifecycle/no-resume/session-cache limits; bounded output; actual Core slash/full event routing; retained UI/capture/race/sprite/fallback/pooling. Mock 9/113/13 through 1,001 updates and 0 combat propagation calls. |
| Initial focused attempt / corrective review | Initial engine passed, adapter failed an old two-map evidence count after expansion to four; changed count to 13 lines and asserted all four kinds. Independent review then found callback-relative sender drain could extend observation; anchored logical deadlines and added hitch/update/receive regressions. Re-reviewed fixed; subsequent/final focused passes above executed. No failure counted as a pass. |
| `C:/Python314/python.exe scripts/validate_project.py` | STATIC PASS — 52 expected paths, synchronized 14-module TOCs, protocol/local links and header-only 60-column ledger. No Lua/client execution by this validator. |
| Independent read-only source/timing review | Original timing issue fixed; no remaining material issue found. |
| `git diff --check` / staged equivalent | PASS — source/docs scope and whitespace; CRLF normalization notices informational. |
| Actual Forever registration/send/receive/enums, deployment/reload, two-client/reconnect/PARTY/bidirectional/4/8/performance and Lua5.4/full current suite | NOT RUN. No current transport result, participant capacity, race replication or milestone completion inferred. |

**Remaining limits:** API signatures are source expectations, not client behavior. Full event sender spelling/cross-realm reachability, actual enum returns, callback/queue cost, sustainable rates and recovery need real clients. The probe's rate guard is not a measured capacity failure; observed deadlines/RTT include local scheduling and peer ACK work. Current addon version is still a developer prototype. CSV stays header-only; no fake zeros or synthetic test rows.

**Handoff/commit:** intended focused commit `feat: add bounded opt-in transport probe`; resolve completed immutable hash with `git log -1 codex/transport-probe`. Updated Codex handoff with exact commands/semantics/tests and deployment boundaries. No changes to Claude's source/handoff, installed art or other addons/SavedVariables.

**Next single task:** review/integrate with Claude's current deployed-art source, then execute the first consenting two-client 16-byte/0.5 DATA/s WHISPER window using the network checklist. Verify enum/source behavior before sends and reconcile both DATA/ACK maps before escalating or selecting replication. If real-client integration is unavailable, prepare an offline reconciliation helper while all actual measurement rows remain pending. Multiplayer retains priority over dedicated ghosts/time trials.


## 2026-10-20 18:22 UTC — reviewed integration and explicit run exits

**Scope and preserved work:** owner explicitly requested fixing the menu and then reviewed integration with Claude and the first lowest-rate two-client window. Started from clean `codex/transport-probe` at `de7a63e` in the existing Codex Review worktree and created `codex/menu-integration`. Reviewed immutable Claude `812d132` (runtime `cf71394`) and merged it with explicit owner authorization. Reconciled five conflicts in UI layout comments/retained Oval markers, CHANGELOG, addon README, ASSETS and INDEX. No other checkout, untracked placeholder/output, SavedVariables, other addon or remote branch changed.

**Implemented:** mouse-down previously stopped/disabled Stop before its own OnClick. Removed that handler, global-event subscription/capture requirement and compensation latch. Unsupported keys are consumed without stopping or clearing held input. Stop/Escape/Close deliberately end the run; Enter/numpad Enter releases for chat; actual focus and lifecycle guards remain. Start/Restart stays a fresh countdown. Results now offer Restart, track choice or Close. Mirage status no longer calls the completed scenery a blockout. [ADR 0011](adr/0011-explicit-drive-exits.md) supersedes the old click/unknown-key policy; historic evidence is retained as prior-source evidence.

**Claude work integrated, evidence attributed:** scenery v1 `76af4aa`, attached shadows `0bf6fd0`, and Goblin Mortar Trike `cf71394`, plus handoffs/owner approval through `812d132`. Claude's pending entries report Python3.10/3.13 byte-identical generators, Lua5.1/5.4 suites and verified earlier installs. Those are Claude-reported checks, not new Codex executions. The owner's [scenery screenshot](evidence/2026-10-20-mirage-scenery-owner-check.md) and [trike/shadow approval](evidence/2026-10-20-trike-and-shadows-owner-approval.md) are scoped acceptance, not timing measurements. Directional-sheet contracts are now reviewed/implemented; Physicsv7, 15 state fields, Mirage geometry, fixed-step/race semantics and transport bounds remain unchanged. Combined pool is 9/113/13. WC3 provenance/credits and unresolved redistribution status are retained for release review.

| Executed check | Result |
|---|---|
| `scripts/test_lua.py --runtime lua51 --tests input presentation ui network_probe transport_probe` | PASS: 34 files parsed, five modules. Initial attempt exposed a test fixture's hidden window after combat; show the window before asserting Start can succeed, then final run passed. |
| `scripts/test_lua.py --runtime lua51` | PASS: all 19 modules, deterministic replay, geometry/collision, race timing, sprite/primitive equivalence and bounded probe accounting. Pool9/113/13 through1,001 mock updates; no per-update UI allocation/chat. |
| `scripts/validate_project.py` | STATIC PASS:56 expected paths, synchronized TOCs, local links/protocol and header-only network ledger. |
| `tests/test_install_local.ps1` | PASS18, SKIP3 junction fixtures (creation denied). Fresh/repeated/backup/hash/failure/WhatIf checks used retained workspace fixtures only. |
| Independent Claude runtime review / asset hashes | No blocking source regression. Trike `a723b067…3208`, scenery `cd5aecb9…c567e` match handoff. Shared visual assertions preserve lifecycle/race checks; contracts reconciled to113 textures. |
| Actual combined-client menu, live API/transport, two-client window/reconnect, performance, held-input Alt-Tab, Lua5.4/native Lua | NOT RUN at this implementation checkpoint. Owner confirmed only one client available; no synthetic ledger rows or network sends. |

**Risks:** build70450 lacks the previously probed application-focus getters; removing the old unknown-Alt-key exit leaves held-input Alt-Tab unverified. Trike art overhang and4MiB raw sheet remain disclosed, client load/FPS cost unmeasured. No ghost/time-trial detour or broad replication engine. Source publication/release is not performed.

**Next:** finish serialized install/menu observation, then retain the precise [first two-client window](../tests/MANUAL_NETWORK_CHECKLIST.md) pending a second consenting peer. Do not escalate rates or choose replication architecture without real reconciled evidence.


**Asset reproducibility, 18:23:52 UTC:** all three check-only generators passed in the combined worktree using Windows Python3.14: `build_kart_sprites.py --check` (`cc7c1c69…126a`), `build_mirage_background.py --check` (`cd5aecb9…c567e`), and `build_wc3_kart.py --source ../AzerothKart-Claude/local-artifacts/third-party/goblin-mortar-trike --check` (`a723b067…3208`). Background's initial invocation lacked pinned Lupa; retry with canonical PYTHONPATH passed. Sources/assets unchanged; no third-party download or raw source committed.


## 2026-10-20 18:25–18:31 UTC / resumed 21:59 UTC — installed menu evidence

Implementation/integration commit: **`7fcdd8919831c6e453bb81a21debc8a190f8b9df`**, branch `codex/menu-integration`, parents `de7a63e` and reviewed `812d132`. No push, tag or release. Local main/origin/main unchanged. Before deployment read Claude's `cf71394` install manifest; serialized `install_local.ps1 -Overwrite` backed up the entire previous addon and verified 20 source files. Manifest and prior files are retained under ignored `local-artifacts/install-backups/20261020-202526-131-567cfd9612074e2d957df74433a02f53/`. Independent hash comparison after resumed work matched all 20 files.

**Executed actual-client check:** `/reload` loaded the combined source. Oval fixtures/trike visible; stopped Track selector loaded Mirage scenery/trike with no Oval fixtures. Start/countdown enabled Stop. While stationary, M was consumed and left the run active; left/right canvas clicks also left it active. Stop's own OnClick ended it with reason `Stopped`, tick 2715, race 42.25s, and enabled Start/Track. New result actions fit. Print Probe and subsequent passive observations retained the stopped sample. Restart began fresh 3 / tick 0 on Mirage; Escape ended that separate run, also opening the normal WoW menu (dismissed with a second Escape). Close hid the window; local chat worked. No WoW character movement/combat automation, settings change or broad manual matrix.

**Exact first stopped sample:** 1.60.1/70450, 16001, Camelot; 8515 frames / 2715 ticks; maxElapsed 0.0810s; dropped 0 / hitch 0; accumulator 0.00300; active 45.2530s / simulated 45.2500s; callbackHz 188.16; 9 frames / 113 textures / 13 fonts; inactive/Stopped/Mirage; no event registration failures; focus API absent, combat/text/keyboard/propagation APIs present. This stationary sample is not sustained FPS/CPU/handling acceptance. The separate short Escape sample showed 0.017s dropped time, not a timing pass.

**No-send network readback:** registration/send function types and selected enum constants yielded `function function 0 1 0 3 8`, matching source expectations. No registration/send call was made. At resumed 21:59 UTC `/akart net report` returned `Azeroth Kart net: Idle: no experiment run`. No continuous checks are claimed for the interruption. [Exact sequence, output and limits](evidence/2026-10-20-menu-integration-client.md).

**Coordination on resume:** Codex worktree remained clean at 7fcdd89. Claude had independently fast-forwarded onto it and committed only a handoff reservation (`f675610`) for effects/vehicles, with its output folder still untracked. Read its scope; no edits to its worktree, deployment or rendering are made by this handoff update.

**Still NOT RUN:** held throttle/drift during incidental clicks, overlapping/outside panels, current Enter during active capture, held-input Alt-Tab, moving camera/sprite edges, sustained performance, actual prefix/send returns and all two-client/reconnect/scale measurements. No milestone boxes were completed. Owner explicitly confirmed no second client: first lowest-rate directed WHISPER window remains the next live task, CSV header-only. If a future run still has one client, the next independent executable task is an offline report/evidence reconciliation helper for the existing four maps, without inventing measurements or choosing replication architecture.


## 2026-10-21 00:17 CEST — close results and plain connection-test guidance

**Scope:** owner reported the stopped panel had no way to dismiss it and the prior network handoff was unclear. Created `codex/results-dismiss` from clean `bdb44d1` in the existing Codex Review worktree. Reserved the summary block, dismissal lifecycle/test callbacks, explicit local chat-help output and shared docs. Claude remains at `f675610` with its effects/vehicle reservation and untracked output folder preserved. No merge, push/release, artwork/physics/geometry change or multiplayer engine.

**Implemented:** added the pooled **Close results** button beside Restart. It hides only that terminal panel, retaining lap times, result, pose, clock and stopped HUD. Dismissal is tied to the terminal race identity so repeated Stop, close/reopen, idle updates and refused Starts cannot resurrect it. Successful Start/map selection clears it; the next ended run still shows results. Outer Close continues to hide the whole addon. No active-run capture/input changes. One pooled button raises explicit wrappers to **10 frames /113 textures /13 font strings**.

**Usability:** `/akart net help` now prints six bounded lines explaining a connection test with a friend, roles/order, fresh code, two-minute wait, report/evidence and cancellation. Reading help never arms/registers/sends or resets an existing experiment. [NETWORK_QUICK_START](NETWORK_QUICK_START.md) supplies exact steps and clearly distinguishes chat commands from the driving-statistics Print Probe button. It retains first-run compatibility review and the detailed evidence procedure. Owner has no second client available; nothing is requested until a friend/second client is ready.

**Executed:** `scripts/test_lua.py --runtime lua51 --tests ui transport_probe` PASS: 34 Lua files parsed, two modules. Dismissal snapshots/hidden-state retention/new-run reset, working controls, unchanged pooled counts through 1,001 mock updates and no-side-effect bounded help tested. An earlier focused UI-only check also passed. Windows Python3.14/pinned Lupa2.8 via canonical ignored dependency path. `scripts/validate_project.py` STATIC PASS56 paths before final docs. Initial count-edit script asserted six occurrences instead of five and exited without writes; corrected the count, then applied the pool updates. No failed Lua test is being reported as a pass.

**Pending at implementation checkpoint:** installed button/help behavior, moving/held-input tests, Lua5.4/full repeated suite, actual prefix/send calls and all two-client transport measurements. No milestone boxes completed. Next: serialized backed-up install and a short stopped-panel/help check; first real connection window stays pending a consenting second player.


### 2026-10-21 00:23 CEST — preserve the concurrently installed effects

Claude completed `c6e1b5e` and installed it at22:18:43UTC, after the prior20-file hash check but before the00:19 CEST menu installation. That installation backed up all prior files and preserved both extra effect atlases but replaced its UI/Presentation/README. Detected the shared-target overlap on the immediate post-install handoff read; no client reload occurred between our install and detection. Restored the implementation through reviewed integration of immutable Claude handoff `1004e73` into this feature branch, retaining Close results and chat help. No other checkout reset/merge or source deletion.

Independent source review found additive Presentation effects and38 pooled UI textures only, with no authoritative state/input/race/lifecycle mutation. Resolved four conflicts in CHANGELOG/API_CONTRACTS/ASSETS/UI test counts; current explicit pool **10/151/13**. Contracts mark effects reviewed/implemented and limit particle-repeatability claims to identical sampled-state/update sequences. Original atlases/credits/source hashes retained. Claude's reported dual-runtime and generator checks remain attributed in its handoff; no effect appearance/cost or multiplayer capacity inferred.

Executed combined `scripts/test_lua.py --runtime lua51 --tests presentation ui transport_probe`: PASS34 parsed files, three modules, including dismissal, six-line idle/active help invariants, on/off effects simulation equivalence and stable10/151/13 pool. STATIC validator PASS61 paths. The helper wording was corrected to uppercase codes and waiting about2m15 until BOTH sayStopped (the listener timer begins at firstDATA), with adapter-only rerun PASS before the integration pass. First actual two-client window remains NOT RUN.


### 2026-10-21 00:24–00:28 CEST — combined install and live Close results check

Merged preservation commit **`8195da9`** contains the button/help plus reviewed Claude effects (`1004e73`/runtime`c6e1b5e`). Final backed-up installation verified 22/22 source hashes, no extras, manifest `local-artifacts/install-backups/20261021-002417-215-569e7e1336304203b52dae42c3cc8849/install.json`. The earlier 00:19 backup retains the pre-overlap effects files. No other addon/WTF data changed. Source effect-generator check PASS for both unchanged atlases; final combined focused Lua5.1 modules PASS and static 61-path validator PASS.

**Actual client:** recovered a fresh WoW handle after a client restart, then normal `/reload` and `/akart`. Started a stationary Oval run and used Stop (tick 812, race/current 10.53s, displayed sample 13.5s). **Close results** button appeared beside Restart and dismissed only the panel; main window/track/kart/HUD remained visible, Start/Track enabled, stopped state unchanged. Typed `/akart net help`: six expected guide lines printed; no test armed or send invoked. Final addon remains open/inactive with summary hidden and chat closed. No character movement/combat or authoritative state injection. No sustained performance/effects-motion acceptance inferred.

**Remaining NOT RUN:** actual close/reopen dismissal and finished/interrupted dismissal variants (covered offline), moving VFX/readability/cost, full repeated runtime matrix and all two-client delivery/latency/loss/throttle/reconnect. No milestone checkboxes completed; ledger remains header-only. Named handoff now reflects the combined source/installed state and cautions against overlapping standalone-branch installs. Next live task is the personalized lowest-rate connection test when a consenting second player is available; no test requested until then.

## 2026-10-21 00:52 CEST — Forever names and IOU route correction

**Milestone:** M2 experiment correction, no milestone completion. Branch `codex/forever-probe`, base `8e34e75`. Clean starting tree and all three existing worktrees inspected; Claude remains `1004e73`, its untracked output preserved. Only the task files are staged. No push/release, IOU modification or gameplay feature.

**Reported failure reproduced in source:** a full first-name/surname command made the old parser treat the session as a numeric rate; the pure validator separately demanded a fictional realm suffix. The invalid command was refused before prefix registration/send, so this is not a transport failure measurement. The owner confirms no realms on Forever. User identities are omitted from committed examples/evidence.

**Implemented:** complete typed Forever-name canonicalization (96 raw bytes, ASCII-space trim/collapse, control/DEL/pipe rejection), complete native sender comparison with ASCII case folding only, quoted/unquoted peer parsing and numeric session support. Ambiguous unquoted commands ask for quotes. Explicit `SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED` route, `WHISPER_LOGGED` reports/CSV label, actual chat-lockdown guard, no fallback. Existing rates/bytes/windows, DATA/ACK accounting, pacing, enum refusal, bounds and lifecycle remain intact. Core ignores unlogged events. Physics/UI/rendering/assets are unchanged.

**Reused evidence:** read-only sibling `IOU-GitHub/transport.lua` and `docs/connection-test.md` document four exact round trips on 16 October, IOU0.3.2/build70425, including UTF-8 and 239/240-byte messages. Local build70450 source declares logged send (nullable result) and logged event. Basic compatibility is established by IOU; this is not an Azeroth Kart sustained throughput/latency/reconnect pass. ADR0012 and affected contracts/help/guides now retain that distinction.

**Executed:** `scripts/test_lua.py --runtime lua51 --tests network_probe transport_probe ui` with Windows Python3.14/pinned Lupa2.8: PASS,34 files parsed/three modules. Includes full names/surnames, ASCII normalization, UTF-8/hyphens, wrong-surname refusal, quoted/unquoted grammar, numeric code, optional settings, ambiguous/malformed input, missing logged API/no fallback, chat lockdown, unchanged pacing/accounting/cleanup and logged Core forwarding. UI still10frames/151textures/13fonts, original lifecycle/drive equivalence checks pass. `scripts/validate_project.py`: STATIC PASS61 paths/TOCs/links/ledger. `git diff --check`: PASS. Read-only independent code review: no actionable defect. No broad repeated matrix or live traffic.

**Deployment/client:** preflight22/22 hashes match combined8195da9 and target has22files; Claude handoff/status checked. New install and local no-send help/readback check follow, with their actual results recorded separately. Two-client registration/send returns, sustained RTT/loss/throttle/reconnect are NOT RUN; no new CSV row. Both testers must update before the next attempt.

**Next exact task:** use a fresh shared code and the corrected full-name commands for the lowest-rate logged window, then reconcile both reports and four sequence maps. No capacity or multiplayer architecture decision yet.

### 2026-10-21 00:53 CEST — correction installed; friend package prepared

Implementation commit **`8f66c5a`**, branch `codex/forever-probe`. Immediately before installation, Claude remained1004e73 and the target again matched all22files in the prior combined8195da9 manifest. Authorized `scripts/install_local.ps1 -AddOnsDirectory <Forever AddOns> -Overwrite` completed: backup verified,22/22 source hashes verified, no extra target files. New ignored manifest:
`local-artifacts/install-backups/20261021-005314-298-f5ce5642e61b4729a8ed4e8b3d553eb0/install.json`.
No other addon, player data or WTF/SavedVariables was changed.

Prepared local friend-install ZIP only (not published/released): `local-artifacts/bundles/AzerothKart-forever-fix-8f66c5a.zip`,22 addon files under one `AzerothKart/` directory,2,975,544bytes. Every decompressed file hash matches source; archive SHA256 `8bfc6a11d462b65190352fa9fe4e03531b605acb43461d9845a1183d19745a99`. The owner can share it with the consenting tester; this agent sent nothing externally. Both must reload the updated build before testing.

The final documentation check initially caught three files written in mixed encoding. Normalized those files to UTF-8, reran structural validation successfully, and corrected the unpublished own implementation commit before deployment. Final Lua focused results remain PASS; no runtime code changed after them.

**Client checks NOT RUN:** only the app/window inventory was read. Owner requested less computer use, so no activation/input/reload/help/API readback or network arm/send followed. New source is installed but not proven loaded in the running client. Actual two-client results, sustained traffic and reconnect remain NOT RUN; CSV unchanged/header-only. No milestone completion or push/release.

**Next exact task:** both clients update/reload, listener then sender using opposite complete character names and a new shared code; execute the first default `WHISPER_LOGGED` window and collect both reports/evidence. The final user instructions supply personalized commands without committing identities to Git.

## 2026-10-21 01:13 CEST (Europe/Oslo) — first live window reconciled; targeted next trial

**Milestone/scope:** M2 capability criterion demonstrated; M2 overall and real-race acceptance remain open. Clean base `177e8f4`, new branch `codex/network-window-akt722` in the existing Codex Review worktree. Both handoffs/worktrees/status/recent commits inspected. Other checkouts, Claude's vehicle systems and untracked outputs untouched. Documentation/evidence only: no runtime, installation, client input, push or release.

**Actual user evidence:** three screenshots of AKT722; sender A is the owner's first image, listener B the other two. Both stopped `window_complete`; 0.5 DATA/s, 16-byte DATA/ACK, 120-second schedule. A: 59 DATA calls/accepted, 59 matched ACKs, one missed local opportunity. B: 59 unique DATA receipts, 59 ACK calls/accepted. Both show prefix raw number:0, actual send returns number:0, no failed/unknown sends, throttles, send errors, rejected/duplicate/reordered DATA, deadline timeouts, late ACKs or outstanding ACKs. No attempted message is unaccounted for in this window. A RTT n=59, p50/p95/p99/max 697/779/881/881 ms; B gaps n=58, 1995/2094/2124/2124 ms. Elapsed A130/B147.325 seconds includes local waiting/drain, not one-way latency. Exact builds/interfaces/location/test UTC/commit attestation were not supplied; no historical values substituted.

**Evidence stored:** [sanitized report](evidence/2026-10-21-akt722-network-window.md), `docs/experiments/AKT722-capture.json`, two 60-column endpoint-local rows in `network-ledger.csv` for this single window. Public aliases A/B only; no screenshots/names/unrelated chat published. B maps show receipt/ACK sequences 1–59 and absent60; A maps partly obscured, so no complete sender-position transcription is invented. Attachment SHA hashes preserve provenance without images.

**Source diagnosis executed:** real Lua5.1/pinned Lupa injected-time reproduction on unchanged NetworkProbe: final callback exactly120s gives60 accepted/matched, missed0; +1microsecond gives59/59, missed1; regular60 Hz offset1ms gives59/59, missed1. All stop normally without timeouts/outstanding/errors/throttles. `advance` closes before final-slot send after the deadline. This is a source explanation, not captured client frametimes. Keep harness unchanged to avoid another friend install; do not repeat solely to chase60/60. Next2/s window can similarly show239/240 opportunities.

**Executed validation:** independent screenshot/counter/source review; Python in-memory capture/ledger consistency assertions PASS (cross-peer counts, local payload/prefix totals, raw-code totals, percentiles/NA semantics, complete listener maps, exactly two endpoint rows/60 columns, unknown metadata blank). `scripts/validate_project.py` STATIC PASS61 paths/TOCs/links/ledger; `git diff --check` PASS. No broad Lua/UI/gameplay rerun for docs-only change. No mocked traffic substituted for actual results.

**Risk/next task:** about0.7–0.9s RTT is a material synchronization risk, not a defined numeric gate failure; no prior numeric threshold exists. No architecture/participant capacity chosen. Run one reverse `AKT723` window on the same build: 2 DATA/s,128-byte DATA,120s, nominally4 DATA+ACK calls/s and316 payload+prefix bytes/s before unknown overhead. Full rate/size/PARTY/4/8 matrix is deferred from the first two-person candidate, not falsely passed. Recovery and real racing corrections/feel remain pending.

**Next exact task:** owner listens first, friend starts within 20 seconds using personalized AKT723 commands; reconcile both reports/evidence, then prepare short explicit reload/fresh-session recovery. No reinstall or computer-use session needed for this next window.

## 2026-10-21 01:32+02:00 (Europe/Oslo) — reverse budget window complete; short recovery prepared

**Milestone/scope:** M2's two-client directed budget sample demonstrated; recovery/architecture/live-race/scale gates remain open. Branch `codex/network-window-akt723`, clean base `400590e`, existing Codex Review worktree. Other worktrees/status/recent commits and both handoffs inspected. Claude advanced to `abe98f6` with four more karts/selector/untinted art; source not reviewed/merged/deployed here, untracked outputs preserved. Docs/evidence only; no runtime, client automation, install, push or release.

**Actual AKT723 evidence:** owner's image1 is A/listener, friend's images2–3 are B/sender. Config2 DATA/s,128-byte DATA,16-byte ACK,120seconds. Both stopped `window_complete`. B240 DATA calls accepted ->A240 unique receipts ->A240 ACK calls accepted ->B240 matched ACKs; numeric prefix0 and every actual send0. Both zero failed/unknown sends, throttles, errors, rejects, duplicates/reordered DATA, deadline timeouts, late/outstanding ACKs and missed slots. No attempted message is unaccounted for in this observation. B RTT n240: p50/p95/p99/max701/771/913/1012ms; A gaps n239:500/551/667/767ms. B elapsed130s,A134.788s includes local waiting/drain; not one-way delay. A3840payload+1680prefix bytes, B30720+1680; total37920/120=316payload+prefixB/s before unknown overhead,480 API calls across the pair.

**Context/limits:** owner explicitly reports different zones, not grouped, US beta servers. Record working cross-zone/ungrouped reachability in this session and US hosting as owner-reported context. No baseline game-ping/route/queue measurements isolate the RTT cause or predict EU performance. Exact builds/interfaces/test UTC/client commit attestations remain unknown; expected probe source8f66c5a is not attested. Overlay/wrapping affects some bitmap positions; complete raw maps are not invented. With valid IDs1–240 and240 unique receipts/matches, full sequence sets are inferred from bounded counters and labelled as inference, not raw transcription.

**Stored/validated:** [evidence report](evidence/2026-10-21-akt723-network-window.md), `docs/experiments/AKT723-capture.json`, two appended endpoint-local CSV rows (four rows/two windows total); names/chat/screenshots excluded, attachment SHA hashes retained. Independent screenshot and final capture/guide review found no errors. Python consistency assertions PASS for roles, all240-message counters, local byte/prefix totals, raw-code totals, timing percentiles/NA classes,316B/s arithmetic, map limitations, unknown metadata and four60-column rows. Structural validator STATIC PASS61 paths/TOCs/links/ledger; `git diff --check` PASS. No broad repeated Lua/UI suite for docs-only checkpoint; no actual recovery result claimed.

**Next exact task, NOT RUN:** same existing probe, friend listens/owner starts AKT724 at2 DATA/s,128 bytes,20seconds. After owner sees Armed, friend waits5seconds and `/reload`s; owner waits for normal deadline/drain stop and saves `/akart net report` BEFORE rearming. Friend's post-reload report should be Idle; pre-reload counters are unavailable. Then fresh AKT725 same rate/bytes for10seconds, explicitly rearm both and retain both reports on completion. Reports only; sequence evidence optional for disagreement. This tests addon reload/rearming, not full socket disconnect/logout. No fake planned CSV rows. Review these results before choosing first live-race synchronization; direct racing feel/corrections and expanded scale remain pending.

## 2026-10-21 07:00+02:00 (Europe/Oslo) — reload evidence closed; first control-protocol implementation

**Scope/continuity:** branch `codex/two-player-control`, base `47f43bd`, existing Codex Review worktree. Resumed the preserved uncommitted tree after the usage interruption; no work is claimed during the gap. Git status/branches/worktrees and both actual handoffs inspected. Claude at `b0b1f2e` holds its `abe98f6` roster install; no other checkout, untracked outputs or owned visual regions changed. No client automation, deployment, push, tag or release.

**Actual recovery evidence:** AKT724 owner A/send,2 DATA/s,128 bytes,20-second schedule: stopped ack_deadline, elapsed26.522s, prefix0,33 accepted sends/code0,22 matched ACKs,11 timeout/outstanding, no failed/unknown sends/throttle/error/reject/duplicate/late ACK, reported missedSlots0. Seven later planned opportunities were unattempted after abort, not extra missedSlots or network loss. Friend B screenshot reads Idle after reload; pre-reload counters unavailable, not zero. The exact reload instant/five-second procedure timing was not captured. AKT725 fresh explicit session completed on both:19 accepted DATA/unique receipts/accepted ACKs/matches, no failures/timeouts/outstanding; owner elapsed20.004s, RTT n19 p50/p95/p99/max700/738/738/738ms; listener elapsed29.316s, gaps n18 491/660/660/660ms. One opportunity unattempted locally, exact sequence IDs not captured. This is addon reload/rearming, not full socket disconnect or automatic rejoin.

**Stored:** recovery evidence report plus sanitized AKT724/725 captures with attachment SHA hashes; one AKT724 sender row and two AKT725 endpoint rows appended (seven endpoint-local rows/four sessions total). No invented receiver stats, reload/recovery seconds, exact UTC/build/interface/location, bitmap positions or packet-loss figure. Names/chat/screenshots excluded. Python consistency assertions PASS for counters, missing metadata, raw-code/byte/timing/NA invariants and seven60-column rows.

**Implemented:** pure `RaceProtocol.lua`, optional namespace registration/return. Version2/prefixAZKART2 separate from unchanged AZKART1 probe. Header11bytes; INVITE17/JOIN11/READY12/START23/CANCEL12/ACK15 bytes. Strict uppercase base36, six-character session, integer sequence1–46655, bounded compatibility/track/lap/startTick/seed data, closed reasons, unknown fields/metatables/malformed messages refused, ACK-of-ACK rejected. No APIs, sends, queue, session FSM, retries, clock alignment or authoritative state writes. Both TOCs now load15modules; runner/validator paths align. Tests exercise exact packets, min/max and nonfinite values, unknown compatibility versions, input immutability, deterministic roundtrips, malformed alphabet/length/fields and ACK recursion refusal.

**Tests actually executed before the usage interruption:** `scripts/test_lua.py --runtime both --tests race_protocol` PASS:36files parsed per runtime, codec passed in Lua5.1 and5.4. `scripts/test_lua.py --runtime lua51 --tests transport_probe ui` PASS:36parsed/two modules; original lifecycle/drive equivalence and idle adapter behavior preserved, UI10frames/151textures/13fonts. New codec independently reviewed with no actionable defect. No runtime source changed after those passes; no broad repeated suite on resume. Structural validation initially identified references to the unfinished ADR; added the ADR and final `scripts/validate_project.py` PASS63paths/TOCs/links/ledger. `git diff --check` PASS. No actual AZKART2 registration/traffic or multiplayer session was run.

**Decision/next exact task:** ADR0013 permits bounded experimental two-peer control work within separate working ceilings of4 aggregate API calls/s and316payload+prefixB/s before overhead, derived from an exercised schedule rather than a maximum capacity claim. Replication authority/model/clocks remain proposed; approximately700ms RTT and untested simultaneous traffic/gameplay/socket recovery remain material. M2's reliable handshake and overall acceptance stay unchecked. Next build pure PeerSession invite/join/ready/start transitions with duplicate/timeout tests. No further standalone manual probe requested at this checkpoint.

## 2026-10-21 07:23+02:00 (Europe/Oslo) — Claude review, UI ownership and pure session state machine

**Scope/baseline:** `codex/peer-session`, clean base `d857ce2`, existing Codex Review checkout. Confirmed remote, branches/worktrees/status/recent commits and both actual handoffs. Implementation/review scope reserved before source edits. Canonical/main/Claude checkouts and untracked outputs preserved. No automatic integration, install, downloads, client automation, push or release. This entry accompanies the focused session commit; resolve its hash with `git log -1 codex/peer-session`.

**Review first:** inspected Claude runtime `abe98f6` and handoff `b0b1f2e` against integrated `1004e73`. P2: late sprite-load failure restores Drag Car path/id but leaves sheet UVs; real Lua5.1 in-memory fault injection reproduced1/64 crop. Claude should restore complete previous visual configuration and handle rollback failure. P3: opaque coverage threshold lowered globally12%->6%; retain per-kart floors12/8/6 for ground/gryphon/gyro. [Review record](reviews/2026-10-21-claude-roster.md) holds roster integration. Read-only Lua5.1 presentation/ui checks on Claude PASS34parsed; source SHA/TGA validation for5vehicles and5JPEG decode checks passed. Pillow/source regeneration, actual new-roster appearance/performance/install NOT RUN. Claude standalone counts10/151/13; future combined build must preserve Close results and use11/151/13. Per-file unresolved art permissions remain explicit; no release clearance inferred.

**Ownership decided before implementation:** Claude owns screen layout, navigation, labels, status copy and visual polish, including roster fixes. Codex owns session state/transitions, command semantics/capabilities, retries/timing, transport and teardown. Shared contract/integration/performance budgets remain reviewed. Recorded in AGENTS, UI_UX and [UI_FLOW_OWNERSHIP](UI_FLOW_OWNERSHIP.md). No edits to Claude's owned runtime or handoff.

**Implemented slice:** new pure PeerSession over injected RaceProtocol/time/output. Explicit host idle->inviting and guest listening->invited->joining, then lobby readiness and starting proposal; closed terminal state never resumes. Host Start requires both ready and local readiness acknowledged. Copied options/views/proposals; complete Forever native-name/session/physics/track scoping, host-offered valid laps; no realm/first-name fallback. One reliable command,0.5-second shared ACK/control/retry spacing,2-second retries/max3attempts, ACK queue8/seen64/scoped events256, finite monotonic clocks, fixed deadlines, duplicate ACK reuse/stale/conflict handling and bounded best-effort cancel/final ACK. START is delivered once as parameters, host after ACK/guest on receipt; it never starts simulation or solves atomic GO/clock mapping. Both TOCs now16modules; tests/runner/validator align. Pure loading registers no event/prefix or native traffic. No UI objects were added.

**Executed checks:** canonical pinned Lupa2.8/real Lua5.1, `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests peer_session race_protocol transport_probe ui` PASS:38source/test files parsed, all4targeted modules passed. First pure run passed; review then found invalid clock arithmetic after a prior send and nested update advancing time before its guard. Both fixed with regressions; final four-module check passed. Added lost START-ACK retry/proposal-once regression, then reran `--tests peer_session`:PASS38parsed. Coverage includes actual-codec two-peer handshake, unready/role refusals, identity/compatibility, options/view copies, drop/reorder/duplicates/conflicts, causal confirmation only after actual send, retry caps/pacing/no bursts, native failures/throws, pre-send/reentrant ACK, clock errors, nested update no clock effects, timeout/ACK-queue cleanup and cancellation. Mock UI retains10frames/151textures/13fonts and authoritative drive trace. `scripts/validate_project.py` STATIC PASS65paths/TOCs/links/ledger; `git diff --check` PASS. No broad suite/dual-runtime repetition. Pure module independently reviewed; no remaining concrete defect identified within control-proposal scope.

**NOT RUN / limits:** new controller Lua5.4, native AZKART2 registration/delivery, session UI, actual two-client handshake/start, full socket recovery, simultaneous candidate traffic, clock/authority/replication/game feel and release-scale validation. Existing measured AKT722–725 evidence remains unchanged.2calls/s per-controller pacing is not a global traffic budget; future adapter must include all traffic under separate4calls/s and316payload+prefixB/s pair working ceilings. Known roughly700ms RTT remains material. No reliable-live-control-plane or M2 completion checkbox changed.

**Next exact task:** build the guarded native two-peer transport adapter around PeerSession, with fresh-session lifetime, existing Forever logged-whisper route, shared rate/byte accounting, explicit lifecycle cancellation and copied view/action bridge for Claude. Keep AZKART1 experiment independent and reject concurrent traffic that bypasses the budget. Claude can prepare Host/Join/Ready flow against the documented controller, with no fabricated connection state. Live-race integration follows after that boundary is reviewed; no new download/manual test needed for this checkpoint.

## 2026-10-21 07:39+02:00 (Europe/Oslo) — safe Claude/Codex source integration

**Owner request / scope:** reconcile Claude's quoted older handoff without accidentally replacing code or deleting work. Codex designated integrator; no new gameplay/network feature. Branch `codex/roster-integration` from clean3644084; reservation commit1fd6275 preceded edits. Existing Claude tracked tree clean except untracked `Claude outputs/`, preserved. Main/local origin/main f923d15/canonical5570968 unchanged. Preserve original codex/peer-session3644084 and claude/track-ui b0b1f2e.

**Graph audit:** shared merge base1004e73; Claude f675610/c6e1b5e/1004e73 already ancestors of Codex. Only abe98f6/b0b1f2e unique to Claude. Ten Codex commits beyond the common base include results/transport/AKT723–725/control codec/FSM. Quoted AKT723-next and scratch400590e integration directions are stale. Merge uses latest Codex, with no squash/rebase/reset/force push/author rewrite. PhilForever identity verified locally. Complete-history3-ref bundle verified before merge; tracked/untracked file SHA inventories for canonical/Claude captured under ignored `local-artifacts/integration/20261021-0732-preservation/` (not published).

**Combined behavior / conflict resolutions:** six stopped-only cosmetic karts and their new source/tooling/credits/neutral tint integrate with existing Close results, explicit exits, logged Forever full-name route, bounded AZKART1 experiment, measured ledger/evidence, RaceProtocol and PeerSession. Seven conflict files: CHANGELOG keeps both histories; README_ADDON keeps network help/transport plus roster; API_CONTRACTS keeps stronger sampled-update repeatability plus roster; ASSETS/TEST_PLAN/client checklist/test_ui combine both buttons at11frames/151textures/13fonts. No whole-file ours/theirs replacement. Both TOCs16modules and all backend implementations retained. Claude's latest handoff copied exactly as historical source evidence; its old execution commands are explicitly superseded by INTEGRATION_STATUS.

**Narrow review fixes:** complete UV/rotation/neutral tint application before metadata commit, exact prior frame/configuration restoration after late failure; failed restoration clears to Basic/default effect anchors while preserving stopped run/result/physics/track. Refused primitive rotation is contained; no extra UI objects. New regressions cover sheet/single transitions, late crop/rotation/tint failures, persistent rollback failure, metadata/effect-label consistency and recovery. Creation-time missing/throwing rotation also covered. Per-kart opaque coverage floors12%trike/tank/biker,8%gryphon,6%gyro; original binary assets unchanged. Review disposition now source-approved on this integration branch; original Claude branch untouched.

**Executed validation:** pinned Lupa real Lua5.1 `C:/Python314/python.exe scripts/test_lua.py --runtime lua51` PASS:38files parsed/all21test modules; includes deterministic10k/cadence tapes, race/lap/input/lifecycle, both network foundations, six-kart presentation, rollback/fallback regressions and UI11/151/13. One full integration pass, no repeated broad/dual-runtime matrix. Earlier targeted presentation and UI passes also executed. `scripts/validate_project.py` STATIC PASS71paths/TOC order/links/ledger; whitespace checks PASS. Direct Git-blob preservation assertions PASS:36mechanical/transport/test/TOC paths unchanged from3644084,21art binaries exactClaude bytes and all147Codex baseline files remain. Post-integration workspace checks PASS: both other worktrees' tracked/untracked SHA sets/HEADs unchanged, baseline branch refs unchanged. Installed22file tree/hashes exactly match prior manifest, no missing/extra files; no installed writes.

**Workflow / limits:** shared INTEGRATION_STATUS + AGENTS record one integration/deployment path and new branches from the combined commit, preserving all original branches/authors. In a stale checkout read the ledger through shared Git. No cleanup/prune/gc or automatic main integration. Lua5.4 current combined slice, installed roster, native appearance/alpha/selection/fallback/resource costs and all new native session/race checks NOT RUN. Imported provenance/rights statuses remain explicit and not cleared for release. No live-control-plane/M2 completion claimed. No install, new package/download, manual test, push/tag/release.

**Next exact task:** create Codex's backend feature branch from the combined commit and implement the guarded native PeerSession transport adapter/global output accounting/lifecycle cleanup plus copied view/action bridge. Claude creates its own next visual branch from that same commit for Host/Join/Ready polish. Preserve this combined source as the sole next deployment candidate; live-race integration follows the reviewed adapter/UI boundary. Do not repeat completed AKT723 or install standaloneabe98f6.

## 2026-10-21 09:10+02:00 (Europe/Oslo) — guarded session transport and copied menu actions

**Scope/base:** user requests connecting controller to Forever logged-whisper transport and exposing actions for Claude's menu. New codex/session-transport from clean combined83c611c;08:50reservation in own handoff before editing. No install/client automation/new download/manual test/push/release or live race feature. Original integration/agent branches and configured PhilForever identity retained.

**Implemented:** new private-controller SessionTransport.Init/Host/Listen/Join/Ready/Start/Leave/Stop/IsActive/Update/Message/HandleEvent/GetView/TakeStartProposal. Explicit full native Forever peer and fresh6code, actual source physics/track compatibility, fixed3laps;64accepted IDs remembered per lifetime, no discovery/realm inference/automatic resume. Getter returns copied phase/capability/offer/readiness/pending/diagnostic state and lifetime native traffic accounting, no native reads or sends. Host/Listen registration is explicit; actions/Message queue only, Update alone invokes paced API calls. START is a backend parameter proposal; no Race/UI.Start/physics activation or clock agreement.

**Native bounds:** only SendAddonMessageLogged/CHAT_MSG_ADDON_LOGGED with nativeWHISPER and separateAZKART2, strict source-matched registration/send enums and protected-result containment, no unlogged/plain fallback. Every attempted control/ACK/retry/final call counts payload+7prefix bytes; local0.5s spacing/rolling1s2calls/158B gate persists across rearming. Current maxpayload23B; one attempted native send/update, no hitch catch-up. With both endpoints compliant, pair4calls/s/316B ceilings remain conservative working budgets before overhead, not measured capacity or a budget for other addons. StandaloneAZKART1 probe stays separate/exclusive. Additive optional PeerSession.update sendAllowed=false preserves deadlines/final expiry with no callback/attempt consumption.

**Ownership/cleanup:** lease on existing CoreframeakNetworkOwner; akNetworkSending held through both adapters' native calls prevents cross-arm after a Stop inside a send. Inactive Stop cannot detach another adapter. Probe now verifies ownership after each prefix/event/update setup and blocks recursive arming. Core preserves native sender/event arguments and routes both adapters; only accepted solo UI.Start adds hardStop(local_drive), before capture. Combat/world/logout, blocked/unreadable clocks/APIs and send failure drop private controller/output/proposal and release owned hooks without resuming. Leave/remoteCancel retain only a bounded best-effort final CANCEL/ACK drain. No new UI objects/chat-per-packet/SavedVariables writes.

**Executed tests/results:** canonical pinned Lupa2.8/real Lua5.1 `C:/Python314/python.exe scripts/test_lua.py --runtime lua51 --tests session_transport peer_session transport_probe ui` PASS,40source/test files parsed/all4targeted modules. New native doubles run actual codec+controller with two isolated mocked endpoints: explicit consent/readiness/start proposals, full surnames/UTF8/channel/session/compatibility, copies, fresh/reuse64cap, malformed inputs, strictmissing/duplicate enums/native refusal/throw/unknown results, retries/lost invite, persistent pacing/rearm budget, no Message sends, lifecycle/clock cleanup, bounded cancel/drain, pre-send/reentrant ACKs, Stop/nestedUpdate/cross-adapter send callbacks and guard-time cancellation. CoreUI tests cover new routing/cancel and retain authoritative900frame drive/effects trace plus11frames/151textures/13fonts. Initial combined pass exposed the UI double's catch-all unknown-field methods; explicitly model missing lease fields as nil, then allpassed. Independent review reproduced legacy probe setup losing its lease after cancellation; fixed all3setup stages/recursive arm and reran the same focused checks PASS. No broad repeated/full dual-runtime matrix.

**Structural/preservation:** scripts/validate_project.py STATIC PASS74paths/17moduleTOC order/links/ledger, whitespace checks PASS. Direct byte comparisons retain12unchangedmechanics/presentation/codec modules and9runtime assets from83c611c; all22installed files/tree still match prior8f66c5a manifest. First preservation precheck detected Claude's expected independent HEAD advance; inspected reservationdfbd83e on claude/ui-flow based83c611c, rather than treating it as overwritten work. Protected oldtrack-uib0b1f2e/combined83c611c/peer3644084 refs remain intact. Canonical/Claude worktrees never edited by this task. Claude has only its own visual reservation/untracked outputs as observed; future visual edits remain independent.

**Docs/limits:** shared contracts/architecture/protocol/feasibility/status and new SESSION_MENU_API document actual API, structural capabilities, last-clock traffic windows, frontend/backend ownership and Start's non-atomic/non-clock boundary. Claude's active reservation excludes our backend/UI.Start area; TOC/test-loader/count/docs integration must preserve both branches. Proposed preferences/persistence/visual work is not implemented here. Current Lua5.4, actual new-prefix registration/delivery, two-client menu/handshake, start clocks, race authority/sync/finish/feel and full socket/scale/release checks **NOT RUN**. No measured traffic result or completed M2 acceptance inferred.

**Next exact task:** implement bounded start-clock/coordinator negotiation for the two-peer candidate, with deadlines/cancel/ambiguous delivery and one-shot session-to-race ownership; keep actual Race activation gated until that boundary is reviewed. Claude can wire menu actions through the published copied bridge after integration review, without raw controller writes or technical tick/seed settings. No standalone manual probe/download needed now; priorAKT722–725 results unchanged.

## 2026-10-21 12:18+02:00 (Europe/Oslo) — opt-in start clock and one-shot race initialization

**Milestone/scope:** M2 experimental candidate, branch `codex/start-clock` from `4f9246a`; the accompanying focused commit is resolved by `git log -1 codex/start-clock`. Reservation was recorded before edits. The quota-interrupted work was resumed from actual files; no work or tests are inferred during the interruption. No roadmap acceptance changes.

**Implemented:** new pure ClockProtocol/StartClock/RaceStart with focused tests; additive PeerSession.handoffStart and Race.newRunning. SessionTransport adds explicit coordinated Host/Listen/PrepareStart, copied clock/capability diagnostics and backend-only TakeRaceStart. Legacy control Start/tick semantics are preserved. Clock prefix AZKCLK1 is registered only on explicit coordinated arming and shares the existing logged route, native lease, 0.5-second minimum spacing and rolling two-call/158 payload-plus-prefix-byte local budget with AZKART2. No packet is sent by actions/Message/getters; no new UI objects, chat output, assets or simulation-tick broadcasts.

**Timing/ownership:** three four-timestamp exchanges remove guest paced wait from RTT and intersect offset intervals without assuming symmetric latency. Integer milliseconds have seven base36 digits/no wrap. Future GO is eight seconds after host calibration; prepare/commit ACKs must finish one second before the mapped epoch. Deadline/packet/sequence/storage limits, duplicate reuse, explicit cancel and strict malformed/late/conflicting refusal remain bounded. Native stamp/preflight delays above two milliseconds refuse the send. Guest arms after local COMMIT-ACK acceptance, host after matching ACK: final ACK/cancel loss can leave one peer armed, never an atomic-GO guarantee. Current clock-offset assumptions do not establish drift accuracy or simultaneous launch skew. Cached calibration retry timestamps can exceed the two-second RTT limit after loss and fail conservatively; a fresh explicit session is then required.

**Actual race initializer:** mapped GO through GO+250 ms can yield one actual Physics.new/Race.newRunning bundle at tick zero; no second solo countdown or pre-GO lap time. Token/ticket copies, close-before-initialize, dependency/version/clock checks, exception and reentrant Stop handling prevent another local launch. Seed is metadata only because current Physics has no random subsystem. Geometry data copies preserve function closures, whose source geometry remains read-only. No UI.Start, input capture, active driving loop, opponent, shared standings or remote finish exists in this slice. The future live controller must preserve native budget/ownership when consuming the bundle.

**Executed checks:** canonical pinned Lupa via `PYTHONPATH=.../AzerothKart/local-artifacts/python-deps`, `C:/Python314/python.exe`:

- `scripts/test_lua.py --runtime lua51 --tests clock_protocol start_clock race_start race peer_session session_transport` — PASS,46 Lua files parsed/all six modules executed. Codec bounds/canonical bytes, asymmetric synthetic 700 ms RTT/offset/queue subtraction, retries/duplicates, cancellation/deadlines, final-ACK ambiguity, malformed/conflicting input, pre-send/reentrant outcomes and late GO; actual 900-tick Physics/Race identical-input replay.
- `scripts/test_lua.py --runtime lua51 --tests session_transport transport_probe ui` — PASS,46 parsed/all three modules. Added delayed native doubles with five-second offset, both-prefix budget checks, sender/channel scope, initializer exceptions and reentrant Stop; UI retained11frames/151textures/13fonts and its900-frame mechanics/effects trace. Native mocks are not client measurements.
- Final `scripts/test_lua.py --runtime lua51 --tests session_transport peer_session` — PASS after reconciling validated callback time before teardown/handoff. Review also caught and fixed the guest PREPARE upper-bound consistency check and protected initializer-transaction cleanup; focused regressions passed. A final `--tests session_transport` pass verifies that launch retains the negotiated physics version rather than recapturing a changed module version.
- `C:/Python314/python.exe scripts/validate_project.py` — PASS,82 expected paths,20-module order in both TOCs, docs links/protocol/ledger. `git diff --check` — PASS. Installed-manifest SHA-256 comparison —22/22 match, read only. Protected simulation/visual/art/Core/probe source diff from4f9246a empty; other worktrees/status preserved.

**NOT RUN / remaining risks:** current Lua5.4/full broad matrix, actual AZKART2/AZKCLK1 client registration/delivery, real drift/skew/last-ACK behavior and game feel, coordinated menu/canvas, movement corrections/finish/standings, socket reconnect, larger rooms and release. No new measured traffic, milestone completion, security guarantee or production authority choice. No install/reload/automation/push/release. Claude's active UI branch/untracked outputs and canonical untracked handoffs remain untouched; shared loaders/docs require reviewed integration. Docs/ADR0014 record exact APIs and candidate limits.

**Next exact task:** implement bounded live-race control and paced remote snapshots using this GO bundle and persistent native budget, with remote state read-only for Claude. Review her current menu/canvas changes before binding/installation. No new download or manual test requested now.

## 2026-10-21 12:25+02:00 (Europe/Oslo) — Gemini feedback reviewed

Documentation-only branch `codex/gemini-feedback` from `2232f82`. [Concise assessment](reviews/2026-10-21-gemini-feedback.md) retains the documentation/UI-boundary and bounded remote-kart suggestions, corrects stale implementation status, and separates candidate budgets from measurements, half-RTT from start accuracy, and deterministic ticks from multiplayer timing fairness. Actual Lua5.1 Loop micro-experiment: one synthetic second at60callbacks executed60ticks; one callback executed5ticks/dropped0.916667s. Read-only source/header audits; no gameplay/API/art/other-worktree/install changes. Broad tests/client checks NOT RUN for this review; structural validator PASS82paths/TOCs/links/ledger and whitespace PASS. No roadmap acceptance changed. **Next exact task:** existing live-race controller/paced remote snapshots, with explicit finish timing and shared budget policy; reviewed Claude integration follows.

## 2026-10-21 13:52+02:00 (Europe/Oslo) — Claude handoff and GitHub safety verified

Documentation-only `codex/github-safety` frome10d3ef. [Audit](reviews/2026-10-21-github-safety.md): Claude1b2d3d5 and Codex history intact, shared83c611c, connectivity PASS/no missing objects, all-ref recovery bundle verified, all3worktrees' tracked/untracked hashes unchanged after read-only checks. Windows Git live refs/dry-run explicit claude/ui-flow push succeeded; no actual publication, merge, auth/config change or install. Claude's cloud allowlist/Linux-shell errors do not reproduce as a Windows Git access failure. Current remote main remainsf923d15; newer feature branches absent.

Claude-source checks actually executed on Windows: Lua5.1 `--tests menu ui` PASS40parsed/counts65/160/79; validator PASS77paths/TOCs/links/ledger; preview art --check PASS/exact SHA. Runtime mechanics/Core/transport and mechanical assertions preserved. Codex approves first-open saved-track restoration through the existing inactive/out-of-combat selection transaction for later integration. Current Lua5.4/fullbroad/combinedscratch/client checks NOT RUN by Codex. Multiplayer remains coming soon. No milestone changes. **Next exact task:** explicit owner-authorized feature-branch publication if requested; reviewed integration remains separate, then live-race control/paced remote snapshots. No overwriting or installing the standalone Claude branch.

## 2026-10-21 14:50+02:00 (Europe/Oslo) — Claude handoff and combined-branch review

Documentation-only `codex/combined-review` from published192c6de, reviewing Claude1b2d3d5/shared83c611c. [Full findings and evidence](reviews/2026-10-21-ui-backend-integration.md). Isolated no-commit scratch merge reproduced exactly the six reported list/docs conflicts; union resolutions retained all21modules and both owners' runtime code. Existing full Lua5.1+5.4 suite PASS48parsed/26testmodules each, UI65/160/79; validator PASS88paths; preview art --check exact2097170B/hash; staged whitespace PASS. Actual runtimes were the canonical pinned Lupa with Windows Python3.14. No original branch merged or runtime file edited.

**Changes requested:** P2 explicit current fallback selections are not persisted. RealLua51/54 reproductions on both Claude source and combined trial confirm deferred Mirage restore overwriting deliberate Oval, failed-Mirage restore retaining wrong saved track after explicit Oval, and failed-Gyrocopter restore retaining wrong saved kart after explicit trike. These are reproduced bugs, not passing acceptance tests. Required fix belongs in Menu's explicit successful-choice bookkeeping; preserve selection transactions, future-version protection and untouched failed-restore preferences. The automatic first-open restore strategy remains acceptable subject to explicit-choice precedence. No other backend/ownership blocker found; current multiplayer mapper remains intentionally unwired.

Publication from the prior authorized turn is now recorded: receipt verified at14:07+02:00, remoteclaude/ui-flow1b2d3d5 andcodex/github-safety192c6de, mainunchangedf923d15. This review performs no new push, source integration, install, client input or milestone update. Native UI/menu/clock/live-race behavior NOT RUN; previews remain stand-in-font layout evidence. **Next exact task:** coordinate explicit-choice persistence and its three focused regressions with Claude's new active Menu reservation, then review the combined source before any main integration. Live-race control/remote snapshots follow that checkpoint.

**Concurrent work observed at14:51:** Claude independently started `claude/capital-cup` at50d8bf6 (commit14:47), changing only its handoff at that checkpoint. The published UI tip1b2d3d5 is unchanged and remains this review's exact target. City-track/Menu changes are newly reserved and outside this review; Codex did not touch that worktree. The final preservation check detected and reported this expected concurrent advancement instead of resetting it.

## 2026-10-22 08:12+02:00 (Europe/Oslo) — coordinated Menu fix and reviewed source integration

**Milestone/scope:** M2/M3 presentation/backend integration checkpoint, not a new milestone or gameplay slice. User requested coordination, regression coverage, then integration. Reservation 5b69834 from own clean review a77fe73 preceded runtime changes. Claude's current handoff78d97a1 explicitly provides isolated fix4ffe184 for the exact P2 finding; no direct message or edits in Claude's active checkout were needed. Its city runtime/menu/pipeline reservation remains separate.

**Commits/source:** normal two-parent merge 6cd611a combines reviewed UI1b2d3d5 with backend 192c6de, retaining both full histories. Six shared conflicts (CHANGELOG, API, architecture, validator, test runner, UI test loader) use the exact per-conflict reviewed unions; UI/Core/TOCs merged cleanly. Menu loads after UI and all session/clock/backend modules remain,21 per TOC. Cherry-pick9b22f12 uses `-x` to retain Claude 4ffe184 authorship/coauthor/source reference; only city-dependent test context is adapted to the reviewed two-track baseline. Extra test commit0eb6c63 preserves future-version preference identity/content and stopped state/input. The following docs commit aligns ownership/API/README/art sheet/review closure/integration status and this handoff; no roadmap checkbox changes.

**Implemented fix:** successful explicit menu selections call Menu.Chose even for an already-current fallback ID. Deliberate track changes, including quick-bar changes, supersede deferred restore; restore establishes a baseline without overwriting an untouched failed-load preference. Existing guarded UI.SelectTrack/SelectKart transactions and authoritative simulation remain unchanged. Saved preference version/unknown-field protection remains; the extra fixture checks exact saved-record/unknown-table identity and values while in-memory choices change, plus unchanged stopped vehicle fields/race/clock/laps/checkpoints, held keys and sampled input. The combined multiplayer screen remains disabled/Coming soon; no live race is implied.

**Executed commands/results:** pinned Lupa2.8 via canonical `local-artifacts/python-deps`, C:/Python314/python.exe:

- Ignored `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/menu_before_fix.py` — EXPECTED FAIL in Lua5.1 and5.4 with original1b2d3d5 Menu injected only in memory: new `choosing the current track is remembered` assertion catches the bug. Source is never swapped. This is negative-control evidence, not an old-build pass.
- `scripts/test_lua.py --runtime lua51 --tests menu ui` — PASS,48 files parsed, both modules executed. Agent's added fixture also passed its one focused Lua5.1 menu run.
- `scripts/test_lua.py --runtime both` — PASS: all 26 modules,48 files parsed per actual Lua5.1/5.4 runtime; full integration run once after final test edits. Pool65frames/160textures/79fonts, including UI lifecycle/race/selection/transport assertions and deterministic tapes. Mock results do not establish native layout/input/performance.
- `scripts/build_ui_art.py --check` — PASS: exact1024×512 BGRA32 atlas,2,097,170bytes, SHA25643afd042ade6b2ab628b860153bcfd91417ed3948bc7526260b91caff999863d. No art regeneration or replacement.
- `scripts/validate_project.py` — PASS: 88 expected paths, synchronized 21-module TOCs, protocol docs, local file links and network ledger. `git diff --check` — PASS. Agent checked 89 local Markdown path/heading targets in its four contract/art/index docs; legacy handoff anchor retained with an HTML compatibility ID.
- Ignored preservation `recheck.py` and source comparisons — PASS at9b22f12:103 canonical /194 Claude files (including3/14 untracked), other HEAD/branch/status and unrelated refs unchanged.18 Codex-owned runtime modules identical192c6de;10 runtime art files identicalClaude1b2d3d5. UI differs from Claude by only the retained SessionTransport.Stop(local_drive). No Circuit/Courses/CapitalCities/city art/pipeline imported. All-ref35,819,184-byte recovery bundle verified complete before integration.

**Final preservation recheck (08:19+02:00):** PASS at0eb6c63: both other worktrees, all297 tracked/untracked files and unrelated refs still unchanged. Only the authorized integration branch advanced.

**Evidence/recovery:** ignored `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/` contains before/after snapshots, complete-ref bundle, negative-control/focused/full/art logs and source-preservation JSON. Existing historical review/repro remains intact. Repo-local PhilForever identity verified; no global config/other-worktree/source-history rewrite, reset, pruning or deletion. Claude handoff unchanged. main/origin-main stay f923d15; no push/install/client input/release.

**Outstanding checks/risks:** all native front-end templates/fonts/sounds/drag/scales/preferences/restart behavior NOT RUN; actual AZKART2/AZKCLK1 delivery/coordinated start/live racing/finish/reconnect/scale acceptance remains open. Current copied lobby mapper is legacy and commands are unwired. Asset redistribution remains unresolved for release. New city collision/selection changes require separate review; neither code presence nor this source merge clears those gates.

**Next single task:** bounded live-race controller and paced two-peer remote snapshot path from the existing backend GO handoff, preserving budgets/lease/teardown and read-only presentation. No manual test/download needed now; do not replay the completed low-rate probe as a prerequisite.

## 2026-10-22 08:37 +02:00 (Europe/Oslo) — latest Claude city review, push and coordinated installation

**Authorization/reservation:** owner explicitly asks whether the Claude handoff was read and authorizes push/install if good, then he tests. Read current `claude/capital-cup:docs/handoffs/claude-latest.md` completely at78d97a1, including city review items, active reservation, pending PROGRESS entries and old-install discrepancy. Reservatione976f55 preceded changes. No computer-use/client-input automation.

**Claude handoff ledger incorporated:** its reported225b128/349945c Stormwind rework includes district streets/three bridges, bright gold-roofed Cathedral and street at its steps, no plazas/solids, grey Mage road,3831-unit loop/sixgates/769approach. Its78f982f deterministic left-to-right float sums keep committed kart pixels unchanged. Claude reports dual-runtime Lua/build checks on its cloud and developer environments; these are author-reported evidence, not our client checks. Both new Stormwind TGA header/byte/SHA values and source ledger62models/594placements/81textures were independently verified. Full city art regeneration is NOT RUN in this integration. Claude's latest authored handoff is now in the combined branch unchanged.

**Review/implementation:** pure city collision/geometry review found no blocker for current no-solid definition; target test_circuit passed in Lua5.1/5.4,29,160 boundary movements per runtime stayed within requested/gate bounds and duplicated10k-tick input replays matched in each runtime. Existing wall speed scrub remains a human handling check. UI review reproduced P2: failed new background plus failed rollback destroys the retained image while old metadata/results remain. Mergef9f2af0 preserves both parents and combines all24 module/test lists and future-preference regressions. Fixe748b60 adds one creation-time hidden background, guarded per-texture UV/load then success-only swap; destructivefalse/throw/missing/throwingUV failures preserve visibleimage/crop/path, state/race/clock/view/laps/checkpoints/results/heldkeys/sample. Retries and Oval transitions allocate no objects. Catalog wording now matches wall-only Stormwind. Counts71/165/80; two scenery images can remain resident. Physics/Track/Mirage/session/clock/transport/Core unchanged. No new live-race feature.

**Actual checks:** pinned Lupa2.8/C:/Python314/python.exe with canonical local dependencies:

- `scripts/test_lua.py --runtime lua51 --tests ui menu circuit` — PASS,52files parsed (agent focused run).
- `scripts/test_lua.py --runtime both` — PASS,52files parsed and27modules executed in each actual Lua5.1/5.4 runtime, final combined integration checkpoint.
- `scripts/validate_project.py` — PASS,96expectedpaths,24-module TOCs/local links/protocol docs/ledger. `git diff --check` — PASS.
- Source/art comparison — PASS:18preexisting Codex runtime modules exactly77581b9, all12runtimeart files exactlyClaude78d97a1; six changed/new authoring scripts parse;39addon files. No art rebuilt.
- WindowsPowerShell5.1 installer WhatIf — FAILED beforewrites (Get-FileHash inheritsWhatIf). Cached PowerShell7 same preflight — PASS. Used the working PowerShell7 helper unchanged for actual installation.

**Install actually performed08:32+02:** existing helper with explicit `_classic_beta_/Interface/AddOns` parent, `-Overwrite`, separate ignored backup directory. Status/StageVerified; BackupVerified/TargetCopyStarted true. All39installed files independently match39source+manifest hashes and exact path sets. All22prior files inbefore/ matchbefore.csv and independent predeploy snapshot; noextras, deletion, other addon orWTF/SavedVariables changes. Tested installed source commit **e748b60c9113a09d6455fb5a39788aa23f3d7084**. Exact manifest `local-artifacts/deploy-20261022/20261022-082336-b891c186/install-backups/20261022-083240-447-60ddc86aae344da38fa31ae61459972d/install.json`; evidence root `local-artifacts/deploy-20261022/20261022-082336-b891c186/`, including final-install-independent-audit.json, source-final.json, Lua/structural logs, snapshots and verified35,835,854byte all-ref recovery bundle.

**Publication:** Windows Git verified live remote tips; default restricted network attempt failed, normal approved network execution succeeded. Non-force dry-run then actual push of exacte748b60 to `refs/heads/codex/ui-backend-integration` succeeded (newfeaturebranch). This deployment-doc commit follows on that same branch; final remote SHA verification/receipt is retained with evidence. No push/merge to main or Claude refs, force, tag, release, author rewrite or other-worktree switch. Otherworktrees297files/HEAD/branch/status unchanged; only Codex integration advances.

**Unrun/next:** owner now fully exits/restarts WoW (newfiles), opens `/akart`, chooses SinglePlayer→CapitalCitiesCup→Stormwind→kart→Race!, inspects scenery/walls and uses Stop/Restart/Close results. All native UI/loading/settings/performance and coordinated multiplayer acceptance stay NOT RUN until evidence arrives. No roadmap criteria marked complete. Next Codex implementation remains bounded live-race control/paced remote snapshots, multiplayer ahead of ghosts/time trials.

Final packaging note: the following deployment-documentation commit also corrects the addon readme's staging-texture count. Runtime code remains e748b60. The authorized installer is rerun against that final source tip; its exact final manifest/hash and remote branch tip are recorded in ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/final-publication-install-receipt.json`. The original22-file backup remains intact.

## 2026-10-22 10:11 +02:00 (Europe/Oslo) — Stormwind full grip to the walls

Owner asks for no Stormwind slow mechanics before the edges. New own feature branch fromc59a607, reservation in named handoff before edits. Code **c4b430d** captures optionalboolean fullSpeedToWalls once in Circuit and promotes corridor shoulders to road; defaultfalse preserves existing rough behavior. Stormwindlayout opts in/version2; generatedCapitalCities updated with geometry-only mode. No art regeneration, road/wall geometry movement, Physicsversion change or other-track policy change. Menu/status/help no longer promise Stormwind slowdown. Updated contracts/track/physics/art/checklist docs; Claude's active checkout untouched and its future layouts must preserve this Stormwind opt-in.

Executed: `scripts/test_lua.py --runtime lua51 --tests circuit surface drift menu ui` PASS,52files parsed/five modules. Regressions retain default square roughground and exactwall resolution, compare all Physicsfields on center/shoulder for10ticks of throttle,boost,chargedrelease,drift, and test actualStormwindshoulder points. `scripts/build_city_tracks.py --wc3 . --geometry-only` wrote only the Lua data; same command with`--check` PASS; currentStormwind has no model-derived solids so no archive access/art render needed. Validator PASS96paths/24TOCs/links/ledger; whitespacePASS. Independent readonly review found no blocker. Lua5.4/fullbroad/nativegame checks NOT RUN for this narrow correction; previous integrated passes remain historical.

Installed with existing PowerShell7 backup/hash helper for the ongoing owner test.39files exactsource/target;39previousfiles verified againstbefore.csv. Exact manifest `local-artifacts/stormwind-full-speed-20261022/install-backups/20261022-100920-414-60b7f53b752c42f781bbb25af9f17193/install.json`; ignored `local-artifacts/stormwind-full-speed-20261022/install-receipt.json`. Verified Physics/Track/Mirage/UI/Input/Race/SessionTransport and every art file unchanged fromc59a607; Claude/canonical HEADs unchanged. No client automation, SavedVariables/otheraddon changes, main merge or publication. No newfiles: owner needs only `/reload`, then drive/boost/drift across the former shoulder; actualfeel pending.

Next: owner handling check; resume live-race controller/paced remote snapshots afterward.

## 2026-10-22 10:46 +02:00 (Europe/Oslo) — painted Stormwind wall alignment and corner slides

**Trigger/diagnosis:** owner screenshot at lap3, nextgateMageQuarter shows kart blocked on the inner paved wedge before the whitewaterwall. No screenshot/privateclientdata committed. Art is union of radius90capsules (wallRadius76+clearance14); collision was the union of radius76capsules. Independent shrinking removes too much at concavejoins. Exact exposed whitewallapex(476.265215329,866.369426623) is30.95units from rejected(450,850), beyondnormal14clearance. Separately, resolveMovement(442,849,445,846) chose an unreachable5.98unit projection and returnedstart although a2.25unit bounded slide existed. Final review also caught a near-tangential whiteapex slide whose unconstrained projection exceeded the movement ball; reproduced and fixed before installation.

**Implementation81cc0ed:** optional wallClearance/wallVertices metadata in Circuit; old radius remains safe fastpath, addedcorner space checked against exposed visualcapsule projections/junctions. New standard-library `scripts/circuit_boundary.py` enumerates analytic line/circle intersections, filterscovered points and stablydeduplicates them. Generator uses exactly roundedruntimecapsules, emits1,025junctioncandidates with8decimalcoordinates/14clearance; Stormwind compatibility3. No pixelcollision/artregeneration. Candidatevalidity/stepbound appliedbefore ranking, including vertex-clearance/movement-circle intersections for a bounded tangentialslide. Existing street endpoint model/radialpadding retained; no neworientedbody orcontinuous-street-sweep guarantee. Perimeter/solids behavior and fullSpeedToWalls retained; defaultlegacyclassification compatible. Sharedcontract/track/art/testdocs aligned; no roadmap criteria changed.

**Executed:** Python `tests/test_circuit_boundary.py -q` PASS9tests, including exactreportedapex, line/circle intersections, tangencies, hiddenintersections and stableorder. Lua5.1 `scripts/test_lua.py --runtime lua51 --tests circuit physics surface obstacles ui` PASS52files/fivemodules; final `--tests circuit` PASS after adding boundedarc-slide regression. Reportedfreepassage, realapex14±0.1clearance/contact, straight76reach, oldprojectionalternative, near-tangential4.154978174move within4.154978274request, and10tickfullspeedactualPhysicsprogress covered. Geometry-onlygenerator/check PASS; structural98paths/24TOCs/links/ledger andwhitespace PASS. Fourchanged/newPythonfiles parse; all12runtimeart and10criticalnon-Circuitmodules byte-identicalf62e708. FullLua5.4/broadsuite, fullartregeneration/nativecost/ownercornerretake **NOT RUN** for this focused correction.

**Deployment:** installed with existing PowerShell7 backup/hashhelper,39files/source/manifest exactlymatchcommitted81cc0ed;39priorfiles verifiedagainstbefore.csv. Manifest `local-artifacts/stormwind-wall-alignment/install-backups/20261022-104405-181-2649cc42360548a2a0242fc1521ba7ea/install.json`; receipt+diagnosticjson/PNG in ignored `local-artifacts/stormwind-wall-alignment/`. No deletion/WTF/otheraddon/clientinput; main/publishedcombinedrefs andClaude/canonicalHEADs unchanged. Sourcecommit81cc0ed plus followingdocumentationcommit remain local.

**Next:** owner `/reload`, retry that same Park/Magecorner and checkactualwallcontact. Gameplayfeedback pending; then resume boundedlive-racecontroller/pacedsnapshots, notmorebroadmanualprobes.
