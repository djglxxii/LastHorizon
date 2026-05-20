# T005 — Energy-meter HUD Readout

| Field | Value |
|---|---|
| ID | T005 |
| State | completed |
| Phase | M2 — Typed weapon + energy meter |
| Depends on | T004 |
| Plan reference | `docs/PLAN.md` — M2 |

## Goal

Surface the **dual-role energy meter** introduced in T004 as an **on-screen HUD readout** so a playtester can see the firing-as-spend pressure in real time. The 2026-05-16 dual-role decision elevates the energy bar to a primary HUD surface; this task lands the first piece of UI under `src/ui/` and closes out M2. No new gameplay mechanics — just the visual readout and the wiring to the existing `typed_weapon_slot`.

## Scope

- **In scope:**
  - **On-screen energy meter** rendered as a HUD element using Godot's built-in UI nodes (per `docs/PLAN.md`: HUD does not need bespoke sprites). A `ProgressBar` or styled `ColorRect` pair is the natural fit. Anchor the meter inside the main playfield area so it is legible while the player's eye is on the ship — exact placement (corner, beneath ship, bottom band) is an implementation call to be evidenced and reviewed.
  - **Live binding to the typed-weapon slot's current energy.** The HUD must reflect `current_energy / max_energy` of the equipped family every frame (or on every change). When the slot is empty (no typed weapon equipped — initial future state and post-expiry state), the meter must render in a clearly distinct **empty / inactive** style (e.g., greyed out, zero fill, dim outline) so it is obvious that no typed weapon is held. Today the player debug-starts equipped, so the empty state is exercised after the first expiry.
  - **Smooth visual response to draining.** Holding fire should produce a visibly dropping bar at the family's drain cadence; the playtester must be able to *see* the spend per shot. If `firing_cost` is large enough that the bar drops in obvious steps, that is acceptable and arguably desirable — the dual-role decision wants the spend to feel deliberate.
  - **Expiry transition is visually legible.** When `current_energy` hits 0, the meter must visibly empty (not snap to hidden) and then transition to the empty / inactive style. The pea shooter's continued firing remains the gameplay signal; the HUD's job here is to make the *cause* of the dropback obvious.
  - **No numerical readout required**, but a small numeric label (e.g., `73 / 100`) is acceptable if it helps the playtester read fast-draining values. If included, it must not crowd the playfield.
  - **Use of `src/ui/`.** This is the first scene/script in the `ui/` directory per the `docs/PLAN.md` source-organization shape. Add the HUD scene and script here; do not stuff it inside `src/player/`.
  - **HUD signal source.** Read from the typed-weapon slot via signal or direct reference; do not introduce a parallel "energy state" cache that can drift from the slot's truth. The slot remains the single owner of `current_energy` per T004's design.
  - **Side panels remain placeholder rectangles** per `design/scope.md` — the side-panel mini-map / planet view is **not** in scope. Only the energy meter is added in this task.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- **Out of scope:**
  - **Defense Grid Integrity meter.** That lands with M3 (T008). Even though decisions.md describes the Grid meter as the only health bar and a primary HUD element, it does not exist yet because there are no enemies, no leak source, and no run-end. Do not stub a fake Grid meter in this task.
  - **Weapon identity / icon next to the meter.** Pickups and multiple families do not exist until M4 (T010). With one placeholder family there is no identification problem to solve yet. Color-coding the meter for the current family is fine, but no icon / family-name surface.
  - **Burn-rate indicator** (the "thrifty-vs-thirsty" axis from the 2026-05-16 per-family cost decision). That readability problem is real but requires multiple families to be meaningful. Defer to M4.
  - **Rarity-tier framing** (common / rare / legendary visual treatment from 2026-05-19). Pickups don't exist yet.
  - **Hit-drain visualization.** The energy meter's shield channel is not exercised until M3/M6. Do not animate or stub enemy-fire hits against the meter in this task.
  - **Tween / juice polish.** A clean live readout is the bar; flash / shake / particle effects on drain are not required for v1 evidence. If a subtle fade or color shift between full / low / empty states clarifies the state, that's acceptable; elaborate effects are not.
  - **Sound effects.**
  - **Side panels, mini-map, planet view.**
  - **Audio cues for low / empty energy.**

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T004 completed and its evidence reviewed; typed-weapon slot drains correctly and expires the weapon at 0.
- [x] Re-read the 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" entry — the dual-role decision is what makes the energy bar a primary HUD surface.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — HUD elements use Godot's built-in UI nodes with styled colors, not bespoke sprites.
- [x] Re-read `design/scope.md` v1 in-scope list — only the energy meter is in scope for this task; the Grid meter is M3, side panels are placeholder rectangles.
- [x] Confirm `src/ui/` exists (it does per current layout) and no prior HUD scenes have been created there.

## Implementation notes

- Suggested layout (refine as needed during implementation):
  - `src/ui/energy_meter.gd` + `scenes/ui/EnergyMeter.tscn` — a small HUD scene containing the bar (and optional numeric label). Exposes a method or accepts a signal connection to receive `current_energy` / `max_energy` updates from the typed-weapon slot.
  - `src/ui/hud.gd` + `scenes/ui/HUD.tscn` — a thin top-level HUD container that holds the energy meter and is added as a CanvasLayer child of the main scene. This gives a clear home for the Grid meter (T008) and any future HUD pieces without retrofitting.
- Wiring: prefer signals out of `typed_weapon_slot.gd`. If T004 already emits an energy-changed-style signal, reuse it; if not, add one rather than poll. The HUD subscribes; the slot owns the data. The HUD reads `family.max_energy` at equip time (via signal payload) so it can scale the bar — do not hardcode 100.
- Empty / inactive state: when the slot is empty (no equipped family), the meter should render in a visibly inert style. A simple approach is a separate "no weapon" modulate / texture, swapped by the HUD when the slot signals expiry or empty. The state must be distinguishable at a glance from "full energy."
- Color: a saturated weapon-color fill (per the 2026-05-14 retro-modern visual target) is appropriate. With only one placeholder family in v1, a single color is fine. Do not engineer per-family palette switching now — T010/T011 will need that and will design it then.
- Placement: anchor inside the playable area so it's in the player's foveal vision. The mockup at `assets/last-horizon-gameplay-mockup.png` is the reference for general feel; v1 does not need to match it pixel-for-pixel.
- Keep the HUD ignorant of the pea shooter. The pea shooter has no resource state in v1; the meter is only about the typed weapon. Do not invent a "pea shooter readout" placeholder.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T005-energy-meter-hud-readout/full-meter.png` — screenshot at scene start with the typed weapon equipped and the meter at (or near) full.
- `tests/evidence/T005-energy-meter-hud-readout/drain-sequence.mp4` (or a short series of stills) — capture of held fire visibly dropping the meter from full to empty, the meter transitioning to the empty / inactive style at 0, and the pea shooter continuing to fire uninterrupted across the transition. The same playtest beat as T004, now made legible without console output.
- `tests/evidence/T005-energy-meter-hud-readout/empty-state.png` — screenshot showing the meter's empty / inactive style after expiry; the difference from the full-state screenshot must be obvious without zooming.
- `tests/evidence/T005-energy-meter-hud-readout/hud-placement-notes.md` — short reviewer-facing note describing where the meter is placed on screen and why, with one or two sentences on tradeoffs considered.
- `tests/evidence/T005-energy-meter-hud-readout/headless-smoke.txt` — rerun of headless smoke; must still show `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T005-energy-meter-hud-readout/hud-checklist.md` — manual checklist confirming: meter is visible during play, fills proportionally to `current_energy / max_energy`, drops on fire, reaches empty at expiry, switches to empty / inactive style, and re-fills if the slot were re-equipped (testable by toggling the debug bootstrap or, if convenient, by a temporary refill key — note explicitly if you skip the refill test because no refill path exists yet).
- `tests/evidence/T005-energy-meter-hud-readout/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] The energy meter is visible on screen during play and renders inside the playable area, not in a side panel.
- [ ] The meter's fill reflects `current_energy / max_energy` of the currently equipped typed-weapon family. It is not hardcoded to a 100-unit scale; it reads `max_energy` from the family.
- [ ] Holding fire produces a visibly dropping bar at the family's drain cadence — a playtester can *see* the spend.
- [ ] At 0 energy, the meter reaches empty and then transitions to a clearly distinct empty / inactive style. The transition is legible without numeric overlay.
- [ ] The pea shooter continues to fire uninterrupted across the expiry transition (regression check against T004).
- [ ] The HUD lives under `src/ui/` (script + scene), not inside `src/player/`. No parallel cache of energy state was introduced — the typed-weapon slot remains the single owner.
- [ ] No Defense Grid Integrity meter, weapon icon, family name display, burn-rate indicator, rarity framing, or hit-drain visualization was added.
- [ ] No side panels / mini-map / planet view content was added.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.

**Rerun command:**

```bash
tools/run_headless_smoke.sh > tests/evidence/T005-energy-meter-hud-readout/headless-smoke.txt
git status > tests/evidence/T005-energy-meter-hud-readout/git-status.txt
```

Manual screenshot/video/checklist evidence is produced by running the Godot project interactively and capturing the full / drain / empty states and the placement notes.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-19 | Created and activated. Pre-flight: T004 evidence accepted and energy expiry is observable; the 2026-05-16 dual-role decision and `docs/PLAN.md` "HUD elements use built-in UI nodes" guidance are the governing constraints. Grid meter and side panels deliberately deferred to M3 and beyond. |
| 2026-05-20 | Implemented `src/ui` HUD and energy-meter scenes wired to `TypedWeaponSlot` signals. Added generated still evidence, placement notes, checklist, headless binding verification, and smoke output for review. |
| 2026-05-20 | Moved the energy meter to the bottom of the playfield below the player shield, as low as possible without viewport clipping, and regenerated T005 visual evidence. |
| 2026-05-20 | Human reviewer approved the task; moved to completed. |

## Blocker

None.
