# M0 stationary profiler and renderer observations — 2026-10-19

The stationary profiler observations were made approximately 08:37–08:46 CEST (Europe/Oslo); the initial transcription was prepared at 08:48:49 CEST, failed renderer follow-up added at 08:56:13 CEST and rollback confirmed at approximately 08:58 CEST. The owner authorized unattended checks using the opened WoW client while unavailable for manual testing. This evidence describes a stationary diagnostic window, not a human handling trial or the third F1 drive. **M0 remains open.** Personal screenshots, character details and chat are excluded.

## Source, environment and stopped baseline

The baseline used source commit `38faab2` (`feat: add bounded opt-in performance probe`). A read-only SHA-256 comparison confirmed all ten installed addon files matched that source. `python scripts/validate_project.py` returned `STATIC PASS: 29 expected paths; TOC order; protocol docs; local links; network ledger; no Lua runtime executed.` These checks preceded the renderer follow-up described below; they are not post-fix installation evidence.

Normal client startup loaded the analytical-band road and optional profiler. The gray outer ellipse, green island, marker and orange kart were visible. Thin horizontal green seams were visible between some road bands. The character remained a stationary ghost; no avatar movement, combat, resurrection or peer-message traffic was automated.

```text
GetBuildInfo(): 1.60.1 70450 Oct 15 2026 16001
selectedTOC=Camelot
GetFramerate(): 226.84307861328
uiScale=1.000000 useUiScale=0
UIParent:GetEffectiveScale(): 0.71111112833023
capture resolution: 1920x1080
```

The FPS number is one whole-client stopped sample. Effective scale was read separately; it must not be inferred from the two CVar values. This baseline does not establish sustained FPS, exclusive addon CPU cost or other-scale appearance.

The initial `/akart perf` report was unarmed, with `api=true`, `state=not-started`, zero attempts/samples/invalid readings and limit 600. Its zero timing aggregates represented an absent sample. `/akart perf on` successfully validated its guarded timer read and armed the next Start.

## Stationary diagnostic window

Automated clicks did not start capture. A direct `/run` invocation of `AzerothKart.UI.Start()` was refused because chat had text focus. A single guarded `C_Timer.After(0.5, ...)` invocation subsequently called the existing `UI.Start` after chat closed. The normal Start guards remained unchanged; no focus/combat guard was overridden and no source was changed for this experiment. No driving keys were supplied. Enter ended capture with the actual reason `Other key released controls`.

The stopped HUD showed speed 0, tick 1959 and `Sample 32.7s`. The ordinary probe was:

```text
M0 version=1.60.1 build=70450 interface=16001 selectedTOC=Camelot focusApi=false
frames=7334 ticks=1959 maxElapsed=0.0700 droppedSeconds=0.0000 hitchFrames=0 accumulator=0.00200
activeFrameSeconds=32.6520 simulatedSeconds=32.6500 callbackHz=224.61
UI frames=6 textures=99 fontStrings=3 active=false stopReason=Other key released controls
eventRegistrationFailures=none
combatApi=true textFocusApi=true keyboardApi=true propagationApi=true
```

The stopped tick matches the HUD, and printed timing accounts for the residual: `1959 / 60 = 32.6500`; `32.6500 + 0.00200 = 32.6520`. Callback cadence is `7334 / 32.6520`, rounded to 224.61 Hz. These are delivered active callback metrics, not an independent timer or addon CPU measurement.

The explicit performance report was:

```text
perf armed=true api=true state=complete attempts=600 samples=600 invalid=0 limit=600
perf elapsedMs simAvg=0.0119 simMax=0.0363 renderAvg=0.0145 renderMax=0.2027 totalAvg=0.0264 totalMax=0.2111
perf scope=Loop.advance+render+HUD includesProbeOverhead=true exclusiveCPU=false
```

Collection reached its 600-attempt cap with 600 valid readings and no invalid attempts. It did not stop the stationary simulation at that cap. These aggregates cover the first 600 eligible callbacks only; they do not cover the whole 32.652-second active interval or describe cost per 60 Hz simulation tick. The three reported phase averages are consistent at printed precision: `0.0119 + 0.0145 = 0.0264` ms.

Delayed queries retained the same stopped aggregates. A diagnostic toggle close confirmed the window hidden; reopening retained the complete performance report and stayed stopped. `/akart perf off` then produced `armed=false` while preserving attempts, samples, invalid count, state and all elapsed aggregates. A fresh unprofiled Start/reset was not part of this recorded sequence.

## Renderer seam diagnosis

Live type checks found both `SetTexelSnappingBias` and `SetSnapToPixelGrid` available as functions. A guarded one-off preview applied bias `0` and snap `false` to the 99 existing canvas textures and reported 99 successful setter pairs. The visible horizontal seams disappeared in the subsequent view at the recorded effective scale. No UI objects or geometry were added by that preview; its changes were local to the current client session.

The matching build's primary generated contract is in the parent-workspace file `research/upstream/wow-ui-source-forever-70450/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua`: `SetSnapToPixelGrid(bool)` at line 555 and `SetTexelSnappingBias(normalizedValue)` at line 594. Both declare `SecretArguments = "AllowedWhenUntainted"`; the preview used ordinary literal arguments. `Blizzard_SharedXML/NineSlice.lua:218–223` in that same pinned source uses bias `0` followed by snap `false` in `NineSliceUtil.DisableSharpening`. Its `version.txt` is `1.60.1.70450`. Runtime availability and the visible preview result are separate evidence from that source contract.

### Creation-time follow-up failed — promotion blocked

A source follow-up attempted those guarded literal setters on only the 96 road bands during creation, retaining the original geometry and texture counts. The complete Lua 5.1/5.4 suites passed: eight tests and 16 parsed files in each runtime, including the 92,853-point geometry regression and missing/throwing API fallback cases. Structural validation passed 29 paths, and whitespace checks passed. Those offline results did not predict actual client appearance.

| Attempt | Installed change and evidence | Actual normal-reload result |
|---|---|---|
| Approximately 08:52 CEST | Set bias/snap at band creation before color/size/anchor setup; manifest `artifacts/AzerothKart/20261019-085011-749932/install.json` in the parent workspace. Independent read-only SHA-256 comparison at 08:52:53 CEST confirmed all ten installed addon files matched that tested source. | All road bands were hidden. Repeating the one-off preview on all 99 canvas textures printed `AK post-init 99` and restored the road. |
| Approximately 08:55 CEST | Move those setters after band color/size/anchor setup; manifest `artifacts/AzerothKart/20261019-085434-186481/install.json`. | All road bands were again hidden after reload. No preview was run after this second failure; source/test restoration, verified installation and the third normal reload followed directly. |

**Root cause unknown.** The second attempt did not confirm an initialization-order explanation. Source initialization affected 96 road bands, whereas the successful later preview affected all 99 canvas textures; both affected population and timing differ. The generated signatures and successful calls do not guarantee identical rendering across those different conditions. No specific public API contract violation, secret-value bypass or general client API contradiction has been established.

The rendering behavior uncertainty blocks promoting either source adjustment and requires review before another implementation is selected. Only this session's `UI.lua` and `tests/test_ui.lua` changes were restored to their `38faab2` content. Rollback manifest `artifacts/AzerothKart/20261019-085619-881590/install.json` records the verified UI.lua replacement and all ten matching source hashes. An independent read-only comparison at **08:58:33 CEST** confirmed all ten installed files matched the restored source; `git diff -- addon/AzerothKart/UI.lua tests/test_ui.lua` was empty. The original source has the observed thin seams, so rollback is not a seam fix. The earlier profiler facts above remain valid for the original `38faab2` source.

### Final restored-source reload

A third normal `/reload`, submitted at approximately 08:57 CEST, completed. Opening the window at approximately 08:58 showed the original gray annulus, green island, marker and kart, without applying another snapping preview. Effective scale was not reread after these reloads; the `0.71111112833023` value belongs to the initial stationary baseline only. The final ordinary report returned build `1.60.1/70450`, interface `16001`, selected TOC `Camelot`, `focusApi=false`, zero frames/ticks/timing/drop/hitch/remainder, counts 6/99/3, `active=false`, `stopReason=Not started`, no event-registration failures and all four required API capabilities true.

The final performance report was unarmed with `api=true`, `state=not-started`, zero attempts/samples/invalid readings, limit 600, zero elapsed aggregates and the unchanged explicit scope. These zero values describe a fresh inactive post-reload session, not zero execution cost. The window was then hidden through its normal toggle; final readback confirmed `active=false`, window shown `false` and `performanceEnabled=false`. No further input was sent.

## Scope and remaining acceptance

This session establishes actual profiler availability, guarded arming, a complete bounded stationary sample, three-line performance output, unchanged six-line ordinary probe/counts, and stopped retention/disarming under the recorded conditions. It also establishes the analytical-band renderer loaded and a one-off pixel-snapping preview removed the observed seams at one scale. The attempted permanent source adjustments failed after reload; no durable seam fix is accepted.

The elapsed spans include probe overhead around `Loop.advance` and render/HUD work. They omit preceding input/focus guards, final aggregation/report formatting and native GPU work; another addon's shared-timer reset can sometimes evade backwards-span rejection. No exclusive CPU/GPU attribution, percentile, sustained-FPS or whole-frame benchmark follows from these averages/maxima. Explicit counts cover the UI module's own allocations, not client/template internals or memory stability.

Human handling, the third externally timed F1 drive, full focus/lifecycle/taint acceptance, supported-scale matrix, long-session performance, isolated persistence and two-client transport remain pending. The owner's deferred combat checks and skipped simultaneous W/Up test were not repeated. No full M0 gate is marked passed.
