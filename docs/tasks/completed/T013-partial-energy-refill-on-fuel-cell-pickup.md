# T013 — Partial Energy Refill on Fuel-Cell Pickup

| Field | Value |
|---|---|
| ID | T013 |
| State | completed |
| Phase | M5 — Fuel cells |
| Depends on | T012 |
| Plan reference | `docs/PLAN.md` — M5 |

## Goal

Wire the T012 fuel-cell carrier's collection beat into the actual energy economy: a successful fuel-cell pickup restores **30% of the held typed weapon's `max_energy`** (capped at `max_energy`), without changing the equipped family. T013 also closes the load-bearing M5 invariant the design log set in 2026-05-16 ("engagement is purely opportunity cost") by **gating fuel-cell spawning on whether a typed weapon is currently equipped** — no weapon, no fuel cells. With this slice, M5 is functionally complete: weapon-chip carriers (full refill / swap) and fuel-cell carriers (partial sip) are visibly distinct in both behavior and HUD treatment, and the player has a real reason to choose between them.

## Scope

- **In scope:**
  - **New `TypedWeaponSlot.apply_fuel_cell_pickup()` method.** Restores `min(current_energy + fuel_cell_refill_fraction * max_energy, max_energy)` to the active weapon's `current_energy`. Does **not** change the equipped family, does **not** reset `_time_until_next_shot`, does **not** re-instantiate the `TypedWeapon`. Emits `typed_weapon_energy_changed(current_energy, max_energy)` and a new `typed_weapon_partial_refilled(family_id: String, amount_restored: float)` signal — in that order, so the HUD bar reads the new value before the flash fires. If the slot has no weapon when called, the method is a no-op and emits nothing (this path should not be reachable in normal play given the spawner gating below; the no-op is defensive only).
  - **`fuel_cell_refill_fraction := 0.30` exported on `TypedWeaponSlot`.** Lives on the slot, not on each `TypedWeaponFamily` resource — fuel cells are faction-agnostic and the design intent is a single coalition refill amount that scales per-family by `max_energy`. M7 (tuning consolidation) is the natural place to move this to a central tuning surface if needed.
  - **New `typed_weapon_partial_refilled(family_id: String, amount_restored: float)` signal on `TypedWeaponSlot`.** Fires only from the fuel-cell path. The `amount_restored` argument is the **actual** energy delta after the cap, so a fuel cell caught with a near-full meter reports a smaller number than a fuel cell caught with a near-empty meter. T013 does not consume the amount value for any logic, but the payload exists for the future event log / playtest telemetry T018 will add.
  - **`FuelCellCarrier._try_collect_from` calls `slot.apply_fuel_cell_pickup()` on the resolved slot.** The existing `fuel_cell_collected(spawn_position)` signal still fires (telemetry), but the actual energy change is owned by the slot, not the carrier. The carrier also gates collection: if the resolved slot reports `has_weapon() == false`, the carrier does **not** consume itself — it continues flying. This is the "carrier in-flight when weapon expires stays in-flight, uncollectible" behavior the user committed to. The player can still catch it if they re-equip before it exits the bottom edge.
  - **`FuelCellCarrierSpawner` gates its timer on the typed-weapon slot.** The spawner resolves the same `TypedWeaponSlot` the HUD does (`find_child("TypedWeaponSlot", true, false)` against the current scene; fall back to the existing `typed_weapon_slot_path` export pattern if a path is wired). Each `_physics_process`:
    - If `slot == null` or `slot.has_weapon() == false`: do **not** decrement `_time_until_next_spawn`. Hold the timer at its current value (no countdown while the slot is empty).
    - On the **transition** from `has_weapon() == false` to `has_weapon() == true` (player just equipped after being empty, OR first equip from the run's opening state): **reset `_time_until_next_spawn` to `spawn_interval_seconds`** — the full ~30 s clock restarts on every equip. This implements the user's choice: a player who picks up their first weapon late, or whose weapon expires and is re-equipped, gets a predictable ~30 s window before the next fuel cell, never an instant spawn.
    - With `has_weapon() == true` and no transition this tick: normal countdown / spawn flow per T012.
  - **New `EnergyMeter.flash_partial_refill()` method.** Distinct from the existing T011 `flash_refill()`: a **shorter** flash (start at `0.16` s vs. `0.25` s for the full-refill flash) using a **softer** accent — a muted cyan that reads as "sip" rather than "top-up". Concretely: introduce two constants `PARTIAL_REFILL_FLASH_FILL` (e.g. `Color(0.55, 0.92, 0.96, 1.0)`, between `ACTIVE_FILL` and `REFILL_FLASH_FILL` in brightness) and `PARTIAL_REFILL_FLASH_BORDER` (e.g. `Color(0.35, 0.84, 0.94, 1.0)`, brighter than `ACTIVE_BORDER` but dimmer than `REFILL_FLASH_BORDER`). Implementation mirrors `flash_refill`'s shape: override the stylebox, `await SceneTreeTimer.timeout`, guard `if !is_inside_tree(): return`, then `set_energy(_bar.value, _bar.max_value)` to restore the ratio-appropriate style. If a `flash_refill` is already in flight when a `flash_partial_refill` comes in (or vice versa), the most-recent flash wins; do not stack or queue. The 0.16 s figure is a starting point; the load-bearing constraint is that the partial flash is **clearly weaker** than the full-refill flash at gameplay framerate so the player learns the visual vocabulary.
  - **HUD wiring.** `src/ui/hud.gd` connects to the new `typed_weapon_partial_refilled` signal and forwards to `_energy_meter.flash_partial_refill()`. No layout changes, no new HUD nodes.
  - **No new pickup-burst variants.** The existing `pickup_burst` already fires on fuel-cell collect (T012) and stays as-is. The flash is HUD-only; the burst is the "the cell was caught" beat regardless of slot state at collection time.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0 with the new method, signal, gating logic, and flash variant all loading cleanly.
  - **Event log.** Existing T012 prints (`fuel_cell_carrier_spawned`, `fuel_cell_collected`, `fuel_cell_carrier_exited`) stay unchanged. Add one new print on the slot: `typed_weapon_partial_refilled family=<id> restored=<float> current=<float> max=<float>` so the captured event log shows the actual refill amount per pickup.

- **Out of scope:**
  - **Tuning iteration on the 30% figure.** The starting fraction is committed in the task; playtest-driven tuning of fuel-cell yield belongs to M7 (alongside the same-family chip refill and per-family burn rates).
  - **Per-family override of the refill fraction.** Single faction-agnostic value on the slot; M7 may revisit.
  - **A separate sound / VFX vocabulary for partial refill beyond the existing pickup_burst + the new softer HUD flash.** No audio system in v1.
  - **Rare / legendary tier fuel cells, faction-themed fuel cells.** Fuel cells are faction-agnostic (2026-05-19 faction split entry); rarity is a post-v1 concern.
  - **Carrier hover / loiter behavior** when the typed weapon is empty. The carrier keeps its existing T012 two-phase movement — ascent, then slow sway-descent, exit through the bottom. The only change is that touching the player ship while the slot is empty does **not** consume the carrier.
  - **Despawning in-flight carriers when the weapon expires mid-flight.** The user's call was "continue flying; uncollectible." Existing carriers keep flying; nothing special happens to them on `typed_weapon_expired`.
  - **HUD treatment for a fuel cell caught at full meter.** The flash still fires; the amount restored will be `0.0`. The bar visibly doesn't change, but the flash teaches "you caught one." Considered and rejected: suppressing the flash at-cap (would punish the player for engaging at the wrong moment with silence — worse readability).
  - **Discard / waste indicator for the gated case** (player touches a carrier while empty). The carrier passes harmlessly; no waste indicator needed because the spawner gating ensures this case is rare in practice. If playtest reveals it confuses players, T017 can address.
  - **EnergyMeter / GridMeter layout, color constants for non-flash states, GridMeter behavior, DefenseGrid leak path, BaselineEnemy behavior, EnemyFormation descent, EnemySpawner cadence, PeaShooter, CarrierSpawner (weapon-chip cadence stays 20.0 s), WeaponChipCarrier / WeaponChip behavior, the 5 family resources, projectile sprites, run-end overlay.** Not touched.
  - **Cross-run / meta progression hooks.** None.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

| Date | Change |
|---|---|
| 2026-05-22 | User requested the current fuel-cell appearance rate be doubled. The fuel-cell spawner baseline interval is now `15.0` seconds instead of `30.0`; all T013 spawn-gating and equip-edge reset semantics remain the same, but their full interval is now 15 seconds. This amends the original T012/T013 `~30 s` cadence language for the active prototype tuning pass. |

## Pre-flight

- [x] T012 accepted; the fuel-cell carrier exists, ascends from the bottom, descends with sway, exits cleanly, emits `fuel_cell_collected(spawn_position)` on contact during descent, and projectiles pass through harmlessly.
- [x] Re-read 2026-05-14 "Pickup categories" — confirm fuel cells "restore a small amount of typed-weapon energy/fuel without changing weapon type or level." T013 implements both halves: partial restore, no family change.
- [x] Re-read 2026-05-16 "Pickup sources split: enemy carriers drop weapons, coalition supply drops fuel" — confirm: ignored fuel-cell carriers do **not** damage the Defense Grid, engagement is pure opportunity cost. Spawner gating preserves this (and tightens it — fuel cells don't exist on screen at all when the player has no weapon to feed).
- [x] Re-read 2026-05-19 "Faction content vs. faction-agnostic carrier split" — confirm fuel-cell carriers are faction-agnostic, so the refill fraction lives on the slot (one value) and not per-family.
- [x] Re-read 2026-05-19 "Same-family pickup refills energy; different-family swaps at full" and the 2026-05-19 "Fuel-cell carriers continue to give *partial* energy refills" amendment — confirm: weapon chip on same family = **full** refill; fuel cell = **partial** refill. T011 implemented the chip side; T013 implements the fuel side. The two flashes (`flash_refill` and the new `flash_partial_refill`) are the visual vocabulary that separates them at a glance.
- [x] Re-read T011 (`same-family-refill-different-family-swap-at-full.md`) for the `flash_refill` / `EnergyMeter` signal grammar — confirm: `typed_weapon_refilled` is the same-family-only signal, fires after `typed_weapon_energy_changed`, HUD wires to `flash_refill()`. T013's `typed_weapon_partial_refilled` follows the same shape (emit-after-energy-change, HUD wires to a dedicated flash variant), but is a **new, distinct** signal so listeners can tell sip apart from top-up.
- [x] Re-read T012 (`coalition-fuel-cell-carrier-approach.md`) "Out of scope" note that explicitly defers the actual partial energy refill to T013 — confirm T013 is the agreed slice for it.
- [x] Grep for callers of `apply_chip_pickup` and consumers of `typed_weapon_refilled` to confirm the analogous `apply_fuel_cell_pickup` / `typed_weapon_partial_refilled` shape will not collide with existing names: `WeaponChip._try_collect_from`, `hud.gd._on_typed_weapon_refilled`, T011 verifier. None conflict.
- [x] Inspect `FuelCellCarrierSpawner` to confirm there is currently no slot resolution path — the spawner is standalone in T012 and will need to add one in T013 mirroring `hud.gd`'s `_resolve_typed_weapon_slot` pattern.

## Implementation notes

- **`TypedWeaponSlot` changes.**
  - Add `@export var fuel_cell_refill_fraction := 0.30`.
  - Add `signal typed_weapon_partial_refilled(family_id: String, amount_restored: float)`.
  - Add `func apply_fuel_cell_pickup() -> void`:
    1. If `active_weapon == null`: return (no-op; defensive — the spawner gating means this branch should not be reachable in normal play).
    2. Compute `restored := minf(active_weapon.max_energy - active_weapon.current_energy, fuel_cell_refill_fraction * active_weapon.max_energy)`. Clamp to `[0, max_energy]`. Set `active_weapon.current_energy += restored`.
    3. Emit `typed_weapon_energy_changed(active_weapon.current_energy, active_weapon.max_energy)`.
    4. Emit `typed_weapon_partial_refilled(active_weapon.family.family_id, restored)`.
    5. `print("typed_weapon_partial_refilled family=%s restored=%.2f current=%.2f max=%.2f" % [...])` for the event log.
  - **Crucially do not call `equip()`** in `apply_fuel_cell_pickup` — equip rebuilds the `TypedWeapon` and would silently reset state that fuel cells must preserve. The refill mutates `active_weapon` in place.
- **`FuelCellCarrier` changes.**
  - In `_try_collect_from`, after the existing `_state != DESCENT` early return, resolve the slot via the existing `_resolve_typed_weapon_slot(other)` walk. If `slot == null` or `slot.call("has_weapon") == false`: return (carrier keeps flying). Otherwise call `slot.apply_fuel_cell_pickup()` before the existing `_collected = true` / signal / burst / `queue_free` sequence.
  - The existing `fuel_cell_collected(spawn_position)` signal still fires unchanged — telemetry value is preserved for T018.
- **`FuelCellCarrierSpawner` changes.**
  - Add a slot reference field `_typed_weapon_slot: Node` resolved on `_ready` (mirror `hud.gd._resolve_typed_weapon_slot`; accept an optional exported `typed_weapon_slot_path: NodePath` for robustness, but find via `current_scene.find_child("TypedWeaponSlot", true, false)` as the fallback).
  - Add a private `_slot_had_weapon_last_tick := false` cache.
  - In `_physics_process`:
    1. `var has_weapon := _typed_weapon_slot != null and _typed_weapon_slot.has_method("has_weapon") and bool(_typed_weapon_slot.call("has_weapon"))`.
    2. If `has_weapon and !_slot_had_weapon_last_tick`: `_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)`. (Equip-edge reset.)
    3. `_slot_had_weapon_last_tick = has_weapon`.
    4. If `!has_weapon`: return (no countdown, no spawn).
    5. Otherwise proceed with the existing T012 countdown / `_spawn_carrier()` / interval-increment flow.
  - **Initialization.** Keep the T012 `_ready` initializer `_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)`. If the player starts the run with no weapon equipped, the timer is held at `spawn_interval_seconds` and only begins counting on the first equip (which is the equip-edge reset path). This matches "no instant spawn after equip" as the user specified.
- **`EnergyMeter` changes.**
  - Add constants `PARTIAL_REFILL_FLASH_FILL`, `PARTIAL_REFILL_FLASH_BORDER`, `PARTIAL_REFILL_FLASH_SECONDS := 0.16`.
  - Add `func flash_partial_refill() -> void` mirroring `flash_refill()` shape. Same `is_inside_tree()` guards, same `SceneTreeTimer` await, same final `set_energy(_bar.value, _bar.max_value)` restoration. The two methods do **not** share an underlying generic helper in this slice — the duplication is small and the explicit pair reads more clearly than a parameterized flash; M7 may consolidate.
- **HUD wiring.** In `hud.gd._ready`, after the existing `connect("typed_weapon_refilled", ...)` line, add `connect("typed_weapon_partial_refilled", _on_typed_weapon_partial_refilled)`. The handler is one line: `func _on_typed_weapon_partial_refilled(_family_id: String, _amount_restored: float) -> void: _energy_meter.flash_partial_refill()`.
- **What not to touch in this slice.** EnergyMeter layout, the non-flash color constants, GridMeter, DefenseGrid leak path, baseline enemy HP/descent, formation spawner cadence, pea shooter, `CarrierSpawner` (weapon-chip cadence stays 20.0 s), `WeaponChipCarrier` movement, `WeaponChip` chip drift, pickup burst visuals, run-end overlay, the 5 family resources, projectile sprites, archetype firing logic.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/fuel-cell-partial-refill-clip.mp4` (or stills) — clip showing the player holding a typed weapon at partial energy (target ~40% of max), catching a fuel cell, the EnergyMeter ticking up by ~30% of max, the partial-refill flash playing on the bar, and the equipped family / projectile pattern unchanged before and after.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/fuel-cell-cap-at-max-clip.mp4` (or stills) — clip showing the player holding a typed weapon near full energy (≥ 80% of max) catching a fuel cell, the meter clamping at max (no overflow), the partial-refill flash still firing.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/flash-vocabulary-comparison.md` — short note with side-by-side stills of `flash_refill` (T011, same-family chip) and `flash_partial_refill` (T013, fuel cell) confirming the partial flash reads as visibly weaker / shorter than the full-refill flash at gameplay framerate.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/no-spawn-without-weapon.md` — short note confirming that with no typed weapon equipped, no fuel-cell carriers spawn for at least 2× `spawn_interval_seconds` of held empty-slot state. Include the event log snippet showing zero `fuel_cell_carrier_spawned` lines across the empty window.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/equip-edge-reset.md` — short note confirming that when a typed weapon is equipped after a stretch of empty-slot state, the spawner waits a full `spawn_interval_seconds` before its next spawn (no instant spawn at the equip moment, no carry-over of a partially-elapsed timer).
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/in-flight-empty-slot.md` — short note confirming that a fuel-cell carrier already in flight when the typed weapon expires continues its descent normally and is **uncollectible** until the player re-equips (touching the carrier while empty does not consume it). If the carrier exits before re-equip, it `queue_free`s through its normal bottom-edge exit — no special despawn.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/partial-refill-verification.txt` — output of the verifier script. Must end in `PARTIAL_REFILL_VERIFICATION_OK`.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/event-log.txt` — captured event log from a short live run showing the spawn → collect → `typed_weapon_partial_refilled` sequence, including the `restored=` value for at least one partial catch and one at-cap catch. No `grid_damaged` events tied to fuel-cell carriers.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] Catching a fuel cell with a typed weapon equipped at partial energy restores 30% of the weapon's `max_energy` (capped at `max_energy`). The equipped family is unchanged; the projectile pattern on the next trigger pull is identical to before the pickup.
- [ ] Catching a fuel cell at or near full energy clamps the meter at `max_energy` with no overflow; the partial-refill flash still fires, and the `amount_restored` value in the event log reflects the actual (possibly zero) energy delta.
- [ ] The partial-refill flash (T013) is visibly **weaker / shorter** than the same-family full-refill flash (T011) at gameplay framerate. A reviewer watching one of each in close succession can tell them apart.
- [ ] No fuel-cell carriers spawn while the typed-weapon slot is empty. After at least 2× the spawn interval of held empty-slot state, zero `fuel_cell_carrier_spawned` events have fired.
- [ ] After equipping a weapon following an empty-slot stretch, the spawner waits a full `spawn_interval_seconds` before its next spawn. No instant spawn at the equip moment, no carry-over of any partially-elapsed timer from before the empty window.
- [ ] A fuel-cell carrier already in flight when the typed weapon expires continues its normal descent and exit. Touching the carrier with an empty slot does **not** consume it (no pickup_burst, no `fuel_cell_collected` signal). If the player re-equips before the carrier exits, the carrier is collectible normally.
- [ ] `typed_weapon_partial_refilled(family_id, amount_restored)` is the only new slot signal. Fires only from the fuel-cell path. Does **not** fire from any chip-pickup path.
- [ ] No changes to the same-family chip refill flash (still uses `flash_refill`), the different-family swap behavior, weapon-chip carrier cadence (still 20.0 s), `WeaponChipCarrier` / `WeaponChip` behavior, baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter layout, the 5 family resources, projectile sprites/tints, pea-shooter behavior, or run-end overlay.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_partial_refill.gd` output ends in `PARTIAL_REFILL_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/verify_partial_refill.gd > tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/partial-refill-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/capture_live_partial_refill_evidence.gd > tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/live-capture.txt
git status > tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/git-status.txt
```

Visual evidence (`fuel-cell-partial-refill-clip.mp4`, `fuel-cell-cap-at-max-clip.mp4`, flash comparison stills) is produced from the live `Main.tscn` scene tree by `capture_live_partial_refill_evidence.gd`. The capture script may force-equip the player into a known typed weapon, force-set `current_energy` to a known fraction, force-spawn a fuel-cell carrier at a known position, and force the collection to make each clip deterministic, mirroring the T011 / T012 capture approach.

The verifier script `verify_partial_refill.gd` must exercise (at minimum):

1. A `TypedWeaponSlot` equipped with family_A at `current_energy = 0.40 * max_energy` receives `apply_fuel_cell_pickup()` → asserts `current_energy == 0.70 * max_energy` within tolerance, equipped family is still family_A, `typed_weapon_energy_changed` fired with the new value, and `typed_weapon_partial_refilled("A", ~0.30 * max_energy)` fired exactly once.
2. Same slot at `current_energy = 0.85 * max_energy` receives `apply_fuel_cell_pickup()` → asserts `current_energy == max_energy` (capped, not overflowed), and `typed_weapon_partial_refilled("A", ~0.15 * max_energy)` fired with the **actual** delta (not the nominal 30%).
3. `TypedWeaponSlot` with no weapon receives `apply_fuel_cell_pickup()` → asserts no signal fires and no error is raised (defensive no-op).
4. A `FuelCellCarrierSpawner` with `spawn_interval_seconds = 30.0` and a stub slot reporting `has_weapon() == false` simulated for 60 s spawns **zero** carriers.
5. Same spawner, then the stub slot flips to `has_weapon() == true` at t = 60 s. The next spawn fires at t = 90 s ± a small epsilon (one full interval after the equip edge), not at t = 60 s.
6. A `FuelCellCarrier` in `DESCENT` state with the stub slot reporting `has_weapon() == false` colliding with a stub player area does **not** consume the carrier (no `fuel_cell_collected` signal, no `_collected = true`, no `queue_free`).
7. Same setup but the stub slot flips to `has_weapon() == true` mid-descent — the next collision consumes the carrier normally and emits `fuel_cell_collected`.
8. Prints `PARTIAL_REFILL_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-21 | Created and activated. Pre-flight Q&A with user resolved the four opinion gaps the design log left open for fuel-cell refill semantics: refill amount is a **fraction of `max_energy`** (single faction-agnostic value on the slot, not per-family), starting at **30%**. Fuel-cell carriers do **not spawn at all** while the typed-weapon slot is empty (the spawner gates its timer on `slot.has_weapon()`), and the timer **resets to the full interval on every equip edge** (no instant spawn after equip). Carriers already in flight when the typed weapon expires continue their descent normally but become **uncollectible** until the player re-equips. The HUD uses a new **softer / shorter `flash_partial_refill`** variant on the EnergyMeter, distinct from T011's `flash_refill`, so the player learns the "sip" vs. "top-up" visual vocabulary at a glance. |
| 2026-05-22 | Implemented the T013 fuel-cell refill slice. Added `TypedWeaponSlot.apply_fuel_cell_pickup()`, the exported `fuel_cell_refill_fraction`, the `typed_weapon_partial_refilled(family_id, amount_restored)` signal, fuel-cell carrier collection gating, fuel-cell spawner slot gating / equip-edge timer reset, HUD wiring, and the softer / shorter EnergyMeter partial-refill flash. |
| 2026-05-22 | Acceptance evidence is ready under `tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup/`. `partial-refill-verification.txt` ends in `PARTIAL_REFILL_VERIFICATION_OK`; `headless-smoke.txt` ends in `LAST_HORIZON_BOOT_SMOKE_OK`; `live-capture.txt` regenerated the partial refill, cap-at-max, flash comparison, no-spawn, equip-edge reset, in-flight empty-slot, event log, and checklist artifacts. Stop here for human review per the task workflow. |
| 2026-05-22 | Applied the requested fuel-cell cadence tuning adjustment: doubled appearance rate by changing the baseline fuel-cell spawn interval from `30.0` seconds to `15.0` seconds. Updated the T013 verifier and live evidence notes to validate no-spawn/equip-edge behavior against the new 15-second interval. |
| 2026-05-22 | Human review accepted T013. Moved the task to `docs/tasks/completed/` and marked it completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
