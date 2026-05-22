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

## 2026-05-16 — Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo

**Decision:** The input model and the role of the typed-weapon energy meter are revised:

- The pea shooter auto-fires continuously. The player does not control pea-shooter fire; it is always on.
- The player's fire input controls **only** the typed weapon.
- Typed-weapon energy/fuel is now drained by **both** firing the typed weapon **and** absorbing enemy-fire hits while a typed weapon is active. Energy is a single shared pool that serves as both sacrificial shield against incoming fire and ammunition for the typed weapon.
- When the energy pool reaches 0, the typed weapon expires and the player drops back to the pea shooter (unchanged from the prior model).

**Reasoning:** The previous model framed typed-weapon energy as a durability buffer that drained only on hits; firing was effectively free for as long as the weapon was active. That made resource management a question of *when do I take the risk to refresh*, but it did not make individual shots tactical. Tying firing to the same energy pool changes the moment-to-moment question to *when is this shot worth it*, which fits the "sustained descending pressure" fantasy better: profligate fire shortens uptime, drops the player back to the pea shooter sooner, increases leakage, and damages the Defense Grid.

It also collapses two inputs into one. The pea shooter being auto-fire means the player only ever pulls the trigger to spend energy, which makes the player's actions and the resource meter perfectly aligned. There is no "I forgot to shoot" loss state, and no "I should hold fire to conserve the pea shooter" non-decision.

**Implications:**
- Energy is now a dual-role meter: shield-against-fire AND firing budget. HUD readability for the energy bar becomes a primary surface, not a secondary one.
- Tuning surface expands: per-shot firing drain, hit drain, max capacity at level 1/2/3, fuel-cell refill amount, and same-type pickup refill amount are all separate levers.
- Weapon family identity now includes burn rate. A rapid-fire or beam-style family will inherently feel more expensive than a slow heavy-shot family, and weapon design must account for that — a low-DPS-but-frugal weapon and a high-DPS-but-thirsty weapon are now distinct archetypes within the same level.
- Pickup decisions sharpen. A same-type weapon chip is now a level bump AND a budget refill; a fuel cell is strictly fire budget. The choice between holding fire to conserve and firing through a wave becomes a real tactical lever.
- Collision interception (2026-05-14) is unaffected in resolution order but feels different in practice, because weapon energy spent on collision is also fire budget the player loses.
- This decision opens a clear meta-progression lever surface (e.g., increase max energy capacity, reduce per-shot firing drain, increase fuel-cell yield). Whether and how to use that surface remains part of the open meta-progression question — this entry does not commit a meta layer.

**Supersedes / amends:**
- 2026-05-13 "Ship cannot be destroyed; hits drain weapon power" — the "hits drain typed-weapon energy" rule still holds; firing is now also a drain channel.
- 2026-05-14 "Typed weapons are temporary energy states" — same amendment. Energy is no longer a hit-only durability timer; it is a shared shield-and-ammo pool.
- The "pea shooter is always firing, never goes away" property from the 2026-05-13 entry is reaffirmed and made literal: the player has no input that affects it.

---

## 2026-05-16 — Per-weapon-family firing cost

**Decision:** Each typed-weapon family defines its own per-shot energy drain. Firing cost is a per-family property, not a uniform game-wide constant. Within a family, the per-shot drain may also scale with level (e.g., level 3 spread firing more pellets per trigger pull naturally costs more), though level-scaling of cost is a tuning detail, not a separate decision.

**Reasoning:** A uniform per-shot cost would have forced weapon identity to be expressed only through firing pattern and damage. Allowing per-family cost adds a third design axis — economy — so a family can earn its slot by being thrifty rather than flashy. This makes a low-DPS-but-frugal weapon and a high-DPS-but-thirsty weapon genuinely distinct archetypes within the same level, and it gives the balance team a knob that does not require redesigning a weapon's pattern or damage to retune its feel.

**Implications:**
- Each weapon family's spec now includes its per-shot energy drain alongside its pattern, damage, and visual identity.
- Pickup decisions become more layered: switching to a thirstier family may shorten your uptime even if you refill on pickup, so "do I swap for the fresh Type IV?" now factors in burn rate as well as level loss.
- HUD and pickup readability should communicate burn rate, not only weapon identity — players need at least a rough sense of how expensive a weapon is before committing to it. Exact representation (icon hint, bar pip count, telegraphed in the pickup carrier itself) is a UX problem for prototyping.
- The "thrifty vs thirsty" axis interacts with faction identity: a faction's roster could lean systematically thrifty or thirsty, which becomes a faction-level mechanical signature in addition to silhouette / formation / bullet style.
- The 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" entry's tuning surface is expanded — per-family burn rate joins per-family pattern and damage as primary balance levers.

**Status note:** Committed for now. Likely to be revisited once actual weapon-family design starts and the practical tuning surface becomes clearer — uniform cost may turn out to be sufficient, or per-family cost may need to be constrained within bands to keep weapons comparable. The decision is "per-family cost is allowed and expected," not "every family must have a distinct cost."

---

## 2026-05-16 — Pickup sources split: enemy carriers drop weapons, coalition supply drops fuel

**Decision:** The two confirmed pickup categories now come from distinct sources with distinct visual directions:

- **Weapon-chip carriers** are enemy ships within the descending armada and drop the attacking faction's typed-weapon chips. This reaffirms the 2026-05-15 large-weapon-pool entry — weapon-chip carriers remain part of the enemy faction and remain a leak risk if not engaged.
- **Fuel-cell carriers** are player-coalition supply vessels that approach from outside the armada — entering from the bottom or sides of the screen. They are narratively framed as the player's coalition resupplying the defender, not as enemy ships, and they do not advance toward the planet.
- **Defense Grid repair carriers**: source is *not* decided here and is added as an open question.

**Reasoning:** Splitting pickup sources by direction does several things at once. Visually, enemy-down vs coalition-up/sides gives each pickup category an unmistakable read at a glance, which matters more as the weapon pool grows. Narratively, weapon chips remain "enemy tech you scavenge" (which is what makes faction-themed weapons and reverse-engineered cross-run unlocks self-evident), while fuel cells become "your coalition reinforcing you" — a quiet reinforcement of the defended-planet fiction without inventing a new system. Mechanically, the leak-risk tension is preserved exactly where it matters most (weapon chips, the primary build-expression decision) and is intentionally absent for fuel cells (you have to break formation to collect them, but they will not damage the Grid if you ignore them).

**Implications:**
- Coalition supply vessels need a clearly distinct visual identity from enemy carriers — different silhouette language, palette closer to player-coalition colors, approach vector from below/sides. They must not read as targets to avoid.
- Fuel-cell carriers do not damage the Defense Grid if ignored; engagement is purely opportunity cost (do I leave my formation slot to grab it?), not a leak-risk decision.
- Weapon-chip carriers continue to behave as in 2026-05-15: faction-flavored, in-armada, leak risk if not engaged.
- Faction visual identity work no longer has to design a "coalition supply" hull per faction — coalition supply is faction-agnostic.
- Defense Grid repair carrier source is the next call to make; it could match weapon chips (in-armada leak risk, "repair tech from defeated enemies") or fuel cells (coalition supply, narratively consistent with "we send help") — both are defensible.

---

## 2026-05-16 — Non-formation rushers are faction content

**Decision:** Dive-bomber-style enemies that break the descending-armada formation to rush past the player directly (Galaxian-style) are part of each faction's content unit. Whether a faction has rushers, how many, what their dive patterns look like, and how aggressive they are is faction-defined. Rushers express faction identity in motion, not only in silhouette.

**Reasoning:** The descending armada provides one kind of pressure (slow inevitable advance); rushers provide a different kind (sudden directed threat). Tying rushers to faction identity gives each faction a mechanical handle on *both* axes — formation behavior and rusher behavior — and creates room for factions that explicitly do not have rushers (a slow-armored siege faction reads completely differently from a swarm faction with frequent low-HP dive bombers, even if their formation behavior is similar). This makes faction encounters more distinct without adding a separate universal enemy type the player has to track across all stages.

**Implications:**
- Each faction's content unit (from 2026-05-15) now explicitly includes a rusher spec: presence/absence, HP/damage profile, dive pattern, frequency, and whether rushers are tied to specific armada events (e.g., triggered when their formation slot is reached or destroyed) or appear on independent timers.
- A faction with no rushers is a valid design choice and a meaningful identity signal — it tells the player "this faction's threat is in the formation; hold your lane."
- Rushers interact strongly with the typed-weapon model: they are short-window threats that may be perfect targets for spread/area weapons but bad matchups for heavy-shot weapons, which sharpens the "is my current weapon family right for this stage?" question.
- Rusher behavior is a primary balance lever for individual faction difficulty within a run; it does not need to scale with stage position in the run if the faction roster itself does.

---

## 2026-05-16 — Stage shape: long descending armada with progressive intermix, faction-boss culmination

**Decision:** Each faction stage is structured as a single long descending armada that extends across multiple screen heights, not as a series of discrete waves with downtime between them. Stage shape:

- The stage opens with weaker baseline enemies in the leading rows of the descending formation.
- Tougher enemies — elites/heavies (see separate entry) and faction rushers (2026-05-16) — are intermixed throughout the armada at progressively greater density and severity as it descends.
- The stage culminates in a faction boss encounter at the end of the armada. The faction boss is part of each faction's content unit (already implied in the 2026-05-15 large-weapon-pool entry's "designing a faction means … a faction boss" implication; this entry makes per-stage faction bosses an explicit stage-structural commitment).
- The final run stage remains the coalition warlord, per 2026-05-15.

**Reasoning:** A long descending armada with intermixed difficulty preserves the "sustained descending pressure" fantasy that the entire damage hierarchy and typed-weapon model is designed around. Discrete waves with downtime would create natural breath points that the pressure loop is explicitly designed *not* to have; intermixing keeps the descent continuous and lets escalation happen by composition rather than by event. Reaching a boss at the end of a long sustained advance feels earned in a way that a wave-arena structure does not, and it keeps the Defense Grid meter the dominant pacing signal (the boss arrives when the armada has had time to chip the Grid down).

**Implications:**
- Stage authoring is part choreography (formation placement, where heavies and rushers sit in the descending column) and part faction-systemic (faction enemy roster, formation behavior, rusher spec). Carrier placement — weapon-chip carriers (enemy) and coalition fuel-cell carriers (your side) — is part of stage authoring.
- Stage length is a tuning value, but must be long enough for typed-weapon expiry / swap / refresh cycles to play out multiple times within a single stage, not just once. A stage that ends before the player has cycled weapons would not exercise the resource economy this design centers on.
- The Defense Grid meter is expected to take real damage over the course of a stage, not just at the boss. Repair-carrier pacing (open question on carrier source notwithstanding) must be tuned against expected per-stage Grid loss.
- The strategic mini-map side panel (2026-05-14) should be able to show approximate stage progress — how much of the armada remains, boss presence — without giving the player exact positional information about off-screen threats.
- Stage transitions remain a separate open question (between-stage screen), but the stage's *internal* shape is now committed.

---

## 2026-05-16 — Elite/heavy enemy tier per faction

**Decision:** Each faction's enemy roster includes at minimum two tiers:

- **Baseline enemies** — low HP, killable by the pea shooter within the time they spend in the playfield. These are the bulk of the descending armada and the primary leakage pressure if ignored.
- **Elite/heavy enemies** — significantly higher HP, designed so that the pea shooter alone cannot reliably kill them before they cross the playfield and damage the Grid. Killing elites in time effectively requires an active typed weapon, and higher typed-weapon levels make the matchup substantially easier.

Faction rosters may have more than one elite tier (e.g., a mid-elite and a heavier "legendary" tier) — that internal granularity is a per-faction content decision, not a global rule.

**Reasoning:** This is what gives typed weapons their job. The typed-weapon economy — energy, levels, family identity, faction-themed drops, post-run upgrade lever — is built around the premise that you *need* the typed weapon to handle some threats. Without an elite tier, the pea shooter would eventually clear everything given enough time and the typed weapon would be a flavor-only bonus rather than a tactical necessity. Elites are the structural reason the typed-weapon system has stakes, and they directly drive the "is my current weapon family right for this stage?" question.

**Implications:**
- Each faction defines its elite roster (at least one elite type) as part of its content unit. Elite visual silhouettes must clearly read as "this is a different-tier threat" — same faction palette, distinct shape language.
- Elite placement within the descending armada is part of stage authoring (see stage-shape entry, same date) — early stage has few or no elites, density and elite tier increase deeper into the armada.
- Elite HP tuning is bounded by two requirements: pea shooter cannot reliably kill an elite before it crosses the playfield, and a level-appropriate typed weapon should make the matchup feel decisive but not trivial. Exact numbers are prototype tuning values.
- The "thrifty vs thirsty" weapon-family axis (2026-05-16 per-family firing cost entry) interacts strongly here. A thirsty high-DPS family is the natural counter to an elite but is unsustainable as default cleanup; a thrifty family handles baseline well but may struggle with elites. This is the intended texture, not a balance problem.
- Elites do not automatically drop pickups. Drops remain authored-carrier-based per 2026-05-14 — being an elite is about HP/threat profile, not about reward.
- Rushers (separate 2026-05-16 entry) are a *third* category orthogonal to baseline/elite — they are defined by formation behavior (out of formation, directed dive) rather than HP profile, and a faction can have elite rushers, baseline rushers, or none.

---

## 2026-05-18 — Typed weapons are faction-flavored sidegrades, not a power ladder

**Decision:** Typed weapons across the full faction-gated pool are **sidegrades**, not progressively stronger tiers. A faction-1 weapon family and a faction-4 weapon family at the same level are comparable in raw power; they differ in *handling profile* (pattern, range, burn rate, target shape) rather than in damage tier. Reverse-engineered drops (2026-05-15) introducing late-faction weapons into early stages do not trivialize already-cleared content, because those weapons are not stronger — they are different tools whose matchup against the current faction's threats may be better, worse, or roughly equivalent.

**Reasoning:** Earlier entries left the relationship between faction order and weapon power unstated, which created the concern that beating later factions and unlocking their tech via the reverse-engineered pool could cake-walk early stages on subsequent runs. Committing weapons as sidegrades resolves that tension structurally: the cross-run unlock is *variety*, not *power*. It also aligns with the existing "thrifty vs thirsty" axis (2026-05-16 per-family firing cost) and the "is my current weapon family right for this stage?" question already implied by the elite/heavy and rusher entries — both of which assume weapon choice is a *matchup* question, not a power question.

**Implications:**
- Weapon-family design budgets are roughly equivalent in peak power within a level, regardless of source faction. A faction-4 spread weapon at level 2 should not significantly out-damage a faction-1 spread weapon at level 2.
- Differentiation between weapons across factions comes from handling — burn rate, projectile speed, spread arc, pierce, area, lock-on behavior — not from raw damage multipliers.
- Difficulty must arise from the enemy side, not the weapon side (see the difficulty-levers entry, same date).
- The reverse-engineered drop pool (2026-05-15) is reaffirmed without modification: rare cross-run drops are tasty variety moments, not power shortcuts.
- A "wrong" weapon for the current faction is harder to play, but never impossible — three universal floors apply (see the bi-modal faction threat profile entry, same date).
- This decision does **not** answer the level-system follow-up. Whether the 1/2/3 level mechanic survives in a large pool is still open; this entry only commits that *within a given level*, faction sources are comparable.

---

## 2026-05-18 — Difficulty arises from enemy-side levers, not weapon power

**Decision:** Progressive difficulty within and across stages comes from enemy-side levers, not from weapons becoming stronger. The committed lever surface:

- **Armada density** — enemies per screen-height of descending column.
- **Descent speed and formation aggression** — closure rate toward the planet, formation reshape behavior on losses.
- **Elite density and mix** — fraction of the armada that is elite tier, presence of multiple elite tiers (mid-elite + heavy).
- **Rusher cadence and aggression** — frequency, overlap with armada pressure, dive HP.
- **Bullet pattern complexity** — density, leading shots, area denial.
- **Leak penalty** — per-enemy Grid damage on leak, varying by enemy type.
- **Carrier scarcity** — weapon-chip and fuel-cell carrier spawn rate and placement depth in the armada.

Carrier scarcity is particularly load-bearing because it compounds: fewer carriers → lower typed-weapon uptime → more pea-shooter time → more leakage → tighter Grid margins.

**Reasoning:** With weapons committed as sidegrades (same date), difficulty has to live somewhere structural. Enemy-side levers preserve the existing pressure-loop fantasy ("sustained descending pressure → leaks → Grid damage → planet falls") and let difficulty scale without breaking the matchup texture the typed-weapon system depends on. They are also the levers stage authoring already touches — armada composition, formation behavior, rusher spec, carrier placement — so this is making explicit what existing entries implicitly relied on.

**Implications:**
- Stage authoring (2026-05-16 stage shape) now has a committed lever surface. Each lever can be turned independently per stage and per faction.
- Difficulty tuning is primarily a stage-authoring problem, not a weapon-balance problem. Weapons are balanced for parity within their level; stages are balanced for intensity.
- Carrier scarcity must be used carefully — turning it too high starves the typed-weapon economy entirely and undermines the resource loop, not just makes the stage harder. There is a floor below which stages stop exercising the system.
- Bullet pattern complexity is now treated as a primary tuning surface for the first time in the log. Faction bullet styles (referenced in 2026-05-13 / 2026-05-14) now carry mechanical weight in addition to visual identity.
- Per-stage Grid damage expectation (2026-05-16 stage shape) is a target output of these levers — stage design should produce a predictable Grid-loss range, and the levers are what tune it.

---

## 2026-05-18 — Bi-modal faction threat profile; three universal floors

**Decision:** Each faction must combine **at least two distinct threat categories** that no single weapon family can handle well simultaneously. The two categories are part of each faction's content unit (2026-05-15) and are the structural reason no weapon "solves" a faction stage on its own.

Illustrative bi-modal pairings (not committed rosters):
- Tight swarm formations + dive rushers — wide AOE clears swarm but is too diffuse to commit on dives.
- Armored elites + dense bullet curtain — single-target burst kills elites but heavy dodging time stalls a thirsty burst weapon.
- Shielded baseline + leak-prone swarm — shield-pierce handles elites but doesn't clear swarm fast enough.

When the typed weapon handles one category, the pea shooter, positioning, and energy budget cover the other. The reverse symmetry — what keeps a poorly matched typed weapon from being a soft-lock — is the **three universal floors**:

1. **The pea shooter clears baseline enemies indefinitely**, regardless of typed-weapon state.
2. **Typed-weapon energy retains full shield value** against incoming fire even when its damage output is poorly matched against the current threat.
3. **Fuel-cell and Grid repair carriers function identically** regardless of weapon match — recovery options exist in every matchup.

**Reasoning:** Without bi-modal threats, a sufficiently good weapon pickup could trivialize any single faction, which would make weapon RNG the dominant variable in run outcome and undermine the "difficulty is on the enemy side" commitment (same date). Forcing every faction to demand two distinct handling profiles means the player is always solving two problems with two tools (typed weapon + pea shooter + positioning), regardless of what weapon family they're holding. It is what gives the "is my current weapon family right for this stage?" question real teeth.

The three universal floors are the symmetric guardrail: they make every weapon viable enough to finish the stage, even when poorly matched. The wrong weapon should be tense, not impossible.

**Implications:**
- Faction design now has a structural requirement: at least two threat categories, paired so that no existing weapon family handles both. When new weapon families are added, they must be checked against the existing faction roster for this property — a weapon that solves any faction's bi-modal pairing breaks the guardrail.
- "Threat category" is a recognizable handling demand (burst single-target / wide AOE / shield-pierce / responsive tracking / area denial / patience). Two categories within a faction must be genuinely distinct in tool requirements, not two flavors of the same demand.
- Rushers (2026-05-16) are a strong second-category candidate but not the only one. A rusher-less faction (which 2026-05-16 explicitly allows) must derive its second category from armada composition or bullet behavior.
- A deliberate "burn the wrong weapon's energy down to expose the pea shooter" is a valid tactical choice when the pea shooter is genuinely the better tool for the current phase. Not a degenerate strategy.
- This entry extends, not supersedes, the 2026-05-16 elite/heavy entry. Elites are still the structural reason typed weapons have stakes; bi-modal pairing is what stops any one weapon from cake-walking those stakes.

---

## 2026-05-18 — Weapon power axes: faction-source parity, in-pool rarity tier, levels as peak

**Decision:** Amends the same-date "Typed weapons are faction-flavored sidegrades, not a power ladder" entry to clarify how the power fantasy is expressed. **Faction source remains parity** — a faction-4 common weapon at level 2 is not stronger than a faction-1 common weapon at level 2 — but power in this game lives on three other axes that the sidegrade framing must not be read as flattening:

1. **Levels are the in-run power spike.** Reaching level 3 of any weapon family should *feel* genuinely overpowered for as long as the player can sustain it. The fantasy is reaching peak and holding it under pressure, not maintaining it forever. This reaffirms the 2026-05-14 level-system entry's "level 3 = late-stage peak state" intent.
2. **Each faction's roster has a rarity gradient.** Most weapons in a faction's pool are roughly comparable (the sidegrade-flavored variety the prior entry named), but each faction authors **1–2 legendary / rare-tier weapons** that are genuinely stronger within their level — exotic patterns, higher damage, lower burn rate, or some combination. These are the lottery pickups; rarity itself prevents reliance.
3. **Cross-run reverse-engineered drops pull from the full pool, legendaries included.** Rolling a cross-run legendary in stage 1 is now an explicit slot-machine moment — the 2026-05-15 "tasty rare moment" given real teeth.

**Reasoning:** The earlier same-date sidegrade entry solved the right problem (faction-source parity, so cross-run unlocks don't trivialize early stages) but collapsed too much of the power-expression surface onto one axis, which would have left the arcade power fantasy flat. The power fantasy in shmups lives in *temporary peak states* — Blazing Lazers' top-level weapons, smart-bomb windows, brief godlike moments. Last Horizon already commits to weapons as temporary energy states (2026-05-14), so peak power is structurally short-lived already. The remaining question was whether the peak is *high enough* to feel godlike, and the original entry implied "no, all weapons are flat." This amendment corrects that: levels and rarity tier are where the height comes from; faction source is only constrained for trivialization-avoidance.

The bi-modal threat guardrail (same date) still does its job even when the player is holding a legendary. A legendary trivializes one of the faction's two threat categories; the other is still tense. That is the "feels overpowered without actually winning the game for you" sweet spot.

**Implications:**
- Each faction authors a tiered roster: a set of common-rarity weapons (parity-balanced across factions) plus 1–2 legendary weapons (genuinely stronger within their level). Exact counts and rarity ratios are tuning.
- Legendary weapons must still respect the bi-modal pairing rule — a legendary cannot solve both of a faction's threat categories. It solves one *harder*, not both.
- The reverse-engineered cross-run pool now has explicit power texture: drops can roll legendaries from defeated factions. The 2026-05-15 "intentionally small" rate still applies, likely with separate rates for common-tier vs. legendary-tier within the cross-run pool.
- HUD and pickup-readability work has another visual axis to communicate: weapon family + faction source + **rarity tier**. Legendary pickups should be immediately recognizable on approach (color, shape, particle treatment) so the choice to commit to them is informed.
- The 2026-05-14 level-system entry is reaffirmed for now, but the open-question tension with the large-pool model carries new weight. If levels become very rare to reach in a large pool, the in-run power spike axis weakens and rarity tier carries more of the fantasy alone. Resolution of the level-system follow-up must consider this.
- Faction-source parity is not reopened. A faction-4 common weapon is still parity-balanced against a faction-1 common weapon; the power axes added here are orthogonal to faction source.

**Amends:**
- 2026-05-18 "Typed weapons are faction-flavored sidegrades, not a power ladder" — faction-source parity stands; power expression now explicitly includes levels and in-pool rarity tier.

---

## 2026-05-18 — Stage-slot intensity scaling; faction order is randomizable

**Decision:** Within-run progressive difficulty rides the **stage slot**, not the faction identity. Each faction authors multiple **intensity presets** for its armada — versions tuned for the stage-1 slot, the stage-2 slot, etc. Same faction roster, same threat shape, but later slots have higher density, more elite intermix, faster descent, sparser carriers, and harder bullet patterns. Faction order within a run is **randomizable**; the slot's intensity preset is what determines difficulty regardless of which faction lands there.

A lightweight global **coalition pressure** multiplier may stack on top to add cross-stage ramp (e.g., gradual rusher cadence increase, bullet density tick). The coalition warlord boss stage (2026-05-15) remains the fixed final stage and is not part of the random pool.

**Reasoning:** Two alternatives were considered and rejected:

1. **Fixed faction order with hand-tuned per-faction difficulty** — rejected because it kills replay variety and forces one faction to always be "the hard one," conflating faction identity with difficulty tier.
2. **Randomized order with no per-slot scaling** — rejected because difficulty would then ride faction identity, making a "harder" faction in slot 1 feel unfair and an "easier" faction in slot 4 feel anticlimactic.

Stage-slot scaling preserves the "invasion is intensifying" pacing fantasy while leaving faction order free to vary run-to-run. It keeps faction identity *mechanical* (threat shape, weapon roster, visual style) rather than *difficulty-tiered*, which is consistent with the sidegrade weapon decision (same date).

**Implications:**
- Each faction's content unit (2026-05-15) now includes multiple intensity presets — one per stage slot it can occupy. Likely 3–4 presets per faction if runs settle on roughly four faction stages.
- Authoring cost per faction increases. This is the explicit tradeoff for replay variety + a structural difficulty curve.
- The coalition pressure multiplier is intentionally lightweight — small per-stage bumps on a few specific levers (rusher cadence, bullet density), not a global damage multiplier. Exact form is tuning.
- This entry partly resolves the open question on faction roster and stage count: **order is randomized, count is still tunable.** Whether the random pool is unrestricted, weighted, or constrained (e.g., no repeat factions in one run) is still open.
- Route choice (Slay the Spire-style branching) is a separate question not answered here. Default is straight-line random.
- The 2026-05-14 "Authored drop carriers and dynamic weapon sustain" entry's early/mid/late stage gating language is now structurally backed: run-internal difficulty attaches to *stage position*, which is what intensity presets formalize. That earlier entry still needs the level-system follow-up resolved before its full rewrite.

---

## 2026-05-18 — Faction content unit clarification: which carriers are faction content

**Decision:** Clarifies the 2026-05-15 faction-themed stages entry, whose content-unit list ("the faction's own carrier hulls — weapon-chip, fuel-cell, repair") was written before the 2026-05-16 pickup-source-split. The current, authoritative breakdown of which carriers are faction content vs. faction-agnostic:

- **Weapon-chip carriers — faction content.** Enemy ships within the descending armada, faction-flavored hull and palette, drop the attacking faction's weapon chips. Leak risk if not engaged (2026-05-16 source split).
- **Coalition fuel-cell carriers — faction-agnostic.** Player-coalition supply vessels approaching from outside the armada (bottom/sides). Not designed per faction; one shared coalition visual identity is reused across all stages (2026-05-16 source split).
- **Defense Grid repair carriers — source open.** Whether repair carriers are faction content (in-armada, enemy-side) or coalition-agnostic (coalition supply) is still unresolved; remains the same open question raised 2026-05-16.

**Reasoning:** The 2026-05-15 entry pre-dated the carrier-source split and is now misleading if read literally on the faction-content scope. This clarification does not change any decision; it just realigns the content-unit list with the current state of pickup-source decisions. Stating the current breakdown in one place avoids agents (or designers) inheriting the older implicit "every carrier is faction content" framing during faction authoring.

**Implications:**
- Per-faction authoring scope: enemy roster (baseline + at least one elite tier), formation/descent behavior, rusher spec (optional), bullet style, weapon-chip carrier hull, weapon family roster (common + 1–2 legendary), boss, and intensity presets per stage slot. Coalition fuel-cell carriers are not in this list.
- Coalition supply visual identity is a one-time global art problem, not a per-faction one.
- If the repair-carrier-source question lands on "in-armada enemy-side," the faction content unit will gain a repair carrier hull at that point. If it lands on "coalition supply," it stays out.
- No supersession of 2026-05-15; this is a clarification, not a course change.

---

## 2026-05-18 — Bi-modal threat categories are independent from baseline/elite HP tiers

**Decision:** Clarifies the interaction between the 2026-05-16 elite/heavy entry (each faction has at minimum baseline + elite HP tiers) and the same-date 2026-05-18 bi-modal threat profile entry (each faction has at least two distinct *handling-demand* categories). These two requirements are **independent axes**, not the same axis:

- **HP tier** = how hard an enemy is to kill before it leaks (baseline = pea-shooter killable in time; elite = effectively requires active typed weapon). This is the lever the typed-weapon economy *needs to exist*.
- **Handling demand** = what tool shape kills it efficiently (burst single-target / wide AOE / shield-pierce / responsive tracking / area denial / patience).

A faction's baseline and elite tiers may demand the **same** handling at different HP scales — e.g., an armored faction where baseline grunts and heavy elites both want burst single-target. That satisfies the HP-tier requirement but does **not** satisfy bi-modal. In that case the faction needs its second threat category from somewhere else (rushers, bullet patterns, formation behavior, a shielded subtype, area-denial mines, etc.).

A faction's baseline and elite tiers **may** also demand different handling — e.g., baseline = swarm wanting AOE, elite = armored single-target. In that case the baseline/elite distinction satisfies both rules at once, and rushers/bullet-patterns become optional flavor rather than structural requirement.

**Reasoning:** Without this clarification, an author could satisfy the baseline/elite rule with two HP tiers that demand the same handling and silently fail bi-modal — producing a faction that a single matched weapon family can carry. The two rules read like they could be the same rule but aren't; pinning the distinction prevents that drift.

**Implications:**
- Faction authoring requires an explicit check: do the HP tiers demand different handling? If yes, bi-modal is satisfied by composition alone. If no, the second handling category must be sourced from rushers, bullet patterns, formation behavior, or a subtype.
- This also constrains the legendary tier (2026-05-18 power axes): legendary weapons must not satisfy *both* handling demands of any faction simultaneously, regardless of whether the demands come from HP tiers, rushers, or bullet behavior.
- No supersession; both source entries remain valid. This entry only names the relationship between them.

---

## 2026-05-19 — Remove weapon levels; rarity tier carries the in-run power spike alone

**Decision:** Typed weapons no longer have levels. Each weapon family has a **single tuning** — there is no level 1 / level 2 / level 3 progression within a family. The in-run power spike that the level system was supposed to provide is now carried entirely by the **rarity tier** (see same-date three-tier rarity entry).

Same-family pickups no longer level up the held weapon; they refill its energy meter to full (see same-date same-family refill entry). Different-family pickups swap to the new family at full energy. The pickup decision becomes purely about *what tool you want*, not about *what level you're at*.

**Reasoning:** The level system was designed for the 4-type Blazing Lazers pool, where same-type stacking happens regularly (~25% of drops match the held weapon). In the faction-gated large pool (2026-05-15), with 6+ weapon families per faction and multiple factions accessible across runs, that match rate drops below 17% — and individual stages don't surface enough weapon drops to reliably see a repeat. Levels were structurally dead-on-arrival under that constraint; the 2026-05-15 entry already flagged this tension and the 2026-05-18 power-axes entry conceded that if levels become rare to reach, rarity tier carries the fantasy alone. This decision commits that path rather than papering over the gap with catalyst pickups or level-from-any-pickup hacks that would recreate a level treadmill.

This also simplifies four surfaces at once: HUD (no level state to display), pickup readability (one less axis), faction authoring (one tuning per weapon instead of three), and stage-progress gating (rarity rather than level — see same-date late-armada gating entry).

**Implications:**
- Each weapon family must land its identity AND its punch in a single tuning. There is no "level 1 establishes the family, level 3 is the payoff" progression to lean on; weapons must feel good at default. This is more design work per family, not less.
- The 2026-05-18 power-axes entry's three axes (faction-source parity, in-pool rarity tier, levels-as-peak) collapse to two: faction-source parity + rarity tier. Rarity is the only in-run height axis. Cross-run reverse-engineered legendary drops remain the slot-machine peak moment.
- Faction roster sizing may need to grow to compensate for the loss of per-weapon depth (was: 3 levels × N families; now: 1 tuning × N families). Exact counts remain tuning.
- The 2026-05-13 / 2026-05-14 "same-type pickup levels you up" rules are gone. The refill / swap-at-full semantics replace them — see same-date entry.

**Supersedes / amends:**
- 2026-05-14 "Typed weapon max level is 3" — **superseded outright.** No levels.
- 2026-05-18 "Weapon power axes: faction-source parity, in-pool rarity tier, levels as peak" — **major amendment.** Levels-as-peak removed; rarity tier carries the entire in-run power spike. Faction-source parity stands.
- 2026-05-14 "Authored drop carriers and dynamic weapon sustain" — early/mid/late level-gating framing is replaced; see same-date late-armada rarity gating entry.
- 2026-05-13 "Ship cannot be destroyed; hits drain weapon power" — same-type / different-type level rules collapse to refill / swap-at-full; see same-date same-family refill entry.
- 2026-05-14 "Typed weapons are temporary energy states" — same amendment as above.
- 2026-05-15 "Large weapon pool, faction-gated primary drops" — the entry's note that "the level system may be redundant or need simplification" is now resolved by removal.
- 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" — tuning surface no longer includes "max capacity at level 1/2/3"; max capacity is one value per weapon family.
- 2026-05-16 "Per-weapon-family firing cost" — the note about "per-shot drain may scale with level" is removed; firing cost is one value per family.
- 2026-05-18 "Typed weapons are faction-flavored sidegrades, not a power ladder" — references to "at the same level" become "at the same rarity tier"; faction-source parity is unchanged.
- 2026-05-18 "Difficulty arises from enemy-side levers, not weapon power" — the implication "Weapons are balanced for parity within their level" becomes "within their rarity tier"; substance unchanged.
- 2026-05-16 "Elite/heavy enemy tier per faction" — incidental references to "higher typed-weapon levels make the matchup substantially easier" and "level-appropriate typed weapon" should now be read as rarity-tier references. The structural claim (killing elites requires an active typed weapon, and a better-matched / higher-rarity weapon makes the matchup more decisive) is unchanged.

---

## 2026-05-19 — Three-tier rarity: common / rare / legendary

**Decision:** Within each faction's weapon pool, rarity has **three tiers**, not two:

- **Common** — the bulk of a faction's roster. Sidegrade-flavored variety. Faction-source parity applies across all factions' commons.
- **Rare** — middle tier. Noticeably stronger or weirder than commons, but still parity-balanced across factions within the rare tier. A few per faction.
- **Legendary** — peak tier. 1–2 per faction, genuinely strong (exotic patterns, lower burn rate, higher damage, or some combination). Lottery pickups.

**Reasoning:** The 2026-05-18 power-axes amendment introduced a two-tier model (common + legendary). With levels removed (same-date entry), rarity tier is the entire in-run power spike axis, and two tiers risks being too coarse — there is no middle ground between "common variety" and "legendary screen-clearer," which leaves no shape for a meaningful-but-not-overpowered pickup. A three-tier model gives the run more texture and more memorable-moment shapes (a rare drop is a "nice" beat without the lottery anxiety of legendaries).

**Implications:**
- Per-faction authoring: roughly N commons + a smaller set of rares + 1–2 legendaries.
- Drop-rate tuning expands: common / rare / legendary spawn rates, both in-faction and cross-run (reverse-engineered) pools. Legendary rates remain "intentionally small" per 2026-05-15; rare rates are a new tuning value, positioned to land between "common is the default" and "legendary is the rare crown."
- The bi-modal threat guardrail (2026-05-18) applies at all three tiers: no weapon at any tier may solve both of a faction's threat categories. Rares solve one harder; legendaries solve one significantly harder.
- HUD and pickup-readability must distinguish three rarity tiers (color, frame, particle treatment) — folded into the existing pickup-readability open question.

**Supersedes / amends:**
- 2026-05-18 "Weapon power axes" — the "1–2 legendary / rare-tier weapons" framing conflated rare and legendary; this entry separates them into distinct tiers.

---

## 2026-05-19 — Same-family pickup refills energy; different-family swaps at full

**Decision:** With levels removed (same-date entry), weapon-chip pickup behavior is:

- **Same family as currently held:** refills the typed-weapon energy meter to full. No swap, no other state change.
- **Different family:** swaps to the new family at full energy. The previous family is lost; its remaining energy is discarded.

Fuel-cell carriers (2026-05-16) continue to give *partial* energy refills regardless of weapon family. So weapon-chip and fuel-cell pickups stay meaningfully distinct: weapon chips are the higher-value refresh (full top-up if same family, full reset to a new tool if different); fuel cells are the general partial top-up.

**Reasoning:** With no levels, same-family pickups need a new payoff. Full refill preserves the "stick with what's working" texture from the old level model (you're rewarded for holding the family longer) without recreating a level treadmill. It also preserves the leak-risk premium of weapon-chip carriers (enemy ships, 2026-05-16 source split) over fuel-cell carriers (coalition supply, no leak risk) — weapon chips remain the more valuable carrier, justifying the higher engagement cost.

A no-op on same-family was considered (force variety) and rejected — it would punish the "celebrate seeing your family again" beat. A partial-refill on same-family was considered (collapses into fuel-cell behavior) and rejected — it would erase the carrier-leak-risk premium.

**Implications:**
- HUD feedback for same-family pickup must clearly signal "your meter just refilled, no swap" so the no-state-change is legible.
- Weapon-chip carrier drop logic is now purely "drop a weapon chip from the faction's pool"; there is no same-vs-different-family branching at drop time. Whether the drop is same-family or different-family is determined by what the player happens to be holding.
- Different-family swap-at-full preserves the 2026-05-13 commitment shape ("commit to your current family or risk it for a fresh one") without the level-loss cost.

**Supersedes / amends:**
- 2026-05-13 "Ship cannot be destroyed; hits drain weapon power" — same-type / different-type rules collapse to the refill / swap-at-full model described here.
- 2026-05-14 "Typed weapons are temporary energy states" — same amendment.

---

## 2026-05-19 — Late-armada rarity gating replaces level-progress gating

**Decision:** With weapon levels removed (same-date entry), the early/mid/late stage drop gating from 2026-05-14 (level 1 early, level 2 mid, level 3 late) is replaced by **rarity gating** along the descending armada:

- **Early armada:** common weapons only.
- **Mid armada:** commons + rares.
- **Late armada / pre-boss:** commons + rares + legendaries. Legendaries remain rare even within the late-armada window.
- **Boss phase:** not committed here; open question.

**Reasoning:** The 2026-05-14 gating logic (you can't get peak power early in a stage) is still load-bearing — it's what made the late-stage power-spike pacing work. With levels gone, the lever changes from "level" to "rarity," but the intent is preserved: the player builds up to peak power across the descending armada, not at its start.

The dynamic responsiveness from 2026-05-14 (if no weapon, more chips; if low energy, more fuel cells) is preserved in spirit but its level-state logic is gone. Responsiveness now lives between *carrier categories* (encourage swap vs. encourage hold), not within a level dimension.

**Implications:**
- Stage authoring: the armada column has implicit rarity zones tied to position — early enemies' weapon-chip carriers drop commons, late enemies' carriers can drop legendaries.
- The 2026-05-18 stage-slot intensity scaling is unaffected; rarity zones live inside each intensity preset, not across them. A stage-1 slot still gets its own early-to-late rarity escalation, just at lower overall intensity than a stage-4 slot.
- Reverse-engineered cross-run drops (2026-05-15, amended 2026-05-18) can include all three rarity tiers. Whether the cross-run pool respects stage-progress rarity gating, or whether reverse-engineered drops can roll any rarity at any stage position, is a new open question.

**Supersedes / amends:**
- 2026-05-14 "Authored drop carriers and dynamic weapon sustain" — early/mid/late level-gating framing is fully replaced by rarity gating. The dynamic-responsiveness intent (give the player what they need) is preserved but lives between carrier categories, not within level state.

---

## 2026-05-22 — Double baseline alien HP for current prototype tuning

**Decision:** The current baseline alien's hit points are doubled from `2.5` to `5.0` for the active prototype tuning pass.

**Reasoning:** This is an ad hoc feel adjustment to make the current alien survive longer against the existing pea-shooter and typed-weapon damage values. It restores a longer baseline time-to-kill without changing projectile damage or weapon energy costs.

**Implications:**
- Pea bullets still deal `1.0` damage, so a fresh baseline alien now takes five pea hits to kill.
- Debug plasma typed projectiles still deal `3.0` damage, so one hit leaves a fresh baseline alien at `2.0` HP instead of killing it outright.
- This is a prototype tuning value, not a new enemy-tier rule. Future enemy HP and stage density tuning still belong to playtest-driven tuning passes.

**Supersedes / amends:**
- The 2026-05-21 post-T009 tuning adjustment that reduced the current baseline alien HP from `5.0` to `2.5`.

---

## Open questions to resolve in GDD

- **Collision tuning:** what exact weapon-energy spend rate, ship-shield absorption cap, feedback, and control penalty make ramming a desperate tactical interception rather than either optimal field-sweeping or a pointless action?
- **Weapon drop tuning:** fuel-cell restore amounts, weapon-chip carrier spawn rules across faction stages and across the within-stage rarity zones (2026-05-19 late-armada rarity gating), and the separate per-rarity drop rates for **common / rare / legendary** (2026-05-19 three-tier rarity) in both the in-faction primary pool and the cross-run reverse-engineered pool.
- **Grid repair tuning:** what exact restore amount, spawn cap, and stage placement rules should govern rare Defense Grid repair carriers?
- **Defense Grid repair carrier source (opened 2026-05-16):** with pickup sources split between enemy armada (weapon chips) and coalition supply from below/sides (fuel cells), where do repair carriers come from? Coalition supply is the natural narrative match ("we send help"), but in-armada repair carriers as a rare enemy-side spawn preserves the "engage or let leak" tension that makes weapon-chip carriers tactically rich.
- **Between-stage screen:** any screen at all between stages? Tentative direction *if* yes: planetary defense upgrades only (grid max, regen, etc.) — ship offense stays purely in-run.
- **Side panel layout:** which side gets the planet view, and what information belongs on the opposite side?
- **Faction roster and stage count:** how many factions exist in total, and what is the per-run stage count (currently leaning four faction stages plus one final boss stage)? Faction order is randomized per 2026-05-18, but the random-pool constraints (can the same faction appear twice in a run, are slot weights uniform) are still open.
- **Route choice:** does the player get Slay-the-Spire-style branching between stages, or is the run a straight-line random sequence? Default per 2026-05-18 is straight-line random; branching is unresolved.
- **Intensity preset count per faction:** if runs are roughly four faction stages, each faction probably needs 3–4 intensity presets (2026-05-18). Whether all factions author the full set, or some are slot-restricted (e.g., only ever appears in slots 2–4), is a tuning + authoring-cost question.
- **Coalition pressure multiplier form:** the lightweight cross-stage ramp introduced in 2026-05-18 needs an exact form — which levers it touches (rusher cadence, bullet density, ...) and how aggressively it scales per stage.
- **Bi-modal pairing audit on weapon additions:** the 2026-05-18 bi-modal threat profile decision requires that no weapon family handles both of any faction's threat categories. As new weapons are added, this needs a check; the process for that check is not yet defined.
- **Reverse-engineered cross-run rarity gating (opened 2026-05-19):** does the cross-run reverse-engineered drop pool respect the within-stage rarity gating (legendaries only in late-armada), or can reverse-engineered drops roll any rarity at any stage position? Consistency argues for respecting the gate; the "tasty rare cross-run moment" framing could argue for breaking it.
- **Boss-phase weapon drops (opened 2026-05-19):** the late-armada rarity gating entry does not commit boss-phase drop behavior. Do bosses drop weapons at all? If yes, is the boss its own rarity zone (e.g., guaranteed rare, chance at legendary) or does it inherit late-armada rates?
- **Single-tuning weapon depth (opened 2026-05-19):** with levels removed, each weapon family is one tuning. Does each common need a distinctive enough handling profile to land its identity in a single read, or do we need a roster-sizing decision (more families per faction) to compensate for shallower per-weapon depth? Answerable only by prototyping.
- **Pickup readability:** how do pickups communicate weapon identity (family + faction source), **rarity tier** (common vs. legendary, per 2026-05-18 power axes), and **burn rate** (per-family firing cost, per 2026-05-16) to the player before contact, so the same-type-stacks vs different-type-swaps decision remains informed in a many-weapon pool with multiple power axes? Three readable axes on a small in-flight pickup icon is the actual UX problem.
- **Difficulty ladder after first clear:** what mechanism extends replay value once the coalition is first defeated — ascension-style modifiers, harder faction variants, or something else.
