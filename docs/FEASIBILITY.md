# M0–M2 feasibility — evidence gates

**M0 is open. WoW client tests are PENDING.** Offline tests and a UI test double cannot establish actual keyboard release, combat safety, frame performance or transport capacity. Execute [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md) before accepting F1/F2/F5. The single next task is the installed-client M0 safety smoke in that checklist.

## Observed local installation, 2026-10-18

- Read-only file inspection found `C:\Program Files (x86)\World of Warcraft\_classic_beta_\WowB.exe` with file/product version `1.60.1.70450`.
- `_classic_beta_\.flavor.info` contains `Product Flavor!STRING:0` and `wow_classic_beta`.
- A process-name inspection found no running `Wow*` process during this session. No live client commands or rendering tests were executed.
- Both repository TOCs declare interface `16001`. This is an unverified candidate until `GetBuildInfo()` and successful addon loading are observed in game. The installation directory/flavor file does not establish runtime `WOW_PROJECT_ID` or prove that the `Camelot` TOC is selected.
- TOC custom metadata `X-AzerothKart-TOC` distinguishes `base` from `Camelot` for the runtime metadata probe. Record the returned value; do not infer selection from filenames.

These observations identify an installed executable, not a passing addon build. Do not change another addon's files or SavedVariables while running these experiments.

## F0: runtime identity and available APIs

Run the exact read-only `/dump` commands in [CLIENT_API.md](CLIENT_API.md), capture output and record date, build, interface, project ID, selected TOC and missing APIs. A missing API is a result, not permission to substitute a guessed protected call. If the addon does not load, first capture the AddOns-list reason and Lua error; do not mark F1/F2 passed.

## F1: rendering and bounded timing

**M0 claim:** the pooled primitive oval and one kart render correctly without growing the addon's explicitly allocated UI object counts during repeated drives. This is a small workload, not the future 32-sprite benchmark.

1. Out of combat, open `/akart`, run `/akart probe`, and record FPS using `/dump GetFramerate()` before starting. Capture resolution, UI scale and a screenshot of the window.
2. Click **Start Test Drive**, steer continuously for 60 seconds, press Escape, then run `/akart probe`. Do not type the command during an active timing sample: opening chat deliberately ends capture.
3. Record reported `frames`, `ticks`, `maxElapsed`, `droppedSeconds`, `hitchFrames`, accumulator, stop reason and addon frame/texture/font-string counts. Repeat three times. Counts must remain stable; ticks must stop advancing after a stop.
4. Repeat at UI scales 0.75, 1.0 and 1.25 **only if supported by the normal client UI**; otherwise record actual available scales. Do not force a hidden/unsupported CVar value. Check kart rotation, clipping, text and controls.
5. After the short F2 safety smoke passes, run 15 minutes idle/open and 10 minutes driving. Record before/after FPS, probe output, errors and visible hitches. Use the normal game FPS display if desired.

`maxElapsed` is a whole-frame interval delivered to `OnUpdate`, not this addon's CPU cost. Dropped time measures bounded catch-up, not network loss or a pause duration. No chat output or UI object creation should occur every simulation tick. Reported object counts cover the UI module's explicit allocations; the bootstrap event frame, template internals and other addons require separate accounting. A long Alt-Tab interval may cause dropped time; there must be no long catch-up burst or automatic resume.

**Gate:** stable counts for this workload, readable primitives, no Lua/taint errors or visible sustained hitching attributable to the prototype, and F2 release tests passed. The future workload target (about 50 static sections, up to 32 moving sprites, at least 45 FPS on a recorded machine) remains untested. A claimed >10 ms addon overhead requires separate CPU profiling; frame intervals cannot establish that claim.

## F2: deliberate input capture and combat safety

The prototype starts only after **Start Test Drive** outside combat. Every subsequent mouse click releases capture, including clicks inside the canvas or an overlapping UI; this avoids guessing which non-text frame owns focus. The Start click's mouse-down/OnClick order still requires live verification. A stop clears held key aliases and the fixed-step accumulator. Returning focus, ending combat, showing the window or logging in must never restart driving automatically.

Run every row of [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md): W/Up overlap, left/right aliases, Escape, Stop, Close, chat/Enter and an unrecognized key, click outside, click chat or another UI, Alt-Tab, window hide/show, world transition, `/reload`, logout/login, opening/starting while in combat, and combat beginning during capture. After every stop, verify ordinary WoW movement and chat manually. A status message alone does not prove keyboard consumption ended.

The probe reports optional game-window focus API availability and unavailable events. Required text-focus, combat, keyboard/propagation and global mouse-event support must be available for capture to start; missing required support fails closed. The optional focus API's absence leaves Alt-Tab behavior unproven, even when other release paths work. Never invoke the restricted propagation setter during combat. Deferred restoration after combat is an implementation detail that must be tested against actual behavior and taint output.

**Gate:** every release route restores ordinary controls, start is rejected in combat, combat interruption stops simulation/input safely, no auto-resume or protected-action errors. Any stuck input or combat taint blocks M0; do not bypass it with protected-action tricks. A permitted on-screen-control fallback would require a separate scoped implementation and evidence.

## F3: deterministic local simulation

For identical initial state/seed and tick-indexed input vectors, compare state at every tick over at least 10,000 fixed steps, including final state. Compare varied render schedules and bounded hitch behavior separately. Record commands and runtime version in `PROGRESS.md`. Offline determinism applies to the tested runtime; it does not establish cross-client floating-point compatibility or good handling. M1 still requires direct play and handling metrics. There is no production lap/checkpoint system to accept yet.

## F4: transport capacity — no architecture decision yet

**No network probe or automatic packet traffic is implemented.** [The network checklist](../tests/MANUAL_NETWORK_CHECKLIST.md) defines the future consented experiment and [network-ledger.csv](experiments/network-ledger.csv) is a header-only result template. Do not enter zero counts for tests not run.

Use two actual clients first, event sender identity, a fresh session ID and `AZKART1`. Test private `WHISPER` and `PARTY` separately, payloads of exactly 16/64/128/220 total message bytes, and 0.5/1/2/4 data packets per second for 120 seconds per window. ACKs and every participant's sends count toward the budget. Advance rates only while the prior window is stable. Record enqueue results separately from matched receipts, duplicates, reorder, timeouts, same-clock RTT and arrival gaps. Missing ACKs cannot alone distinguish data loss, ACK loss, delay, throttle or peer interruption.

Repeat direction A→B and B→A, then bidirectional traffic. Record city and instance conditions independently. Test reload/disconnect/reconnect with a new session; stale session packets must not count as valid receipts. Only add four/eight clients after two-client measurements and available consenting testers. Never send on each render or simulation tick and never use public chat for the probe.

**Gate:** measured sustainable aggregate traffic with reproducible recovery, followed by a recorded ADR selecting live-race research or asynchronous ghost/time-trial exchange. A transport pass is not a playable multiplayer pass. The later two-player race trial target remains an average handling/correction score >4/5 across five runs, no repeated teleport/collision/finish disagreement, and <1% ACK timeout in steady state under the chosen deadline. ACK timeout is an observable failure rate, not proven message loss. These are product targets pending evidence, not API guarantees.

## F5: reload and minimal persistence

The current addon only initializes a minimal schema table; there are no settings, personal-best or ghost records to validate. Follow the checklist's isolated `_m0Probe` sentinel test to distinguish real SavedVariables persistence from simply recreating `schemaVersion=1` on load. Check `/reload`, logout/login and full exit/restart. Do not replace the database or edit other addons' saves. Remove the sentinel after the experiment.

**M0 gate:** clean reload/login, inactive controls after load, and a sentinel value that survives the tested save boundaries. Schema migrations, corrupt-save recovery, bounded ghosts and personal-best persistence remain later work and must not be marked passed by this smoke test.

## Evidence ledger

| ID | Environment | Experiment | Actual outcome | Status |
|---|---|---|---|---|
| F0-local | Windows files, 2026-10-18 | Executable/flavor/process inspection | `WowB.exe` 1.60.1.70450; `wow_classic_beta`; no running `Wow*` process | OBSERVED OFFLINE |
| F0-runtime | Installed client | Build/interface/TOC/API dumps | Not run | PENDING |
| F1 | Installed client | One-kart rendering/timing/object counts | Not run | PENDING |
| F2 | Installed client | Focus/release/combat safety matrix | Not run | PENDING |
| F3 | Offline runtime | Determinism/hitch tests | See executed command evidence in `PROGRESS.md` | OFFLINE ONLY |
| F4 | Two actual clients | Transport windows and recovery | No traffic generated; no measurements | PENDING |
| F5 | Installed client | Reload/restart/sentinel persistence | Not run | PENDING |

When recording results include exact command output, build, date, conditions and evidence paths. Screenshots and personal logs belong in local artifacts unless explicitly approved for publication. On failure, record the narrow failing case and any resulting ADR before claiming a workaround.
