# Automatic community highscores

Implemented on `codex/automatic-score-sync`, from `1c029f8`. This connects the
existing saved solo results, pure community ranking and menu. No manual result
exchange, desktop uploader or continuously logged-in scorekeeper is required.
Actual Forever roster population and end-to-end delivery remain **NOT RUN**.

## Player flow

Fully restart WoW after installing this build: it adds three Lua files. Enter
the world and open **Main Menu → Highscores**. Azeroth Kart automatically joins
its own `AzerothKartScores` channel and reads the cached/event-fed member list.
Compatible addon users exchange scores through logged whispers in the background.
There is no setup command, code to copy or dependency on being grouped/nearby.
Cross-faction reach is still unverified.

Finish a normal three-lap solo race. A new personal best is saved locally,
merged into the shared cache and queued ahead of historical catch-up. The visible
table refreshes on receipt. Top-10/top-3 entry, and a move to first place, produce
one local chat/result congratulations notice. Incoming records, login catch-up,
opening results and slower/equal finishes do not replay congratulations.

All karts share the map board; no kart column or filter is added. Name, total
time and UTC finish date remain visible. Historical handling versions remain
saved separately. The garage and kart picker show the current actual handling
profiles, replacing the older installed identical-handling text.

## Status and limits

The board shows its actual discovery/connection state. **Waiting for channel
member list** means the native roster has not become available. No player names
are guessed, and no native chat-channel selection is changed to force it.
`/akart scores` prints the automatic status if diagnostic detail is useful;
the older explicit diagnostic remains `/akart scores check`.

This is a cache of the best compatible scores learned from other players.
Ranks are best-known community ranks, not a complete server-authoritative
global database. Times and relayed records are client-reported. Local accepted
send results are not delivery acknowledgements. New-score delivery should be
prompt once connected; a missed update recovers through periodic reconciliation.
Returning players' historical catch-up takes longer than a new-result update.

The initial test implementation admits at most 32 other channel members. An
over-capacity roster stops traffic and displays that limit instead of retaining
a stale connected state. Large-community throughput, native latency, full names
from actual rosters and cross-faction delivery need evidence before release.
The previous failed CHANNEL broadcast test remains failed; this adapter uses
roster discovery plus the separately verified WHISPER route.

## Implementation

- `ScoreDiscovery.Read` validates an entire bounded cached roster using display
  indices, not local send-channel IDs. Missing/secret/partial data stays pending.
  It neither joins channels nor changes native selection.
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

UI pool remains 86 frames/167 textures/135 fonts. Core and the score receiver
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
