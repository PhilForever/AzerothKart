# Connection test — short reload and fresh-session recovery

The two longer windows are complete. [AKT722](evidence/2026-10-21-akt722-network-window.md) delivered/acknowledged 59 of 59 attempts; reverse [AKT723](evidence/2026-10-21-akt723-network-window.md) delivered/acknowledged all 240 at 2 DATA/s,128 bytes,120 seconds. No reported throttle/error/timeout in either window. AKT723 p95 RTT was 771 ms. The owner reports different zones, no group and US beta servers; this does not isolate the cause of the RTT.

**Use your existing build. No download is needed.** The next step checks that reloading one addon stops its peer's sends safely, then a fresh session works. It uses two short windows, not another two-minute budget trial. Both stop the kart and remain out of combat. Keep any unexpected refusal/error instead of repeating the test.

Generic names here: owner **Amber Stone**, friend **Birch Vale**. Replace them with complete actual first names/surnames; no realm suffix. Chat's personalized instructions contain the actual names.

## 1. Interrupt a short session

1. Friend types first:

   ```text
   /akart net listen "Amber Stone" AKT724 2 128 20
   ```

2. Within 20 seconds, owner types:

   ```text
   /akart net start "Birch Vale" AKT724 2 128 20
   ```

3. Once owner sees `Armed`, tell the friend to wait about **5 seconds**, then type `/reload`. After loading, friend types `/akart net report`; expected result is **Idle: no experiment run**. Keep that result. Pre-reload friend counters are lost and must not be invented.
4. Owner does **not** reload or manually stop. Wait for `Stopped` (roughly 15–20 seconds after the friend's reload), then type `/akart net report`. Save a screenshot **before** the next session replaces it. `ack_deadline` is the expected stop reason. Intentional missing replies here are part of the interruption test, not unexplained packet loss. If a different stop/error occurs, preserve it for review.

## 2. Prove a fresh session works

After the owner has saved the first report and the friend has loaded back in, explicitly arm both with new code `AKT725`:

1. Friend:

   ```text
   /akart net listen "Amber Stone" AKT725 2 128 10
   ```

2. Owner within 20 seconds:

   ```text
   /akart net start "Birch Vale" AKT725 2 128 10
   ```

3. Let both say `Stopped` (about 20 seconds from sender start). **Both type `/akart net report` and save a screenshot.** Do not reload during this second window.

Give Codex the owner's AKT724 report, the friend's post-reload Idle result and both AKT725 reports. Sequence evidence is optional if counts disagree; it is not required for this focused lifecycle check. None of these recovery results has been run or marked passed yet.

This tests addon `/reload` and explicit rearming, not a full logout/socket disconnect. Larger rooms, PARTY and the full rate/size matrix remain separate expansion work. After this recovery evidence, review the measured budget and first two-player synchronization design; actual racing still needs direct play.

## Reference commands

`/akart net stop` cancels. `/akart net report` prints retained local counters; `/akart net evidence` prints sequence maps. `/akart net help` describes the initial generic two-minute test, not this current recovery procedure. Reading help/report sends nothing. The detailed [developer checklist](../tests/MANUAL_NETWORK_CHECKLIST.md) retains counter definitions and expansion procedures.

Forever names can be quoted or unquoted; prefer quotes. Settings after the fresh six-uppercase-letter/digit code are `pps bytes seconds`: rates0.5/1/2/4, DATA bytes16/64/128/220, integer duration10–120. The native route is `SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED`, channel WHISPER; reports/ledger say WHISPER_LOGGED. No unlogged/ordinary-whisper fallback exists. Existing clock/lifecycle/lockdown/error/throttle guards stay active.
