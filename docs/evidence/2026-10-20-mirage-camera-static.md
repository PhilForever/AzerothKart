# Mirage closer camera — stopped client check

Observed 2026-10-20, approximately 01:30–01:32 CEST, through the available client UI. This is separate from the owner's earlier [whole-map screenshot](2026-10-20-mirage-static-background.md). No personal gameplay screenshot is copied into the repository.

After the verified sixteen-file installation, `/reload` and `/akart` showed the normal Test Oval overview. Selecting **Track: Mirage Raceway** displayed the closer salt-flat view across the full 800×480 canvas without the old dark sidebars. The placeholder kart was visibly larger, at canvas position approximately (400,150). The Start strip aligned across the road; the partially visible West strip was clipped at the left canvas edge. Background UV cropping was accepted and rendered with the expected orientation.

**Print Probe**, while still stopped, reported version `1.60.1`, build `70450`, interface `16001`, selected TOC `Camelot`; explicit counts were 9 frames/111 textures/13 font strings. Frame/tick/elapsed values were zero, `active=false`, stop reason `Track selected`, selected track `mirage_raceway`, and no event-registration failures. Combat, text-focus, keyboard and propagation API availability were true; the optional focus API remained unavailable.

No Start, driving or WoW character movement was automated. The check establishes the stopped crop, visible orientation, larger kart and specific Start/West marker placement only. It does not establish moving-camera smoothness, camera edge behavior, driving/handling quality, transparent-sprite alpha, sustained performance or stable object counts during movement. Those remain **NOT RUN**. API availability is not a new input/combat behavior result, and M0/M1/M3 acceptance remains open.
