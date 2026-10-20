# Forever client identity and API probes

**Live-client status: PARTIAL, updated 2026-10-19 at approximately 16:27 CEST.** The installed client reported version `1.60.1`, build `70450`, interface `16001`, `WOW_PROJECT_ID=18` and selected TOC `Camelot`; Azeroth Kart `0.0.1` was enabled and loaded. Basic rendering/Start, two human near-minute drives, a bounded stationary profiler window, the focused grass/road fix and a scoped 917.598-second stopped/open idle check are evidenced below. The latest normal-scale attempt auto-reverted before confirmation; original preferences returned, but effective-scale restoration needs review. Full timing, held-key release, repeated-event/taint auditing, scaling/sustained performance and complete M0 acceptance remain pending. See the [initial evidence](evidence/2026-10-18-m0-client.md), [two driving samples](evidence/2026-10-19-m0-client.md), [stationary profile/failed attempts](evidence/2026-10-19-m0-stationary-profile.md), [road-layer isolation/startup verification](evidence/2026-10-19-m0-road-layer.md), [idle evidence](evidence/2026-10-19-m0-idle.md) and [incomplete scale attempt](evidence/2026-10-19-m0-scale.md).

**Current development and handoff, 2026-10-20:** Physics v6 implements progressive steering, drift correction grace and boosts. Local Race/Laps/Checkpoints implement a 180-tick countdown, three-lap finish and per-run best lap. Mirage has a stopped-state selector and scale-1.5 follow camera; current explicit counts are 9/111/13 in an 856×762 window. The opaque cropped Mirage background, larger kart and specific Start/West marker placement were observed in the [stopped build-70450 camera check](evidence/2026-10-20-mirage-camera-static.md). Moving camera/edges, v6 handling acceptance, latest countdown/finish/restart play, transparent sprites and sustained performance remain NOT RUN. The full Lua 5.1 offline suite passed at the handoff checkpoint, including the 10k-tick v6 replay; this is not client acceptance. M0/M1/M3 stay open. See [implemented contracts](API_CONTRACTS.md), [the handoff](handoffs/codex-latest.md) and PROGRESS; historical observations below retain their original scope.

The earlier read-only disk scan found `_classic_beta_\WowB.exe` version `1.60.1.70450`, `.flavor.info` value `wow_classic_beta` and no running `Wow*` process **at that initial scan**. A live client was available for the later observations above. Runtime readbacks, rather than the folder or executable alone, confirm the tested interface and TOC selection.

## Exact runtime identity checks

On 2026-10-19 the updated source was installed with a verified prior-addon backup, then loaded through normal `/reload`. Live readbacks again showed `1.60.1`, build `70450`, interface `16001`, selected TOC `Camelot`, the new zeroed timing fields and UI counts 6/99/3. See [the baseline and later two drives](evidence/2026-10-19-m0-client.md); those observations do not complete the remaining timing or retained-note checks. A shell process scan missed the available client; the desktop app/window inventory confirmed it. Use that inventory before declaring a requested live session unavailable. The 07:32 no-client observation is historical: the owner's later opened-client authorization enabled the [stationary checks](evidence/2026-10-19-m0-stationary-profile.md). Following the rejected renderer adjustments, a final normal reload restored the original source's gray annulus, island, marker and kart at approximately 08:58 CEST. An independent read-only comparison at 08:58:33 CEST confirmed all ten installed files matched the restored `38faab2` source. The client was left with capture inactive, window hidden and profiling off.

After authorized continuation, the grass-priority/band-snapping candidate was installed with verified backup and all ten source matches; independent comparisons repeated at 09:20:08 and 13:54:48 CEST. A controlled normal reload at approximately 13:57–14:02 showed the entire road, island, marker, kart and controls without apparent seams, followed only by read-only diagnostics. Probe identity remained 1.60.1/70450/16001/Camelot, zeroed/inactive with counts 6/99/3. Effective scale was freshly read as `0.72452831268311`; 96 band states and explicit grass `BACKGROUND,-1` with unchanged default snapping were verified. Final close/reopen/close left the client inactive/hidden/profiling off. This is scoped startup evidence, not full M0 acceptance.

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

The prototype reports build/interface/selected TOC, input capabilities and unavailable registered events. Capture remains disabled if a required keyboard/text-focus capability is missing. Under [ADR 0011](adr/0011-explicit-drive-exits.md), incidental mouse clicks and unassigned keys keep the run active; Stop/Escape/Close and Enter/chat, actual text focus, available application-focus readback and lifecycle handling are explicit exits. Global mouse-down is no longer registered or required. Earlier live Stop/canvas/map-key observations used the superseded all-click/unknown-key policy; they do not validate the revised Stop OnClick or held-input Alt-Tab behavior.

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

## Texture snapping and draw priority — scoped startup verification

The analytical-band road loaded with thin horizontal seams at the measured effective scale. Live type checks found `SetTexelSnappingBias` and `SetSnapToPixelGrid` functions. A guarded one-off application of literal bias `0`/snap `false` to all 99 existing canvas textures reported 99 successful setter pairs and removed the seams. This does not establish equivalent construction-time behavior or other-scale appearance.

The build-70450 primary source `SimpleTextureBaseAPIDocumentation.lua:555` defines `SetSnapToPixelGrid(snap: bool)` and `:594` defines `SetTexelSnappingBias(bias: normalizedValue)`, both with `SecretArguments="AllowedWhenUntainted"`. `Blizzard_SharedXML/NineSlice.lua:218–223` uses bias `0` followed by snap `false` in `NineSliceUtil.DisableSharpening`. These files are under the same pinned parent-workspace `research/upstream/wow-ui-source-forever-70450/Interface/AddOns/` tree identified above. The literals do not require secret-value inspection.

Two earlier source attempts configured only the 96 road bands: first before color/size/anchor setup, then after it. Both hid the road after normal reload. Repeating the all-99 preview after the first failure printed `AK post-init 99` and restored the road. No preview followed the second failure; source/test restoration, verified installation and the third reload followed directly. Initialization order was not established as the cause; no specific public API contract violation was shown. Original appearance returned at approximately 08:58 CEST without another preview. Effective scale was not reread at that rollback; no snapping adjustment was retained at that time. [Historical attempts and rollback evidence](evidence/2026-10-19-m0-stationary-profile.md).

The owner then authorized continued diagnosis. Changing only the existing 96 bands reproduced disappearance after initialization. Hiding only grass restored the road; showing it hid the road, and matching only grass snapping restored it. In an independent fresh session, setting only grass to `BACKGROUND,-1` kept the road visible with seams; changing only the 96 bands' bias/snap then removed seams while preserving visibility. Marker/kart were untouched. The generated `SimpleRegionAPIDocumentation.lua:24,147` supports `GetDrawLayer()` and `SetDrawLayer(layer, sublevel)`, default sublevel 0; `SimpleTextureBaseAPIDocumentation.lua:206,347` exposes `GetTexelSnappingBias()` and `IsSnappingToPixelGrid()`. Native batching internals remain unproven.

The retained creation-only source now explicitly lowers grass to `BACKGROUND,-1` and guards optional bias `0`/snap `false` calls on the 96 bands after color/geometry setup. Grass snapping and marker/kart settings remain unchanged; geometry, physics and UI-object counts are unchanged. Offline regressions cover missing/throwing optional setters, one grass-priority call, 192 band-setter calls, and no reconfiguration during updates/reopening. Full Lua 5.1/5.4 suites passed, 16 files/eight tests each.

**Controlled normal startup, approximately 13:57–14:02:** without post-reload texture mutations, the full canvas/controls were visible without apparent seams. Read-only inspection verified all 96 bands had bias 0/snap false; grass read `BACKGROUND,-1`, default bias `0.30000001192093`/snap true. Effective scale was freshly read as `0.72452831268311`, counts remained 6/99/3, and final close/reopen/close left inactive/hidden/profiling off. [Exact isolation, installation and startup evidence](evidence/2026-10-19-m0-road-layer.md). This resolves the scoped candidate's promotion blocker; scale matrix, full input/taint and sustained-performance acceptance remain open.

**Stopped/open idle check, 15:29:48.901–15:45:06.499 CEST:** completed 917.598 wall-clock seconds, with no agent input and capture/profiling off. Endpoint/reopen probes retained every clock counter/tick 852 and counts 6/99/3. Effective scale remained 0.72452831268311; whole-client FPS point observations were 206.00857543945 / 198.3470916748. Renderer/controls remained readable in passive observations; final state hidden/inactive/profiling off. The earlier owner-interrupted attempt was excluded. [Exact evidence and limits](evidence/2026-10-19-m0-idle.md); this is not sustained FPS, CPU/memory or full M0 acceptance.

### Supported-scale attempt and read-only review

At 16:19–16:27 CEST, normal Options search exposed Use UI Scale, initially unchecked at stored 100%. Applying the checked 100% state produced a timed confirmation; acceptance was not completed before automatic reversion. No temporary effective-scale/probe/addon-appearance sample was recorded. Final original preferences/CVars were 1.000000/0, with every stopped counter/tick 852 and counts 6/99/3 retained, hidden/inactive/profiling off. Effective scale changed from 0.72452831268311 to 0.71111112833023, so full restoration is not verified. Further setting/client mutations stopped for review. [Exact evidence](evidence/2026-10-19-m0-scale.md). No established API contradiction or accepted scale comparison follows.

Read-only inspection of the same pinned build-70450 source above found `Blizzard_SharedXML/PixelUtil.lua:3–6`: its pixel-to-UI-unit conversion returns `768.0 / physicalHeight` from `GetPhysicalScreenSize()`. This is not proof of UIParent's automatic-scale implementation. Generated `Blizzard_APIDocumentationGenerated/ScreenDocumentation.lua:9–26` declares `GetDefaultScale()` and `GetPhysicalScreenSize()`; `SimpleFrameAPIDocumentation.lua:381,621` documents effective/local scale and `SimpleScriptRegionAPIDocumentation.lua:161,323` height/width. Presence in source does not establish function availability or unrestricted readback in this session. Observe errors/secret restrictions without coercing results or using another access path.

**Deferred M0 review, PREPARED/NOT RUN:** one guarded read-only physical/default-scale/UIParent geometry snapshot at unchanged settings, using [client-checklist section 3d](../tests/MANUAL_CLIENT_CHECKLIST.md#3d-read-only-geometry-review--deferred-m0-check). The original physical/window dimensions were not measured; the numerical resemblance to 768/1060 and 768/1080 is only a hypothesis. No settings change, arbitrary CVar write, reload, Start or character input is part of this review. Per ADR 0007, it does not block current local mechanics work.

## API confidence ledger

| Capability | Current evidence | Remaining verification |
|---|---|---|
| Installed executable/flavor file | Initial disk scan: `1.60.1.70450`, `wow_classic_beta` | Disk evidence is historical context; use live readbacks for runtime identity |
| Interface 16001 / Camelot selection | Live `GetBuildInfo()` returned `1.60.1`, `70450`, `16001`; project ID `18`; probe selected `Camelot`; addon `0.0.1` loaded/enabled | Recheck on client updates or another installation |
| Core APIs | Live function types for `CreateFrame`, `InCombatLockdown`, `GetTime`, `GetFramerate`, `GetCurrentKeyBoardFocus`, `ChatEdit_GetActiveWindow`; input probe APIs true and no event-registration failures | Availability does not establish all runtime semantics |
| Keyboard events/propagation | Live Start, Escape, Close/reopen, Enter/chat, Stop, Alt-Tab, map key, canvas click, hide/show and inactive reload observed; owner reported actual combat closure, note and working WoW controls | Simultaneous W/Up skipped at owner request (offline coverage retained); remaining focus/lifecycle, repeated combat/reopen behavior and full taint audit |
| Application focus APIs | Live `IsGameWindowFocused` and `IsWindowFocused` both absent; idle Alt-key release observed | Held-key Alt-Tab/release-outside behavior remains pending |
| Rotation/rendering/OnUpdate | Two human drives; full canvas visible without apparent seams after controlled source reload; counts 6/99/3 | Full timing/scaling/stress and allocation acceptance |
| `debugprofilestop` | Generated elapsed-ms contract plus actual guarded arming, 600 valid samples and retained/off output | Sustained/load-varied cost and full performance acceptance; fresh unprofiled reset remains live follow-up |
| Texture snapping/draw priority | Failed history preserved; grass isolation and independent sublevel test; creation-only grass -1/band bias0/snapfalse verified after normal reload | Native batching cause not established; supported-scale/stress matrix remains pending |
| Normal UI scale / geometry | Control discovered; attempted 100% apply auto-reverted; original CVars restored, effective-scale mismatch recorded | Accepted changed-scale readbacks/renderer, restoration review and guarded geometry snapshot remain pending; no native-scale explanation established |
| `C_ChatInfo` availability | Historical live function types for prefix registration, `SendAddonMessage`, `SendAddonMessageLogged`; `Enum.SendAddonMessageResult` is a table. Build-matched local source declares prefix/send result enums and addon-event fields | AKT722/723 demonstrate numeric prefix/send success0 and reconciled receipts/ACKs; latest AKT723 has240 accepted calls per transmitting endpoint. Other result paths/recovery remain unverified |
| Message payload/rate behavior | Bounded opt-in two-peer WHISPER harness authored; exact 16/64/128/220-byte DATA, 16-byte ACK and deterministic offline accounting are distinct from network evidence | AKT722 and reverse AKT723 completed; latest2 DATA/s,128-byte DATA/16-byte ACK,120seconds. Recovery, budgets beyond these samples, PARTY and multi-peer remain unmeasured |
| SavedVariables | Minimal schema authored | Isolated sentinel across reload/logout/full restart |

## Transport probe API contract — source evidence, not a live pass

**Current live evidence:** AKT722 and [AKT723](evidence/2026-10-21-akt723-network-window.md), reviewed 2026-10-21. Reverse AKT723 completed 240 accepted/received 128-byte DATA and 240 accepted/matched 16-byte ACKs at 2 DATA/s over 120 seconds; numeric prefix/send success0, no reported errors/throttles/timeouts, RTT median 701 / p95 771 / max 1012 ms. Owner reports different zones, no group and US beta servers; exact client builds/interfaces/test UTC and attribution of latency remain unknown. Reload/fresh-session recovery is NOT RUN, and this is not production racing approval. Historical/source-contract paragraphs below retain their original scope.

The current branch adds `/akart net listen|start ...`, `stop`, `report`, `evidence` and local-only `help`; [the manual checklist](../tests/MANUAL_NETWORK_CHECKLIST.md) gives the exact two-client procedure. There is no load-time prefix registration or automatic traffic. Arming is explicit, logged-private-WHISPER-only and refused while a drive/combat is active or required API/event/clock/result semantics are missing. The probe reuses the Core frame; it adds no input-capture API, network-per-simulation-tick loop or new UI objects. No new prefix registration/send calls were executed in the actual client during this implementation task.

Inspected primary source is the parent-workspace tree `research/upstream/wow-ui-source-forever-70450`, whose `version.txt` reads `1.60.1.70450`. In `Interface/AddOns/Blizzard_APIDocumentationGenerated/`:

- `ChatInfoDocumentation.lua:469` declares `C_ChatInfo.RegisterAddonMessagePrefix(prefix)` returning `RegisterAddonMessagePrefixResult`, not a boolean.
- `ChatInfoDocumentation.lua:535` declares `C_ChatInfo.SendAddonMessageLogged(prefix, message, chatType, target)` returning nullable `SendAddonMessageResult`, with `SecretArguments = "NotAllowed"`. The adapter sends only its own literal/validated printable payload, channel and explicitly supplied peer; it must not inspect/coerce secret values or bypass a refused call.
- `ChatInfoDocumentation.lua:821` declares `CHAT_MSG_ADDON_LOGGED` payload order: prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID. Peer scoping uses the event `sender`, never a payload identity or the event `target` field.
- `ChatConstantsDocumentation.lua` declares `Enum.RegisterAddonMessagePrefixResult.Success=0`, `DuplicatePrefix=1`, `InvalidPrefix=2`, `MaxPrefixes=3`; `Enum.SendAddonMessageResult.Success=0`, `AddonMessageThrottle=3`, `ChannelThrottle=8`, and other failures within 1–12. These source values are expectations to compare with the real client's enum tables, not hard-coded proof of installed behavior.

**2026-10-20 actual no-send readback:** registration/send function types and five selected constants returned `function function 0 1 0 3 8` (registration Success/DuplicatePrefix, send Success/AddonMessageThrottle/ChannelThrottle). This matches the selected source expectations; full enum tables, actual registration/send returns and transport remain unverified. Later `/akart net report` returned `Idle: no experiment run`. [Exact command/evidence](evidence/2026-10-20-menu-integration-client.md). No prefix was registered or packet sent in this check.

**Reused compatibility evidence (reviewed 2026-10-21):** sibling `IOU-GitHub/docs/connection-test.md` records four exact round trips between IOU 0.3.2 clients on Forever 1.60.1/build 70425 on 16 October, including UTF-8 and 239/240-byte messages. Its `transport.lua` uses the logged API/event pair and complete names. Azeroth Kart now deliberately reuses that route, with no fallback; see [ADR 0012](adr/0012-forever-logged-transport.md). The earlier 20 October no-send readback used the unlogged send function and remains historical evidence only. Two actual logged windows are recorded above; capacity beyond these samples, recovery and unobserved return branches remain unverified. Native `InChatMessagingLockdown` when present is guarded and must be false; the broad outgoing-restriction diagnostic does not override actual native results. Nil logged-send returns are unknown and stop the probe.

Read these on **both** clients before any explicit arm. They only read availability/enum values; they do not register or send:

```text
/dump GetBuildInfo()
/dump type(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix), type(C_ChatInfo and C_ChatInfo.SendAddonMessageLogged)
/dump Enum and Enum.RegisterAddonMessagePrefixResult
/dump Enum and Enum.SendAddonMessageResult
```

Capture exact values and absence/errors. Stop for review if they contradict the build-matched source or are protected/secret; do not substitute another API or assume legacy `true`/`nil` success. The guarded adapter requires the expected enum contract, retains the raw registration/send results and classifies only recognized values. `Success` or an existing matching `DuplicatePrefix` permits registration; a recognized send `Success` is **local acceptance**, not delivery. Failure, unknown result, throw or throttle stops the session without retries. Prefix registration remains in the client after Stop if the API has no corresponding unregister action; stopped code sends nothing.

Forever uses full first names and surnames, without realms. The complete native logged-event sender must match the configured full name: trim/collapse ASCII spaces and fold ASCII case only; raw names are capped at 96 bytes and control/DEL/pipe characters are rejected. Preserve surnames, punctuation, hyphens and UTF-8 exactly; Unicode case folding and realm inference are not performed. A mismatch refuses the packet rather than silently broadening trust. The fixed rejection-reason report counts sender/session and other failures without printing identities. Session IDs are public correlation tokens, not credentials. This narrow harness proves no authorization, anti-cheat, reliable delivery, participant capacity or playable racing; AKT722 and AKT723 demonstrate their configured two-client windows; recovery and production capacity remain **PENDING**.

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

Last local observations: 2026-10-19 through approximately 16:27 CEST, including the incomplete normal-scale attempt and recorded effective-scale restoration mismatch. Actual-client acceptance: **PARTIAL; scaling review, held-input, remaining lifecycle, sustained performance and full M0 checks PENDING**. These checks are deferred under ADR 0007. See PROGRESS for the next local build task; another combat test is not requested.
