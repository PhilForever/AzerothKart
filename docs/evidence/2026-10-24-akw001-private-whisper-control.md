# AKW001 — private logged-WHISPER positive control

Reviewed 2026-10-24, Europe/Oslo, after the owner supplied both endpoint reports.
Run configured as0.5DATA/s,16bytes,10second send plus10second drain. Context is
the same private AnoCore server as the preceding score-channel check. This
is observed receive/ACK evidence, not merely successful local enqueue calls.
No live/personal screenshots are copied into Git.

| Field | Sender (owner screenshot2) | Listener (owner screenshot1) |
|---|---|---|
| session / route | AKW001 / WHISPER_LOGGED | AKW001 / WHISPER_LOGGED |
| phase / reason | stopped / window_complete | stopped / window_complete |
| DATA calls / accepted | 4 / 4 | 0 / 0 |
| planned DATA / missed slots | 5 / 1 | 5 / 0 |
| ACK calls / accepted | 0 / 0 | 4 / 4 |
| RX total / DATA unique | 4 / 0 | 4 / 4 |
| matched ACK / timed out / late / outstanding | 4 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| rejected / duplicate / reordered | 0 / 0 / 0 | 0 / 0 / 0 |
| throttle / errors | 0 / 0 | 0 / 0 |
| attempted payload / prefix bytes | 64 / 28 | 64 / 28 |
| prefix registration / successful-send codes | number:0 / number:0×4 | number:0 / number:0×4 |
| RTT n / p50 / p95 / p99 / max (ms) | 4 / 162 / 292 / 292 / 292 | 0 / NA |
| arrival-gap n / p50 / p95 / p99 / max (ms) | 0 / NA | 3 / 1946 / 2211 / 2211 / 2211 |
| reported elapsedSeconds | 20.022 | 23.818 |

**Result: positive control PASS at this narrow scope.** Four attempted DATA
messages reconcile with four unique receipts, four accepted ACKs and four
matched ACKs. The fifth planned opportunity was not attempted (`missedSlots=1`),
so it is not a lost network packet. No exact sequence maps were supplied;
reconciliation is aggregate. Four RTT samples do not establish a sustained
latency/capacity guarantee. No one-way latency, gameplay fairness, packet budget
increase, socket recovery or shared-score publication is inferred.

Both reports are complete enough for these counters. Build/interface and exact
UTC capture times are not printed in this probe report, so the ledger leaves
those fields blank. The preceding score reports identified client70532; do not
silently substitute that into this run's native measurements. The existing
installed runtime source was attested in the preceding checkpoint only.

## Additional owner readbacks

Asked to run `UnitFactionGroup("player")` on both characters, the owner reports
both return Horde/Horde. The simple opposite-faction channel split is therefore
ruled out for the supplied characters; race labels such as Skyborne were not
used to guess a faction.

A subsequent named-channel roster/prefix query printed `Score prefix: true`
and no roster, according to the owner. The reply does not separately identify
each endpoint, so record it as one reported local-prefix readback, not two
independent verified registrations. No roster output is not an empty-roster
measurement; shared membership remains unknown. A common local channel index6
and client-local registered=true do not prove server-side channel fanout state.

## Narrowed diagnosis and remaining check

General logged addon receive/reply works on this server with AZKART1. The
preceding AZKSCP1 CHANNEL window still has no observed matching event. Its
prefix/subscription/channel path is not established by the different-prefix
control. Do not repeat AKW001 or raise its rate.

Primary comparison, inspected 2026-10-24: upstream TrinityCore's
[addon chat handler](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Handlers/ChatHandler.cpp)
routes whispers and channels differently. Its
[channel send implementation](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/Chat/Channels/Channel.cpp)
checks the recipient session's server-side `IsAddonRegistered(prefix)` before
delivery. Thus local prefix registration is not sufficient evidence of the
server's corresponding state. This is an upstream comparison, not inspected
AnoCore handler source or proof that this is the failure. No hyperlink checking
was found in those upstream addon paths; a pipe-delimiter failure is also not
established. No speculative codec/filter/server fix was made.

The smallest remaining active control needs the existing build only:
Fourtwenty Blazeit starts `/akart scores check`; while it is active, Mobby Bobby
sends one plain ASCII logged WHISPER to that character under **AZKSCP1**. The
existing score receiver records matching-prefix event metadata before rejecting
the WHISPER route for score purposes. A report with `event route=WHISPER` would
establish that new prefix/native receive path without changing filters or
publishing any score. This specific control is **NOT RUN**. Channel fanout,
server prefix state, shared membership and public Forever behavior stay open.
