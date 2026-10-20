# AKT722 — first completed two-client logged window

Reviewed 2026-10-21, Europe/Oslo. Evidence: three user-supplied screenshots, first from sender A and the other two from listener B. Names, unrelated chat and screenshots are not committed. Attachment hashes and a sanitized transcription are in [AKT722-capture.json](../experiments/AKT722-capture.json); [the ledger](../experiments/network-ledger.csv) contains **two endpoint-local rows for this single window**, not two independent trials.

The expected installed source was `8f66c5a`. These screenshots do not attest either client's commit, build/interface, location or exact UTC test time; those fields remain unknown. The report demonstrates that the logged probe was running. Historical build70450 observations are not silently substituted for missing metadata.

## Observed configuration and result

Session `AKT722`, native WHISPER / explicit route `WHISPER_LOGGED`, A sends DATA and B sends ACKs. Configured DATA rate 0.5/s, DATA 16 bytes, ACK 16 bytes, schedule 120 seconds, planned 60 opportunities. Both ended `phase=stopped reason=window_complete`.

| Local report | A: sender | B: listener |
|---|---:|---:|
| Arm-to-stop elapsed seconds | 130.000 | 147.325 |
| Prefix registration raw | number:0 | number:0 |
| DATA calls / accepted | 59 / 59 | 0 / 0 |
| ACK calls / accepted | 0 / 0 | 59 / 59 |
| Raw send code counts | DATA number:0=59 | ACK number:0=59 |
| Received matching-prefix events | 59 | 59 |
| Unique DATA received | 0 | 59 |
| Matched unique ACKs | 59 | 0 |
| Local missed schedule opportunities | 1 | 0 |
| Attempted payload bytes / prefix bytes | 944 / 413 | 944 / 413 |

Both reports show zero failed/unknown sends, throttles, send errors, rejected events, duplicates, reported reorder, ACK deadline timeouts, late ACKs and outstanding ACKs. Reorder accounting here describes unique DATA arrivals; there is no separate measured ACK-order statistic.

**Round-trip timing at A:** n=59, nearest-rank p50=697ms, p95=779ms, p99=881ms, max=881ms. **Unique DATA arrival gaps at B:** n=58, p50=1995ms, p95=2094ms, p99=2124ms, max=2124ms. The other timing class has zero samples/NA at each endpoint; NA is not measured zero latency.

## Reconciliation and source diagnosis

59 locally accepted DATA calls match 59 unique listener receipts;59 locally accepted ACKs match 59 unique sender ACKs. **No attempted DATA/ACK is unaccounted for in this completed observation window.** This is not a guarantee of loss-free transport in other windows.

B's complete bitmap shows DATA receipt and ACK acceptance for sequences 1–59, with sequence 60 absent; its DATA-sent/ACK-received maps are empty. Parts of A's bitmap display are obscured by the game portrait/wrapping, so a complete independent transcription of A's positions is not claimed. Its aggregate counts, visible map portions and B's complete maps agree. No missing sender bitmap text is reconstructed as raw evidence.

The unattempted terminal opportunity is a **local probe boundary limitation**, not demonstrated network loss. In current `NetworkProbe.advance`, the first callback strictly after the 120-second schedule closes sending before `update` can attempt the slot due exactly at 120. Offline real Lua5.1 reproduction on the unchanged source:

- Final callback exactly 120 seconds:60accepted sends / 60 matched ACKs, missedSlots 0.
- Final callback 120 seconds + 1 microsecond:59 accepted / 59 matched, missedSlots 1, sequence 60unattempted.
- Regular60 Hz callbacks offset by 1 ms: the same59/59 and one missed terminal slot, with no simulated hitch.

Injected ACKs in these reproductions are test fixtures, not live samples. This explains the counters but does not establish the actual client callback times. The harness is unchanged for the next trial so neither tester needs a reinstall. A repeat solely to obtain60/60 is unnecessary. At 2/s the same boundary behavior can produce239 attempts out of240 planned opportunities.

The different elapsed totals include local listener waiting and drain periods. Do not subtract them to estimate one-way latency, clock offset or network asymmetry.

## Gate disposition and next single trial

**Demonstrated:** actual `AZKART1` two-client capability, full-name scoping, logged prefix/send success codes, completed lowest-rate exchange and reconciled counts. Mark only the roadmap's two-client capability criterion complete. M2 overall stays open.

The approximately 0.7–0.9second round trip is a material racing-design risk. There is no previously accepted numeric RTT pass/fail threshold, so this result is not silently labeled a failed gate or a production racing GO. Higher payload/rate, reverse DATA direction, reload/recovery, actual race corrections/feel and larger participant budgets remain unmeasured. No production replication architecture is selected here.

**Next:** existing build, fresh `AKT723`, reverse roles (A listens, B starts),2 DATA/s,128-byte DATA, 120 seconds. This one exploratory scenario tests reverse DATA and a more useful payload/budget together; it is not an isolated parameter experiment. Nominally 2 DATA + 2 ACK calls/s across the pair,288 payload bytes/s plus 28 prefix bytes/s= 316 bytes/s before unknown overhead. Existing stop/error/throttle/deadline guards remain; no automatic escalation. The full rate/size/PARTY/4/8-player matrix is reference work deferred from the first two-player candidate. A short explicit reload/fresh-session recovery check remains necessary before the live-race architecture decision.
