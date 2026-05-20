# T006 — Baseline Enemy + Descending Formation

| Field | Value |
|---|---|
| ID | T006 |
| State | completed |
| Phase | M3 — Enemy baseline + Defense Grid |
| Depends on | T005 |
| Plan reference | `docs/PLAN.md` — M3 |

## Goal

Introduce the first enemies to the playfield: a **single baseline enemy type** spawning in **descending block formations** that drift down through the playfield and exit off the bottom. This is the visual and structural skeleton M3 builds on — T007 plugs damage into these enemies, T008 plugs leak-on-exit into the Defense Grid. No damage exchange and no Grid meter are introduced in this task; T006 is the descent itself, which the prototype has never had before.

## Scope

- **In scope:**
  - A **single baseline enemy type** — one entity, one sprite, one set of stats. The 2026-05-16 elite/heavy entry defines baseline as "low HP, killable by the pea shooter within the time they spend in the playfield" — that property must be *expressible* via the enemy's data fields, but cannot be *exercised* yet (T007 wires pea-shooter damage into enemies). Define `max_hp` as an `@export` field so T007 can land without reshaping the entity. Do not stub damage handling itself.
  - **Single static block formation, per-enemy sway.** Each spawned formation is a rectangular **rows × cols** block of baseline enemies, descending as a rigid unit at a tunable downward speed. The block as a whole has no side-to-side step. Each individual enemy adds a **small horizontal sine-wave sway** on top of the block's descent so the formation reads less rigid without dissolving the formation shape. Sway is per-enemy phase, not block-wide — neighboring enemies should not drift in lockstep.
  - **Continuous armada via a spawner.** The "long descending armada extending across multiple screen heights" framing from the 2026-05-16 stage-shape entry must be visibly true at runtime: after one block has descended far enough that the next block can spawn behind it without overlap (or on a tunable spawn cadence — whichever feels right in implementation), the spawner emits another block. The reviewer should see at least two blocks coexisting on screen during evidence capture, demonstrating the column of pressure rather than a one-shot wave.
  - **Despawn silently on bottom exit.** Enemies that cross below the playable area are freed. No signal, no event consumed yet — T008 will add the `leaked` signal and Grid-damage wiring. A debug print on despawn is acceptable for development legibility but should not become load-bearing.
  - **First entities under `src/enemies/`.** Add the baseline enemy script + scene and the formation/spawner script + scene here. Mirror the `src/player/` + `scenes/player/` shape already established. Do not co-locate enemies inside `src/game/` or `src/player/`.
  - **Baseline enemy PNG sprite** under `assets/sprites/enemies/` — a new directory. Follow the established sourcing approach (the agent authors the sprite via a `tools/generate_*.gd` script or hand-authored equivalent, matching the visual feel of the existing player and projectile sprites). The silhouette must be recognizably alien and clearly distinct from the player ship. Update `assets/README.md` with the new sprite entry and provenance per `docs/PLAN.md`.
  - **`src/enemies/baseline_enemy.gd`** is the entity. **`src/enemies/enemy_formation.gd`** (or similarly named — pick what reads cleanly) owns the rigid block movement; it composes baseline enemies as children and translates the block downward. **`src/enemies/enemy_spawner.gd`** owns the cadence of emitting formations. Refine these names during implementation; the boundary that matters is: per-enemy entity vs. per-formation movement vs. spawning loop.
  - **Wire the spawner into `Main.tscn`** so the existing scene now shows the player firing into a descending armada that exits off the bottom (with no damage exchange or Grid effect — both are intentionally absent in T006). The mockup feel from `assets/last-horizon-gameplay-mockup.png` should start to be recognizable.
  - **Tuning surface is data-on-the-spawner.** Block dimensions (rows, cols, intra-block spacing), block descent speed, sway amplitude, sway period, and spawn cadence must be `@export` fields on the spawner / formation scripts so T008 / playtesting can iterate without code edits. Start with values that produce ~4–6 cols × ~3 rows, a descent that takes ~6–10s for a block to cross the playfield, and a sway that reads as life-at-rest rather than as evasion. These are starting points, not commitments.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. The smoke test must not require the spawner to actually emit formations in headless mode — a clean boot of the scene tree is sufficient.
- **Out of scope:**
  - **Damage to enemies.** Pea shooter and typed-weapon projectiles still pass through (or visibly through, or are unaffected by) enemies. Hit detection, HP decrement, and on-kill behavior all land in T007. Do not stub a `take_damage()` method that decrements HP — leave the HP field exported but inert.
  - **Defense Grid Integrity meter and run-end.** Both land in T008. Bottom-exits are silent in T006.
  - **Enemy fire / bullets.** The user explicitly deferred the v1 enemy-fire decision; T006 adds none either way. Do not author enemy-projectile sprites, scenes, or scripts in this task.
  - **Collision interception, post-hit invulnerability.** M6 (T015, T016). The player passes through enemies without consequence in T006; this is a temporary state until M6, not a permanent design.
  - **Elite / heavy enemies.** M6 (T014). One enemy type only.
  - **Rusher behavior.** Out of v1 per `scope.md`. Even per-enemy sway must remain *sway*, not a dive — enemies do not break formation, do not accelerate toward the player, and do not change direction toward the bottom of the screen.
  - **Side-step + descend.** Explicitly rejected for T006 (user choice). The block has no horizontal step. Do not add it as a "harmless option" toggle.
  - **Faction-flavored palette, silhouette family, bullet style.** v1 has one placeholder faction (`scope.md`). One enemy sprite, one palette, no faction visual variants in T006.
  - **Carrier ships (weapon-chip, fuel-cell).** M4 / M5.
  - **Stage progression / boss / armada end.** v1 has no boss, no stage end, no win condition. The armada loops as long as the scene runs.
  - **Sound effects, on-spawn flashes, hit feedback particles.** Visual juice waits until the system it would be juicing exists.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T005 completed and its evidence reviewed; HUD energy meter renders correctly and the typed weapon expires cleanly with the pea shooter continuing.
- [x] Re-read the 2026-05-16 "Elite/heavy enemy tier per faction" entry — baseline-tier definition is "low HP, killable by the pea shooter within the time they spend in the playfield." HP value chosen for baseline must be consistent with that definition when T007 lands; T006 only needs to define the field, not prove the property.
- [x] Re-read the 2026-05-16 "Stage shape: long descending armada with progressive intermix, faction-boss culmination" entry — the armada is a *continuous descending column*, not discrete waves with downtime. The continuous-spawner requirement above derives directly from this.
- [x] Re-read the 2026-05-16 "Non-formation rushers are faction content" entry — rushers are explicitly *out* of v1 per `scope.md`. Per-enemy sway must not drift into rusher-style dive behavior.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — entities are PNG pixel-art sprites with recognizable silhouettes, ~16–64 px, stored under `assets/sprites/<category>/`. Geometric placeholders are not acceptable.
- [x] Re-read `docs/design/scope.md` v1 in-scope/out-of-scope — baseline + elite + carriers are in v1; rushers, additional factions, and faction-themed visual variety are out. T006 covers only baseline + descending formation.

## Implementation notes

- Suggested layout (refine as needed during implementation):
  - `src/enemies/baseline_enemy.gd` + `scenes/enemies/BaselineEnemy.tscn` — the per-enemy entity. Exports `max_hp`, `sway_amplitude`, `sway_period`. Owns the per-enemy sway via a local phase offset (e.g., randomized on `_ready()`) so neighbors do not visibly march in lockstep. Movement is `position += Vector2(sway_x_delta, 0)` on top of the formation's translation.
  - `src/enemies/enemy_formation.gd` + `scenes/enemies/EnemyFormation.tscn` — a rigid container that lays its baseline-enemy children out in a rows × cols grid on `_ready()` and translates the whole node downward each frame at `descent_speed`. Exports `rows`, `cols`, `cell_size`, `descent_speed`. Frees itself when the last child has exited the playable area, or when the whole formation has crossed the bottom edge — pick whichever boundary keeps cleanup simple.
  - `src/enemies/enemy_spawner.gd` + `scenes/enemies/EnemySpawner.tscn` — owns the spawn cadence. Exports `spawn_interval_seconds` (or a "spawn next when previous has descended N pixels" trigger, if that reads better in play). Spawns a new `EnemyFormation` instance above the playable area at a randomized-or-fixed horizontal offset. Lives as a child of `Main`, alongside `Player` and `HUD`.
  - `assets/sprites/enemies/baseline-grunt.png` (or similar) + matching `.png.import`. Add the generation script under `tools/` mirroring the existing typed-projectile sprite generator. Update `assets/README.md` with the new sprite entry and provenance.
- **Sway phase per enemy:** randomize the starting phase on `_ready()` so a block of identical sprites doesn't march in visible synchrony. Keep amplitude small (a few pixels at v1 scale) — sway is texture, not evasion.
- **Coordinate frames:** the formation's transform is the source of truth for "where the block is." Per-enemy sway should add to the enemy's local position relative to its formation slot, not push enemies out of the block shape. A reviewer must still read "this is a block of enemies descending together," not "enemies are independently drifting downward."
- **Playable-area bounds:** read from the same convention `Player` already uses (whatever T002 established). Don't hardcode the bottom Y in two places.
- **Spawner cadence:** the easiest implementable version is a `Timer` that emits a new `EnemyFormation` every N seconds, with N tuned so two-to-three blocks coexist on screen during a normal-paced descent. If the descent feels stuttery (a block exits before the next is fully visible), reduce the interval. The "armada extends across multiple screen heights" requirement is the visual gate.
- **No collision shape on enemies yet.** T015 (M6) is the collision task. Adding a hitbox here that nothing else queries is fine if it costs nothing, but do not author collision *responses* — player passes through enemies in T006. If you add an `Area2D`, leave its callbacks empty.
- **Headless smoke** must keep working. If `Main` now instantiates a spawner that requires assets or sprites to exist, ensure that path either tolerates a missing sprite gracefully or that the smoke test exits before the spawner emits anything. The existing `LAST_HORIZON_BOOT_SMOKE_OK` print should still fire on a clean boot.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T006-baseline-enemy-and-descending-formation/armada-descent.mp4` (or a short series of stills if video tooling is awkward) — capture of at least one full block-descent cycle: a block enters from the top, descends as a rigid unit with per-enemy sway visible, and exits off the bottom. The clip must include a moment where **two blocks coexist** on screen, demonstrating the continuous armada.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/block-formation.png` — single screenshot showing the block formation clearly, with the player ship and existing HUD visible for compositional context. The silhouette of the baseline enemy must be recognizable as alien and visibly distinct from the player ship sprite.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/sway-detail.png` — close-crop or zoomed screenshot showing the per-enemy horizontal sway offsets across a single row (neighbors visibly out of lockstep). Annotate or caption briefly if the offsets are small at v1 scale.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/passthrough-check.md` — short reviewer-facing note confirming: pea bullets and typed-weapon projectiles pass through enemies without effect (no HP decrement, no kill animation, no flash), and the player ship passes through enemies without consequence (no collision response). Both are *intentional* placeholders for T007 and T015.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/headless-smoke.txt` — rerun of headless smoke; must still show `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/armada-checklist.md` — manual checklist confirming: spawner emits successive blocks, two blocks coexist during normal play, each block descends as a rigid unit, individual enemies sway with independent phase, enemies despawn silently on bottom exit, pea shooter and typed weapon continue to fire across the screen against the armada with no damage interaction, headless smoke still passes.
- `tests/evidence/T006-baseline-enemy-and-descending-formation/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] The scene now shows enemies descending from the top of the playfield in a rows × cols block formation, with at least two blocks visible on screen during normal play.
- [ ] Each block descends as a rigid unit; the block does not visibly fragment, scatter, or dive.
- [ ] Individual enemies within a block exhibit small horizontal sway with independent phase offsets — neighbors are visibly out of lockstep.
- [ ] Enemies that reach the bottom of the playable area despawn silently. No Grid meter, no leak feedback, no game-over.
- [ ] Pea shooter and typed-weapon projectiles continue to fire and travel upward across the armada with no damage exchange. The player's existing fire behavior from T003/T004/T005 is unchanged.
- [ ] The player ship can move horizontally and pass through enemy positions without collision response (no stop, no damage, no bounce). T015 will add collision; T006 is explicitly passthrough.
- [ ] The baseline enemy uses a PNG pixel-art sprite under `assets/sprites/enemies/`, with a recognizable alien silhouette distinct from the player ship. `assets/README.md` is updated with the new sprite entry and provenance.
- [ ] `src/enemies/` contains the entity, formation, and spawner scripts (or equivalent boundary). No enemy code was placed under `src/player/`, `src/game/`, or `src/weapons/`.
- [ ] Block dimensions, descent speed, sway amplitude/period, and spawn cadence are exported on the formation/spawner scripts, not buried as hardcoded constants.
- [ ] HP is defined as an `@export` field on the baseline enemy, but no damage code is wired (intentional — T007).
- [ ] No enemy bullets, no rushers, no elite tier, no Grid meter, no collision response, no carriers, and no faction visual variants were introduced.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] HUD energy meter from T005 still binds and updates correctly (regression check against T005).

**Rerun command:**

```bash
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T006-baseline-enemy-and-descending-formation/capture_live_armada_evidence.gd > tests/evidence/T006-baseline-enemy-and-descending-formation/live-capture.txt
tools/run_headless_smoke.sh > tests/evidence/T006-baseline-enemy-and-descending-formation/headless-smoke.txt
git status > tests/evidence/T006-baseline-enemy-and-descending-formation/git-status.txt
```

Visual evidence is produced from the running `Main.tscn` scene tree by `capture_live_armada_evidence.gd`, which advances live frames and saves viewport captures of the armada descent, block formation, and sway detail. Checklist and passthrough notes remain reviewer-facing written evidence.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-20 | Created and activated. Pre-flight: T005 evidence accepted; the 2026-05-16 elite/heavy, stage-shape, and rusher entries are the governing decisions, plus the v1 in-scope list in `scope.md`. Per user direction this task uses a single static block formation that descends as a rigid unit with per-enemy sway; horizontal block-step, enemy bullets, and faction visual variants are explicitly out of scope. Bottom-exit is silent despawn — T008 will attach Grid-leak damage to the same exit. |
| 2026-05-20 | Implemented T006 slice: added baseline enemy entity, descending formation, continuous spawner, generated baseline enemy sprite, wired the spawner into `Main.tscn`, and produced visual/checklist evidence under `tests/evidence/T006-baseline-enemy-and-descending-formation/`. |
| 2026-05-20 | Tuning adjustment after review: halved the default enemy descent speed from `130.0` to `65.0` and regenerated T006 evidence with the slower descent. |
| 2026-05-20 | Evidence correction after review: replaced the standalone rasterized armada evidence script with a live scene capture script that loads `Main.tscn`, advances the actual scene tree, and captures viewport images from the real spawner/formation/enemy chain. Also moved the two-block frame to a timestamp where the second block is visible on screen. |
| 2026-05-20 | Accepted by human reviewer and moved to completed. |

## Blocker

None.
