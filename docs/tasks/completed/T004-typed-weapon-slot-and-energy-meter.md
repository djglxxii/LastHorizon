# T004 — Typed-weapon Slot + Dual-role Energy Meter

| Field | Value |
|---|---|
| ID | T004 |
| State | completed |
| Phase | M2 — Typed weapon + energy meter |
| Depends on | T003 |
| Plan reference | `docs/PLAN.md` — M2 |

## Goal

Add the player's **typed-weapon slot** with a **dual-role energy meter**, the load-bearing mechanic the entire v1 prototype exists to playtest (per `design/scope.md` and the 2026-05-16 dual-role decision). Player fire input now drives a single placeholder typed weapon whose firing drains a shared energy pool; when the pool hits zero, the typed weapon expires and the player drops back to the always-on pea shooter. No HUD yet (that is T005) and no enemy fire to absorb yet (that channel of the dual-role pool is exercised in M3/M6); this task delivers the slot, the energy meter, the firing-drain channel, and the expiry transition.

## Scope

- **In scope:**
  - A **typed-weapon slot** on the player. At most one typed weapon is held at a time. When no typed weapon is held, the slot is empty and player fire input does nothing (the pea shooter continues unaffected).
  - A **dual-role energy meter** owned by the player (data only — no on-screen meter in this task). Fields: `max_energy` (`@export`, configurable per weapon family), `current_energy` (runtime). The meter is the shared shield-and-ammo pool from the 2026-05-16 invariant, even though only the firing-drain channel is wired up in this task.
  - **Player fire input** controls only the typed weapon. Pressing/holding the fire input while a typed weapon is held emits typed-weapon shots and drains `current_energy` by the family's `firing_cost` per shot. Fire input has **no effect** on the pea shooter, which keeps auto-firing per T003.
  - **A single placeholder typed-weapon family** is sufficient. Treat it as the data-driven shape that M4 will fill out with 3–4 families; do not pre-build the full roster. The family must define at minimum: `family_id`, `max_energy`, `firing_cost` per shot, `fire_interval` (or projectile cadence), `projectile_speed`, `projectile_damage` (stored even if unused), and a sprite reference. A `Resource` (`.tres`) is the natural fit; a plain script with `@export` constants is also acceptable.
  - **Per-shot firing cost is a per-family property** (2026-05-16). Implementation must read it from the family definition, not from a global constant. The placeholder family must set its cost to a value high enough that the energy pool visibly depletes within a few seconds of held fire (so the expiry transition is exercisable in playtest).
  - **Expiry transition:** when `current_energy` reaches 0 (or would go negative on a shot), the typed weapon is removed from the slot, the player visibly stops emitting typed-weapon projectiles, and the pea shooter continues firing uninterrupted. Re-equipping the typed weapon is out of scope (pickups arrive in M4); for this task, a debug seed at scene start is enough to enter the equipped state.
  - **Debug bootstrap:** since pickups do not exist yet, the player starts the scene with the placeholder typed weapon equipped at full energy. This is throwaway scaffolding that T009 (weapon-chip carrier + drop spawn) replaces. Mark the bootstrap location clearly in code (a single function or `@export` toggle on the player) so it is trivial to delete later.
  - **Typed-weapon projectile sprite** — a PNG pixel-art sprite under `assets/sprites/projectiles/`, distinct from the pea bullet so the two streams are visually separable on screen during playtest. Same generation approach as T002/T003 (a `tools/generate_*_sprite.gd` script or hand-authored equivalent). Update `assets/README.md`.
  - Headless smoke (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- **Out of scope:**
  - **HUD / on-screen energy meter.** That is explicitly T005. This task may print energy values to the console / event log for verification, but no in-game UI.
  - **Hit-drain channel.** The energy pool is *defined* as dual-role here, but the enemy-fire-absorption side cannot be exercised until enemies exist (M3) and collision exists (M6). Do not stub fake enemy fire to test it.
  - **Multiple weapon families, same-family refill, different-family swap-at-full.** Those land in M4 (T010, T011). A single placeholder family is sufficient and intentional — over-building the family system before pickups exist risks specifying out-of-date work.
  - **Weapon levels.** Removed by the 2026-05-19 decision. Do not add `level` fields, level-up logic, or level-bumping behavior even as scaffolding.
  - **Rarity tiers, faction gating, reverse-engineered drops.** All M4+ or beyond.
  - **Pickups, carriers, fuel cells.** M4 and M5.
  - **Enemies, collision, Defense Grid.** M3 and M6.
  - **Sound effects, muzzle flashes, screen shake.**

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T003 completed and its evidence reviewed; pea shooter still auto-fires with no player input.
- [x] Re-read the 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" entry — this task's load-bearing invariant.
- [x] Re-read the 2026-05-16 "Per-weapon-family firing cost" entry — the family data model must expose `firing_cost` as a per-family knob, not a constant.
- [x] Re-read the 2026-05-19 "Remove weapon levels" and "Same-family pickup refills energy; different-family swaps at full" entries. **The older 2026-05-14 entries ("Typed weapons are temporary energy states", "Typed weapon max level is 3") still mention levels but are explicitly amended.** Do not implement levels.
- [x] Confirm `docs/PLAN.md` M2 and `design/scope.md` v1 in-scope list — single typed-weapon slot, dual-role meter, no HUD this task.

## Implementation notes

- Suggested layout (refine as needed during implementation):
  - `src/weapons/typed_weapon_family.gd` — a `Resource` class describing one family (`family_id`, `max_energy`, `firing_cost`, `fire_interval`, `projectile_speed`, `projectile_damage`, `projectile_sprite`). Stored as `.tres` instances under `data/weapons/` (or similar) so the placeholder can be authored as data, not code.
  - `src/weapons/typed_weapon.gd` (or merged into a slot script on the player) — runtime state for the currently equipped family: holds the family resource and `current_energy`. Exposes `try_fire()` → bool (deducts cost, returns whether a shot was emitted) and `is_expired()` → bool.
  - `src/player/typed_weapon_slot.gd` — child node of the player. Reads player fire input, calls `typed_weapon.try_fire()` on input + fire-interval cadence, spawns projectiles, and clears the slot on expiry.
  - `src/weapons/typed_projectile.gd` + `scenes/projectiles/TypedProjectile.tscn` — analogous to the pea bullet but with the typed family's sprite and speed. Reuse the upward-movement / off-screen despawn pattern from `pea_bullet.gd`.
- The energy meter is just two numbers (`max_energy`, `current_energy`) on the equipped `typed_weapon` instance. Keep it that simple — no separate `EnergyMeter` god-object. The HUD in T005 will read these values via a signal or a getter.
- Fire input: use the existing project input map (whatever was set up in bootstrap). If a fire action is not yet bound, add one (e.g., `fire_typed` mapped to space / left mouse / gamepad south). Document the binding in the input checklist.
- Fire cadence: respect the family's `fire_interval` — held fire input should *not* drain energy at frame rate; it should drain at the family's tunable cadence. This is the same shape as the pea shooter's interval timer.
- Expiry: when `try_fire()` cannot afford the cost, the slot drops the weapon (sets to null / empty) and emits a signal (e.g., `typed_weapon_expired(family_id)`) for the event log and future HUD. The pea shooter continues to fire uninterrupted across this transition — that is a key playtest signal and must be observable in the evidence video.
- Debug bootstrap: the cleanest version is an `@export var debug_starting_family: TypedWeaponFamily` on the player; if non-null, the slot equips it at `current_energy = family.max_energy` on `_ready()`. Easy to remove in T009 by clearing the export.
- Tune the placeholder family so a playtester can:
  1. Hold fire and see the typed weapon stream consume the pool over a few seconds.
  2. Observe expiry: typed-weapon stream stops, pea-shooter stream continues.
  3. Tap fire and observe slower drain.
  - Suggested starting values (refine in play): `max_energy = 100`, `firing_cost = 5`, `fire_interval = 0.10s` → ~2s of held fire to drain. These are tuning starting points, not commitments — the point is to make the expiry transition reachable in a short evidence clip.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/dual-stream.png` — screenshot showing both projectile streams active simultaneously: pea bullets and typed-weapon projectiles, visibly distinct sprites.
- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/expiry-sequence.mp4` (or a short series of stills if video tooling is not yet set up) — capture of held fire draining the meter to 0, the typed-weapon stream stopping, and the pea-shooter stream continuing uninterrupted. The video may include console output of energy values for legibility since no HUD exists yet.
- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/headless-smoke.txt` — rerun of headless smoke; must still show `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/energy-drain-verification.txt` — output of a headless verification script (`tests/evidence/T004-typed-weapon-slot-and-energy-meter/verify_typed_weapon.gd` or similar) that:
  - Equips the placeholder family at full energy.
  - Simulates held fire for a fixed duration.
  - Logs the energy value at fixed intervals.
  - Confirms the weapon expires at 0 and that further fire input emits no typed-weapon projectiles while the pea shooter continues.
  - Ends with a recognizable `TYPED_WEAPON_VERIFICATION_OK` line.
- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/input-checklist.md` — manual checklist confirming: pea shooter is unaffected by fire input (still continuously firing whether typed weapon is held, fired, or expired); typed weapon only fires when the equipped slot has energy; expiry transitions are observable.
- `tests/evidence/T004-typed-weapon-slot-and-energy-meter/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] The player starts the scene with the placeholder typed weapon equipped at full energy (debug bootstrap is in code, marked, easy to remove).
- [ ] Holding the fire input emits typed-weapon projectiles at the family's `fire_interval` cadence and drains `current_energy` by `firing_cost` per shot.
- [ ] When `current_energy` reaches 0, the typed weapon expires: the typed-weapon stream stops, the slot is empty, and the pea shooter continues firing without any interruption.
- [ ] Fire input has no effect on the pea shooter at any point — engaging the typed weapon does not stop, slow, or speed up the pea shooter, and the typed weapon expiring does not change pea-shooter behavior.
- [ ] `firing_cost`, `max_energy`, `fire_interval`, `projectile_speed`, and the projectile sprite are defined on a per-family resource/data object, not as constants inside the slot or projectile script. (Per the 2026-05-16 per-family-cost decision.)
- [ ] The energy pool is implemented as a single `current_energy` field on the equipped family instance, ready to be drained by enemy fire as well in M3/M6. No separate "shield" pool or "ammo" pool was introduced.
- [ ] No weapon-level concept exists in code (`level` fields, `level_up()`, level-based scaling). Per the 2026-05-19 level-removal decision.
- [ ] The typed-weapon projectile uses a PNG pixel-art sprite from `assets/sprites/projectiles/`, distinct from the pea bullet. `assets/README.md` is updated.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] No HUD / on-screen energy meter was introduced (that is T005).
- [ ] No enemies, no collision, no pickups, no carriers were introduced.

**Rerun command:**

```bash
tools/run_headless_smoke.sh > tests/evidence/T004-typed-weapon-slot-and-energy-meter/headless-smoke.txt
tools/godot/bin/godot --headless --path . --script tests/evidence/T004-typed-weapon-slot-and-energy-meter/verify_typed_weapon.gd > tests/evidence/T004-typed-weapon-slot-and-energy-meter/energy-drain-verification.txt
git status > tests/evidence/T004-typed-weapon-slot-and-energy-meter/git-status.txt
```

Manual screenshot/video/input evidence is produced by running the Godot project interactively and capturing the dual-stream view, the expiry transition, and the input checklist.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-19 | Created and activated. Pre-flight confirmed T003 evidence accepted; the 2026-05-16 dual-role and per-family-cost decisions and the 2026-05-19 level-removal decision are the governing invariants. The older 2026-05-14 typed-weapon entries are explicitly amended (no levels) and flagged in pre-flight so they are not accidentally re-introduced. |
| 2026-05-20 | Implemented the debug typed-weapon slot, `TypedWeaponFamily` data resource, single runtime energy pool, placeholder typed projectile, and `fire_typed` input binding. The player debug-starts with `debug_plasma` at full energy; held fire drains by the family's per-shot cost and expiry clears the slot while the pea shooter continues. |
| 2026-05-20 | Generated T004 evidence: dual-stream screenshot, three-frame expiry sequence, headless smoke, energy-drain verification, input checklist, and git status. Ready for human review. |
| 2026-05-20 | Human-approved; moved to completed. |

## Blocker

None.
