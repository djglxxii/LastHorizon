# Prototype Scope

Scope for the first playable prototype of Last Horizon. Not a full vertical slice — a focused playtest target designed to answer the highest-risk open questions in the design log before broader content authoring begins.

## Prototype v1 goal

Playtest the **dual-role energy meter** — the single most novel and load-bearing mechanic in the design log (2026-05-16). Almost every other system is a known shmup pattern in a new outfit; if firing-as-spend doesn't create real per-shot tension, or if dropping back to the pea shooter feels punishing rather than rhythmic, a lot of downstream decisions get reopened. v1 must prove that loop works at the feel level before content scales.

## In scope

- **One faction.** Placeholder visual identity, no lore.
- **One stage** of that faction — a long descending armada per 2026-05-16 stage shape. No boss.
- **Pea shooter** (permanent, auto-fires, no player input per 2026-05-16).
- **One typed-weapon slot** with a dual-role energy meter (shield + ammo).
- **3–4 weapon families**, all **common rarity**, single tuning each. No rares, no legendaries.
- **Same-family pickup refills energy to full; different-family swaps at full energy** (per 2026-05-19).
- **Two enemy types:** baseline (pea-shooter killable) and one elite/heavy (effectively needs typed weapon). No rushers.
- **Weapon-chip carriers** (faction-flavored, in the descending armada, leak risk per 2026-05-16).
- **Fuel-cell carriers** (coalition supply from bottom/sides, no leak risk per 2026-05-16).
- **Collision interception** with placeholder tuning: weapon energy → capped shield absorption → leak (2026-05-14).
- **Defense Grid Integrity meter**, front and center.
- **Brief post-hit invulnerability** (2026-05-14).
- **Narrow vertical playfield** — side panels can be placeholder rectangles, not styled instrumentation yet.

## Deferred (intentionally out of v1)

- Boss encounters.
- Strategic mini-map side panel and planet view side panel (placeholder only).
- Defense Grid repair carriers — skip until we measure how fast the Grid actually drains in unassisted play.
- Rusher behavior.
- Additional factions, faction-themed visual variety, stage-slot intensity presets.
- Rare and legendary rarity tiers.
- Cross-run reverse-engineered drop pool (no cross-run state at all in v1).
- Bi-modal threat profile audit — with one faction the question is moot.
- Coalition pressure multiplier.
- Between-stage screen.
- Route choice / run branching.
- Post-clear difficulty ladder.
- Meta-progression of any form.
- Faction-specific bullet styles, palettes, hull designs beyond placeholder.

## What v1 is designed to answer

1. Does **firing-as-spend** create real per-shot tension, or does it feel fiddly and joyless?
2. Does dropping back to the **pea shooter** feel like meaningful vulnerability, or just punishment?
3. Do **pickup swap decisions** ("commit to my current family or risk it for the fresh one") create real tactical tension?
4. Does **collision interception** find a use case in practice, or does it stay theoretical?
5. Does the **single-tuning weapon model** (post-2026-05-19) land family identity in one read, or do weapons feel one-note? (Direct test of the open question opened 2026-05-19.)
6. How fast does the **Defense Grid** actually drain in unassisted play? Feeds the deferred repair-carrier tuning.
7. Rough ballpark for **collision tuning**, **drop tuning**, and **Grid damage per leak**.

Directional answers are sufficient; numerical tuning values do not need to be final.

## What v1 is NOT designed to answer

- Stage count per run.
- Faction roster size and order.
- Route choice / run branching.
- Coalition pressure multiplier form.
- Between-stage screen.
- Post-clear difficulty ladder.
- Pickup readability across a many-faction many-rarity pool.
- Cross-run reverse-engineered drop tuning.
- Stage-slot intensity preset shape.

These need a second prototype that adds run shape on top of a working core loop. Trying to answer them in v1 is the trap.

## Risks

- **If the dual-role meter doesn't work**, the auto-fire pea shooter decision (2026-05-16) probably gets revisited too. The two were committed together and only make sense as a pair. v1 should be ready to surface that.
- **If single-tuning weapons feel flat** with only 3–4 commons, v2 should expand the roster before re-introducing rarity tiers — depth might come from variety, not from per-weapon power gradient.
- **Engine choice constrains iteration speed.** Picking a stack that makes energy-meter tuning slow to iterate will silently lengthen v1 by weeks. Pick for iteration feel, not for production fit.

## Tech stack

Tech stack is **not decided in this doc**. Engine, language, and tooling decisions belong in `docs/decisions/` as ADRs. Whatever stack is chosen, the constraint above (fast iteration on energy-meter and drop-tuning values) is the highest-priority criterion for v1.

## Done criteria

v1 is "done" when the team has a clear, evidence-backed directional answer to each of the seven questions above. Tuning values do not need to be locked. If any answer is "we still don't know," v1 is not done.

## After v1

Once v1 has produced its answers, v2 expands scope to test the next layer of design risk:
- A second faction with distinct mechanical identity, to test the bi-modal threat profile (2026-05-18) in practice.
- Stage-slot intensity scaling across two stages (2026-05-18).
- Rare and legendary rarity tiers introduced into the drop pool (2026-05-19).
- Rusher behavior for at least one faction (2026-05-16).
- Boss encounter for one faction.
- The strategic mini-map side panel and planet view as real instrumentation rather than placeholders.

v2 scope is captured here as a forward-looking note; it will be specified in detail only once v1 has produced its answers and any of its decisions have been revisited.
