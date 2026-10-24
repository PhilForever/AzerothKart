# Private score-channel check — no observed peer receipt

Reviewed 2026-10-24 19:48+02:00, Europe/Oslo. Owner supplied two screenshots
after running the score-channel procedure with another client. Evidence is
transcribed below; personal/live screenshots are not copied into Git.

Source candidate77a1891, published combined branch at2ae3f7a. Both native
reports say build70532. The owner's environment is the private AnoCore server,
not public Forever. The second screenshot's GM-panel startup text mentions
70205, but that is another addon's label, not the native probe's build readback.
Nearby normal-chat timestamps before the check are19:40:48/19:40:51; exact
check start/end timestamps, overlapping duration, zones and factions are not
printed in these reports. Do not infer those measurements from appearance.

| Report field | Client A | Client B |
|---|---|---|
| Phase/reason | stopped/check_complete | stopped/check_complete |
| sent / accepted | 3 / 3 | 3 / 3 |
| selfEcho / peerHello / peerACK | 0 / 0 / 0 | 0 / 0 / 0 |
| route | CHANNEL_LOGGED | CHANNEL_LOGGED |
| local channel ID | 6 | 6 |
| native send result | number:0 | number:0 |
| client build | 70532 | 70532 |
| cleanup | membership_preserved | membership_preserved |
| matching-event diagnostic line | absent | absent |

**Result: reciprocal receipt gate NOT MET in this window.** Enqueue acceptance
is not delivery. This is not proof of100% packet loss or a general statement
that AnoCore/Forever cannot support the route. Local channel ID6 on both does
not establish shared membership; preexisting memberships were intentionally
preserved. No shared score publication/query path has been verified.

## Static diagnostic review

Core forwards all nine documented `CHAT_MSG_ADDON_LOGGED` arguments. The
signature agrees with primary build70450 ChatInfoDocumentation and installed
Chomp's logged receiver. The exclusive lease registers before sending; inactive
TransportProbe/SessionTransport do not tear down this frame subscription.
`ScoreChannelProbe.receive` increments eventCount immediately after the prefix
check, before channel ID/name, sender, payload or token checks. Report prints
metadata whenever this count exists. Thus a wrong channel-name/localID filter
would leave diagnostic evidence; it cannot alone explain these two reports
if matching-prefix logged events reached receive.

Still unresolved: no native callback, event/prefix transformation, subscription
or registration differences, isolated channel membership, server fanout, or
insufficiently overlapping runs. The screenshots do not isolate these causes.
No clear code defect was found, so no speculative receiver relaxation or
ordinary/unlogged transport fallback was introduced.

Read-only local server-pack review: its VERSION.txt advertises client70532;
its template enables AddonChannel=1. Neither proves the running server's
effective configuration or logged-message implementation. Only distributed
binaries were found, not relevant server chat handler source. No configuration,
database, GM/privacy state, executable, service or server file was modified.

Installed addon readback now matches every one of the67tested runtime source
files, with one leftover unreferenced legacy drag sprite. This is consistent
with the owner's overlay installation. That file was preserved, not deleted.
No claim is made about the second computer's exact installed hashes.

## Next decisive control — not yet run

Use the existing `AZKART1` logged WHISPER probe on the same server, with the
same two clients. It already has public-Forever evidence; its private-AnoCore
behavior has not been measured. Listener first, sender immediately afterward,
both targeting the other's complete first+surname, fresh6character code,
0.5DATA/s,16bytes,10seconds; allow its10second drain, then both print reports.
Expected positive evidence is listener RXunique>0 and sender matchedACK>0.
Acceptance alone remains insufficient. No new download is needed.

A positive control establishes that known route on this server. It does not
by itself distinguish new-prefix registration from CHANNEL-specific fanout.
If needed, the following targeted diagnostic can read native prefix/event
registration and passively compare both addon event types under a finite
budget, with a same-prefix directed logged-WHISPER control. No such extension
or native control was executed in this checkpoint. Keep publication off;
review results before selecting another architecture or requesting more tests.
