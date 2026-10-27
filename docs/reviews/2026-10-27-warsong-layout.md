# Claude Warsong layout review

2026-10-27 16:10 CET. Reviewed `claude/warsong-layout`bf94d2b
(implementation51304df, reservation28c86bc) against shared5c481d4. Owner asks
review only; no code integration, registration, push or install performed.
Original Claude checkout retains only its pre-existing untracked outputs.

## Findings requiring correction before enabling

### P2 — mandatory roof art failure still permits racing

Claude `addon/AzerothKart/UI.lua:802–807` leaves UI.roofs nil when a roof
texture load fails. SelectTrack still succeeds, and UI.Start at1794/1800–1804
checks background/camera readiness only. With Warsong temporarily admitted in
the existing mock fixture and `env.textureModes[course.roofs]="false"`, actual
Lua51 produces `select=true, roofs=nil, active=true, layered=true`. This lets
upper-floor collision remain active without its visible floor/roof art.
The current coming-soon gate prevents users reaching it, but enabling the
course would expose this failure (for example, a missing new file/restart).

Require the complete essential roof presentation or an explicit visible
fallback before Start/Ready. Preserve existing scenery-selection rollback on
failure, and cover refused/throwing loads/reopen with a regression. The arrow
may remain optional; the upper floor's visible geometry is essential.

### P2 — opponent retains a layered draw sublevel after changing to a flat map

Claude `UI.lua:820` sets UI.opponentSublevel nil without restoring the actual
texture layer. The flat restore at1278 requires a non-nil cache, so it then
skips the required call. In-memory Lua51 reproduction using the existing UI
mock: show a ground peer on Warsong at-5, select Mirage and show the peer again:
actual sublevel stays-5, cache nil, peer shown. A high-floor3 value can persist
the same way, affecting ordering relative to the local kart/effects.

Restore the actual opponent OVERLAY0 layer before clearing the cache, or keep
a cache value that accurately describes the texture. Test low/high Warsong
peer→flat map and same-player rematch/map changes.

## Accepted review scope

- Current Warsong geometry has no blocking defect found: main lap uses real
  LayeredTrack with seven ordered ground gates; pads and floor-specific flags
  are coherent. Both optional banana/connector routes independently walked
 369resolved<=4unit steps each, zero contacts, floor sequence010.
- Both grid roles pass actual zero-step collision clearance. Mid finish's west
  half is intentional/reachable; taking the east side requires coming back to
  the gate. This remains an actual-client usability check, not a geometry fault.
- Four pooled roofs, floor sorting, fades, crops and direct next-gate arrow
  are a coherent visual design. The PNG review was inspected as an offline
  image, not native appearance evidence. Pool91frames/96textures/151fonts is
  verified by mocks; actual memory, new-file loading and native look remain open.
- Coming-soon isolation is correct: no playable/scores/session context yet.
  Menu shows one disabled row, skips it in Highscores, TOCs load Battlegrounds
  before Courses, current eleven courses/boards remain unchanged.
- Generator's extra own-floor/end-only ramp adjacency rule is sensible
  defensive hardening. Current Warsong obeys it. The Lua constructor currently
  accepts the broader geometry: a framework follow-up, not an observed map bug.

## Expected Codex integration work

Warsong needs actual race/score identifiers, mixed Physics12/13 catalogue
support and enabling after review. ScoreSync presently rejects differing
context.physicsVersion values. Do not just remove soon and append a digest:
the current legal full-range HELLO would grow155→166bytes including prefix,
above the158byte native ceiling. With literal Physics13 it would be158exactly;
either way the bounded encoding contract needs an explicit change/test.
This was correctly left to Codex and is not a Claude regression.

Keep the current eleven Physics12 boards/history and transport budget.
Registration, complete same-build layered multiplayer flow and coordinated
installation follow the two renderer corrections. No eight-player or native
release acceptance is implied.

## Checks executed in this review

- Actual Lua51 `warsong presentation menu ui circuit dungeon`: PASS6modules,
 85Lua sources/tests parsed, including current turning/position/rematch guards.
- Independent in-memory Lua51 route/grid and renderer failure reproductions
  above; no fixture/source file edits.
- `scripts/export_score_catalog.py --check`: PASS11canonical boards.
- `scripts/validate_project.py`: only the2pre-existing historical skill-path
  links in PROGRESS fail; not a full validator pass.
- Claude diffcheck clean. Its status remains only untracked `Claude outputs/`.

Full46module/Lua54 suite, exact image/model rebuild and WoW native checks:
NOT RUN here. Claude's earlier full-suite/rebuild reports remain attributed
to its own handoff. Installed runtime736ac2f and ZIP are unchanged.
