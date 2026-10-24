# Shared score route — dedicated logged channel

Status, 2026-10-24: **candidate only; the two-client private-server window did
not meet the reciprocal receipt gate**. Both report sent3/accepted3 but no
peerHello/peerACK or matching-event metadata. [Recorded results and next
control](evidence/2026-10-24-score-channel-no-receipts.md). Delivery remains
UNVERIFIED. This does not complete
global publication. Public Forever behavior cannot be inferred from a private
server. The owner reports the public beta is closed until November 4; this is
owner-provided scheduling context, not independently verified service status.

Latest control: [AKW001](evidence/2026-10-24-akw001-private-whisper-control.md)
successfully delivered/acknowledged all4attempted logged WHISPER messages on
the private server. One planned slot was never attempted, not network loss.
Owner reports both characters are Horde; a local prefix readback returnedtrue,
but no channel roster appeared. The remaining uncertainty is the new prefix/
channel path, not general addon delivery. Do not rerun the successful control.

## Route and evidence

Prefer an opt-in dedicated channel with bounded peer synchronization and local
saved caches. It needs no external uploader, hosting operator or always-online
scorekeeper. It would be a community leaderboard with eventual coverage, not a
complete server-authoritative global database. Joining/reloading players would
request missing compatible records; requests, replies and duplicates must have
fixed budgets. No such production sharing is enabled by this diagnostic slice.

Primary implementation references inspected in the workspace:

- Blizzard build70450 `ChatInfoDocumentation.lua:535–550` declares
  `C_ChatInfo.SendAddonMessageLogged`; lines819–834 declare the nine
  `CHAT_MSG_ADDON_LOGGED` event arguments. Its generic target is a cstring;
  native numeric CHANNEL behavior therefore needed a check.
- `ChatConstantsDocumentation.lua:154–166` defines numeric send results.
- `Blizzard_Channels/Classic/ChannelList.lua:389` uses
  `JoinPermanentChannel(channelName)`; line396 uses `LeaveChannelByName`.
- Installed EverAuras `Libs/Chomp/Public.lua:62–92` validates numeric CHANNEL
  targets for its logged-send wrapper. This is library code, not proof of
  Forever channel delivery. No installed caller providing delivery evidence
  was found. IOU's verified logged WHISPER remains a separate route.

The source snapshot is under `research/upstream/wow-ui-source-forever-70450/`
in the parent addon workspace; the actual client checked was build70532.
No generic custom server score store/HTTP service was found in that source.

### Executed native check, 2026-10-24 about 00:24–00:31 Europe/Oslo

Owner's private AnoCore server, using the existing
`_classic_beta_/WowB.exe`, launched through their AnoWoW launcher. Desktop
inventory resolved that executable; the launcher's folder is not a second
addon installation. `GetBuildInfo()` returned `1.60.1`, `70532`, `16001`.
The user handled WoW's custom-script permission dialog. No addon install,
client restart, character movement, account/server changes or file persistence
was performed. Existing UI/TransportProbe/SessionTransport all reported inactive.

A temporary diagnostic frame registered `CHAT_MSG_ADDON_LOGGED`, captured only
prefix `AZKSCP1`, and kept at most the last received event. One send was attempted:

| Observation | Actual result |
|---|---|
| Prefix registration | `0` |
| Dedicated channel lookup after join | local ID `6` |
| `pcall(SendAddonMessageLogged, "AZKSCP1", "1|H|70532-1", "CHANNEL", 6)` | `true, 0` |
| Native Success / InvalidChatType enum | `0 / 4` |
| Matching logged receive events, including final cleanup readback | `0` |
| Lookup after leaving | `0, nil, 0, false` |

The join had a 60-second automatic leave/unregister timer, plus explicit
cleanup of its handler and temporary global. This was a direct API check,
**not an execution of the new 30-second addon module**. No self-echo is not
proof of packet loss: the server may exclude the sender. No second recipient
was present; receiving metadata, cross-zone/faction delivery, capacity,
persistence and public Forever behavior are **NOT RUN**. Do not retry blindly
or turn this successful return code into a claim that publication works.

## Implemented bounded addon check

**Ready test package, 2026-10-24:** combined runtime77a1891 contains the reviewed
Claude visuals, saved solo scores and this probe. Send the same
`AzerothKart-ScoreChannel-77a1891.zip` from the project-pack directory to both
testers. It is not installed yet. Fully exit WoW on both computers, unpack the
archive and copy its `AzerothKart` folder into each client's
`Interface/AddOns/` folder, replacing the addon files. The layout must be
`Interface/AddOns/AzerothKart/AzerothKart_Camelot.toc` (not a nested project-pack
folder). Keep each prior addon folder as a backup; do not edit WTF/SavedVariables.
Relaunch WoW and make sure Azeroth Kart is enabled in AddOns.

Use two characters on the **same server** (both on the private test server if
that is the available environment). Record their client builds/zones/factions
when reporting results. No group, nearby-character check or racing is part of
this probe; cross-zone/faction delivery is still an observation to record.

`ScoreChannelProbe.lua` is offline-tested in the source branch. It is not yet
installed. Once that exact combined candidate is installed and loaded:

1. Close any race/lobby. Two consenting players enter the same server.
2. Both type **`/akart scores check`**, within about five seconds of each other.
3. Wait 30 seconds. The result prints automatically. Save each result; use
   **`/akart scores report`** to repeat it. **`/akart scores stop`** cancels.

Both should first print `Checking dedicated score channel for 30 seconds`.
At completion, both should show `stopped (check_complete)` and **peerHello>=1,
peerACK>=1** for reciprocal receipt evidence. `selfEcho=0` is allowed; a success
return or self echo without a peer reply is insufficient. Send the final report
from each client. If only a menu opens, that client loaded an older build;
check the folder/install and fully restart. If the check refuses, stops for
another reason or has no peer reply, report both results without increasing
the rate or repeating the check in a loop.

There are no character names, realms, codes or numeric options to type. The
check sends diagnostic tokens only, never score/name/date records. Membership
that predated the check is preserved; a membership it created is left on stop.
Result wording distinguishes send acceptance, own echo, peer HELLO, and a reply
addressed to this run's token. Peer replies are observations, not authenticated
proof or score validation. Both peers must show matching replies before adopting
this as the shared route. Testing different zones should follow on the same
two-client window; public-server/faction scope must be recorded independently.

Limits: exclusive Core network lease; 30 seconds total; eight-second join limit;
three HELLOs and at most three replies to distinct peers; six sends total;
at least two seconds between calls, no catch-up burst. Unexpected/opaque/error
returns stop immediately. No login sends, public chat fallback, score writes,
per-tick UI allocations, or rate escalation. Combat/world exit/logout/drive
activation cancel it. Malformed/replayed/wrong-channel events are ignored;
diagnostics retain bounded readable event metadata to investigate API differences.

**Remaining gate:** verify reciprocal receipt with this check on two consenting
clients. If it succeeds, implement bounded versioned record exchange over this
route, with self-reported scores and an explicitly incomplete community cache.
If the native route is refused or peers cannot receive, keep publishing off
and review the evidence before selecting an alternative service.

**After the reported no-receipt window:** AKW001 is now an executed positive
control; keep its reports and do not repeat it. Before further channel trials,
isolate the new prefix with one directed logged-WHISPER observation while the
score check is listening. See the [recorded control and exact remaining scope](evidence/2026-10-24-akw001-private-whisper-control.md).
No new download, unlogged fallback, rate increase or server change is required.
The new-prefix control is **NOT RUN**; publication remains off.
