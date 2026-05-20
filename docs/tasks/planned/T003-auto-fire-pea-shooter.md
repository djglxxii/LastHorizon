# T003 — Auto-fire Pea Shooter

| Field | Value |
|---|---|
| ID | T003 |
| State | planned |
| Phase | M1 — Player baseline |
| Depends on | T002 |
| Plan reference | `docs/PLAN.md` — M1 |

## Goal

Give the player ship a permanent **auto-fire pea shooter** that continuously emits bullets upward without any player input, per the 2026-05-16 input-model invariant. This completes the M1 player-baseline milestone: the ship now moves *and* fires, which is the foundation the typed-weapon slot (M2) will sit on top of.

## Scope

- **In scope:**
  - A pea-shooter behavior attached to the player (as a child node of the Player scene, or as a component owned by `player_ship.gd` — implementer's choice).
  - Bullets fire **continuously** at a tunable rate (`@export` fire interval). The pea shooter has no input — pressing keys, mouse buttons, or gamepad buttons must not start, stop, pause, or change fire rate.
  - Bullets travel **upward** from the ship's current position at a tunable speed (`@export`).
  - Bullets despawn when they leave the playfield (top, and for safety, sides).
  - A **PNG pixel-art bullet sprite** under `assets/sprites/projectiles/pea-bullet.png` (per the `docs/PLAN.md` Visual assets policy). Same generation approach as the player ship is acceptable: a `tools/generate_pea_bullet_sprite.gd` script that produces the PNG, or a hand-authored equivalent. Update `assets/README.md` with the new entry.
  - Main scene continues to load with the player visible and now firing.
  - Headless smoke continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit cleanly.
- **Out of scope:**
  - Player-controlled fire input (that belongs to the typed weapon in T004 — the pea shooter is explicitly *not* under player input).
  - Typed-weapon slot, energy meter, weapon-chip pickups, fuel cells.
  - Enemies, collision detection, damage application, kill resolution. Bullets fire into empty playfield — that's correct for this milestone.
  - Visual effects beyond a simple sprite (no muzzle flash, no trails, no impact VFX).
  - HUD, ammo count, fire-rate readout, side panels.
  - Sound effects.

## Scope changes

None.

## Pre-flight

- [ ] T002 completed and its evidence reviewed.
- [ ] Re-read the 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" entry in `docs/design/decisions.md`. The pea shooter's "always firing, never under player input" property is the load-bearing invariant for this task.
- [ ] Re-read `docs/PLAN.md` M1 milestone and the "Visual assets for v1" section.

## Implementation notes

- Bullet scene lives under `scenes/projectiles/PeaBullet.tscn`; bullet script under `src/weapons/pea_bullet.gd`. The `src/weapons/` directory already exists from the bootstrap skeleton.
- Bullet is a simple `Node2D` (or `Area2D` if convenient for later collision wiring, but no collision logic in this task) with a `Sprite2D` and a script that moves upward each frame and despawns past a y-threshold.
- The pea shooter itself can be a child node of the Player scene with its own script (`src/player/pea_shooter.gd`), or methods on `player_ship.gd`. Either is fine — the structural rule is that fire timing is encapsulated and tunable via `@export`, not magic numbers in `_process`.
- Default fire interval should be visibly continuous but not overwhelming (rough target: 6–10 bullets per second; tune for what reads well on screen).
- Bullet speed should be fast enough to clear the playfield in well under a second.
- Bullets should be visually distinct from the player ship — a small, bright-colored projectile (cyan or green is conventional for player fire and aligns with the visual mockup).
- `texture_filter = 1` (NEAREST) on the bullet sprite to preserve the pixel-art look, matching the player ship sprite.
- The main scene wiring may need a container/parent for bullets so they don't clutter the scene tree under the player (whose position moves). Spawning bullets as children of the Main scene root, with their world position set at spawn time, is the simplest pattern.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T003-auto-fire-pea-shooter/bullet-stream.png` — visual evidence showing the ship at one or more positions with bullets visible streaming upward.
- `tests/evidence/T003-auto-fire-pea-shooter/headless-smoke.txt` — rerun of the headless smoke after pea-shooter wiring; must still show `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T003-auto-fire-pea-shooter/fire-rate-verification.txt` — output of a headless verification script (`tests/evidence/T003-auto-fire-pea-shooter/verify_pea_shooter.gd` or similar) that runs the player + pea shooter for a few simulated seconds and reports the number of bullets fired and their spawn positions/velocities, ending with a recognizable `PEA_SHOOTER_VERIFICATION_OK` line.
- `tests/evidence/T003-auto-fire-pea-shooter/input-checklist.md` — manual checklist confirming the pea shooter is not affected by any input (movement keys, fire keys, mouse buttons, gamepad buttons).
- `tests/evidence/T003-auto-fire-pea-shooter/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] The pea shooter fires continuously as soon as the project starts, without any input.
- [ ] Bullets travel upward from the ship's current x-position.
- [ ] Bullets despawn after leaving the playfield (no growing-forever bullet count).
- [ ] Pressing fire-like inputs (space, mouse, gamepad face buttons) does not change firing behavior in any way.
- [ ] The player can still move horizontally per T002 while bullets fire.
- [ ] The bullet uses a PNG pixel-art sprite from `assets/sprites/projectiles/`, not procedural shapes.
- [ ] `assets/README.md` is updated to reflect the new sprite.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] No typed-weapon slot, energy meter, enemies, collision, or HUD were introduced.

**Rerun command:**

```bash
tools/run_headless_smoke.sh > tests/evidence/T003-auto-fire-pea-shooter/headless-smoke.txt
tools/godot/bin/godot --headless --path . --script tests/evidence/T003-auto-fire-pea-shooter/verify_pea_shooter.gd > tests/evidence/T003-auto-fire-pea-shooter/fire-rate-verification.txt
git status > tests/evidence/T003-auto-fire-pea-shooter/git-status.txt
```

Manual screenshot/input evidence is produced by running the Godot project and capturing the bullet stream interactively.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-19 | Created, state: planned. |

## Blocker

None.
