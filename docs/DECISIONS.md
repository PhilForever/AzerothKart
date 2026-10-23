# Decisions and open questions

## Accepted now

- 2026-10-23: owner prioritizes finishing single player before more multiplayer
  playtests and requests total finish time/name/date/global highscores. Local
  records and a bounded visible board are implemented; global publication
  requires a supported shared destination and remains open. Architecture choice
  was delegated to the efficient reliable approach, not proof of a capability.
  [ADR0016](adr/0016-solo-records-and-global-score-gate.md).
- Name `Azeroth Kart` and format top-down 2D.
- Native WoW addon in Lua; no browser overlay or external executable.
- Deterministic fixed-step pure simulation; UI is a separate renderer.
- Test offline driving first, retain multiplayer vision, gate design on measurements.
- No in-game gold betting. Original art and owner-accepted Warcraft III material follow ADR 0009's source/credit/status rules; unrelated commercial racing assets remain excluded.
- Demo initially runs on a simple analytical oval; production tracks use checkpoint geometry and collision regions.
- **Combat interruption (owner confirmed 2026-10-18):** close the racing window, release its controls, finalize the current race placements once and label the result **"Game interrupted by combat"**. Do not resume that race when combat ends. The M0 driving probe has no standings, so it closes and records the interruption without inventing placements. See [ADR 0006](adr/0006-combat-interrupted-results.md).
- **Build-first development (owner confirmed 2026-10-19):** reduce testing effort by about 80% and proceed with playable local M1 slices while remaining M0 manual validation stays open. Use focused checks for changed mechanics; defer long probe sessions and repeated broad matrices. This does not waive acceptance, input/combat safeguards, data integrity or the measured multiplayer gate. See [ADR 0007](adr/0007-build-first-development.md).
- **First production map and vehicles (owner confirmed 2026-10-20):** Mirage Raceway on the dry, pre-flood Shimmering Flats replaces the planned Tinker Speedway. Use precomposed static track art with separate geometry and pooled dynamic sprites; vehicles should be recognizable Warcraft III-like fantasy archetypes, preserving both Siege Tank and Steam Tank. Strict overhead sprites may rotate; angled art needs directional frames. Aircraft initially share ground collision with cosmetic hover. This accepts the direction, without claiming assets cleared or runtime migration tested. See [ADR 0008](adr/0008-mirage-raceway-art-direction.md).

- **Warcraft III asset reuse (owner confirmed, Codex reviewed 2026-10-20):** [ADR 0009](adr/0009-warcraft-iii-asset-reuse.md) supersedes the original-only preference for Warcraft III material while preserving Mirage styling, geometry, pooling and per-file provenance. Another addon's use does not establish a general redistribution grant; source-specific status remains documented for release review.
- **Multiplayer and release priority (owner confirmed 2026-10-20):** [ADR 0010](adr/0010-multiplayer-release-priority.md) places verified multiplayer ahead of dedicated time trials/ghosts. Codex completes the needed mechanics/race/network work through measured multiplayer; Claude supplies three ready maps and eight ready karts. New solid obstacles belong on Test Oval only, not Mirage Raceway. Failed transport gates require owner review rather than automatic ghost substitution; eight karts does not promise eight-player support. The release target is not publishing authorization.

- **Bounded two-peer implementation (2026-10-21):** [ADR 0013](adr/0013-two-player-experiment-scope.md) permits control-protocol/session development after measured traffic and addon reload/fresh rearming. It does not approve production replication, socket recovery or release. RaceProtocol is a pure codec; live session behavior remains next.

## Questions that require evidence / product owner approval

The owner-directed [ADR 0011](adr/0011-explicit-drive-exits.md) replaces incidental click/unassigned-key stops with explicit run exits. Stop must receive its own click; stopped results retain progress and offer a fresh run, track choice or Close. Historical input observations refer to the earlier policy.

1. What exact installed Forever client build and TOC flavor path are present?
2. Can focused keyboard input coexist cleanly with user keybindings and combat on this build?
3. What is sustained addon message throughput in actual party/whisper in cities, dungeons and raids?
4. Does world zoning and `/reload` disrupt frames and transport in ways affecting race resumption?
5. Is usable simultaneous racing feasible at 2, 4 or 8 players? Establish the supported count from actual-client evidence. If transport fails the gate, the owner must review a scope change; ghosts are not currently the first social-mode priority.
6. Per-asset provenance, final illustration treatment, export dimensions and viewport framing within the accepted Mirage Raceway/Warcraft III-like direction; see ADR 0008.
7. Forever has no realms; complete first-name/surname identity and the logged transport follow [ADR 0012](adr/0012-forever-logged-transport.md), reusing IOU's verified compatibility evidence. AKT722–725 now record scoped traffic and addon reload/fresh rearming. Production racing capacity and full socket recovery remain open under ADR 0013.

## Change process
New decisions enter `docs/adr/NNNN-...md` when architecture or product feasibility changes. Link the empirical test and update impacted acceptance criteria, rather than leaving contradictory docs.

## Implemented candidate awaiting shared/client review

[ADR 0014](adr/0014-experimental-start-clock.md) records the opt-in bounded clock/epoch and one-shot Physics/Race initialization foundation under ADR 0013. It is not a production replication or release decision. Actual start skew/drift/feel and live movement/finish remain open.
