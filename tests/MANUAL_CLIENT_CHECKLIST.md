# Manual client acceptance — F0/F1/F2/F5

**Live checks PARTIAL, 2026-10-18.** Identity, basic rendering/Start and several idle release paths were observed in the installed client; the owner also confirmed real combat closes the window, displays the interruption note and leaves WoW controls working. See [the actual-client evidence](../docs/evidence/2026-10-18-m0-client.md). Sustained driving, held-key release and remaining rows are pending unless separately reported; simultaneous W/Up is SKIPPED at the owner's request. Do not turn an idle UI smoke or test-double result into a full acceptance pass.

Observed date/time: 2026-10-18 ~17:10–17:16 CEST (Europe/Oslo); tester: Codex computer-use, manual gameplay pending.
Build/interface: 1.60.1 / 70450 / 16001; runtime project ID: 18; selected TOC: Camelot; addon version: 0.0.1.
Captured resolution: 1920×1080; uiScale: 1.000000 / useUiScale: 0; Windows; hardware not recorded.
Other addons remained enabled/unchanged; baseline whole-client FPS sample: 207.6124420166. Evidence: linked above; no public screenshots.

## 1. Identity and startup

- [x] AddOns-list enabled state observed, addon version read from runtime metadata, no incompatible/out-of-date notice visible. Screenshot observed in this chat; personal capture not committed.
- [x] Runtime identity and required capabilities read through `/akart probe`, `/dump` and equivalent grouped local readbacks; outputs transcribed in evidence. Interface `16001`, project ID `18`, Camelot selection confirmed; `IsGameWindowFocused`/`IsWindowFocused` absent. Extra standalone command forms remain available for reproduction in [CLIENT_API.md](../docs/CLIENT_API.md).
- [x] Out of combat, `/akart` opened the primitive oval inactive; probe output observed. Start worked only after clicking its button.
- [ ] Exact slash-toggle close plus manual ordinary movement check. Close-button hide and stopped reopen/chat were observed; ordinary character movement remains manual/pending.

## 2. Controls and stop matrix

For **each row**, start a fresh drive with a deliberate **Start Test Drive** click outside combat. Hold W for movement, perform the action, then release all keys. Record the actual stop reason from `/akart probe`, confirm ticks remain unchanged across two probe calls several seconds apart, test ordinary WoW movement keys and type into chat, and confirm no automatic resume. Do not type the probe during the active timing sample: entering chat is itself a stop test.

Perform character movement and combat setup manually through normal WoW controls; these steps do not authorize automation of the WoW character. Kart input controls only the addon's test drive.

| Check | Reproducible action | Required observation | Result/evidence |
|---|---|---|---|
| Basic movement | W then Up; S then Down; A/D then Left/Right | Acceleration, braking/reverse and both steering aliases work; visible rotation matches motion | PENDING |
| Overlapping aliases | Hardware-dependent simultaneous alias hold/release | Alias bookkeeping has offline regression coverage; this live combination is not an acceptance gate for this keyboard | SKIPPED at owner's request, 2026-10-18: keyboard cannot hold W+Up together. Not a pass/failure; do not request this combination again |
| Escape | Press Escape while moving | Capture stops; ordinary bindings/chat recover | IDLE OBSERVED: stopped, normal Game Menu opened. Held movement still PENDING |
| Stop | Click Stop while holding throttle | Stops and clears held input; ordinary controls recover | IDLE OBSERVED: global mouse-down stopped before button OnClick. Held throttle still PENDING |
| Close/toggle | Click Close; separately use `/akart` to close | Hidden window cannot retain capture; reopening is stopped | Close/reopen observed inactive; exact slash-close/held-input still PENDING |
| Enter/chat | Press Enter during capture, then type a harmless chat draft and cancel it | Driving stops; chat receives text normally; record whether first Enter opens chat | IDLE OBSERVED: first Enter stopped/opened chat; local command typed/executed; no peer message. Held throttle PENDING |
| Unrecognized key | Press the normal map key (or another non-driving binding), then close that UI normally | Driving stops; record whether the normal binding also works on that press | OBSERVED: first M stopped capture and opened map; second M closed it normally |
| Click outside | Click world outside the race window while throttle is held | Stops and releases controls without relying on key-up reaching the race frame | PENDING |
| Any mouse click | Click the race canvas; separately click a non-text UI panel overlapping the race window | Every mouse-down releases capture; overlapping UI/clicks work normally | Canvas click OBSERVED: stopped with mouse-click reason. Overlapping panel/held-throttle variant PENDING |
| Other UI focus | Click chat edit area, bag/UI panel or another normal edit box | Stops; typing/clicked UI work normally | PENDING |
| Application focus | Alt-Tab away for 5 seconds, release W outside the game, return | Stopped on return, no stale throttle or auto-resume; record optional focus API status | IDLE OBSERVED: remained stopped after >=5s away; optional focus API absent. Held W/release-outside still PENDING |
| Hide/show UI | Use the ordinary client UI-hide binding, then show UI again | No capture through a hidden window; stopped after show | OBSERVED: Alt-Z hid all UI; second Alt-Z restored it with racing stopped, no auto-resume |
| World transition | Have a normal manually initiated loading transition occur during capture when practical (for example a consented portal/instance entry) | Stops on leaving world; no auto-resume after arrival | PENDING / unavailable |
| Reload | While driving, enter `/reload` normally, then log result after load | Clean reload, inactive controls and ordinary movement/chat | OBSERVED: normal Enter released capture; reload completed with window hidden; post-reload probe active=false/Not started, ticks=0, counts=6/99/3. Local chat command worked; no movement automation used |
| Logout/login | Log out normally after a drive, then log in | Clean load; inactive controls, ordinary movement/chat | PENDING |
| Combat before Start | Enter combat through ordinary manual game play, open `/akart`, attempt Start | Start rejected; no capture, restricted-action error or taint | PENDING |
| Combat during capture | Outside combat Start, then have combat begin through ordinary manual game play or a consenting duel partner; after combat deliberately reopen `/akart` without Start | Window closes; ticks stop; held input clears; `Game interrupted by combat` is retained on reopen; ordinary movement/chat work during and after combat; no taint or auto-resume | OWNER CONFIRMED: window closed, message appeared, WoW controls work. Exact stopped tick, reopen/retention, repeat/no-auto-resume and full taint audit still PENDING live |
| Repeated combat notification | During the same interruption, observe subsequent combat notifications if they occur; otherwise leave the live duplicate case pending and use the offline lifecycle check as separate evidence | One interruption note/result for that drive, no change to its stopped tick; no repeated close/reopen loop | PENDING / unavailable |

Capture stop reasons may differ with event order (for example global mouse-down can precede a button click). The deliberate Start click must activate capture successfully despite the mouse-down stop rule; verify actual ordering rather than assuming it. All later mouse-down events stop driving. Record actual output and behavior. Chat commands can stop capture before reload/logout events; the loading-transition row tests a separate non-chat route. If a scenario cannot be arranged, leave it pending and explain why.

Any stuck input or combat taint is an M0 blocker. Record the exact failing action, event/status output and client error. End that driving test; do not bypass protected restrictions to produce a pass. Confirm that after combat the input propagation restoration does not restart the drive.

The confirmed [combat rule](../docs/adr/0006-combat-interrupted-results.md) ends a race with its actual current placements, finalized once and labeled interrupted. This M0 probe has no standings: accept closure and the retained interruption note only, and do not record a fabricated placement. Network propagation of another player's combat is outside this local test. Do not generate fake combat events or deliberately enter a duplicate result merely to fill a checklist row.

## 3. F1 timing and allocation sample

**NOT RUN:** three timed client drives and the 2026-10-19 timing/HUD changes. The 2026-10-18 short probe predates the cumulative elapsed/cadence fields and immediate stopped-HUD refresh; retain it as historical smoke evidence only.

Perform each drive manually, outside combat, with an independent timer. Use the normal client FPS display if desired. Do not open chat or click the probe button during the active sample: both deliberately stop capture. This is a measurement aid, not an automatic driver or timed race mode.

1. While stopped, copy `/akart probe`, `/dump GetFramerate()` and normal UI-scale readbacks. Record the client build, resolution, scale and other relevant conditions. Close chat before starting.
2. Click **Start Test Drive** and start the independent timer. The HUD must reset from the previous sample to tick 0 / `Sample: 0.0s` immediately on Start, then advance normally. Drive and steer for approximately 60 seconds; sequential W then Up is sufficient for the throttle aliases. Do not attempt the owner's skipped simultaneous W/Up combination.
3. Press Escape at the target duration and stop the independent timer. If Escape opens the normal game menu, dismiss it normally. The HUD must immediately reflect the final stopped tick, rather than retaining the last quarter-second update. Copy `/akart probe` while stopped and confirm its tick equals the HUD tick.
4. Wait several seconds, run `/akart probe` again, then close/reopen `/akart` without Start and repeat the probe. Ticks, timing/cadence values and allocation counts must remain unchanged while inactive; the status/stop reason can reflect closing. Reopen must not resume driving. Confirm ordinary WoW controls work manually.
5. Repeat steps 2–4 for three fresh drives. Only a deliberate Start resets the timing sample. Keep failed/interrupted or shorter runs as separate evidence rather than calling them 60-second passes.

- [ ] Three samples recorded with independent timer duration, `activeFrameSeconds`, `simulatedSeconds`, `callbackHz`, frames, ticks, maxElapsed, hitchFrames, droppedSeconds, accumulator, stop reason, explicit addon frame/texture/font-string counts and visible symptoms.
- [ ] For each sample, verify `activeFrameSeconds ≈ simulatedSeconds + droppedSeconds + accumulator` within 0.0002 seconds at the current printed precision; record actual values and investigate an unexplained discrepancy.
- [ ] Immediate stopped HUD/probe tick agreement, frozen values across delayed probe/close/reopen, and fresh Start reset verified.
- [ ] Counts stable across repeated drives/open/close cycles and no chat output each tick. These UI module counts exclude the bootstrap event frame and internal template allocations; do not claim whole-client allocation measurements.
- [ ] Repeat readable/usable layout checks at available normal client scales near 0.75/1/1.25. Record actual values if the normal UI range differs.
- [ ] After safety passes, leave open/idle for 15 minutes, then drive for 10 minutes. Record before/after FPS, metrics/errors and visible hitches. Return from a long Alt-Tab without catch-up burst or automatic resume.

`activeFrameSeconds` sums valid elapsed values delivered to active `OnUpdate` callbacks; it is not an independent wall clock and need not equal the timer exactly. `simulatedSeconds` is `ticks × 1/60`, excluding dropped time. `callbackHz` is `frames / activeFrameSeconds` (zero before elapsed time), the cadence of accepted active callbacks; record separately sampled whole-client FPS independently. `maxElapsed` is whole-frame elapsed time, not measured addon CPU overhead. Stop preserves the residual accumulator for readback, and the inactive clock cannot advance. This one-kart experiment does not validate 32 sprites, multiplayer, production tracks or a lap engine.

## 4. F5 minimal SavedVariables persistence

Only schema initialization exists. A schema value recreated at load does not prove persistence. The optional sentinel below adds and removes **one unused field in AzerothKartDB only**; it must not replace the table, touch another addon's data or overwrite an existing field.

1. Stop the drive. Check that the field is unused:

```text
/dump AzerothKartDB and AzerothKartDB._m0Probe
```

2. If the field is nil and the DB is a table, run this guarded setup, replacing the sample token with this test's unique date/time token. If it says `sentinel not set`, stop this subtest and record why; do not clear an existing field.

```text
/run if type(AzerothKartDB)=="table" and AzerothKartDB._m0Probe==nil then AzerothKartDB._m0Probe="M0-20261018-A" print("sentinel set",AzerothKartDB._m0Probe) else print("sentinel not set") end
```

3. `/reload`; then run the two readbacks below. Repeat after normal logout/login and a full game exit/restart. Verify the exact token survives each boundary, no Lua errors occur and the race stays inactive until deliberate Start.

```text
/dump AzerothKartDB and AzerothKartDB.schemaVersion, AzerothKartDB and AzerothKartDB._m0Probe
/akart probe
```

4. After all three boundaries, remove **only the sentinel you created** using its exact token; reload and verify nil.

```text
/run if type(AzerothKartDB)=="table" and AzerothKartDB._m0Probe=="M0-20261018-A" then AzerothKartDB._m0Probe=nil print("sentinel removed") else print("sentinel unchanged") end
/reload
/dump AzerothKartDB and AzerothKartDB._m0Probe
```

- [ ] Sentinel survives reload; evidence: ______
- [ ] Sentinel survives logout/login; evidence: ______
- [ ] Sentinel survives full exit/restart; evidence: ______
- [ ] Test sentinel removed; inactive post-load controls verified; evidence: ______

Do not mark settings/ghost saves, migrations or corrupt-save recovery passed: those features are not implemented. Persist observed outcomes, exact errors and evidence links in `docs/FEASIBILITY.md` and `docs/PROGRESS.md`, keeping any unexecuted row pending.
