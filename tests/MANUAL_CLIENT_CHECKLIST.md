# Manual client acceptance — F0/F1/F2/F5

## Deferred short Test Oval obstacle check (Physics v7)

**NOT RUN.** Coordinate installation with Claude's current art first; this branch is based on the shared sprite review, not the latest scenery deployment. Do not overwrite that deployment from this checkout without reviewed integration.

1. After a coordinated verified update/reload, open `/akart` out of combat. On Test Oval, confirm two red 32×24 barriers near the upper-left and lower-right road edges. Start, wait for GO, approach one deliberately and confirm a head-on hit slows the kart and clears drift/boost. At an angle the kart should slide along its edge; steer away to recover. Clearance uses a conservative 18-unit square margin, not the exact chassis outline.
2. Stop, select Mirage Raceway, and confirm neither barrier appears. Drive only if a human is available; no obstacle should affect the map. Stop and switch back to Oval: both same markers return. Do not move the WoW character to perform this test.
3. Print Probe once while stopped. Source expects 10 frames/151 textures/13 font strings (9/113/13 before the 38 pooled drift/boost effect textures and the Kart button), with stable counts through switches/reopen. Record actual build, appearance/handling issues and the observations executed; leave other cases pending. No repeat combat or long profiling matrix is required for this slice.

**Live checks PARTIAL, 2026-10-18.** Identity, basic rendering/Start and several idle release paths were observed in the installed client; the owner also confirmed real combat closes the window, displays the interruption note and leaves WoW controls working. See [the actual-client evidence](../docs/evidence/2026-10-18-m0-client.md). Sustained driving, held-key release and remaining rows are pending unless separately reported; simultaneous W/Up is SKIPPED at the owner's request. Do not turn an idle UI smoke or test-double result into a full acceptance pass.

**2026-10-19 continuation:** two human near-minute drives are recorded below. An unplanned combat/death sequence left the stopped window visible. That inactive-event source gap is fixed/tested offline, installed and loaded; actual combat verification remains deferred. Further drives were put on hold at that point; the owner's subsequent direction is recorded below. [Driving evidence](../docs/evidence/2026-10-19-m0-client.md).

**Owner steering afterward:** continue development elsewhere; no further combat test is requested now. On 2026-10-19 the owner requested about 80% less testing and build-first work ([ADR 0007](../docs/adr/0007-build-first-development.md)). Unrun rows stay pending while local M1 mechanics progress; long manual/scale/profile matrices and the geometry review below are deferred.

**2026-10-19 profiler continuation, 07:32 CEST:** desktop app/window inventory returned no WoW client. The optional bounded profiler is installed on disk with all ten addon files matching tested source. Live profiler type/readback/cost, new-renderer load and appearance remain **NOT RUN**. The separate `/akart perf` protocol below is prepared; no new human drive or combat check is requested during this development slice.

**Stationary continuation, ~08:37–08:58 CEST:** the owner authorized unattended checks while unavailable. WoW was accessible. One stationary diagnostic supplied 600 valid scoped samples; counters/timings stayed frozen after stop, close/reopen and disarm. The analytical road loaded with horizontal seams. Two creation-time snapping experiments hid the road after reload and were removed; the prior renderer was restored and observed after another reload. [Historical results and review blocker](../docs/evidence/2026-10-19-m0-stationary-profile.md). This does not replace a human drive, fresh unprofiled Start, scale matrix or full M0 acceptance.

**Latest rendering continuation, 09:08–09:20 and 13:54–14:02 CEST:** isolated grass hide/show and settings checks identified occlusion under mixed snapping states. The permanent fix sets explicit grass priority and configures only the 96 bands during creation. A clean normal reload showed the complete renderer without seams at effective scale 0.72452831268311; readbacks verified all 96 band settings and grass `BACKGROUND,-1` with unchanged grass snapping. Reopen stayed inactive with counts 6/99/3; final state stopped, hidden, profiling off. [Exact evidence, including the quota interruption](../docs/evidence/2026-10-19-m0-road-layer.md). Supported-scale/stress and full M0 acceptance remain open.

Observed date/time: 2026-10-18 ~17:10–17:16 CEST (Europe/Oslo); tester: Codex computer-use, manual gameplay pending.
Build/interface: 1.60.1 / 70450 / 16001; runtime project ID: 18; selected TOC: Camelot; addon version: 0.0.1.
Captured resolution: 1920×1080; uiScale: 1.000000 / useUiScale: 0; Windows; hardware not recorded.
Other addons remained enabled/unchanged; baseline whole-client FPS sample: 207.6124420166. Evidence: linked above; no public screenshots.

## Optional M1 drift smoke — NOT RUN

Use at a later handling checkpoint, when a person can drive; this is not a prerequisite to the next local build slice.

1. Outside combat, open `/akart` and click Start. Wait for 3–2–1/GO, then accelerate to 90+ with W or Up, then hold Space with one turn direction. Observe bounded slide, blue charge and the named drift HUD.
2. Keep the turn for about 0.5 seconds to reach gold/tier 1; continuing about 1.0 second total reaches pink/tier 2. Release Space to spend the charge: observe cyan/BOOST, then return to normal. Judge responsiveness rather than timing these short intervals by eye as proof of exact ticks.
3. Keep Space held and briefly release steering or change direction. Charge should pause with `CHARGE HELD`, then resume when steering settles; a pause longer than 0.2 seconds clears it. Releasing Space during the brief pause can still boost an earned tier. Braking or leaving the road clears charge without reward. Avoid intentionally triggering combat. Escape must stop capture; the HUD retains `Last drive`, and a deliberate new Start clears it.
4. Record subjective handling, any Lua/layout error and stopped probe. Current source expects 10 frames/151 textures/13 font strings (9/113/13 before the drift/boost effects and the Kart button); prior live 6/99/3 evidence belongs to the earlier source. Do not repeat the skipped simultaneous W/Up test.

Optional surface check at that same later checkpoint (**NOT RUN**): leave the road into island/exterior grass, observe slowdown and Grass feedback with cancelled drift/boost, then return to road. Approach a gray perimeter wall at an angle: the kart stays visible and slides along it with a speed scrub. Stop retains the surface under `Last drive`; Start resets it. Do not expand this into another long scale/combat matrix.

Optional interpolation check at that checkpoint (**NOT RUN**): drive and turn at a callback cadence above 60 Hz when available, observing motion between simulation steps and continuous heading across a full turn. Press Escape, note the final kart pose, then close/reopen; it must stay still until a deliberate Start resets it. Exact final-pose snapping can move the kart by up to the last fixed step; active interpolation adds at most one fixed step of visual delay. Record perceived smoothness and any visible jump or Lua error; no new scale/profile matrix is requested.

Optional meter check at that checkpoint (**NOT RUN**): during the same drift attempt, observe half-fill at Tier 1 and full fill at Tier 2 with a named ready caption. Release Space and observe the cyan remaining-boost meter drain on its 0.4s/0.8s scale; a Tier 1 boost starts shorter than Tier 2 on the shared scale. Cancelling or entering grass clears it. Escape freezes the meter with `Last drive`; close/reopen retains it, and a deliberate Start empties it. Record readability/layout issues in the current 856×762 window; exact tick thresholds remain an offline check.

Optional steering check at that checkpoint (**NOT RUN**): tap and hold a turn, release it, then reverse direction during the same drive. Judge whether buildup and faster centering feel controllable at road speed; reversal centers before turning the other way. With Space held, charge pauses through brief corrections and expires after the 12-tick grace; grass still cancels it and permits recovery. Exact 8/4/12-tick full-turn/release/reversal timings are offline checks, not intervals to prove by eye. No additional capture, combat or scale matrix is requested.

Optional countdown/three-lap finish check during the same later drive (**NOT RUN**): hold throttle after Start and observe the kart remain at spawn through 3–2–1, then begin moving after GO. GO clears shortly afterward; lap/race time excludes countdown while probe ticks include it. A hitch can extend countdown wall time, so do not prove exact ticks by eye. In one short attempt, Escape during countdown must retain zero race elapsed time and reopening must not resume; Restart begins a fresh countdown. Then follow North, West, South and Start counterclockwise for three circuits. Each ordered circuit awards one lap; crossing Start before the other gates must not award another. Best must show -- before the first completed lap, then that lap time/number. A faster later completed lap replaces it; an incomplete lap does not. Exact equal-time/earliest-lap handling remains an offline check. At lap three, capture must release and RUN COMPLETE must show total/last-lap times and the best completed lap with the kart frozen. Check the taller 380×190 summary for clipping. Close/reopen must retain that summary; click Restart deliberately and confirm a fresh countdown with empty best and no automatic driving on reopen. In a separate short attempt, Escape must show RUN STOPPED with actual partial progress and any best from already completed laps. Reopen must retain it. Best is per run and does not survive a fresh run as a personal record. Do not arrange combat for this slice; retain the existing deferred combat checks. Timing uses simulation ticks, excludes dropped callback time and is not an independent wall-clock measurement. Record any readability/error without starting a long matrix.

## 1. Identity and startup

- [x] AddOns-list enabled state observed, addon version read from runtime metadata, no incompatible/out-of-date notice visible. Screenshot observed in this chat; personal capture not committed.
- [x] Runtime identity and required capabilities read through `/akart probe`, `/dump` and equivalent grouped local readbacks; outputs transcribed in evidence. Interface `16001`, project ID `18`, Camelot selection confirmed; `IsGameWindowFocused`/`IsWindowFocused` absent. Extra standalone command forms remain available for reproduction in [CLIENT_API.md](../docs/CLIENT_API.md).
- [x] Out of combat, `/akart` opened the primitive oval inactive; probe output observed. Start worked only after clicking its button.
- [ ] Exact slash-toggle close plus manual ordinary movement check. Close-button hide and stopped reopen/chat were observed; ordinary character movement remains manual/pending.

## 2. Controls and stop matrix

**Current owner policy, 2026-10-20:** incidental mouse clicks and unassigned keys must leave the run active. Unsupported keys are consumed during capture. Escape/Stop/Close are explicit terminal exits; Enter/`NUMPADENTER` is an intentional chat exit. The earlier all-click/unknown-key stop observations below are historical and do not verify this changed policy. The new flow is **NOT RUN** in the client until a scoped result is recorded.

For **each row**, start a fresh drive with a deliberate **Start Test Drive** click outside combat. Hold W for movement, perform the action, then release all keys. For continue-driving rows, confirm the run remains active and ticks continue before deliberately stopping. For stop rows, record the actual stop reason from `/akart probe`, confirm ticks remain unchanged across two probe calls several seconds apart, test ordinary WoW movement keys and type into chat, and confirm no automatic resume. Do not type the probe during the active timing sample: entering chat is itself a stop test.

Perform character movement and combat setup manually through normal WoW controls; these steps do not authorize automation of the WoW character. Kart input controls only the addon's test drive.

| Check | Reproducible action | Required observation | Result/evidence |
|---|---|---|---|
| Basic movement | W then Up; S then Down; A/D then Left/Right | Acceleration, braking/reverse and both steering aliases work; visible rotation matches motion | First human near-minute drive OBSERVED 2026-10-19: displaced/rotated kart, 3492 ticks. Individual alias/braking/reverse checks remain PENDING |
| Overlapping aliases | Hardware-dependent simultaneous alias hold/release | Alias bookkeeping has offline regression coverage; this live combination is not an acceptance gate for this keyboard | SKIPPED at owner's request, 2026-10-18: keyboard cannot hold W+Up together. Not a pass/failure; do not request this combination again |
| Escape | Press Escape while moving | Capture stops; ordinary bindings/chat recover | IDLE OBSERVED: stopped, normal Game Menu opened. Held movement still PENDING |
| Stop | Click Stop while holding throttle | Button remains enabled during countdown/driving; its own callback stops and clears held input; ordinary controls recover | Historical IDLE OBSERVED: global mouse-down stopped before button OnClick. Corrected callback/held-throttle flow NOT RUN |
| Close/toggle | Click Close; separately use `/akart` to close | Hidden window cannot retain capture; reopening is stopped | Close-button and slash-close/reopen OBSERVED inactive, including frozen sample 1 timing on Oct19. Held-input/ordinary movement variant PENDING |
| Enter/chat | Press Enter during capture, then type a harmless chat draft and cancel it; separately check Numpad Enter when available | Driving stops; chat receives text normally; record whether first Enter opens chat | Historical IDLE OBSERVED: first Enter stopped/opened chat; local command typed/executed; no peer message. Explicit-key implementation and held throttle NOT RUN |
| Unassigned key | Press M, F, Tab or another unassigned key while driving | Run/held driving inputs continue; unsupported key is consumed and does not open its ordinary WoW binding during capture | Historical OBSERVED: M stopped capture and opened map under superseded policy. New behavior NOT RUN |
| Click outside | Click outside the race window while throttle is held | Incidental click leaves the run active; releasing throttle still clears throttle | NOT RUN under current policy |
| Incidental mouse click | Click the race canvas; separately click a non-text UI panel overlapping the race window | Run continues; no stopped summary or reset of held driving inputs | Historical canvas click OBSERVED: stopped under superseded policy. New behavior NOT RUN |
| Text/other UI focus | Click a normal chat/edit box; separately click a non-text bag/UI panel | Actual text focus stops capture and permits typing; a non-text click alone leaves driving active | NOT RUN under current policy |
| Application focus | Alt-Tab away for 5 seconds, release W outside the game, return | If an application-focus getter is available, stops without auto-resume. On build 70450 record actual held-key behavior; do not assume a stop or claim a fallback | Historical idle Alt-Tab stopped through the now-removed unknown/Alt-key route; both observed focus getters absent. Current held W/release-outside case NOT RUN |
| Hide/show UI | If the client hides the racing window during capture, show it again normally; do not require an unassigned key to propagate | No capture through a hidden window; stopped after show | Historical OBSERVED: Alt-Z hid/restored UI with racing stopped under the old key policy. Current hide/show route NOT RUN |
| World transition | Have a normal manually initiated loading transition occur during capture when practical (for example a consented portal/instance entry) | Stops on leaving world; no auto-resume after arrival | PENDING / unavailable |
| Reload | While driving, enter `/reload` normally, then log result after load | Clean reload, inactive controls and ordinary movement/chat | OBSERVED: normal Enter released capture; reload completed with window hidden; post-reload probe active=false/Not started, ticks=0, counts=6/99/3. Local chat command worked; no movement automation used |
| Logout/login | Log out normally after a drive, then log in | Clean load; inactive controls, ordinary movement/chat | PENDING |
| Combat before Start | Enter combat through ordinary manual game play, open `/akart`, attempt Start | Start rejected; no capture, restricted-action error or taint | PENDING |
| Combat during capture | Outside combat Start, then have combat begin through ordinary manual game play or a consenting duel partner; after combat deliberately reopen `/akart` without Start | Window closes; ticks stop; held input clears; `Game interrupted by combat` is retained on reopen; ordinary movement/chat work during and after combat; no taint or auto-resume | OWNER CONFIRMED: window closed, message appeared, WoW controls work. Exact stopped tick, reopen/retention, repeat/no-auto-resume and full taint audit still PENDING live |
| Combat after Stop | After loading the fix, open an inactive window; separately stop a short drive and record its probe. Have combat begin only through normal owner-controlled play when practical | Window hides on combat onset; completed sample/reason or prior interrupted result unchanged; no new interrupted-drive announcement or automatic resume. Explicit reopen may inspect the note/Start refusal | FAILURE OBSERVED Oct19: stopped window remained visible during attack/death. Source regression/fix PASS offline; installed and loaded, actual combat verification NOT RUN. Do not automate combat or character recovery |
| Repeated combat notification | During the same interruption, observe subsequent combat notifications if they occur; otherwise leave the live duplicate case pending and use the offline lifecycle check as separate evidence | One interruption note/result for that drive, no change to its stopped tick; no repeated close/reopen loop | PENDING / unavailable |

Exercise normal mouse-down followed by button release: Start must start, Stop must reach its own callback, and incidental clicks must leave driving active. `GLOBAL_MOUSE_DOWN` is no longer required to capture input. Track selection stays disabled while active; clicking it must neither stop the run nor discard progress. Record actual output and behavior. Chat commands can stop capture before reload/logout events; the loading-transition row tests a separate non-chat route. If a scenario cannot be arranged, leave it pending and explain why.

Any stuck input or combat taint is an M0 blocker. Record the exact failing action, event/status output and client error. End that driving test; do not bypass protected restrictions to produce a pass. Confirm that after combat the input propagation restoration does not restart the drive.

The confirmed [combat rule](../docs/adr/0006-combat-interrupted-results.md) ends a race with its actual current placements, finalized once and labeled interrupted. This M0 probe has no standings: accept closure and the retained interruption note only, and do not record a fabricated placement. Network propagation of another player's combat is outside this local test. Do not generate fake combat events or deliberately enter a duplicate result merely to fill a checklist row.

**Retained interruption note follow-up — NOT RUN for the 2026-10-19 source fix:**

1. After the ordinary manual combat-interruption check above, reopen `/akart` without Start. Record the visible interruption note, stopped tick and timing probe.
2. Close/reopen with `/akart` twice, then separately use Close and reopen. The interruption note and stopped probe values must remain, with no automatic resume or new unsolicited interruption message. Explicit probe reports may repeat the retained stop reason; those are requested diagnostics.
3. If combat is still ongoing, attempt Start normally: the refusal and retained interruption note must both be visible, with ticks unchanged. After combat ends, a successful deliberate Start must clear the old note and reset the drive. A later normal Stop/Close must show its own reason. Leave unavailable cases pending; do not automate combat or remove APIs to fill a row.

## 3. F1 timing and allocation sample

**2026-10-19 two drives observed:** 58.2120/62.6020 active seconds and 3492/3756 ticks; no dropped time, counts 6/99/3, matching stopped HUD and frozen delayed readbacks. First-sample close/reopen also retained numeric fields. See [the live evidence](../docs/evidence/2026-10-19-m0-client.md). Third sample remains PENDING at owner direction while independent M0 development continues. Independent duration/handling details, scaling/stress and full acceptance remain pending. The 2026-10-18 short probe remains historical smoke evidence only.

Perform each drive manually, outside combat, with an independent timer. Use the normal client FPS display if desired. Keep chat/probe output out of the active timing sample: chat deliberately stops capture, while clicking Print Probe no longer stops the run and would report a moving sample. This is a measurement aid, not an automatic driver or timed race mode.

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
- [x] Basic analytical-band appearance after normal reload: full gray outer road, masked island, marker/kart at spawn, window controls and counts 6/99/3 observed without horizontal seams on 2026-10-19 at effective scale 0.72452831268311. Read-only getters verified all 96 band settings and explicit grass priority. This accepts the recorded appearance only; the separate supported-scale matrix remains pending.
- [ ] After safety passes, leave open/idle for 15 minutes, then drive for 10 minutes. Record before/after FPS, metrics/errors and visible hitches. Return from a long Alt-Tab without catch-up burst or automatic resume.

`activeFrameSeconds` sums valid elapsed values delivered to active `OnUpdate` callbacks; it is not an independent wall clock and need not equal the timer exactly. `simulatedSeconds` is `ticks × 1/60`, excluding dropped time. `callbackHz` is `frames / activeFrameSeconds` (zero before elapsed time), the cadence of accepted active callbacks; record separately sampled whole-client FPS independently. `maxElapsed` is whole-frame elapsed time, not measured addon CPU overhead. Stop preserves the residual accumulator for readback, and the inactive clock cannot advance. This one-kart experiment does not validate 32 sprites, multiplayer, production tracks or a lap engine.

## 3a. Optional bounded update-render timing

**Status: PARTIAL client evidence, 2026-10-19.** A stationary guarded diagnostic recorded 600 attempts/samples, zero invalid, total average 0.0264 ms / maximum 0.2111 ms including probe overhead. Ticks continued past the collection cap; stopped/reopen/disarm output retained values. Automated Start clicks were unsuccessful, so an existing guarded Start was called once after chat closed; this does not accept the mouse-click sequence below. Fresh unprofiled Start and full errors/handling/performance checks remain pending. [Exact conditions and output](../docs/evidence/2026-10-19-m0-stationary-profile.md).

Profiling is off by default. This sequence measures one short diagnostic window of up to 600 active updates, independent of the three approximately 60-second F1 drives. It neither automates driving nor requires another combat test. Run when the client is available, outside combat and after loading the installed source through normal startup or `/reload`; record actual runtime identity and any errors.

1. With driving stopped, open `/akart` if needed. Copy the unchanged six-line `/akart probe`, normal FPS/scale readbacks, and then run these commands separately:

```text
/dump type(debugprofilestop)
/akart perf
/akart perf on
```

2. Record the exact type and arming result. `perf on` checks one guarded finite, nonnegative clock read. If unavailable/invalid, record that result and leave profiling acceptance pending; do not replace the reader, call `debugprofilestart` or change client restrictions. Ordinary driving must remain usable. If armed, close chat and deliberately click **Start Test Drive**. Drive/steer normally for several seconds. Collection caps at 600 active updates, with three clock reads per attempted update (at most 1,800 plus the arming read); its elapsed duration varies with actual callback cadence. Completion must not print chat or stop the kart.
3. Stop normally with Escape or Stop, recording the actual stop reason. Only then run:

```text
/akart probe
/akart perf
```

4. Copy all three performance lines: armed/API/collection state, attempts/samples/invalid/limit, simulation/render/total averages/maxima in elapsed milliseconds, and scope. The output is three lines total: status/counters, timing aggregates, scope. If stopped before the cap, retain the partial sample as partial evidence. Invalid, backwards or throwing reads/validation consume attempts without inventing valid samples or stopping driving; `samples + invalid` should equal `attempts`, never exceeding 600. Zero means/maxima with no valid samples do not demonstrate zero cost.
5. Wait several seconds and repeat `/akart perf`. Close and reopen with `/akart` twice without Start; repeat `/akart perf`. The same aggregates/counters must remain frozen, and the window must reopen stopped. Then run:

```text
/akart perf off
/akart perf
```

6. Verify `armed=false` and the same retained stopped aggregates. Click Start deliberately for a fresh unprofiled drive, then stop and query `/akart perf`: the old diagnostic window must be cleared. Optionally arm a fresh window again, Start, stop early, and verify only that new window is reported. Record visible handling problems and explicit UI counts; do not infer responsiveness or unchanged allocation from a timing number alone.

- [x] Live function type and successful guarded arming recorded on build 70450. Missing/erroring-reader behavior is offline evidence only.
- [x] Three-line report captured with actual counters/elapsed means/maxima and unchanged six-line ordinary probe/counts.
- [x] Attempt budget/counters bounded at 600; no unsolicited collection/completion output observed; stationary simulation continued to tick 1959 across 7334 callbacks.
- [ ] Stopped/delayed/close-reopen output and disarm retention OBSERVED; fresh unprofiled Start/reset remains NOT RUN. Reload clearing the sample does not establish this Start behavior.
- [ ] Client errors, visible handling/hitch symptoms, build, FPS/scale and test conditions recorded; real live cost acceptance remains pending until measured.

These scoped elapsed milliseconds include clock/protection instrumentation overhead around `Loop.advance` and render/HUD work. They exclude preceding input/focus/combat guards, aggregate/report work and native GPU rendering; they are not exclusive addon CPU cost. The addon never resets the shared profiler timer with `debugprofilestart`. Backwards timestamps reject, but another addon's reset can leave plausible positive spans and evade detection. [CLIENT_API.md](../docs/CLIENT_API.md#optional-bounded-updaterender-timing) records the pinned build-70450 primary source and remaining runtime uncertainty. Offline tests cover invalid/throwing reads, cap behavior and unchanged deterministic driving; those do not constitute live profiler verification.

## 3b. Stopped/open idle stability

**Status: PASS for this scoped idle check, 2026-10-19 15:29:48.901–15:45:06.499 CEST.** Completed 917.598 wall-clock seconds (917.608 monotonic) without agent input. Endpoint probe retained all counters/tick 852, counts 6/99/3, inactivity and profiling off; effective scale stayed 0.72452831268311. Before/after FPS points were 206.00857543945 / 198.3470916748. Sampled road/controls stayed readable without an observed error dialog; no continuous hitch/taint measurement was made. Normal close/reopen retained the sample; final hidden/inactive/profiling-off readback passed. The earlier attempt was interrupted by confirmed owner use and remains an interruption, not a failure. [Exact evidence](../docs/evidence/2026-10-19-m0-idle.md). This does not replace the ten-minute human drive, full focus matrix, supported-scale matrix or memory/CPU measurement; the combined section 3 checkbox stays pending.

1. Confirm the returned WoW window, current installed source/build and an inactive kart. Open `/akart` without Start; keep profiling off. Record an independent start timestamp, `/akart probe`, `/dump GetFramerate()` and `/dump UIParent:GetEffectiveScale()`. Keep other addons/settings unchanged.
2. Leave the kart stopped/open for 15 measured minutes. Do not arm input, drive, change scale, generate combat, or add any per-update diagnostic. If input occurs or the client closes/hides/disconnects, record the actual interval and interruption rather than claiming a completed run.
3. Record the end timestamp, the same probe/FPS/scale readbacks and visible errors/hitches. Counts, stopped tick and timing must remain frozen; the road/controls must remain readable. A start/end FPS pair consists of two whole-client observations, not sustained FPS or exclusive addon cost. Leave memory/CPU checks NOT RUN unless separately measured.
4. Close/reopen normally, repeat the stopped probe, then leave the window hidden and controls inactive. Record exact elapsed duration, conditions and results in PROGRESS. Keep unsupported/unavailable checks pending.

## 3c. One supported-scale comparison — prepared independent M0 task

**Status: INCOMPLETE / REVIEW NEEDED, 2026-10-19 16:19–16:27 CEST.** The normal Use UI Scale control was found unchecked at stored 100%. Apply confirmations expired before acceptance; the changed-scale renderer/probe was not verified. Original preferences/CVars returned, but effective scale changed from 0.72452831268311 to 0.71111112833023. All clock counters and counts 6/99/3 stayed frozen, final hidden/inactive/profiling off. Further scale changes stopped for review under step 4. [Exact evidence](../docs/evidence/2026-10-19-m0-scale.md). This is not a scale-matrix or M0 pass.

1. Inspect the normal client Options for an available UI-scale control. Record its actual label, enabled/automatic state, current displayed value and supported range/steps. Do not assume a menu path or that 0.75/1.0/1.25 are supported. If no normal control is available, record UNAVAILABLE and make no scale change.
2. Open `/akart` without Start. Record a timestamp, build/source identity, road/controls appearance, `/akart probe` and these read-only values:

```text
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump UIParent:GetEffectiveScale()
```

3. Choose one different supported setting through that normal control, apply it normally and record the actual displayed setting, the same readbacks/probe and appearance. If the client presents a timed acceptance dialog, verify acceptance before collecting the changed-setting sample; automatic reversion is not a completed comparison. Do not repeat setting changes when the tool roundtrip cannot meet that deadline; leave the probe pending. Check full road/island/marker/kart visibility, horizontal seams, clipping, text and access to Start/Stop/Close/Print Probe. Keep capture inactive; the existing clock/state and explicit counts must stay unchanged. Effective scale is a measured value, not the nominal slider value. If a normal reload is required to apply, record it and collect a fresh inactive baseline; do not claim the old clock survived reload.
4. Restore the exact original control value and automatic/enabled state through the normal UI, apply normally and verify the original CVar values and effective scale return. Do not use arbitrary `SetCVar` writes to reach unsupported values. If restoration fails, record it and stop for review. Close/reopen once to check readability/inactivity/counts, then finish hidden/inactive with profiling off.
5. Transcribe sanitized results into the table and PROGRESS, including both changed and restored readbacks and any interruption. An unavailable setting remains pending, not a failure or a pass. Whole-client FPS, if sampled separately, is only a point observation.

| Point | Normal control value/state | uiScale / useUiScale | Effective scale | Probe/canvas/readability | Status |
|---|---|---|---|---|---|
| Original baseline | Unchecked; stored 100% | 1.000000 / 0 | 0.72452831268311 | Tick 852, counts 6/99/3, full canvas/controls readable | OBSERVED |
| One supported alternative | Checked; 100%, Apply then timed reversion | NOT READ during temporary state | NOT READ | Kart hidden; changed-scale renderer NOT RUN | INCOMPLETE |
| Restored original | Unchecked; stored 100% | 1.000000 / 0 | 0.71111112833023 | All counters/counts frozen; hidden/inactive/profiling off | Preferences restored; effective-scale criterion unmet, REVIEW NEEDED |

## 3d. Read-only geometry review — deferred M0 check

**Status: PREPARED, NOT RUN; deferred under ADR 0007.** This review does not block local M1 work. Review the scale mismatch before further setting changes. At unchanged settings, record timestamp and actual build, then run these lines individually. Each optional call is type-checked and protected; its returned table begins with the `pcall` success boolean. Record unavailable/error results; if reporting encounters restricted or secret values, stop that read without coercion or a fallback access path.

```text
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump type(GetPhysicalScreenSize)=="function" and {pcall(GetPhysicalScreenSize)} or "unavailable"
/dump type(GetDefaultScale)=="function" and {pcall(GetDefaultScale)} or "unavailable"
/dump UIParent and type(UIParent.GetWidth)=="function" and {pcall(UIParent.GetWidth,UIParent)} or "unavailable", UIParent and type(UIParent.GetHeight)=="function" and {pcall(UIParent.GetHeight,UIParent)} or "unavailable"
/dump UIParent and type(UIParent.GetScale)=="function" and {pcall(UIParent.GetScale,UIParent)} or "unavailable", UIParent and type(UIParent.GetEffectiveScale)=="function" and {pcall(UIParent.GetEffectiveScale,UIParent)} or "unavailable"
```

Keep the kart hidden/inactive and profiling off; do not change settings, reload, Start or supply character input. Compare only observed current dimensions with the pinned source described in [CLIENT_API.md](../docs/CLIENT_API.md). The former physical/window dimensions were not measured, so a numerical 1060/1080-height relationship cannot establish their history or explain the earlier scale. Record the review outcome and one next task; keep the accepted-alternative comparison pending.

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
