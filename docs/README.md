# Documentation Index

## Research

Background reading and external references that inform the design.

- [`research/schump-deep-research-report.md`](research/schump-deep-research-report.md) — Deep research report on the Invaders + Blazing Lazers + BALL x PIT hybrid concept. Reference material only; several elements of the report (BALL x PIT-style mid-run recombination, town/base-building layer, mid-combat pause-and-pick upgrade choices) have since been explicitly rejected — see `design/decisions.md`.

## Design

The active design log and supporting design notes.

- [`design/decisions.md`](design/decisions.md) — chronological log of committed design decisions, append-only, **Decision / Reasoning / Implications** format. This is the authoritative source for current design state until the GDD is drafted.
- [`design/scope.md`](design/scope.md) — v1 prototype scope and done criteria. Defines what the first playable prototype is testing and what is deliberately deferred.
- [`design/feedback.md`](design/feedback.md) — external review of the decision log. Signal, not a design source. Predates the 2026-05-19 level removal; read as a snapshot, not current state.

Planned design artifacts:
- `design/GDD.md` — top-level game design document (vision, pillars, core loop, systems) — to be drafted once v1 prototype playtest answers the open questions in `scope.md`.
- `design/systems/` — deeper specs per system (typed weapons, factions, formations, bosses, HUD) as they emerge.

## Decisions

Architecture and tech decision records (ADR-style). Each file captures the decision, alternatives considered, and rationale.

- [`decisions/0001-engine-and-language.md`](decisions/0001-engine-and-language.md) — Godot 4.x + GDScript for v1 prototype (2026-05-19).

## Conventions

- Design docs live in `docs/design/` as Markdown.
- External research goes in `docs/research/`, kept read-only after import.
- Decisions about tech stack, architecture, or scope changes get a dated entry in `docs/decisions/`.
