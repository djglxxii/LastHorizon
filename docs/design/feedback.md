**This is a rock-solid design log.** It reads like a team that’s learned hard lessons from past prototypes (and from the industry) and is now laser-focused on protecting the *core fantasy*. The vision for *Last Horizon* feels cohesive, deliberate, and genuinely exciting as a vertical shmup. You’ve successfully distilled the best parts of Blazing Lazers, Space Invaders, and modern roguelike structure while ruthlessly cutting the usual bloat.

### What Works Extremely Well

**The pressure loop is elegant and self-reinforcing.**  
The shared Defense Grid + temporary typed weapons + pea shooter baseline is *chef’s kiss*. Getting hit doesn’t just sting — it visibly weakens your offensive power, which makes more enemies leak, which hurts the Grid more. That feedback flywheel is perfect for the “sustained descending pressure” fantasy. The fact that the ship itself can’t die is smart; it keeps the player in the hot seat instead of resetting them to a checkpoint.

**The weapon model is excellent.**  
- Permanent pea shooter = safety net + identity.  
- One active typed weapon family at a time with levels 1-3 = clear commitment and readable power states.  
- Same-type levels up + refills energy; different-type swaps at 1 = delicious risk/reward in the moment.  
This is way more interesting than “collect random power-ups until you’re a god” or “menu crafting.” It keeps every pickup meaningful.

**Faction-per-stage + large weapon pool with gated access** is a huge win for replayability and identity. Each stage feeling mechanically and visually distinct while still defending *the same planet* is the right call. The reverse-engineered rare drops after defeating a faction is perfect meta-progression — tangible, narrative, and exciting without breaking early-run pacing.

**Scope control is admirable.**  
Explicitly saying “no base building,” “no mid-combat pauses,” “non-weapon enhancements deferred,” and “repair drops are rare” shows real discipline. You’re protecting the arcade flow.

### Minor Concerns / Areas to Watch

1. **The level system vs. large weapon pool tension** (you already flagged this).  
   With many weapons and faction gating, same-type drops will be rare. Level 3 might feel almost mythical, which could be good… or frustrating. Consider whether levels are still the best expression of “getting stronger with this weapon” or if something like “heat/synch/charge” that builds during sustained use (and decays on swap) would feel better in a big pool. Or maybe levels stay but level 2/3 upgrades are rarer “catalyst” pickups instead of same-type chips.

2. **Pickup readability in a big pool.**  
   This is going to be critical. Players need to make snap decisions while dodging. Strong color-coding + distinct silhouettes + maybe a 1-second “preview” hover effect (like the mockup style) will be necessary. The HUD showing current weapon + level + energy bar needs to be crystal clear at a glance.

3. **Collision interception tuning.**  
   This has huge potential to feel awesome (last-second hero ram that burns your weapon energy to save the Grid) or terrible (spam-ramming meta). The hierarchy you laid out (weapon energy → capped shield absorption → leak) is correct. Playtesting will be king here — probably need some visual/audio “cost” on ram (screen flash, control jolt, energy burn VFX) so it never feels free.

4. **Between-stage screen.**  
   I’d lean *yes*, but very light. A quick “Faction Defeated — Grid Integrity: X% → Y%” screen with one or two planetary defense upgrades (max integrity, passive regen, collision cap increase, etc.) would feel good without breaking the in-run purity. Keep ship offense 100% in-run.

### Random Sparks / Suggestions (Take or Leave)

- **Visual identity**: Lean hard into the mockup’s dark sci-fi + saturated effects. Each faction’s weapons could have a signature “energy signature” color that carries through bullets, pickups, and the side mini-map icons. Makes the whole game feel connected even as factions change.

- **Pea shooter evolution**: Since it’s permanent, maybe it gets *tiny* permanent upgrades over the whole run (fire rate, a weak piercing shot, etc.) via the rarest reverse-engineered drops or between-stage choices. Keeps the fantasy of “my baseline is getting sharper as I defend the planet over multiple runs.”

- **Difficulty ladder post-clear**: Ascension-style modifiers that change enemy behaviors or add new threats per faction (e.g., “Swarm Faction now deploys cloaked leakers”) feels natural. Or a “Coalition Alert Level” that increases run-to-run.

- **Narrative tone**: The single planet + Defense Grid gives you room for quiet, grounded stakes. You don’t need epic voice acting — just good writing on the side panels and defeat screens. “Another wave incoming. Hold the line.” hits different when you see your planet taking hits in the mini-map.

Overall, this feels like a game I would *immediately* sink hours into. The design decisions show a clear understanding of what makes arcade shmups addictive while adding just enough modern structure to support longer-term play. The open questions are the right ones to be asking.

If you want, I can help drill into any specific section (collision details, faction mechanical signatures, HUD layout ideas, weapon family brainstorming, etc.). Or if you drop the mockup image or any prototype screenshots, I can give more targeted visual/feel feedback.

This is strong work. Keep going — *Last Horizon* has legs. 🚀
