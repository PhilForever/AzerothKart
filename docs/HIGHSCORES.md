# Solo finish records and highscores

Central-store work, 2026-10-24: [ADR0017](adr/0017-central-score-store.md) accepts
the owner's central leaderboard direction. [The durable server-side component](../services/leaderboard/README.md)
stores/query-pages compatible personal bests; it is not connected to the addon.
The supported bridge and addon-only/external-uploader constraint remain open.
Local capture/menu behavior below is unchanged; no global traffic is enabled.

Implemented on `codex/solo-highscores`, based on `de4b291` / Physics10.
This is a saved **local leaderboard**, not an all-player global service.
Global publication remains blocked on a supported dissemination/persistence
route. No score messages, public-channel joins or external uploads are sent.

## Player flow

Complete a normal Single Player three-lap race. Results display the full race
total and a personal-best saving notice. Open **Main Menu → Highscores** to see
name, total time and finish date (UTC). The track arrows browse scores without
changing the selected driving track. Previous/Next page through ten rows at a
time. The board retains the fastest total per full player name, up to 50 players
per compatible course. Slower/equal finishes keep the original best's date.
Karts currently have identical handling and share a board.

Race time is exact integer `Race.totalTicks` at 60 Hz, excluding the countdown;
hundredths are rounded for display only. Best lap and last lap are not used to
rank the race. Successful finish is captured once before the result opens.
Reopening results, closing, stopping, combat, partial runs and multiplayer cannot
submit scores. Genuine lost simulation ticks during running disqualify that
score, with an explanation; unused ticks after the terminal finish do not.
The normal race result remains usable even if saving fails.

## Data and compatibility

`AzerothKartDB.highscores` is independently versioned (`version=1`) under the
existing root schema1. Boards are keyed by track ID, track version, physics
version, lap count, tick rate and scoring rules version, in that order. A physics
or geometry change therefore starts a fresh compatible board. Only current
course/handling boards are shown; older stored boards are retained. Maximum
32 boards: a new board beyond this bound refuses saving rather than silently
deleting history. No ghost tape or unbounded run history is saved.

Each row stores the full Forever character name, total ticks, finish Unix
timestamp, cosmetic kart ID and those compatibility fields. Full-name identity
comes from guarded Camelot `NameUtil.GetUnmodifiedUnitFullName("player")`, or
`UnitNameUnmodified` plus the actual
`Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR`.
There is no realm suffix. `GetServerTime()` supplies the finish date; `date`
formats UTC on display. Missing/secret/invalid identity or timestamp refuses a
save with a notice, rather than fabricating a name or date. These new native
readbacks have not yet been run in Azeroth Kart on the actual client.

Unknown fields elsewhere in the root, preferences and prior installed files
remain intact. Absent root/version markers retain their existing initialization
convention; malformed scalar roots and unknown/future root or score schemas are
preserved read-only. Unknown v1 score fields also refuse writes, rather than
silently dropping data. Root/child identities and versions are rechecked at
write time, including after native API callbacks. No WTF or SavedVariables file
is read or written by development/install scripts for this task; WoW performs
normal SavedVariables persistence.

## Global publication — open dependency

2026-10-24 update: [dedicated logged channel investigation](SCORE_CHANNEL.md)
selected the community-cache candidate and executed a one-packet private-server
check on client70532. Join and native send succeeded; no receive event was
observed. Cross-client/public-server delivery and global publishing remain open.
The bounded two-client check is implemented/offline-tested, not installed.

The owner delegated the architecture choice to the most efficient reliable
approach. A genuinely complete, offline-available board needs a persistent
shared destination. There is no implemented/verified Forever leaderboard
endpoint, HTTP uploader or addon broadcast channel in this repository.
Only explicit full-name peers over logged `WHISPER` have client evidence
([ADR 0012](adr/0012-forever-logged-transport.md),
[ADR 0013](adr/0013-two-player-experiment-scope.md)). Generic source declarations
of `SendAddonMessageLogged` and normal custom chat joins do not establish global
addon delivery, discovery, cross-faction reach or delivery to offline players.

A peer-synchronized community cache could be useful but cannot promise global
completeness. A central service would need Forever-supported ingestion and
querying; an external executable/hidden uploader is outside the current addon
architecture. Neither route has been implemented or approved as proven here.
Keep the visible **Global publishing pending** label until the route is chosen
and verified. The next task is to establish that supported route, not to rerun
live-race playtests or market this local board as global.

All times are client-reported. Input/checkpoint tests do not establish anti-cheat
or server-verified scores. Future publishing should contain only the requested
player name/time/date and compatibility metadata, with bounded validation,
rate limits and an explicit privacy/sharing contract.

## Verification and deferred native check

Focused Lua5.1: `python scripts/test_lua.py --runtime lua51 --tests highscores
solo_records ui menu race loop multiplayer_integration`. These are offline
tests with native/UI doubles, not evidence of native storage or layout.
The explicit pool is now **85 frames / 166 textures / 133 font strings**;
six frames and 52 font strings were added, with no added textures. Board rows
are allocated once; no store sorting/identity/date reads/network sends occur
per simulation tick. Results height is 336 to separate its saving notice.

When a test build is explicitly installed (two new Lua files require a full
client restart), complete one ordinary solo race, check its total/name/UTC
date in Highscores, reopen results to check no duplicate, then reload and
confirm the same entry remains. A slower run should keep the earlier date;
a faster run should replace it. A stopped run must not add a score. These
client checks are **NOT RUN**. No new friend test or download is required now.
