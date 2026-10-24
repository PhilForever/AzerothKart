# Score-prefix receive confirmed; CHANNEL path remains open

Reviewed 2026-10-24 20:18+02:00, Europe/Oslo. Owner supplied both screenshots
after the same-prefix control. Private AnoCore evidence only; no live/personal
screenshots are copied into Git.

| Recipient report field | Observed value |
|---|---|
| phase/reason | stopped/check_complete |
| configured route | CHANNEL_LOGGED |
| sent/accepted | 3/3 |
| selfEcho/peerHello/peerACK | 0/0/0 |
| local channel/native send result | 6/number:0 |
| build/cleanup | 70532/membership_preserved |
| matching-prefix incoming event route | WHISPER |
| event localID/name | 0/unavailable |
| diagnostic rejection | event_fields |

Sender screenshot shows several `AK control true 0` lines, not a measured
single-packet run. The recipient prints first-event metadata without per-packet
sequence, received count, sender/body readback or timing. Do not infer total
delivery count, reciprocal delivery, loss ratio or RTT for these controls.

**Narrow receive control PASS:** at least one AZKSCP1 logged WHISPER reached
the actual score receiver while active. Its local prefix/event/Core forwarding
path works on that recipient. `rejected=event_fields` is intentional: metadata
is recorded before the CHANNEL-only guard rejects this WHISPER. localID0 and
no channel name fit this received route. No score was accepted; no receiver
relaxation is needed. The configured route line is the outbound probe mode,
while `event route` describes the incoming control.

The channel peer counters remain0. First-event metadata alone does not count
every other event. Earlier AKW001 separately reconciles4DATA/4receipts/4ACKs.
Both faction readbacks were reported Horde/Horde; local prefix registration
true was reported, but no usable roster appeared. Equal local channel index6
does not demonstrate shared server membership or server-side prefix state.

## Actionable server integration handoff

Stop repeating the completed friend controls. Before an addon change or another
identical window, inspect actual private-server source/observability:

1. Identify the running AnoCore revision and effective configuration.
2. Confirm both players' server-side custom channel membership/GUID and the
   build70532 roster request/response. No roster output is not an empty roster.
3. Trace the client's prefix-registration packet and the recipient session's
   resulting prefix set. Local registered=true does not prove that server state.
4. Trace the logged CHANNEL target/name/GUID decoding, membership resolution,
   addon/recipient-prefix checks and outbound logged event. Compare the working
   logged WHISPER path. Preserve its behavior and existing packet budget.
5. Review findings before changing configuration, registration timing, payload
   framing or architecture. None is an automatic fix authorized by this record.

Upstream TrinityCore's [channel send](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Chat/Channels/Channel.cpp)
uses server-side recipient-prefix filtering, with a distinct
[whisper path](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Handlers/ChatHandler.cpp).
That is a comparison, not inspected AnoCore handler source or a confirmed cause.
Relevant handler source/effective server state were unavailable in the local
repack review, which found binaries/templates. Both characters reporting Horde
rules out blaming the template's opposite-faction channel setting alone.

**Disposition:** global publication remains disabled and the shared channel/
service route remains unverified. No speculative codec/filter/server change,
rate increase or unlogged fallback. Retest only after an identified fix or a
bounded public-Forever opportunity; private results do not prove public behavior.
Local scores and verified directed-peer transport remain intact. No capacity,
authority, release or milestone claim follows from this receive control.
