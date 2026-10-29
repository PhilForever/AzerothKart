# Ice drifting and immersive gates — 2026-10-29

Reviewed Claude `ef0bb58`, including the gate kit/posts/pools, softer lines,
feedback and Alterac geometry2 bridge gate at x988. The actual passability
mask still requires all8 gates (independent flood checks). The review image
was inspected; GateKit’s512×512 RGBA32 header/length/hash match the handoff
(SHA256 A4E6CC10819A72C5AE035AFC9DA834BC7133EB81B49A73749887AB59261CA57C).
The Warcraft-source artwork rebuild was not repeated here.

Codex Physics16 permits normal tier1/tier2 drift charging, correction grace
and release boosts on every passable ice cell, including rough-snow underlay.
Ice traction remains reduced; ordinary snow, brake and wall cancellation
remain. Meter/HUD/help now reflect this.6,660 collision-free real ice-map
samples cover3,891 road and2,769 off-road starts. Legacy goldens and deterministic
tapes pass; old score contexts remain saved and old peers reject.

Fixed one review bug: render-time gate splits used frame-end progress.lastTick,
which advanced after the crossing on catch-up frames. Solo now observes exact
fixed-step progress; tests cover30fps,5step catch-up and2 gates in one callback.
Live views lack exact pass events, so only gate-name feedback is displayed,
with no numeric split history. No authority or packet-rate changes.

Fifteen focused Lua51 modules pass,93 files parsed. Ice/legacy focused Lua54
also pass. Final font-aware preview check has0 faults;14-board export passes
with154-byte HELLO under158 cap. Production pool121/233/232. Validator retains
two historical expired skill links. Native ice feel, remote prediction, gate
appearance/sounds and performance remain NOT RUN.
