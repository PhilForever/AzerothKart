# Active reservation — requested 10% impact / 80% scrape tuning and Undercity grade

2026-10-23 Europe/Oslo. Owner requests exactly10% initial wall loss and80%
contact speed cap, plus pushing Claude's latest Undercity update. Own clean
codex/wall-penalty-10 from455d233; review targete83c889, two new commits after
reviewedee144b5. Reserve Physics.lua constants/cap split, focused wall/version
tests, current contracts/docs/PROGRESS/ownhandoff and reviewed11-file art merge.
Preserve all steering/recovery/geometry/native implementation. Physics10 avoids
mixed tuning. Independently review art before non-force publication; install
combined candidate and ZIP after focused checks. No main push/merge/release,
foreign checkout or author-history changes.

## Previous completed checkpoint

# Codex handoff — slight wall penalty, Physics9

2026-10-23 14:44+02:00. Owner requests only a very small extra wall slowdown.
Own **codex/wall-penalty**, baseddc52148; reservation07ec5a2; tested/installed
runtime **58925eb08095f7a227ee96fcbc8f9bf68922856b**. Following docs commit
does not change addon files. No push/release or milestone completion.

First contact loses another5% after its existing angle adjustment. Contact
speed caps at95% of normal maximum:190forward/52.25reverse. Continuous drag
stays40units/s²; no repeated percentage decay. Leaving the wall removes the
ceiling. Steering,53-tick recovery, parking assist, geometry and15state fields
are retained. Physics9 rejects old7/8 peers; both friends need this update.

Focused actual Lua5.1 wall_slide/physics/drift/session_transport PASS,60files
parsed. New tests cover shallow penalty, sustained forward/reverse cap and
immediate release away from walls, retaining deterministic replay/anti-sticking
coverage.30tick45degree slide:189.934speed/58.327travel; stationary1.823rad in
60ticks and frontal escape53ticks unchanged. Independent review no blocker.
Whitespace PASS; structural validator only the two historical local skill link
failures. Fullbroad/Lua5.4/native new feel NOT RUN for this narrow tuning.

Installed54files,54priorfiles backed up/verified, source/installed/manifest/ZIP
hashes exact. OnlyPhysics/addonreadme change fromdf21866;52runtime files unchanged.
Manifest `local-artifacts/wall-penalty-20261023/backups/20261023-144309-479-bad5857506594201b033234abc56d846/install.json`.
Friend archive from installed folder:
`C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-58925eb.zip`,
47,241,206bytes, SHA256 `24e97807dc336d90e2372b8b7c9be5fc4e6bfc358452474e98b1172eeaaf4b88`.
Receipt/logs ignored under `local-artifacts/wall-penalty-20261023/`.

Claude remains ee144b5 onclaude/undercity-river; canonical5570968 unchanged.
All376foreignfiles/statuses/HEADs/branches preserved, no authored handoff or
foreign checkout edits. Source/shared docs coordinate this small tuning; no
direct Claude acknowledgment claimed. Existing city/grid/transport work remains.

Next exact task: owner `/reload`, brush a wall and judge the slight penalty.
Both friends use Physics9. This Lua-only update needs no fullrestart if the
preceding texture build was already restarted. Native feel remains pending;
other production/contact/result/reconnect and elevation gates remain open.
