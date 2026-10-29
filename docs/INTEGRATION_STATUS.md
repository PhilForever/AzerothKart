# Shared integration and deployment status

## Installed ice drift and gates — 2026-10-29

Runtime **aa9ed46** installed;102 source/installed and102 prior backup files
independently verified. Friend ZIP `../AzerothKart-IceDrift-aa9ed46.zip` matches.
Both clients fully restart. Native checks pending; authorized feature push next.
[Receipt](PROGRESS.md), [review](reviews/2026-10-29-ice-drift-gates.md).

## Reviewed ice drift and gate candidate — 2026-10-29

Claudeef0bb58 plus Physics16 whole-field drift/boost and exact solo gate
split correction pass focused checks. Alterac geometry2 has its own context.
Native checks pending; install/push next.
[Review](reviews/2026-10-29-ice-drift-gates.md), [evidence](PROGRESS.md).

## Installed reviewed menus — 2026-10-29

Runtime **c8a3eed** installed;101 source/installed and100 backup files
independently verified. Friend ZIP `../AzerothKart-Menus-c8a3eed.zip` matches.
Fully restart for new UI atlases. Native appearance/tooltips/loading NOT RUN.
[Receipt](PROGRESS.md), [review](reviews/2026-10-29-menu-launch.md).

## Reviewed launch menu candidate — 2026-10-29

Claude6098e73 plus Codex copy/overflow regressions approved. Focused Lua51,
atlas rebuilds and final font-aware layout check pass. Native menu appearance,
tooltips and loading NOT RUN. [Review](reviews/2026-10-29-menu-launch.md),
[evidence](PROGRESS.md). Verified install follows.

## Installed Alterac Valley — 2026-10-29

Runtime **858913b** is installed with99 source files independently verified
and95 previous files backed up. Matching ZIP `../AzerothKart-Alterac-858913b.zip`
verified. Full client restart required; native ice feel/remote smoothing,
scenery seams and performance remain NOT RUN. [Receipt](PROGRESS.md),
[review](reviews/2026-10-29-alterac.md).

## Alterac reviewed candidate — 2026-10-29

Reviewed Claude `ee4ac0c` with Codex Physics15 ice and solo/two-player sprint
registration.14-board catalogue and19 focused Lua51 modules pass. Native
feel, ice forecast smoothness, tile seams and frame/memory cost NOT RUN.
[Review](reviews/2026-10-29-alterac.md); [evidence](PROGRESS.md). Install next.

## Arathi open grass installed — 2026-10-28

Runtime **3e3e056** installed; 94 source/installed and 94 prior backup files
verified. Matching ZIP `../AzerothKart-ArathiOpenGrass-3e3e056.zip` verified.
Fully restart WoW; native grass/edge and shortcut balance NOT RUN.
[Receipt](PROGRESS.md); [review](reviews/2026-10-28-arathi-open-grass.md).

## Arathi open grass candidate — 2026-10-28

Reviewed Claude `445c322` and Codex geometry3 collision mask. Focused Lua51
checks and map/score exports pass. Native play and new grass shortcuts remain
unverified. See [review](reviews/2026-10-28-arathi-open-grass.md) and
[PROGRESS](PROGRESS.md). Verified install and playtest are next.

## Installed Arathi v2 — 2026-10-28

Runtime **4dd8071** is installed and independently hash-verified (93 files);
94 prior files are backed up, including the preserved extra. Friend ZIP
`../AzerothKart-ArathiV2-4dd8071.zip` matches. Full client restart required;
user playtest of the v2 track and grass shortcut remains NOT RUN.
[Receipt and evidence](PROGRESS.md); [review](reviews/2026-10-28-arathi-v2.md).

## Arathi v2 reviewed candidate — 2026-10-28

Reviewed Claude `0b27c02` plus Codex’s opt-in Physics14 grass boost.
Focused Lua51 and thirteen-board export pass; native play is NOT RUN.
Install and friend ZIP verification are the next step. See
[review](reviews/2026-10-28-arathi-v2.md) and [PROGRESS](PROGRESS.md).

## Installed Arathi Basin — 2026-10-28

Runtime **8bf3218** on `codex/arathi-integration` is installed. Reviewed Claude
3b85407 is integrated with solo/two-player registration and a solid-aware guide.
All93 source/installed and92 prior backup files independently SHA-256 verified;
legacy extra preserved. Friend ZIP `../AzerothKart-Arathi-8bf3218.zip` has93
entries. [Receipt](PROGRESS.md), [review](reviews/2026-10-28-arathi-basin.md).

Fourteen focused Lua51 modules,87 parsed files and thirteen-board export PASS.
Native gameplay/frame cost and peer/score delivery remain NOT RUN; validator
retains two historical expired links. **Fully restart both clients** for new
assets and complete score catch-up. Arathi's slopes remain visual under flat
Physics12. No GitHub push, main merge, other-worktree mutation or release.


## Arathi reviewed candidate — 2026-10-28

`codex/arathi-integration` combines reviewed Claude3b85407 with the current
Warsong v3 source. Arathi is registered solo/two-player, flat Physics12, with
raceD/scoreB. Thirteen boards fit the existing budget via a145-byte HELLO;
both peers update for full catch-up. Barn guidance is solid-aware and can
hide when no checked route point is clear. [Review](reviews/2026-10-28-arathi-basin.md),
[executed evidence](PROGRESS.md). Installation receipt follows after commit;
native checks remain NOT RUN. No push/main/release.


## Installed Warsong v3 — 2026-10-28

Runtime **a51b60e** on `codex/warsong-v3-integration` is installed, merging
reviewed Claude5cee515. Both bases now run up the outside ramp and out down
the tunnel, with descent-aware cover fades and a guide clearance margin.
All91 source/target and92 prior backup files independently SHA-256 verified;
legacy extra retained. Friend ZIP `../AzerothKart-WarsongV3-a51b60e.zip` has91
entries. [Receipt/evidence](PROGRESS.md), [review](reviews/2026-10-28-warsong-v3.md).

Eight focused Lua51 modules,85 parsed files,12-board catalogue and independent
geometry/guide/history checks PASS. Native checks remain NOT RUN; validator
retains two old links. **Fully restart both clients** after updating. Geometry3
gets its own score context; v1/v2 history and other eleven maps remain intact.
No GitHub push, main merge, other-worktree mutation or release.


## Installed Warsong v2 — 2026-10-28

Runtime **5871f06** on `codex/warsong-v2-integration` is installed, integrating
reviewed Claude0794343 and fixes c362f4a. All91 source/target and92 prior backup
files independently SHA-256 verified; legacy extra preserved. Friend package:
`../AzerothKart-WarsongV2-5871f06.zip` (91 entries). [Receipt](PROGRESS.md).

Both review findings are closed. Eight focused Lua51 modules,85 parsed files,
12-board catalogue and independent guide/mutation checks PASS. Native checks
remain NOT RUN; validator has two historical broken links. **Fully restart
both clients** for the replacement textures and matching geometry2. V1 scores
remain saved separately; other eleven boards/handling/transport are unchanged.
Original Claude checkout/history intact; no GitHub push, main merge or release.


## Installed Warsong build — 2026-10-27

Runtime **9b7d6df** on `codex/warsong-registration` is installed in the owner's
classic_beta AddOns folder. Reviewed Claude79792cd is integrated with registration
and bounded mixed Physics12/13 scores; original worktrees preserved. All91
source/installed files and86 prior backup files independently SHA-256 verified.
Friend ZIP `../AzerothKart-Warsong-9b7d6df.zip` has91 tested entries; legacy extra
remains installed/backed up but is excluded from the package. [Full receipt](PROGRESS.md).
**Fully restart both clients** (six new paths); both need AZKSCR2 for score sync.
All46 Lua51 modules,12-board export and13 Python tests PASS. Native tests remain
NOT RUN; structural validator has two old expired links. No push/main/release.


## Warsong integrated candidate — 2026-10-27

`codex/warsong-registration` merges reviewed Claude79792cd and registers
Warsong solo/two-peer/Highscores. Old11Physics12boards remain; Warsong13 is
separate. AZKSCR2 requires both players update, without saved-data migration.
All46Lua51modules and13Pythonstoretests PASS; catalogue12PASS; structural
validator retains only2historical expiredlinks. Native NOT RUN. Installation
preflight passed; exact committed runtime/backup/package receipt follows.
Fullrestart is required for6newpaths. [Evidence](PROGRESS.md).


## Developer foundation ready for Claude — 2026-10-27

`60a9d77` on `codex/layered-track-foundation` implements reviewed opt-in floors/
ramps/gates/pads and explicit same-size layered telemetry. [Exact contract](LAYERED_TRACKS.md),
[handoff](handoffs/codex-latest.md), [evidence](PROGRESS.md).14focusedLua51modules
pass; current11flatmaps/score contexts remain unchanged. Warsong itself, roof
rendering and playable/score registration are pending. This source is NOT
installed; runtime736ac2f remains the verified player test build. No new push/
release or native claim. Original Claude worktree/branch remain unchanged.

## Installed all-course two-player build — 2026-10-27 08:40 CET

Tested runtime `736ac2f` on `codex/sprint-multiplayer-smoothing` enables all11
courses, including one-run Scarlet sprints, and reconciles friend-kart x/y
packet corrections with bounded geometry recovery. Rematch, art, Physics12,
scores and transport limits preserved. Eleven focused Lua51 modules pass;
native new-course smoothness still pending. All85source/target and86prior
backup files independently verified. Friend ZIP `AzerothKart-AllMapsMP-736ac2f.zip`.
No new paths: reload from3f1b3fe. [Full evidence/next check](PROGRESS.md).
No new GitHub push, main merge, other-worktree edit, release or8-player claim.

## Installed Claude visual/rematch integration — 2026-10-26 21:14 CET

Reviewed runtime `3f1b3fe` on `codex/claude-race-integration` combines Claude
e3c82ad (Gryphon/race-screens/Scarlet-v3) with the current rematch build. Exact
finish metadata, pending/tied results, cold-first-save and peer wing lifecycle
corrections are included. [Review/tests](reviews/2026-10-26-claude-visual-integration.md).
All85source/installed and85prior backup files independently verified; legacy
extra preserved. Matching ZIP `AzerothKart-ClaudeVisuals-3f1b3fe.zip`,85entries.
[Deployment evidence](PROGRESS.md). **Full restart required**, native checks
pending. Other branches/worktrees unchanged; no new GitHub push/main/release.

## Installed multiplayer rematch build — 2026-10-26 20:49 CET

Local tested runtime `94d4d1e` is installed with a complete prior-addon backup.
All84source/installed hashes and85prior files independently verified; legacy
extra preserved. Matching verified friend ZIP is
`AzerothKart-MultiplayerRematch-94d4d1e.zip`. No new paths: reload from da292f6.
[Deployment evidence](PROGRESS.md), [room/results API and short check](MULTIPLAYER_POSTRACE.md).
Native checks remain pending. No new push/release. Claude's newer Gryphon/race
screens/Scarlet-v3 branch remains separate for reviewed integration.

## Local multiplayer postrace candidate — 2026-10-26

`codex/multiplayer-rematch` adds a bounded same-player postrace room, observed
placements and fresh-session rematch/map flow. Current turning/physics/art/
scores/maps remain intact; Claude Scarlet-v3 is not included. Seven focused
Lua51 integration modules and final guard/two-round regressions pass. Native
checks remain pending. [API, player steps and limits](MULTIPLAYER_POSTRACE.md).
No new push/release or main change. Backed-up local test deployment follows in
PROGRESS; same84runtime paths mean reload is sufficient from the previous build.

## Installed Scarlet v2/stat bars — 2026-10-26 14:19 CET

Reviewed runtime `da292f6` is published on `codex/scarlet-stats-review` and
installed with a complete prior-addon backup. All84source/installed hashes and
84prior files independently verified; legacy extra preserved. Matching verified
friend ZIP `AzerothKart-ScarletStats-da292f6.zip` has84entries. Both original
Claude branches are published at unchanged tips8889aa4/e122120; main unchanged.
[Review and executed checks](reviews/2026-10-26-scarlet-fixes-stat-bars.md),
[deployment evidence/next native check](PROGRESS.md). New StatBars.tga path
requires full client restart. No native appearance/feel or release claim.

## Reviewed Scarlet v2 and kart stat bars — 2026-10-26

`codex/scarlet-stats-review` combines reviewed Claude e122120, including Scarlet
fixes8889aa4, with installed Codex98f433e. No blocking review finding or conflict.
Focused combined Lua51/atlas/catalogue checks pass; source remains eleven solo
courses and seven existing two-peer circuits. Three Scarlet versions become2;
the four read-only stat bars raise the pooled budget to89/77/140. Current Codex
systems and saved history are preserved. [Review and pending native checks](reviews/2026-10-26-scarlet-fixes-stat-bars.md).
Owner authorizes publication and backed-up installation; exact deployment
receipt follows in PROGRESS. No main merge/release, force or other-worktree edit.

## Installed combined Scarlet build — 2026-10-26 10:16 CET

Owner explicitly authorized installation. Tested runtime `9c80746` is installed
in the existing AzerothKart AddOns target:83source/installed hashes and78prior
backup files independently verified; legacy extra preserved. Installed files
include both collision/score fixes and all reviewed content/current Codex work.
The matching `AzerothKart-ScarletCup-9c80746.zip` contains83verified entries.
[Exact deployment receipt and pending check](PROGRESS.md). Six new texture paths
require a full WoW restart. Native testing remains pending. No saves/otheraddons,
parallel worktrees, main or release were changed by this deployment.

## Scarlet Cup combined source — 2026-10-26

**Published:** tested source/runtime `9c80746` and its documentation on
`origin/codex/scarlet-integration`. All four original Claude feature tips are
also published, with exact remote hashes verified. Main remains `f923d15`.
No installation or release was performed by this publication task.

`codex/scarlet-integration` combines reviewed Claude ea4425d with current Codex
source, closes the swept-pool and score-code findings, and preserves remote
turning/group score discovery/Physics12/Oval retirement. Eleven solo/score maps,
seven current two-peer circuits; four Scarlet sprints remain solo. Full Lua51
43-module suite,24 Python tests, catalogue and load/asset checks pass offline;
native checks remain pending. [Exact review and limits](reviews/2026-10-26-scarlet-integration.md).
The owner authorizes publishing this integration and the four original Claude
branches. No main update or release. Installed runtime remains01bd880; no install
is performed in this publication task. Claude's worktree remains untouched.

## Latest reviewed source/package — 2026-10-24

Runtime **77a1891**, `codex/podracer-score-review`, integrates Claude0afeedf
Pod Racer/start signs/optional outline with Codex98b3ce2 scores/channel probe.
Both feature branches were pushed and exact remote heads checked. Main is
unchanged. [Review and executed checks](reviews/2026-10-24-podracer-score-integration.md).
Measured pool86/167/135; seven focused Lua5.1 modules and ten outline rebuilds
PASS. No native art/delivery claim. Test ZIP `AzerothKart-ScoreChannel-77a1891.zip`
has67files and is hash/TOC-verified; **not installed**. Installed runtime remains
d3fd99d/54files. Both testers need this exact package and full restart before
[the short second-client check](SCORE_CHANNEL.md). Claude's checkout/handoff
and existing untracked outputs are preserved. No release.

Updated2026-10-22 16:33 +0200, Europe/Oslo. Codex is the designated integrator for the owner's request to combine the agents' work without losing either side. The reviewed combined developer source is installed for owner testing; no release is authorized. See [PROGRESS](PROGRESS.md), [ownership](UI_FLOW_OWNERSHIP.md), [API contracts](API_CONTRACTS.md) and both agent handoffs.




## Latest installed tuning/art — 2026-10-23 15:00+02:00

Combined d3fd99d on local codex/wall-penalty-10: requested10% initial wall loss
and80% scrape cap, plus reviewed Undercity lighting. Physics10, both friends
update; fullrestart for changed textures. Claude exacte83c889 pushed/live-verified
on origin/claude/undercity-river; main unchanged. Later Codex tuning not pushed.
Focusedfour-module Lua5.1 PASS60parsed; native feel/appearance pending.54files
installed/hash-verified,54priorfiles backed up, ZIP from installed folder:
`AzerothKart-Multiplayer-d3fd99d.zip`. Receipts/hashes in PROGRESS/handoff.
No other-worktree overwrite/main merge/release. Earlier entries are historical.

## Latest tuning — Physics9, 2026-10-23 14:44+02:00

Installed58925eb on local codex/wall-penalty adds a light5% initial wall penalty
and95% contact-speed ceiling, preserving the improved sliding/steering recovery.
Focusedfour-module Lua5.1 checks PASS; native feel pending.54installed files and
installed-folderZIP exact;54priorfiles backed up. Archive:
`AzerothKart-Multiplayer-58925eb.zip`. Both peers update toPhysics9; `/reload`
suffices for this Lua-only follow-up. Exact receipt/hash in PROGRESS/handoff.
Other worktrees/art unchanged. No push/release. Entries below are historical.

## Latest installed build — river update and wall handling, 2026-10-23 14:11+02:00

**df21866** on local `codex/wall-slide` combines reviewed Claudeee144b5 with
Physics8: preserved steering and useful angled wall travel, continuous scrape
drag, faster parking turns, unchanged high-speed drift. [Claude review](reviews/2026-10-23-undercity-river.md).
Claude's exact river branch was pushed/live-verified; main remainsf923d15.
The later local Physics8 branch has not been pushed. Both peers must update.

Actual Lua5.1 full32module/60parsed suite PASS; geometry check and whitespace
PASS. Validator still flags two historical local skill links. Native city/handling/
multiplayer feel NOT RUN. Installed54files/source/manifest/ZIP hashes exact,
54priorfiles backed up and verified. ZIP from installed folder:
`AzerothKart-Multiplayer-df21866.zip`,47,241,029bytes. Fullrestart for the
changed city textures. Source/hashes/manifests in PROGRESS/Codexhandoff.
Other worktrees preserved; no main merge/release. Older entries below are history.

## Latest combined build — two reviewed cities, 2026-10-23 10:28+02:00

**cac4290** on `codex/two-city-integration` combines Claude9143949 with the
eb2055a multiplayer grid/profile/countdown/peerart/prediction fixes. Seven solo
tracks/ten karts; Darnassus and Undercity use painted levels with flat handling.
Physical slopes/bridges remain proposals. [Review](reviews/2026-10-23-two-city-integration.md).
Focused actual Lua5.1 sixmodules/59parsed PASS, geometrycheck/boundary11 PASS,
pool79/166/81; structuralvalidator still fails the two historical skill links.
All native newcity/revisedmultiplayer acceptance remains NOT RUN.

Installed54files/source/manifest/ZIP hashes exact,50priorfiles verified in
backup. ZIP from installedfolder: `AzerothKart-Multiplayer-cac4290.zip`,
46,956,754bytes. Exacthash/manifest/receipts in PROGRESS/Codexhandoff.
Fullrestart for newtextures. Multiplayer remains Mirage/TestOval only. Claude's
checkout/source/authoredhandoff and canonicalcheckout preserved; no push/main
merge/release. Earlier entries below are historical checkpoints.

## Multiplayer grid/display follow-up — 2026-10-23

`codex/multiplayer-grid` builds on6ad66d1/c581a52 with immutable kart-profile
agreement, two role-specific grid slots, full3–2–1–GO and timestamp-aware bounded
opponent display. First owner race feedback is [recorded](evidence/2026-10-23-first-live-race.md);
revised native behavior remains NOT RUN. Tested runtime eb2055a is installed:50source/target/manifest/ZIP hashes match,49priorfiles backed up. The installed-folder ZIP is AzerothKart-Multiplayer-eb2055a.zip. Exact receipt is recorded in PROGRESS and the Codex handoff. No asset/track/Physics
change, kart contact, agreed winner, main merge or publication is included.

Claude independently advanced to e96044b on `claude/darnassus-undercity`, from
the same6ad66d1 baseline. Its handoff explicitly preserves the multiplayer
reservation, with catalog-only Menu/test additions. That worktree, its untracked
outputs and existing Orgrimmar ref remain untouched; no new city integration is
included here. Future integration must combine catalog rows with these newer
session/capture/render changes rather than installing the older branch alone.
All older entries below are historical checkpoints.

## Authorized publication and shared baseline

2026-10-22 16:38 +0200: `codex/ironforge-narrows` is published at `c6bb0e5699b5f30d9f684d50283c76b5fd4d4a8b` (normal push/live remote exact); following publication documentation goes on that same branch. All current Claude9461f9c history is included; its checkout is tracked-clean and unchanged. Main remainsf923d15. [Open the combined GitHub branch](https://github.com/PhilForever/AzerothKart/tree/codex/ironforge-narrows), rather than expecting the main landing page to contain it. Installed runtime remains tested82d57eb:41 exact files,41 verified prior-file backup. Native v3 acceptance pending. Codex's [handoff](handoffs/codex-latest.md#authorized-publication-and-claude-alignment) gives Claude safe fetch/new-branch commands; no foreign checkout was switched and no direct Claude acknowledgment is claimed. No release or automatic future publication.

## Current Ironforge v3 integration — installed for owner testing

2026-10-22 16:24 +0200. `codex/ironforge-narrows`, base d5817a8/reservation69dc2dd, integrates reviewed Claude9461f9c. The additive narrows contract is accepted: two radius42 tunnels, matching visual/generator/collision geometry, unchanged route/gates and Stormwind. Lava/anvil/pump art imported; all other runtime images and backend/UI/global Physics unchanged. Focused dual-runtime circuit/physics/surface/ui/menu/determinism,11 analytic tests, geometry check and104-path validator PASS. [Review](reviews/2026-10-22-ironforge-narrows.md). Implementation **82d57eb11e23eb2417a323ba0c714c23514a50af** is installed after verified41-file backup; all41 committed/source/installed/manifest hashes match, and the backup exactly matchesac4ae23 with no extras. Independent receipt `local-artifacts/ironforge-v3-integration-20261022/deployment-receipt.json`; manifest `local-artifacts/ironforge-v3-integration-20261022/install-backups/20261022-163127-637-2915c11e90644cd9ae1a21f6037226c3/install.json`. Both other worktrees'326 files/statuses/HEADs and all previous refs remain intact. The reviewed rough-pocket correction keeps fully paved tunnel corners on road without changing clearance or broad shoulders. Following documentation changes no addon files. Native v3 acceptance remains NOT RUN; no GitHub push or main merge.

## Current Ironforge integration — installed for owner testing

2026-10-22 13:27 +02:00. `codex/ironforge-integration` combines clean899d04d with reviewed Claude `de2fa5f`. Stormwind's owner-confirmed corner/full-speed fixes and the staged background loader remain; Ironforge adds its original route/art and reuses the exposed-wall correction in version2, with rough shoulders retained. Four solo tracks and six karts; no multiplayer activation. Full dual-runtime offline suite, focused regressions,9 analytic tests, generated geometry and103-path structural validation PASS. [Review](reviews/2026-10-22-ironforge-integration.md) and [Codex handoff](handoffs/codex-latest.md) specify scope, resources and native checks. Implementation merge **ac4ae23** (parents7fe251e/de2fa5f) is installed:41/41 committed source/target/manifest hashes exact;39/39 prior files independently verified in backup against before.csv and81cc0ed, no extras. Ignored manifest `local-artifacts/ironforge-integration-20261022/install-backups/20261022-132604-865-804f0c60ebb042a7bc3e340f5eb40463/install.json`; independent deployment receipt in the same task-artifacts root. Both other worktrees'305files/statuses/HEADs are preserved. Full exit/restart is required for new textures; Ironforge native checks remain NOT RUN. Following deployment docs do not change addon files. This feature branch is local; main/published branches and both other checkouts remain unchanged.

## Latest installed collision correction — painted Stormwind wall

2026-10-22 10:46 +02:00: **81cc0ed**, `codex/stormwind-wall-alignment` fromf62e708. Corrects invisibleconcavecollisionwedge atPark/Mage by retaining14-unitcentreclearance to exposedpaintedunion; keepsfullspeed andstraightwallpadding, no art/othertrack/Physicschanges. Reachableprojection/arcslides obeytheoriginalstepbound. Stormwindv3/generatedjunctionmetadata; focusedPython9/Lua5.1checks and98pathvalidator PASS.39installedfiles/source/hash exact,39priorfiles backedup/verified. Native `/reload` retest NOT RUN. Localonly; publishedcombinedc59a607 andotheragentworktree/history remainunchanged. Details inPROGRESS/Codexhandoff.

## Prior installed handling correction — Stormwind full speed

2026-10-22 10:11 +02:00: owner-directed correction **c4b430d**, `codex/stormwind-full-speed` from the published integratedc59a607 baseline. Stormwind version2 has full road grip/speed/drift/boost throughout the existing corridor until wall contact; no slowdown on its painted shoulder. Other tracks/walls/art/globalPhysics7 unchanged. Focused Lua5.1 tests/generator/validator PASS;39files installed/hash-verified,39priorfiles backed up/verified. Owner `/reload` check NOT RUN. This local correction has not been pushed; the combined published branch below remains unchanged. See PROGRESS and the Codex handoff.

## Published combined baseline — pushed and installed before handling correction

2026-10-22 08:37 +02:00, Europe/Oslo. User explicitly authorized latest-handoff review, push and installation, then his client test. Codex read Claude's complete current handoff **78d97a1**, reviewed the city collision/selection changes and integrated that source, beyond the previously reviewed two-track UI. See [city review](reviews/2026-10-22-city-integration.md).

- Original UI/backend merge **6cd611a**, authored preference fix **9b22f12** and future-schema/stopped-state regression **0eb6c63** remain preserved.
- Deployment reservation **e976f55** preceded new changes. Two-parent merge **f9f2af0** adds Claude's **78d97a1** city/runtime/art/pipeline, with per-hunk shared-list/docs/test unions retaining all Codex modules and regressions. Both agent histories and original tips remain intact.
- Tested/installed code **e748b60** repairs a reviewed P2: load/validate a new scenery image on a hidden pooled texture, swapping it into view only on success. No destructive rollback load of the visible image. Final explicit pool **71 frames/165 textures/80 font strings**,24 modules in each TOC. No new multiplayer action/replication.
- Full offline suite **27 modules/52 parsed files in each Lua5.1/5.4** PASS; focused Lua5.1 UI/menu/circuit PASS; validator **96 paths**, TOCs/links/ledger PASS; all18 old Codex modules and12 authored art files preserved. Source39files.
- Normal non-force push created `origin/codex/ui-backend-integration` at codee748b60; the following documentation commit records this deployment and advances the same branch. Resolve its final tip with `git log -1 codex/ui-backend-integration`; final remote-ref verification is retained in the ignored publication receipt. No main/Claude branch push, tag, release or history rewrite.
- **Installed and independently verified:** all39 files in `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/AzerothKart` exactly match this tested source and manifest. Prior22 files are backed up and independently SHA256-checked against preflight/before.csv. Manifest Status/Stage=Verified, BackupVerified=true. No extras, deletion, other addon or WTF/SavedVariables writes.

Evidence/backup root: ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`; exact operation `local-artifacts/deploy-20261022/20261022-082336-b891c186/install-backups/20261022-083240-447-60ddc86aae344da38fa31ae61459972d/`. Both other worktrees'297 tracked/untracked files, HEADs, branches and statuses remain unchanged. The combined checkout now contains Claude's actual latest authored handoff; Codex has not rewritten it or switched Claude's active city worktree.

**Owner test next:** fully exit/restart WoW (new files), `/akart` → Single Player → Capital Cities Cup → Stormwind City Circuit → kart → Race!. Check the city scenery/bridges/Cathedral, driving and Stop/Restart/Close results. Actual native texture loading, menus/fonts/sound/scales/persistence/handling/performance remain **NOT RUN** until the owner reports. Multiplayer remains Coming soon and actual new-prefix/start/live-race/reconnect gates remain open.

## Previous review (2026-10-21)

The trial merge and three wrong preference outcomes remain documented in the [original review](reviews/2026-10-21-ui-backend-integration.md). At that time there was no real branch merge and the P2 finding blocked integration. Today's authored fix, regressions and source merge close that finding without changing historical evidence.

## GitHub and worktree safety checkpoint

2026-10-21: [audit](reviews/2026-10-21-github-safety.md) verified Claude1b2d3d5 and Codexe10d3ef independently descend from83c611c; both histories, other worktrees and untracked outputs are preserved. A verified ignored all-ref recovery bundle exists. Native Windows Git live refs and explicit dry-run push succeed; no actual push/merge/install occurred. Claude's session allowlist and Linux-shell credential errors are separate from this working Windows path. The owner subsequently authorized the two explicit feature-branch publications; the14:07 receipt verifies them. Reviewed source integration remains a separate action.

Codex's review accepts Claude's guarded first-open saved-track restoration for integration. Menu/UI Lua5.1, Windows structural validation and exact preview-art check pass on Claude's source. The combined integration check now passes as recorded above; actual client checks remain pending. Do not install either standalone branch over the shared target.

## Preserved backend history

`codex/start-clock` descends from SessionTransport commit `4f9246a` and adds the opt-in [clock/epoch and one-shot backend race initializer](START_CLOCK.md). Resolve its resulting commit from the Codex handoff/Git. The source is now included in the reviewed combined branch and39-file installation above. Claude's completed `claude/ui-flow` at `1b2d3d5` and its untracked outputs remain untouched. Integration must preserve both branches' shared loader/docs edits; ordinary solo UI.Start remains unchanged. Live movement/finish and actual client validation follow separately.

Previous backend boundary:

`codex/session-transport` starts from the preserved combined83c611c and adds the guarded SessionTransport bridge, copied menu API and focused tests. Its resulting commit is recorded in the Codex handoff/Git; it is retained in the current combined source/installation; that historical feature branch remains unchanged. Claude can inspect [SESSION_MENU_API](SESSION_MENU_API.md) via `git show codex/session-transport:docs/SESSION_MENU_API.md`; coordinate that exact backend commit when wiring the menu. Preserve any active visual branch/changes before creating a new branch or reviewed integration. The roster baseline/history below remains intact; do not install an older standalone branch.

## One integration path

| Role | Branch / state |
|---|---|
| Current reviewed combined source | `codex/ui-backend-integration`, tested/installed codee748b60; city mergef9f2af0 preserves Claude78d97a1 and prior UI/backend fixes. The following documentation commit records deployment. |
| Preserved roster baseline | `codex/roster-integration`83c611c, preserving Codex3644084 and Claude b0b1f2e. The following roster details are historical. |
| Preserved Codex baseline | `codex/peer-session` at3644084; protocol/session/results/Forever transport remain in the combined history. |
| Preserved Claude source | `claude/track-ui` atb0b1f2e, including runtime abe98f6. Its original five commits/authors/hashes are retained. Its worktree and untracked outputs are not changed. |
| Current installed addon |39 files, tested sourcee748b60, verified exactSHA256 with prior22-file backup. Native client test pending full restart. |
| Publication | Combined feature branch published normally; main/local origin/mainf923d15 preserved. No tag or release. |

Do not merge Codex into the old Claude branch and separately install it. All deployment preparation for this checkpoint is from the reviewed combined branch, by Codex, after backup and installed-hash comparison. Claude continues visual work from the combined commit on a new Claude feature branch, preserving `claude/track-ui`. Codex continues backend work on its own branch from the same combined commit. Neither agent installs independently or merges the other's branch automatically. Future changes require a new reservation and reviewed integration.

The quoted Claude reply and its retained handoff are historical: AKT723 was completed, and AKT724/725 recovery plus PeerSession3644084 now exist. Do not execute the older trial-merge command from400590e or install standaloneabe98f6; both omit newer work. The source handoff remains unchanged as evidence of Claude's original branch, rather than being silently rewritten by Codex. In a stale checkout, inspect the current integration ledger from shared Git with `git show codex/ui-backend-integration:docs/INTEGRATION_STATUS.md`.

## Previous roster integration — preserved and resolved

- Normal merge, no squash/rebase/reset/force push or author rewrite. Earlier Claude commits f675610/c6e1b5e/1004e73 were already shared; only abe98f6/b0b1f2e were unique. New integrator commits use the configured PhilForever identity; no request to rename past or future authors was made.
- Four new64-heading WC3 sheets, the six-kart selector and neutral loaded-art colour, plus existing trike/drag car/effects/Mirage assets. Imported binary art stays byte-identical to Claude's committed files. Source/credit/permission records are preserved; this does not clear redistribution.
- Codex's explicit drive-exit policy, Stop/Close results, Forever full-name logged route, opt-in AZKART1 experiment, measured evidence, RaceProtocol and pure PeerSession. Authoritative mechanics/transport modules and their tests are checked against3644084.
- Shared count/docs/test conflicts combine both buttons:11frames/151textures/13fonts. The stronger effect repeatability limitation is retained. Historical evidence/counts are not converted into new client passes.
- Narrow reviewed fixes: a failed kart load restores full previous crop/rotation/metadata; rollback failure falls back consistently to the primitive. Per-kart coverage floors remain12% for ground sheets,8% gryphon and6% gyro. No new gameplay or transport feature is added here.

## Local recovery and future synchronization

Current deployment all-ref recovery bundle and other-worktree file/ref snapshots are under ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`. The earlier Menu integration recovery remains under `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/`. The earlier roster recovery remains under `local-artifacts/integration/20261021-0732-preservation/`. They contain local recovery data only; do not publish the folder. Canonical and Claude tracked/untracked file hashes are compared after integration; no cleanup, pruning or deletion is performed. In the cloud environment, never run Git worktree prune/gc against stored Windows worktree paths.

Claude remains on its active city branch. Do not switch or reset it: its78d97a1 history is now in the combined source, with Codex's reviewed staging-load repair above. Future city work must preserve that transaction, both agents' subsequent changes and their reservations. After that reservation is complete, its owner may create a new feature branch from the exact combined commit. Check status first; preserve new work and stop if a switch would overwrite it. Example for that future clean start, run only by the checkout's owner:

```powershell
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" status --short
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" switch -c claude/next-visual codex/ui-backend-integration
```

These commands were not executed in Claude's worktree. The owner now performs the client test against the coordinated installation above. Next Codex task: bounded live-race controller and paced two-peer remote snapshots consuming the existing backend GO handoff. Native menu appearance, selection/fallback/saving, resource costs and coordinated live-race behavior remain NOT RUN. Multiplayer retains priority; no roadmap acceptance was marked complete.

Final packaging note: the following deployment-documentation commit also corrects the addon readme's staging-texture count. Runtime code remains e748b60. The authorized installer is rerun against that final source tip; its exact final manifest/hash and remote branch tip are recorded in ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/final-publication-install-receipt.json`. The original22-file backup remains intact.
