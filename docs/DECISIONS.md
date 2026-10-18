# Decisions and open questions

## Accepted now
- Name `Azeroth Kart` and format top-down 2D.
- Native WoW addon in Lua; no browser overlay or external executable.
- Deterministic fixed-step pure simulation; UI is a separate renderer.
- Test offline driving first, retain multiplayer vision, gate design on measurements.
- Prototype no borrowed graphic IP or in-game gold betting.
- Demo initially runs on a simple analytical oval; production tracks use checkpoint geometry and collision regions.

## Questions that require evidence / product owner approval
1. What exact installed Forever client build and TOC flavor path are present?
2. Can focused keyboard input coexist cleanly with user keybindings and combat on this build?
3. What is sustained addon message throughput in actual party/whisper in cities, dungeons and raids?
4. Does world zoning and `/reload` disrupt frames and transport in ways affecting race resumption?
5. Is usable simultaneous racing feasible at 2, 4 or 8 players, or should asynchronous time-trial ghost races be the first social mode?
6. Asset direction: illustrated sprites vs pixel art; visual quality target/asset provenance.
7. Cross-realm support: test, do not assume.

## Change process
New decisions enter `docs/adr/NNNN-...md` when architecture or product feasibility changes. Link the empirical test and update impacted acceptance criteria, rather than leaving contradictory docs.
