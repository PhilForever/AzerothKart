# M0–M2 feasibility study — mandatory evidence gates

There is **no game client** in this package's creation environment. All observations below are hypotheses until tested on a real WoW Forever installation. API documentation is not performance proof.

## Hypothesis F1: rendering
**Claim to test:** the client can render ~50 static background sections, ≤32 moving sprites, text HUD, one animated kart at >=45fps on a mainstream PC without visible UI hitching.
- Prototype a flat map window, pooled color textures and rotating kart glyph/texture.
- Test: visual correctness at UI scales 0.75/1/1.25, 15-minute idle, 10-minute continuous steering; no unbounded allocations.
- Record: client build, machine, viewport dimensions, approximate FPS, symptoms and screenshots.
**Gate:** no taint, no stuck frames, keyboard release reliable; if >10ms per-frame overhead measured, optimize/stop scope.

## Hypothesis F2: keyboard control
**Claim to test:** an ordinary UI frame can receive W/A/S/D and arrows only while explicitly in focus and without compromising game chat/combat movement.
- Test keydown/keyup, window toggling, Alt-Tab, escape, click chat, GUI focus changes, zoning, combat start/end and `/reload`.
- Danger: `SetPropagateKeyboardInput` cannot be changed from addon code during combat. Need design in which race controls cannot be initiated in combat; when combat starts, stop simulation and show clear prompt; legal restoration sequence must be checked.
- Test failure => switch to clickable on-screen steering or other permitted input, not insecure code hacks.
**Gate:** all release/focus scenarios safe, no in-combat taint.

## Hypothesis F3: deterministic local physics
- The same seed, controls (held states per tick) and dt should yield numerically identical outcomes for the same client math implementation.
- Test normal, low-FPS, high-FPS, long frame hitch, UI scale change and seeded replay.
**Gate:** 10000-step deterministic test vectors pass; no negative lap or checkpoint abuse.

## Hypothesis F4: transport capacity (HIGH RISK)
**Do not implement full live multiplayer without this gate.**
- Register `AZKART1` prefix, create a consented probe with two real players. Then repeat in groups of 4 and 8 only when available.
- Test `PARTY` and targeted `WHISPER`; 16/64/128/220-byte packets; sustained send budgets 0.5, 1, 2 and 4 packets/second for 2-minute windows. Measure ack'd receipts separately from enqueue success; no spam to public channels.
- Repeat in normal city and instanced setting if possible; record server throttle return codes, p50/p95/p99 RTT, packet arrival gaps, duplicate/reorder counts, CPU/performance impact, peer disconnect recovery. Server limits are dynamic.
- Test what happens if user opens chat and focus leaves canvas, and whether simultaneous 4-kart action remains responsive.
- **Do not** assume '2-4 snapshots/sec + prediction' is viable. Distinguish local visualization from authoritative simulation and finish adjudication.
- Packet budget includes all players and host fan-out; no one state packet per kart per frame. Favor a single aggregate low-rate host broadcast if viable, bitpacked inputs and snapshots under byte cap, with local interpolation.

**Go/no-go: documented trial threshold**: after two-player implementation, player testers must rate handling/visual correction acceptable (> 4/5 average in 5 structured test runs), with no repeated teleporting/false collision/finish disagreements, and transport must stay under a measured sustainable budget with <1% acknowledged-message loss in steady-state tests. Numeric criterion is an internal product target, **not** a claim about WoW network support. Set/adjust thresholds based on evidence; log decision.

**Fallback if no-go:** build `Async Ghost Challenge` (share checkpoints or compact input/ghost tapes, import/export codes, client simulations) or time-trial result exchange; be honest that competitors are not moving synchronously. Preserve full solo racer vision.

## Hypothesis F5: data persistence
- SavedVariables survive `/reload`, logout/login and upgrade migrations.
- Save settings, personal-best laps, compact validated ghost inputs; cap data size. Test with corrupted saves and old schema.
**Gate:** no loss of user configurations, migration tests pass.

## Evidence ledger (do not pre-fill with fake results)
| ID | Build | Setup | Experiment | Actual outcome | Status | Evidence link |
|---|---|---|---|---|---|---|
| F1 | TBD | TBD | Render prototype | Not run | PENDING | — |
| F2 | TBD | TBD | Keyboard/focus/combat | Not run | PENDING | — |
| F3 | TBD | Offline Lua | Determinism + hitch | Not run | PENDING | — |
| F4 | TBD | 2/4/8 clients | Transport/latency | Not run | PENDING | — |
| F5 | TBD | In-game reload | SavedVariables | Not run | PENDING | — |

When an experiment fails, add a narrow ADR before claiming a workaround.
