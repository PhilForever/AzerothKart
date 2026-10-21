# Gemini feedback review

2026-10-21. Reviewed the owner's pasted feedback against source commit `2232f82`. This records assessment, not authorization to implement the suggested architecture or formats. No source/API/art changes.

## Recommendations to retain

- Shorten current documentation and archive historical progress while preserving evidence links and handoffs. The repetition criticism is fair; documentation cleanup should stay small and should not displace multiplayer work.
- Consider a first two-player candidate with non-colliding remote karts. Keep local track collisions authoritative and remote presentation read-only. This is a candidate scope, not verified gameplay or a finalized collision policy.
- Bounded remote kinematic snapshots are a reasonable next experiment. They must share the existing budget with control/results/retries; two snapshots per second are not two additional calls per second. Interpolation buffering, extrapolation limits and stale-state behavior remain design work.
- After reviewed Claude menu integration, extract rendering and session control incrementally. A large UI rewrite during parallel development would add avoidable integration risk.

## Corrections

| Feedback claim | Verified correction |
|---|---|
| Clock modules are unfinished/unlisted; no start-clock tests | Stale snapshot: `2232f82` commits all three modules, both TOC entries and `test_start_clock.lua`. Focused validation is recorded in [PROGRESS](../PROGRESS.md). |
| Measured capacity is two calls/158 bytes per second per peer | This is the implemented local candidate ceiling. [AKT723](../evidence/2026-10-21-akt723-network-window.md) exercised asymmetric DATA/ACK loads totaling 316 payload-plus-prefix bytes/s across the pair. Simultaneous bidirectional movement is unverified. |
| Start alignment within about 350 ms | No such guarantee follows from half the observed RTT. [StartClock](../START_CLOCK.md) reports an offset interval, assumes approximately constant offset during negotiation and separately allows callback lateness. Actual skew/drift remains unmeasured. |
| Integer finish ticks are 100% immune to render jitter/network latency | Integer ticks give deterministic simulation durations for identical executed steps. [Loop](../../addon/AzerothKart/Loop.lua) deliberately drops excess hitch time. Shared start/finish agreement, fair elapsed-time policy and peer-report trust remain unresolved. |
| Reproducible on all operating systems/Python versions | Recorded matching outputs cover specific checked environments/inputs; see the [trike sheet](../art/karts/goblin-mortar-trike.md). Do not turn those results into a universal compatibility claim. |
| Mirage background is 3 MiB; texture memory is completely fine | The actual background is 4 MiB raw BGRA32. All nine current TGA pixel payloads total 24.65625 MiB (25,854,114 file bytes including headers). File sizes and lazy selection do not measure GPU residency, caching, load hitches or memory acceptance. |
| RLE TGA saves 60–70% and should replace current sheets | A read-only packet-size estimate over current WC3 sheets gives roughly 49–64%, varying by sheet; this is not a client test. Type-10 loading is unverified; builders/validators currently require type 2. Distribution already uses ZIP deflate. Compare actual package sizes and verify the client before changing formats. Disk compression does not establish lower texture memory. |

## Executed evidence and next task

Read-only source/TOC/test existence inspection and two independent source audits. One real Lua 5.1 micro-experiment executed the actual Loop for one synthetic second: 60 callbacks executed 60 ticks/zero dropped time; one callback executed five ticks and dropped 0.916667 seconds. This demonstrates the timing distinction, not a measured client stall. No broad suite, asset regeneration or game checks were run for this review.

Next development task remains the bounded live-race controller and paced remote snapshots from the backend GO handoff, with a reviewed remote-render contract for Claude. Gameplay acceptance and finish policy still need evidence; Gemini's favorable verdict does not close those gates.
