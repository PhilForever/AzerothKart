# Active reservation — Claude river review/publication, then wall-slide handling

2026-10-23 Europe/Oslo. Owner requests review/push of Claude latest, then fixing
sticky angled/side wall contact and slow stationary turning. Own clean
codex/wall-slide from505f054; review targetee144b5/claude/undercity-river. Reserve
reviewed36-file integration, AGENTS Ironforgepolicy wording, ownhandoff/PROGRESS/
review/contracts/deploymentdocs; afterward Physics.lua, focusedwallhandlingtests,
existing physics/steering/obstacle/drift/surface fixtures, Physics compatibility
assertions in native tests and runner/validator if needed. No renderer or art
implementation edits; preserve Claude checkout and whole current multiplayer
grid/profile/camera/menu code. First approve/publish exact Claude branch; then
integrate and make one deterministic wall-handling slice, with fixed-step replay
and handling metrics. Installation/ZIP follows source checks in ongoing test
workflow. No main push/merge/release or force/history rewrite.

## Previous completed checkpoint

# Codex handoff — reviewed Darnassus/Undercity combined build

2026-10-23 10:28+02:00, Europe/Oslo. Owner requested review and integration if
approved. Own **codex/two-city-integration**, base1733eac/reservation381cb46;
normal two-parent merge/runtime **cac4290dd8421457196a96985135511a96948431**
integrates exact Claude **91439490703c67ff7e90efbfc74e6eff8b66bc72** from6ad66d1
while retaining multiplayer eb2055a. Following handoff commit changes docs only.
[Review](../reviews/2026-10-23-two-city-integration.md). No main merge/push/release.

## Delivered and boundary

Darnassus and Undercity are selectable solo courses, with four new TGAs and
previews/catalog/pipeline/provenance. Seven available solo tracks, ten cosmetic
karts; ThunderBluff soon. Darnassus6gates/3895units/206approach; Undercity5gates/
7327units/noapproach/spawnonloop. Ordered gate tests cover both. Existingcity
data/art and fullgrip/wall semantics remain. Painted tiers/ramps and inert
generated height arrays are accepted; Circuit does not read elevation and
handling stays flat. ADR0015's physical slopes/crests/bridges/kartheight designs
remain proposals, with Physics compatibility and route/layer/replication review
needed. No new simulation feature or milestone acceptance is declared.

All eb2055a multiplayer grid/profile/cues/chosenpeerart/boundedprediction code is
retained. Multiplayer still negotiates only Mirage/TestOval. No kartcontact,
agreedwinner, authoritative correction or automatic reconnect added.

## Review and executed tests

Complete Claude canonical handoff9143949 read/imported unchanged. Independent
read-only reviews cover geometry/gates, art/pipeline/provenance and Menu; root
inspected both panoramic sheets. No blocker. Only README conflicted; resolved
as current multiplayer text plus newcity choices. No whole-file Menu/UI/native
replacement. Corrected Darnassus shortest-city claim, stale count and elevation
proposal's physical-compatibility omission. Claude's original commits remain.

Final actual Lua5.1 **sixmodules/59parsedfiles PASS**:
`scripts/test_lua.py --runtime lua51 --tests circuit menu ui race_grid session_transport multiplayer_integration`.
New tests cover both savedcity restores/correctpreviews and false/throwing
backgrounds retaining actual prior results/state/picture/prefs/counts. Existing
native/E2E grid/countdown/heldinput/peerart/pacing tests passed unchanged. Pool
79frames/166textures/81fonts. Agent's isolated circuit/gridposes and focusedmenu
checks pass. Geometry-only generated check PASS; boundaryPython11tests PASS;
threepipelineAST/TGAheaders/finiteheights/provenance/whitespace checks PASS.
Structuralvalidator FAILonlythetwo historical expired skill links, not a pass.
Lua5.4/fullbroad/fullartrebuild/nativecities/FPS/feel NOT RUN. Claude's separate
two-machine fullrebuild/tests remain attributed author evidence.

## Installed candidate and friend archive

Source **cac4290** installed to `_classic_beta_/Interface/AddOns/AzerothKart`,
54files independently matchsource/manifest/ZIP. Prior50files matcheb2055a
receipt and verifiedbackup/before.csv. Manifest `local-artifacts/two-city-integration-20261023/backups/20261023-102735-053-4fa3216003b74641bd0466db614bcfb2/install.json`.
ZIP created from actual installed directory, CRC/exactpaths/SHA256 verified:
`C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-cac4290.zip`,
46,956,754bytes, SHA256 `3e1ba05309ccefc548050106c8d7654d66cc2d9a21738f3abb2d0e5d1885254d`.
OldZIPs retained; nootheraddon/WTF/SavedVariables/clientinput touched.
Ignoredreceipt/logs/snapshots: `local-artifacts/two-city-integration-20261023/`.
Native newcity loading/look/drive/walls/performance/preferences and revised
multiplayer feel remain NOT RUN. Fully restart WoW for the four new textures.

## Parallel work and synchronization

Claude checkout remains9143949 on claude/darnassus-undercity with its preexisting
untrackedoutputs, canonical5570968 unchanged.370foreignfilehashes/HEADs/branches/
statuses preserved;46existingruntimefiles exactlyeb2055a. OnlyCapitalCities/
Courses/Menu catalog/addonreadme differ, plus four newimages. No direct Claude
conversation/acknowledgment claimed; source/contracts/handoffs are the record.

After checking/finishing its own work, Claude may use this same repository's
local combined ref as the next visual baseline, without resetting its branch:

```powershell
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" status --short
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" switch -c claude/from-two-city-integration codex/two-city-integration
```

These commands are provided, **not executed** in the foreign checkout. The new
branch name must be unused; Git must refuse conflicting work rather than reset
it. Nothing has been pushed; cloud use needs a separately authorized publication
or the established local bundle transfer. Do not install the older standalone
Claude branch over this combined candidate.

## Next exact task

Owner fullrestart then inspect/drive Darnassus and Undercity in SinglePlayer
([city checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md)). Record actual load/
feel before acceptance. A friendrace uses this identical ZIP and the existing
[short multiplayer steps](../MULTIPLAYER_PLAYTEST.md); no standalone netprobe.
Continue multiplayer based on realgrid/peerdisplay feedback; slope/bridge design
remains deferred to a separate task. Productionauthority/contact/trustedfinish,
fullsocketrecovery, nativecost and redistribution review remain open.
