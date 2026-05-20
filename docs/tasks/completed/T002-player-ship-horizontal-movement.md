# T002 — Player Ship + Horizontal Movement

| Field | Value |
|---|---|
| ID | T002 |
| State | active |
| Phase | M1 — Player baseline |
| Depends on | T001 |
| Plan reference | `docs/PLAN.md` — M1 |

## Goal

Add the first playable behavior to the bootstrap project: a visible player ship constrained to horizontal movement near the bottom of the narrow vertical playfield. This creates the control foundation for the later pea shooter and energy-meter tasks without introducing weapons or enemies yet.

## Scope

- **In scope:**
  - A player scene and script under `src/player/` or `scenes/player/` following the existing Godot project layout.
  - Horizontal keyboard/gamepad-friendly movement with tunable speed.
  - Movement clamped inside the active 540x960 playfield.
  - A visible placeholder player-ship PNG sprite suitable for screenshots and consistent with `docs/PLAN.md` v1 sprite expectations.
  - Main scene wiring so the player appears when the project runs.
  - Evidence showing the ship at left, center, and right bounds, plus the command used to produce or support that evidence.
- **Out of scope:**
  - Pea shooter bullets or auto-fire.
  - Typed weapons, energy, pickups, enemies, collision, Defense Grid logic, HUD, side panels, or final art.
  - Input remapping UI or permanent settings.

## Scope changes

| Date | Change |
|---|---|
| 2026-05-19 | Updated visual scope to follow the revised `docs/PLAN.md` v1 sprite requirement: the player is now backed by a project-authored PNG sprite under `assets/sprites/player/` instead of a procedural geometric placeholder. |

## Pre-flight

- [x] Confirm T001 completed and its evidence exists under `tests/evidence/T001-project-bootstrap/`.
- [x] Re-read `docs/PLAN.md` M1 player-baseline milestone.
- [x] Re-read current design invariants for narrow vertical playfield and player/pea-shooter input separation.

## Implementation notes

- Keep the boot smoke path intact: headless mode should still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit cleanly.
- Prefer Godot input actions over raw key checks if adding project-level input config is low-friction; left/right arrow keys and A/D are sufficient for v1.
- The player should sit in the lower defended band but leave room for later bullets, pickups, and collision work.
- Use a modest-resolution project-authored PNG sprite for the placeholder ship. Do not add gameplay systems in this task.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T002-player-ship-horizontal-movement/player-bounds.png` — visual evidence showing the player at left, center, and right bounds, either as a composite screenshot or separate labeled captures.
- `tests/evidence/T002-player-ship-horizontal-movement/headless-smoke.txt` — rerun of the T001 headless smoke after player wiring.
- `tests/evidence/T002-player-ship-horizontal-movement/input-checklist.md` — manual checklist recording movement keys tested and observed clamp behavior.
- `tests/evidence/T002-player-ship-horizontal-movement/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.
- `assets/sprites/player/player-ship.png` — project-authored PNG sprite used by the player scene.

**Reviewer checklist:**

- [ ] The player ship is visible near the bottom of the playfield when the project runs.
- [ ] Left/right controls move only horizontally.
- [ ] The ship cannot leave the left or right playfield bounds.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] No weapons, enemies, Grid logic, or HUD were introduced.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tools/generate_player_sprite.gd
tools/godot/bin/godot --headless --path . --import
tools/godot/bin/godot --headless --path . --script tests/evidence/T002-player-ship-horizontal-movement/render_player_bounds.gd
tools/godot/bin/godot --headless --path . --script tests/evidence/T002-player-ship-horizontal-movement/verify_player_movement.gd > tests/evidence/T002-player-ship-horizontal-movement/movement-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T002-player-ship-horizontal-movement/headless-smoke.txt
git status > tests/evidence/T002-player-ship-horizontal-movement/git-status.txt
```

Manual screenshot/input evidence is produced by running the Godot project and capturing the player at left, center, and right bounds.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-19 | Created and activated after T001 human approval. |
| 2026-05-19 | Implemented visible player scene, horizontal movement/clamping, main scene wiring, and generated screenshot/movement evidence. Ready for human review. |
| 2026-05-19 | Revised player visuals from procedural drawing to a PNG pixel-art sprite after `docs/PLAN.md` was updated to require sprite-backed v1 entity graphics. Regenerated evidence. |
| 2026-05-19 | Human-approved; moved to completed. |

## Blocker

None.
