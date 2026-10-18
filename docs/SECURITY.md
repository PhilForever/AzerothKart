# Security, privacy, performance and fair play

## Trust boundaries
Every network message is untrusted, even from group members. Peer identity from event sender is better than a claimed payload sender but not cryptographic security. Room IDs are not authentication. The host is not a trusted authority in the security sense.

## Rules
- Reject unknown event types/versions, unsupported channels, unknown room IDs, invalid source players, unauthenticated invites/actions, out-of-bounds quantities, future/old ticks, duplicate seq, oversized payloads, control characters and poison strings.
- Rate-limit inbound invites, outward sends and retry loops; retain bounded message queues/seen-set; do not flood chat or print each packet.
- User-set room name/nickname fields sanitized, length-limited, never executed/interpreted as Lua, UI markup or links.
- Addon has no network access beyond WoW-supported addon messaging; no telemetry to third parties.
- Do not persist session data from other players unless needed for current races; user may clear personal best/ghost data.
- No automatic creation of protected macros, bindings or combat actions. Input capture must be user-initiated and combat-safe.
- Data sizes: cap ghost tape, replay length, leaderboard entries, SavedVariables history; migrations tested.
- No gold or real-world wagering; no exchangeable chips; no RMT.
- No copied racer/tracks/assets from Nintendo, Crash Team Racing, other add-ons, or proprietary games.

## Testing
Property/fuzz tests for codec and state transitions; repeated invite spam and stale packet sequences; invalid save corpus; blocked player UX; 20-minute rendering and memory check; double-finishing and replay-tampering attempts; reconcile peers with intermittent packet loss.
