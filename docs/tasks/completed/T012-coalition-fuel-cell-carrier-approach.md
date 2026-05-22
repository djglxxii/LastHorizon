# T012 — Coalition Fuel-Cell Carrier Approach

| Field | Value |
|---|---|
| ID | T012 |
| State | completed |
| Phase | M5 — Fuel cells |
| Depends on | T011 |
| Plan reference | `docs/PLAN.md` — M5 |

## Goal

Introduce the **coalition fuel-cell carrier** as a distinct, faction-agnostic vessel that launches up from the bottom of the playfield, arcs to about mid-screen, then descends slowly with gentle sway until it exits through the bottom. The player collects a fuel cell by **flying into the carrier directly** — no shooting required, and player projectiles pass through the carrier harmlessly. T012 delivers the carrier's spawn cadence, two-phase launch/descent traversal, harmless-to-shots interaction, and the on-touch consumption beat (carrier vanishes, pickup burst plays, a `fuel_cell_collected` signal fires). T012 deliberately does **not** apply any energy change on collection — wiring the partial energy refill payload is T013's slice. This task is the foundation that makes the M5 "no leak risk, opportunity-cost-only" pickup category exist on screen.

## Scope

- **In scope:**
  - **New `FuelCellCarrier` (Node2D + Area2D) with two-phase movement.**
    - **Phase A — launch ascent.** Spawned just below the bottom edge of the playfield at a random x within the playfield. Travels upward at a brisk constant speed (start at ~220 px/s — see Implementation notes for the constants surface). No sway during ascent. Ends when the carrier reaches its apex y (random per spawn within a band roughly at mid-screen, e.g. `apex_y_min = 360.0`, `apex_y_max = 440.0`).
    - **Phase B — slow descent with sway.** Once apex is reached, switches to a slow downward speed (start at ~50 px/s) with a sin-wave x-sway that mirrors `WeaponChipCarrier`'s sway grammar (amplitude ~22 px, period ~1.9 s, phase randomized per spawn). The descent anchor x is the carrier's x at apex; the sway is applied as an offset to that anchor.
    - **Exit.** When the carrier's y goes below the bottom edge plus `off_screen_margin`, it `queue_free()`s. No fade-out, no loiter — clean off-screen exit per the user's call.
  - **Direct-contact collection.** The carrier is an `Area2D` (or carries one) with a collision shape sized to its sprite. On `body_entered` (player ship) or `area_entered` (player's pickup hitbox — match whichever convention `WeaponChip` uses today), the carrier:
    1. Emits a new module-level `fuel_cell_collected(spawn_position: Vector2)` signal on the carrier instance.
    2. Spawns a `pickup_burst` at its current position (reusing the existing VFX scene that weapon-chip pickup uses; do not author a new burst variant in this slice).
    3. `queue_free()`s itself.
  - **Player projectiles pass through harmlessly.** Neither the pea bullet nor any typed projectile may damage, destroy, or alter the carrier. Concretely: the carrier's collision layer/mask must not overlap the projectile collision layers, OR the carrier exposes no `take_damage` method and projectiles do not detect it as a target. The carrier sprite renders above projectile sprites is fine; the load-bearing rule is that projectile lifetimes and behavior are unaffected by passing across the carrier. Document the chosen mechanism (layer/mask exclusion vs. no-target-method) in the carrier script with one short comment — this is exactly the kind of non-obvious WHY a future reader needs.
  - **New `FuelCellCarrierSpawner` (Node2D)** dedicated to fuel cells.
    - **Spawn cadence:** `spawn_interval_seconds := 30.0` exported, ~30 s baseline per the design call (less frequent than weapon-chip carriers, which remain at 20 s). The first spawn fires after the first full interval — the run does **not** open with a fuel cell already in flight, so the player has time to read the weapon-chip cadence first.
    - **Spawn position:** random x within `[off_screen_margin, playfield_width - off_screen_margin]`, y at `bottom_spawn_y` (just below the playfield's bottom edge — pick a value that puts the sprite fully off-screen at spawn time so the ascent reads as an entry, not a pop-in).
    - This is a **new spawner**, separate from the existing `CarrierSpawner` (which stays weapon-chip-only). Do not generalize `CarrierSpawner` into a multi-type spawner in this slice — the responsibilities are different enough (spawn direction, weapon pool vs. no pool, cadence, anti-overlap rules) that combining them creates risk of regressing T009/T010/T011 evidence for little gain.
  - **Main scene wiring.** Add a `FuelCellCarrierSpawner` node to `scenes/main/Main.tscn` as a sibling of the existing `CarrierSpawner`, with `carrier_scene` pointing at the new `FuelCellCarrier.tscn`. The spawner's parent in the tree should put fuel-cell carriers under the same world layer used for weapon-chip carriers (so sprite ordering vs. enemies and player is consistent).
  - **Sprite work — fuel-cell carrier hull (PNG).** A new placeholder sprite at `assets/sprites/carriers/fuel-cell-carrier.png` matching the PLAN.md `assets/sprites/carriers/` category (note the existing `weapon-chip-carrier.png` lives under `assets/sprites/enemies/` because it *is* an enemy; fuel-cell carriers are coalition, so the `carriers/` category is the right home). Visual brief:
    - **Palette:** cool blue / cyan coalition hull. Avoid the warm/amber palette used by faction enemies, and avoid the tints used for the 5 common weapon families (the weapon-chip carrier sprite gets tinted per family — fuel-cell carrier must read as "different vessel category" at a glance, not just "different color of the same hull").
    - **Silhouette:** a clearly readable fuel canister / payload pod mounted under or in front of a small utility hull. The silhouette must be *distinct* from `weapon-chip-carrier.png`'s silhouette — a reviewer at gameplay scale must not confuse the two in a 0.3 s glance.
    - **Glow accent:** a single bright cyan/white highlight on the canister area suggesting "fuel inside." A solid color block is fine; do not author multi-frame animation in this slice.
    - **Size:** comparable to `weapon-chip-carrier.png` (~32–48 px). Set up the `.png.import` settings to match the other sprites (filter off / nearest-neighbor, the same import preset other game entities use).
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0 with the new spawner instantiated.
  - **Event log.** The carrier emits `fuel_cell_carrier_spawned(position)` from the spawner on spawn and `fuel_cell_collected(position)` from the carrier on collect. The existing event log capture path used in T009–T011 should record these so the reviewer's evidence log shows the spawn → collect lifecycle.

- **Out of scope:**
  - **The actual partial energy refill on collection.** T013's slice. T012's `fuel_cell_collected` signal is the hook T013 will wire up. T012 deliberately leaves the energy meter untouched on collection — the carrier visibly disappears and the burst plays, but the meter is unchanged.
  - **Approach from sides.** The user committed to "bottom only" (launch up from below). Side approaches are not in v1.
  - **Carrier lingering / fade-out timeout.** The carrier exits cleanly through the bottom. No loiter, no fade.
  - **Shootable-with-penalty variants.** Projectiles pass through harmlessly per the design call.
  - **Fuel-cell tuning iteration** (apex band, ascent/descent speeds, sway amplitude/period, spawn cadence). Initial values are starting points; tuning belongs to M7.
  - **Sound effects** for spawn / collect. No audio system in v1.
  - **HUD changes.** EnergyMeter, GridMeter, and HUD layout are untouched.
  - **Defense Grid Integrity behavior.** Ignored fuel-cell carriers do **not** damage the Grid; the existing leak-damage path is not touched. (This is the load-bearing M5 invariant — verify in evidence that letting carriers exit produces zero Grid change.)
  - **Multiple fuel-cell carriers on screen simultaneously.** With a 30 s cadence and a ~6–8 s on-screen lifetime, two-at-once is rare; do not author an explicit cap or anti-overlap rule in this slice. If playtest reveals stacked carriers feel bad, T017 (tuning consolidation) can address it.
  - **Anti-overlap rules vs. weapon-chip carriers / enemies / chips.** Fuel-cell carriers move on the bottom-up-then-top-down axis; their flight envelope only briefly overlaps with descending weapon-chip carriers near mid-screen, and the design intent is that occasional crossing reads as "supply running through the armada," not a bug. No anti-overlap logic in v1.
  - **Cross-run / meta progression hooks.** None.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T011 accepted; the carrier/chip flow (spawn → drop → collect → equip/refill/swap) is at HEAD.
- [x] Re-read 2026-05-14 "Pickup categories" — confirm fuel cells "restore a small amount of typed-weapon energy/fuel without changing weapon type or level." (Confirms the no-weapon-change semantic that T013 will implement; T012 must not change the active typed weapon on collect either.)
- [x] Re-read 2026-05-16 "Pickup sources split: enemy carriers drop weapons, coalition supply drops fuel" — confirm: fuel-cell carriers are coalition supply approaching from outside the armada (bottom/sides), do **not** damage the Defense Grid if ignored, and engagement is pure opportunity cost.
- [x] Re-read 2026-05-19 "Faction content vs. faction-agnostic carrier split" — confirm fuel-cell carriers are faction-agnostic (one shared coalition visual identity reused across all stages), so the sprite must not lean on any faction palette.
- [x] Re-read the 2026-05-16 implication "engagement is purely opportunity cost (do I leave my formation slot to grab it?)" — note that in v1 the player ship is pinned to the bottom of the playfield (not free-roaming). The opportunity cost in v1 reads as horizontal repositioning during the descent phase, not as "leaving formation." This is consistent with the design log (the player is the only defender), and is exactly why the descent phase swaying through the mid-to-lower playfield is the load-bearing window.
- [x] Re-read T009 (`weapon-chip-carrier-and-drop-spawn.md`) and T010 (`common-tier-weapon-families.md`) for the carrier/chip pipeline shape — confirm `CarrierSpawner` stays weapon-chip-only and we add a parallel `FuelCellCarrierSpawner`; do not refactor `CarrierSpawner` in this slice.
- [x] Grep for the existing `pickup_burst` scene path and confirm it's reusable in the carrier's collection hook without modification.
- [x] Confirm the player ship's pickup-collection collision convention (Area2D `area_entered` vs. `body_entered`) by inspecting `WeaponChip.gd` and the `Player.tscn` collision layers, and match it for the fuel-cell carrier so the reviewer doesn't see a collection-grammar inconsistency between pickup types.

## Implementation notes

- **File and node layout.**
  - `src/carriers/fuel_cell_carrier.gd` (new) — the carrier behavior. Class name `FuelCellCarrier`. (Note `weapon_chip_carrier.gd` currently lives under `src/enemies/` because it is an enemy ship; the fuel-cell carrier is coalition supply, so `src/carriers/` per `docs/PLAN.md`.)
  - `src/carriers/fuel_cell_carrier_spawner.gd` (new) — the dedicated spawner.
  - `scenes/carriers/FuelCellCarrier.tscn` (new) — Area2D root carrying a `Sprite2D`, a `CollisionShape2D` sized to the sprite, and the script.
  - The existing `scenes/main/Main.tscn` adds a `FuelCellCarrierSpawner` node (sibling of `CarrierSpawner`) with `carrier_scene` set to `FuelCellCarrier.tscn`.
- **Two-phase movement state machine.** Use a single `_state` enum (`ASCENT`, `DESCENT`) on the carrier. On `_ready`, sample `_apex_y` from `[apex_y_min, apex_y_max]`, sample `_sway_phase` from `[0, TAU]`, and start in `ASCENT`. Each `_physics_process`:
  - If `_state == ASCENT`: move y by `-ascent_speed * delta`. When `position.y <= _apex_y`, snap y to `_apex_y`, record `_descent_anchor_x = position.x`, switch to `DESCENT`.
  - If `_state == DESCENT`: increment `_age` by delta; set `position.y += descent_speed * delta`; set `position.x = _descent_anchor_x + sin((_age / sway_period) * TAU + _sway_phase) * sway_amplitude`. When `position.y > playfield_height + off_screen_margin`, `queue_free()`.
- **Starting tuning constants** (exported on the carrier so the M7 tuning consolidation can move them later):
  - `ascent_speed := 220.0`
  - `descent_speed := 50.0`
  - `apex_y_min := 360.0`, `apex_y_max := 440.0` (sanity-check against the actual playfield height once you read the Main scene's playfield dimensions; adjust band so apex reads as "about mid-screen" given the real top/bottom edges).
  - `sway_amplitude := 22.0`, `sway_period := 1.9` (close to `WeaponChipCarrier` for grammar consistency; slightly slower period keeps the descent feeling unhurried).
  - `playfield_width := 540.0`, `off_screen_margin := 56.0` (match the existing carrier values).
- **Projectile pass-through.** The cleanest mechanism is collision layer/mask: assign the fuel-cell carrier to a layer that is **not** in the pea bullet's or typed projectile's mask, and put the player's pickup-collect sense in the carrier's monitoring mask. If `WeaponChip` already uses a "pickups" layer that projectiles ignore, reuse that layer for the carrier's collection-side area. The carrier should expose **no** `take_damage` method — if a future projectile change widens the mask by accident, the carrier still doesn't respond to damage. Add a one-line comment on the carrier script noting "intentionally no take_damage — projectiles pass through harmlessly per T012 design call."
- **Spawner cadence behavior.** Mirror `CarrierSpawner`'s shape: `_time_until_next_spawn` initialized to `maxf(spawn_interval_seconds, 0.01)` in `_ready`, decremented in `_physics_process`, spawn when ≤ 0, then increment by the interval. This gives the run a clean opening window before the first carrier appears.
- **Random apex sampling, not deterministic.** Each spawn picks its own `_apex_y` within the band so two carriers in quick succession don't sit at exactly the same height and overlap visually if their lifetimes do briefly cross.
- **Signal surface.** Exactly two new signals:
  - `FuelCellCarrierSpawner.fuel_cell_carrier_spawned(position: Vector2)` — emitted right after `add_child` for the event log.
  - `FuelCellCarrier.fuel_cell_collected(spawn_position: Vector2)` — emitted at the start of the collection handler, before `pickup_burst` and `queue_free`. The argument is the carrier's `global_position` at the moment of collection; T013 will use the signal but not necessarily the position payload.
- **No HUD changes.** Don't touch EnergyMeter, GridMeter, RunEndOverlay, or HUD.
- **No new burst variant.** Reuse `scenes/vfx/PickupBurst.tscn` exactly as weapon-chip pickup currently does. The burst at collection is the "the cell was caught" beat; T013 may layer in a meter-side flash but T012 does not.
- **What not to touch in this slice.** `CarrierSpawner` (stays weapon-chip-only), `WeaponChipCarrier`, `WeaponChip`, the 5 family resources, `TypedWeaponSlot`, `EnergyMeter`, `DefenseGrid`, `BaselineEnemy`, `EnemyFormation`, `EnemySpawner`, `PeaShooter`, `PlayerShip`, projectile scripts, the run-end overlay, and the 20.0 s weapon-chip-carrier cadence.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/fuel-cell-traversal-clip.mp4` (or stills sequence) — clip showing a fuel-cell carrier launching from the bottom edge, ascending to about mid-screen, then slowly descending with visible sway and exiting through the bottom uncollected. The Defense Grid Integrity meter must read identically before and after the carrier's exit.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/fuel-cell-collected-clip.mp4` (or stills) — clip showing the player flying into a fuel-cell carrier during its descent phase, the carrier vanishing on contact, and a `pickup_burst` playing at the contact point. The EnergyMeter must read identically before and after (no refill yet — that is T013).
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/projectiles-pass-through-clip.mp4` (or stills) — clip showing pea bullets and an active typed weapon's projectiles flying across a fuel-cell carrier with no interaction: no carrier damage, no projectile destruction, no carrier movement disturbance.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/visual-distinctness.md` — short note (with 2 reference stills side-by-side or as separate PNGs) confirming the fuel-cell carrier sprite is unambiguously distinct from `weapon-chip-carrier.png` at gameplay scale: different silhouette, different palette (cool blue/cyan vs. weapon-chip family-tinted).
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/no-grid-damage-on-ignore.md` — short note confirming that letting a fuel-cell carrier exit through the bottom uncollected produces **zero** change to the Defense Grid Integrity meter and no `grid_damaged` event in the log.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/fuel-cell-verification.txt` — output of the verifier script. Must end in `FUEL_CELL_VERIFICATION_OK`.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/event-log.txt` — captured event log from a short live run, showing `fuel_cell_carrier_spawned` followed by either `fuel_cell_collected` (collected case) or a clean carrier `queue_free` (exited case), with no `grid_damaged` or carrier-damaged events tied to the fuel-cell carrier.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T012-coalition-fuel-cell-carrier-approach/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] Fuel-cell carriers spawn on a ~30 s cadence (the first spawn fires after the first full interval, not immediately at run start).
- [ ] On spawn, the carrier launches up from below the bottom edge, reaches an apex roughly at mid-screen, then descends slowly with a visible gentle sway, and exits through the bottom if not collected.
- [ ] Flying the player ship into the carrier during the descent phase consumes the carrier (it disappears) and plays a `pickup_burst` at the contact point. The EnergyMeter is unchanged (energy refill is T013, intentionally deferred).
- [ ] Pea bullets and an active typed weapon's projectiles pass across the carrier with no visible interaction. The carrier never takes damage, the projectiles never despawn early or change direction.
- [ ] Ignoring a fuel-cell carrier (letting it exit through the bottom) does **not** change the Defense Grid Integrity meter and does **not** emit a `grid_damaged` event tied to the fuel-cell carrier.
- [ ] The fuel-cell carrier sprite is visually distinct from the weapon-chip carrier sprite at gameplay scale: cool blue / cyan coalition palette with a readable fuel-canister highlight, distinct silhouette.
- [ ] `fuel_cell_carrier_spawned(position)` and `fuel_cell_collected(spawn_position)` are the only two new signals introduced. No new HUD signals, no new EnergyMeter signals.
- [ ] No changes to weapon-chip carrier spawn cadence (still 20.0 s), `WeaponChipCarrier` movement (sweep speed / sway amplitude / sway period unchanged), `WeaponChip` chip drift behavior, baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter / HUD layout, the 5 family resources, projectile sprites, pea-shooter behavior, or run-end overlay.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_fuel_cell_carrier.gd` output ends in `FUEL_CELL_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T012-coalition-fuel-cell-carrier-approach/verify_fuel_cell_carrier.gd > tests/evidence/T012-coalition-fuel-cell-carrier-approach/fuel-cell-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T012-coalition-fuel-cell-carrier-approach/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T012-coalition-fuel-cell-carrier-approach/capture_live_fuel_cell_evidence.gd > tests/evidence/T012-coalition-fuel-cell-carrier-approach/live-capture.txt
git status > tests/evidence/T012-coalition-fuel-cell-carrier-approach/git-status.txt
```

Visual evidence (`fuel-cell-traversal-clip.mp4`, `fuel-cell-collected-clip.mp4`, `projectiles-pass-through-clip.mp4`) is produced from the live `Main.tscn` scene tree by `capture_live_fuel_cell_evidence.gd`. The capture script may force-spawn a fuel-cell carrier at a known position, force-equip the player into a known typed weapon, and (for the projectile-pass-through scene) force-fire across the carrier to make each clip deterministic, mirroring the T009/T010/T011 capture approach.

The verifier script `verify_fuel_cell_carrier.gd` must exercise (at minimum):

1. A `FuelCellCarrierSpawner` instantiated headless with `spawn_interval_seconds = 30.0` spawns no carrier in the first 29 s of simulated time and exactly one carrier just after 30 s.
2. A `FuelCellCarrier` spawned at a known x with `apex_y_min = apex_y_max = 400.0` and `playfield_height` consistent with the scene reaches y ≤ 400.0 within `(spawn_y - 400.0) / ascent_speed + small epsilon`, then transitions to descent, with descent x oscillating around the recorded anchor x within `[-sway_amplitude, +sway_amplitude]`.
3. A `FuelCellCarrier` left to exit through the bottom `queue_free`s itself when `position.y` exceeds `playfield_height + off_screen_margin`, and the Defense Grid Integrity value is identical before and after the carrier's lifetime.
4. A `FuelCellCarrier` colliding with a stub player area emits `fuel_cell_collected(spawn_position)` exactly once and `queue_free`s itself, with the EnergyMeter / `TypedWeaponSlot.current_energy` unchanged.
5. Firing a pea bullet and a typed projectile across the carrier's position does not emit any damage signal on the carrier (the carrier exposes no `take_damage`) and the projectiles complete their normal lifetime.
6. Prints `FUEL_CELL_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-21 | Created and activated. Pre-flight Q&A with user resolved the open opinion gaps the design log left for the fuel-cell carrier: approach direction is **bottom only** (launch up from below, not side approaches); movement is a **two-phase launch ascent then slow descent with gentle sway** (mirroring weapon-chip carrier sway grammar during the descent only); collection is **direct contact with the carrier — no shooting required**; spawn cadence is **~30 s** (less frequent than the 20 s weapon-chip cadence); missed carriers **exit through the bottom and despawn cleanly** (no loiter, no fade); player projectiles **pass through harmlessly** via collision layer/mask exclusion; visual identity is **cool blue/cyan coalition hull with a glowing fuel canister silhouette**, distinct from the weapon-chip carrier sprite. T012 covers the carrier behavior; the actual partial energy refill on collection is T013. |
| 2026-05-22 | Implemented the T012 carrier slice. Added `FuelCellCarrier`, `FuelCellCarrierSpawner`, `FuelCellCarrier.tscn`, main-scene wiring, and the generated cool-blue coalition carrier sprite. Fuel carriers use the pickup collision layer/mask and intentionally expose no `take_damage`, so projectile hitboxes do not target them. Collection is limited to the descent phase so the bottom launch cannot be accidentally caught before the readable slow-descent opportunity window. |
| 2026-05-22 | Acceptance evidence is ready under `tests/evidence/T012-coalition-fuel-cell-carrier-approach/`. `fuel-cell-verification.txt` ends in `FUEL_CELL_VERIFICATION_OK`; `headless-smoke.txt` ends in `LAST_HORIZON_BOOT_SMOKE_OK`; `live-capture.txt` regenerated traversal, collection, projectile pass-through, and visual-distinctness stills. Stop here for human review per the task workflow. |
| 2026-05-22 | Human review accepted T012. Moved the task to `docs/tasks/completed/` and marked it completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
