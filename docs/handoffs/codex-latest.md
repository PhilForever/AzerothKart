# Active reservation — slight wall-contact penalty

2026-10-23 Europe/Oslo. Owner reports v8 wall slides feel almost penalty-free
and requests a very small slowdown. Own clean codex/wall-penalty fromdc52148.
Reserve Physics.lua (first-contact retention/contact speed ceiling), focused
wall-slide and Physics/native version assertions, current API/physics/readme
docs, PROGRESS/INTEGRATION_STATUS and own handoff. Add a5% initial loss and95%
normal-speed ceiling only during contact; preserve steering, recovery, geometry,
scrape drag and parking turns. Physics9 avoids mixed deterministic tuning.
Use focused Lua5.1 checks, then backup/hash-verified install and refreshed ZIP
for the continuing owner test. No art/Claude checkout edits or push/release.

## Previous completed checkpoint

# Codex handoff — published Claude river update and wall handling v8

2026-10-23 14:11+02:00, Europe/Oslo. Owner asks to review/push Claude latest,
then improve sticky wall contact and slow parking turns. Own **codex/wall-slide**,
base505f054, reservation04db93e, reviewed mergefeba3f8, tested/installed runtime
**df2186697439b307055072be0a990137ce379660**. Following handoff commit is docs only.

## Publication and reviewed integration

Approved exact Claude **ee144b5d26fd8522ffdd3b1f7826151a049af074** on
`claude/undercity-river`; normal push and live SHA verification succeeded before
Physics work. Main remainsf923d15; no main merge/force/tag/release. Own later
physics branch is **not pushed**. [Review](../reviews/2026-10-23-undercity-river.md).
Prior combined/city refs queried before this push were absent; the authored
Claude handoff's earlier-publication claim is not repeated as fact.

Claude's Undercityv2 has six flat canal crossings, six gates,1,340junctions and
a5,797-unit lap. Every city is paved to its walls. Ironforgev4 full grip changes
only its policy/version: both narrows and all1,682wall vertices remain. Other
city geometry is unchanged. AGENTS records the reviewed replacement of the old
rough-shoulder rule. Humpelevations remain painted; no slope/layer design adopted.

## Implemented handling and preserved interfaces

Physics8 retains all15state fields and existing movement hooks. First wall
contact loses speed according to admitted travel, capped at1; continuous
contact loses40units/s² rather than repeatedly multiplying speed by0.25.
Blocked frontal/corner movement still stops. Steering remains held, and up to
1.2rad/s of extra parking yaw fades to zero by80speed. Racing/drift90+ yaw,
progressive8/4/12tick steering, charges and boost durations remain unchanged.
Contact clears drift/grace/boost/slip and release acceleration, with no bounce
or automatic facing alignment. Geometry remains authoritative and unchanged.

Native compatibility uses actual Physics.VERSION, now8. Explicit tests reject
v7 peers before grid/countdown/GO; both friends must update. No wire/rate change,
UI object allocation, input policy or new renderer/velocity API. Scalar speed
is requested longitudinal speed; actual wall-tangent movement may be smaller,
and the existing bounded remote forecast can overestimate during wall pressure.

## Executed verification

Actual WindowsPython3.14/pinnedLupa2.8, Lua5.1. Focused handling/native/UI passes,
then final `scripts/test_lua.py --runtime lua51` **PASS32modules/60parsedfiles**.
New regressions cover glancing/persistent/solid/perimeter/realcity contacts,
mirrors/reverse/coasting/frontal/corner/recovery, stationary and racing yaw,
all15fields across30/144FPS delivery, plus current native grid/GO/pacing/cleanup
and v7 refusal. Pool remains79frames/166textures/81fonts. Independent source
review found no blocker. One initial new-test lower-bound estimate was corrected
from29to25units against actual28.172; source was not changed to hide a failure.

Reproducible before/after metrics:45degree contact30ticks travels4.306→60.744units,
ending speed0.861→197.005; frontal throttle+left recovery releases at53ticks in
v8 (v7 still blocked at60); stationary60ticks turns39.44→104.45degrees with zero
translation. Ignored handling-metrics.json/metrics.py retain exact tapes/source
hashes. These are offline behavior, not a claim about native feel or every angle.
Geometry-only generated check PASS, review AST/TGA/provenance checks PASS,
whitespace PASS. Validator FAIL only two historical expired skill links. Full
Lua5.4/art rebuild/native loading/bridge turns/handling/FPS/traffic NOT RUN.
Claude's reported full rebuilds remain separately attributed evidence.

## Installation and friend archive

Installed runtime df21866 at `_classic_beta_/Interface/AddOns/AzerothKart`,
54files matching tested source/manifest/ZIP. All54priorfiles matchcac4290
receipt and verified backup/before.csv. Manifest `local-artifacts/wall-slide-20261023/backups/20261023-141009-111-f42c06aa0c944f65a9a4927419acab14/install.json`.
ZIP created from actual installed folder, CRC/exactpaths/all SHA256 verified:
`C:/Users/bakke/Downloads/Forever_Addons/AzerothKart-Multiplayer-df21866.zip`,
47,241,029bytes, SHA256 `40884600082c3e0d04fce0ace33f2a9573a634a6a61d82aafeb24aeeab22b92a`.
OldZIPs preserved; no other-addon/WTF/SavedVariables or client input touched.
Ignored receipts/logs/snapshots: `local-artifacts/wall-slide-20261023/`.

## Parallel work and synchronization

Claude stays ee144b5 on claude/undercity-river, canonical5570968 unchanged.
All376foreign tracked/untracked file hashes, statuses, branches and HEADs are
preserved. Sixteen rendering/geometry/native production modules and all assets
match reviewedee144b5. Only Physics/addonreadme change in the runtime handling
slice. Claude's authored handoff is imported unchanged; no direct conversation
or acknowledgment claimed. Source/contracts/handoffs provide coordination.

After Claude checks/finishes its own work, a new visual branch may start at
the local combined ref; commands are provided, **not executed**:

```powershell
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" status --short
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" switch -c claude/from-wall-slide codex/wall-slide
```

The name must be unused and conflicting work must cause refusal, never reset.
Cloud use of Physics8 needs separately authorized publication or the established
local bundle transfer. GitHub's Claude river branch is published; it precedes
the local Physics8 changes. Do not install it over this newer combined build.

## Next exact task

Owner fullrestart, then one short angled/frontal wall recovery and stationary
turn check using [the deferred checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-wall-slide-physics8-check--not-run).
Record direct play before more tuning. Both players use this Physics8 archive
for the next Multiplayer menu race. Native acceptance, sharp bridge feel,
trusted finish/contact authority, full socket reconnect, physical slopes/layers
and redistribution review remain open. No milestone completed from source alone.
