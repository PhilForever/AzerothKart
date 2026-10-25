# Solo finish records and highscores

Current source integrates [automatic community sharing](AUTOMATIC_SCORES.md):
channel-member discovery, logged whispers, catch-up, saved caches and visible
local-finish congratulations. Players do not manually exchange results or run
extra software. Native roster population and actual delivery remain unverified.
The disconnected Python store is retained but deferred.

Personal bests remain in `AzerothKartDB.highscores`; the independent protected
`communityScores` child uses the same versioned bounded schema. Shared caches
seed current compatible personal bests silently. Unknown/future/malformed or
replaced saves refuse writes and are preserved. Sharing failures do not stop
ordinary local saving or race results.

## Player flow

Complete a normal Single Player three-lap race. Results display the full race
total and a personal-best notice, including any new top-3/top-10 placement in known shared scores. Open **Main Menu → Highscores** to see
name, total time and finish date (UTC). The track arrows browse scores without
changing the selected driving track. Previous/Next page through ten rows at a
time. The board retains the fastest total per full player name, up to 50 players
per compatible course. Local slower/equal finishes keep the original best's date; community ties converge to the earliest recorded date.
Karts share one board under the owner's explicit2026-10-25 direction, despite
the new balanced/heavy/agile handling profiles. No kart column or filter is
added. Physics11 starts a fresh compatible board; old Physics10 data is retained.

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
timestamp, internal kart ID metadata and those compatibility fields. Full-name identity
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

The implemented adapter automatically joins its dedicated channel and consumes
cached/event-fed member lists, then uses logged WHISPER. It does not rely on the
previously failed CHANNEL addon-message broadcast. [Exact flow, limits and
pending evidence](AUTOMATIC_SCORES.md). When connected, new local personal bests
have priority over catch-up, and visible rows refresh on receipt.

The board reports actual status and contains the best compatible records it
has learned. Offline/disconnected groups may differ until automatic catch-up.
No complete world-wide or authenticated rank is promised. Notices explicitly
refer to known shared scores. Direct announcements match their native sender;
relayed records and race times are client-reported. The initial test limit is
32 peers; larger rosters show a capacity status and stop traffic.

A fully persistent central server remains a different, deferred option. There
is no hidden HTTP uploader or outside executable, and the addon does not contact
the Python component. Actual native discovery/delivery/cross-faction/scale are
still required before release claims.

## Verification and deferred native check

Focused real Lua5.1 checks cover score_sync, score_discovery, score_sharing,
menu, solo_records and multiplayer_integration, plus existing UI checks. Mocked
clients cover automatic new-best delivery within two simulated seconds, visible
refresh, threshold notices, quiet replay/catch-up/reload, protected saves and
bounded lease-aware traffic. This is not native Forever evidence.

UI pool remains86frames/167textures/135fonts; Core and the new score receiver
are two additional fixed frames. No UI objects or messages are created per
simulation tick. Full restart is required for the three new Lua files.

After installation, two updated clients can simply enter the world, finish a
normal race and leave Highscores open to observe delivery. No repeated network
probe or manual result exchange is required. Native checks remain NOT RUN.
