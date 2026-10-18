# Manual client acceptance — F0/F1/F2/F5

**All client checks PENDING; no WoW session was available on 2026-10-18.** Do not tick from source inspection or UI test-double results. This is the single next M0 task. Run the short identity/safety smoke first; run the longer rendering/persistence work only after controls release correctly.

Date/time/timezone: ______  Tester: ______  Build/interface: ______
Runtime project ID: ______  Selected TOC metadata: ______  Addon version: ______
Resolution/normal UI scale: ______  OS/hardware: ______  Location: ______
Other addons/context: ______  Baseline FPS: ______  Evidence path: ______

## 1. Identity and startup

- [ ] Observe the AddOns list: enabled state, displayed version and any incompatibility/load reason. Record a screenshot and errors verbatim.
- [ ] Run all identity/capability `/dump` commands in [CLIENT_API.md](../docs/CLIENT_API.md); save the outputs. Record missing APIs/events and the optional focus API status. Candidate interface `16001` and Camelot selection require actual results.
- [ ] Out of combat, `/akart` opens the primitive oval without starting movement/capture. `/akart probe` prints bounded output, including build/interface/TOC, frames/ticks/maxElapsed/droppedSeconds/hitchFrames, accumulator, object counts and stop reason.
- [ ] A second `/akart` closes the window; ordinary movement/chat works. Reopening remains stopped until an explicit Start click.

## 2. Controls and stop matrix

For **each row**, start a fresh drive with a deliberate **Start Test Drive** click outside combat. Hold W for movement, perform the action, then release all keys. Record the actual stop reason from `/akart probe`, confirm ticks remain unchanged across two probe calls several seconds apart, test ordinary WoW movement keys and type into chat, and confirm no automatic resume. Do not type the probe during the active timing sample: entering chat is itself a stop test.

| Check | Reproducible action | Required observation | Result/evidence |
|---|---|---|---|
| Basic movement | W then Up; S then Down; A/D then Left/Right | Acceleration, braking/reverse and both steering aliases work; visible rotation matches motion | PENDING |
| Overlapping aliases | Hold W and Up; release W while keeping Up held; then release Up. Repeat A/Left and D/Right | Remaining alias stays held; releasing both removes the control; no stuck key | PENDING |
| Escape | Press Escape while moving | Capture stops; ordinary bindings/chat recover | PENDING |
| Stop | Click Stop while holding throttle | Stops and clears held input; ordinary controls recover | PENDING |
| Close/toggle | Click Close; separately use `/akart` to close | Hidden window cannot retain capture; reopening is stopped | PENDING |
| Enter/chat | Press Enter during capture, then type a harmless chat draft and cancel it | Driving stops; chat receives text normally; record whether first Enter opens chat | PENDING |
| Unrecognized key | Press the normal map key (or another non-driving binding), then close that UI normally | Driving stops; record whether the normal binding also works on that press | PENDING |
| Click outside | Click world outside the race window while throttle is held | Stops and releases controls without relying on key-up reaching the race frame | PENDING |
| Any mouse click | Click the race canvas; separately click a non-text UI panel overlapping the race window | Every mouse-down releases capture; overlapping UI/clicks work normally | PENDING |
| Other UI focus | Click chat edit area, bag/UI panel or another normal edit box | Stops; typing/clicked UI work normally | PENDING |
| Application focus | Alt-Tab away for 5 seconds, release W outside the game, return | Stopped on return, no stale throttle or auto-resume; record optional focus API status | PENDING |
| Hide/show UI | Use the ordinary client UI-hide binding, then show UI again | No capture through a hidden window; stopped after show | PENDING |
| World transition | Have a normal manually initiated loading transition occur during capture when practical (for example a consented portal/instance entry) | Stops on leaving world; no auto-resume after arrival | PENDING / unavailable |
| Reload | While driving, enter `/reload` normally, then log result after load | Clean reload, inactive controls and ordinary movement/chat | PENDING |
| Logout/login | Log out normally after a drive, then log in | Clean load; inactive controls, ordinary movement/chat | PENDING |
| Combat before Start | Enter combat through ordinary manual game play, open `/akart`, attempt Start | Start rejected; no capture, restricted-action error or taint | PENDING |
| Combat during capture | Outside combat Start, then have combat begin through ordinary manual game play or a consenting duel partner | Simulation/input stop safely; movement works during and after combat; no taint or auto-resume | PENDING |

Capture stop reasons may differ with event order (for example global mouse-down can precede a button click). The deliberate Start click must activate capture successfully despite the mouse-down stop rule; verify actual ordering rather than assuming it. All later mouse-down events stop driving. Record actual output and behavior. Chat commands can stop capture before reload/logout events; the loading-transition row tests a separate non-chat route. If a scenario cannot be arranged, leave it pending and explain why.

Any stuck input or combat taint is an M0 blocker. Record the exact failing action, event/status output and client error. End that driving test; do not bypass protected restrictions to produce a pass. Confirm that after combat the input propagation restoration does not restart the drive.

## 3. F1 timing and allocation sample

- [ ] Copy `/akart probe` and `/dump GetFramerate()` baseline output. Click Start, drive 60 seconds, press Escape and copy output again. Repeat three runs.
- [ ] For each sample record duration, frames, ticks, maxElapsed, hitchFrames, droppedSeconds, accumulator, stop reason, explicit addon frame/texture/font-string counts and visible symptoms.
- [ ] Confirm counts stay stable across repeated drives/open/close cycles and no chat output occurs each tick. These UI module counts exclude the bootstrap event frame and internal template allocations; do not claim whole-client allocation measurements.
- [ ] Repeat readable/usable layout checks at available normal client scales near 0.75/1/1.25. Record actual values if the normal UI range differs.
- [ ] After safety passes, leave open/idle for 15 minutes, then drive for 10 minutes. Record before/after FPS, metrics/errors and visible hitches. Return from a long Alt-Tab without catch-up burst or automatic resume.

`maxElapsed` is whole-frame elapsed time, not measured addon CPU overhead. This one-kart experiment does not validate 32 sprites, multiplayer, production tracks or a lap engine.

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
