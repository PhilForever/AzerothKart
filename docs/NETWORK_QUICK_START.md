# Connection test — you and a friend

This measures how steadily Azeroth Kart can exchange messages with a friend. It is **not a multiplayer race**. A friend counts as the second client; you do not need two accounts yourself. There is no connection-test button yet: use chat commands. **Print Probe** in the kart window prints driving statistics, not this test.

IOU already demonstrated that Forever's logged addon whispers work: two clients completed four exact round trips on 16 October 2026. We are reusing that route. The remaining test measures a longer, paced exchange for racing; it does not repeat IOU's basic connection check.

Both players need the same updated Azeroth Kart build with full-name support. Forever characters use **first name and surname**, such as `Amber Stone`, with **no realm suffix**. In the examples below, you are Amber Stone and your friend is Birch Vale. Replace those names with your actual full names and keep the quotes.

## The test

1. Both install the same updated addon build and type `/reload`, then stop the kart and stay out of combat. Confirm each other's exact full first name and surname, as used for whispers.
2. Agree on a new six-character uppercase letter/number code. `AKT721` below is an example: use the same fresh code on both sides, and a different code for each attempt.
3. **Your friend types this first**, using **your** full name:

   ```text
   /akart net listen "Amber Stone" AKT721
   ```

4. **Within 20 seconds, you type this**, using **your friend's** full name:

   ```text
   /akart net start "Birch Vale" AKT721
   ```

   Each side should print `Armed`. This sends one 16-byte test message every two seconds for two minutes, with a reply from your friend's addon. If either says `Refused`, cancel the other side and save the message.
5. Wait **about 2 minutes 15 seconds, until both players see `Stopped`**. There is no driving or clicking to do. The friend's timer begins when the first message arrives, so it can finish a few seconds after yours. If it stops early, keep the reason rather than restarting it.
6. **Both players** type these commands, one at a time:

   ```text
   /akart net report
   /akart net evidence
   ```

7. Save each player's complete output and give both sets to Codex before anyone reloads or starts another attempt. Codex compares the two sides; one player's report alone cannot prove which messages arrived.

To cancel at any point, either player can type `/akart net stop`. Do not increase the rate to get past an error.

For the short reminder inside WoW, type **`/akart net help`**. Reading help never starts the test, registers the prefix or sends a message.

## Developer notes

Quoted full names are recommended; unquoted full names also work, for example `/akart net listen Amber Stone AKT721`. Optional arguments after the code are `pps bytes seconds`, defaulting to `0.5 16 120`. Supported rates are `0.5`, `1`, `2`, `4`; DATA sizes are `16`, `64`, `128`, `220` bytes; duration is an integer from `10` to `120` seconds. Start with the defaults.

The transport is explicitly `C_ChatInfo.SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED`, using `WHISPER`. It never falls back to unlogged addon messages or ordinary chat whispers. Record this path as `WHISPER_LOGGED` in the experiment ledger. IOU's live evidence was on build 70425; actual logged API/return checks on build 70450 and the first sustained Azeroth Kart window remain **NOT RUN**. Coordinate the [capability readbacks](CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass) before arming. These send nothing. The detailed measurement and reconciliation procedure is in the [network checklist](../tests/MANUAL_NETWORK_CHECKLIST.md).
