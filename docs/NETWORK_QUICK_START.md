# Connection test — you and a friend

This checks whether two running WoW clients can exchange the addon's messages. It is **not a multiplayer race**. A friend counts as the second client; you do not need two accounts yourself. There is no connection-test button yet: use chat commands. **Print Probe** in the kart window prints driving statistics, not this test.

You do not need to run anything until a friend is available. Both players need the same current addon build. Before the first attempt, coordinate the [compatibility readbacks](CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass) with Codex on both clients. Those checks send nothing. The detailed developer procedure is in the [network checklist](../tests/MANUAL_NETWORK_CHECKLIST.md).

## The test

1. Both log into WoW, stop the kart and stay out of combat. Agree which person is **you** and which is **your friend**. Get both exact full `Character-Realm` names. If unsure of either spelling, stop here and have Codex prepare the two personalized commands; do not guess the realm.
2. Agree on a new six-character uppercase letter/number code. `AKT721` below is an example: use the same fresh code on both sides, and a different code for each attempt.
3. **Your friend types this first**, replacing `YourName-YourRealm` with your full name:

   ```text
   /akart net listen YourName-YourRealm AKT721
   ```

4. **Within 20 seconds, you type this**, replacing `FriendName-FriendRealm` with your friend's full name:

   ```text
   /akart net start FriendName-FriendRealm AKT721
   ```

   Each side should print `Armed`. The defaults run the first, lowest-rate test. If either says `Refused`, cancel the other side and save the message.
5. Wait **about 2 minutes 15 seconds, until both players see `Stopped`**. There is no driving or clicking to do. The friend's timer begins when the first message arrives, so it can finish a few seconds after yours. If it stops early, keep the reason rather than restarting it.
6. **Both players** type these commands, one at a time:

   ```text
   /akart net report
   /akart net evidence
   ```

7. Save each player's complete output and give both sets to Codex before anyone reloads or starts another attempt. Codex compares the two sides; one player's report alone cannot prove which messages arrived.

To cancel at any point, either player can type `/akart net stop`. Do not increase the rate to get past an error.

For the short reminder inside WoW, type **`/akart net help`**. Reading help never starts the test, registers the prefix or sends a message.
