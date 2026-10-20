# AKT723 — reverse direction at 2 DATA/s and 128 bytes

Reviewed 2026-10-21, Europe/Oslo. The owner supplied three screenshots: attachment1 is owner A, now the listener; attachments2–3 are friend B, now the sender. [Sanitized capture](../experiments/AKT723-capture.json) and [two endpoint-local ledger rows](../experiments/network-ledger.csv) record this one window. Player names, chat and screenshots are not committed; attachment SHA256 hashes retain correlation.

## Observed result

Session `AKT723`, `WHISPER_LOGGED`, configured 2 DATA/s,128-byte DATA,16-byte ACK,120-second schedule. Both stopped normally with `window_complete`; all 240 scheduled opportunities were attempted, with zero missed slots.

| Local report | A: owner/listener | B: friend/sender |
|---|---:|---:|
| Arm-to-stop elapsed seconds | 134.788 | 130.000 |
| Prefix raw result | number:0 | number:0 |
| DATA calls / accepted | 0 / 0 | 240 / 240 |
| ACK calls / accepted | 240 / 240 | 0 / 0 |
| Raw send result count | ACK number:0=240 | DATA number:0=240 |
| Matching-prefix RX total | 240 | 240 |
| Unique DATA received | 240 | 0 |
| Matched unique ACKs | 0 | 240 |
| Attempted payload bytes | 3,840 | 30,720 |
| Prefix bytes | 1,680 | 1,680 |

Both report zero failed/unknown sends, throttles, send errors, rejected events, duplicate/reordered DATA, ACK deadline timeouts, late ACKs and outstanding ACKs. No separate ACK-order measurement exists.

**Round-trip timings at B:** n=240, nearest-rank p50=701ms, p95=771ms, p99=913ms, max=1012ms. **Unique DATA gaps at A:** n=239, p50=500ms, p95=551ms, p99=667ms, max=767ms. The unused timing class at each endpoint has zero samples/NA, not measured zero latency.

240 accepted DATA calls match 240 unique DATA receipts;240 accepted ACK calls match 240 sender ACKs. No attempted message is unaccounted for in this observation window. Because valid sequence IDs are bounded 1–240,240 unique DATA receipts and240 matched ACKs imply complete sequence sets. This is an inference from counters and bounds, **not an invented raw bitmap transcription**. Visible maps agree; player portraits/other UI obscure some positions, so the structured capture leaves full raw bitmap strings null.

The pair made 480 DATA+ACK calls, totaling 34,560 attempted payload bytes plus 3,360 prefix bytes. Dividing by the configured 120-second schedule yields316 payload-plus-prefix bytes/s across both directions, excluding unknown network overhead. Individual send and ACK classes remain distinct; this is not an unlimited or eight-player budget.

## Context and interpretation

The owner reports that the characters were **in different zones and not grouped**, and that the Forever beta servers are in the US. Thus this observed logged-whisper exchange worked without grouping or co-location. Exact zone names, client builds/interfaces, test UTC and client commit attestations were not supplied. Expected probe source was `8f66c5a`; newer Claude work is not silently included or assumed installed.

Record US hosting as owner-reported context, not an independently verified cause of the RTT. No synchronized peer clocks, baseline game-ping samples or route/queue measurements were captured. Server distance may contribute, but this experiment cannot divide RTT into travel time, server scheduling or addon processing; it cannot establish expected future EU-server latency. Different elapsed totals include local listener waiting/drain and do not measure one-way delay.

The previous [AKT722](2026-10-21-akt722-network-window.md) median/p95 RTT was 697/779ms with 59 samples; this run gives 701/771ms with 240 samples. Central timings are similar, while the larger maximum has a different sample count, direction, size and rate. This is not an isolated-variable comparison or proof that higher rates have no latency cost. No ACK deadline backlog was reported in either completed window. Approximately 0.7-second median RTT remains a material live-racing synchronization concern; there is no accepted numeric RTT threshold to silently pass/fail.

## Gate disposition and next single task

**Demonstrated:** completed reverse 128-byte/2-DATA/s window, count-reconciled DATA and return ACKs, zero reported error/throttle/timeout, and owner-reported cross-zone/ungrouped reachability in this context. The two-client budget sample can be checked separately from untested 4/8-player budgets. M2 overall and live-race acceptance remain open; no production synchronization architecture is selected.

**Next:** a short listener-reload/fresh-session recovery pair on the existing probe. `AKT724`:2 DATA/s,128 bytes,20seconds, friend listens/owner starts; friend reloads about 5seconds after owner arms. Owner retains its normal stop/report before the next arm; friend should return Idle with unsaved prior counters unavailable. `AKT725`: same rate/bytes,10seconds, explicitly arm both with the fresh ID and retain both reports after completion. This is prepared, **NOT RUN**. Native peer-unavailable errors or unexpected stops must be recorded; do not invent a timeout result. `/reload` tests addon lifecycle recovery, not a socket disconnect/full logout. Actual race corrections/feel and expanded contexts remain separate acceptance work.
