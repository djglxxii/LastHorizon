# T014 — Elite/Heavy Enemy Type

| Field | Value |
|---|---|
| ID | T014 |
| State | completed |
| Phase | M6 — Elite enemy + collision |
| Depends on | T013 |
| Plan reference | `docs/PLAN.md` — M6 |

## Goal

Introduce a second enemy tier — the **elite/heavy** — into the descending armada. Elites share the formation grid with baseline grunts but have ~4× the HP, deal ~4× the Grid damage on leak, and ramp up in density over the first ~90 seconds of the run. With T014 in place, the pea shooter alone can no longer reliably clear the armada deep into a run: killing elites in time effectively requires an active typed weapon, which is the structural reason the typed-weapon economy exists per the 2026-05-16 elite/heavy decision. Collision interception, post-hit i-frames, and elite-flavored bullet patterns remain out of scope for T014 — this slice delivers the enemy itself and its ramp, not the collision model (T015) or invulnerability window (T016).

## Scope

- **In scope:**
  - **New `EliteEnemy` scene + script** at `scenes/enemies/EliteEnemy.tscn` and `src/enemies/elite_enemy.gd`. Mirrors `BaselineEnemy` shape (signals: `damaged`, `killed`, `leaked`; same `take_damage` / `_leak` flow; same defense-grid resolution; same damage-number / pixel-burst / planet-impact VFX wiring) so the rest of the gameplay stack (projectile hit detection, formation iteration, defense-grid leak path) treats elites and baselines through the same interface. **Differences from baseline:**
    - `@export var max_hp := 20.0` (4× the baseline's 5.0). Starting tuning value; M7 may revisit.
    - `@export var leak_damage_per_enemy := 40.0` (4× the baseline's 10.0). One leaked elite is a major Defense Grid event by design.
    - Uses a **new placeholder sprite** at `assets/sprites/enemies/elite-heavy.png` — same coalition-enemy palette as `baseline-grunt.png`, visibly larger and bulkier silhouette. Quality bar: silhouette must read as "same faction, different tier" at gameplay framerate. No new tint accent — the shape language alone carries the threat read.
    - Sway behavior identical to baseline (uses the same `configure_sway(amplitude, period)` setter so the formation can call it uniformly across both enemy types). Elites are not faster or differently-moving in T014; they are an HP/threat-profile change only.
  - **Per-slot elite roll in `EnemyFormation._spawn_block`.** For each grid slot the formation iterates, roll an independent elite chance: if `randf() < elite_chance` and the slot is occupied, spawn an `EliteEnemy` instead of a `BaselineEnemy`. `elite_chance` is passed in via `configure(...)`. The roll is independent per slot — a formation can have zero elites, several elites, or (rarely) be entirely elites if the chance is high. Per-slot independence matches the chosen ramp model.
  - **Elite chance ramp in `EnemySpawner`.** The spawner tracks `_run_age_seconds` (incremented in `_physics_process` by `delta`), and each `_spawn_formation()` call computes the **current** elite chance:
    - `elite_chance = clampf(_run_age_seconds / elite_ramp_seconds, 0.0, 1.0) * elite_chance_max`
    - With starting tuning `elite_ramp_seconds = 90.0` and `elite_chance_max = 0.20`, this yields `0.0` at t=0 (the opening armada is pure baseline), `~0.10` at t=45 s, `~0.20` at t=90 s, and holds at `0.20` thereafter. Linear ramp; no easing.
    - The computed chance is passed to `formation.configure(...)` as a new trailing parameter, alongside the existing `rows / cols / cell_size / descent_speed / sway_amplitude / sway_period / playfield_height`.
  - **`EnemyFormation.configure` signature extension.** Add a trailing `block_elite_chance: float` parameter, stored as `elite_chance` on the formation and consumed by `_spawn_block`. Default value `0.0` so the existing T020 grid-spacing verifier (which constructs formations with the old 7-arg `configure`) does not crash — old call sites keep working with no elites. The spawner uses the 8-arg form going forward.
  - **`EnemyFormation.elite_enemy_scene: PackedScene` export.** Assigned to `scenes/enemies/EliteEnemy.tscn` in the editor; required for the formation to spawn elites. If unassigned and `elite_chance > 0`, the formation falls back to baseline for that slot and emits a single `push_warning`. The existing `enemy_scene` export remains the baseline grunt scene.
  - **Spawner exports for the ramp.** New on `EnemySpawner`:
    - `@export var elite_ramp_seconds := 90.0`
    - `@export var elite_chance_max := 0.20`
    - The spawner does not need its own `elite_enemy_scene` reference — that lives on the formation.
  - **`Main.tscn` wiring.** Assign `EliteEnemy.tscn` to the spawner's formation scene's `elite_enemy_scene` export. No new top-level node added; the elite is plumbed through the existing formation/spawner stack.
  - **Event log additions.**
    - `elite_spawned slot_row=<int> slot_col=<int> formation_age=<float> elite_chance=<float>` printed by `EnemyFormation._spawn_block` each time an elite is rolled. The `formation_age` here is the seconds-since-run-start used to compute the chance, so the playtest log shows the ramp working.
    - `elite_killed` printed by `EliteEnemy._kill` (in addition to the existing `killed` signal emission). Differentiates elite kills from baseline kills in the captured event log.
    - `elite_leaked grid_damage=<float>` printed by `EliteEnemy._leak`. Differentiates elite leaks from baseline leaks for cost-of-mistake auditing.
    - The existing baseline `killed` / `leaked` event lines are unchanged.
  - **Pixel-burst VFX.** Elites reuse the existing `PixelBurst.tscn` on kill — no new VFX scene. The shape difference (sprite is larger) means the burst origin reads as bigger naturally; explicit burst scale tuning is deferred to M7. Same for `PlanetImpact.tscn` on leak.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0 with the new scene, script, exports, and ramp logic loading cleanly.
  - **T020 grid-spacing guarantee preserved.** Elites occupy the same grid cells as baselines; sway amplitude clamp on the formation is unchanged. The elite sprite's wider footprint **must still fit within the existing `cell_size.x` minus sway**. The placeholder elite sprite should be sized to keep at least the same horizontal safety margin baseline has (`BASELINE_ENEMY_SPRITE_WIDTH = 48.0` → elite stays at or below ~60 px wide; the `SWAY_SAFETY_MARGIN` cap on the formation already enforces this and will clamp sway down if the elite sprite is wider than baseline). The verifier in T020 (`verify_grid_alignment.gd`) should still pass with elites present.

- **Out of scope:**
  - **Collision interception model.** Elites colliding with the player ship → T015. T014 elites are treated identically to baselines by the player-collision code path (currently: nothing, because there is no collision body on the ship in v1 prior to T015). The only contact path that matters in T014 is "elite reaches the planet line" (leak), which is fully wired.
  - **Post-hit invulnerability.** Brief i-frames after a hit → T016.
  - **Elite firing / bullet patterns.** Elites do not shoot in T014; baseline grunts don't shoot either. Bullet patterns are deferred past v1 per `design/scope.md`.
  - **Multiple elite sub-tiers** (mid-elite + heavier "legendary" tier). The 2026-05-16 decision permits per-faction sub-tiers but does not require them. v1 ships a single elite type.
  - **Tuning iteration on the 20 HP / 40 leak / 90 s ramp / 20% max numbers.** Starting values are committed in this task. M7 (tuning consolidation) is the natural place to revisit them.
  - **Per-faction elite variants** (faction-themed silhouettes, palettes, behaviors). v1 has one coalition-flavored elite placeholder; faction content is post-v1.
  - **Elite drop behavior.** Elites do not drop pickups on kill (per 2026-05-16: "Elites do not automatically drop pickups. Drops remain authored-carrier-based"). Weapon-chip carriers and fuel-cell carriers remain the only pickup sources.
  - **Rusher / Galaxian dive-bomber behavior.** Rushers are a separate orthogonal category per the 2026-05-16 entry; not in v1.
  - **EnergyMeter, GridMeter, DefenseGrid leak path internals, TypedWeaponSlot, PeaShooter, WeaponChipCarrier, FuelCellCarrier, FuelCellCarrierSpawner, the 5 family resources, projectile sprites, run-end overlay, pickup burst visuals.** Not touched.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

| Date | Change |
|---|---|

## Pre-flight

- [x] T013 accepted; fuel-cell partial refill + spawner gating live; M5 is functionally complete.
- [x] Re-read 2026-05-16 "Elite/heavy enemy tier per faction" — confirm: baseline (pea-shooter killable in time) + elite (effectively requires active typed weapon). T014's 20 HP / 40 leak starting values satisfy the spirit; M7 may retune.
- [x] Re-read 2026-05-18 "Bi-modal threat categories are independent from baseline/elite HP tiers" — confirm: T014 elites are an HP-tier change only, not a bi-modal handling-demand change. The v1 prototype is single-faction and explicitly does not need to satisfy bi-modal yet; bi-modal is a per-faction authoring constraint for full-game content.
- [x] Re-read 2026-05-16 "Stage shape" — confirm: "early stage has few or no elites, density and elite tier increase deeper into the armada." T014's 0% → 20% / 90 s ramp matches the spirit at v1's endless-armada scale, with the assumption that by ~90 s the player has had time to acquire a typed weapon.
- [x] Re-read 2026-05-16 "Damage hierarchy" — confirm: elite leak damage is heavier than baseline leak damage but still survivable from a single occurrence (40 vs. the Defense Grid's full pool). The Grid sizing is a M3/M7 concern; T014 only sets the per-enemy leak number.
- [x] Re-read T020 (`grid-aligned-armada-spacing`) — confirm: the elite sprite must fit within the existing grid cell minus the sway clamp. The formation's `_clamped_sway_amplitude` already protects against overlap when sprite widths grow; the elite sprite should be authored at ≤ ~60 px wide to keep the existing sway range usable.
- [x] Grep for callers of `EnemyFormation.configure` to confirm extending the signature with a trailing `elite_chance` (default `0.0`) is backwards compatible: only `EnemySpawner._spawn_formation` and the T020 verifier call it. Default-zero keeps the verifier passing without modification.
- [x] Re-read T013 progress log convention (dated rows, Stop-for-review explicit at evidence-ready) — match the same shape here.

## Implementation notes

- **`src/enemies/elite_enemy.gd`.**
  - New `extends Node2D`, `class_name EliteEnemy`. Easiest path: copy `baseline_enemy.gd` and edit `max_hp` / `leak_damage_per_enemy` defaults, the `_kill` print to add `elite_killed`, and the `_leak` print to add `elite_leaked grid_damage=...`. **Do not** subclass `BaselineEnemy` — the two scripts diverge in tuning defaults and event-log strings, and an explicit pair reads more clearly than a parameterized base in this slice. M7 may consolidate.
  - Preserve every signal name, signal payload, public method (`take_damage`, `configure_sway`), and Node2D layout choice from baseline. Projectile hit detection must work against either type via the same `take_damage(amount, hit_position)` call, with no type sniffing in the projectile code path.
  - `_kill` emits the existing `killed` signal **and** prints `elite_killed`. `_leak` emits the existing `leaked(impact_position)` signal **and** prints `elite_leaked grid_damage=%.2f`.
- **`scenes/enemies/EliteEnemy.tscn`.**
  - Mirror `BaselineEnemy.tscn` structure: root `Node2D` with the script attached, a `Sprite2D` child pointed at the new `elite-heavy.png`, and any collision/area children baseline has (or doesn't — projectile hit detection in v1 is via Area2D on the projectile, not on the enemy; verify against the baseline scene before adding nodes).
  - Sprite import settings should match `baseline-grunt.png` (nearest-neighbor filter, no mipmaps) for pixel-art consistency.
- **`assets/sprites/enemies/elite-heavy.png`.**
  - Author a placeholder pixel-art sprite in the same coalition-enemy palette as `baseline-grunt.png` but visibly larger / bulkier (chunkier hull, heavier silhouette). Target width ≤ 60 px to stay under the formation's sway budget. Quality bar: a reviewer glancing at the playfield can instantly tell elite from baseline without reading the HUD.
- **`src/enemies/enemy_formation.gd` changes.**
  - Add `@export var elite_enemy_scene: PackedScene`.
  - Add `var elite_chance := 0.0` (set via `configure`).
  - Extend `configure(...)` to a trailing `block_elite_chance := 0.0` (default keeps T020 verifier compatibility). Store as `elite_chance = clampf(block_elite_chance, 0.0, 1.0)`.
  - In `_spawn_block`, inside the `for col in cols` loop, after computing the slot position, decide which scene to instance:
    - `var is_elite := elite_chance > 0.0 and elite_enemy_scene != null and randf() < elite_chance`
    - If `is_elite`: `var enemy := elite_enemy_scene.instantiate() as Node2D` (plus the existing null-check / push_warning path).
    - Else: existing `enemy_scene.instantiate()` path.
    - If `is_elite` was rolled but `elite_enemy_scene == null`, fall back to baseline and `push_warning("EnemyFormation: elite_chance > 0 but no elite_enemy_scene assigned; spawning baseline.")` once per formation (gate behind a local `_warned_no_elite_scene` flag inside `_spawn_block`).
  - On elite spawn, print the `elite_spawned slot_row=%d slot_col=%d formation_age=%.2f elite_chance=%.2f` event-log line. The `formation_age` is computed from the spawner-provided value; the formation does not own a wall-clock — see below.
- **`src/enemies/enemy_spawner.gd` changes.**
  - Add `@export var elite_ramp_seconds := 90.0` and `@export var elite_chance_max := 0.20`. Add `var _run_age_seconds := 0.0`.
  - In `_physics_process(delta)`, increment `_run_age_seconds += delta` before the existing countdown logic.
  - In `_spawn_formation`, compute `var elite_chance := clampf(_run_age_seconds / maxf(elite_ramp_seconds, 0.01), 0.0, 1.0) * elite_chance_max` and pass it as the new trailing arg to `formation.configure(...)`. Also call `formation.set("elite_chance_run_age", _run_age_seconds)` (or pass via configure if a parameter is cleaner — see the formation note) so the formation's `elite_spawned` event log can print the correct `formation_age`.
  - Cleanest formation-side variant: extend `configure(...)` to accept **both** `block_elite_chance` and `block_run_age_seconds` as trailing params (both default `0.0`). The formation stores them and consumes both in `_spawn_block`. This avoids the `set(...)` indirection.
- **`Main.tscn` wiring.**
  - Assign `scenes/enemies/EliteEnemy.tscn` to the spawner's formation scene `elite_enemy_scene` export. The spawner exports stay at the defaults.
- **What not to touch in this slice.** Projectile hit detection (existing Area2D path works against any node implementing `take_damage`), pea shooter, typed-weapon slot, energy meter, weapon families, carriers (weapon-chip or fuel-cell), defense grid leak path internals beyond the per-enemy damage number, HUD, run-end overlay.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T014-elite-heavy-enemy-type/elite-vs-baseline-silhouette.png` — single still showing one elite and one baseline side by side in the live playfield, confirming the elite reads as "same palette, larger/bulkier" at gameplay framerate.
- `tests/evidence/T014-elite-heavy-enemy-type/elite-survives-pea-shooter-clip.mp4` (or stills) — clip of the pea shooter alone firing into a stationary elite for the elite's full descent. The elite leaks (reaches the planet line) before dying. Confirms the structural intent: pea shooter alone cannot reliably kill an elite in time.
- `tests/evidence/T014-elite-heavy-enemy-type/elite-killed-by-typed-weapon-clip.mp4` (or stills) — clip of the player picking up a Heavy Slug (or other high-damage common-tier family) and killing an elite well before it leaks. Confirms typed-weapon engagement is the intended counter.
- `tests/evidence/T014-elite-heavy-enemy-type/elite-leak-grid-damage-clip.mp4` (or stills) — clip showing a single elite leaking and the Defense Grid meter visibly dropping by the configured 40 (vs. baseline's 10). HUD readout before/after confirms the heavier punishment.
- `tests/evidence/T014-elite-heavy-enemy-type/ramp-density-curve.md` — short note plotting elite density (rolls per formation / total slots in formation) sampled at t ≈ 0 s, 30 s, 60 s, 90 s, 150 s during a single run. Includes the event-log snippet showing the corresponding `elite_chance=...` values. Confirms the 0% → 20% / 90 s linear ramp working end-to-end.
- `tests/evidence/T014-elite-heavy-enemy-type/zero-elites-at-run-start.md` — short note confirming that the first formation of every run contains **zero** elites (the t=0 evaluation of the ramp). Includes the opening event-log snippet showing no `elite_spawned` lines.
- `tests/evidence/T014-elite-heavy-enemy-type/elite-verification.txt` — output of the verifier script. Must end in `ELITE_VERIFICATION_OK`.
- `tests/evidence/T014-elite-heavy-enemy-type/event-log.txt` — captured event log from a ~3-minute live run showing `elite_spawned`, `elite_killed`, and `elite_leaked` lines interleaved with baseline events. Confirms the new event vocabulary.
- `tests/evidence/T014-elite-heavy-enemy-type/grid-alignment-still-passes.txt` — rerun of the T020 grid-alignment verifier with the new elite-bearing formations active. Must still end in `GRID_ALIGNMENT_VERIFICATION_OK`. Confirms T020's invariant survives the elite addition.
- `tests/evidence/T014-elite-heavy-enemy-type/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T014-elite-heavy-enemy-type/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T014-elite-heavy-enemy-type/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] Elite silhouette reads as "same coalition palette, distinct/bulkier shape" against the baseline grunt at gameplay framerate. A reviewer can identify which is which from a single still without reading the HUD.
- [ ] An elite under pea-shooter-only fire takes appreciably longer than the elite's descent window to die — the pea shooter alone cannot reliably prevent an elite leak.
- [ ] An elite under typed-weapon fire (any common-tier family with reasonable energy) dies well before leaking.
- [ ] A single elite leak deducts ~40 Defense Grid integrity (4× the baseline grunt leak). A single baseline leak still deducts ~10.
- [ ] The opening formation of every run contains zero elites (verified across at least 3 fresh starts). The first `elite_spawned` event in the log occurs only after the ramp has had time to climb above zero.
- [ ] By t ≈ 90 s, formations visibly contain elites in roughly 1-in-5 slots on average. Density does **not** continue climbing past that point — the cap holds.
- [ ] The T020 grid-alignment verifier still passes with elite-bearing formations. No new overlap, no sway clipping, no descent-rate drift.
- [ ] `elite_spawned`, `elite_killed`, `elite_leaked` event lines appear in the live event log; baseline `killed` / `leaked` lines still appear unchanged. The two are distinguishable in the log.
- [ ] No regressions in weapon-chip carrier behavior, fuel-cell carrier behavior, typed-weapon refill/swap semantics, pea-shooter firing, energy-meter HUD, Defense Grid run-end behavior, or projectile sprites.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_elite.gd` output ends in `ELITE_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T014-elite-heavy-enemy-type/verify_elite.gd > tests/evidence/T014-elite-heavy-enemy-type/elite-verification.txt
tools/godot/bin/godot --headless --path . --script tests/evidence/T020-grid-aligned-armada-spacing/verify_grid_alignment.gd > tests/evidence/T014-elite-heavy-enemy-type/grid-alignment-still-passes.txt
tools/run_headless_smoke.sh > tests/evidence/T014-elite-heavy-enemy-type/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T014-elite-heavy-enemy-type/capture_live_elite_evidence.gd > tests/evidence/T014-elite-heavy-enemy-type/live-capture.txt
git status > tests/evidence/T014-elite-heavy-enemy-type/git-status.txt
```

Visual evidence (the three clips, the silhouette still, the ramp-density and zero-elites notes) is produced from the live `Main.tscn` scene tree by `capture_live_elite_evidence.gd`. The capture script may force-spawn isolated elites at known positions, force-equip the player into a known typed weapon family, and fast-forward the spawner's `_run_age_seconds` to make ramp samples deterministic, mirroring the T012 / T013 capture approach.

The verifier script `verify_elite.gd` must exercise (at minimum):

1. An `EliteEnemy` instance has `max_hp == 20.0` and `leak_damage_per_enemy == 40.0` by default, emits `damaged` and `killed` signals on `take_damage` calls that reduce HP to zero, and emits `leaked` with the impact position when its global Y crosses `planet_line_y`.
2. An `EliteEnemy` reaching the planet line calls `DefenseGrid.apply_leak_damage(40.0, ...)` exactly once (with a stub DefenseGrid recording the call).
3. An `EnemyFormation` configured with `elite_chance = 0.0` spawns **zero** elites across 100 slot rolls (deterministic with seeded RNG); the spawned children are all `BaselineEnemy`.
4. An `EnemyFormation` configured with `elite_chance = 1.0` spawns **all** elites across its grid; every spawned child is an `EliteEnemy`.
5. An `EnemyFormation` configured with `elite_chance = 0.2` and a seeded RNG spawns elites in approximately 20% of slots across a large batch (within statistical tolerance).
6. An `EnemySpawner` simulated for 0 s of `_run_age_seconds` computes `elite_chance == 0.0`. At `elite_ramp_seconds / 2`, `elite_chance == elite_chance_max / 2`. At `elite_ramp_seconds` and beyond, `elite_chance == elite_chance_max` (no overshoot).
7. An `EnemyFormation` configured with `elite_chance > 0` but `elite_enemy_scene == null` spawns only baselines, emits exactly one `push_warning`, and does not crash.
8. Prints `ELITE_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-22 | Created and activated. Pre-flight Q&A with user resolved the four opinion gaps the design log left open for elites in v1: **HP** is a flat 4× baseline (20.0); **leak damage** is a flat 4× baseline (40.0); **silhouette** is a new placeholder sprite in the same coalition palette, visibly larger/bulkier (shape language, not color accent); and **density** ramps **per-slot** independently from 0% to a 20% cap over the first 90 seconds of the run, then holds. The opening armada of every run is pure baseline (t=0 ramp evaluation = 0%), and elites only surface after the player has had time to acquire a typed weapon. Collision interception, post-hit i-frames, and elite firing remain explicitly out of scope (T015 / T016 / post-v1). |
| 2026-05-22 | Implemented `EliteEnemy`, `EliteEnemy.tscn`, the 60 px same-palette placeholder sprite, per-slot elite formation rolls, spawner-side 0%→20% / 90 s ramp, and elite event-log lines. Generated T014 evidence under `tests/evidence/T014-elite-heavy-enemy-type/`; `verify_elite.gd`, the T020 grid-alignment verifier, and headless smoke all pass. Acceptance caveat: with the committed `max_hp = 20.0` and current pea-shooter DPS, a single perfectly aligned elite does **not** survive a full playfield descent; evidence records the 4× hit requirement and armada-level pressure instead. Retuning HP/descent/pea DPS belongs in M7 unless the reviewer wants to reopen T014 tuning. Stop for review. |
| 2026-05-22 | Accepted by human reviewer and moved to completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
