# Design Decisions Log

A running log of design commitments made during discussion, captured before they're folded into the GDD. Each entry: the decision, the reasoning, and the date.

---

## 2026-05-13 — No base building

**Decision:** Last Horizon will not have a base-building / town layer.

**Reasoning:** The BALL x PIT town layer is a recurring weak point in player feedback (clunky, sometimes feels tacked on relative to the combat). The research report flags this as a known pitfall. Meta-progression, if any, should take a flatter form (unlocks, archive screens) rather than a managed place.

---

## 2026-05-13 — No mid-combat pause for upgrade choices

**Decision:** Combat does not pause to present level-up / upgrade / recombination choices. BALL x PIT's "pause-and-pick" cadence is explicitly rejected.

**Reasoning:** The game's core fantasy is sustained descending pressure. Pausing combat to open a menu repeatedly breaks that flow and undermines the tension the formation system is supposed to create.

---

## 2026-05-13 — Build expression is in-combat pickups only

**Decision:** Build expression happens entirely through in-combat pickups, in the style of Blazing Lazers. There is no mid-run fusion / recombination reactor.

**Reasoning:** With pauses off the table and the "don't over-complicate" guidance, dropping the reactor entirely keeps the moment-to-moment loop tight and arcade-feeling. Power growth comes from picking things up while flying — weapon swaps, weapon level-ups, support modules — never from a menu.

---

## 2026-05-13 — Theme and fail-state: Planetary Defense Grid

**Decision:** The narrative frame is that an enemy is trying to reach the player's planet. The planet is protected by a **Defense Grid** with a finite pool of integrity. Every enemy that gets past the player and reaches the bottom of the screen damages the grid. When the grid reaches 0, the planet is destroyed and the run ends.

**Reasoning:** This gives the Space Invaders "don't let them reach the bottom" rule real stakes and a visible, persistent meter. It folds the formation pressure, the defended lower band, and the run-ending fail condition into a single coherent fiction.

**Implications:**
- The Defense Grid is the run-meter; it's always on screen.
- Enemies leaking past the player is a *cost*, not an instant loss — the player can absorb some leakage.
- Different enemy types likely do different grid damage on reaching the bottom (a swarm leaker ≠ a heavy that punches through).

---

## 2026-05-13 — Ship cannot be destroyed; hits drain weapon power

**Decision:** The player ship cannot be destroyed by enemy fire or collision. It remains in play until the shared Defense Grid Integrity pool reaches 0. Weapon model is Blazing Lazers-style:

- The **pea shooter** is permanent. It is always firing, never goes away, and is the baseline regardless of state.
- Above the pea shooter, the player has **one weapon family slot** that can hold a typed weapon — Type I, Type II, Type III, Type IV, etc. (e.g. Spread, Lightning, Ring, etc.).
- The active typed weapon fires *alongside* the pea shooter (not instead of it).
- Picking up a pickup of the **same type** as the currently equipped weapon **levels it up** (Type II level 1 → Type II level 2 → Type II level 3, etc.). Higher levels are more powerful — more bullets, wider spread, longer range, whatever fits that family.
- Picking up a pickup of a **different type** than the currently equipped weapon **swaps to the new type at level 1** (you lose your investment in the previous type).
- Taking an enemy-fire hit while a typed weapon is active drains typed-weapon energy/fuel instead of damaging the shared Defense Grid. If the energy/fuel reaches 0, the typed weapon expires and the player drops back to the pea shooter.
- Taking an enemy-fire hit while already stripped down to the pea shooter damages the shared Defense Grid instead, with cosmetic shield-hit feedback and a brief pea-shooter fire-rate interruption.

**Reasoning:** This is the Blazing Lazers loop the design report flagged as the model: deterministic, legible, and tactile. Same-type stacking rewards commitment to an archetype; different-type pickups create real decision tension ("do I lock in my current Type III, or risk it for that fresh Type IV?"); hits punish without ever fully disarming. Combined with the Defense Grid, it gives the same self-reinforcing pressure loop:

> Get hit → typed weapon energy drops → less upgraded-weapon uptime → more enemies leak past, or get hit while stripped → Defense Grid takes damage → eventually the planet falls.

**Implications:**
- Current weapon type, current level, and remaining energy/fuel are primary HUD elements.
- The visual identity of each weapon family must be instantly distinguishable at a glance (color-coded chips like Blazing Lazers is a strong precedent).
- Pickup choice ("grab this Type IV or skip it to protect my Type II level 3?") becomes a real moment-to-moment decision.
- Defense Grid Integrity is the *only* run-ending failure condition. The ship itself cannot be destroyed.

---

## 2026-05-13 — In-stage pickup categories

**Decision:** Pickups dropped during a stage fall into three confirmed buckets for the first prototype:

1. **Weapon pickups** — swap to a new weapon family (Type I / II / III / IV …) or level up the current one (Blazing Lazers-style).
2. **Fuel cells** — restore a small amount of typed-weapon energy/fuel without changing weapon type or level.
3. **Defense Grid repair** — exceedingly rare drops that restore some of the planetary shield meter.

A fourth bucket — **non-weapon enhancements** (bombs, satellites/options, speed, temporary Defense Grid overcharge, etc.) — is **deferred**. It may or may not be added later, once playtesting shows what gameplay actually needs.

**Reasoning:** Keeps the initial scope tight while supporting the temporary typed-weapon model. Weapon pickups create build expression, fuel cells sustain weapon uptime without accelerating level pacing, and rare Defense Grid repair gives limited recovery. Non-weapon enhancements are a "reach for it if combat needs more texture" decision, not a day-one requirement.

---

## 2026-05-14 — Ship and planet share one Defense Grid shield

**Decision:** The ship and planet do not have separate health or shield meters. They share a single **Defense Grid Integrity** pool. The ship is protected by a projection of the planetary Defense Grid, so damage to the ship drains the same meter that protects the planet.

**Damage hierarchy:**
- Enemy bullets hitting the ship while a typed weapon is active drain that typed weapon's energy/fuel instead of damaging Defense Grid Integrity.
- Enemy bullets hitting the ship while the player has only the pea shooter cause light Defense Grid damage.
- Enemies colliding with the ship resolve through the collision interception model: typed weapon energy is spent first, then the ship's shared-shield projection absorbs up to its collision cap, and any remaining enemy HP continues toward the planet.
- Enemies leaking past the player and reaching the planet line cause heavy Defense Grid damage. Leakage remains the worst outcome.

**Reasoning:** This keeps the fail-state simple: there is one health meter, and it belongs to the defended planet. Typed weapons act as the first sacrificial layer against enemy fire; once the player is reduced to the pea shooter, further enemy-fire hits are paid for by the shared shield. It also creates an interesting emergency choice: body-blocking an enemy can be a costly interception that prevents a much worse leak.

**Implications:**
- The HUD should present Defense Grid Integrity as the only health meter.
- Bare pea-shooter hit feedback should visibly and audibly affect the Defense Grid meter, reinforcing that the planet absorbed the hit, and should briefly interrupt the pea shooter's fire rate.
- Typed-weapon hit feedback should emphasize energy/fuel loss rather than Defense Grid damage.
- Enemy collision is not pure failure; it can be an intentional last-second defensive move.
- Tuning must preserve the hierarchy: bare enemy-fire hit is light damage, collision is a last-line resource conversion, and full enemy leakage remains the worst outcome.

---

## 2026-05-14 — Narrow vertical playfield with side information panels

**Decision:** The main combat field is a narrow vertical playfield, targeting roughly a 9:16 aspect ratio or slightly wider. Extra horizontal screen space is reserved for informational side panels rather than expanding the active combat area.

One side panel should show a non-interactive strategic mini-map: the defended planet, Defense Grid strength, the broader enemy squadron as tiny miniatures, boss presence when applicable, and any enemies that have already leaked past the player. Leaked enemies continue toward the planet in this side view and visibly strike the planet or shield. This view is purely informational; the player cannot interact with the mini-map, target enemies inside it, or navigate the playfield through it. The playable field is only a slice of the larger battle represented there.

**Reasoning:** A narrow vertical field supports the Space Invaders/shmup pressure fantasy: enemies descend toward a defended lower band, and the player reads threats in a focused column. Side panels let the game show strategic and fictional context without widening the combat lane or diluting formation readability.

**Implications:**
- The side planet view must not imply that leaked enemies are still actionable targets.
- The combat field remains the only interactive space.
- The mini-map can show how much of the enemy squadron remains, including boss presence, without letting the player act on that space directly.
- Planet impacts should reinforce Defense Grid damage through synchronized meter, audio, and visual feedback.
- Side panels can carry HUD information, but the main playfield must retain the critical moment-to-moment combat state.

---

## 2026-05-14 — Retro-modern tactical arcade visual direction

**Decision:** The accepted gameplay mockup in `assets/last-horizon-gameplay-mockup.png` establishes the current visual target: a polished retro-modern arcade/shmup presentation with a dark sci-fi interface, crisp readable silhouettes, saturated weapon and shield effects, and restrained side-panel instrumentation.

**Reasoning:** The mockup supports the current design goals: the narrow combat field remains dominant, the side mini-map communicates larger battle context without reading as playable, and the Defense Grid/planet view makes off-screen consequences visible. The style feels energetic without turning the screen into unreadable particle noise.

**Implications:**
- Prioritize readability over spectacle in the active combat field.
- Use dark neutral UI framing with contrasting blue shield effects, red/orange enemy impact language, and green/cyan player weapon fire.
- Side panels should feel like tactical instrumentation, not decorative cards or menus.
- The mini-map and planet panel should use simplified silhouettes/icons so they read as strategic information rather than alternate gameplay space.
- Future concept art and prototypes should compare against this mockup for layout, contrast, and information hierarchy.

---

## 2026-05-14 — Typed weapons are temporary energy states

**Decision:** Typed weapons are temporary energy/fuel states, not permanent upgrades. The pea shooter remains permanent and always available. When the typed weapon's energy runs out, the player drops back to the pea shooter.

Weapon pickups still define the primary build expression:
- Picking up a pickup of the **same type** as the current typed weapon levels it up and refills its energy.
- Picking up a pickup of a **different type** swaps to the new weapon family at level 1 and fills that weapon's energy.
- Enemy-fire hits while a typed weapon is active drain that weapon's energy/fuel instead of reducing its level.

**Reasoning:** Prior prototypes showed that persistent weapon upgrades could make the game too easy once the player stabilized. Temporary typed weapons turn power into a tempo resource: the player can become strong, but must keep earning that state through risky pickup collection. This better supports the core pressure loop, because weapon power naturally decays back toward vulnerability instead of becoming a solved permanent advantage.

**Implications:**
- Current weapon type, level, and remaining energy/fuel are all primary HUD elements.
- Pickup cadence becomes a major balance lever; too many refreshes will recreate permanent power, while too few will make typed weapons feel disposable.
- Same-type pickups reward commitment by both increasing power and extending uptime.
- Different-type pickups remain a meaningful tradeoff: switch archetypes now, or preserve the current high-level state.

---

## 2026-05-14 — Typed weapon max level is 3

**Decision:** Typed weapons max out at level 3.

**Reasoning:** A three-level weapon ladder is easier to read and balance than a deeper upgrade chain. It gives the player a clear arc from baseline typed weapon to strong peak state without creating too many intermediate states or making weapon power hard to tune.

**Implications:**
- Level 1 should establish the weapon family's identity.
- Level 2 should feel meaningfully stronger but still controlled.
- Level 3 should be a late-stage peak state, not something the player reaches early and maintains for most of the stage.
- Pickup timing and enemy/drop tables must prevent level 3 from becoming available too early in a stage.

---

## 2026-05-14 — Authored drop carriers and dynamic weapon sustain

**Decision:** Weapon and sustain pickups are driven primarily by authored drop carriers and stage/drop windows, not broad random loot from every enemy.

Confirmed drop categories:
- **Weapon chip carriers** drop typed weapon pickups.
- **Fuel-cell carriers** drop fuel cells that restore a small amount of typed-weapon energy/fuel without changing weapon type or level.
- **Defense Grid repair carriers** drop rare Defense Grid repair pickups.

Dynamic drop pacing should consider both stage progress and current player state:
- Early stage: level 1 weapon chips only.
- Mid stage: level 2 becomes available.
- Late stage: level 3 becomes available and should remain rare or tied to late pressure spikes.
- If the player has a level 2 typed weapon before level 3 is allowed, sustain should come from fuel cells rather than early level 3 chips.
- If the player has no typed weapon, weapon chip carriers become more important.
- If the player has low typed-weapon energy, fuel-cell carriers become more important.

**Reasoning:** Blazing Lazers appears to rely on particular item-bearing enemies, cycling item behavior, and orb thresholds rather than a flat random loot table. Last Horizon should use that lesson while adapting it to temporary typed weapons: level-up pacing and weapon sustain must be separated so the player can maintain a level 2 weapon without being handed level 3 too early.

**Implications:**
- Enemy/drop carrier placement is part of stage design, not just reward RNG.
- Fuel cells are now a confirmed pickup category for typed-weapon sustain.
- Stage progress gates the maximum available weapon level.
- Drop bias can help struggling players recover without breaking late-stage power pacing.
- The GDD should define exact stage-progress thresholds, fuel-cell restore amounts, and carrier spawn rules.

---

## 2026-05-14 — Defense Grid repair drops are rare authored carrier rewards

**Decision:** Defense Grid repair pickups come from authored Defense Grid repair carriers and should be exceedingly rare.

**Reasoning:** Defense Grid Integrity is the game's only health meter, so repair drops must feel valuable without undermining the pressure of leaks, bare pea-shooter hits, and collision absorption. Making repair tied to rare carriers keeps recovery legible and contestable instead of feeling like ambient random healing.

**Implications:**
- Repair carriers should be visually distinct and immediately readable.
- Repair drops should be rare enough that players cannot rely on them as the main survival plan.
- Exact restore amount, spawn cap, and stage placement remain prototype tuning values.
- Repair opportunities can be positioned as risky objectives during pressure waves.

---

## 2026-05-14 — Collision interception spends weapon energy before shared shield

**Decision:** Enemies have HP, and ship collision resolves by spending typed-weapon energy first, then limited shared-shield absorption. The ship and planet still share one Defense Grid shield, but the ship projection can only absorb up to a predetermined collision cap **N** before the remaining enemy threat continues toward the planet.

Collision resolution order:
1. Typed weapon energy/fuel is spent first to reduce the enemy's HP.
2. If enemy HP remains, the ship's shared-shield projection absorbs up to **N** additional HP. This absorption damages Defense Grid Integrity because the ship and planet share one shield.
3. If enemy HP remains after weapon-energy spend and capped shield absorption, the enemy survives and continues advancing.
4. Any remaining enemy HP that reaches the planet line damages Defense Grid Integrity.

**Reasoning:** This makes ramming a resource conversion, not a free defensive move. A player with an active typed weapon can sacrifice weapon energy to reduce or destroy an enemy before it leaks. A player with only the pea shooter has no weapon-energy buffer, so ramming does not reduce total Defense Grid loss by itself: the shield absorbs some damage at the ship, and any remainder still reaches the planet. Because the player ship sits at the very bottom of the playfield, collision usually happens at the last line of defense; an enemy that survives contact will likely pass by shortly afterward, leaving little or no opportunity for follow-up shots unless it is nearly destroyed already.

**Implications:**
- Ramming with an active typed weapon can be beneficial, but it spends weapon uptime.
- Ramming with only the pea shooter has no inherent Defense Grid advantage over letting the enemy leak.
- Heavier enemies can survive collision and continue toward the planet with reduced HP.
- The collision cap **N** prevents the ship projection from absorbing unlimited enemy HP.
- Collision is a last-line interception, not a reliable setup for finishing enemies after contact.
- Additional feedback or control penalties may still be needed so repeated ramming feels costly and readable.

---

## 2026-05-14 — Brief post-hit invulnerability

**Decision:** After the player ship takes an enemy-fire hit or collision/contact hit, it receives a brief invulnerability window so a single bad moment cannot chain multiple energy drains, bare pea-shooter grid hits, or collision absorptions in rapid succession.

**Reasoning:** The game should punish mistakes, but not let overlapping bullets or enemy bodies instantly consume a large amount of weapon energy or Defense Grid Integrity before the player can respond. A short recovery window keeps damage readable and gives the player a chance to reposition.

**Implications:**
- The recovery window should be long enough to prevent continuous hit stacking, but short enough that sustained bad positioning still remains dangerous.
- Hit feedback must clearly communicate temporary invulnerability without obscuring bullets, enemies, or the Defense Grid meter.
- Exact duration remains a tuning value for the prototype.

---

## 2026-05-15 — Stages are faction-themed; one planet, varied invaders

**Decision:** Each stage in a run features a distinct alien faction in the invasion. The defended planet stays singular, but the attackers change stage to stage. Each faction has both a visual identity (enemy silhouettes, color palette, bullet style, carrier-ship designs) and a mechanical identity (formation behaviors, descent patterns, HP/shield profile, primary threat type). A run targets roughly four faction stages plus a final boss stage; exact count is tunable. The final stage is the coalition warlord or prime instigator behind the invasion.

**Reasoning:** Defending a single planet across multiple stages creates a visual sameness problem — every stage reads the same backdrop and the same enemies. Two alternatives were considered and rejected:

1. **Multi-planet campaign** (each stage is a different defended planet) — rejected because it dilutes the singular "defend YOUR planet" emotional core that anchors the Defense Grid fiction (2026-05-13 and 2026-05-14 entries), and adds thorny questions about per-planet vs. shared grids and what failure on an outer planet means.
2. **Single planet with cosmetic variety levers only** (time of day, altitude, sky mood) — rejected as the *only* lever because it provides backdrop variety but not mechanical variety, so each stage still plays the same.

Faction-as-stage is stronger than either alone: it preserves the single-planet emotional core, provides strong visual distinction between stages, and adds *mechanical* variety against the typed-weapon model without requiring biome fictionalization on a single planet. It also gives the run a natural climax — a final boss as the warlord of the coalition.

**Implications:**

- Each faction is a content unit. Designing a faction means: a handful of enemy silhouettes, a color palette, a bullet style, formation behaviors, the faction's own carrier hulls (weapon-chip, fuel-cell, repair), and a faction boss.
- Each faction should have a distinct *mechanical* signature against the typed-weapon model. Illustrative directions (not committed): swarm/leak-pressure faction, armored/typed-weapon-required faction, shielded/pea-shooter-immune faction, long-range/sniper faction.
- The Defense Grid sky/backdrop shifts per stage to reflect the current attacker (organic glow, industrial particulate, prismatic shimmer, etc.), so the whole screen reads different even though the planet is the same.
- The strategic mini-map side panel (2026-05-14) continues to show the same defended planet but should reflect the current attacking faction in its squadron miniatures.
- Run shape is implicitly **winnable**, not endless. Roughly four faction stages plus a final boss stage; tunable. Replay extension after first clear is expected to come from a separate difficulty-ladder mechanism (not decided here).
- Faction defeat is a natural meta-progression hook (e.g., reverse-engineered tech unlocks per faction), but the meta-progression layer itself remains undecided.
- The "between-stage screen" open question is now sharper: stages have clear faction boundaries (faction defeat → next faction arrives), so there is well-defined space between them if we want to use it.

---

## 2026-05-15 — Large weapon pool, faction-gated primary drops, reverse-engineered rare drops after faction defeat

**Decision:** The typed-weapon pool is large — many weapon families, not a fixed four — and access to those weapons is gated through two channels:

1. **Primary channel — faction-themed drops.** At each stage, the weapon-chip carriers operated by the attacking faction drop weapons from *that faction's* weapon pool. Stage 1's faction drops Stage 1's weapons; later factions drop their own weapons. A player cannot get late-faction weapons in early stages through normal play.
2. **Secondary channel — reverse-engineered cross-faction drops.** Once a faction has been defeated in any prior run, that faction's weapons enter a persistent cross-faction "reverse-engineered tech" pool. Subsequent runs can roll rare drops from that pool at *any* stage, narratively framed as the player's coalition deploying reverse-engineered tech rather than the current attacker's tech. The drop chance is intentionally small — this is a "tasty rare moment," not a reliable shortcut to peak power.

**Reasoning:** The general shape is inspired by *Enter the Gungeon* (large weapon pool, gated access expanding over runs) but does not replicate Gungeon's specifics. The two-channel structure delivers several things at once:

- **Within-run identity:** faction-themed primary drops preserve each stage's combat character (the typed weapons a player can field in Stage 1 are shaped by Stage 1's faction), reinforcing the 2026-05-15 faction-stage decision.
- **Cross-run progression that is visible:** new weapons appearing in early stages of later runs is tangible proof of meta-progression, stronger than a stat number going up.
- **Run-to-run surprise:** the rare reverse-engineered drop is a slot-machine moment that makes individual runs feel distinct.
- **Narratively grounded gating:** the player cannot get a late-faction weapon in Stage 1 because that faction has not arrived yet, and they can only get the reverse-engineered version once their coalition has actually beaten that faction in a prior run. There is no abstract "tier" or "rarity" gate to explain.

**Implications:**

- Each faction must author its own weapon-family roster. The total typed-weapon pool will be substantially larger than the four-type model implicit in earlier decisions; exact counts per faction are tunable.
- Faction defeat is the unlock event. Encountering or even temporarily using a faction's weapon does *not* unlock it; the player must defeat the faction's stage in a prior run.
- The reverse-engineered drop chance is a tuning value, not a decision. The design intent is "tasty rare moment that makes a run feel special," not "reliable shortcut to power." Too high trivializes early-stage power pacing; too low and the mechanic does not feel real.
- The 2026-05-14 "Typed weapon max level is 3" decision was designed around a small fixed type pool where same-type stacking was common. With a much larger pool, same-type drops will become rare and the level system may be redundant or need simplification. This tension is acknowledged as an open follow-up; the level system is not changed by this decision.
- The 2026-05-14 "Authored drop carriers and dynamic weapon sustain" entry's within-stage *level* progression language (early/mid/late stage gating by weapon level) describes the same drop system using terminology that predates this decision. The faction-themed gating model now carries the within-run progression weight; that earlier entry should be revisited and aligned once the level-system follow-up is resolved.
- HUD design must communicate weapon identity clearly given a larger pool. Pickup readability ("what is this weapon I am about to grab?") becomes a more important UX problem in a many-weapon pool and may need preview or icon language so the same-type-stacks-vs-different-type-swaps decision stays informed.

---

## Open questions to resolve in GDD

- **Collision tuning:** what exact weapon-energy spend rate, ship-shield absorption cap, feedback, and control penalty make ramming a desperate tactical interception rather than either optimal field-sweeping or a pointless action?
- **Weapon drop tuning:** fuel-cell restore amounts, carrier spawn rules across faction stages, and the exact reverse-engineered cross-faction drop rate. Faction-themed gating supersedes the earlier stage-progress level-threshold framing.
- **Grid repair tuning:** what exact restore amount, spawn cap, and stage placement rules should govern rare Defense Grid repair carriers?
- **Between-stage screen:** any screen at all between stages? Tentative direction *if* yes: planetary defense upgrades only (grid max, regen, etc.) — ship offense stays purely in-run.
- **Side panel layout:** which side gets the planet view, and what information belongs on the opposite side?
- **Faction roster and stage count:** how many factions exist in total, what is the per-run stage count (currently leaning four faction stages plus one final boss stage), and is the faction order fixed, randomized, or branching (route choice)?
- **Level system in a large weapon pool:** does the level-1/2/3 stacking system from 2026-05-14 survive when same-type drops become rare in a large faction-themed pool? Should levels be simplified, removed, or replaced with a different within-type progression lever? Resolving this likely requires revising the 2026-05-14 "Authored drop carriers and dynamic weapon sustain" entry.
- **Pickup readability:** how do pickups communicate weapon identity to the player before contact, so the same-type-stacks vs different-type-swaps decision remains informed in a many-weapon pool?
- **Difficulty ladder after first clear:** what mechanism extends replay value once the coalition is first defeated — ascension-style modifiers, harder faction variants, or something else.
