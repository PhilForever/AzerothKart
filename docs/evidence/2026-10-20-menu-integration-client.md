# Menu integration — scoped actual-client evidence

Observed by Codex through the computer-use skill on 2026-10-20, approximately 18:25–18:31 UTC (20:25–20:31 CEST, Europe/Oslo). A later 21:59 UTC / 23:59 CEST observation is separate. No character movement/combat was automated. No personal chat/screenshots were copied into the repository.

## Installed source

`codex/menu-integration` at `7fcdd8919831c6e453bb81a21debc8a190f8b9df`, reviewed merge of Codex `de7a63e` and Claude `812d132`. Installer verified 20/20 source hashes and the previous full backup; no extra installed files were present. Manifest: git-ignored `local-artifacts/install-backups/20261020-202526-131-567cfd9612074e2d957df74433a02f53/install.json`. Independent later comparison again matched all 20 files. Other addons and WTF/SavedVariables were not modified by deployment.

Normal `/reload` completed. `/akart` opened Test Oval with two red fixtures and the trike. The stopped Track button selected Mirage successfully; its scenery/shadows/trike loaded and Oval fixtures were hidden. This verifies these existing texture paths after this reload; it is not a general new-file/restart guarantee.

## Menu check

1. Start Test Drive entered countdown on Mirage. Start and Track were disabled; Stop was enabled.
2. With the kart stationary and no driving keys held, pressed M. The run continued and no world map opened (612 ticks / 7.20 s race time visible).
3. Right-clicked the canvas, then left-clicked it. The run continued (1315 then 1970 ticks visible); no stopped modal appeared.
4. Clicked Stop. Its own callback ended the run with `stopReason=Stopped`, not the former mouse-click reason. Stopped summary showed 0/3 laps, time 42.25 s, current lap 42.25 s, best --. Start/Track enabled, Stop disabled. Hint: `Restart, choose a track, or Close`.
5. Clicked Print Probe; the stopped sample was retained. Later passive observations before Restart still showed tick 2715 / time 42.25 s. No full close/reopen freeze comparison was performed.
6. Clicked Restart. Fresh 3/countdown and tick 0 / time 0 appeared with Mirage still selected. A coordinate miss preceded the successful click; it was not a failed Start callback.
7. Escape ended that stationary run (`Exited test drive`, 597 ticks, 6.95 s race time). The normal WoW Game Menu also opened because input was released; a second Escape dismissed it. HUD displayed 0.017 s dropped time for this separate restarted sample; it is not a clean timing/performance pass.
8. Clicked Close; the stopped race window hid. Local chat subsequently accepted the read-only commands below.

Held throttle/drift while clicking, other overlapping/outside panels, all key aliases, steering, complete laps, moving sprite directions/camera edges, sustained performance and held-input Alt-Tab remain NOT RUN in this check. Combat was not retested. This is scoped menu/installation evidence, not milestone completion or human handling acceptance.

## Exact first stopped Print Probe

```text
M0 version=1.60.1 build=70450 interface=16001 selectedTOC=Camelot focusApi=false
frames=8515 ticks=2715 maxElapsed=0.0810 droppedSeconds=0.0000 hitchFrames=0 accumulator=0.00300
activeFrameSeconds=45.2530 simulatedSeconds=45.2500 callbackHz=188.16
UI frames=9 textures=113 fontStrings=13 active=false stopReason=Stopped track=mirage_raceway
eventRegistrationFailures=none
combatApi=true textFocusApi=true keyboardApi=true propagationApi=true
```

Callback frequency is delivered callbacks in this sample, not exclusive CPU/GPU cost or a sustained FPS claim. Three countdown seconds explain race time 42.25 s versus simulation time 45.25 s.

## No-send transport preflight

Executed while stopped; no prefix registration or send function was called:

```text
/run local c=C_ChatInfo;local r=Enum.RegisterAddonMessagePrefixResult;local s=Enum.SendAddonMessageResult;print(type(c.RegisterAddonMessagePrefix),type(c.SendAddonMessage),r.Success,r.DuplicatePrefix,s.Success,s.AddonMessageThrottle,s.ChannelThrottle)
```

Observed output:

```text
function function 0 1 0 3 8
```

This matches the types and five selected constants expected by the pinned source. It does not verify the complete enum tables, actual registration/send return values, sender spelling or delivery behavior. Both peers still need the checklist preflight before arming.

At 21:59 UTC, after the interrupted work resumed, the client had a fresh window handle. Refreshed inventory/state before any input. `/akart net report` returned:

```text
Azeroth Kart net: Idle: no experiment run
```

Final observed window hidden, chat closed, no probe armed. No work or continuous monitoring is claimed for the intervening gap.

Owner confirmed there is no second client available. First 0.5 DATA/s, 16-byte, 120-second WHISPER window, loss/ordering/throttle/RTT/reconnect and all multiplayer capacity gates remain NOT RUN; network CSV stays header-only.
