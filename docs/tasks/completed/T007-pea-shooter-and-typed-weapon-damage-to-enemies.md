# T007 — Pea Shooter + Typed Weapon Damage to Enemies

| Field | Value |
|---|---|
| ID | T007 |
| State | completed |
| Phase | M3 — Enemy baseline + Defense Grid |
| Depends on | T006 |
| Plan reference | `docs/PLAN.md` — M3 |

## Goal

Wire **damage exchange** into the existing armada. Pea-shooter and typed-weapon projectiles now hit baseline enemies, decrement HP, and kill them when HP reaches 0. The dual stream the player has been firing across the screen since T004 finally interacts with the descending blocks from T006 — this is the first task in which the player can affect the playfield. Defense Grid damage on leak, collision response, and run-end all remain T008/M6.

## Scope

- **In scope:**
  - **Hit detection between projectiles and baseline enemies.** Pea bullets and typed-weapon projectiles collide with baseline enemies; on hit the projectile applies its damage and is freed. Implementation uses Godot `Area2D` nodes on both projectile and enemy with a single dedicated collision layer/mask pair so the routing is unambiguous. Projectiles do not pierce — one hit, one free.
  - **HP decrement on the baseline enemy.** Replace the inert `max_hp` field from T006 with a `current_hp` runtime value initialized from `max_hp` on `_ready()`. Expose `take_damage(amount: float) -> void` (or equivalent) on the enemy. When `current_hp` drops to `<= 0`, the enemy is killed.
  - **Tuned starting damage and HP numbers** that produce a **5-hit pea kill** on baseline and a **2-hit typed-weapon kill** on baseline (per user direction 2026-05-20). Starting values: `BaselineEnemy.max_hp = 5.0`, pea-bullet `damage = 1.0`, typed-weapon-family `projectile_damage = 3.0` (overkill on the second hit is fine — floats are not load-bearing here). These are tuning starting points; expose them as `@export` where they aren't already. Update `data/weapons/debug_plasma.tres` to match the new family damage.
  - **Pea-bullet damage field.** `pea_bullet.gd` currently has no `damage` field. Add `@export var damage := 1.0` so the pea shooter is a damage source on the same shape as the typed projectile. Damage is per-bullet on the projectile, not per-shooter — the shooter does not need to know its damage; the projectile carries it.
  - **Floating damage numbers on hit.** Each landed hit spawns a tiny short-lived label at the hit position showing the integer damage dealt. The label drifts upward a few pixels over ~0.4s while fading out, then frees itself. Plain styling for now (single color, modest pixel font / default theme is fine) — the design log allows for future crit-styled variants but those are explicitly out of scope here. The label must not be load-bearing for gameplay: if it fails to spawn, gameplay continues.
  - **Pixel-burst kill effect.** When a baseline enemy is killed, spawn a small pixel-burst particle effect at the enemy's position: **8–12 fragments**, lifetime **~0.2s**, fragments colored from the baseline enemy's palette so the burst reads as "that thing came apart" rather than as a generic VFX. Implementation can be `CPUParticles2D`, `GPUParticles2D`, or a hand-rolled `Node2D` with a few `ColorRect`/sprite children — whichever is cheapest and reads correctly. The enemy node itself is freed immediately; the burst lives independently and frees itself when its lifetime ends.
  - **Formation cleanup on child death.** When a baseline enemy is killed mid-descent, the enemy is freed and removed from its formation's child set, but the formation continues descending normally. The block's coherence in T006 was "rigid rows × cols translating downward"; with kills, the block becomes a partially-empty grid descending at the same speed — explicitly do not re-pack survivors into a denser block. If the formation's free-when-empty rule from T006 was per-child-count, make sure dying-from-damage triggers it the same way scrolling-off-the-bottom did (no double-free, no orphaned formations).
  - **Damage source decoupling.** The enemy's `take_damage` does not care whether the source is a pea bullet or a typed projectile. The projectile is responsible for carrying its `damage` value; the enemy is responsible for subtracting and resolving death. No `is_typed_weapon` branching inside the enemy.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. Damage-resolution code paths must not require a running render loop or input to import cleanly.
- **Out of scope:**
  - **Defense Grid Integrity meter and leak damage.** T008. Enemies that reach the bottom still despawn silently per T006.
  - **Run-end.** T008. The scene continues running forever; the player simply gets a cleaner playfield as they shoot.
  - **Enemy fire / bullets / damage to the player.** Deferred per the v1 enemy-fire decision. The energy meter's shield channel remains unexercised; this task only exercises the *outbound* damage direction.
  - **Collision interception model (enemy-body vs. ship).** M6 / T015. The player ship still passes through enemies without consequence.
  - **Post-hit invulnerability.** M6 / T016. There is nothing for the player to be invulnerable *to* until T008/T015.
  - **Elite / heavy enemy tier.** M6 / T014. One enemy type only, same as T006.
  - **Kill counter, score display, combo meter, on-kill audio.** Not authored. The pixel burst plus damage numbers are sufficient feedback for the playtest evidence; persistent scoring is not in v1's seven scope questions.
  - **Carriers and pickups.** M4/M5.
  - **Crit / variant damage-number styling.** User indicated future support; not in this task.
  - **Bullet pierce, area-of-effect, multi-hit typed projectiles.** Will arrive with M4 weapon families. The placeholder typed weapon stays one-projectile-one-hit.
  - **Faction visual variants on the kill burst.** v1 has one placeholder faction; the burst palette derives from the single baseline-enemy sprite, no per-faction theming.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T006 accepted; armada descends, two blocks coexist, per-enemy sway visible, enemies silently despawn off the bottom.
- [x] Re-read the 2026-05-16 "Elite/heavy enemy tier per faction" entry — baseline is "low HP, killable by the pea shooter within the time they spend in the playfield." A 5-hit pea kill at the current pea cadence/baseline-descent speed must satisfy that definition; if it doesn't (e.g., baseline crosses the playfield before 5 pea hits land under reasonable aim), raise it before tuning numbers harder. The fix is HP/cadence/speed, not "baseline survives the playfield."
- [x] Re-read the 2026-05-16 stage-shape entry — armada is continuous, not wave-with-downtime. Damage and kills do not introduce a "wave cleared" beat; killing one block does not stop the spawner.
- [x] Re-read the 2026-05-19 "Remove weapon levels" entry — damage values are per-family / per-projectile constants, not level-derived. Do not add level-keyed damage scaling.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — the pixel-burst fragments and damage-number label are placeholder visuals, not final art. Programmer-rectangle fragments are acceptable here because the burst is a transient effect, not a persistent entity silhouette.
- [x] Re-read `docs/design/scope.md` v1 in-scope/out — verify nothing in this task crosses into M4/M5/M6 territory.

## Implementation notes

- **Collision routing.** Use one collision layer for "enemy hurtbox" and one for "player projectile". Each baseline enemy carries an `Area2D` on the enemy layer with a mask that ignores other enemies. Each projectile carries an `Area2D` on the projectile layer with a mask matching the enemy layer. On `area_entered`, the projectile reads the area's parent (the `BaselineEnemy` node) and calls `take_damage(damage)`, then `queue_free()`s itself. The enemy's `Area2D` does not need to handle the signal — single direction is enough and avoids double-resolution.
- **Bullet → enemy damage carry.** Both `pea_bullet.gd` and `typed_projectile.gd` need an exported `damage` field. The pea shooter does not need to know its own damage; the bullet does. The typed-weapon slot already configures the typed projectile from the family resource (`configure_from_family`) — that path already carries `projectile_damage`, just verify it reaches the bullet.
- **Enemy death.** `take_damage(amount)` subtracts from `current_hp`, emits a `damaged(amount, hit_position)` signal (or calls a sibling node directly) for the damage-number spawn, and if `current_hp <= 0` triggers the kill path: spawn the pixel burst at `global_position`, then `queue_free()`. Keep the kill path inside the enemy script — the formation does not need to know how the enemy died, only that it is gone (formation's existing free-when-empty logic from T006 should handle the rest).
- **Damage-number label.** A small autoload-free scene `scenes/ui/DamageNumber.tscn` with a `Label` and a script that tweens `position.y -= 12` and `modulate.a → 0` over ~0.4s, then `queue_free()`s. Spawn at the hit position in the *playfield's* coordinate frame, not as a HUD child — these are diegetic to the game layer, not part of the HUD overlay. Pass the integer damage on instantiation.
- **Pixel-burst.** Lean implementation: a `CPUParticles2D` configured one-shot with `amount = 10`, `lifetime = 0.2`, `explosiveness = 1.0`, small `scale_amount_min/max`, fragment color sampled from the enemy sprite's dominant hue (or a hard-coded palette match — sampling the texture is overkill for v1). Set `one_shot = true` and `emitting = true` on `_ready`, then `queue_free` on a `Timer`. Alternative: a tiny custom `Node2D` that spawns ~10 `Sprite2D` children with randomized velocities and frees itself at 0.2s — either is acceptable. Pick whichever reads as "thing came apart in pixels" not "thing dissolved smoothly."
- **Hit position for feedback.** Both the damage-number spawn and the kill burst should use the enemy's `global_position` (or the projectile's hit position — close enough at v1 enemy sizes). Don't try to derive a contact normal.
- **Numbers.**
  - `BaselineEnemy.max_hp`: `5.0` (was `3.0` in T006 — bump it).
  - `pea_bullet.damage`: new `@export`, default `1.0`.
  - `TypedWeaponFamily.projectile_damage` and `data/weapons/debug_plasma.tres`: `3.0` (was `2.0`).
  - These are tuning starting points. If the resulting feel is wrong, change them — do not lock them in by burying them as constants.
- **What not to touch in this slice.** Do not change the formation's descent speed, the spawner's cadence, the player's movement, the energy-meter mechanic, the HUD, or the pea-shooter cadence. The only behavior changes are: projectiles can hit, enemies can die, kills produce feedback.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/damage-exchange.mp4` (or short still series) — capture of the live scene showing: pea bullets hitting and chipping baseline enemies with floating damage numbers appearing per hit, the typed-weapon stream killing baselines in two hits, and the pixel-burst kill effect playing on death. The clip must include at least one kill from the pea shooter alone (5 hits, no typed weapon active) and at least one kill from the typed weapon (2 hits).
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/hit-feedback-detail.png` — close-crop screenshot showing the floating damage number(s) clearly readable above a hit enemy.
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/kill-burst-detail.png` — frame from the kill burst — fragments visible, palette-matched to the baseline enemy.
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/leak-still-silent.md` — short reviewer-facing note confirming: enemies that survive and reach the bottom still despawn silently with no Grid feedback or run-end (T008 territory).
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/passthrough-still-holds.md` — note confirming: the player ship still passes through enemies without collision response (M6 territory).
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/damage-verification.txt` — output of a headless verification script that:
  - Instantiates a baseline enemy and a pea bullet, simulates collision, asserts HP went from 5 to 4 and the bullet was freed.
  - Instantiates a baseline enemy and a typed projectile (damage 3), simulates collision, asserts HP went from 5 to 2.
  - Instantiates a baseline enemy at HP 1, applies a pea bullet, asserts the enemy entered the kill path (signal fired or `queue_free()` queued).
  - Ends with a recognizable `DAMAGE_VERIFICATION_OK` line.
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/headless-smoke.txt` — rerun of headless smoke; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/damage-checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] Pea bullets that intersect a baseline enemy deal `1.0` damage and are freed on contact. After 5 pea hits, the enemy dies.
- [ ] Typed-weapon projectiles deal `3.0` damage per hit and are freed on contact. After 2 typed hits, a fresh baseline enemy dies.
- [ ] Each landed hit (pea or typed) spawns a small floating damage number at the hit position that drifts upward and fades over ~0.4s. The numeric value shown matches the damage dealt.
- [ ] When a baseline enemy is killed, a small pixel-burst (8–12 fragments, ~0.2s, palette-matched) plays at the death position. The enemy node itself is freed at the same instant.
- [ ] The formation continues descending normally with kills mixed in — the block does not re-pack survivors, does not stop, does not accelerate, does not spawn replacement enemies.
- [ ] Enemies that survive and reach the bottom of the playfield still despawn silently with no Grid effect, no run-end, no feedback. (T008 territory.)
- [ ] The player ship still passes through enemies without consequence — no collision response was introduced. (M6 territory.)
- [ ] The energy meter, HUD, pea-shooter cadence, formation descent speed, and spawner cadence are unchanged versus T006. The only new behavior is damage and its feedback.
- [ ] `pea_bullet.gd` carries a `damage` `@export`; `typed_projectile.gd` continues to read damage from its family resource; `TypedWeaponFamily.projectile_damage` and `data/weapons/debug_plasma.tres` are updated to `3.0`; `BaselineEnemy.max_hp` is `5.0`.
- [ ] No level-keyed damage scaling, no rarity tiers, no crit handling, no AOE/pierce projectile behavior were introduced. (Per the 2026-05-19 level removal and v1 scope.)
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] No carriers, no pickups, no enemy bullets, no Defense Grid meter, no run-end were introduced.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/verify_damage.gd > tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/damage-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/capture_live_damage_evidence.gd > tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/live-capture.txt
git status > tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/git-status.txt
```

Visual evidence (`damage-exchange.mp4`, `hit-feedback-detail.png`, `kill-burst-detail.png`) is produced from the live `Main.tscn` scene tree by `capture_live_damage_evidence.gd`, mirroring the T006 capture approach.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-20 | Created and activated. Pre-flight: T006 evidence accepted; the 2026-05-16 elite/heavy and stage-shape entries plus the v1 scope are the governing decisions. Tuning starting points fixed by user direction this session: baseline = 5 HP (pea = 1 dmg, 5-hit kill), typed = 3 dmg (2-hit kill). Hit feedback = tiny floating damage numbers (crit styling reserved for later). Kill feedback = small pixel-burst particle (8–12 fragments, ~0.2s, palette-matched). |
| 2026-05-20 | Implemented T007 damage slice: projectile hitboxes now damage baseline enemy hurtboxes; baseline enemies track runtime HP, spawn floating damage numbers on hit, and spawn a short pixel burst on death; empty formations clean themselves up without repacking survivors. Generated verification, smoke, live capture, checklist, leak-silent, passthrough, and git-status evidence under `tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies/`. |
| 2026-05-20 | Accepted by human reviewer and moved to completed. |

## Blocker

None.
