# Last Horizon — v1 Prototype Implementation Plan

This is the active architectural plan for the v1 prototype. Every task file references it. For *what* the prototype is testing and what's deliberately deferred, see [`design/scope.md`](design/scope.md). For *why* design decisions are what they are, see [`design/decisions.md`](design/decisions.md).

## Goal

Build a playable v1 prototype that lets a human playtester answer the seven questions in `design/scope.md` — primarily: does the **dual-role energy meter** create real per-shot tension and a rhythmic drop-back-to-pea-shooter loop?

## Stack

Per [`decisions/0001-engine-and-language.md`](decisions/0001-engine-and-language.md): Godot 4.x + GDScript. Engine is pinned and installed locally via a `tools/` bootstrap script. Headless smoke test runs through the same wrapper.

## Visual assets for v1

v1 uses **placeholder pixel-art sprites**, *not* procedural geometric shapes (`ColorRect`, `Polygon2D`, etc.) for game entities. The visual target is the mockup at `assets/last-horizon-gameplay-mockup.png`: pixel-style, retro-modern arcade, saturated effects, readable silhouettes.

Concrete expectations:

- **Game entities** — player ship, enemies, carriers, pickups, projectiles — are **PNG sprites** at modest resolution (roughly 16–64 px per entity, scaled appropriately in-game).
- **Silhouettes must be recognizable.** A ship looks like a ship, an alien like an alien, a weapon-chip carrier visibly distinct from a fuel-cell carrier. Abstract or purely geometric placeholders are not acceptable.
- **Quality bar:** "placeholder, not final." Sprites should not distract a playtester from the energy-meter mechanics, but they should not be visually offensive either. Rough pixel art is OK; programmer-art rectangles are not.
- **Storage layout:** `assets/sprites/<category>/` — e.g., `assets/sprites/player/`, `assets/sprites/enemies/`, `assets/sprites/carriers/`, `assets/sprites/pickups/`, `assets/sprites/projectiles/`.
- **Sourcing:** the coding agent authors sprites directly (by hand or via image generation). If any third-party asset is used, it must be public domain or CC0, and provenance noted in `assets/README.md`.
- **HUD elements** (energy meter, Grid meter, text) can use Godot's built-in UI nodes with styled colors — they do not need bespoke sprites.
- **Side panels** (mini-map, planet view) remain placeholder rectangles per `design/scope.md` and are not in-scope for sprite work.

v1 sprites are throwaway. They will be replaced by final art post-v1; the goal in v1 is enough visual cohesion that playtesting reflects the *mechanics*, not the *graphics*.

## Source organization

Under `src/`, grouped by gameplay domain:

```
src/
  game/        top-level orchestration, scene boot, run state
  player/      ship movement, pea shooter, typed-weapon slot, energy meter
  weapons/     weapon families (data + behavior), pickup application
  enemies/     baseline + elite behavior, formation descent
  carriers/    weapon-chip carriers, fuel-cell carriers, pickup spawning
  grid/        Defense Grid Integrity meter, leak handling
  ui/          HUD, energy meter, Grid meter, pickup readability
```

This is the *intended* shape; tasks add directories as needed and may refine boundaries during implementation. Don't pre-create empty modules.

## Milestones

Each milestone is a coherent slice that produces playable evidence on its own. Only the next 1–2 tasks within a milestone need full specifications; later tasks live as one-liners in `tasks/INDEX.md` until they move toward `active/`.

### M0 — Repo bootstrap
Pinned Godot binary, headless smoke test, project skeleton, `.gitignore`, conventions.

### M1 — Player baseline
Player ship, horizontal movement, auto-fire pea shooter. No enemies yet — just movement and a stream of bullets.

### M2 — Typed weapon + energy meter
Typed-weapon slot with dual-role energy meter. Fire input drains energy; energy expiring drops the player back to the pea shooter. **This is the milestone the entire prototype exists to test.** HUD shows the meter.

### M3 — Enemy baseline + Defense Grid
A single baseline enemy type spawning in a descending formation. Pea shooter and typed weapon damage enemies. Defense Grid Integrity meter; enemies that leak past damage the Grid. Run ends when Grid hits 0.

### M4 — Weapon pickups
Weapon-chip carriers in the descending armada. 3–4 common-tier weapon families with single tunings and visibly distinct handling (e.g., one wide, one piercing, one heavy single-target, one rapid). Same-family pickup refills energy to full; different-family swaps at full energy.

### M5 — Fuel cells
Coalition fuel-cell carriers approaching from below/sides. Partial energy refill on pickup. No leak risk.

### M6 — Elite enemy + collision
Elite/heavy enemy type that effectively requires an active typed weapon to kill before leaking. Collision interception model (weapon energy → capped shield → leak). Brief post-hit invulnerability.

### M7 — Playtest packaging
Tuning constants consolidated for fast iteration. Event log capture for playtester review. Manual playtest protocol covering the seven scope questions.

## Out of scope for v1

Per `design/scope.md`: bosses, mini-map / planet side panels (placeholder rectangles are acceptable), Grid repair carriers, rusher behavior, additional factions, faction-themed visual variety, rare/legendary weapons, cross-run state, between-stage screens, route choice, meta-progression of any form.

## Verification baseline

After each task, the reviewer should be able to:

1. Run the bootstrap script on a fresh checkout and have the pinned engine appear.
2. Run the headless smoke test and see a clean boot.
3. Run the project in the Godot editor and exercise the task's new behavior.
4. Inspect task-specific evidence under `tests/evidence/T###-name/`.

Task-specific evidence (video, screenshot, event log, checklist) is named in each task file per the workflow in [`tasks/README.md`](tasks/README.md).
