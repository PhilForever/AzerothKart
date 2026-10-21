# Connection testing — checkpoint complete

**No further manual probe is requested now.** Keep the existing client build; a codec-only development change needs no new download. The next task is implementation of the two-peer session state machine.

## Observed results

- [AKT722](evidence/2026-10-21-akt722-network-window.md): lowest-rate exchange, all 59 attempted DATA/replies reconciled.
- [AKT723](evidence/2026-10-21-akt723-network-window.md): reverse 2 DATA/s,128-byte DATA,120 seconds; all 240 attempted DATA/replies reconciled, no reported errors/throttles/timeouts.
- [AKT724/725](evidence/2026-10-21-akt724-akt725-recovery.md): friend reloaded to Idle, the remaining sender stopped at its ACK deadline, then a fresh explicit session completed all 19 attempted DATA/replies. The interrupted listener's old counters and exact reload time are unknown. This is addon reload/rearming, not a full socket-disconnect or automatic-rejoin test.

US beta hosting and different zones/no group are owner-reported context for AKT723; they do not isolate the cause of approximately700ms RTT. The experimental candidate must handle the measured latency without making local controls wait for network replies.

## Development next

[ADR 0013](adr/0013-two-player-experiment-scope.md) permits bounded experimental two-player control work. A pure RaceProtocol codec now validates invite/join/ready/start/cancel/ACK message formats; it sends nothing. Next implement explicit peer/session state, duplicate handling and bounded timeouts/retries, then integrate the peer flow for an actual two-player candidate. Production replication, clock agreement, live race feel, full socket recovery and expanded player counts are not marked passed.

The [developer checklist](../tests/MANUAL_NETWORK_CHECKLIST.md) retains the completed procedures and future expansion checks. Do not repeat the full rate/size matrix or the completed reload test without a concrete implementation uncertainty. `/akart net help` remains the initial generic probe guide, not a new multiplayer menu. `/akart net report` is local diagnostics and `/akart net stop` cancels an armed probe.
