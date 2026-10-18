# ADR — Pure deterministic simulation

Decision: fixed 60Hz simulation and tick-indexed input independent of WoW renderer. Reason: stable game feel/replays/net debugging. Consequences: input tape, explicit seed, bounded catch-up. Status: Accepted for design; implementation to verify.
