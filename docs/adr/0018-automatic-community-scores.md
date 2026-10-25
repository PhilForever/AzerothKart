# ADR 0018 — Automatic addon-only community leaderboard

Status: Product direction selected from the owner's 2026-10-25 request for
automatic sharing, prompt board updates and top-3/top-10 congratulations.
Native shared discovery/delivery is still OPEN; no global rollout is enabled.
This supersedes ADR 0017 as the active implementation path. Preserve its
disconnected Python store for possible future server integration.

## Player experience

Players install Azeroth Kart, race, and open Highscores. Eligible completed
solo totals are saved locally and shared automatically. There are no codes to
copy, exports to exchange, desktop uploaders or scorekeeper characters to run.
A new qualifying score should reach connected online participants within a
few seconds under normal conditions. This is a target to measure, not an
established service guarantee. Returning players automatically catch up from
other participants' saved bests.

Each compatible map has one best total per player, with name and finish date.
The bounded shared board retains the top 50; the visible top 3 and top 10 are
subsets. Local personal records and the community cache have separate storage
ownership. A local completed personal best may trigger a placement notice;
duplicate packets, login catch-up and opening the board must not replay it.
Presentation should identify the community board and its refresh status.

## Consistency and scope

For one compatible board, merge the union of received records by taking the
same canonical best for each normalized player, then retaining the top 50.
Resolve equal times by earliest finish date, then stable display-name and kart
bytes. This shared merge is distinct from the existing local Submit operation,
which preserves the first stored equal-time result. Reordering or retrying the
same records must produce the same shared board. Track, physics and rules
versions partition boards; a future adapter admits only known contexts.

A cached board contains the best records it has learned. Offline or disconnected
groups can temporarily differ. Data saved by several players survives one
player going offline, but a result that never reached another participant
cannot become globally known by itself. No complete world-wide rank, instant
consistency, authenticated race time or cheat-proof claim follows from gossip.
Relayed records are client-reported: native relay identity does not authenticate
the original racer. This limitation must remain explicit in integration docs.

## Transport and implementation boundary

Use a dedicated addon channel if actual Forever delivery supports it. Publish
small result updates with priority; pace catch-up requests/replies, suppress
duplicate responses and avoid rebroadcast loops. Sharing must cooperate with
Core's existing event lease and measured race budget, not create an unrestricted
second sender. No every-frame messages or repeated whole-board broadcasts.

Logged WHISPER works between known peers, including the score prefix. The
private server's logged CHANNEL test produced no receipts. Public Forever,
cross-faction discovery and community scale remain unverified. Do not treat a
successful send return as delivery or silently switch to unlogged/public chat.

Channel-roster discovery followed by logged whispers is another candidate.
Blizzard's channel UI uses display indices, which differ from local chat channel
IDs, and roster data can arrive asynchronously. Full Forever names, actual
membership delivery and a request path that does not steal native UI selection
must be established before this becomes the adapter. No new native result is
claimed by that source review.

The pure first slice is now connected in source to cached roster discovery,
logged-WHISPER publication/catch-up, a protected community save child, live board
refresh and local-finish congratulations. [Implementation and current limits](../AUTOMATIC_SCORES.md).
Native roster population/delivery and community scale remain unverified; the
initial test adapter explicitly stops above 32 peers. No native acceptance or
world-wide rank guarantee follows from offline integration tests.
