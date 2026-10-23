# Codex handoff — requested10%/80% wall tuning and Undercity lighting

2026-10-23 15:00+02:00. Own codex/wall-penalty-10, base455d233,
reservationd96557f, tuningc70c8b8, combined/installed runtime
**d3fd99d1d154d45f4d882c9f8cd6759a5944de28**. Following docs commit changes no
addon files. Owner explicitly requests10% impact/80% scrape and latest Claude push.

Physics10: first-contact retention0.90 plus separate0.80normal-speed ceiling
(160forward/44reverse). High-speed hits also meet the cap; below-cap first hits
independently apply10% loss. No per-tick percentage decay. Steering/recovery,
40units/s² drag, parking yaw, geometry and15fields unchanged. Prior7/8/9 peers
refused before live GO. Both friends update.

Focused actual Lua5.1 wall_slide/physics/drift/session_transport PASS,60parsed.
30tick45degree slide160speed/54.438travel; frontal escape53ticks/stationary
1.823rad unchanged. New first-hit/cap/reverse/release and old-peer tests pass.
Merge touches no Lua/testLua, so tested code is unchanged. Whitespace PASS;
validator still has only two historical expired skill links. Fullsuite/Lua5.4/
native new feel NOT RUN for this tuning.

Approved/pushed exact Claudee83c8895c3d8032a7cdf941915e5ff99971d5f52 as normal
fast-forward of origin/claude/undercity-river; live SHA matched and mainf923d15
unchanged. [Review](../reviews/2026-10-23-undercity-lighting.md). Runtime art delta
is only Undercity Background/Preview. Geometry/native code unchanged. Offline
camera review, AST and TGA checks pass; full rebuild/native lighting NOT RUN.
Canonical Claude handoff imported unchanged, with no direct acknowledgment
claimed. Codex's later Physics10 branch is local, not pushed; no release.

Installed54files match source/manifest/ZIP,54priorfiles backed up/verified.
OnlyPhysics/addonreadme/twoUndercitytextures differ;50runtimefiles unchanged.
Manifest `local-artifacts/wall-penalty-10-20261023/backups/20261023-145931-919-febd065f4ce44ece99686fb7d193219f/install.json`.
ZIP from installed folder:
`C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-d3fd99d.zip`,
49,601,326bytes; SHA256 `56b8fe1c43401c7158bce19e5a3fd733ef6f4c26b4db91c214e292605fa3f1ce`.
CRC/exactpaths/hashes and unchanged-target packaging PASS; oldZIP preserved.
Receipts/logs ignored under `local-artifacts/wall-penalty-10-20261023/`.

Both foreign worktrees'377filehashes/statuses/branches/HEADs preserved, including
Claudee83c889 and pre-existing outputs. No foreign source/handoff/checkout changes,
otheraddon/WTF/SavedVariables/clientinput writes. Shared source/docs coordinate
the integration. Future visuals should retain this newer Physics10 baseline;
do not install the older standalone Claude branch over it.

Next exact task: owner fullrestart for changed texture cache, then test wall
scraping penalty. Both friends use Physics10. Native feel/appearance, official
results/contact authority, fullsocket recovery and release gates remain open.
