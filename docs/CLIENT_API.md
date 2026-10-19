# Forever client identity and API probes

**Live-client status: PARTIAL, updated 2026-10-19 at approximately 08:58 CEST.** The installed client reported version `1.60.1`, build `70450`, interface `16001`, `WOW_PROJECT_ID=18` and selected TOC `Camelot`; Azeroth Kart `0.0.1` was enabled and loaded. Basic rendering, Start and several idle release routes were observed; two human near-minute drives supplied movement/rotation and stopped timing evidence. A later stationary profiler window supplied 600 valid scoped samples. Renderer seams and failed creation-time snapping adjustments remain an unresolved API-behavior investigation; the adjustments were removed and the original road returned after reload. The owner confirmed actual combat closes an active drive and leaves WoW controls working. Full timing, held-key release, repeated-event/taint auditing, scaling/sustained performance and complete M0 acceptance remain pending. See the [initial evidence](evidence/2026-10-18-m0-client.md), [two driving samples](evidence/2026-10-19-m0-client.md) and [stationary profile/renderer investigation](evidence/2026-10-19-m0-stationary-profile.md).

The earlier read-only disk scan found `_classic_beta_\WowB.exe` version `1.60.1.70450`, `.flavor.info` value `wow_classic_beta` and no running `Wow*` process **at that initial scan**. A live client was available for the later observations above. Runtime readbacks, rather than the folder or executable alone, confirm the tested interface and TOC selection.

## Exact runtime identity checks

On 2026-10-19 the updated source was installed with a verified prior-addon backup, then loaded through normal `/reload`. Live readbacks again showed `1.60.1`, build `70450`, interface `16001`, selected TOC `Camelot`, the new zeroed timing fields and UI counts 6/99/3. See [the baseline and later two drives](evidence/2026-10-19-m0-client.md); those observations do not complete the remaining timing or retained-note checks. A shell process scan missed the available client; the desktop app/window inventory confirmed it. Use that inventory before declaring a requested live session unavailable. The 07:32 no-client observation is historical: the owner's later opened-client authorization enabled the [stationary checks](evidence/2026-10-19-m0-stationary-profile.md). Following the rejected renderer adjustments, a final normal reload restored the original source's gray annulus, island, marker and kart at approximately 08:58 CEST. An independent read-only comparison at 08:58:33 CEST confirmed all ten installed files matched the restored `38faab2` source. The client was left with capture inactive, window hidden and profiling off.

Enter each line separately in chat on the installed Forever client. Copy output verbatim; do not substitute a build inferred from a folder name. These `/dump` commands read data and do not start a drive or send network traffic.

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
/dump WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC
/dump type(C_AddOns), type(C_AddOns and C_AddOns.GetAddOnMetadata)
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "Interface")
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "Version")
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "X-AzerothKart-TOC")
```

The final value should identify loaded metadata as `base` or `Camelot`; record what is returned, including nil. If the modern metadata API is absent, record that absence and inspect the AddOns list; do not guess TOC selection. Record whether the addon is enabled, any incompatibility reason and displayed version. Successful load does not establish keyboard safety.

## Exact capability checks

Run before driving, out of combat. `/akart` must have created its window for method checks. Each `type` check may legitimately return `nil`.

```text
/dump type(CreateFrame), type(InCombatLockdown), type(GetTime), type(GetFramerate)
/dump type(GetCurrentKeyBoardFocus), type(ChatEdit_GetActiveWindow), type(IsGameWindowFocused)
/dump type(IsWindowFocused)
/dump type(AzerothKartMainWindow and AzerothKartMainWindow.EnableKeyboard)
/dump type(AzerothKartMainWindow and AzerothKartMainWindow.SetPropagateKeyboardInput)
/dump type(AzerothKart and AzerothKart.UI and AzerothKart.UI.kart and AzerothKart.UI.kart.SetRotation)
/dump type(C_ChatInfo), type(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix)
/dump type(C_ChatInfo and C_ChatInfo.SendAddonMessage), type(C_ChatInfo and C_ChatInfo.SendAddonMessageLogged)
/dump type(Enum and Enum.SendAddonMessageResult)
/akart probe
```

The prototype reports build/interface/selected TOC, input capabilities and unavailable registered events. Capture must remain disabled if a required input capability is missing. Every mouse-down while driving releases capture, including clicks inside the canvas and on overlapping UI; this does not depend on a guessed mouse-over focus owner. On the tested build, Start successfully captured input and advanced ticks; clicking Stop released through the earlier global mouse-down event. Held-input and overlapping-UI cases remain pending.

Both `IsGameWindowFocused` and `IsWindowFocused` returned `nil` on this build. Idle Alt-Tab released through the unknown/Alt-key route, but Alt-Tab with throttle held and released outside the game remains unverified. Do not use the unrelated unit-focus event as an application-focus substitute. An API returning `function` is availability evidence only: semantics, restrictions and complete release behavior still require the manual matrix.

Do not use `/dump` to call `SetPropagateKeyboardInput` or other mutating input methods. The addon guards its own propagation setter out of combat; test through deliberate Start/Stop and combat transitions. Never bypass these guards.

## Timing and persistence readback

```text
/dump GetFramerate()
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump UIParent:GetEffectiveScale()
/dump AzerothKartDB and AzerothKartDB.schemaVersion
/akart probe
```

Record baseline and stopped-run output as described in [FEASIBILITY.md](FEASIBILITY.md). Starting chat while driving is a focus-loss test and stops capture, so collect metrics after Escape. The probe adds `activeFrameSeconds` (sum of valid active `OnUpdate` elapsed), `simulatedSeconds` (`ticks * 1/60`) and `callbackHz` (`frames / activeFrameSeconds`, zero before elapsed time). These require no new client APIs; they are not an independent wall-clock duration, separately sampled whole-client FPS or addon CPU measurement. `maxElapsed` is a callback interval, not addon CPU time.

After stopping, verify `activeFrameSeconds ≈ simulatedSeconds + droppedSeconds + accumulator` within 0.0002 seconds at the current printed precision. The stopped HUD must immediately show the same tick as the probe, with `Sample` showing active callback seconds. A second probe several seconds later and a close/reopen must preserve the timing values and tick; a deliberate Start resets the sample and HUD to zero. The zeroed post-reload baseline, two matching human-drive samples and a stationary accounting sample were observed on 2026-10-19; the complete three-drive/external-timer protocol remains **PENDING**. The stationary session separately read `uiScale=1`, `useUiScale=0`, effective scale `0.71111112833023` at 1920×1080 and one stopped whole-client FPS value `226.84307861328`; do not infer effective scale from the CVars or sustained performance from that FPS point.

Object counts cover the UI module's explicit allocations, excluding the bootstrap event frame and template internals. Follow [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md) for the temporary persistence sentinel; schema readback alone cannot prove a save occurred.

## Optional bounded update/render timing

The existing six-line `/akart probe` output is unchanged. `/akart perf` is a separate, explicit three-line report. Profiling is off by default and is not saved as a setting. Run setup commands while stopped and outside combat; close chat before clicking Start:

```text
/dump type(debugprofilestop)
/akart perf on
```

`perf on` makes one guarded `debugprofilestop` read and requires a finite nonnegative numeric result before arming the next deliberate Start. An unavailable/throwing/invalid reader leaves profiling off and reports that result; driving remains available. A successful fresh Start creates new scalar aggregates. A profiled drive samples at most 600 active updates, using three reads per attempted update: before `Loop.advance`, after it, and after render/HUD work. This caps sampling at 1,800 reads per window, plus the one arming read; repeat arming commands each perform their own check. Invalid, backwards or throwing reads/validation consume the same attempt budget without aborting simulation or producing valid zero-cost samples. Collection stops silently at the cap while driving continues.

After stopping the drive normally, run:

```text
/akart perf
/akart perf off
/akart perf
```

The report gives armed/API status, collection state, attempts, valid samples, invalid attempts and limit, followed by derived average/maximum simulation, render and total elapsed milliseconds, then scope. Before a sample or with zero valid samples, printed zero aggregates are not evidence of zero cost. Stop and close/reopen retain the sample; `perf off` disarms future collection and retains the stopped values until the next Start. Configuration changes are refused while a drive is active. See [the precise manual sequence](../tests/MANUAL_CLIENT_CHECKLIST.md#3a-optional-bounded-update-render-timing) for capture and reset checks.

The locally pinned build-70450 primary API documentation defines `debugprofilestop` as elapsed milliseconds relative to the shared `debugprofilestart` reference. It is at parent-workspace path `research/upstream/wow-ui-source-forever-70450/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:528–539`, with `version.txt` value `1.60.1.70450`; [pinned mirror source](https://github.com/Gethe/wow-ui-source/blob/172a387e3ab85b26e6640d3058d5ec1e6ccd4c63/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua#L528-L539), commit `172a387e3ab85b26e6640d3058d5ec1e6ccd4c63`. This contract is source evidence; actual runtime arming and samples are recorded separately below.

The addon never calls `debugprofilestart`. It rejects backwards spans, but another addon's shared-timer reset can sometimes leave plausible positive deltas and evade that check. Measurements include clock/protection instrumentation overhead; their scope is `Loop.advance` plus render/HUD. They exclude preceding input/focus/combat guards, aggregation/report work and native GPU work, and do not establish exclusive addon CPU cost or whole-client FPS. No per-frame output, sample arrays or UI-object allocations are added.

**Live stationary window, approximately 08:37–08:46 CEST:** initial profiling was off, guarded arming succeeded, and collection completed with `attempts=600 samples=600 invalid=0 limit=600`. Simulation average/max was `0.0119/0.0363` ms; render/HUD `0.0145/0.2027` ms; total `0.0264/0.2111` ms. Enter stopped the stationary session at 1959 ticks/32.6520 active seconds, counts 6/99/3. Delayed close/reopen queries retained the aggregates; off disarmed while retaining them. The aggregates cover only the first 600 callbacks, not the whole active interval or a human drive. Full sustained-performance acceptance stays open. [Exact reports, start conditions and limits](evidence/2026-10-19-m0-stationary-profile.md).

## Texture snapping investigation — review required

The analytical-band road loaded with thin horizontal seams at the measured effective scale. Live type checks found `SetTexelSnappingBias` and `SetSnapToPixelGrid` functions. A guarded one-off application of literal bias `0`/snap `false` to all 99 existing canvas textures reported 99 successful setter pairs and removed the seams. This does not establish equivalent construction-time behavior or other-scale appearance.

The build-70450 primary source `SimpleTextureBaseAPIDocumentation.lua:555` defines `SetSnapToPixelGrid(snap: bool)` and `:594` defines `SetTexelSnappingBias(bias: normalizedValue)`, both with `SecretArguments="AllowedWhenUntainted"`. `Blizzard_SharedXML/NineSlice.lua:218–223` uses bias `0` followed by snap `false` in `NineSliceUtil.DisableSharpening`. These files are under the same pinned parent-workspace `research/upstream/wow-ui-source-forever-70450/Interface/AddOns/` tree identified above. The literals do not require secret-value inspection.

Two source attempts configured only the 96 road bands: first before color/size/anchor setup, then after it. Both hid the road after normal reload. Repeating the all-99 preview after the first failure printed `AK post-init 99` and restored the road. No preview followed the second failure; source/test restoration, verified installation and the third reload followed directly. Initialization order is not a confirmed cause. Population/layer and timing differ; no specific public API contract violation is established. Offline geometry/fallback/allocation tests passed but did not establish actual rendering. Original appearance returned at approximately 08:58 CEST without another preview. Effective scale was not reread after reload; `0.71111112833023` describes the initial baseline only. No snapping adjustment remains in source. [Full attempts and rollback evidence](evidence/2026-10-19-m0-stationary-profile.md).

**Next probe plan for review, NOT RUN:** retain explicit diagnostic references to the grass, 64 outer bands, 32 island bands, marker and kart without adding UI objects or changing geometry. Compare fresh-session applications after creation to only the 96 bands, only the grass, then all 99 textures at the same recorded scale. Record setter outcomes and before/after appearance. Once population/layer behavior is isolated, compare the same population at construction versus a controlled later callback. Review results before selecting another implementation; do not add a per-update setter workaround or bypass any client restriction. See [FEASIBILITY.md](FEASIBILITY.md#renderer-api-uncertainty--review-before-another-implementation) for the prepared sequence.

## API confidence ledger

| Capability | Current evidence | Remaining verification |
|---|---|---|
| Installed executable/flavor file | Initial disk scan: `1.60.1.70450`, `wow_classic_beta` | Disk evidence is historical context; use live readbacks for runtime identity |
| Interface 16001 / Camelot selection | Live `GetBuildInfo()` returned `1.60.1`, `70450`, `16001`; project ID `18`; probe selected `Camelot`; addon `0.0.1` loaded/enabled | Recheck on client updates or another installation |
| Core APIs | Live function types for `CreateFrame`, `InCombatLockdown`, `GetTime`, `GetFramerate`, `GetCurrentKeyBoardFocus`, `ChatEdit_GetActiveWindow`; input probe APIs true and no event-registration failures | Availability does not establish all runtime semantics |
| Keyboard events/propagation | Live Start, Escape, Close/reopen, Enter/chat, Stop, Alt-Tab, map key, canvas click, hide/show and inactive reload observed; owner reported actual combat closure, note and working WoW controls | Simultaneous W/Up skipped at owner request (offline coverage retained); remaining focus/lifecycle, repeated combat/reopen behavior and full taint audit |
| Application focus APIs | Live `IsGameWindowFocused` and `IsWindowFocused` both absent; idle Alt-key release observed | Held-key Alt-Tab/release-outside behavior remains pending |
| Rotation/rendering/OnUpdate | Two human drives; analytical-band road loaded with seams; stationary/final restored counts 6/99/3 | Seam investigation, full timing/scaling/stress and allocation acceptance |
| `debugprofilestop` | Generated elapsed-ms contract plus actual guarded arming, 600 valid samples and retained/off output | Sustained/load-varied cost and full performance acceptance; fresh unprofiled reset remains live follow-up |
| Texture snapping setters | Live function types; literal all-99 preview removed seams; both creation-time 96-band attempts hid the road; original source restored/reloaded | Root cause unknown; population/layer/timing comparison prepared for review; no durable fix accepted |
| `C_ChatInfo` availability | Live function types for prefix registration, `SendAddonMessage`, `SendAddonMessageLogged`; `Enum.SendAddonMessageResult` is a table | Prefix registration/result semantics and transport measurements; no prefix registered or network traffic sent |
| Message payload/rate behavior | Proposed experiment only | Measured private-channel send/receive, throttle, RTT/recovery |
| SavedVariables | Minimal schema authored | Isolated sentinel across reload/logout/full restart |

## Reference material to verify against the client

These are reference starting points retained from the scaffold, not observed results for this build. Their current contents were not used to mark any test passed. Keep packet size, prefix limits and return semantics provisional until actual API probes and F4 measurements confirm them.

- [Frame:EnableKeyboard](https://warcraft.wiki.gg/wiki/API:Frame_EnableKeyboard)
- [Frame:SetPropagateKeyboardInput](https://warcraft.wiki.gg/wiki/API:Frame_SetPropagateKeyboardInput)
- [TextureBase:SetRotation](https://warcraft.wiki.gg/wiki/API:TextureBase_SetRotation)
- [OnUpdate](https://warcraft.wiki.gg/wiki/OnUpdate)
- [C_ChatInfo.SendAddonMessage](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessage)
- [C_ChatInfo.RegisterAddonMessagePrefix](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.RegisterAddonMessagePrefix)
- [C_ChatInfo.SendAddonMessageLogged](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessageLogged)
- [CHAT_MSG_ADDON_LOGGED](https://warcraft.wiki.gg/wiki/CHAT_MSG_ADDON_LOGGED)
- [Community Forever API dump/examples](https://github.com/Atraeau/WoW-Addons)

Last local observations: 2026-10-19 through approximately 08:58 CEST, including a stationary live profile and restored-source normal reload. Actual-client acceptance: **PARTIAL; renderer API uncertainty requires review; held-input, remaining lifecycle, scaling/sustained performance and full M0 checks PENDING**. The owner directed independent development elsewhere; another combat test is not the next task.
