# T009 — Weapon-Chip Carrier + Drop Spawn

| Field | Value |
|---|---|
| ID | T009 |
| State | completed |
| Phase | M4 — Weapon pickups |
| Depends on | T008 |
| Plan reference | `docs/PLAN.md` — M4 |

## Goal

Introduce the **weapon-chip carrier** — a fragile auxiliary ship that sweeps across the playfield from one side, and on death drops a **weapon-chip pickup** that drifts down toward the planet with a large sweeping sway. Collecting the chip equips the typed weapon (or refills it). This task replaces the T004 debug-bootstrap "you start with `debug_plasma` already equipped" with the real carrier → chip → equip loop. M4's weapon-family roster (T010) and the same-family/different-family pickup semantics (T011) are out of scope here — the chip in T009 is intentionally generic: it always grants/refills the single existing `debug_plasma` family.

## Scope

- **In scope:**
  - **Weapon-chip carrier enemy.** A new `scenes/enemies/WeaponChipCarrier.tscn` + `src/enemies/weapon_chip_carrier.gd`. Visually distinct silhouette from `BaselineEnemy` — a recognizably different sprite under `assets/sprites/enemies/` (e.g., a stubbier hull with a chip/cargo motif, accent palette). Per `docs/PLAN.md` "Visual assets for v1," this is a hand-authored placeholder PNG at the same quality bar as the baseline enemy sprite (no programmer-art rectangles). Carrier takes damage via the same `TypedProjectile`/`PeaBullet` hit path baseline enemies already use.
  - **Carrier is a fragile glass cannon.** `@export var max_hp := 2.0` (designed to die in ~2 pea-shooter hits or 1 typed-weapon hit at current T007 damage tuning — confirm against actual T007 `pea_damage` and `typed_damage` and pick the integer HP that lands ~2 pea / 1 typed; document the chosen number in the Progress log if T007's damage values mean a different integer fits the brief better). Carrier death plays the existing T007 kill pixel-burst (with the existing palette is fine — same "enemy died" semantic).
  - **Carrier spawn cadence.** A new `src/carriers/carrier_spawner.gd` (`Node2D`, registered under `Main.tscn` alongside the existing `EnemySpawner`) emits **one lone carrier on a timer**. Default `@export var spawn_interval_seconds := 8.0` — a tuning starting point chosen so a carrier appears at least once per typical energy-meter cycle but not so often that pea-shooter time is rare. Spawner picks the entry side (`left` or `right`) per spawn, alternating or randomly — implementer's call; document which in the Progress log. Spawn position is just **off-screen on the chosen side** at a y in the upper-middle band (e.g., `y` somewhere in `[200, 500]`), randomized per spawn.
  - **Carrier sweeping movement.** The carrier moves **horizontally across the playfield** from its entry side to the opposite side at `@export var sweep_speed := 110.0` px/s with a gentle vertical sine sway (`@export var sway_amplitude := 24.0`, `@export var sway_period := 1.8`) so the trajectory is non-trivial to track. The carrier does **not** descend into the planet line and does **not** debit the Defense Grid if it exits the opposite side uncaught — it is auxiliary, not part of the descending armada's leak threat. When the carrier's bounding box clears the opposite side of the playfield, it `queue_free()`s silently (no chip spawn, no debit — it's a missed opportunity).
  - **Chip pickup on carrier death.** When the carrier's HP reaches 0 (kill path, not exit path), spawn a `scenes/pickups/WeaponChip.tscn` + `src/pickups/weapon_chip.gd` at the carrier's `global_position` and `queue_free()` the carrier. The chip is a new placeholder sprite under `assets/sprites/pickups/` — visually distinct from the carrier, suggesting "captured tech / cargo": small, glowing, clearly an item not a ship. Sprite-quality bar matches the carrier and baseline enemy.
  - **Chip drift behavior.** The chip drifts downward at `@export var drift_speed := 60.0` px/s (slower than the armada — gives the player a real window to chase it) with a **large** horizontal sweeping sway: `@export var sway_amplitude := 90.0` px, `@export var sway_period := 1.6` s. The sway is the load-bearing part of the user's "make it somewhat challenging to catch" direction — the chip's x oscillates wide enough that the player must commit to tracking it. The chip's sway is independent of the carrier's prior sway phase. If the chip's `global_position.y` crosses the **same planet line** baseline enemies use (`900.0` per T008's tuning), the chip `queue_free()`s **silently**: no Grid damage, no kill burst, no event. It is an expired pickup, not a leaked enemy.
  - **Chip collection.** The chip has a small collision shape (an `Area2D` with a `CircleShape2D` radius ~16–22 px). When the chip's area overlaps the player ship (the same player node baseline-enemy leak detection already implicitly references), the chip:
    1. Calls a new `TypedWeaponSlot.apply_chip_pickup()` method (see below).
    2. Spawns a small **pickup feedback burst** at the chip's `global_position` (reuse `PixelBurst.tscn` with a warm/yellow palette argument if it supports palette tinting, OR introduce a tiny `scenes/vfx/PickupBurst.tscn` mirroring `PixelBurst`'s structure with a yellow/cyan palette — implementer's call, same path the T008 planet-impact burst followed; default to the new-scene path if `PixelBurst` does not already accept palettes). Distinct from both the kill burst (T007) and the planet-impact burst (T008).
    3. `queue_free()`s itself.
  - **`TypedWeaponSlot.apply_chip_pickup()` method.** New public method on `src/player/typed_weapon_slot.gd`. Behavior in T009:
    - If `active_weapon == null` (player is in pea-shooter-only state), `equip(debug_plasma_family)` — a single exported `@export var default_pickup_family: TypedWeaponFamily` resource reference on the slot, assigned in the editor to `debug_plasma`. This is the v1-only stand-in for "the chip rolls a random family"; T010 reshapes this method to draw from a family pool.
    - If `active_weapon != null`, refill `active_weapon.current_energy` to `active_weapon.max_energy` and emit `typed_weapon_energy_changed`.
    - Emit a new signal `chip_pickup_applied(family_id: String, granted_new_family: bool)` on the slot, so HUD/event-log subscribers can react in T010/T011 without rewiring.
  - **Remove the T004 debug bootstrap.** Delete the `_equip_debug_starting_family()` call from `src/player/player_ship.gd` (and its `@export var debug_starting_family` if no other code path still uses it — grep first; if it's referenced elsewhere, leave the export and just stop calling the function at boot). At run start, the player has **no typed weapon**: pea shooter only. The first carrier kill that yields a successfully-caught chip is what equips `debug_plasma` for the first time. This is the load-bearing scope-change of T009 — it shifts the typed-weapon meter from "free at boot" to "earned through the carrier loop," which is the loop the entire prototype exists to test.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. The carrier spawner, carrier, chip, and pickup feedback scenes must import and instantiate cleanly headless.
- **Out of scope:**
  - **The 3–4 common-tier weapon families.** Per `tasks/INDEX.md`, that is T010. T009 ships with the single existing `debug_plasma` family only.
  - **Same-family refill / different-family swap-at-full semantics.** Per `tasks/INDEX.md`, that is T011. In T009 the chip is generic (always grants `debug_plasma` if empty, always refills if equipped), so the "different family" branch literally cannot occur.
  - **Fuel-cell carriers.** Per `docs/PLAN.md`, that is M5 / T012.
  - **Defense Grid repair carriers.** Per `docs/design/scope.md`, deferred out of v1 entirely.
  - **Elite enemy variants.** Per `docs/PLAN.md`, M6 / T014.
  - **Chip-drop variation per carrier or per enemy.** Only the carrier drops chips; baseline enemies still drop nothing.
  - **Magnetism / auto-attract on the chip.** User direction is "make it somewhat challenging for the player to catch." Magnetism contradicts that.
  - **Per-faction visual identity, hull theming.** Single placeholder carrier sprite — v1 has one faction, no themed roster yet.
  - **Carrier shooting back at the player.** No enemy-fire system in v1.
  - **Audio, screen shake, HUD changes.** Pickup feedback is visual-only; the existing EnergyMeter HUD already reacts to `typed_weapon_energy_changed`, which is the only HUD coupling needed.
  - **Reverse-engineered cross-run drop pool.** Per `docs/design/scope.md`, no cross-run state in v1.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

| Date | Change |
|---|---|
| 2026-05-21 | User-approved tuning update after T009 review: regular baseline alien HP is reduced by half, from `5.0` to `2.5`. Carrier HP remains `2.0` because the user said the task itself looks good and the carrier was already tuned for ~2 pea hits / 1 typed hit. |
| 2026-05-21 | User-approved tuning update after T009 review: typed weapon uptime is too short. Keep `debug_plasma.max_energy` at `100.0`, but reduce firing cost by 1/5 from `5.0` to `1.0`, giving roughly 5x as many shots per full meter without changing the HUD scale. |

## Pre-flight

- [x] T008 accepted; baseline enemies, kill bursts, planet-impact bursts, Defense Grid meter, leak path, and run-end + restart all working. The carrier and chip slot into the existing scene graph next to those systems without modifying them.
- [x] Re-read 2026-05-13 "In-stage pickup categories" — weapon pickups are confirmed as a v1 pickup channel.
- [x] Re-read 2026-05-14 "Authored drop carriers and dynamic weapon sustain" — weapon chips come from authored carriers, not random enemy drops. This task introduces the carrier channel.
- [x] Re-read 2026-05-16 "Pickup sources split: enemy carriers drop weapons, coalition supply drops fuel" — weapon-chip carriers are enemy ships in the armada and are a leak risk if not engaged. **Note on the cross-side sweep movement:** the user's chosen carrier trajectory (sweep across from one side) means the carrier itself does not threaten the planet line — there is no leak risk if it exits the opposite side uncaught. This is an intentional v1 simplification: the leak-risk fiction will be reintroduced when in-armada carrier placement returns in later work, but for this slice the carrier is a horizontal sweeper. Flag and accept the divergence; do not treat the missed carrier as a Grid debit.
- [x] Re-read 2026-05-18 "Faction content unit clarification" — weapon-chip carriers are faction content. v1 has one faction and no faction-themed visual styling, so the carrier ships as a single placeholder hull and absorbs no faction theming work yet.
- [x] Re-read 2026-05-19 "Remove weapon levels" and "Same-family pickup refills energy; different-family swaps at full" — the v1 pickup model is refill-to-full / swap-at-full, no levels. T009 only exercises the refill path (and the initial equip path); the swap path is T011.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — placeholder pixel-art sprites for carrier and chip, not procedural geometry. Recognizable silhouette is required; programmer-rectangle is not acceptable for the carrier or chip.
- [x] Confirm the T004 debug bootstrap (`_equip_debug_starting_family`) is removable — its in-code comment already names T009 as its replacement. Grep for any other call sites before deleting; the export field may stay if the editor `Main.tscn` still references it, but the call at boot must be removed.

## Implementation notes

- **Sprite authoring.**
  - `assets/sprites/enemies/weapon_chip_carrier.png` — ~48×48 or ~64×48 px. Suggested visual language: a wider hull than the baseline enemy with a visible cargo/chip cluster on top, accent color in the warm range (orange/yellow) to telegraph "this drops something good." Must read as a ship and as visibly auxiliary, not as a beefier baseline.
  - `assets/sprites/pickups/weapon_chip.png` — ~16×16 or ~20×20 px. Suggested visual language: a small glowing chip or capsule, primary glow color matching the carrier's accent so the linkage is obvious at a glance. Distinct from any projectile sprite (chips are catchable; projectiles are dangerous). Note provenance in `assets/README.md` if any third-party reference is used; otherwise mark as agent-authored.
- **WeaponChipCarrier node.** `Area2D` (so it can detect player projectiles and dispatch hits via the same path baseline enemies use) or `Node2D` matching whatever `BaselineEnemy` is — mirror `BaselineEnemy`'s structure exactly to keep the projectile hit path uniform. Owns:
  - `@export var max_hp := 2.0`, `@export var sweep_speed := 110.0`, `@export var sway_amplitude := 24.0`, `@export var sway_period := 1.8`, `@export var chip_scene: PackedScene`, `@export var direction := 1.0` (set by spawner: `+1` for left-to-right, `-1` for right-to-left).
  - In `_physics_process`, advance `position.x += direction * sweep_speed * delta`, apply sine sway to `position.y` against an anchor y stored at spawn.
  - On HP ≤ 0 (kill path): instantiate `chip_scene` at `global_position`, spawn the existing kill pixel-burst, emit a `carrier_killed(global_position)` signal, `queue_free()`.
  - On crossing the opposite playfield edge (use the spawner's `playfield_width` ± a small margin): `queue_free()` silently. No chip, no burst, no debit.
- **CarrierSpawner node.** New `src/carriers/carrier_spawner.gd` (`Node2D`). Owns:
  - `@export var carrier_scene: PackedScene`, `@export var spawn_interval_seconds := 8.0`, `@export var spawn_y_min := 200.0`, `@export var spawn_y_max := 500.0`, `@export var playfield_width := 540.0`, `@export var off_screen_margin := 48.0`.
  - Mirrors `EnemySpawner`'s simple timer pattern (`_time_until_next_spawn`, decrement in `_physics_process`, spawn at zero, reset). First spawn fires after one full interval, not at t=0 — this gives the player a brief pea-shooter-only window at run start that lets them feel the unequipped state before the first chip.
  - On spawn: pick a side (alternate is simplest, document the choice in the Progress log), set carrier `direction`, `position.x = (-off_screen_margin)` for left or `(playfield_width + off_screen_margin)` for right, `position.y = randf_range(spawn_y_min, spawn_y_max)`, `add_child(carrier)`.
- **WeaponChip node.** `Area2D` with a `CircleShape2D` collision shape and a `Sprite2D` child. Script `src/pickups/weapon_chip.gd`:
  - `@export var drift_speed := 60.0`, `@export var sway_amplitude := 90.0`, `@export var sway_period := 1.6`, `@export var planet_line_y := 900.0`, `@export var pickup_burst_scene: PackedScene`.
  - In `_physics_process`, advance y at `drift_speed`, apply sine sway to x against the chip's spawn-time anchor x. Clamp the swayed x to the playfield (`[half_width, playfield_width - half_width]`) so the chip doesn't visually leave the playfield mid-arc.
  - On `body_entered` or `area_entered` against the player: resolve the player's `TypedWeaponSlot` (climb up to `PlayerShip` then `get_node("TypedWeaponSlot")` — mirror how `HUD` resolves it), call `apply_chip_pickup()`, spawn pickup burst, `queue_free()`.
  - On `global_position.y >= planet_line_y`: `queue_free()` silently — no debit, no burst, no event log entry. Print one line to the in-engine event log (per T007's event-log pattern) like `chip_expired_at_planet_line position=...` for evidence purposes only.
- **TypedWeaponSlot.apply_chip_pickup().** Add to `src/player/typed_weapon_slot.gd`:

  ```gdscript
  func apply_chip_pickup() -> void:
      if active_weapon == null:
          if default_pickup_family == null:
              push_warning("TypedWeaponSlot has no default_pickup_family configured.")
              return
          equip(default_pickup_family)
          chip_pickup_applied.emit(default_pickup_family.family_id, true)
          return

      active_weapon.current_energy = active_weapon.max_energy
      typed_weapon_energy_changed.emit(active_weapon.current_energy, active_weapon.max_energy)
      chip_pickup_applied.emit(active_weapon.family.family_id, false)
  ```

  Add the `@export var default_pickup_family: TypedWeaponFamily` and `signal chip_pickup_applied(family_id: String, granted_new_family: bool)` at the top of the script alongside the existing exports/signals. Wire the export to the `debug_plasma` family resource in `Main.tscn`'s TypedWeaponSlot inspector.
- **Boot state change.** In `src/player/player_ship.gd`, remove the `_equip_debug_starting_family()` call from `_ready()`. If no other code references the function, delete the function and the `debug_starting_family` export. If the editor scene still references the export, leave the export but make `_ready()` not call equip — the field becomes a no-op held against possible debug toggle. Confirm with `git grep debug_starting_family` after editing.
- **Pickup feedback burst.** Default to a new `scenes/vfx/PickupBurst.tscn` + `src/vfx/pickup_burst.gd` mirroring `PixelBurst`'s structure with a warm palette (yellow/orange + white), 6–10 fragments, ~0.20s lifetime. Distinct from kill burst (T007 enemy palette) and planet-impact burst (T008 cool/blue palette). If `PixelBurst` already accepts a palette argument, the reuse path is acceptable and shorter.
- **Carrier in the headless verify pass.** Reuse the headless evidence pattern from T008. Add a `tests/evidence/T009-.../verify_carrier.gd` script that:
  1. Instantiates a `WeaponChipCarrier`, sets `max_hp := 2.0`, asserts initial HP and that calling its damage method twice produces a death event and emits `carrier_killed` exactly once.
  2. Instantiates a `WeaponChip`, calls `_physics_process` synthetically until y crosses `planet_line_y`, asserts the chip is queued for deletion and no Grid debit was sent.
  3. Instantiates a `TypedWeaponSlot` with `default_pickup_family := debug_plasma`, with `active_weapon == null`, calls `apply_chip_pickup()`, asserts `active_weapon != null` and `chip_pickup_applied(granted_new_family=true)` fired.
  4. Calls `apply_chip_pickup()` again, asserts energy is at max and `chip_pickup_applied(granted_new_family=false)` fired.
  5. Prints `CARRIER_VERIFICATION_OK` and exits 0.
- **What not to touch in this slice.** EnergyMeter HUD layout (T005/T008), GridMeter HUD (T008), DefenseGrid leak path (T008), baseline enemy descent/HP/kill burst (T006/T007), formation spawner descent_speed (already tuned to 32.5), typed-weapon firing cost or projectile behavior (T004), pea shooter (T003).

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/boot-no-weapon.png` — frame at run start: player ship visible, EnergyMeter reads `0 / 0` (or whatever the "no weapon" state renders as in the current HUD), no typed-weapon projectiles in flight, baseline armada descending normally.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/carrier-sweep.mp4` (or short still series) — clip showing a carrier entering from one side, sweeping across the playfield with vertical sway, and exiting the opposite side uncaught. Confirm in caption: no Grid damage, no chip spawn on exit.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/carrier-kill-drops-chip.mp4` (or stills) — clip showing the player killing a carrier mid-sweep, the kill pixel-burst playing, and a chip pickup spawning at the carrier's death position.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/chip-sweep-and-collect.mp4` (or stills) — clip showing the chip drifting downward with a wide horizontal sway, the player intercepting it, and the pickup feedback burst playing. EnergyMeter visibly fills to max immediately after collection.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/chip-expires-at-planet-line.png` (or stills) — sequence showing a chip drifting all the way to the planet line uncaught. GridMeter is unchanged before and after; chip silently disappears.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/three-bursts-distinct.md` — short note with cropped frames confirming the T007 kill burst, the T008 planet-impact burst, and the new T009 pickup feedback burst are visually distinct at a glance.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/equip-from-empty.md` — note confirming that starting in the no-weapon state, the first successfully-caught chip equips `debug_plasma` at full energy, and the typed-weapon fire input begins working from that moment.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/refill-while-equipped.md` — note confirming a second successfully-caught chip while equipped refills the EnergyMeter to max without changing the active family.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/carrier-verification.txt` — output of the headless verification script ending in `CARRIER_VERIFICATION_OK`.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/headless-smoke.txt` — rerun of headless smoke; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/carrier-checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] At run start, the player has **no typed weapon equipped**. EnergyMeter reflects the empty state. The fire-typed input produces no projectiles.
- [ ] Weapon-chip carriers spawn on a timer (~every 8 seconds by default) and enter from off-screen on one side. The carrier sprite is visually distinct from baseline enemies and reads as auxiliary cargo, not as a beefier baseline.
- [ ] Carriers sweep horizontally across the playfield with a gentle vertical sway, exit the opposite side if uncaught, and **do not damage the Defense Grid** in any case.
- [ ] Carriers die in ~2 pea-shooter hits or 1 typed-weapon hit (or the documented equivalent), spawning a chip pickup at the death position and playing the existing kill pixel-burst.
- [ ] The dropped chip drifts downward at a moderate speed with a **large** horizontal sweeping sway that makes interception feel deliberate, not automatic.
- [ ] If the chip reaches the planet line uncaught, it disappears silently. **GridMeter is unchanged.** No burst, no overlay.
- [ ] Intercepting a chip plays the new pickup feedback burst at the chip's position. That burst is visibly distinct from both the T007 enemy-kill burst and the T008 planet-impact burst.
- [ ] First successful chip catch equips `debug_plasma` at full energy. The typed-weapon fire input begins working at that moment.
- [ ] Subsequent chip catches while equipped refill the EnergyMeter to max and do not change the active weapon family (because T009 only has one family).
- [ ] No changes to baseline enemy behavior, formation descent, GridMeter behavior, EnergyMeter HUD layout, pea-shooter behavior, projectile damage values, or run-end overlay.
- [ ] No enemy-fire system, no collision response on the player ship, no fuel-cell carriers, no repair carriers, no audio, no screen shake, no HUD additions were introduced.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_carrier.gd` output ends in `CARRIER_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/verify_carrier.gd > tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/carrier-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/capture_live_carrier_evidence.gd > tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/live-capture.txt
git status > tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/git-status.txt
```

Visual evidence (`boot-no-weapon.png`, `carrier-sweep.mp4`, `carrier-kill-drops-chip.mp4`, `chip-sweep-and-collect.mp4`, `chip-expires-at-planet-line.png`) is produced from the live `Main.tscn` scene tree by `capture_live_carrier_evidence.gd`, mirroring the T006/T007/T008 capture approach.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-20 | Created and activated. Pre-flight clarified with user: carrier is a **fragile glass cannon** (~2 pea / 1 typed hit) that spawns as a **lone carrier on a timer** and **sweeps from one side to the other** of the playfield (not part of the descending armada). On kill, it drops a **generic chip** (no family choice yet — always grants/refills `debug_plasma`, the single existing family) that **drifts down with a large sweeping sway** to make interception deliberate. Chip expiring at the planet line is silent; carrier exiting the opposite side uncaught is silent. T004 debug-bootstrap equip is removed — player starts in pea-shooter-only state. |
| 2026-05-21 | Implemented the T009 carrier loop. Added `WeaponChipCarrier`, `CarrierSpawner`, `WeaponChip`, and a distinct `PickupBurst`; authored placeholder PNG sprites for the carrier and chip; added `TypedWeaponSlot.apply_chip_pickup()` and removed the player debug starting equip. Carrier spawn side alternates left/right. Carrier HP is `2.0`, matching two pea hits (`1.0` each) or one debug plasma hit (`3.0`). Generated evidence under `tests/evidence/T009-weapon-chip-carrier-and-drop-spawn/`; `carrier-verification.txt` ends in `CARRIER_VERIFICATION_OK`, and `headless-smoke.txt` prints `LAST_HORIZON_BOOT_SMOKE_OK`. |
| 2026-05-21 | Applied the requested tuning update: baseline alien `max_hp` is now `2.5` (half of the prior `5.0`). Updated the T007 damage verifier expectations so current verification reflects the new HP: pea hit `2.5 -> 1.5`, debug plasma hit kills `2.5 -> 0.0`. |
| 2026-05-21 | Applied the requested typed-weapon uptime tuning update: `debug_plasma.max_energy` remains `100.0`, while `firing_cost` is now `1.0` instead of `5.0`. This preserves the meter scale but increases full-meter shot budget from ~20 shots to ~100 shots. |
| 2026-05-21 | Refreshed tuning evidence. `typed-weapon-cost-tuning-verification.txt` ends in `TYPED_WEAPON_VERIFICATION_OK`, `hud-cost-tuning-verification.txt` ends in `HUD_BINDING_VERIFICATION_OK`, `carrier-verification.txt` ends in `CARRIER_VERIFICATION_OK`, and `headless-smoke.txt` prints `LAST_HORIZON_BOOT_SMOKE_OK`. |
| 2026-05-21 | User approved T009. Moving task to `completed/` and committing the completed task bundle. |

## Blocker

None.
