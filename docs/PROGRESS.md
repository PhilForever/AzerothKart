# PROGRESS — persistent project handoff

**Current milestone:** M0 — repository and actual-client/API feasibility. **OPEN.**
**Current state (2026-10-18):** local driving probe hardened; structural checks and seven offline tests pass in Lua 5.1 and Lua 5.4. No actual WoW session was run. M0 rendering, focus, combat, reload and performance acceptance remain pending.

## Canonical checkout and commits

Work in this directory: `C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart`.
Remote: `https://github.com/PhilForever/AzerothKart.git`; branch `main`. The pack originally had no `.git` history; remote inspection returned no refs. The original pack was preserved before changes.

- `98bd16a` — `chore: preserve initial Azeroth Kart M0 project pack`.
- `be33176` — `fix: harden M0 driving probe and feasibility checks`.
- The following documentation handoff commit records this run; inspect `git log` for its hash.

Repository-local identity is `PhilForever <philfluenser@gmail.com>` with `user.useConfigOnly=true`; verified in config and commit authors. Global identity was left unchanged. No push, tag, distribution, installation or automation was performed. Ignored `local-artifacts/` contains test dependencies/logs only and is not staged.

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

- [ ] Runtime `GetBuildInfo()`, interface `16001`, project ID, selected base/Camelot TOC and successful addon load. Unique `X-AzerothKart-TOC` metadata enables observation rather than inference.
- [ ] Actual keyboard/focus and event ordering, including deliberate Start mouse-down/OnClick ordering, overlapping WoW UI, chat, Alt-Tab, hide/show and ordinary bindings after release.
- [ ] Combat interruption: propagation setters are guarded in code/mocks, but actual legality/effectiveness of `EnableKeyboard(false)` during combat and absence of taint remain **MANUAL TEST REQUIRED**. No protected API bypass is acceptable.
- [ ] `IsGameWindowFocused` availability/Alt-Tab semantics. Its absence does not crash the probe but leaves application focus safety unresolved and blocks accepting F2.
- [ ] Actual rendering, rotation, UI scale, FPS/CPU cost, long-session behavior and memory. Mock counters measure explicit addon allocations only, not client/template internals or real performance.
- [ ] Reload/logout/full restart and isolated sentinel persistence. Minimal schema initialization is not proof of a save, migration or settings/ghost support.
- [ ] Direct handling/play evaluation. Analytical metrics are a baseline only; no M1 game-feel acceptance.
- [ ] Two-client transport measurements, reconnect and architecture ADR. No runtime bandwidth, loss, throttle or latency results exist.

Read-only local evidence: `_classic_beta_\WowB.exe` reports file/product version `1.60.1.70450`; `.flavor.info` contains `wow_classic_beta`. No running `Wow*` process was observed. These files establish neither interface number nor runtime TOC selection. Source was not installed during this run; IOU's direct-install authorization does not apply to this addon.

## Next exact task

Execute the installed-client M0 identity and input/combat safety smoke in **sections 1–2 of `tests/MANUAL_CLIENT_CHECKLIST.md`**, recording real interface/TOC/API output and every control-release/taint outcome in `docs/FEASIBILITY.md` and this file. Arrange an explicit developer install of this source if needed; do not silently deploy. Keep M0 open and defer further features until these results exist.

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
