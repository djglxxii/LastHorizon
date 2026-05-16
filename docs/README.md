# Documentation Index

## Research

Background reading and external references that inform the design.

- [`research/schump-deep-research-report.md`](research/schump-deep-research-report.md) — Deep research report on the Invaders + Blazing Lazers + BALL x PIT hybrid concept. Reference material only; several elements of the report (BALL x PIT-style mid-run recombination, town/base-building layer, mid-combat pause-and-pick upgrade choices) have since been explicitly rejected — see `design/decisions.md`.

## Design

The active design log and supporting design notes.

- [`design/decisions.md`](design/decisions.md) — chronological log of committed design decisions, append-only, **Decision / Reasoning / Implications** format. This is the authoritative source for current design state until the GDD is drafted.
- [`design/feedback.md`](design/feedback.md) — external review of the decision log. Signal, not a design source.

Planned design artifacts:
- `design/GDD.md` — top-level game design document (vision, pillars, core loop, systems) — to be drafted once decisions stabilize.
- `design/systems/` — deeper specs per system (typed weapons, factions, formations, bosses, HUD) as they emerge.
- `design/scope.md` — prototype scope and milestone targets.

## Decisions

Architecture and tech decision records (ADR-style). Each file captures the decision, alternatives considered, and rationale.

- _None yet. Engine, language, and tooling choices will live here once made._

## Conventions

- Design docs live in `docs/design/` as Markdown.
- External research goes in `docs/research/`, kept read-only after import.
- Decisions about tech stack, architecture, or scope changes get a dated entry in `docs/decisions/`.
