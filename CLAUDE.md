# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Note for non-Anthropic agents:** `AGENTS.md` in this repo is a symlink to this file. They are the same content — read only one. If your tooling auto-loads both, ignore the duplicate.

## Project status

Last Horizon is in **pre-production**. There is no engine, language, or build system chosen yet. `src/` and `tests/` are empty placeholders (`.gitkeep` only). All active work is **design documentation** in `docs/`. Do not invent build/test/lint commands — none exist. If asked to set up tooling, treat it as a tech-stack decision that needs an ADR in `docs/decisions/` first.

## The game in one paragraph

A roguelite vertical shmup fusing Space Invaders descending pressure, Blazing Lazers-style typed-weapon loadouts, and faction-themed stages. The player defends a single planet via a shared **Defense Grid Integrity** meter (the only health bar — ship cannot be destroyed). A permanent pea shooter is always firing; above it sits one **temporary typed weapon** (levels 1–3) fueled by energy that drains from hits and refills from same-type pickups. Each stage is a different alien faction with its own visual + mechanical identity and its own weapon-chip pool; defeating a faction unlocks its weapons into a persistent cross-faction "reverse-engineered" rare drop pool for future runs.

## Repository layout

```
docs/
  research/      external reference material (read-only after import)
  design/        active design docs — decisions.md is the source of truth
  decisions/     ADR-style tech/architecture decisions (none yet)
src/             empty — no engine selected
tests/           empty — no engine selected
assets/          contains the accepted gameplay mockup
```

## How design work happens here

The design process is **decision-log driven**. `docs/design/decisions.md` is a chronological log of design commitments, each with **Decision / Reasoning / Implications** sections. It is the authoritative source for current design state — newer entries supersede older ones (e.g., the 2026-05-15 large-weapon-pool entry explicitly notes tension with the 2026-05-14 max-level-3 entry).

When the user makes a new design call:
- Append a new dated entry to `docs/design/decisions.md` in the same format (Decision / Reasoning / Implications, `---` separators, date heading `## YYYY-MM-DD — short title`).
- If it supersedes or conflicts with a prior entry, say so explicitly in the new entry and add it to the "Open questions" section at the bottom if a follow-up is still needed.
- Do **not** silently edit old entries — the log is append-only history.

`docs/design/feedback.md` is external review of the design log, not a design source. Use it as a signal of what is working and what to watch, not as a decision.

`docs/research/schump-deep-research-report.md` is imported reference material. Treat it as read-only; do not rewrite it.

`docs/README.md` lists planned-but-not-yet-written artifacts (`design/GDD.md`, `design/systems/`, `design/scope.md`). These are the next docs to draft once decisions stabilize.

## Load-bearing design invariants

When proposing systems, mechanics, or content, these are committed and should not be re-litigated without an explicit superseding decision:

- **No base building, no town layer.** Meta-progression, if any, stays flat (unlocks, archive screens).
- **No mid-combat pauses for upgrade picks.** Build expression is in-combat pickups only; no reactor / fusion menu.
- **Defense Grid Integrity is the only health meter.** Ship and planet share it. Ship cannot be destroyed.
- **Damage hierarchy:** typed-weapon energy absorbs enemy fire first → bare pea-shooter hits cost light Grid damage → enemy leaks past player cost heavy Grid damage → collision spends weapon energy first, then capped shield absorption, then remainder continues toward planet.
- **Weapon model:** permanent pea shooter + one temporary typed-weapon slot, levels 1–3, same-type levels & refills / different-type swaps to level 1.
- **Stages are faction-themed**, ~4 faction stages + a final boss; weapon drops in a stage come from that faction's pool; defeated factions unlock their weapons into a rare cross-run drop pool.
- **Narrow vertical playfield (~9:16) with non-interactive side panels** (strategic mini-map of the larger battle / planet view). Extra screen space is instrumentation, not playfield.
- **Visual target** is the mockup at `assets/last-horizon-gameplay-mockup.png` — readable retro-modern arcade, dark UI, saturated weapon/shield effects.

## Open follow-ups (don't assume resolved)

The bottom of `decisions.md` tracks open questions. The biggest current tension: the levels 1–3 system was designed for a small fixed type pool, but the later large-weapon-pool decision makes same-type drops rare, so the level mechanic may need rework. Don't propose new systems that assume the level system is settled.
