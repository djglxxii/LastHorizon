# T008 — Defense Grid Integrity Meter + Leak Damage + Run-End

| Field | Value |
|---|---|
| ID | T008 |
| State | completed |
| Phase | M3 — Enemy baseline + Defense Grid |
| Depends on | T007 |
| Plan reference | `docs/PLAN.md` — M3 |

## Goal

Give the descending armada **real stakes**. Introduce the **Defense Grid Integrity** meter — the run's only health bar — wire **leak damage** when a baseline enemy crosses the planet line at the bottom of the playfield, and end the run when the Grid hits 0 with a freeze + overlay + restart key. This is the first task where losing is possible; it closes M3.

## Scope

- **In scope:**
  - **Defense Grid Integrity run state.** A single shared `DefenseGrid` Node (under `src/grid/`) owns `max_integrity := 100.0` and a runtime `current_integrity` initialized at full on scene boot. Exposes `apply_leak_damage(amount: float, impact_position: Vector2)` and emits `integrity_changed(current, max)`, `leak_registered(amount, impact_position)`, and `grid_failed` signals. The DefenseGrid lives in `Main.tscn` once, not per-enemy; the HUD and any leak-feedback listeners subscribe to it.
  - **Per-leak damage of `10.0`** against a starting `100.0` pool (10 leaks ends a run). These are tuning starting points, exposed as `@export` on the DefenseGrid node — not buried as constants. Picked for v1 to fail fast enough that playtesters reach run-end during a session, while still letting the dual-role energy meter cycle multiple times before failure (per the M3 stage-shape invariant).
  - **Planet-line crossing detection on baseline enemies.** Each baseline enemy now tracks a configurable `planet_line_y` in playfield coordinates (default just above the HUD band, e.g. `y ≈ 900` for the current 540×960 viewport — exact value is a tuning starting point). When a live baseline enemy's `global_position.y` crosses `planet_line_y` from above, it: (a) calls `DefenseGrid.apply_leak_damage(10.0, global_position)`, (b) emits its `leaked(global_position)` signal, (c) `queue_free()`s itself. A leaked enemy does **not** spawn the kill pixel-burst from T007 — a leak is not a kill; it gets its own visual (below). Death-by-damage (T007) and death-by-leak are mutually exclusive: the `_dead` guard already in `baseline_enemy.gd` covers this.
  - **Planet-impact pixel burst at the leak position.** A separate placeholder VFX (`scenes/vfx/PlanetImpact.tscn` or reuse `PixelBurst.tscn` with a different palette/configuration — implementer's choice) plays at the leak's `global_position` on the playfield. Palette skews toward the Grid color (cool blue/cyan flash) mixed with enemy-hue fragments — reads as "the shield absorbed an impact," not "the enemy exploded." 8–14 fragments, ~0.25s lifetime, one-shot, self-frees. Distinct enough from the T007 kill burst that a reviewer can tell at a glance whether the enemy died or leaked.
  - **Grid meter HUD readout.** A new `scenes/ui/GridMeter.tscn` + `src/ui/grid_meter.gd` placed in `HUD.tscn` at the **bottom-right**, mirroring the existing EnergyMeter's width (~230 px) and vertical position (~926–956 px range). Both meters share the same bottom band; energy stays on the left, Grid sits on the right. The HUD widget subscribes to `DefenseGrid` and renders:
    - A horizontal bar filling proportionally to `current_integrity / max_integrity`.
    - A short text label (e.g. `GRID 100 / 100` or `GRID 100%`) — match the EnergyMeter's existing labeling convention; pick whichever reads more legibly at the current pixel scale.
    - Bar color: cyan/blue family to contrast with the energy meter's existing color and to reinforce the "planet shield" fiction. No final-art polish; placeholder styling on the same quality bar as EnergyMeter.
  - **Leak feedback on the Grid bar.** On every `leak_registered` event, the GridMeter briefly **flashes** (modulate to red/white for ~0.15s, then back) and the bar visibly drops to the new value. Tween the bar value over ~0.15s so the drop is readable rather than instantaneous. Numeric label updates in lockstep.
  - **Run-end on Grid → 0.** When `current_integrity` reaches `0.0`, the DefenseGrid emits `grid_failed` once. On that signal, the orchestrator in `Main.tscn` (or a small `src/game/run_state.gd` introduced here if needed) freezes the run:
    - Stop the enemy spawner (no new formations).
    - Pause descent: easiest implementation is `get_tree().paused = true` plus a top-level `process_mode = PROCESS_MODE_ALWAYS` on the run-end overlay so it stays interactive. Alternative: set descent_speed and spawner cadence to 0 manually. Pick whichever keeps the playfield visibly frozen without freezing the overlay's input handling.
    - Show a full-screen overlay (`scenes/ui/RunEndOverlay.tscn` + `src/ui/run_end_overlay.gd`) with **"DEFENSE GRID FAILED"** and a hint line like **"Press R or Enter to restart"**. Dark semi-transparent backdrop over the playfield; meters remain visible underneath so the reviewer can see Grid = 0.
    - On `R` or `Enter` (or `ui_accept`), reload the current scene: `get_tree().paused = false` then `get_tree().reload_current_scene()`. State reset is whatever a fresh scene load provides — no bespoke reset path required.
  - **Damage hierarchy enforcement for v1.** Only the leak path damages the Grid in this task. Pea-shooter / bare-ship hits damaging the Grid (per the 2026-05-14 hierarchy entry) requires enemy fire, which is **deferred** for v1. Collision damage (M6) is also deferred. The leak is the only Grid debit path here.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. The DefenseGrid, GridMeter, and RunEndOverlay must import and instantiate cleanly headless.
- **Out of scope:**
  - **Enemy fire / enemy projectiles / damage to the player.** Deferred — there is no enemy-fire system in v1's M0–M3.
  - **Collision interception model (enemy body vs. ship).** M6 / T015. The player ship still passes through enemies without consequence.
  - **Pea-shooter / bare-ship Grid damage path.** Listed in the 2026-05-14 hierarchy but requires enemy fire; out of v1 scope until enemy bullets exist.
  - **Defense Grid repair carriers / repair pickups.** Per `docs/design/scope.md`, out of v1.
  - **Different per-enemy-type leak damage values.** The 2026-05-13 entry foresees this, but v1 has one enemy type. Single uniform `10.0` is correct here.
  - **Side panels / window widening / minimap / planet-view art.** Per the user's 2026-05-20 direction: defer side-panel work; the Grid meter lives at the bottom of the playfield next to the energy meter for now.
  - **Score, kill counter, leak counter readout.** Run-end overlay shows "Defense Grid Failed" + restart hint only. Numeric stats are not v1 scope-question evidence.
  - **Run-end audio sting, screen shake, particle storm.** Visual overlay + bar feedback only. Audio and shake are not in v1.
  - **Elite/heavy enemies, carriers, pickups, weapon families beyond debug_plasma.** M4–M6.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

- 2026-05-20 — HUD placement adjusted within the current 540×960 viewport: the existing EnergyMeter remains unchanged at `offset_left=155, offset_right=385, offset_top=926, offset_bottom=956`, and the new 230 px GridMeter sits at the lower-right immediately above it (`offset_left=292, offset_right=522, offset_top=890, offset_bottom=920`). This avoids meter overlap without moving the EnergyMeter; exact same-band left/right placement needs either a later HUD layout pass or a wider instrumentation area.
- 2026-05-20 — User requested final HUD placement adjustment: EnergyMeter moved to bottom-left (`offset_left=18, offset_right=248, offset_top=926, offset_bottom=956`) and GridMeter moved to bottom-right in the same band (`offset_left=292, offset_right=522, offset_top=926, offset_bottom=956`).
- 2026-05-20 — User requested the alien armada descent be slowed by half because the current descent still felt too fast. Baseline formation/spawner `descent_speed` changed from `65.0` to `32.5`.

## Pre-flight

- [x] T007 accepted; baseline enemies take damage, die with a kill burst, and formations clean themselves up when empty. Enemies that survive still despawn silently off the bottom — this task replaces that silent despawn with a leak.
- [x] Re-read the 2026-05-13 "Theme and fail-state" and 2026-05-14 "Ship and planet share one Defense Grid shield" entries — Defense Grid is the only health meter; leaks are heavy damage relative to bare hits (which don't exist yet). The `10.0`/`100.0` numbers chosen here treat each leak as a meaningful but not run-ending event.
- [x] Re-read the 2026-05-16 stage-shape entry — armada is a continuous descent. Run-end on Grid failure is the *only* place the spawner stops; do not introduce a "wave cleared" or "stage cleared" beat anywhere else.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — the planet-impact burst, Grid meter styling, and run-end overlay are placeholder visuals at the same quality bar as the existing EnergyMeter and PixelBurst; programmer-rectangle/text overlay is acceptable, but it must read cleanly (no debug-purple defaults).
- [x] Confirm the current HUD layout: EnergyMeter is at `offset_left=155, offset_right=385, offset_top=926, offset_bottom=956`. The Grid meter mirrors that on the right side of the same band — do **not** reposition the EnergyMeter.

## Implementation notes

- **DefenseGrid node.** A simple Node (not Node2D) under `src/grid/defense_grid.gd`, registered as a child of `Main.tscn` with `unique_name_in_owner = true` so HUD nodes can `%DefenseGrid` it. Holds `@export var max_integrity := 100.0` and `@export var leak_damage_default := 10.0`. `apply_leak_damage(amount, impact_position)` clamps `current_integrity` to `[0, max_integrity]`, emits `integrity_changed` and `leak_registered`, and emits `grid_failed` exactly once when the value first reaches 0. A `_failed` boolean guards re-entrant emission.
- **Planet-line detection.** Add `@export var planet_line_y := 900.0` (or similar default) and a private `_planet_grid_path: NodePath` on `BaselineEnemy`. Resolve the DefenseGrid reference once in `_ready()` via `get_node_or_null("/root/Main/%DefenseGrid")` or by walking up to find a `unique_name_in_owner` node — implementer's call. In `_physics_process`, after the sway update, check `global_position.y >= planet_line_y` and, if not already `_dead` and not already `_leaked`, take the leak path: call `DefenseGrid.apply_leak_damage(leak_damage_per_enemy, global_position)`, emit a new `leaked(global_position)` signal, spawn the planet-impact burst (via `_add_feedback_child` reuse), and `queue_free()`. Add `@export var leak_damage_per_enemy := 10.0` on the enemy so per-type variation has a hook later (out of scope to use it).
- **No double-resolve.** The existing `_dead` guard already prevents kill + leak from both firing. Mirror the pattern with an `_leaked` flag if you prefer explicitness; either way, a single enemy contributes at most one Grid debit.
- **Formation cleanup.** The formation's "free when child count is 0" path from T006/T007 already handles a leaked enemy disappearing — no formation-side changes needed. The formation should still despawn itself when its top edge passes `playfield_height + despawn_margin`; that path covers the (now-rare) case of a formation whose remaining members all leaked before the formation's own y check would trigger.
- **Planet-impact VFX.** Two viable paths:
  1. **Reuse `PixelBurst.tscn`** with a different palette argument — least new code, but requires `PixelBurst` to accept a palette or color tint at instantiation.
  2. **New `scenes/vfx/PlanetImpact.tscn` + `src/vfx/planet_impact.gd`** mirroring PixelBurst's structure with hard-coded cool-palette fragments — slightly more code but trivially distinct from kill bursts.

  Default to (2) unless PixelBurst already supports configurable palettes — keeping the two effects as separate scenes makes evidence frames unambiguous.
- **GridMeter HUD.** Mirror the existing EnergyMeter file structure: `scenes/ui/GridMeter.tscn` with a `Control` root containing a styled `ProgressBar` (or `ColorRect`+`ColorRect` if EnergyMeter does that — match the existing convention) and a `Label`. Position in `HUD.tscn` at `offset_left=GAP, offset_right=GAP+230, offset_top=926, offset_bottom=956` where GAP is chosen so the right edge sits with a small margin from the playfield's right edge (mirror the EnergyMeter's left margin). Script subscribes to the DefenseGrid's signals in `_ready()` via `%DefenseGrid`. On `integrity_changed`, tween the bar to the new value over ~0.15s and update the label. On `leak_registered`, run a one-shot color-modulate flash on the bar.
- **Run-end overlay.** `scenes/ui/RunEndOverlay.tscn` is a `CanvasLayer` (or a `Control` inside the existing HUD CanvasLayer — pick what doesn't cover the meters at boot). Hidden by default; shown on `grid_failed`. Backdrop = semi-transparent dark `ColorRect` filling the playfield; centered `Label` with "DEFENSE GRID FAILED" and a smaller hint label below. Has its own `process_mode = PROCESS_MODE_ALWAYS` so it can listen for input while the tree is paused.
- **Pause + restart wiring.** On `grid_failed`, the orchestrator sets `get_tree().paused = true` and shows the overlay. Spawner and enemies inherit `PROCESS_MODE_PAUSABLE` (the Godot default) so they freeze automatically. The overlay's `_unhandled_input` listens for `ui_accept` and the `R` key, and on either it calls `get_tree().paused = false; get_tree().reload_current_scene()`. No persistent state to clear — a fresh scene load resets everything (energy meter, Grid, spawner, formations).
- **Headless verification.** Add a `tests/evidence/T008-.../verify_grid.gd` script that:
  1. Instantiates `DefenseGrid`, applies 9 leaks of 10.0, asserts `current_integrity == 10.0` and `grid_failed` has not fired.
  2. Applies one more leak; asserts `current_integrity == 0.0` and `grid_failed` fired exactly once.
  3. Applies a further leak; asserts `current_integrity` is still 0 and `grid_failed` did **not** fire again.
  4. Prints `GRID_VERIFICATION_OK` and exits 0.
- **What not to touch in this slice.** Pea-shooter / typed-weapon / energy-meter logic, formation descent speed, spawner cadence, baseline enemy HP / sway, T007 kill burst, T007 damage numbers. The only behavior changes are: leaks register against the Grid, the Grid has a HUD, run ends when Grid is empty.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/grid-meter-hud.png` — screenshot of the HUD at run start showing the new Grid meter at bottom-right next to the existing EnergyMeter at bottom-left, both legible.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/leak-feedback.mp4` (or short still series) — clip showing a baseline enemy crossing the planet line, the planet-impact pixel burst playing at that position, the Grid bar tweening down with a flash, and the numeric label decrementing by 10.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/run-end-overlay.png` — frame of the run-end state: Grid at 0, "DEFENSE GRID FAILED" overlay visible, playfield dimmed behind, meters still readable.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/restart-restores-grid.png` — frame after pressing R/Enter, showing Grid back at full and a fresh armada visible.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/kill-vs-leak-distinct.md` — short note (with cropped frames if useful) confirming the kill pixel-burst (T007) and the planet-impact burst (T008) are visually distinct.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/passthrough-still-holds.md` — note confirming the player ship still passes through enemies without collision response (M6 territory).
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/grid-verification.txt` — output of the headless verification script ending in `GRID_VERIFICATION_OK`.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/headless-smoke.txt` — rerun of headless smoke; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/grid-checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] At run start, the Grid meter is at the bottom-right of the playfield, mirroring the EnergyMeter's width and vertical band. Both meters are simultaneously legible.
- [ ] Initial Grid value reads `100 / 100` (or `100%`) and the bar is full.
- [ ] When a baseline enemy crosses the planet line, a planet-impact pixel burst plays at the crossing position. The burst is visibly different from the T007 kill burst (cooler palette, "shield absorbed" read).
- [ ] Each leak debits exactly `10.0` from the Grid. The bar tweens to the new value over a brief interval and flashes; the numeric label updates to match.
- [ ] A leaked enemy does **not** also spawn the T007 kill burst, and a killed enemy does **not** debit the Grid.
- [ ] After 10 leaks, the Grid reads `0 / 100`. The spawner stops, descending formations freeze in place, and the "DEFENSE GRID FAILED" overlay appears.
- [ ] Pressing R or Enter on the overlay reloads the scene: a fresh armada is descending, Grid is back to `100 / 100`, and the energy meter / typed-weapon state are reset to their boot-time values.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_grid.gd` output ends in `GRID_VERIFICATION_OK` and demonstrates `grid_failed` fires exactly once.
- [ ] No enemy-fire system, no collision response, no Grid-repair pickups, no score readout, no audio, no screen shake were introduced.
- [ ] No changes to T007 behavior: pea-shot kills still take 5 hits, typed-weapon kills still take 2 hits, damage numbers and kill bursts still play, energy meter and HUD positioning are unchanged.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/verify_grid.gd > tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/grid-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/capture_live_grid_evidence.gd > tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/live-capture.txt
git status > tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/git-status.txt
```

Visual evidence (`grid-meter-hud.png`, `leak-feedback.mp4`, `run-end-overlay.png`, `restart-restores-grid.png`) is produced from the live `Main.tscn` scene tree by `capture_live_grid_evidence.gd`, mirroring the T006/T007 capture approach.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-20 | Created and activated. Pre-flight clarified with user: Grid starts at 100, each baseline leak debits 10 (10 leaks = run-end). Run-end is freeze playfield + "DEFENSE GRID FAILED" overlay + R/Enter to reload. Window stays at current size (side-panel widening deferred); Grid meter sits bottom-right mirroring the EnergyMeter's bottom-left placement. Leak feedback = Grid bar flash + planet-impact pixel burst at the crossing position, distinct palette from the T007 kill burst. |
| 2026-05-20 | Implemented DefenseGrid, leak detection, planet-impact VFX, GridMeter HUD, run-end overlay, restart handling, and T008 evidence scripts. Verified `verify_grid.gd`, T007 damage verification, and live screenshot capture locally; final evidence logs are being regenerated under `tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end/`. |
| 2026-05-20 | Adjusted HUD meter positions per user direction: EnergyMeter now sits bottom-left and GridMeter bottom-right, both in the same bottom band. Regenerating T008 evidence after the layout change. |
| 2026-05-20 | Halved armada descent speed from `65.0` to `32.5` per user tuning direction. Regenerating T008 evidence after the speed change. |
| 2026-05-20 | User approved T008. Moving task to completed and committing all changes. |

## Blocker

None.
