# Automatic community highscores

Implemented on `codex/automatic-score-sync`, from `1c029f8`. This connects the
existing saved solo results, pure community ranking and menu. No manual result
exchange, desktop uploader or continuously logged-in scorekeeper is required.
Actual Forever end-to-end delivery for the latest discovery fix remains **NOT RUN**. The owner's two screenshots confirm channel discovery is stuck, with each client showing only its own saved sprint time. Local saving is working.

## Player flow

Fully restart WoW after installing this build: it adds three Lua files. Enter
the world and open **Main Menu → Highscores**. Azeroth Kart automatically joins
its own `AzerothKartScores` channel and reads the cached/event-fed member list.
Compatible addon users exchange scores through logged whispers in the background.
Discovery now also reads complete native party/raid names and remembers a full
peer identity after a valid incoming multiplayer control message. Friends can
therefore synchronize even when the public channel's cached roster never arrives.
No scores or character names need to be copied. Being grouped is one discovery
source, not a requirement for the existing two-player game. Public discovery
for strangers with no current group/racing contact remains unresolved; proximity
or having a character selected as target is not admission. Cross-faction reach
is still unverified.

Finish a normal three-lap solo race. A new personal best is saved locally,
merged into the shared cache and queued ahead of historical catch-up. The visible
table refreshes on receipt. Top-10/top-3 entry, and a move to first place, produce
one local chat/result congratulations notice. Incoming records, login catch-up,
opening results and slower/equal finishes do not replay congratulations.

All karts share the map board; no kart column or filter is added. Name, total
time and UTC finish date remain visible. Historical handling versions remain
saved separately. The garage and kart picker show the current actual handling
profiles, replacing the older installed identical-handling text.

## Quick check for the reported separate boards

Both players update to the same fixed build and `/reload` from the installed
combined build. Join the same ordinary WoW party, then open Highscores for the
same map while stopped and out of combat. Existing saved times are seeded and
shared automatically; no new race is required. Give the boards roughly30seconds;
older multi-map catch-up may take longer. This is the next native check, not
an already verified delivery guarantee. A confirmed multiplayer counterpart is
another automatic source after the race lease ends.

## Status and limits

The board shows its actual discovery/connection state. **Waiting for channel
member list** means the native roster has not become available. No player names
are guessed, and no native chat-channel selection is changed to force it.
`Automatic sharing connected (known peers)` means the group/racing-peer path
has exchanged compatible score messages while public channel discovery remains
pending. `/akart scores` also prints the exact channel/group reason and remembered
count;
the older explicit diagnostic remains `/akart scores check`.

This is a cache of the best compatible scores learned from other players.
Ranks are best-known community ranks, not a complete server-authoritative
global database. Times and relayed records are client-reported. Local accepted
send results are not delivery acknowledgements. New-score delivery should be
prompt once connected; a missed update recovers through periodic reconciliation.
Returning players' historical catch-up takes longer than a new-result update.

The initial test implementation admits at most32distinct recipients across all discovery sources. An
over-capacity roster stops traffic and displays that limit instead of retaining
a stale connected state. Large-community throughput, native latency, full names
from actual rosters and cross-faction delivery need evidence before release.
The previous failed CHANNEL broadcast test remains failed; this adapter uses
cached-channel/native-group/confirmed-racer discovery plus the separately verified WHISPER route.

## Implementation

Current catalogue: thirteen courses, with eleven flat maps on Physics12,
Warsong on Physics13 and Arathi v2 on flat Physics14. AZKSCR2/schema2 HELLO uses fourteen fixed hexadecimal
digest slots, including retired O=0, and an exact-context catalogue hash. The
maximum HELLO is145 bytes including prefix; Arathi adds score code B and all
prior codes remain stable. Maximum legal NEW/ROW is150 bytes, including a
96-byte name. Each payload remains capped151 and native total158 bytes.
Wire contexts permit track/physics/rules versions1..1295, laps1..9 and tickRate60.
Prior thirteen-slot HELLOs cannot complete catch-up with this build. Both peers
need the update for complete reconciliation; compatible direct NEW records from
an older build may still be received. Historical scores and Test Oval remain
saved. No save migration or board reset. [Contract](API_CONTRACTS.md),
[decision](adr/0023-mixed-version-score-sync.md), [maps](PRODUCTION_MAPS.md).

- `ScoreDiscovery.Read` validates an entire bounded cached roster using display
  indices, not local send-channel IDs. Missing/secret/partial data stays pending.
  It neither joins channels nor changes native selection.
- `ScoreDiscovery.ReadGroup` reads complete native group names, preserves full
  Forever surnames/UTF-8, deduplicates and rechecks membership. It makes no joins,
  selection changes or sends. Its40-member read bound is not a racing capacity.
- `ScoreSharing.RememberPeer` is called only after an accepted scoped incoming
  session control message. Configuring a name, an arbitrary score HELLO, a
  target, or the native friend list cannot introduce recipients.
- Discovery unions/deduplicates these sources. Last good channel/group snapshots
  survive partial data for at most30/15seconds. A complete empty/leave removes
  that source; pending data is not treated as an authoritative empty roster.
  Confirmed racing peers live30minutes in memory; accepted score traffic can
  renew an already admitted remembered peer. Receive/send check expiry before
  use, even if a race/combat has prevented the next idle scan. Remembered names
  are not persisted and do not alter score save schemas.
- `ScoreSync` owns readable versioned HELLO/digest, request, row, end and new-best
  packets. Full Forever names are preserved. Current contexts and registered
  kart IDs are validated. Canonical merges converge after duplicates/reordering.
- `ScoreSharing` owns `AzerothKartDB.communityScores`, independent from personal
  `highscores`. It seeds compatible personal bests silently and persists only
  actual changes. Future/malformed/replaced saves are preserved; local saving
  continues if community sharing is unavailable.
- One creation-time frame receives score events. Outgoing attempts are limited
  to one per second and 158 prefix-plus-payload bytes; sends pause during combat,
  chat restrictions and another Core lease, then observe two idle seconds.
  No race/probe hooks are removed. Prefix failures and send failures back off.
- The once-latched eligible finish queues publication. Receive/catch-up cannot
  emit a local achievement. UI rows and result text are reused; no per-tick UI
  allocation or message stream is added.

The integrated Warsong production UI pool is92frames/96textures/151fonts. Core and the score receiver
add two fixed frames outside that pool. Normal WoW SavedVariables saving remains
responsible for disk persistence; development/install scripts never read player
WTF data. No external service or Python database is contacted.

## Evidence

Focused real Lua5.1 checks cover codec/merge, native discovery doubles, mocked
multi-client automatic publication/catch-up, two simulated seconds for a new
best, quiet reload/replay, visible menu refresh, threshold notices, lease/rate
guards and protected saves. These do not establish native roster/delivery/FPS.
After installation, ordinary play can verify the path: both updated clients
enter the world, one finishes a race, and the other leaves Highscores open.
No repeated throughput probe or manual result exchange is needed.
