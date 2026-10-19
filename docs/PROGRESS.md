# PROGRESS — persistent project handoff

**Current milestone:** M0 — repository and actual-client/API feasibility. **OPEN.**
**Current state (2026-10-19, latest session ~07:35 CEST):** completed the bounded opt-in M0 update/render timing probe. `/akart perf on` arms up to 600 active updates on the next Start; `/akart perf` prints scoped elapsed-ms aggregates; `/akart perf off` disarms. Default off, no extra UI objects/periodic output; invalid/erroring readings consume the cap without changing driving. Eight tests pass in each actual embedded Lua 5.1/5.4 runtime; 16 files parsed and counts remain 6/99/3. Installed five changed/new addon files with verified backup/ten source hashes. **Client load, new renderer appearance and actual performance readings NOT RUN** — desktop inventory at 07:32 returned no WoW client. No new combat/drive test requested; owner-deferred checks remain pending and M0 stays open.

## Canonical checkout and commits

Work in this directory: `C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart`.
Remote: `https://github.com/PhilForever/AzerothKart.git`; branch `main`. The pack originally had no `.git` history; remote inspection returned no refs. The original pack was preserved before changes.

- `98bd16a` — `chore: preserve initial Azeroth Kart M0 project pack`.
- `be33176` — `fix: harden M0 driving probe and feasibility checks`.
- `c2ecadf` — `docs: record M0 validation evidence and client handoff` (initial offline session).
- `6e20ec0` — `fix: close kart sessions when combat interrupts`.
- `3b02641` — `docs: record live M0 checks and owner combat results`.
- `2825ba3` — `fix: preserve complete M0 timing samples`.
- `fc7f339` — `fix: verify and back up repeatable local installs`.
- `2a5b8e8` — `fix: retain combat outcome through rejected restarts`.
- `364a245` — `docs: record updated M0 install and live baseline`.
- `ae6fed0` — `fix: close stopped kart windows when combat begins`.
- `865e187` — `fix: align primitive road with analytical track bounds`.

Repository-local identity is `PhilForever <philfluenser@gmail.com>` with `user.useConfigOnly=true`; verified in config and commit authors. Global identity was left unchanged. No push, tag, distribution or automation was performed. The later client-check session installed only AzerothKart in the local Forever AddOns folder and verified all nine files against source SHA-256. Ignored `local-artifacts/` contains developer dependencies/logs and synthetic install fixtures/backups; it is not staged.

## Completed and evidenced

- [x] Inspected all original source, tests/scripts and documents from `docs/INDEX.md`, including ADRs; preserved initial content in Git.
- [x] Structural validation of paths, synchronized TOC source order, discovery markers, local Markdown links and network-ledger fields.
- [x] All seven addon modules and nine Lua test/runner files parsed under both Lua 5.1 and Lua 5.4; eight tests executed in each runtime.
- [x] Removed `_G` dependency from pure Track/Physics modules; introduced pure Input and Loop modules with explicit addon namespace registration/returned offline imports.
- [x] Corrected inverted left/right steering; physics compatibility version is 2. This is still the analytical M0 handling probe, with no drift or production collision/race engine.
- [x] Physical-key alias tracking prevents W/Up and equivalent steering/brake releases from canceling another held alias. Sampling reuses a semantic input table; stop clears held/sampled controls in place.
- [x] Fixed 60 Hz loop, at most five catch-up steps per frame; preserves fractional remainder and records full elapsed, executed ticks, dropped seconds and hitch frames.
- [x] Seed `1729` generates a repeatable 10,000-tick input tape. Every state field matches at every tick under 30/60/144 simulated FPS in each tested runtime. This is same-runtime determinism for the tested tape, not cross-client proof or a gameplay PRNG.
- [x] Mocked UI/Core lifecycle coverage includes hidden/chat/combat/missing-capability Start refusal; key aliases; Escape/unknown/Enter; Stop/Close/Hide/toggle; all mouse clicks; text/application focus; leaving world/logout; combat event and OnUpdate fallback; deferred propagation; no automatic resume; minimal save-field preservation.
- [x] Explicit `/akart probe` / Print Probe reports identity, input capabilities, event-registration failures, clock metrics, last stop reason and explicit UI object counts. No per-tick chat or UI object creation.
- [x] Source timing aid: cumulative valid active frame seconds, executed simulation seconds and callback cadence; complete stopped elapsed/drop/remainder accounting and immediate Start/Stop HUD refresh. Offline tested and installed; zeroed live baseline observed, with timed/final-sample acceptance pending.
- [x] 2026-10-19 installation/reload baseline: prior addon backed up, two changed files copied and all nine installed SHA-256 values verified twice; updated zeroed timing/HUD fields rendered inactive. Timed drive/final-sample acceptance remains pending.
- [x] Two human drives: ticks 3492/3756, active seconds 58.2120/62.6020, no dropped time, matching HUD and explicit counts 6/99/3. Delayed probes remained frozen; sample 1 also retained numbers across slash close/reopen. Third sample/external durations/full F1 remain pending.
- [x] Primitive road now follows unchanged analytical Track outer/inner bounds using the same 96 road textures. Dense actual-rectangle regression covers 92,853 points outside a 3.5-unit vertical edge margin and the old mismatch at `(400,440)`; allocation/replay tests pass. Installed with verified backup/hashes; reload/live appearance pending.
- [x] Optional bounded profiler: pure Performance scalar aggregates, UI timer adapter and reachable slash commands, 600-attempt cap including read/validation failures, default-off zero reads, frozen/fresh windows and identical profiled/unprofiled 650-update state. Full Lua suites pass and source is installed; actual client costs are NOT RUN.
- [x] Stopped-window combat source gap reproduced and fixed: combat-start event hides inactive window while preserving its sample/result/reason, without another interruption announcement. New never-started/stopped/interrupted fixtures pass Lua 5.1/5.4. Disk install verified; reload/live fix verification NOT RUN.
- [x] Retained interruption note through repeated Close/toggle/reopen, inactive Stop and rejected Start; actual refusal text is also visible. Regression checks retain the same result/state/clock/HUD and clear the note only on a successful fresh Start. Offline only; extended client sequence pending.
- [x] Local installer fixture slice: direct per-file repeat copies, verified old-file backup before target writes, copied SHA-256 verification, explicit overwrite/preview and failure records. PowerShell 7: 18 cases passed, 3 junction fixtures skipped; PowerShell 5.1 syntax passed, runtime blocked. No live install performed.
- [x] Exact installed-client manual probes and header-only F4 experiment ledger prepared; no network code/traffic or multiplayer claim.

## Pending acceptance / blockers

- [x] Live `GetBuildInfo()` returned `1.60.1 70450 Oct 15 2026 16001`; runtime project ID is `18`; selected TOC metadata is `Camelot`; addon `0.0.1` loads and appears enabled without an out-of-date warning.
- [x] Core client control smoke: Start mouse-down/OnClick ordering, Escape/menu, Close/reopen, Enter/chat, Stop, idle Alt-Tab, map binding, canvas click, UI hide/show and clean inactive reload observed. This does not mark every held-input/overlapping-panel/world-transition case passed; see the checklist's exact scope.
- [x] Owner's real combat smoke: window closed, interruption message appeared, WoW controls worked. Once-only handling and retained results pass offline; exact repeated-notification count, reopen and full taint audit remain live follow-ups. Restricted propagation setters remain guarded; no bypass is used.
- [ ] `IsGameWindowFocused` and `IsWindowFocused` are both absent on build 70450. An idle Alt-Tab trial stayed stopped after >=5 seconds away through the unknown-key path. Held-key release outside the application and other application-switch routes remain unverified; do not mark full F2 passed.
- [ ] Remaining UI-scale/layout, sustained FPS/CPU cost, long-session behavior and memory. Basic kart movement/rotation is observed; mock/live counters measure explicit addon allocations only, not client/template internals or whole-client performance.
- [ ] Optional profiler runtime availability/load and real scoped elapsed-ms samples. Local build-70450 API contract is verified; desktop inventory at 07:32 returned no WoW client. Synthetic timing tests are not measured CPU/GPU cost.
- [ ] Stopped-window combat-close live follow-up after reload: source fixed/offline tested, live check deferred at owner direction to continue elsewhere. Do not ask for another combat test as the next development task. Prior observations remain scoped in the evidence; no API contradiction is established.
- [ ] Analytical-band renderer actual appearance/scaling after reload. Latest source installed, but the attempted local reload was not sent because the helper detected user input. Earlier drive samples used the old road renderer and do not establish this appearance check.
- [ ] Logout/full restart and isolated sentinel persistence. Clean inactive `/reload` is observed; minimal schema initialization is not proof of a save, migration or settings/ghost support.
- [ ] Direct handling/play evaluation. Analytical metrics are a baseline only; no M1 game-feel acceptance.
- [ ] Two-client transport measurements, reconnect and architecture ADR. No runtime bandwidth, loss, throttle or latency results exist.

Initial file-only evidence: `_classic_beta_\WowB.exe` reports `1.60.1.70450`; `.flavor.info` contains `wow_classic_beta`; the initial scan had no running `Wow*` process. A later actual client session confirmed runtime identity and Camelot selection as above. After the owner instructed proceeding with sections 1–2, this addon was installed for those checks. No prior AzerothKart installation existed; status and all nine hash matches are recorded in workspace `artifacts/AzerothKart/20261018-170909/`. No other addon or SavedVariables files were edited by deployment.

## Next exact task

**Next exact task: verify M0 startup and one optional performance window when the client is available.** Check desktop inventory first, load the installed source normally and confirm the analytical-band road/marker/kart and both ordinary/performance reports. While stopped, `/akart perf on`; deliberately Start for a short idle or human-driven diagnostic window, stop normally, then `/akart perf` and `/akart probe`. Record actual conditions/counters/scoped elapsed values, frozen delayed output and `/akart perf off`; a short idle sample is not human handling or sustained-performance acceptance. Exact steps are in client-checklist section 3a. If no actual client is returned, keep live checks NOT RUN and do not fabricate results or repeat the owner's deferred combat/skipped W+Up tests. M0 remains open.

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

### 2026-10-19 01:28 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, one timing-evidence slice while the actual-client driving gate is unavailable. Confirmed canonical remote `https://github.com/PhilForever/AzerothKart.git`, branch `main`, clean initial status and prior head `3b02641`. Read canonical docs/ADRs and existing source/tests/scripts. No `Wow*`/`Battle*` process was found; no client was launched or controlled.

**Changes:** `Loop.lua` accumulates valid delivered elapsed in `elapsedSeconds`. The explicit six-line probe adds `activeFrameSeconds`, `simulatedSeconds=steps*dt` and `callbackHz=frames/elapsedSeconds` (zero before elapsed). `UI.Stop` freezes the clock including its fractional remainder; fresh Start creates a new clock. Thus stopped samples retain `elapsedSeconds ≈ steps*dt + droppedSeconds + accumulator`. Start/Stop immediately refresh the existing HUD, addressing the prior visible 528/probe 534 discrepancy. During driving the HUD remains bounded at quarter-second simulation intervals. No new frames/textures/font strings, automatic driving or periodic chat reports were added.

**Documentation:** architecture/API/feasibility/testing docs and client-checklist section 3 now define exact duration/cadence semantics and three independent-timer samples, immediate stopped tick agreement, unchanged delayed/reopened probes and fresh Start reset. Corrected stale feasibility prose that still requested the owner's skipped simultaneous W/Up case. README/CHANGELOG distinguish the source update from the historical installed probe. Roadmap acceptance boxes remain unchanged.

**Actually executed:**

| Command/check | Result and scope |
|---|---|
| `python scripts/test_lua.py` | PASS — Lua 5.1 and 5.4 through pinned local Lupa; 14 files parsed and all seven tests executed in each runtime. Synthetic 60-second schedules at 30/60/144 Hz each execute exactly 3,600 ticks with complete elapsed/drop/residual accounting. |
| New mocked timing/HUD assertions in `tests/test_ui.lua` | PASS within both complete suites — zero metrics before Start; immediate fresh/final HUD; frozen stopped/reopened clock and probe; retained fractional remainder; fresh clock replacement; five-step hitch bound; no periodic chat. Existing allocation regression remains 6 UI frames / 99 textures / 3 font strings across 1,001 updates and reopen cycles. |
| `python scripts/validate_project.py` | PASS — 25 expected paths, synchronized TOCs, protocol docs, local links and header-only network ledger. |
| `git diff --check` | PASS — whitespace check. |
| Read-only delegated timing/code review | No blocking findings; preserved accumulator cannot advance while inactive and is replaced on Start. |
| `Get-Command lua,luajit,luac -ErrorAction SilentlyContinue` | No native executable found; standalone `lua tests/run.lua` NOT RUN. Both actual embedded Lua runtimes above executed the same entry point. |
| WoW F1/F2/F5 and network F4 | NOT RUN — no client process or peer experiment. New timing/HUD layout, three timed drives, scaling/stress, held-input/lifecycle edge cases and persistence remain pending. |

The first integration run exposed a test-double instrumentation error: its fallback returns a function for unknown fields, so the new HUD-write counter needed `rawget`. Corrected that fixture counter; both full runtime suites then passed. No production change was required for that failure.

**Risks/limits:** cumulative delivered callback time and callback cadence are not an independent wall clock, separately sampled whole-client FPS or addon CPU cost. Simulation time excludes dropped time. No handling/performance rating is inferred from synthetic schedules. The prior 2026-10-18 installation remains unchanged and does not contain these source changes. No migration, transport, race/standings, content or deployment work occurred. No API contradiction or new product decision arose.

**Git:** focused commit intended as `fix: preserve complete M0 timing samples`; see `git log` for its hash. Repository-local PhilForever identity was reverified. No push, tag, release, deployment or automation was performed.

**Next exact task:** harden the local install helper against nested repeat copies with backup/hash verification and workspace fixture tests; preserve the manual M0 gate above.

### 2026-10-19 02:06 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, complete the prior handoff's repeatable developer-install task using workspace fixtures only. Confirmed correct remote, branch `main`, clean initial status and prior head `2825ba3`. Read the current canonical handoff, acceptance criteria, architecture/ADRs and relevant source/tooling. No `Wow*`/`Battle*` process was found; no client was launched or controlled.

**Changes:** rewrote `scripts/install_local.ps1` as an explicit AddOns-target installer with `-Overwrite` for existing targets and standard `-WhatIf`/`-Confirm`. It copies source files directly into the addon folder, preserves unknown extras and verifies source/installed SHA-256 values. Existing addon files and empty directories are copied into an isolated backup and verified before target writes. Ignored run directories contain `source.csv`, optional `before.csv`/`before/` and `install.json`; status, stage, backup verification and copy-start markers distinguish successful verification from failure. Missing/overlapping/conflicting paths and observed reparse entries are rejected; source/target snapshots are rechecked before copying. A target appearing after fresh-install preflight is rejected rather than overwritten without a backup.

The helper performs no deletion or automatic rollback. A failure after copying starts can leave a partial target, so its error points to the retained backup and manifest. Added `tests/test_install_local.ps1` with literal-path and isolated AddOns/WTF sentinel fixtures, preflight/preview refusal, repeated installs, empty prior target, preserved extras, locked-file failures, injected backup/target hash failures, concurrent-target refusal, and a manual recovery rehearsal that preserves the failed target and verifies restored old files while acknowledging new files left behind. No real WTF or installed addon files were touched. Updated README/CHANGELOG, release/test documentation and structural validation (now 27 required paths). No roadmap boxes changed.

**Actually executed:**

| Command/check | Actual result and scope |
|---|---|
| `pwsh -NoProfile -NonInteractive -File tests/test_install_local.ps1` | PASS — PowerShell 7.6.5, 18 cases; 3 junction fixtures SKIPPED because `New-Item -ItemType Junction` returned Access denied in the sandbox. No junction rejection pass is claimed. |
| `powershell.exe -NoProfile -NonInteractive -File tests/test_install_local.ps1` | Runtime NOT RUN — Windows PowerShell returned `AuthorizationManager check failed` before the suite executed. No execution-policy change or bypass was attempted. |
| Windows PowerShell `Parser.ParseFile` on helper and fixture suite | PASS — both scripts parsed in 5.1.26100.9711. This is syntax evidence, not a 5.1 runtime pass. Read-only `Get-ExecutionPolicy -List` also reported registry access denied, so the effective policy was not established. |
| `python scripts/test_lua.py` | PASS — 14 Lua files parsed, all seven tests executed in each of Lua 5.1/5.4 through local Lupa. No addon Lua changed in this slice. Standalone native `lua` was absent; native CLI NOT RUN. |
| `python scripts/validate_project.py` | PASS — 27 expected paths, TOCs, protocol docs, Markdown links and network ledger. |
| `python -m compileall -q scripts` | PASS — Python script parsing. |
| `git diff --check` | PASS — whitespace checks. |
| WoW F1/F2/F5, live installation and network F4 | NOT RUN — no client process, no installation or peer experiment. Historical client results are unchanged. |

**Evidence:** ignored `local-artifacts/install-tests-ps7-20261019.log` and `install-tests-ps51-20261019.log`. Final successful fixture root: `local-artifacts/install-tests/c0c483a78c6746439aa7ed5f7ba3475f/`. Synthetic prior/failed installs and manifests are retained there for inspection. Early runs exercised smaller subsets before the final 18-case run; they do not substitute for the explicit skipped/runtime limits above.

**Risks/limits:** file overlay with verified backup, not an atomic deployment or concurrency/security guarantee. Unknown extra files are retained; restoring old files does not remove newly added files. Stop other editors/installers during a real operation. Junction rejection remains unexecuted in this sandbox, PowerShell 5.1 runtime acceptance remains pending, and client behavior still requires direct play. No API contradiction, migration or product decision arose. Source timing/HUD changes are still not installed.

**Git:** focused commit intended as `fix: verify and back up repeatable local installs`; inspect `git log` for its hash. PhilForever repository-local identity reverified; global config unchanged. No push, tag, release, actual deployment or automation.

**Next exact task:** the M0 F1 actual-client timing sample described above: three human-controlled 60-second drives after an authorized source install, with honest pending status while no client/tester is available.

### 2026-10-19 02:11 CEST (Europe/Oslo) — Codex / main

**Milestone/objective:** M0, one existing lifecycle defect while the actual-client timing gate is unavailable. Confirmed canonical remote, branch `main`, clean initial status and prior head `fc7f339`; read current handoff, acceptance criteria, architecture/ADRs and relevant source/tests. No `Wow*`/`Battle*` process was found. No client was launched or controlled.

**Reproduction:** after a mocked combat interruption, the first reopen retained the note, but a second toggle close or Close button called `UI.Stop("Closed")`, replacing the visible reason while leaving `UI.result` intact. Start refusal for combat, text focus or missing input capability likewise replaced the note. This contradicted the already accepted ADR 0006 retention rule; no new product decision or API behavior was needed.

**Changes:** `UI.Stop` keeps an interrupted result's reason authoritative. A small Start-refusal formatter displays the retained note plus the actual refusal. Existing guards, controls, terminal result and fixed-step simulation are unchanged; only a fresh accepted Start clears the result/note. `tests/test_ui.lua` now exercises repeated toggles/Close, hidden/inactive stops, combat/text/event/API refusals, frozen result identity/tick/state/clock/HUD, stable object counts, one unsolicited interruption message, no automatic resume, and a fresh Start followed by ordinary Stop/Close with no stale note. Updated architecture/feasibility/test docs, README/CHANGELOG and a precise pending manual follow-up. No new module, UI objects, race placements, transport or migration.

**Actually executed:**

| Command/check | Actual result and scope |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before the UI fix | Expected FAIL — added regression reproduced `toggle close 1: interruption stays visible and authoritative` in `test_ui.lua`; other six tests passed. |
| `python scripts/test_lua.py` after the fix | PASS — all 14 Lua files parsed and all seven tests executed in each of Lua 5.1/5.4 through Lupa, including the retained-note regressions and existing 10k-tick replay/timing tests. Mock UI allocation counts remain 6 frames / 99 textures / 3 font strings; no mocked propagation setter in combat. |
| `python scripts/validate_project.py` | PASS — 27 expected paths, TOCs, protocol docs, Markdown links and header-only network ledger. |
| `git diff --check` | PASS — whitespace checks. |
| Native `lua tests/run.lua` | NOT RUN — no `lua`, `luajit` or `luac` executable found. The actual embedded Lua runtimes above executed the same suite. |
| Actual-client F1/F2/F5 and network F4 | NOT RUN — no client process or peer measurement. Historical owner combat smoke remains observed; repeated-note/rejected-restart client behavior is not inferred from mocks. |

**Limits:** all 2026-10-19 source changes remain uninstalled; the existing 2026-10-18 addon install is untouched. The longer refusal-plus-note layout still needs client observation. No fresh PowerShell installer runtime claim is made in this Lua-only slice; the preceding session's 18-pass/3-skipped PowerShell 7 evidence and blocked PowerShell 5.1 runtime remain scoped to that tooling task. Roadmap acceptance boxes are unchanged.

**Git:** focused commit intended as `fix: retain combat outcome through rejected restarts`; inspect `git log` for its hash. PhilForever repository-local identity reverified; no global config change, push, tag, release, deployment or automation.

**Next exact task:** M0 F1, three human-controlled 60-second client samples after an authorized source install. The precise retained-note close/reopen/refused-Start follow-up is also prepared in client-checklist section 2 and remains pending. Do not request the owner's skipped simultaneous W/Up combination.

### 2026-10-19 02:26 CEST (Europe/Oslo) — Codex / main, live continuation

**Objective:** continue the existing M0 client gate after the owner reported WoW running. Confirmed clean `main`, canonical remote and HEAD `2a5b8e8`; read the handoff/acceptance criteria and [computer-use skill](C:/Users/bakke/.codex/plugins/cache/openai-bundled/computer-use/26.1013.40934/skills/computer-use/SKILL.md). The shell process scan again returned no matches, but the desktop inventory returned one running `WowB.exe` client window. Activated that returned window and observed the logged-in client. Added the discovery limitation to AGENTS so future runs do not declare the desktop unavailable from an empty shell scan alone.

**Deployment:** validated source first. Only installed `Loop.lua`/`UI.lua` differed; the other seven files matched. The PowerShell helper `-WhatIf` could not load because the script was unsigned. No execution-policy change was made and that script was not executed. Using the normal filesystem approval mechanism, a one-off Python file operation backed up the full prior AzerothKart tree, verified the backup, copied only those two files, then verified all nine installed hashes against source. Artifact: workspace `artifacts/AzerothKart/20261019-022106-763673/install.json`, with source/before/installed hash maps and prior files under `before/`. Independent read-only verification at 02:24:17 +02:00 confirmed nine matches. No other addon or WTF/SavedVariables files were edited for deployment.

**Actually observed:** normal local `/reload` completed; `/akart` opened the primitive track/kart inactive with `Sample: 0.0s`. A grouped read-only `/run` baseline plus explicit `UI.ReportProbe()` showed client `1.60.1`, build `70450`, interface `16001`, selected TOC `Camelot`, focus API false, all timing counters zero, active false/Not started, UI counts 6/99/3, no event-registration failures and required input capability flags true. One whole-client FPS sample with the stopped kart window open was `230.10543823242`; uiScale=1/useUiScale=0, combat=false, capture resolution 1920×1080. This is not CPU profiling, sustained driving or full F1/F2 acceptance. No AzerothKart error popup was visible; a full taint audit was not run. Sanitized evidence is in [2026-10-19 client observations](evidence/2026-10-19-m0-client.md); no personal captures/chat were committed.

**Executed checks:**

| Command/check | Actual result |
|---|---|
| `python scripts/validate_project.py` | PASS — 27 expected paths/TOCs/docs links/ledger; rerun after evidence/doc updates. |
| `python scripts/test_lua.py` | PASS — 14 Lua files parsed, all seven tests in each of Lua 5.1/5.4 via Lupa. No addon source changed during the live run. |
| Backup/source/installed SHA-256 checks | PASS — verified old addon backup and nine installed matches, followed by an independent nine-file comparison. |
| PowerShell installer preview | NOT RUN — unsigned-script SecurityError prevented loading; no policy change. This is distinct from the prior fixture results. |
| Normal client reload and stopped new-HUD/probe baseline | OBSERVED — precise scope above; no new gameplay/performance pass. |
| Three human-controlled timed drives; extended combat-note sequence; scaling/stress; F5 sentinel/logout/restart; F4 peer tests | PENDING / NOT RUN — no completed result recorded. |
| `git diff --check` | PASS — final whitespace check. |

**Handoff:** asked the owner to perform the first normal 60-second kart drive and report completion/responsiveness. Keyboard/mouse input remains untouched while waiting. Blank drive rows in the evidence ledger mean unmeasured. Do not infer results, repeat the skipped W/Up combination, synthesize combat, or automate character movement. No gameplay milestone/roadmap checkbox advanced. No push, tag, release, network traffic or automation.

**Git:** focused documentation/evidence commit intended as `docs: record updated M0 install and live baseline`; inspect `git log` for its hash. The installed addon source remains the tested files from `2a5b8e8`.

**Next exact task:** capture the owner's first stopped timed-drive probe, then complete samples 2 and 3 before choosing further M0 work.

### 2026-10-19 02:35 CEST (Europe/Oslo) — Codex / main, first human drive

**Objective:** capture the owner's `Done` reply to the first requested near-minute kart drive. Confirmed clean `main`, prior HEAD `364a245`, read current handoff/checklist, selected the unique returned WoW desktop window and activated it. No installed/source code changed, no reload or new deployment.

**Observed sample 1:** owner-confirmed completion, with no separately reported handling rating or external timer. Stopped probe: frames=13171, ticks=3492, maxElapsed=0.0700, droppedSeconds=0.0000, hitchFrames=0, accumulator=0.01200, activeFrameSeconds=58.2120, simulatedSeconds=58.2000, callbackHz=226.26; UI=6 frames/99 textures/3 font strings; active=false, stopReason=Mouse click released controls, event failures=none. Build 70450/interface16001/Camelot and capability flags unchanged. Kart displacement/rotation from spawn was visible; stopped HUD tick matched 3492. Actual stop reason is mouse-click release; held Escape is not inferred from the brief reply.

**Delayed lifecycle check:** ordinary `/akart` closed the window, which was visibly hidden; a second `/akart` reopened it inactive. A subsequent `/akart probe` retained all numeric fields and the same HUD tick without auto-resume. Only the ordinary stop reason changed to `Closed`. Local chat commands worked; no WoW character movement/combat was automated. Personal screenshots/chat were not committed.

**Evidence/checks:**

- Python arithmetic on printed values: PASS — `3492 / 60 = 58.2000`; `58.2000 + 0.01200 = 58.2120`; `13171 / 58.2120` rounds to `226.26`. This verifies printed internal accounting, not independent wall-clock accuracy or addon CPU cost.
- `python scripts/validate_project.py`: PASS — 27 expected paths, TOCs, links and ledger.
- `python scripts/test_lua.py`: PASS — actual embedded Lua 5.1/5.4, all 14 Lua files parsed and seven tests each; no Lua source changes this session.
- `git diff --check`: PASS — whitespace.
- Sample 2/3, external timer/handling rating, scaling/stress, extended combat-note/remaining F2 routes, F5 persistence and F4 networking: PENDING / NOT RUN; not established by one drive.

Updated the sanitized [evidence ledger](evidence/2026-10-19-m0-client.md), F1 notes and manual checklist. Checked only the roadmap's basic render-and-drive criterion, supported by the owner's completion and actual moved/rotated kart with advancing ticks. Frame-performance/focus/full M0 gates remain unchecked.

**Known visual follow-up:** the stopped kart was beyond the gray primitive road. Existing source confirms the painted tile oval and analytical drivable annulus differ: for example `(400,440)` is drivable while the gray tiles reach at most y=425. Keep visual/collision alignment as a prototype follow-up; no road/grass handling acceptance is claimed. Do not change the installed probe between the remaining measurement samples.

**Handoff:** second near-minute drive requested, UI input left untouched. Source remained `2a5b8e8` at this point; no tag, push, release, deployment or network traffic. These first-sample documentation edits were still uncommitted when the second reply arrived; they are preserved in the focused follow-up below.

**Next exact task:** capture sample 2's stopped probe, then request/capture sample 3 and update the F1 evidence before choosing further work.

### 2026-10-19 02:43 CEST (Europe/Oslo) — Codex / main, second drive and stopped-window combat fix

**Objective/state:** owner replied `Done.` to sample 2. Confirmed canonical `main`, HEAD `364a245`, and five existing first-sample documentation edits; preserved them. Selected the unique returned WoW window through the computer-use skill. Sample 2 showed a displaced/rotated kart and stopped HUD speed 179, tick 3756, Sample 62.6 s. Probe: frames=14326, ticks=3756, maxElapsed=0.0700, droppedSeconds=0.0000, hitchFrames=0, accumulator=0.00200, activeFrameSeconds=62.6020, simulatedSeconds=62.6000, callbackHz=228.84, UI counts=6/99/3, active=false, stopReason=Mouse click released controls; identity/capabilities unchanged. A delayed local `/akart probe` retained the same numbers/reason. External duration and handling feedback were unreported.

**Unplanned live failure:** during this stopped readback the character was attacked and died while the window stayed visible. No character movement/combat or death-dialog action was automated. The event was not instrumented, so do not declare an API contradiction or claim the active-drive path failed. Source inspection found `HandleEvent` discarded combat-start events whenever inactive, and `InterruptCombat` returned before hiding an inactive window. Stopped-window closure is a real missing path consistent with the observation. Further driving is on hold for user review/live verification; no third drive was requested.

**Plan/change:** preserve both measured samples, reproduce the inactive closure failure offline, then repair that path without changing physics or timing. Handle combat-start events before the active guard; inactive interruption hides an existing shown window, preserving the completed sample/result/HUD/reason and printing nothing. Existing active-drive terminal result/once-only note remains unchanged. Inactive OnUpdate remains idle so deliberate combat-time reopen can inspect the note and Start refusal. Added regressions for pre-load/nil window, never-started/stopped/interrupted UI, duplicate event/direct calls, every clock/state field, UI counts, guarded propagation, no duplicate output and no reopen/resume. Architecture/checklist/feasibility/evidence/README/changelog aligned. Only the basic render-and-drive roadmap box advances; M0 remains open.

**Actually executed:**

| Command/check | Actual result |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before production fix | Expected FAIL — `never started: combat hides stopped window`; new regression reproduced the gap. Other six tests passed. |
| `python scripts/test_lua.py` after fix | PASS — 14 Lua files parsed, seven tests each in actual embedded Lua 5.1/5.4; seeded 10k-tick replay/timing/active combat plus new inactive fixtures. Counts 6/99/3; zero mocked propagation setters in combat. |
| Python arithmetic on both printed samples | PASS — sample 2: `3756/60=62.6000`; `62.6000+0.00200=62.6020`; `14326/62.6020` rounds to `228.84`. Sample 1 accounting also rechecked. Not independent timing/CPU evidence. |
| `python scripts/validate_project.py` / `git diff --check` | PASS — final structural/docs/ledger and whitespace checks. |
| Read-only delegated code/test/evidence review | No blocking findings; narrow stopped-result preservation and pending live scope verified. |
| Backup/install SHA-256 verification | PASS — prior entire AzerothKart backed up/verified; only UI.lua copied, all nine installed files matched tested source. An independent read-only nine-file hash comparison also passed at 02:42 CEST. Manifest below. |
| Native `lua tests/run.lua` | NOT RUN — no standalone runtime available; actual embedded runtimes above executed the suite. |
| Reload/live verification of this fix; sample 3; held-input/extended combat/scale/stress/F5/F4 | NOT RUN / PENDING. Running client still has previous in-memory code. |

**Deployment:** normal filesystem approval granted. Reused the inspected one-off verified Python file copier because the PowerShell helper's historical unsigned-script block remains; no policy/security change. Artifact: workspace `artifacts/AzerothKart/20261019-024015-566233/install.json`, verified prior files in `before/`. No other addon or WTF/SavedVariables edited. No reload after fix; client input left untouched for owner recovery. The timing/physics code was not changed, so both old-source samples remain valid with their recorded version context.

**Git/handoff:** PhilForever repository-local identity reverified; focused commit intended as `fix: close stopped kart windows when combat begins` (inspect `git log` for hash). Includes the preserved first-sample evidence edits. No push, tag, release, network traffic or automation. Next exact task is the reload/stopped-window combat check above before sample 3; visual/collision alignment remains a separate M0 prototype follow-up.

### 2026-10-19 02:51 CEST (Europe/Oslo) — Codex / main, primitive road alignment

**Owner steering/objective:** owner said to continue elsewhere instead of focusing on combat/dying. Confirmed canonical remote, clean `main`, HEAD `ae6fed0`; read handoff/acceptance/docs and existing source. Selected one independent M0 fix: the visible centerline-tile road did not match the analytical drivable annulus. Prior client checks remain unrun and are not falsified or discarded. No further drive/combat test requested.

**Plan/change:** retain physics and the object budget, replace the static road drawing with bands derived from Track radii, compare actual generated rectangles with collision geometry, then install tested source and document actual scope. UI.lua fills 64 outer gray ellipse bands (BACKGROUND), masks the island with 32 grass bands (BORDER), and keeps marker/kart in ARTWORK/OVERLAY. Total remains 6 frames/99 textures/3 font strings. Geometry is built once during Create; moving updates do not recreate it. The vertical raster uncertainty is at most 3.40625 world units outside and 2.625 inside, not an exact vector boundary or horizontal-error guarantee. Track/Physics/Input/Loop/Core and TOCs are unchanged.

**Tests/evidence:**

| Command/check | Actual result |
|---|---|
| `python scripts/test_lua.py --runtime lua51` before renderer fix | Expected FAIL — new test reproduced `road uses 64 outer bands and 32 island bands`; other six tests passed. |
| `python scripts/test_lua.py` after fix | PASS — 14 Lua files parsed, seven tests in each embedded Lua 5.1/5.4. Actual mock rectangles agree with `Track.isDrivable` at 92,853 grid points outside a 3.5-unit vertical boundary margin; `(400,440)` is painted road. Existing 10k-tick replay, timing, lifecycle and 1,001-update/reopen allocation checks pass. |
| `python scripts/validate_project.py` | PASS — 27 paths, synchronized TOCs, docs links/protocol and header-only transport ledger. |
| `git diff --check` / staged equivalent | PASS — whitespace checks. |
| Backup/install source SHA-256 checks | PASS — entire prior AzerothKart backed up/verified, only UI.lua copied, all nine installed files matched tested source. Independent read-only comparison also performed. |
| Native `lua tests/run.lua` | NOT RUN — standalone interpreter absent; actual embedded runtimes above executed the suite. |
| Client reload/new renderer display/scale/performance | NOT RUN — WoW was available in desktop inventory, but input actions were rejected by the helper's user-input freshness check. Refreshed once; ongoing interference remained. No reload command was typed/submitted; client left alone. |
| New driving/combat/F5/F4 checks | NOT RUN — outside this owner-directed slice. No character or peer actions automated. |

Delegated geometry design/test authoring supported the parent implementation. A later delegated review attempt failed because model capacity was unavailable; no successful final independent-review claim is made. Parent inspected code/tests and executed the complete suites. Updated architecture, track raster bounds, test plan, feasibility/manual steps, README and changelog; roadmap acceptance boxes stay unchanged.

**Deployment:** normal filesystem approval granted. Inspected one-off Python copier preserved the prior addon under workspace `artifacts/AzerothKart/20261019-024844-773041/before/`; hashes/status recorded in `install.json` beside it. Only AzerothKart UI.lua changed in the installed addon; no other addon or WTF/SavedVariables touched. Source is installed on disk, not observed reloaded. Existing live drive evidence remains historical under its original renderer.

**Handoff:** focused commit intended as `fix: align primitive road with analytical track bounds`; inspect `git log` for hash. No push, tag, release, network traffic or automation. Next exact task is the bounded opt-in render-cost probe above; do not resume repeated combat testing as the next task.

### 2026-10-19 07:35 CEST (Europe/Oslo) — Codex / main, bounded optional profiling

**Objective/state:** continued the existing M0 handoff on clean `main`, canonical remote, HEAD `865e187`. Inspected current docs/ADRs/source/tests; retained the owner's direction to continue independent work instead of combat/death testing. One slice: optional bounded simulation/render timer spans with a pure aggregator and exact client probe steps. No physics/input/track/loop behavior or roadmap acceptance boxes changed.

**API evidence/plan:** local primary generated build-70450 documentation (`research/upstream/wow-ui-source-forever-70450/.../FrameScriptDocumentation.lua:528–539` in parent workspace), pinned mirror commit `172a387e3ab85b26e6640d3058d5ec1e6ccd4c63`, defines `debugprofilestop` as elapsed milliseconds since the shared `debugprofilestart` reference. Implement guarded read differences without resetting that reference; keep disabled by default, cap attempts, preserve stopped results and report only on request. Runtime availability remains unprobed; provenance/steps are in CLIENT_API and the manual checklist.

**Changes:** added pure `Performance.lua` with nine scalar count/total/max fields and a 600-attempt cap; rejects malformed/nonfinite/negative/backwards readings and finite-total overflow. Both TOCs load it before UI. Core routes `/akart perf [on|off]` separately from the unchanged six-line ordinary probe. Arming while stopped validates one guarded read; a successful fresh Start creates a new window. Eligible updates take three reads around `Loop.advance`, then render/HUD work. After 600 attempts there are no more profiler reads; simulation continues. Stop/close/reopen retain aggregates; off retains them until the next Start. Active configuration changes are refused. Protected calls contain reader/validation failures, count them against the cap and never change driving. No new UI widgets, per-frame chat, sample arrays, saved settings or timer resets.

These are instrumented elapsed spans, including probe overhead. They omit preceding input/focus guards, final aggregation/report formatting and native GPU work, and do not establish exclusive addon CPU or whole-client FPS. Backwards checks cannot detect every external shared-timer reset; output is advisory. No counterfeit performance or timer-security claim is made.

**Actually executed:**

| Command/check | Actual result |
|---|---|
| Local generated API contract/provenance inspection | VERIFIED SOURCE — milliseconds/shared reference as above; no live availability pass. |
| `python scripts/test_lua.py` | PASS — 16 Lua files parsed and eight tests each in Lua 5.1/5.4 through pinned Lupa. Pure totals/maxima/zero-resolution/overflow/error budgets, full existing determinism/geometry/lifecycle suites and new UI profiling integration all execute. |
| New UI integration checks | PASS in both runtimes — zero reads off; one arm read + at most 1,800 window reads; 600 valid/invalid cap; no completion chat; stable 6/99/3 counts; frozen/restarted windows; same every-field state after identical 650-update profiled/unprofiled tape; throwing read/validation cannot stop driving. Mock phase values test accounting only. |
| `python scripts/validate_project.py` | PASS — 29 required paths, synchronized seven-module TOC order, docs links, protocol and header-only network ledger. |
| `git diff --check` / staged equivalent | PASS — whitespace checks. |
| Normal filesystem backup/install verification | PASS — old entire addon preserved/hash-verified; five changed/new files copied; all ten installed hashes matched source. Independent read-only comparison passed at 07:35. |
| Native `lua tests/run.lua` | NOT RUN — no standalone lua/luajit/luac command found. Actual embedded runtimes above ran the suite. |
| Actual client load, optional profiler availability/cost and analytical-band appearance | NOT RUN — desktop app/window inventory at 07:32 returned no WoW client; no launch/input/new drive attempted. |
| PowerShell installer fixtures, F5 persistence, F4 transport and additional combat | NOT RUN this slice — helper code unchanged; no peer/character/combat actions. |

Delegated API research, pure aggregator/tests and scoped manual docs; parent integrated/reviewed and ran both complete suites. Read-only integration review found no additional blocker after the parent fixed the thrown-validation attempt budget: errors before module commit must increment the UI attempt counter too. Added a specific regression; full suites then passed. No intentionally failing pre-implementation test run is claimed for this slice.

**Deployment:** source included two TOCs, Core.lua, Performance.lua and UI.lua; all other addon files unchanged. Normal filesystem approval granted; inspected one-off Python file copier updated its explicit ten-file/allowed-change guard and verified prior backup before writes. Artifact: parent workspace `artifacts/AzerothKart/20261019-073146-820718/install.json`, previous addon in `before/`. No other addon or WTF/SavedVariables modified. No runtime reload was possible/attempted because no client was returned. No push, tag, release, packet traffic or automation.

**Git/handoff:** PhilForever repository-local identity reverified, global settings untouched. Focused commit intended as `feat: add bounded opt-in performance probe`; inspect `git log` for hash. Next exact task is the actual-client startup/one optional profile window above. M0 and all unrun acceptance checks remain open; do not turn them into invented passes.
