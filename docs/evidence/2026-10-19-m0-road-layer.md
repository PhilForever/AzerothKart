# M0 road-layer isolation — 2026-10-19

Initial isolation was observed approximately 09:08–09:12 CEST (Europe/Oslo), followed by an independent comparison at approximately 09:14–09:16. The initial transcription was prepared at 09:12:51 and the source/install follow-up added at 09:20:08 CEST. The owner instructed continuing after the [earlier renderer review stop](2026-10-19-m0-stationary-profile.md), authorizing diagnosis of that discrepancy. These are stopped-window visual experiments on existing addon textures. **M0 remains open.** Personal screenshots, character information and chat are excluded.

## Starting conditions

The canonical source was commit `ce1b78c`; its addon implementation was unchanged from `38faab2`, with no experimental snapping setters retained. The existing stopped window was opened. The observed capture was 1920×1080. A baseline readback gave active `false` and effective scale **`0.72452831268311`**, measured during this session. It differs from the earlier session's `0.71111112833023`; neither value should be substituted for the other or inferred from CVars.

The 99 existing canvas textures were inventoried by actual draw layer:

| Layer | Texture count | Source role |
|---|---:|---|
| `BACKGROUND` | 65 | One full-canvas grass texture and 64 gray outer bands |
| `BORDER` | 32 | Green island bands |
| `ARTWORK` | 1 | Marker |
| `OVERLAY` | 1 | Kart |

No drive was started. No driving keys, avatar movement, combat or recovery actions, peer messages, UI-object creation or source changes were part of these observations. This experiment does not measure timing, handling, taint or sustained performance.

## Controlled observations

The transcript below records operations and returned values supplied by the live operator. Exact input command strings are not reconstructed from those summaries.

| Step | Operation and readback | Visible result |
|---|---|---|
| 1 | Select existing textures with height below 8; apply texel snapping bias `0` and snap-to-grid `false`. The operation identified 96 bands (`AK bands 96`). Grass, marker and kart were not changed. | The gray road vanished while the window remained stopped. This reproduces the failure after creation, without another source install or startup setter. |
| 2 | Identify the unique full-canvas grass texture by height above 400; count 1. `GetDrawLayer()` returned `BACKGROUND`, sublevel `0`. Hide only this grass texture. | Gray road and green island appeared against the window backdrop. |
| 3 | Show that same grass texture again, leaving every band's settings unchanged. | The road vanished again. |
| 4 | Read that grass texture's snapping state: `GetTexelSnappingBias()` returned `0.30000001192093`; `IsSnappingToPixelGrid()` returned `true`. | Readback only. |
| 5 | Change only the grass texture to bias `0` and snap `false`. Both `pcall` invocations succeeded; subsequent state readback was bias `0`, snap `false` (`AK grass now 0 false`). | Road appearance returned without visible horizontal seams in the observed view. |

Marker and kart snapping settings were untouched throughout. The 96 selected bands and one subsequently changed grass texture account for 97 textures; this recovery did not require changing all 99 canvas textures.

## What the experiment establishes

The road disappearance can occur when snapping settings change on the existing bands after initialization; it is not confined to creation-time setter ordering. Hiding/showing only the grass texture changes whether the gray road is visible under that configuration. Matching only the grass snapping state to the bands restores the observed road without touching marker or kart.

These observations narrow the problem to a grass/band rendering interaction under the tested state and scale. They do not establish native renderer batching rules, a particular GPU cause, a general ordering guarantee or a public API contract violation. The original grass and gray bands share `BACKGROUND` at the source's default sublevel; the independent comparison below tests an explicit grass priority.

The pinned build-70450 generated contract exposes `GetDrawLayer()` and `SetDrawLayer(layer, sublevel)` in `SimpleRegionAPIDocumentation.lua:24,147`; `GetTexelSnappingBias()` and `IsSnappingToPixelGrid()` are in `SimpleTextureBaseAPIDocumentation.lua:206,347`. `GetRegions()` in `SimpleFrameAPIDocumentation.lua:577` returns regions without a documented enumeration-order guarantee. These files are under the parent-workspace `research/upstream/wow-ui-source-forever-70450/Interface/AddOns/Blizzard_APIDocumentationGenerated/` tree. Source signatures are separate from the actual visual evidence above.

## Independent explicit grass-priority comparison

At approximately 09:14–09:16 CEST a normal `/reload` restored the original source and removed the earlier texture mutations. The gray road was visible with its horizontal seams. A fresh baseline readback gave active `false` and effective scale **`0.71111112833023`** (`AK fresh false 0.71111112833023`). This is a new scale reading for this comparison, distinct from the first isolation's value.

Only the unique grass texture's draw priority was changed through a guarded `SetDrawLayer("BACKGROUND", -1)` call. Its call succeeded (`AK lower true`), and a separate `GetDrawLayer()` readback gave `BACKGROUND`, `-1` (`AK layer BACKGROUND -1`). The road remained visible, with seams still present. Grass snapping settings were not changed in this independent session.

The same operation setting bias `0`/snap `false` on only the 96 bands was then repeated (`AK bands 96`). The gray road and island remained visible, and the seams were absent in the observed view. Marker and kart were untouched. This establishes a working explicit-grass-priority plus band-snapping combination after initialization at the freshly recorded scale; it does not prove native batching mechanics.

## Focused source, tests and installation

The candidate sets only the grass texture's draw layer to `BACKGROUND,-1` during `UI.Create`, leaving the outer bands at default `BACKGROUND,0`. On each of the 96 bands, after color/size/anchor setup, it guards the optional snapping setter types and uses `pcall` for literal bias `0` and snap `false`. These operations occur only during construction; geometry, physics, input and the explicit 6/99/3 object budget are unchanged. Grass snapping and marker/kart settings remain unchanged.

`tests/test_ui.lua` first added assertions for explicit grass priority, 192 snapping calls on the 96 bands, setup after geometry, unchanged grass snapping, missing/throwing optional setter fallback, and no configuration calls during updates/reopening. Before the source change, `python scripts/test_lua.py --runtime lua51` failed at the new road-band snapping assertion, as expected; 16 files parsed and the other seven tests passed. After implementation, the complete suites passed in both actual embedded Lua 5.1 and 5.4 runtimes: 16 files parsed/eight tests each, including the unchanged 92,853-point geometry check. `python scripts/validate_project.py` passed 29 paths and whitespace checks passed. These are offline assertions, not client appearance acceptance.

Only `UI.lua` was installed after preserving and verifying the prior complete addon. Parent-workspace manifest `artifacts/AzerothKart/20261019-091849-478523/install.json` records the verified replacement and all ten matching source hashes. An independent read-only SHA-256 comparison at **09:20:08 CEST** confirmed all ten installed addon files matched the tested candidate source. Read-only code/test review found no additional blocker; no unrelated files were changed by that review.

**Historical status at 09:20:** a normal `/reload` was submitted at approximately 09:19 CEST, but resulting live appearance and layer/snapping/probe readbacks were not yet recorded. The controlled post-resume check below supersedes that pending startup status. Other-scale appearance, performance, full input/lifecycle/taint acceptance and the full M0 gate remain pending.

## Quota-resume observations, approximately 13:54–13:56 CEST

Execution resumed after quota interruption when the owner instructed continuing. The candidate UI/test changes and this evidence file persisted. An independent read-only SHA-256 comparison at **13:54:48 CEST** again confirmed all ten installed addon files matched the candidate source. A read-only diff review found the same creation-only grass/band changes and regression fixtures, without additional source changes.

The owner's cropped zeroed-probe image from the interrupted check is consistent with build 70450, counts 6/99/3 and a scale readback near 0.711111, but does not show the full canvas or establish handling/startup appearance acceptance. That earlier image is not a new scale readback for the resumed view. The subsequent actual whole-canvas view showed the gray road, island, marker and a displaced/rotated kart, with no horizontal seams visible in that view. The addon was already stopped; its HUD showed speed 0, tick 1237 and `Sample 20.6s`.

```text
M0 version=1.60.1 build=70450 interface=16001 selectedTOC=Camelot focusApi=false
frames=4942 ticks=1237 maxElapsed=0.0600 droppedSeconds=0.0000 hitchFrames=0 accumulator=0.01333
activeFrameSeconds=20.6300 simulatedSeconds=20.6167 callbackHz=239.55
UI frames=6 textures=99 fontStrings=3 active=false stopReason=Mouse click released controls
eventRegistrationFailures=none
combatApi=true textFocusApi=true keyboardApi=true propagationApi=true
```

The stopped HUD tick matched that existing probe. The sample's origin, input tape and independent duration are unknown; it was not a new drive performed by the unattended check and does not count as the third F1 drive or a handling trial. Its printed timing is consistent within rounding: `1237 / 60 ≈ 20.6167`, plus remainder `0.01333 ≈ 20.6300`. `maxElapsed` is a delivered frame interval, not measured addon CPU time.

The performance report remained unarmed, with API present, `state=not-started`, zero attempts/samples/invalid readings, limit 600 and all elapsed aggregates zero. Those values indicate no profiler sample in this session, not zero cost. The earlier 600-sample performance evidence belongs to the separate stationary window.

**Historical status at the 13:57:09 CEST transcription:** a newly controlled reload/readback was still pending; the following check supersedes that status. Supported-scale coverage, sustained performance, human handling and full M0 acceptance remain open.

## Controlled installed-source startup, approximately 13:57–14:02 CEST

A fresh normal `/reload` completed with the addon hidden. The window was then opened through its ordinary toggle; only reporting and read-only scale/layer/snapping diagnostics followed. No texture mutation or live preview was applied after this reload. The whole gray road, green island, marker, kart and window controls were visible, with no horizontal seams apparent in the observed view. A new effective-scale readback returned **`0.72452831268311`**.

The fresh ordinary probe reported:

```text
M0 version=1.60.1 build=70450 interface=16001 selectedTOC=Camelot focusApi=false
frames=0 ticks=0 maxElapsed=0.0000 droppedSeconds=0.0000 hitchFrames=0 accumulator=0.00000
activeFrameSeconds=0.0000 simulatedSeconds=0.0000 callbackHz=0.00
UI frames=6 textures=99 fontStrings=3 active=false stopReason=Not started
eventRegistrationFailures=none
combatApi=true textFocusApi=true keyboardApi=true propagationApi=true
```

Read-only inspection of the existing band textures found **96** with height below 8, texel snapping bias `0` and snap-to-grid `false` (`AK bands verified 96`). The unique grass texture read back `BACKGROUND,-1`; its snapping state remained the client's default bias `0.30000001192093`, snap `true`. Thus the installed creation-only configuration was present after normal reload, without matching grass snapping or altering marker/kart settings through a preview.

Normal close/reopen/close toggles retained inactive state and counts (`AK reopened false 6 99 3`). The final explicit readback was `active=false`, window shown `false`, profiling enabled `false` (`AK end false false false`). No active drive, avatar keys, synthetic combat or peer traffic occurred during this controlled sequence.

The complete Lua suites were rerun after quota resume and passed again in Lua 5.1 and 5.4: 16 parsed files/eight tests each. Structural validation passed 29 paths and whitespace checks passed. Native `lua tests/run.lua` was **NOT RUN** because `lua`/`luajit`/`luac` were absent; the embedded runtimes executed the suite. The earlier RED assertion and independent ten-file hash comparisons remain recorded above.

**Scoped result:** the explicit grass sublevel plus 96-band snapping fix is verified at normal startup on build 70450 under these recorded conditions. This supersedes the previous promotion blocker for this candidate; native renderer batching mechanics are still not established. No supported-scale matrix, sustained FPS/CPU/GPU, full taint/input lifecycle, human handling or full M0 acceptance follows from this stopped-window check.

**Next executable task:** measure one 15-minute stopped/open idle window, with start/end timestamps, whole-client FPS samples, ordinary probe/object counts and visible errors/appearance. Keep capture inactive and profiling off. That task has not been run in this evidence and does not require gameplay or another combat test.
