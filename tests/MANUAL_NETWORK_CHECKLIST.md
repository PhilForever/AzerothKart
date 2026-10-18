# Manual network acceptance form — F4, future implementation

Client build/date: _______   participants: _______   region: _______
Prefix registered: _______   transport: PARTY / WHISPER   location: overworld / instance
Payload sizes tested: 16 / 64 / 128 / 220 bytes

- [ ] Messages sent with explicit consent and no public spam.
- [ ] Sender event identity and ACK round-trip observed.
- [ ] Success code != delivery ACK, recorded separately.
- [ ] Sending rates tested conservatively from 0.5 and 1 msg/s, then 2/4 only if safe.
- [ ] Enqueue failures/throttle codes recorded with timestamps.
- [ ] p50/p95 RTT, update gap and missing seq IDs recorded.
- [ ] Two-player test stable over 2-minute runs before larger groups.
- [ ] Disconnect/reconnect and zone/instance transitions tested.
- [ ] Real-time 2-player race feel manually rated by both testers.

Measured results, not expectations, should determine live-race feasibility ADR.
