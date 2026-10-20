# Connection test — you and a friend

This measures how steadily Azeroth Kart can exchange messages with a friend. It is **not a multiplayer race**. A friend counts as the second client; you do not need two accounts yourself. There is no connection-test button yet: use chat commands. **Print Probe** in the kart window prints driving statistics, not this test.

IOU already demonstrated that Forever's logged addon whispers work: two clients completed four exact round trips on 16 October 2026. We are reusing that route. The remaining test measures a longer, paced exchange for racing; it does not repeat IOU's basic connection check.

Both players need the same updated Azeroth Kart build with full-name support. Forever characters use **first name and surname**, such as `Amber Stone`, with **no realm suffix**. In the examples below, you are Amber Stone and your friend is Birch Vale. Replace those names with your actual full names and keep the quotes.

## Next test — reverse direction, larger packets

**AKT722 is complete.** Both clients exchanged all 59 attempted DATA/ACKs with no reported throttles/errors/timeouts; p95 round-trip time 779 ms. [Recorded evidence](evidence/2026-10-21-akt722-network-window.md). No repeat of the basic connection test is needed. The missing final opportunity was local scheduling, not a lost packet.

Use your **current installed build**; no new download or reload is needed for this next window. Reverse the roles and use a fresh code. In these generic examples, you are Amber Stone and your friend is Birch Vale. The owner receives personalized commands in chat.

1. Both stop the kart and stay out of combat. **You type first** (your friend's full name):

   ```text
   /akart net listen "Birch Vale" AKT723 2 128 120
   ```

2. **Within 20 seconds, your friend types** (your full name):

   ```text
   /akart net start "Amber Stone" AKT723 2 128 120
   ```

3. Both should see `Armed`. Wait about **2 minutes 15 seconds**, until both see `Stopped`. This tests two 128-byte DATA messages per second in the reverse direction, with a 16-byte reply to each. If either refuses, stops early or the client becomes sluggish, cancel the other side with `/akart net stop` and keep the message.
4. **Both type**, one at a time, and save all output before reload/another attempt:

   ```text
   /akart net report
   /akart net evidence
   ```

5. Give both sets of output to Codex. The sender can report 239 attempts out of 240 planned because of the known terminal-slot scheduling edge; do not rerun merely to chase 240/240. We compare actual attempts/receipts, not just the planned count.

This replaces an exhaustive rate/size matrix for the immediate two-player candidate. A short reload/fresh-session recovery check remains before selecting the live-race synchronization design; higher participant counts are separate work.

For the short reminder inside WoW, type **`/akart net help`**. Reading help never starts the test, registers the prefix or sends a message.

## Developer notes

Quoted full names are recommended; unquoted full names also work, for example `/akart net listen Amber Stone AKT721`. Optional arguments after the code are `pps bytes seconds`, defaulting to `0.5 16 120`. Supported rates are `0.5`, `1`, `2`, `4`; DATA sizes are `16`, `64`, `128`, `220` bytes; duration is an integer from `10` to `120` seconds. Start with the defaults.

The transport is explicitly `C_ChatInfo.SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED`, using `WHISPER`. It never falls back to unlogged addon messages or ordinary chat whispers. Record this path as `WHISPER_LOGGED` in the experiment ledger. IOU's live evidence was on build 70425; Azeroth Kart AKT722 now records actual logged success codes and a completed lowest-rate exchange. Exact build/interface metadata for those screenshots was not supplied; higher-rate delivery and recovery remain pending. Coordinate the [capability readbacks](CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass) before arming. These send nothing. The detailed measurement and reconciliation procedure is in the [network checklist](../tests/MANUAL_NETWORK_CHECKLIST.md).
