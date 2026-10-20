# Codex handoff — bounded WHISPER transport probe

Prepared 2026-10-20, Europe/Oslo. M2 experiment preparation only: no live traffic, multiplayer architecture or gameplay replication. M0/M1/M3 and all real transport gates remain open.

## Branch, scope and preserved work

| Item | Verified state |
|---|---|
| Repository | `https://github.com/PhilForever/AzerothKart.git` |
| Current feature | `codex/transport-probe` in existing `../AzerothKart-Codex-Review` |
| Base | `b1cd42c54c368eb6c14aef392b36808836be6507`, prior Oval collision slice |
| Result | Completed `feat: add bounded opt-in transport probe`; resolve with `git log -1 codex/transport-probe` and use the immutable hash from the final report |
| Main / local origin/main | `f923d15`, not integrated or pushed |
| Other Codex checkout | `../AzerothKart`, `codex/handoff-contracts` at `5570968`; three empty untracked handoff placeholders preserved |
| Claude inspected checkout | `../AzerothKart-Claude`, `claude/track-ui` at `5734335`; active uncommitted Presentation/UI/presentation-test/UI-test edits and untracked `Claude outputs/`/`scripts/build_wc3_kart.py` preserved; wait for its handoff before integration |
| Shared deployment | Claude reports scenery/shadow install `0bf6fd0`; no deployment or client input occurred here |

Reserved before implementation: new pure/accounting and adapter modules/tests, Core slash/event wiring, TOCs/structural validator/test registrations, network contract/manual/architecture/memory docs. No UI/render/physics/track/asset source changed from the base. No changes to SavedVariables, another addon, other checkout or installed files. No branch merge/reset/rebase/cherry-pick, push/tag/release or worktree cleanup.

This source branch descends from the shared sprite review plus Oval work; its artwork is older than Claude's installed scenery. Do not install it directly over that build. Reviewed integration must preserve Claude's newer assets. The canonical untracked Claude handoff placeholder also needs inspection/preservation before a later integration. Do not run worktree pruning/GC from Claude's Linux mount environment.

## Implemented experiment

- Pure `NetworkProbe.lua`: explicit clock, bounded mutable accounting, exact printable DATA/ACK codec, injected sender callback, summaries and sequence evidence. It has no WoW globals, Physics access, simulation seed or gameplay state.
- `TransportProbe.lua`: guarded `C_ChatInfo`/enum boundary. Core routes `/akart net ...` and forwards all addon-event arguments. The adapter consumes prefix/text/channel/sender, reuses the existing Core event frame and owns its OnUpdate only while armed. No new Frame/UI object or input capture API.
- On addon load/Init: no prefix registration, CHAT_MSG_ADDON subscription, update callback or network call. Explicit arming registers them; stop removes event/update work. Prefix registration can remain in the client after stopping, but no packet work continues.
- Directed WHISPER only. Both testers explicitly arm the same fresh six-character uppercase/alphanumeric ID and matching rate/size/duration. Typed full `Name-Realm` matches the event sender with Lua ASCII case conversion only; no guessed realm expansion, Unicode folding, discovery or authentication.
- Defaults 0.5 DATA/s,16bytes,120seconds. Allowed rates 0.5/1/2/4, exact DATA sizes 16/64/128/220 including the10-byte envelope, duration integer 10–120, at most 480 sequences. ACKs always 16 bytes. Prefix adds 7 bytes per actual API call, separately from payload and unknown transport overhead.
- First DATA is scheduled after one interval; at most one due DATA/update, with missed slots recorded instead of catch-up bursts. One ACK per unique valid DATA, no ACK-of-ACK, no duplicate ACK response or retries. A four-token ACK bucket refills 4/s and aborts before an excess call. That local guard is not a transport-capacity result.
- Five-second ACK deadline stops new DATA and permits ten seconds of drain, anchored to the earliest original send deadline or window end. A resumed callback cannot extend it; receive processing checks expiry too. Exact end-time update can send the final scheduled slot.
- Listener waits at most 30 seconds for first DATA, then uses a bounded receive window and normal ten-second drain. During active listening, five seconds without unique valid DATA stops it. Normal drain deliberately follows its explicit endpoint instead of the idle rule.
- Abort on failed/unknown/throwing/throttled sends, missing/invalid capability/clock, receive/rejection/burst limits, manual stop, combat/world/logout/reload or a local drive. No auto-resume/rate escalation. Same-process session IDs are remembered up to 64, with reuse rejected; reload clears history, so a genuinely fresh ID remains required.
- Raw enum outcomes, local enqueue and delivery evidence are separate. Rejections cover sender/channel/session/version/type/sequence/size/padding. Maps, samples and sequence arrays are capped. No arbitrary payload/error strings or peer identities are copied into reports, no personal logs/CSV/SavedVariables are written.

`Report` prints seven bounded lines: session/config/phase/reason and frozen elapsed seconds (arm to last accounting, including any drain); DATA/ACK attempts/outcomes/planned/missed slots; receipt/duplicate/reorder/ACK deadline counters; raw result/rejection maps and payload/prefix byte totals; nearest-rank RTT/gap percentiles and samples; interpretation reminder. No samples is NA, not zero latency. RTT uses one sender clock and includes callback/queue/peer processing, not one-way wire time. Arrival/reorder counters refer to unique DATA; matched ACKs have their own counter.

`Evidence` prints up to 12 chunks of 160 positions plus a legend: `sent`, `received`, `acks_sent`, `acks_received`. Sender outcomes use 1/f/u/.; receipt maps use 1/.. Reconcile A's accepted DATA set with B's seen set, then B's accepted ACK set with A's matched ACK set. Missing ACK alone is not DATA loss.

PARTY, simultaneous bidirectional DATA, 4/8-client fan-out, lobby, race replication and an automatic evidence exporter are not implemented. New probe commands are diagnostics, not advertised multiplayer.

## Source API evidence and actual-client limits

Read-only primary source inspected under parent workspace `research/upstream/wow-ui-source-forever-70450`, version 1.60.1.70450:

- Generated ChatInfoDocumentation lines 469/516/803 describe prefix registration, SendAddonMessage arguments/result and CHAT_MSG_ADDON payload.
- ChatConstantsDocumentation declares registration Success/DuplicatePrefix and send Success/throttle/failure enum names.
- Send arguments disallow secret values. The adapter sends only its own printable packet strings and typed peer scope; it never unwraps protected values. Unknown/opaque values abort instead of being coerced into success.

These are source expectations, not executed installed-client calls. Full sender spelling/realm normalization, cross-realm reachability, actual return values, registration, event delivery, sustainable throughput/order/latency/throttle and reconnect remain **NOT RUN**. A contradictory installed result requires review, not guessed legacy boolean handling.

## Changes/integration contract

Both TOCs load 14 modules: existing order through UI, then NetworkProbe, TransportProbe, Core. Static validator expects that synchronized order and 52 required paths. The runner has two new focused modules; UI tests load the same namespace order and verify actual Core slash/event routing.

The experiment mutates only its own capped diagnostic state. Physics v7, all 15 fields, Oval v2 solids, Mirage geometry, camera/sprite presentation, race/checkpoint rules and driving/input lifecycle are unchanged. Explicit UI pool stays **9 frames / 113 textures / 13 font strings**; bootstrap frame was already excluded from that count. Read [API_CONTRACTS](../API_CONTRACTS.md) and [PROTOCOL](../PROTOCOL.md) before extending it.

Codex owns these transport/accounting systems. Claude owns maps/karts/rendering; shared Core/load-order/contracts/tests need reviewed integration. Multiplayer retains priority over ghosts/time trials; release still requires verified multiplayer and Claude's three maps/eight karts under ADR0010. Eight karts is not evidence of eight clients.

## Tests actually executed

Windows Python `C:/Python314/python.exe`, Lua5.1 via pinned Lupa2.8 supplied from the canonical ignored dependency directory through process-local PYTHONPATH.

| Check | Result |
|---|---|
| `scripts/test_lua.py --runtime lua51 --tests network_probe transport_probe ui` — final run | PASS: 34 Lua files parsed; all three modules executed. Codec lengths/bounds, pacing/skips, all outcome classes, timeout/late ACK, hitch-anchored sender/listener drain, exact-end schedule, ACK burst/flood limits, stale/fresh sessions, raw-map/evidence caps, percentiles/NA and frozen elapsed. |
| Adapter/Core/UI doubles in that run | PASS: inactive startup, explicit commands, API/enum/registration/event/clock failures, throttle/unknown outcomes, lifecycle cleanup/no resume, bounded output/session cache; real Core slash/event forwarding; existing UI/capture/race/pooling/sprite fallbacks. Mock pool 9/113/13 through 1,001 updates, 0 combat propagation calls. |
| Initial focused attempt | Pure engine passed, adapter then failed an outdated two-bitmap output count after four-map evidence was added; corrected expected 13 lines and asserted all four kinds. A later independent review found hitch-based drain extension, fixed with targeted regressions; subsequent/final focused runs passed. No failed attempt is reported as a pass. |
| `scripts/validate_project.py` | STATIC PASS: 52 paths, synchronized TOCs, docs/protocol links, header-only ledger. No Lua/client code executed by this validator. |
| Independent read-only review | Timing issue above fixed and re-reviewed; no remaining material issue found. |
| `git diff --check` / staged equivalent | PASS: scoped source/docs whitespace; line-ending normalization notices informational. |
| Native Lua / Lua5.4/full current suite, deployment/reload, actual prefix/send APIs, two-client/reconnect/PARTY/bidirectional/scale/performance | NOT RUN. No network capacity, client acceptance or milestone completion inferred. |

The `network-ledger.csv` remains header-only. All packet/timing results above are injected/offline assertions. UI counts exclude Core/templates/native internals and are not a client CPU/GPU/FPS guarantee.

## Next single task

**Review/integrate this source with Claude's current build, then execute the first consenting two-client WHISPER window** in [MANUAL_NETWORK_CHECKLIST](../../tests/MANUAL_NETWORK_CHECKLIST.md). First verify both clients' enum/source contract without sending; arm B's listener and A's lowest-rate 16-byte/0.5 DATA/s window promptly, using a fresh session and exact event peer spelling. Record real reports/evidence and reconcile sets before escalating or selecting architecture. No user test was requested or client used this implementation run.

If two clients/integration are unavailable, keep results pending and prepare an offline reconciliation helper against these four evidence maps; do not fill the ledger with synthetic results or begin broad replication/ghosts instead. Deployment remains serialized with Claude and separately authorized.
