# Finite group-delivery check

This opt-in diagnostic establishes whether logged PARTY or RAID messages really
reach consenting group members in Forever. It does not enable an eight-player
race, require grouping for existing two-player races, or run on login.
Native group delivery and eight-racer aggregate capacity remain **NOT RUN**.

## Short procedure, after installing the combined candidate

1. Everyone installs the same combined build and fully restarts WoW. This update
   adds `GroupProbe.lua`; reload alone is insufficient when the file is new.
2. Make a WoW party or raid of two to eight consenting testers. Stop racing.
   Everyone must agree to this check; remove any nonparticipating members.
   No character names or realm suffixes need to be typed.
3. Pick one sender and a fresh six-character uppercase/digit code, e.g. `NET801`.
   Everyone except the sender first types:
   `/akart net group listen NET801 RAID`
4. Within 30 seconds the sender types:
   `/akart net group host NET801 RAID`
5. Wait about 30 seconds. Results print automatically. **Do not reload before
   saving the reports.** `/akart net group report` prints them again.
6. Save the sender's report and each listener's report. For a normal party,
   replace `RAID` with `PARTY` in both commands. They are separate route checks.

Cancel with `/akart net group stop`. Use a new code after an ended attempt.
`/akart net group help` shows the command syntax. No higher-rate retry is needed
if the route fails or Forever refuses it; retain the exact result for review.

## Reading the result

The sender attempts ten small group DATA messages, one every two seconds after
a one-second quiet handoff. Listeners return paced logged-whisper receipts for
the actual DATA they saw. Numeric send success and self echoes are not delivery.

For a complete clean window, the sender has ten accepted attempts and ten
matched receipts for **each** listener. Each listener has ten unique DATA and
ten accepted ACK sends. In an eight-member group this is ten group sends and
70 distinct return receipts, not seven copies of every outgoing group DATA.
Read per-peer masks, missed local slots, duplicates, ordering, RTT and errors;
missing receipts alone are not proven packet loss. A hitch can leave a local
slot unattempted, which is recorded separately. There are no catch-up bursts.

Any errors/throttling, wrong-route events, incomplete reciprocal evidence or
roster changes leave the gate open. A two-client clean result proves only that
route and window. This single-sender low-rate check does not establish the
aggregate load of eight racers sending two updates per second each.

## Implemented boundary

`GroupProbe.Init(frame,reporter?)` stays idle. `Start(role,code,route?)`,
`Command`, `Stop`, `Update`, `Message`, `HandleEvent`, `GetView` and `Report`
belong to this finite diagnostic. A missing route selects the current native
group type; the explicit commands above avoid mixing results.

Start snapshots two to eight complete native Forever identities using guarded
group/unit APIs, fixes the route/session and reserves Core's exclusive frame.
The listener binds only a valid native sender in that snapshot. Another host,
unreadable fields, changed membership, lost lease, combat, world departure,
clock errors, send refusal or throttling stops the check. Private queues,
native callbacks and mutable identity tables are not exposed by copied views.
There are no new UI objects, automatic invites or score/race messages.

The group check shares SessionTransport's persistent 0.5-second cadence and
rolling two-call/158-prefix-plus-payload-byte window through
`ReserveDiagnosticSend(owner,nowSeconds,bytes)`. A reservation consumes budget
before the native attempt, including throws, and requires the diagnostic's
actual lease. An immediate return to normal racing cannot reset that window.
Historical standalone probes keep their own rates: GroupProbe waits one second
on entry, and their entry guards wait one second after its last reservation.
Score sharing already yields to the lease and waits two idle seconds.

The pinned local Forever UI source, version1.60.1.70450,
`Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua` documents
`SendAddonMessageLogged` with `chatType` and the logged receive event. This is
an API contract, not receipt evidence for the installed build. No ordinary or
unlogged chat fallback is enabled.

Offline checks cover two-member PARTY and eight-member RAID fan-out, exact
identity/session/route, distinct receipt evidence, bounded scheduling/budgets,
roster/lifecycle/opaque-value cleanup and native callback reentry. Native
delivery, full reconnect, live eight-racer rooms and release acceptance remain
pending. Existing ungrouped two-player whisper racing stays available.
