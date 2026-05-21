# T020 — Grid-Aligned Armada Spacing (Anti-Overlap Tuning)

| Field | Value |
|---|---|
| ID | T020 |
| State | active |
| Phase | M3 — Enemy baseline + Defense Grid |
| Depends on | T006 (revisits its tuning; functional dependency only on the formation/spawner shape T006 established) |
| Plan reference | `docs/PLAN.md` — M3 |

## Goal

Eliminate enemy-on-enemy visual overlap in the descending armada by aligning successive formations to a single coherent global grid. Today the spawner emits each new formation at a fixed horizontal center, and the inter-formation vertical gap (`descent_speed × spawn_interval ≈ 76 px`) is only marginally larger than `cell_size.y` (66 px), so a new block's bottom row sits ~55 px above the previous block's top row — tighter than within-formation rows. Combined with same-column stacking across formations and per-enemy sway that can pull X-neighbors into each other on opposite phases, the armada reads as "stacked aliens" rather than as a coherent grid. T020 is a **tuning + light-logic adjustment** that lands successive formations on integer-cell row spacing, half-cell-staggers their horizontal offset, and caps sway amplitude so neighbors can never visibly collide. No new mechanics, no refactor of the per-formation concept.

## Scope

- **In scope:**
  - **Grid-aligned inter-formation row spacing.** Replace the current `spawn_interval_seconds := 2.35` default on `EnemySpawner` with a value derived from `rows × cell_size.y / descent_speed`. With the current defaults (`rows=3`, `cell_size.y=66`, `descent_speed=32.5`), that lands at **≈6.09 s**. Either:
    - (a) hardcode the new default value in `@export var spawn_interval_seconds := 6.09`, **plus** add a `_ready()` assertion that `abs(spawn_interval_seconds × descent_speed − rows × cell_size.y) < 0.5` and `push_warning` if violated; or
    - (b) compute it at runtime as `var _spawn_interval := rows * cell_size.y / max(descent_speed, 0.01)` and keep `spawn_interval_seconds` only as a fallback / inspector display.
    Pick (a) unless (b) reads cleaner in code review — the load-bearing constraint is that the invariant `spawn_interval × descent_speed == rows × cell_size.y` holds at runtime, and that violating it is loud (warning at boot, not silent drift).
  - **Half-cell horizontal stagger across successive formations.** Track a `_stagger_index` (or boolean flag) on `EnemySpawner` that flips on every spawn. Even formations spawn at `playfield_width × 0.5`; odd formations spawn at `playfield_width × 0.5 + cell_size.x × 0.5` (or `−0.5`, whichever keeps the block centered within the playable area at edge formations). The result is a brick pattern: no two enemies across the armada share an X column. This is the user-chosen "Tuning + horizontal stagger" option from pre-flight.
  - **Sway-amplitude clamp.** Add a `_ready()` validation on `EnemyFormation` (or `EnemySpawner` — whichever owns the value before it's pushed to children via `configure_sway`) that clamps `sway_amplitude` to at most `(cell_size.x − BASELINE_ENEMY_SPRITE_WIDTH) × 0.5 − SWAY_SAFETY_MARGIN`. With `cell_size.x = 82`, sprite width 48, and a 2 px safety margin, the cap lands at **15 px**. The current default of 5 px is already well below the cap; the clamp exists to enforce the invariant if anyone later raises amplitude. Expose `BASELINE_ENEMY_SPRITE_WIDTH` as a constant on the relevant script (don't read it from the texture at runtime — the sprite is content-authored at 48 px and lives in the project as a constant). If the clamp triggers, `push_warning` once with the requested vs. effective amplitude. Do **not** rewrite sway to be deterministic or in-phase — neighbor-phase independence from T006 stays as-is.
  - **`EnemyFormation` keeps its current per-enemy slot layout.** Within a formation, the layout already places enemies on `cell_size`-spaced slot positions; that math is correct today. Do not touch `_spawn_block` except as needed to receive a `slot_offset_x` (or equivalent) if you choose to do the stagger inside the formation rather than at the spawner. **Preference: do the stagger at the spawner by offsetting `formation.position.x`**, not by reshaping the formation's internal slot grid — that keeps the formation's "I am a rigid block of enemies" identity intact and isolates the stagger to one site.
  - **Sprite-edge invariant documented in code.** Add a one-line comment near the spawner's `cell_size`, `descent_speed`, and `spawn_interval` fields making the relationship explicit (e.g., `# spawn_interval × descent_speed must equal rows × cell_size.y to keep the armada on a continuous grid (T020)`). This is the one place a comment is load-bearing: a future tuner who changes `descent_speed` without adjusting `spawn_interval` will desynchronize the grid, and the comment is the cue to look at the assertion.
  - **Tuning surface preserved.** All current `@export` fields stay exported (so playtesters can still nudge values). The new behavior is purely additive: assertions, the stagger toggle, and the sway clamp.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. Boot-time assertions must not fail at default values.

- **Out of scope:**
  - **Global-armada-grid refactor.** Dissolving the per-formation concept into a single shared grid where each enemy is independently slot-assigned was explicitly rejected at pre-flight ("Tuning + horizontal stagger" chosen over "Global armada grid refactor"). Keep formations as the per-block unit; the grid coherence is achieved by spacing and stagger, not by restructuring the entity tree.
  - **Sway redesign.** "Reduce sway significantly" and "Remove sway entirely" were both rejected at pre-flight ("Keep sway, cap amplitude" chosen). Do not lower the default amplitude from 5 px, do not add vertical sway, do not change the sine model. The clamp is a *ceiling*, not a *new value*.
  - **Adjusting `descent_speed`.** Pre-flight committed to keeping `descent_speed` stable (it was the 2026-05-20 T006-review tuning); only `spawn_interval` moves. If `descent_speed` ever needs to change later, the assertion above will catch the drift.
  - **Per-formation horizontal randomization beyond the half-cell stagger.** A full random X offset per formation would break the global-grid invariant. The stagger is exactly `cell_size.x × 0.5` and alternates deterministically; no random jitter.
  - **Changes to: baseline enemy HP/leak/sprite, weapon-chip carriers, chip drift, pickup-burst visuals, EnergyMeter, Defense Grid, pea shooter, typed weapons, run-end overlay, the 5 common-tier weapon families.** None of those are touched.
  - **Difficulty rebalance from the slower cadence.** The new 6.09 s interval will reduce per-time enemy density compared to the current 2.35 s cadence. This is an intentional consequence of the grid invariant; any difficulty re-tuning (cell_size, descent_speed, rows×cols, or rusher/elite introduction) is M6/M7 territory and explicitly **not** rolled into T020.
  - **Tooling for visual grid debugging.** No on-screen grid overlay, no debug-draw cell boundaries. The evidence stills are sufficient to verify alignment by eye.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T011 accepted; M4 is complete through same-family refill / different-family swap, and the next-planned task (T012 — coalition fuel-cell carrier) is paused so T020 can land first per user direction.
- [x] T006's progress log re-read — the 2026-05-20 "halved enemy descent speed from 130.0 to 65.0" review note is the most recent commitment on descent tuning. T020 keeps descent_speed at its current value (32.5; the value reduced once again from 65.0 in subsequent tuning under the running formation/spawner) and moves `spawn_interval` only.
- [x] 2026-05-16 "Stage shape: long descending armada with progressive intermix" re-read — confirms the intended stage shape is a **continuous descending column**, not discrete waves. A grid-aligned spacing where each formation flows into the next on a coherent global grid is the strongest expression of that intent. The longer spawn_interval (6.09 s vs 2.35 s) is *not* a return to "discrete waves with downtime" — because the block height is 198 px and the playfield is 960 px, multiple blocks still coexist on screen and the descent reads as a continuous armada.
- [x] 2026-05-16 "Non-formation rushers are faction content" re-read — confirms within-formation enemies should not rusher-dive. The sway-amplitude clamp explicitly reinforces this: sway stays *texture*, not evasion or pre-rusher motion.
- [x] 2026-05-14 "Narrow vertical playfield" re-read — confirms the playfield is ~9:16 and lateral room is constrained. The half-cell horizontal stagger (`cell_size.x × 0.5 = 41 px`) must keep a `cols=5` formation within `playfield_width=540`. Block width is `(cols-1) × cell_size.x = 328 px`; centered at `540 × 0.5 + 41 = 311`, the rightmost enemy lands at `311 + 164 = 475 < 540`. Confirmed within bounds. The stagger sign (left vs right) does not matter for correctness; pick a consistent convention and document it.
- [x] Pre-flight Q&A resolved the three opinion gaps the design log and PLAN left open:
    1. Scope: tuning + horizontal stagger (not a global-grid refactor; not pure-tuning-without-stagger).
    2. Sway treatment: keep sway, cap amplitude.
    3. Stable knob: keep descent_speed, adjust spawn_interval.

## Implementation notes

- **Where the change lives.** `src/enemies/enemy_spawner.gd` owns the spawn cadence and the horizontal placement; both anti-overlap mechanisms (grid-aligned interval, half-cell stagger) sit here. `src/enemies/enemy_formation.gd` owns the sway-amplitude clamp, since amplitude is pushed from the formation into each enemy via `configure_sway` and the formation is the right gatekeeper. Two files touched, both already existing.
- **Stagger implementation sketch.**
    ```
    var _stagger_index := 0
    var _stagger_offset_x := cell_size.x * 0.5

    func _spawn_formation() -> Node2D:
        ...
        var base_x := playfield_width * 0.5
        var staggered_x := base_x + (_stagger_offset_x if (_stagger_index % 2) == 1 else 0.0)
        formation.position = Vector2(staggered_x, spawn_y)
        _stagger_index += 1
        ...
    ```
    The convention: even formations (index 0, 2, 4, …) spawn centered; odd formations (index 1, 3, 5, …) spawn shifted right by half a cell. Pick the sign once; do not flip per-spawn-context.
- **Grid invariant assertion.** Add at the bottom of `_ready()`:
    ```
    var expected_interval := rows * cell_size.y / max(descent_speed, 0.01)
    if abs(spawn_interval_seconds - expected_interval) > 0.5:
        push_warning(
            "EnemySpawner: spawn_interval_seconds (%.2f) does not match grid-aligned value (%.2f). Armada will drift off-grid."
                % [spawn_interval_seconds, expected_interval]
        )
    ```
    The 0.5 s tolerance is wide enough to forgive minor float drift but narrow enough to catch any real misconfiguration. Adjust if it proves noisy.
- **Sway clamp implementation sketch.** In `EnemyFormation._spawn_block`, just before passing amplitude to children:
    ```
    const SPRITE_WIDTH := 48.0
    const SAFETY_MARGIN := 2.0
    var max_amplitude := (cell_size.x - SPRITE_WIDTH) * 0.5 - SAFETY_MARGIN
    if sway_amplitude > max_amplitude:
        push_warning(
            "EnemyFormation: sway_amplitude %.1f exceeds safe cap %.1f for cell_size.x %.1f; clamping."
                % [sway_amplitude, max_amplitude, cell_size.x]
        )
        sway_amplitude = max_amplitude
    ```
    Then `enemy.configure_sway(sway_amplitude, sway_period)` uses the clamped value. The clamp does not need to be re-applied on every frame — formations are short-lived and `_spawn_block` runs once at `_ready()`.
- **Default value updates.** Change `EnemySpawner.spawn_interval_seconds := 2.35` to `:= 6.09`. Update the corresponding value baked into `scenes/enemies/EnemySpawner.tscn` (if it overrides the export) so the in-scene value matches the script default. **Check both:** an in-`.tscn` override can silently shadow the script default and leave the assertion unsatisfied at runtime.
- **Do not introduce a new `cell_size` constant or duplicate `BASELINE_ENEMY_SPRITE_WIDTH` in two scripts.** If you find yourself needing the sprite width in both `enemy_spawner.gd` and `enemy_formation.gd`, pick one home (`enemy_formation.gd` is the natural one — it's already responsible for sway). The spawner does not need the sprite width.
- **No changes to `BaselineEnemy._ready` or `_physics_process`.** The per-enemy sway model is intentionally untouched. The clamp is upstream of `configure_sway`.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T020-grid-aligned-armada-spacing/grid-aligned-armada.mp4` (or stills) — clip showing at least three successive formations descending. The reviewer must be able to read the armada as a single continuous grid: row spacing across the formation boundary is the same as within-formation row spacing (≈66 px), and adjacent formations are visibly half-cell-staggered in X so no two enemies share a column.
- `tests/evidence/T020-grid-aligned-armada-spacing/stagger-detail.png` — still showing two consecutive formations on screen with the half-cell horizontal stagger clearly readable. Annotate the offset if it's subtle at v1 zoom.
- `tests/evidence/T020-grid-aligned-armada-spacing/sway-cap-warning.txt` — short transcript / log capture demonstrating that setting `sway_amplitude := 50` (e.g., via a one-off debug override in the verifier) triggers the clamp `push_warning` and the effective amplitude is reduced to the safe cap. This proves the guard is wired, not just the default-value safety.
- `tests/evidence/T020-grid-aligned-armada-spacing/grid-invariant-warning.txt` — short transcript / log capture demonstrating that mismatching `spawn_interval_seconds` against the grid-aligned value (e.g., setting it to `3.0` while leaving descent_speed and rows×cell_size.y as defaults) triggers the assertion's `push_warning`. This proves the assertion is wired.
- `tests/evidence/T020-grid-aligned-armada-spacing/no-overlap-verification.txt` — output of the verifier script. Must end in `GRID_ALIGNED_VERIFICATION_OK`.
- `tests/evidence/T020-grid-aligned-armada-spacing/regression-checklist.md` — manual checklist confirming T006/T007/T008/T009/T010/T011 behaviors are unaffected: pea shooter and typed weapon still fire and damage enemies; defense grid still loses Integrity on leak; weapon-chip carriers still drop chips; same-family refill and different-family swap still produce the right HUD/projectile beats.
- `tests/evidence/T020-grid-aligned-armada-spacing/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T020-grid-aligned-armada-spacing/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] Successive formations descend on a continuous grid: the vertical spacing between the bottom row of one formation and the top row of the next is the same as within-formation row spacing (one `cell_size.y`).
- [ ] Adjacent formations are visibly half-cell-staggered in X — no two enemies across consecutive formations share a column.
- [ ] Within a single formation, neighboring enemies in a row sway with independent phase but never visibly touch or overlap (sway-amplitude clamp is in force).
- [ ] The verifier output ends in `GRID_ALIGNED_VERIFICATION_OK`.
- [ ] The grid-invariant `push_warning` fires when `spawn_interval_seconds × descent_speed` materially diverges from `rows × cell_size.y`, and does not fire at default values.
- [ ] The sway-amplitude clamp `push_warning` fires when amplitude exceeds the safe cap, and does not fire at default values.
- [ ] No regression in T006 (formation descent, bottom-exit despawn), T007 (damage exchange), T008 (defense grid leak), T009 (chip carrier + chip drop), T010 (5 common families + tinting), T011 (same-family refill / different-family swap + HUD flash).
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `descent_speed` is unchanged from its current value at HEAD (the 2026-05-20 review-tuned value), and the `BaselineEnemy._physics_process` sway model is unchanged.
- [ ] No global-grid refactor: the per-formation `EnemyFormation` entity still exists and still owns its block of children; the change is purely in spawner-side spacing/stagger and a formation-side clamp.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T020-grid-aligned-armada-spacing/verify_grid_alignment.gd > tests/evidence/T020-grid-aligned-armada-spacing/no-overlap-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T020-grid-aligned-armada-spacing/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T020-grid-aligned-armada-spacing/capture_live_grid_alignment_evidence.gd > tests/evidence/T020-grid-aligned-armada-spacing/live-capture.txt
git status > tests/evidence/T020-grid-aligned-armada-spacing/git-status.txt
```

The verifier script `verify_grid_alignment.gd` must exercise (at minimum):

1. Instantiate `EnemySpawner` with defaults. Assert `spawn_interval_seconds × descent_speed == rows × cell_size.y` within a 0.5 px tolerance.
2. Force two successive formation spawns. Read each formation's `position.x` and assert the second is offset from the first by exactly `cell_size.x × 0.5` (sign-consistent with the chosen convention).
3. Set `sway_amplitude := 50` on a formation, call `_spawn_block`, and assert the effective amplitude pushed into a child enemy is ≤ `(cell_size.x − BASELINE_ENEMY_SPRITE_WIDTH) × 0.5 − SAFETY_MARGIN`.
4. Set `spawn_interval_seconds := 3.0` on a spawner with default `descent_speed` and `rows × cell_size.y`, run `_ready()`, and assert a `push_warning` was emitted (capture via Godot's `Engine.print_error_messages` or by checking the log buffer; if the test harness can't capture push_warning directly, fall back to asserting the computed expected value differs from the configured one by > 0.5 and trust the warning fires).
5. Prints `GRID_ALIGNED_VERIFICATION_OK` and exits 0.

Visual evidence (`grid-aligned-armada.mp4`, `stagger-detail.png`) is produced from the live `Main.tscn` scene tree by `capture_live_grid_alignment_evidence.gd`, mirroring the T006/T011 capture approach. The script may need to advance the scene tree for ~15 s to capture three full formations descending; choose a frame for `stagger-detail.png` where two consecutive formations are both fully visible.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-21 | Created and activated. Pre-flight Q&A resolved three opinion gaps: scope = tuning + horizontal stagger (not a global-grid refactor), sway treatment = keep sway and cap amplitude (no reduction or removal), stable knob = keep descent_speed and move spawn_interval. Inserted in front of T012 (coalition fuel-cell carrier) per user direction. INDEX updated to reflect the new active task. |
| 2026-05-21 | Implemented grid-aligned spawn cadence, alternating half-cell horizontal stagger, and formation-side sway-amplitude clamp. Added verifier/capture scripts and generated T020 evidence: grid/stagger screenshots, warning transcripts, no-overlap verifier output, regression checklist, headless smoke, and git status. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
