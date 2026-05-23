# T015 — Collision Interception Model

| Field | Value |
|---|---|
| ID | T015 |
| State | completed |
| Phase | M6 — Elite enemy + collision |
| Depends on | T014, T021 |
| Plan reference | `docs/PLAN.md` — M6 |

## Goal

Introduce the **collision interception model** between the player ship and descending enemies (baseline grunts and elites). On contact, the typed-weapon energy meter is spent against the enemy's HP at a 1:1 ratio; whatever HP remains after the spend lands on the Defense Grid immediately and the enemy is consumed by the collision. When the typed-weapon meter is at 0 energy, the ship cannot intercept — the enemy passes through and leaks normally at the planet line, but the player still gets a hit-flash and screen shake so the moment is legible. This implements the **2026-05-22 superseding** of the original 2026-05-14 collision interception entry (which had a capped shared-shield absorption step that is being dropped this slice — see Scope below). Post-hit invulnerability and stacking against bullet hits remain T016's slice; T015 only owns the body-contact path with a minimal proto-cooldown so a cluster touch can't drain the entire meter in one physics frame.

## Scope

- **In scope:**
  - **New decision-log entry — supersedes 2026-05-14 collision interception math.** Append a new `## 2026-05-22 — Collision interception math: energy 1:1 versus enemy HP, no shared-shield cap` entry to `docs/design/decisions.md` (append-only, dated). The new entry must:
    - State the rule: on contact, `energy_spent = min(current_energy, enemy.current_hp)`; drain that much energy; `leftover_hp = enemy.current_hp - energy_spent`; apply `leftover_hp` directly to the Defense Grid; consume the enemy. If `current_energy == 0` at contact, no interception occurs — the enemy is **not** consumed and continues toward the planet line where it leaks normally for its full `leak_damage_per_enemy`.
    - Explicitly list the 2026-05-14 "Collision interception spends weapon energy before shared shield" entry as superseded for the cap-N step. The 1:1 spend semantics of step 1 of that entry survive; step 2 (the shared-shield capped absorption) does not.
    - Note the implication: a typed-weapon meter with even 1 energy can intercept any current enemy (turning a 40-Grid elite leak into a 19-Grid collision, etc.). The marginal value of the last energy unit is high by design — that creates the "hoard one energy point as emergency body-block" decision the player is meant to face. M7 may revisit if playtest shows it dominates.
  - **`CLAUDE.md` damage-hierarchy invariant update.** Edit the "Damage hierarchy" bullet so the collision line reads: "collision spends weapon energy first, then any remaining enemy HP continues toward planet (no shared-shield absorption cap)." Mirror the new decision-log wording; don't touch the other lines.
  - **`PlayerHull` Area2D on the player ship.** Add a new `Area2D` child to `scenes/player/Player.tscn` named `PlayerHull`, sibling of `PickupCollector`. Tight collision shape — a circle of radius ~18 (visibly smaller than the sprite half-width so the player feels generously treated). `collision_layer = 0`, `collision_mask` set to a new dedicated **enemy hull** layer (see below). Its parent is the player ship; the new collision script attaches here.
  - **Enemy hull collision layer.** Both `BaselineEnemy.tscn` and `EliteEnemy.tscn` already carry an Area2D for projectile hit detection (the existing `Hitbox` referenced by `typed_projectile.gd`). Reuse that Area2D — set its `collision_layer` to also include the new enemy-hull layer so the player's `PlayerHull` can detect it. Do **not** add a second Area2D to each enemy; the existing one carries both the projectile-hit and ship-contact roles.
  - **`src/player/player_collision.gd`.** New script attached to the `PlayerHull` Area2D. On `area_entered(area: Area2D)`:
    - Resolve the enemy via `var enemy := area.get_parent()` — the same shape the projectile uses (matches `typed_projectile._on_hitbox_area_entered`). Guard with a `has_method("take_damage")` and `has_method("consume_for_collision")` check; bail silently on no-match.
    - Read `enemy.current_hp` and `typed_weapon_slot.current_energy()`.
    - If `current_energy <= 0.0`: **no-op** for damage. Play collision feedback (see VFX bullet) and return without consuming the enemy. The enemy continues its descent and will leak normally via the existing `_leak()` path.
    - Else: compute `energy_spent := minf(current_energy, enemy.current_hp)`, `leftover := enemy.current_hp - energy_spent`. Call a new `typed_weapon_slot.drain_for_collision(energy_spent)` that subtracts the energy, emits `typed_weapon_energy_changed`, runs `_check_silent_resumed_edge()`, and prints a dedicated event-log line (see Event log additions). If `leftover > 0.0`, call `defense_grid.apply_collision_damage(leftover, enemy.global_position)` (new method on `DefenseGrid` — see below). Then call `enemy.consume_for_collision(global_position)` to destroy the enemy via the collision path.
    - Enforce a **proto-i-frame cooldown.** A local `var _collision_cooldown := 0.0` decremented in `_physics_process`. Each successful collision (whether intercepted or 0-energy pass-through) starts a `0.15 s` cooldown; while cooldown > 0, further `area_entered` events are ignored. This is the scoped minimal de-stack guard so a cluster contact in a single frame can't drain the full meter or trigger N hit-flashes; T016 will formalize a full hit-invulnerability window with broader scope (bullet hits too).
    - Trigger feedback regardless of which branch fired (intercepted or pass-through, except cooldown-suppressed events): energy bar flash on the HUD (reuse the existing energy-bar flash hook from T011/T013 — call into the HUD's existing `flash_partial_refill` analogue, or add a `flash_collision` method on `EnergyMeter` that briefly pulses the bar's color), ship sprite hit-flash (additive white modulate on the player `Sprite2D` for ~0.12 s), and a small screen shake on the main `Camera2D` (~4 px amplitude, ~0.15 s duration). Camera shake is centralized in a new tiny helper or, if no Camera2D currently exists in `Main.tscn`, the helper falls back to translating the `Main` `Node2D` (or the `HUD`'s `CanvasLayer` is left alone). The implementer should pick the cleanest hook given the actual scene tree — the requirement is "visible shake," not a specific transform target.
  - **`TypedWeaponSlot.drain_for_collision(amount: float)` method.** New on `src/player/typed_weapon_slot.gd`. Subtracts up to `amount` from `active_weapon.current_energy` (clamped at 0), emits `typed_weapon_energy_changed`, runs `_check_silent_resumed_edge()`, and prints `typed_weapon_collision_drain family=<id> spent=<float> current=<float> max=<float>`. No projectile spawn, no fire cooldown change.
  - **`DefenseGrid.apply_collision_damage(amount: float, position: Vector2)` method.** New on `src/grid/defense_grid.gd`. Reduces `current_integrity` by the amount (clamped at 0), emits `integrity_changed`, prints `grid_collision_damage amount=<float>` to the event log (distinct from leak damage), and triggers `grid_failed` if integrity hits 0. Distinct from `apply_leak_damage` so the event log distinguishes collision damage from leak damage cleanly; the underlying meter math is the same.
  - **`BaselineEnemy.consume_for_collision(impact_position: Vector2)` and `EliteEnemy.consume_for_collision(impact_position: Vector2)`.** New methods on both enemy scripts. Mark the enemy as consumed (set `_dead = true`), emit a new `collided` signal payloaded with `impact_position`, print `baseline_collided impact=<x,y>` / `elite_collided impact=<x,y>` to the event log (distinct from `killed` and `leaked`), spawn the existing `PixelBurst` for the consume visual, and `queue_free()`. **Do not** emit `killed` (collision is not a kill from the scoring/log perspective) and **do not** emit `leaked` (collision short-circuits the leak path). The new `collided` signal is added to both enemy scripts; no listener is wired in v1 — it exists so future analytics or VFX hooks can subscribe without revisiting the consume path.
  - **Event log additions.**
    - `typed_weapon_collision_drain family=<id> spent=<float> current=<float> max=<float>` — one per intercepting collision.
    - `grid_collision_damage amount=<float>` — one per intercepting collision that has leftover HP (omitted when energy fully covered enemy HP).
    - `baseline_collided impact=<x,y>` / `elite_collided impact=<x,y>` — one per intercepting collision.
    - `collision_no_intercept reason=zero_energy enemy=<baseline|elite>` — one per 0-energy contact event (after the proto-cooldown check). Communicates "the player got hit but couldn't intercept."
    - `collision_cooldown_suppressed` — one per `area_entered` event suppressed by the 0.15 s proto-cooldown. Useful for tuning the cooldown duration during playtest.
  - **No changes to `take_damage`.** Projectiles continue to call `enemy.take_damage(amount, hit_position)` exactly as today. The collision path is a separate code path that calls `consume_for_collision` directly; it does not route through `take_damage`. This keeps the projectile-damage event-log vocabulary (`damaged`, `killed`) unchanged.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0 with the new collision script, hull Area2D, drain/apply methods, and consume methods loading cleanly.
  - **T020 grid-alignment verifier still passes** — the enemy Hitbox layer change does not affect formation spacing or sway.

- **Out of scope:**
  - **Full post-hit invulnerability window (T016).** T015's 0.15 s proto-cooldown is intentionally minimal and applies only between collision events on the player hull. T016 will introduce the broader hit-invulnerability semantics covering bullet hits, collisions, and any future damage source on a shared timer with reviewer-tunable duration. The proto-cooldown stays in place when T016 lands — T016 either replaces it with the broader window or layers on top, but does not require T015 to anticipate that decision.
  - **Bullet-hit absorption against the energy meter.** Enemies do not shoot in v1 (per the existing scope), so the "energy absorbs enemy fire" half of the dual-role energy model is not exercised here. Collisions are the only damage path against the player in v1.
  - **Repair carriers / Defense Grid healing.** Still an open question in the design log; T015 only adds the collision damage path.
  - **Per-faction collision flavoring** (different VFX or shake amplitudes per faction). v1 has one coalition; faction-themed collision feel is post-v1.
  - **Tuning iteration on the 0.15 s proto-cooldown, the ~18 px hull radius, the 0.12 s hit-flash duration, or the ~4 px / 0.15 s shake.** Starting values are committed by this task; M7 (tuning consolidation) is the natural place to revisit.
  - **Knockback / control penalty** on the player ship from a collision. The 2026-05-14 collision entry's implication note ("Additional feedback or control penalties may still be needed so repeated ramming feels costly and readable") is acknowledged; this slice ships hit-flash + shake + the proto-cooldown as the readability surface. A control penalty (brief stun / slow / drift) is explicitly deferred. If playtest in M7 shows ramming is overused, that's the natural reopen point.
  - **Collision against carriers** (weapon-chip carriers and fuel-cell carriers). Carriers are not enemies and do not occupy the enemy-hull collision layer. Player-carrier contact remains the existing pickup path (`PickupCollector` Area2D), unchanged.
  - **Projectile sprites, pea shooter, typed-weapon slot beyond `drain_for_collision`, energy meter beyond the optional `flash_collision`, weapon families, weapon chips, fuel cells, run-end overlay, T020 grid-aligned spacing, T021 zero-energy persistence / letter glyphs.** Not touched.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

| Date | Change |
|---|---|
| 2026-05-23 | User-requested tuning adjustment while T015 remained active: halve live armada descent speed from `32.5 px/s` to `16.25 px/s` and double the grid-aligned spawn interval from `6.09 s` to `12.18 s`. This is scoped as tuning only; collision rules and evidence shape are unchanged. |
| 2026-05-23 | User follow-up tuning adjustment: `16.25 px/s` was too slow, so the live armada descent speed is increased to `24.375 px/s` (midpoint between `32.5` and `16.25`). The grid-aligned spawn interval is recalculated to `8.12308 s`. |

## Pre-flight

- [x] T014 and T021 accepted; elite tier is live in the armada and the typed-weapon family persists through zero energy (with `typed_weapon_silent` / `typed_weapon_resumed` edge logging in place). The "0 energy = silent" semantics from T021 are exactly what the T015 collision model keys on for the no-intercept branch.
- [x] Re-read 2026-05-14 "Collision interception spends weapon energy before shared shield" — confirm the user-decided 2026-05-22 supersede: the cap-N shared-shield step is dropped; 0 energy = no intercept; 1:1 energy-to-HP spend on contact. Append the new dated decision-log entry as part of this task.
- [x] Re-read 2026-05-14 "Brief post-hit invulnerability" — confirm T016 is the full owner; T015 ships a 0.15 s proto-cooldown as a minimal de-stack guard, not the broader invulnerability window. The proto-cooldown's specific duration is a starting tuning value.
- [x] Re-read 2026-05-22 "Typed weapon persists at zero energy" (T021) — confirm: `current_energy()` returns 0.0 with the family still equipped at the post-T021 zero-energy state, which is the state the 0-energy no-intercept branch must respond to. The `has_weapon()` check is **not** the right gate (it returns `true` through zero); the gate is `current_energy() > 0.0`.
- [x] Re-read 2026-05-16 "Damage hierarchy" — confirm the new collision rule still respects "collision is a last-line resource conversion, not a free defensive move" at non-zero energy, and ramps to "0 energy = no intercept" at the zero edge. The damage hierarchy bullet in `CLAUDE.md` needs the cap-N phrase removed.
- [x] Grep `area.get_parent()` in `src/weapons/typed_projectile.gd` to confirm the enemy node sits one level above the Area2D — the collision script will use the same shape.
- [x] Confirm the existing enemy `Hitbox` Area2D on `BaselineEnemy.tscn` and `EliteEnemy.tscn` can take an additional collision layer bit without breaking projectile detection (Godot collision layers are a bitmask; setting an additional bit is additive and projectiles only mask the projectile-hit bit).
- [x] Confirm no current camera shake / screen-shake infrastructure exists — implementer picks the cleanest hook given the actual scene tree. If `Main.tscn` doesn't have a `Camera2D`, transient translation of a parent `Node2D` is acceptable; the requirement is "visible shake," not a specific transform target.

## Implementation notes

- **`scenes/player/Player.tscn`.**
  - Add `PlayerHull` `Area2D` child of `Player`, sibling of `PickupCollector`. `collision_layer = 0` (the hull does not need to be a target), `collision_mask` set to the enemy-hull layer bit (pick the next free bit number — likely layer 4 if pickups are on 2; the implementer chooses based on the actual layer assignments in the scene tree). `CollisionShape2D` child with a `CircleShape2D` of radius `18.0`.
  - Attach `src/player/player_collision.gd` to `PlayerHull`.
- **`src/player/player_collision.gd`.**
  - `extends Area2D`.
  - `@export var typed_weapon_slot_path: NodePath` (set to `../TypedWeaponSlot` in the scene).
  - `@export var defense_grid_path: NodePath` (set to `../../DefenseGrid` in `Main.tscn` via the player's `PlayerHull` override, or resolved lazily by `find_child` if the path is left empty — pick the cleanest one; the rest of v1 uses NodePath exports).
  - `@export var ship_sprite_path: NodePath` (set to `../Sprite2D`) for the hit-flash modulate target.
  - `@export var collision_cooldown_seconds := 0.15`.
  - `@export var hit_flash_seconds := 0.12`.
  - `@export var screen_shake_amplitude := 4.0`.
  - `@export var screen_shake_seconds := 0.15`.
  - `var _cooldown := 0.0`.
  - `_ready` resolves the three node references (with `push_warning` on each missing reference and a graceful degrade — collision still resolves damage even if visuals fail to wire).
  - `_physics_process(delta)` decrements `_cooldown`.
  - `area_entered(area)` is the hot path; structure described in Scope above.
  - Hit-flash is a private `_run_hit_flash()` coroutine using `await get_tree().create_timer(hit_flash_seconds).timeout` to revert modulate.
  - Screen shake is a private `_run_screen_shake()` coroutine.
- **`src/player/typed_weapon_slot.gd`.**
  - New `func drain_for_collision(amount: float) -> float` returning the actual amount drained (could be less than `amount` if energy is already low — though the caller pre-clamps, defensive coding helps). Internals: clamp the subtraction at 0, emit `typed_weapon_energy_changed`, call `_check_silent_resumed_edge()`, print the event-log line. No fire cooldown change (collisions don't affect the typed-weapon fire interval).
- **`src/grid/defense_grid.gd`.**
  - New `func apply_collision_damage(amount: float, impact_position: Vector2) -> void`. Mirrors `apply_leak_damage`'s internal math (clamp, emit `integrity_changed`, check `_failed` / `grid_failed`), but emits a new `collision_registered(amount: float, impact_position: Vector2)` signal (distinct from `leak_registered`) and prints the `grid_collision_damage` event-log line. No new HUD wiring is required in v1 — the existing `GridMeter` listens to `integrity_changed`, which fires from both paths uniformly.
- **`src/enemies/baseline_enemy.gd`** and **`src/enemies/elite_enemy.gd`.**
  - Add `signal collided(impact_position: Vector2)`.
  - Add `func consume_for_collision(impact_position: Vector2) -> void`. Guard against double-consume / already-dead / already-leaked via the existing `_dead` / `_leaked` flags. Set `_dead = true`, emit `collided.emit(impact_position)`, print the `baseline_collided` / `elite_collided` event line, spawn the `PixelBurst` at the impact position, and `queue_free()`. Do **not** emit `killed` or `leaked` — those are reserved for the projectile and leak paths respectively.
- **`scenes/enemies/BaselineEnemy.tscn`** and **`scenes/enemies/EliteEnemy.tscn`.**
  - On the existing `Hitbox` Area2D child of each, extend `collision_layer` to also include the new enemy-hull layer bit. Projectile detection (which masks the projectile-hit bit) is unaffected.
- **`scenes/main/Main.tscn`.**
  - If a `Camera2D` doesn't currently exist and the implementer chooses a Camera2D as the shake target, add one as a child of `Main` and assign it as current. Otherwise no Main.tscn change is required — the shake can drive a `Node2D` transient offset on `Main` itself.
- **`CLAUDE.md`.**
  - Edit the **Damage hierarchy** bullet: change the collision line from "collision spends weapon energy first, then capped shield absorption, then remainder continues toward planet" to "collision spends weapon energy first 1:1 against enemy HP, then any remaining enemy HP applies directly to Grid integrity (no cap); at 0 energy, no interception — enemy continues to leak normally." Leave the rest of the bullet intact.
- **What not to touch in this slice.** `PeaShooter`, weapon-chip carriers, fuel-cell carriers, the five family resources, projectile sprites, `EnergyMeter` layout beyond an optional `flash_collision` polish, `GridMeter` (the integrity_changed signal already paints it), run-end overlay, T020 grid-alignment, T021 letter glyphs, T021 zero-energy persistence behavior.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T015-collision-interception-model/full-energy-ram-elite-clip.mp4` (or stills) — clip of the player at full typed-weapon energy ramming a single elite. The elite is consumed on contact; energy bar visibly drops by 20 (or by the elite's `current_hp` if it was already damaged); Defense Grid takes 0 damage. Confirms the "energy fully covers HP" branch.
- `tests/evidence/T015-collision-interception-model/partial-energy-ram-elite-clip.mp4` (or stills) — clip of the player with ~5 energy ramming a full-HP elite (20 HP). Energy drops to 0; elite is consumed; Defense Grid drops by exactly 15. HUD before/after confirms the math. Confirms the "leftover-HP-lands-on-Grid" branch.
- `tests/evidence/T015-collision-interception-model/zero-energy-no-intercept-clip.mp4` (or stills) — clip of the player at 0 energy (typed weapon silent) being contacted by a descending baseline grunt. Visual feedback plays (ship sprite flash, screen shake, energy bar flash if wired). The grunt is **not** consumed; it continues and leaks at the planet line for full 10 Grid damage. Confirms the "no intercept at 0 energy" branch.
- `tests/evidence/T015-collision-interception-model/zero-energy-no-intercept-elite-clip.mp4` (or stills) — same shape as above, but with an elite. Elite continues, leaks for 40 Grid damage. Confirms the 0-energy branch scales correctly to the elite tier.
- `tests/evidence/T015-collision-interception-model/cluster-cooldown-clip.mp4` (or stills) — clip showing a tight cluster of enemies contacting the player ship in close succession. At most one collision resolves per cooldown window; the event log shows `collision_cooldown_suppressed` lines for the suppressed events.
- `tests/evidence/T015-collision-interception-model/feedback-readability-still.png` — single still or short clip isolating the ship hit-flash + screen shake during a collision. A reviewer can confirm the visual is legible without obscuring bullets / enemies / the HUD.
- `tests/evidence/T015-collision-interception-model/event-log.txt` — captured event log from a ~2-minute live run showing `typed_weapon_collision_drain`, `grid_collision_damage`, `baseline_collided`, `elite_collided`, `collision_no_intercept`, and at least one `collision_cooldown_suppressed` line. Baseline `killed` / `leaked` and elite `elite_killed` / `elite_leaked` lines remain unchanged in shape and appear interleaved.
- `tests/evidence/T015-collision-interception-model/collision-verification.txt` — output of the verifier script. Must end in `COLLISION_VERIFICATION_OK`.
- `tests/evidence/T015-collision-interception-model/grid-alignment-still-passes.txt` — rerun of the T020 grid-alignment verifier with the new enemy-hull collision-layer bit active. Must still end in `GRID_ALIGNMENT_VERIFICATION_OK`.
- `tests/evidence/T015-collision-interception-model/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T015-collision-interception-model/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T015-collision-interception-model/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] At full typed-weapon energy, ramming a baseline grunt (5 HP) drains 5 energy, consumes the grunt, and deals 0 Grid damage.
- [ ] At full typed-weapon energy, ramming a full-HP elite (20 HP) drains 20 energy, consumes the elite, and deals 0 Grid damage.
- [ ] At ~5 energy, ramming a full-HP elite drains the 5 energy to 0, consumes the elite, and deals exactly 15 Grid damage. The event log shows `typed_weapon_collision_drain spent=5.00` and `grid_collision_damage amount=15.00`.
- [ ] At 0 energy (typed weapon silent), contact with a baseline grunt does **not** consume the grunt; the grunt continues to the planet line and leaks for the full 10 Grid damage. Ship hit-flash and screen shake still play; the event log shows `collision_no_intercept reason=zero_energy enemy=baseline` followed (later) by the existing `leaked` line for the same grunt.
- [ ] At 0 energy, contact with an elite does **not** consume the elite; it continues and leaks for 40 Grid damage. Event log shows `collision_no_intercept reason=zero_energy enemy=elite`.
- [ ] Cluster contact (two or more enemies hitting the ship within 0.15 s) resolves at most one collision per cooldown; the event log shows `collision_cooldown_suppressed` lines for the suppressed events. The energy meter does not drain by the sum of all touched enemies in a single physics frame.
- [ ] Collision feedback is legible: ship sprite hit-flash (~0.12 s), screen shake (~4 px / ~0.15 s), and energy-bar flash all play and are distinguishable from a typed-weapon firing event.
- [ ] The 0.15 s proto-cooldown does **not** affect the typed-weapon fire interval, the pea-shooter cadence, or any other system. Firing continues normally during and after a collision.
- [ ] `consume_for_collision` does not emit `killed` or `leaked`; the new `collided` signal fires instead. Projectile-driven kills still emit `killed` and still print `baseline_killed` / `elite_killed` lines. Leak-line crossings still emit `leaked` and print the baseline / elite leak lines.
- [ ] T021 zero-energy persistence is unchanged: the typed-weapon family is still held at 0 energy after a partial-energy collision drains the meter to 0; the next chip or fuel cell refills the same family.
- [ ] No regressions in weapon-chip carrier behavior, fuel-cell carrier behavior, typed-weapon refill/swap semantics, pea-shooter firing, T020 grid alignment, baseline/elite descent, or run-end behavior.
- [ ] CLAUDE.md "Damage hierarchy" invariant has been updated to match the 2026-05-22 superseding decision-log entry.
- [ ] `decisions.md` has a new dated entry superseding the 2026-05-14 collision interception math (cap-N step removed; 0-energy = no intercept committed).
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_collision.gd` output ends in `COLLISION_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T015-collision-interception-model/verify_collision.gd > tests/evidence/T015-collision-interception-model/collision-verification.txt
tools/godot/bin/godot --headless --path . --script tests/evidence/T020-grid-aligned-armada-spacing/verify_grid_alignment.gd > tests/evidence/T015-collision-interception-model/grid-alignment-still-passes.txt
tools/run_headless_smoke.sh > tests/evidence/T015-collision-interception-model/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T015-collision-interception-model/capture_live_collision_evidence.gd > tests/evidence/T015-collision-interception-model/live-capture.txt
git status > tests/evidence/T015-collision-interception-model/git-status.txt
```

Visual evidence (the five clips and the feedback-readability still) is produced from the live `Main.tscn` scene tree by `capture_live_collision_evidence.gd`. The capture script may force-equip the player into a known typed-weapon family, force-set `current_energy` to a known fraction (full / partial / 0), force-spawn isolated enemies at known positions just above the player ship, and force-drive contacts at deterministic intervals to make each clip reproducible.

The verifier script `verify_collision.gd` must exercise (at minimum):

1. With `current_energy = 100` (or any value ≥ `enemy.current_hp`), invoke the collision path against a stub baseline (`current_hp = 5`). Assert: `typed_weapon_slot.current_energy() == 95.0` (within tolerance), `defense_grid.current_integrity` is unchanged, the baseline stub's `collided` signal fired exactly once with the impact position, `consume_for_collision` was called exactly once, and `killed` / `leaked` did **not** fire.
2. With `current_energy = 5` and a stub elite (`current_hp = 20`), invoke the collision path. Assert: `current_energy == 0.0`, `defense_grid.current_integrity` dropped by exactly `15.0`, the elite's `collided` fired exactly once, `typed_weapon_silent` fired exactly once (from the energy-to-zero edge), and the elite is queued for deletion.
3. With `current_energy = 0` and a stub baseline, invoke the collision path. Assert: `current_energy` is still `0.0`, `defense_grid.current_integrity` is unchanged, the baseline's `collided` did **not** fire, `consume_for_collision` was **not** called, and the `collision_no_intercept` event-log line was printed exactly once.
4. With `current_energy = 100` and two stub baselines contacting in the same physics tick, simulate two consecutive `area_entered` events 0.05 s apart. Assert: only the first resolves (energy drains by 5, one `collided` fires), the second is logged as `collision_cooldown_suppressed`, and after `> 0.15 s` a third contact resolves normally.
5. `DefenseGrid.apply_collision_damage(15.0, Vector2.ZERO)` reduces integrity by 15, emits `integrity_changed` and `collision_registered`, and prints the `grid_collision_damage` event-log line. At 0 remaining integrity, `grid_failed` fires exactly once. `apply_leak_damage` continues to work independently and emits the existing `leak_registered`.
6. `TypedWeaponSlot.drain_for_collision(7.0)` on a slot at `current_energy = 10` reduces energy to 3, emits `typed_weapon_energy_changed`, does not trigger `typed_weapon_silent` (still above zero), and prints the `typed_weapon_collision_drain` event-log line. Calling `drain_for_collision(50.0)` on a slot at `current_energy = 3` reduces energy to 0 (clamped, no negative), emits `typed_weapon_silent` exactly once, and prints the line with `spent=3.00`.
7. The 2026-05-22 collision math decision-log entry exists in `docs/design/decisions.md` and explicitly lists the 2026-05-14 collision entry as superseded for the cap-N step. (Verifier reads the file; a substring match is sufficient.)
8. The `CLAUDE.md` damage-hierarchy bullet contains the new wording ("no cap" / "no interception" at 0 energy). (Verifier reads the file; substring match.)
9. Prints `COLLISION_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-23 | Created and activated. Pre-flight Q&A with user resolved the four opinion gaps the 2026-05-14 collision entry left open: **energy-to-HP conversion** is a straight **1:1, full meter spendable** spend; the **cap-N shared-shield step is dropped** (leftover HP after the energy spend lands directly on the Defense Grid, no intermediate cap); **multi-body stacking** is handled in T015 by a **0.15 s proto-cooldown** between collision resolutions (T016 will own the full hit-invulnerability window); and **feedback** is **energy-flash + ship sprite hit-flash + screen shake** per collision. The user further clarified that at **0 energy the ship cannot intercept** — the enemy is not consumed, continues to leak normally, and the player still gets the visual feedback so the moment is legible. T015 will append a new dated decision-log entry capturing the 2026-05-14 supersede before implementation begins. |
| 2026-05-23 | Implemented the collision interception path and evidence. Added the 2026-05-23 decision-log supersede, updated the `CLAUDE.md` damage hierarchy, added `PlayerHull` with an enemy-hull collision layer, implemented `src/player/player_collision.gd`, `TypedWeaponSlot.drain_for_collision`, `DefenseGrid.apply_collision_damage`, and baseline/elite `consume_for_collision` paths. Added HUD collision flash and camera shake feedback. Generated T015 evidence under `tests/evidence/T015-collision-interception-model/`; `verify_collision.gd` ends in `COLLISION_VERIFICATION_OK`, T020 grid alignment still ends in `GRID_ALIGNED_VERIFICATION_OK`, and headless smoke still prints `LAST_HORIZON_BOOT_SMOKE_OK`. Evidence is ready for human review; stopping at the task boundary per workflow. |
| 2026-05-23 | Applied user tuning request to reduce armada descent speed by 2x. Updated the design log with the 2026-05-23 armada speed tuning decision and preserved the T020 grid spacing invariant by doubling `EnemySpawner.spawn_interval_seconds`. Re-ran collision verification, grid alignment, headless smoke, and live T015 evidence capture after the tuning change. |
| 2026-05-23 | Applied follow-up tuning request to set armada descent speed to `24.375 px/s` and `EnemySpawner.spawn_interval_seconds` to `8.12308 s`. Added a superseding decision-log entry for the midpoint tuning and re-ran collision verification, grid alignment, headless smoke, and live T015 evidence capture. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
