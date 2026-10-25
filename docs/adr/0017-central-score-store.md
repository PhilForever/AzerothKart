# ADR 0017 — Central score store; explicit client bridge required

Superseded as the active implementation path on 2026-10-25 by
[ADR 0018](0018-automatic-community-scores.md): the owner wants automatic
addon-only community sharing. The server-side component is retained but
deferred; no uploader or always-online scorekeeper was accepted.

Status: Accepted central persistent leaderboard direction from the owner's
2026-10-24 "get to work" response. Server-side core implemented in this slice;
live transport/deployment remain OPEN. No global-delivery acceptance implied.

Automatic solo finish records already exist locally. The owner wants a board
everyone can query and prefers the efficient reliable approach. Stop spending
friend-test windows on the failed private-server channel candidate. Build one
small durable central submit/query component with the existing record format,
compatibility boundaries and repeat-submission behavior.

Use SQLite with versioned/application/deployment metadata, atomic strictly-better
updates and bounded pages. Retain each player's best even outside the first50.
The configured board catalogue is generated from actual Lua course contexts.
Derive actor identity from a future trusted adapter; never treat a claimed name
or an embedded public-addon secret as authentication. Scores remain self-reported.

Available primary source70450 exposes no supported arbitrary HTTP/custom server
RPC/remote addon store. Its empty UiRpcRequestManager constants, game-specific
account purchase APIs and predefined browser URLs are not such a bridge.
This audit is not exhaustive runtime70532 absence proof, but supplies no valid
native endpoint to implement. Logged WHISPER between named clients is verified;
that does not establish a generic web endpoint or permanent scorekeeper service.

A supported game-server adapter or explicitly accepted external bridge is still
required. Ask the owner whether the product must be addon-only; do not silently
add a desktop uploader, always-online client/operator or game-file watcher.
Do not deploy a web service and claim the WoW addon can already reach it.
Keep the racer/local records usable and add no unreachable menu setting.

This ADR does not change physics, UI ownership, client safety, packet budgets,
release gates or public-sharing consent. No hosting, account creation, server
configuration change, auto-push or release is authorized by the storage design.
See [the component and exact boundary](../../services/leaderboard/README.md).
