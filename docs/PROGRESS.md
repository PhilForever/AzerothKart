# PROGRESS — persistent project handoff

**Current milestone:** M0 — repository and actual-client/API feasibility. **OPEN.**
**Current state (2026-10-18, latest session ~17:33 CEST):** combat closes the racing window and records one retained interruption result/note. Seven offline tests pass in Lua 5.1/5.4. The installed probe's identity, rendering/Start, ordinary stop/window actions and clean inactive reload were observed. The owner confirmed actual combat closure, the interruption message and working WoW controls. The simultaneous W/Up case is SKIPPED at owner request, with offline alias coverage retained. M0 timed driving/performance, persistence and unrun edge cases remain open. See [sanitized live evidence](evidence/2026-10-18-m0-client.md).

## Canonical checkout and commits

Work in this directory: `C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart`.
Remote: `https://github.com/PhilForever/AzerothKart.git`; branch `main`. The pack originally had no `.git` history; remote inspection returned no refs. The original pack was preserved before changes.

- `98bd16a` — `chore: preserve initial Azeroth Kart M0 project pack`.
- `be33176` — `fix: harden M0 driving probe and feasibility checks`.
- `c2ecadf` — `docs: record M0 validation evidence and client handoff` (initial offline session).
- `6e20ec0` — `fix: close kart sessions when combat interrupts`.
- The following documentation commit records the actual-client handoff; inspect `git log` for its hash.

Repository-local identity is `PhilForever <philfluenser@gmail.com>` with `user.useConfigOnly=true`; verified in config and commit authors. Global identity was left unchanged. No push, tag, distribution or automation was performed. The later client-check session installed only AzerothKart in the local Forever AddOns folder and verified all nine files against source SHA-256. Ignored `local-artifacts/` contains test dependencies/logs only and is not staged.

## Completed and evidenced

- [x] Inspected all original source, tests/scripts and documents from `docs/INDEX.md`, including ADRs; preserved initial content in Git.
- [x] Structural validation of paths, synchronized TOC source order, discovery markers, local Markdown links and network-ledger fields.
- [x] All six addon modules and eight Lua test/runner files parsed under both Lua 5.1 and Lua 5.4; seven tests executed in each runtime.
- [x] Removed `_G` dependency from pure Track/Physics modules; introduced pure Input and Loop modules with explicit addon namespace registration/returned offline imports.
- [x] Corrected inverted left/right steering; physics compatibility version is 2. This is still the analytical M0 handling probe, with no drift or production collision/race engine.
- [x] Physical-key alias tracking prevents W/Up and equivalent steering/brake releases from canceling another held alias. Sampling reuses a semantic input table; stop clears held/sampled controls in place.
- [x] Fixed 60 Hz loop, at most five catch-up steps per frame; preserves fractional remainder and records full elapsed, executed ticks, dropped seconds and hitch frames.
- [x] Seed `1729` generates a repeatable 10,000-tick input tape. Every state field matches at every tick under 30/60/144 simulated FPS in each tested runtime. This is same-runtime determinism for the tested tape, not cross-client proof or a gameplay PRNG.
- [x] Mocked UI/Core lifecycle coverage includes hidden/chat/combat/missing-capability Start refusal; key aliases; Escape/unknown/Enter; Stop/Close/Hide/toggle; all mouse clicks; text/application focus; leaving world/logout; combat event and OnUpdate fallback; deferred propagation; no automatic resume; minimal save-field preservation.
- [x] Explicit `/akart probe` / Print Probe reports identity, input capabilities, event-registration failures, clock metrics, last stop reason and explicit UI object counts. No per-tick chat or UI object creation.
- [x] Exact installed-client manual probes and header-only F4 experiment ledger prepared; no network code/traffic or multiplayer claim.

## Pending acceptance / blockers

- [x] Live `GetBuildInfo()` returned `1.60.1 70450 Oct 15 2026 16001`; runtime project ID is `18`; selected TOC metadata is `Camelot`; addon `0.0.1` loads and appears enabled without an out-of-date warning.
- [x] Core client control smoke: Start mouse-down/OnClick ordering, Escape/menu, Close/reopen, Enter/chat, Stop, idle Alt-Tab, map binding, canvas click, UI hide/show and clean inactive reload observed. This does not mark every held-input/overlapping-panel/world-transition case passed; see the checklist's exact scope.
- [x] Owner's real combat smoke: window closed, interruption message appeared, WoW controls worked. Once-only handling and retained results pass offline; exact repeated-notification count, reopen and full taint audit remain live follow-ups. Restricted propagation setters remain guarded; no bypass is used.
- [ ] `IsGameWindowFocused` and `IsWindowFocused` are both absent on build 70450. An idle Alt-Tab trial stayed stopped after >=5 seconds away through the unknown-key path. Held-key release outside the application and other application-switch routes remain unverified; do not mark full F2 passed.
- [ ] Actual rendering, rotation, UI scale, FPS/CPU cost, long-session behavior and memory. Mock counters measure explicit addon allocations only, not client/template internals or real performance.
- [ ] Logout/full restart and isolated sentinel persistence. Clean inactive `/reload` is observed; minimal schema initialization is not proof of a save, migration or settings/ghost support.
- [ ] Direct handling/play evaluation. Analytical metrics are a baseline only; no M1 game-feel acceptance.
- [ ] Two-client transport measurements, reconnect and architecture ADR. No runtime bandwidth, loss, throttle or latency results exist.

Initial file-only evidence: `_classic_beta_\WowB.exe` reports `1.60.1.70450`; `.flavor.info` contains `wow_classic_beta`; the initial scan had no running `Wow*` process. A later actual client session confirmed runtime identity and Camelot selection as above. After the owner instructed proceeding with sections 1–2, this addon was installed for those checks. No prior AzerothKart installation existed; status and all nine hash matches are recorded in workspace `artifacts/AzerothKart/20261018-170909/`. No other addon or SavedVariables files were edited by deployment.

## Next exact task

Run the **M0 timed driving/performance sample in section 3 of `tests/MANUAL_CLIENT_CHECKLIST.md`**: three 60-second out-of-combat drives with stopped probe output and stable explicit UI counts. Keep the unrun lifecycle/persistence cases documented without turning them into passes. The simultaneous W/Up case is skipped at the owner's request because the keyboard cannot hold that pair; it is not a live gate and must not be requested again. Do not automate WoW character movement/combat. Full M0 acceptance remains open.

## Session handoff log

### 2026-10-18 13:18 CEST (Europe/Oslo) — Codex / main

**Milestone:** M0; one local input/timing/lifecycle feasibility slice, plus reproducible probes.

**Files changed:** `addon/AzerothKart/{Track,Physics,Input,Loop,UI,Core}.lua`, both TOCs and addon readme; test runner and seven test files; Python validation/Lua harnesses, pinned test dependency and text attributes; README/CHANGELOG; architecture/API/feasibility/test/roadmap/progress docs; manual client/network checklists and the empty network CSV ledger. Existing roadmap gates remain open except the executed offline-validator criterion.

**Tests actually run and final results:**

| Command/check | Result and scope |
|---|---|
| `python scripts/validate_project.py` | PASS — 25 expected paths, TOC order/discovery markers, protocol docs, local links and ledger structure; no Lua runtime executed by this command |
| `python scripts/test_lua.py` | PASS — Lua 5.1 and 5.4 via Lupa 2.8; 14 files parsed and 7 tests run in each; includes 10k-tick/three-cadence replay and mocked lifecycle tests |
| `python -m compileall -q scripts` | PASS — Python script parsing |
| `git diff --check` / staged equivalent | PASS — whitespace checks after consistent text endings |
| Documentation check by delegated agent | PASS — 27 manual command lines fit 255 characters, local links resolve, CSV has 60 unique header fields and no measurement rows |
| `python scripts/test_with_lua54.py` | Optional Linux shared library unavailable on Windows; runtime execution NOT RUN through this path. Full Lua 5.4 suite executed through Lupa above. |
| Native `lua tests/run.lua` | Native interpreter absent from PATH; standalone CLI NOT RUN. The same entry point was executed in both actual embedded Lua runtimes above. |
| WoW F0/F1/F2/F5 and network F4 | NOT RUN / PENDING — no live client session or peer measurements |

**Measured offline baseline:** physics v2 on an open analytical plane: 50% speed in 39 ticks (0.650 s), top speed in 78 ticks (1.300 s); brake from 200 units/s crosses zero after 47 ticks (0.7833 s), path length 75.322 units including that final step. These are simulation measurements, not client handling ratings. UI test double: 6 UI frames, 99 textures, 3 font strings; counts unchanged through 1,001 updates and reopen cycles; 0 propagation setter calls in mocked combat. Bootstrap frame and template internals excluded.

**Evidence:** ignored `local-artifacts/m0-2026-10-18-validation.txt` and `local-artifacts/m0-2026-10-18-lua.txt`; reproducible tests in the committed source. A new handling assertion initially used exact x equality despite `cos(pi/2)` floating error; it was corrected to a small numeric tolerance, then both complete suites passed. A mixed-line-ending whitespace failure was corrected; final diff checks pass. Initial system runtime/dependency discovery failures did not execute Lua; the pinned local runtime then enabled both suites.

**Limitations:** manual tests and F4 gates remain pending as listed above. Any mouse-down now stops capture because a rectangle hit-test cannot identify an overlapping UI's focus. Actual Start/event ordering and combat release are client acceptance requirements. M0 does not imply production race timing, laps, ghosts, multiplayer or content readiness.

**Next exact task:** installed-client M0 identity and input/combat safety smoke (client checklist sections 1–2), then record observations before selecting another slice.

**Git implementation:** `be33176`; original scaffold `98bd16a`; local only, no force push or release.

### 2026-10-18 17:23 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** proceed with M0 client-checklist sections 1–2 and apply the owner's clarified rule: combat ends the game, closes the window and labels current results interrupted. No broad race/multiplayer engine was added.

**Implementation commit:** `6e20ec0` — `fix: close kart sessions when combat interrupts`.

**Files/behavior:** UI.lua now records one terminal `UI.result` (interrupted status, reason, stopped tick), closes on combat from event/key/OnUpdate paths and emits `Game interrupted by combat` once. OnHide preserves a prior terminal reason; deliberate reopen retains the note, new Start clears it. Actual standings do not exist in M0, so placements are not fabricated; the future final-placement rule is recorded in ADR 0006, DECISIONS/GAME_DESIGN/AGENTS and related scoped docs. Added regression assertions for closure, frozen tick, duplicate notifications, retained reason/reopen, no auto-resume and zero mocked combat propagation calls.

**Deployment:** owner instructed proceeding with live sections 1–2; the tested probe was installed directly into `_classic_beta_/Interface/AddOns/AzerothKart` using the normal filesystem approval mechanism. There was no prior AzerothKart install. All nine source/installed SHA-256 values matched both on install and the later read-only verification. Evidence is in workspace `artifacts/AzerothKart/20261018-170909/`; no other addon or SavedVariables file was edited by deployment. No push, tag, release or network traffic.

**Actually executed:**

- `python scripts/validate_project.py`: PASS, 25 expected paths plus TOC/docs links/ledger.
- `python scripts/test_lua.py`: PASS, 14 parsed Lua files and seven executed tests in each of Lua 5.1/5.4 (Lupa 2.8), including the new terminal-combat regressions.
- `git diff --check` and staged equivalent: PASS.
- Read-only installed/source SHA-256 verification: PASS, nine files.
- Actual Forever UI/commands through the [computer-use skill](C:/Users/bakke/.codex/plugins/cache/openai-bundled/computer-use/26.1013.40934/skills/computer-use/SKILL.md): successful addon startup/metadata, basic rendering/Start, idle Escape/Close/reopen/Enter-chat/Stop/Alt-Tab checks. Detailed sanitized output: [live evidence](evidence/2026-10-18-m0-client.md). Personal screenshots/chat were not committed or published.
- Human actual-combat test: owner reported, "Window closed on combat and game interrupted by combat appears. wow controls work." Record as a user-observed combat smoke, not an independently instrumented taint or duplicate-message audit.

**Client findings:** `GetBuildInfo()` = `1.60.1 70450 Oct 15 2026 16001`; project ID 18; Camelot TOC; addon version 0.0.1; enabled without an out-of-date notice. Required keyboard/text-focus/combat APIs and registered events available. IsGameWindowFocused and IsWindowFocused are nil. Existing unknown-key handling stopped an idle Alt-Tab trial after >=5 seconds away; no guessed focus getter was substituted. Local build-matching UI/API source was inspected read-only to confirm no known public application-focus getter/event; it was not copied into this repository or addon.

**Metrics/scope:** short stopped-run live sample: frames=1871, ticks=534, maxElapsed=0.0310, droppedSeconds=0, hitchFrames=0, explicit UI counts 6/99/3. One closed-window whole-client FPS sample was 207.6124420166 at uiScale=1/useUiScale=0. These are not sustained driving, addon CPU, scaling or long-session performance passes. HUD throttling left 528 visible when stopped probe/state had 534; this small display lag is recorded as a known M0 observation. A single synthetic key tap gave no clearly measurable movement, so the agent did not mark held driving/handling passed.

**Pending/coordination:** the agent stopped UI input for the owner's manual test. Real combat closure/message/working controls are confirmed by the owner's direct report. The owner then instructed skipping simultaneous W/Up because the keyboard cannot hold that pair; record SKIPPED, not pass/fail, with offline coverage retained. No further special combinations were requested. Repeat-notification count, combat reopen/retention, explicit in-combat Start refusal and full taint auditing are not inferred from the brief report. The subsequent ordinary checks below cover more UI/lifecycle behavior; unrun cases remain distinguished.

**Next exact task:** the M0 timed driving/performance sample in client-checklist section 3, before selecting an M1 slice.

### 2026-10-18 17:33 CEST — completion of this client-check run

After the owner's test reply, the agent performed ordinary M/map-key release, canvas-click release, Alt-Z hide/show and `/reload`. The map opened on the first M while capture stopped; canvas click stopped; UI hide/show did not resume racing. Reload completed with the kart window hidden. A local `/akart probe` then reported frames=0/ticks=0, active=false, stopReason=Not started, UI counts 6/99/3, no event-registration failures and input APIs available. Chat accepted and executed the local probe after reload. No character movement/combat or third-party chat was automated.

Updated README, client checklist, API/feasibility ledgers, architecture and [actual-client evidence](evidence/2026-10-18-m0-client.md) distinguish observed core startup/control/combat/reload smoke from remaining unrun cases. Simultaneous aliases are skipped by owner instruction, not a blocker. Actual logout/login/world transition and persistence sentinel work were not performed; no claim of full M0 completion. The existing combat implementation remained unchanged during live checks and still matches all nine installed files by SHA-256.

Final structural/doc-link/ledger and whitespace checks passed. Lua code has not changed since the complete Lua 5.1/5.4 suite passed and implementation commit `6e20ec0`. The session leaves the live kart window hidden and capture inactive. No push or release.
