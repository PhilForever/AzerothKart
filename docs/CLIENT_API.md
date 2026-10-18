# Forever client identity and API probes

**Live-client status: PARTIAL, 2026-10-18.** The installed client reported version `1.60.1`, build `70450`, interface `16001`, `WOW_PROJECT_ID=18` and selected TOC `Camelot`; Azeroth Kart `0.0.1` was enabled and loaded. Basic rendering, Start and several idle release routes were observed. The owner then confirmed actual combat closes the window, displays the interruption message and leaves WoW controls working. Sustained driving, held-key release, repeated-event/taint auditing and complete M0 acceptance remain pending. See the [actual-client evidence](evidence/2026-10-18-m0-client.md).

The earlier read-only disk scan found `_classic_beta_\WowB.exe` version `1.60.1.70450`, `.flavor.info` value `wow_classic_beta` and no running `Wow*` process **at that initial scan**. A live client was available for the later observations above. Runtime readbacks, rather than the folder or executable alone, confirm the tested interface and TOC selection.

## Exact runtime identity checks

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
/dump AzerothKartDB and AzerothKartDB.schemaVersion
/akart probe
```

Record baseline and stopped-run output as described in [FEASIBILITY.md](FEASIBILITY.md). Starting chat while driving is a focus-loss test and stops capture, so collect metrics after Escape. `maxElapsed` is a frame interval, not addon CPU time. Object counts cover the UI module's explicit allocations, excluding the bootstrap event frame and template internals. Follow [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md) for the temporary persistence sentinel; schema readback alone cannot prove a save occurred.

## API confidence ledger

| Capability | Current evidence | Remaining verification |
|---|---|---|
| Installed executable/flavor file | Initial disk scan: `1.60.1.70450`, `wow_classic_beta` | Disk evidence is historical context; use live readbacks for runtime identity |
| Interface 16001 / Camelot selection | Live `GetBuildInfo()` returned `1.60.1`, `70450`, `16001`; project ID `18`; probe selected `Camelot`; addon `0.0.1` loaded/enabled | Recheck on client updates or another installation |
| Core APIs | Live function types for `CreateFrame`, `InCombatLockdown`, `GetTime`, `GetFramerate`, `GetCurrentKeyBoardFocus`, `ChatEdit_GetActiveWindow`; input probe APIs true and no event-registration failures | Availability does not establish all runtime semantics |
| Keyboard events/propagation | Live Start, Escape, Close/reopen, Enter/chat, Stop, Alt-Tab, map key, canvas click, hide/show and inactive reload observed; owner reported actual combat closure, note and working WoW controls | Simultaneous W/Up skipped at owner request (offline coverage retained); remaining focus/lifecycle, repeated combat/reopen behavior and full taint audit |
| Application focus APIs | Live `IsGameWindowFocused` and `IsWindowFocused` both absent; idle Alt-key release observed | Held-key Alt-Tab/release-outside behavior remains pending |
| Rotation/rendering/OnUpdate | Primitive oval/kart visible; ticks advanced; short stopped-run probe captured | Sustained driving/rotation, full timing/scaling/stress and allocation acceptance |
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

Last local/live observations: 2026-10-18. Actual-client acceptance: **PARTIAL; held-input and remaining lifecycle/full M0 checks PENDING**. The [evidence transcription](evidence/2026-10-18-m0-client.md) defines the exact observed scope and the owner's combat report.
