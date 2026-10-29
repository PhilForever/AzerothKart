# Launch menu review — 2026-10-29

Reviewed Claude `6098e73` on top of installed Alterac `fcd1273`/runtime
`858913b`. Approve the implemented cup tabs, paged track/highscore lists,
portrait kart tiles, revised copy, Credits and developer-only diagnostic
lines. Proposed lobby picker/quick-start/minimap work is not implemented.

The review found no blocking callback, selection, multiplayer-transition or
saved-data regression. Added real page-button overflow fixtures (17 track
rows,16 karts) to check recycled identities, cleared/disabled rows, unchanged
driving state while browsing boards, preserved preferences and stable widget
counts. Corrected How to Play’s Arathi active-boost grass exception.

Executed Lua51 menu/ui/multiplayer_integration/session_transport PASS; then
menu PASS after the added regressions.93 Lua source/test files parsed. Both
atlas rebuild checks PASS. Final `preview_ui.py --check --client-fonts` PASS
0 faults using bundled Python3.12 and the client’s local fonts. Review PNGs
were visually inspected; they are offline layouts, not client screenshots.

Current pool121frames/213textures/230fontStrings. Track/kart rows are pooled;
capacity is bounded by5 cup tabs,32 kart icon cells and64 track thumbnail
cells. A sixth cup needs UI work; new catalogue art requires rebuilding its
atlas. The fixed row pools do not imply unlimited catalogue support. Native
appearance, tooltip fallback and loading/memory remain NOT RUN.
