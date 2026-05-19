# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Note for non-Anthropic agents:** `AGENTS.md` in this repo is a symlink to this file. They are the same content — read only one. If your tooling auto-loads both, ignore the duplicate.

## Project status

Last Horizon is in **pre-production**. There is no engine, language, or build system chosen yet. `src/` and `tests/` are empty placeholders (`.gitkeep` only). All active work is **design documentation** in `docs/`. Do not invent build/test/lint commands — none exist. If asked to set up tooling, treat it as a tech-stack decision that needs an ADR in `docs/decisions/` first.

## The game in one paragraph

A roguelite vertical shmup fusing Space Invaders descending pressure with a typed-weapon economy across faction-themed stages. The player defends a single planet via a shared **Defense Grid Integrity** meter (the only health bar — ship cannot be destroyed). A permanent pea shooter **auto-fires** continuously; above it the player operates one **temporary typed weapon** drawn from a large faction-gated pool with three rarity tiers (common / rare / legendary), and the player's fire input controls only that typed weapon. Typed-weapon energy is **dual-role** — it is both the sacrificial shield against enemy fire AND the fuel that powers the weapon — so every trigger pull is a deliberate spend. Each stage is a long descending armada operated by a distinct alien faction with its own enemy roster, rusher behavior, weapon-chip pool, and boss; defeating a faction unlocks its weapons into a persistent cross-run "reverse-engineered" drop pool.

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

The design process is **decision-log driven**. `docs/design/decisions.md` is a chronological log of design commitments, each with **Decision / Reasoning / Implications** sections. It is the authoritative source for current design state — newer entries supersede or amend older ones (e.g., the 2026-05-19 "Remove weapon levels" entry supersedes the 2026-05-14 max-level-3 entry outright and lists every other entry it amends).

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
- **Input model:** the pea shooter auto-fires continuously and is not under player input. The player's fire input controls only the typed weapon.
- **Energy is dual-role:** the typed-weapon energy pool is consumed by BOTH firing the typed weapon AND absorbing enemy fire. It is shield and ammo at once. When it reaches 0, the typed weapon expires and the player drops back to the pea shooter.
- **Weapon model:** permanent auto-fire pea shooter + one temporary typed-weapon slot drawn from a large faction-gated pool with **three rarity tiers** (common / rare / legendary). Each weapon family has a single tuning — no levels. Same-family pickup refills the energy meter to full; different-family swaps to the new family at full energy. Per-weapon-family firing cost is allowed and expected (each family defines its own per-shot energy drain), creating a thrifty-vs-thirsty axis on top of pattern and damage.
- **Power expression:** in-run power height lives entirely in **rarity tier** (rare and legendary pickups), not in level progression. Cross-run reverse-engineered drops can roll legendaries from defeated factions and are the slot-machine peak moment.
- **Difficulty source:** progressive difficulty comes from **enemy-side levers** (armada density, descent speed, elite mix, rusher cadence, bullet pattern complexity, leak penalty, carrier scarcity), not from weapons becoming stronger. Within-run difficulty rides the **stage slot** (each faction authors multiple intensity presets); faction order is randomizable.
- **Faction threat profile:** each faction must combine at least **two distinct handling demands** (bi-modal threat) so no single weapon family solves a stage. The three universal floors that keep wrong-matchup viable are: pea shooter clears baseline, energy retains shield value regardless of matchup, fuel/repair carriers function identically.
- **Stage shape:** each faction stage is a single long descending armada extending across multiple screen heights, opening with weaker enemies and intermixing tougher enemies (elites and rushers) at progressively greater density, culminating in a faction boss. The final run stage is the coalition warlord. Stage length must be long enough for the energy economy to cycle multiple times.
- **Enemy tiers per faction:** at minimum baseline (pea-shooter killable in time) and elite/heavy (effectively requires an active typed weapon to kill before leaking). Rushers (Galaxian-style dive bombers that break formation) are a separate category, faction-flavored, and optional per faction — a faction with no rushers is a valid identity choice.
- **Faction-themed stages,** ~4 faction stages + a final boss; weapon drops in a stage come from that faction's pool; defeated factions unlock their weapons into a rare cross-run drop pool.
- **Pickup sources are split by direction.** Weapon-chip carriers are enemy ships in the descending armada (leak risk if not engaged). Fuel-cell carriers are coalition supply approaching from the bottom/sides of the screen (no leak risk; engagement is pure opportunity cost). Defense Grid repair carrier source is still an open question.
- **Narrow vertical playfield (~9:16) with non-interactive side panels** (strategic mini-map of the larger battle / planet view). Extra screen space is instrumentation, not playfield.
- **Visual target** is the mockup at `assets/last-horizon-gameplay-mockup.png` — readable retro-modern arcade, dark UI, saturated weapon/shield effects.

## Open follow-ups (don't assume resolved)

The bottom of `decisions.md` tracks open questions. Many of the remaining ones — collision tuning, per-rarity weapon drop rates, single-tuning weapon depth, intensity preset shape, fuel-cell economy — explicitly need prototype playtest data to resolve, not more decision rounds. The core systems are stable enough that a scoped prototype focused on the dual-role energy meter is the natural next artifact; the historical "level system tension" was resolved 2026-05-19 by removing levels.

Note: `docs/design/feedback.md` was written before the 2026-05-19 level removal and still discusses the levels 1–3 system as committed. Read it as a snapshot in time, not current state.
