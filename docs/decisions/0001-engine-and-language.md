# ADR-0001 — Engine and language: Godot 4.x with GDScript

**Status:** Accepted, 2026-05-19.

## Context

Last Horizon is in pre-production. `src/` and `tests/` are empty; no engine, language, or build system has been chosen. The v1 prototype scope (`docs/design/scope.md`) names *iteration speed on energy-meter tuning* as the highest-priority criterion for the chosen stack — v1's job is to playtest the dual-role energy meter at the feel level, not to deliver production polish. An engine that silently lengthens v1 by weeks (compile times, heavy tooling, no hot-reload of tuning values) is the named risk.

A separate prior prototype using a closely related design was previously built in Godot 4.x + GDScript on a single-developer cadence, and reached a working build with player movement, auto-fire, formation enemies, and a basic upgrade UI before its design pivoted away. That prior project is not carried forward as code or docs; it is a data point that this stack is sufficient for vertical-shmup mechanics at this scale.

## Decision

**Godot 4.6.2-stable** as the engine (the latest stable 4.x maintenance release at v1 start, 2026-05-19), **GDScript** as the primary language. Future patch upgrades within the 4.6.x line are allowed; minor or major version bumps require a superseding ADR.

## Alternatives considered

**Godot 4.x + C#.** Stronger typing and faster execution, but C# adds a compile step between tuning-value edits and play, directly conflicting with the iteration-speed criterion. Acceptable at production scale; not at prototype scale. Reasonable to revisit if v1's done criteria are met and v2 enters a phase where production polish outweighs feel-iteration.

**Unity (C#).** More mature ecosystem and asset store, but 2D ergonomics are weaker than Godot's, account / Hub overhead adds solo-developer friction, and editor startup is heavier. No upside for this prototype.

**Bevy (Rust).** Strong ECS and type system, but Rust compile times — even incremental — are an order of magnitude slower than GDScript for the tuning-tweak loop this prototype is built around. Strong fit for a different shape of project; not for this one.

**LÖVE (Lua).** Equally fast iteration and lighter than Godot, but v1 needs non-trivial UI work (multi-meter HUD, pickup readability surfaces) and Godot's built-in UI nodes save real time over building UI from scratch in Lua.

**Phaser / web stack.** Easier distribution but worse dev ergonomics and weaker tooling for a feel-focused prototype.

## Consequences

- **Engine wrapper.** v1 uses a pinned, locally-installed Godot binary rather than relying on a system install. A `tools/` bootstrap script — written fresh for this repo, not copied from the prior prototype — installs the pinned version and provides a wrapper executable. Engine version pinning is required for reproducibility.
- **Headless tests.** GDScript supports `--headless` execution. The first concrete test artifact should be a headless boot smoke test that loads the main scene and exits cleanly, runnable via the wrapper.
- **Editor state hygiene.** `.godot/` generated state, local engine downloads, build exports, and imported asset caches are `.gitignore`'d. Only authored source belongs in the repo.
- **Typed GDScript by default.** Prefer typed signatures for clarity. Style guidance, not a hard rule; relaxes during pure tuning passes.
- **Vertical playfield viewport** consistent with the design log's ~9:16 invariant. Specific dimensions and renderer choice (forward-plus vs. compatibility) are implementation details, not part of this ADR.
- **No carryover from the prior prototype.** Game code, scene files, design docs, task files, and tooling under `/home/djglxxii/src/_old/LastHorizon/` are reference only. v1's repo starts clean.

## Revisit conditions

This decision should be revisited if any of:

- v1 hits a performance ceiling GDScript can't clear.
- v1's done criteria (per `docs/design/scope.md`) are met and v2 enters a phase where production polish outweighs iteration speed.
- Team composition changes such that C#, TypeScript, or another typed language becomes a meaningful productivity gain.

## Open follow-ups

- Write the `tools/` bootstrap script and `.gitignore` entries (T001).
- Decide whether to add a CI smoke-test gate now or defer to v2.
