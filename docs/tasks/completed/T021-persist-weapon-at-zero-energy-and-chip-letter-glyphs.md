# T021 — Persist Typed Weapon at Zero Energy + Weapon-Chip Letter Glyphs

| Field | Value |
|---|---|
| ID | T021 |
| State | completed |
| Phase | M2 / M4 tuning revisit |
| Depends on | T013, T014 |
| Plan reference | `docs/PLAN.md` — M2, M4 |

## Goal

Two coupled tuning adjustments that fall out of the 2026-05-22 design log:

1. **Typed weapon persists at zero energy.** The held typed-weapon family is no longer dropped to "no weapon" when its energy meter reaches `0`. The slot retains the family; firing the typed weapon at `0` energy is silently rejected; the pea shooter continues as the only active offense; and the next refill (same-family chip, fuel cell, or different-family chip swap) resumes firing without forcing the player to re-acquire a family.
2. **Weapon-chip letter glyphs.** Each common-tier weapon-chip pickup carries a stylized family letter centered on the chip body: `S` (Wide Spread), `P` (Piercing Lance), `H` (Heavy Slug), `R` (Rapid Stream), `D` (debug_plasma). The letter sits on top of the existing tint-modulated chip sprite in a contrasting on-tint color so the family is unambiguously readable at the catch decision moment. Carriers continue to telegraph family via tint only — letters are chip-only in v1.

Together these implement the 2026-05-22 "Typed weapon persists at zero energy" and "Weapon-chip readability via stylized family-letter glyph" decision-log entries. The dual-role energy hierarchy is unchanged; the M2 prototype hypothesis is unchanged (energy still both fires and absorbs hits, and the firing-uptime drop-back to pea-shooter-only still happens at zero energy) — what changes is that the player no longer silently loses their family identity at the zero-edge, and chip identity is no longer hue-dependent.

## Scope

- **In scope:**
  - **`TypedWeaponSlot` zero-energy retention.**
    - `_fire_once` no longer calls `_expire_active_weapon` on the "energy insufficient to fire" branch. When `active_weapon.try_fire()` returns `false`, `_fire_once` returns `false` and the slot continues holding the family. No projectile spawns; no error.
    - `_fire_once` no longer calls `_expire_active_weapon` on the "fired but now expired" branch. When `active_weapon.is_expired()` becomes `true` after a successful shot, the slot **does not clear** `active_weapon`. The shot lands normally; subsequent fire inputs while at `0` are no-ops until a refill arrives.
    - `_expire_active_weapon(...)` itself is **removed**. The `typed_weapon_expired` signal is **retired** — no remaining caller, no remaining listener (HUD path is removed too, see below). Removing the signal in this slice is preferred over leaving a dead signal in place, because the v1 codebase has only two listeners and they're both reachable from this task.
    - The `clear()` method is **kept** but no longer called from the zero-energy path. It remains available for explicit slot resets (e.g., a future "lose weapon on collision" mechanic from T015's blast radius), which is not in scope here.
    - Add a new beat: when `current_energy` transitions from `> 0` to `0` (either by firing or by a future absorb-hit path), emit a new signal `typed_weapon_silent(family_id: String)` and print `typed_weapon_silent family=<id> current=0.00 max=<max>` to the event log. The transition is detected with a private `_was_empty_last_tick: bool` cache compared against `active_weapon.current_energy <= 0.0` after each `_fire_once` and each `apply_chip_pickup` / `apply_fuel_cell_pickup`. Re-emission across consecutive frames at `0` is suppressed by the cache — the signal fires once per zero-edge.
    - Add a paired `typed_weapon_resumed(family_id: String)` signal emitted when `current_energy` transitions from `0` back to `> 0` after a refill (same-family chip, different-family swap, or fuel-cell sip). Print `typed_weapon_resumed family=<id> current=<float> max=<float>`. Same cache; same once-per-edge guarantee.
    - The existing `typed_weapon_energy_changed` signal continues to fire on every energy change, including the zero-edges; the new silent/resumed beats are *additional*, not replacement.
  - **Different-family chip swap at zero energy.** Unchanged behavior, made explicit: catching a different-family chip while the held family is at `0` energy still **swaps to the new family at full energy**. The held family is replaced; the player loses the (empty) old family to acquire the (full) new one. This is the same swap rule that already applies at any energy level (T011) — T021 only confirms it survives the new persist-at-zero behavior unchanged.
  - **Same-family chip refill at zero energy.** Catching a same-family chip while the held family is at `0` energy refills the held family to full and emits `typed_weapon_refilled` plus the new `typed_weapon_resumed`. Existing T011 same-family refill behavior, exercised through the new zero state.
  - **Fuel-cell sip at zero energy.** `apply_fuel_cell_pickup` already partially refills the held family (T013). With zero-energy persistence, a fuel cell caught at `0` restores `fuel_cell_refill_fraction * max_energy` (currently 30%) and resumes firing. No change to the fuel-cell math; only the previously-unreachable case of "fuel cell collected while weapon held but at 0" is now reachable in normal play. The T013 spawner gate (`has_weapon()`-based) continues to apply — and since `has_weapon()` now returns `true` through zero energy, the fuel-cell spawner timer runs continuously after the first equip.
  - **HUD updates for the silent state.**
    - `hud.gd._on_typed_weapon_expired` and its `EXPIRY_INACTIVE_DELAY` machinery are **removed**. The expiry-flash-then-set-empty path was the only place the meter became `set_empty()`; with zero-energy persistence the meter at `0` should read as "this family is held but silent," not "no weapon."
    - When `typed_weapon_energy_changed` reports `current_energy == 0` with `max_energy > 0`, `EnergyMeter.set_energy(0, max)` already handles this — the bar drains to empty but the family tint and stylebox persist. No new HUD code is needed for the visual; the change is that nothing now overrides this state to `set_empty()` after a delay.
    - The HUD also drops its `connect("typed_weapon_expired", ...)` line and the corresponding handler. Connection to the two new signals is **optional** for the HUD in v1 — the energy bar already reflects the state through `typed_weapon_energy_changed`. If desired, `typed_weapon_silent` could trigger a brief "weapon silent" tint flash on the bar (e.g., a 0.2 s desaturated pulse) and `typed_weapon_resumed` could trigger the existing `flash_refill` or `flash_partial_refill`. The implementer's call. **Minimum viable**: no HUD wiring for the new signals; rely on `typed_weapon_energy_changed` for the visual.
    - `EnergyMeter.set_empty()` is **still called** at run start (before any chip is caught) — the player begins with no typed weapon at all. This call path is untouched.
  - **`TypedWeaponFamily.letter_glyph: String` field.** New `@export var letter_glyph := ""` on `src/weapons/typed_weapon_family.gd`. Single character expected (`"S"`, `"P"`, `"H"`, `"R"`, `"D"`); empty string is a valid no-glyph fallback for future symbolic chip designs. The five existing `.tres` resources are populated:
    - `data/weapons/common_wide_spread.tres` → `letter_glyph = "S"`
    - `data/weapons/common_piercing_lance.tres` → `letter_glyph = "P"`
    - `data/weapons/common_heavy_slug.tres` → `letter_glyph = "H"`
    - `data/weapons/common_rapid_stream.tres` → `letter_glyph = "R"`
    - `data/weapons/debug_plasma.tres` → `letter_glyph = "D"`
  - **`WeaponChip` scene letter rendering.** `scenes/pickups/WeaponChip.tscn` gains a `Label` child (named `LetterGlyph`) centered on the chip body. `src/pickups/weapon_chip.gd._apply_family_tint` is extended (or paired with a new `_apply_letter_glyph` helper) to set `LetterGlyph.text = family.letter_glyph` and `LetterGlyph.modulate = Color.WHITE` (contrasting against any tinted chip body). Font: Godot's built-in default font is acceptable for v1; font size sized so the letter occupies roughly 60-70% of the chip body diameter. Center alignment via `Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER` and `Label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER`. If the family or `family.letter_glyph` is empty/null, the label is hidden (`visible = false`) so the no-glyph fallback path is silent.
  - **Carrier hull unchanged.** `WeaponChipCarrier` continues to use tint-only family telegraphing. No letter on the carrier in v1.
  - **CLAUDE.md invariant update.** Edit the "Energy is dual-role" bullet in `CLAUDE.md` so the final sentence reads "When it reaches 0, the typed weapon cannot fire until refilled, but the held family persists." This brings the load-bearing invariants in line with the 2026-05-22 design log entry. **The 2026-05-19 weapon-model bullet** ("Same-family pickup refills the energy meter to full; different-family swaps to the new family at full energy.") is unchanged — that rule survives intact at zero energy and is reaffirmed by this task.
  - **Event log additions.**
    - `typed_weapon_silent family=<id> current=0.00 max=<float>` — once per zero-energy edge transition.
    - `typed_weapon_resumed family=<id> current=<float> max=<float>` — once per refill back above zero.
    - The existing `typed_weapon_expired` print and the legacy `typed_weapon_dropped`-style event log lines (if any remain) are removed.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0 with the new signal pair, removed expiry path, new family field, and chip label all loading cleanly.

- **Out of scope:**
  - **Rare and legendary chip readability.** The 2026-05-22 letter-glyph entry only commits the common-tier convention. Rare/legendary visual treatment (border, particle accent, etc.) is deferred.
  - **Letter glyphs on the carrier hull.** Carriers stay tint-only in v1 per the chosen scope.
  - **Per-family bespoke fonts or hand-authored letter sprites.** Default-font Label is the v1 implementation. Final art can replace with hand-drawn glyphs post-v1.
  - **The "weapon silent" HUD flash on the meter.** Optional and explicitly minimum-viable; the bar at `0` reads the silent state through its existing empty-with-family-tint look. Implementer can add a desaturated pulse if it lands within the slice, but it's not required.
  - **Player ship visual changes** while the typed weapon is silent (e.g., a "silent" cosmetic indicator on the ship). The HUD energy bar is the readability surface.
  - **Collision interception.** Still T015's slice. T021 does not change the absorb-hit path or the player's collision body.
  - **Fuel-cell tuning, weapon-chip cadence, per-family burn rate retuning.** No tuning changes to any family's `max_energy`, `firing_cost`, `fire_interval`, `projectile_damage`, etc.
  - **Elite enemy tuning** (T014 HP / leak / ramp values stay as committed; M7 retunes).
  - **Reworking the `typed_weapon_expired` listeners outside HUD.** Verified callers are HUD only in current code; no other listeners exist. If a third caller is discovered during implementation, it is documented in Progress log and re-wired to `typed_weapon_silent` or `typed_weapon_energy_changed`, whichever fits.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

| Date | Change |
|---|---|

## Pre-flight

- [x] T014 accepted and moved to `completed/`; elite tier is live in the armada.
- [x] Re-read 2026-05-22 "Typed weapon persists at zero energy; no auto-expire to pea shooter" — confirm the rule: family identity persists past zero; firing is rejected silently; different-family swap rules unchanged; the CLAUDE.md "Energy is dual-role" invariant requires a one-sentence amendment.
- [x] Re-read 2026-05-22 "Weapon-chip readability via stylized family-letter glyph" — confirm the rule: chip-only (not carrier), role-letter convention (S/P/H/R/D), contrasting on-tint color, placeholder-class implementation acceptable for v1.
- [x] Re-read T011 same-family-refill / different-family-swap-at-full semantics — confirm: T021 does not alter the swap rule at any energy level. The 2026-05-19 "Same-family pickup refills to full; different-family swaps at full" decision still holds at zero energy.
- [x] Re-read T013 fuel-cell spawner gate — confirm: `has_weapon()` continues to gate fuel-cell spawns. With persist-at-zero, `has_weapon()` returns true through zero energy, so once the player catches their first chip the gate is effectively always open for the rest of the run. This is the intended steady state.
- [x] Re-read T010 chip identity surface — confirm: tint modulate stays on the chip body; the letter glyph is composited on top. Per-family projectile tints (T010 implementation note) are unchanged.
- [x] Grep for listeners of `typed_weapon_expired`: only `hud.gd` line 23. Removing the signal removes one HUD handler and one HUD timer path; no other code touches it.
- [x] Grep for the literal string `typed_weapon_expired` in `tests/` evidence: T004 and T005 verifier scripts may reference it. Confirm whether T021's verifier must replicate any of that flow — current code has no test infra against the expiry path, so T021's new verifier is the sole coverage.
- [x] Confirm `EnergyMeter.set_energy(0.0, max)` paints the bar empty without clearing the family-tint stylebox. This is the visual that needs to read as "silent" — visually verify the bar at zero retains family tint after T021's HUD changes.

## Implementation notes

- **`src/player/typed_weapon_slot.gd`.**
  - Remove `signal typed_weapon_expired(family_id: String)`.
  - Add `signal typed_weapon_silent(family_id: String)` and `signal typed_weapon_resumed(family_id: String)`.
  - Add private `var _was_empty_last_tick := false`.
  - In `_fire_once`, replace the two `_expire_active_weapon(family.family_id)` calls with `return false` (and `pass` for the "fired and is_expired" branch — the shot already landed; just don't expire).
  - Remove `func _expire_active_weapon(...)` entirely.
  - After any path that mutates `active_weapon.current_energy` (`_fire_once`, `apply_chip_pickup`, `apply_fuel_cell_pickup`), invoke a private `_check_silent_resumed_edge()` that compares the current `active_weapon.current_energy <= 0.0` to `_was_empty_last_tick` and emits/prints the appropriate edge signal. Update `_was_empty_last_tick` at the end of the check.
  - `equip(family)` resets `_was_empty_last_tick = false` since the freshly equipped weapon starts at `max_energy`. The first fire that drains to zero will then correctly emit `typed_weapon_silent`.
  - The `apply_chip_pickup` different-family branch already calls `equip(family)` — the `_was_empty_last_tick` reset is automatic. After the swap the silent/resumed cache is correct.
- **`src/ui/hud.gd`.**
  - Remove `const EXPIRY_INACTIVE_DELAY := 0.35`, the `_typed_weapon_slot.connect("typed_weapon_expired", ...)` line, and `func _on_typed_weapon_expired(...)`.
  - The `_on_typed_weapon_energy_changed` handler already does the correct thing at zero energy when `max_energy > 0`: `set_energy(0, max)` keeps the bar empty with family tint. No new HUD code needed for the silent state.
  - **Minimum viable:** no connections to `typed_weapon_silent` / `typed_weapon_resumed`. Optional polish: connect to them for a brief desaturated pulse on silent and `flash_refill` on resumed. Implementer's choice within the slice — neither is required for acceptance.
- **`src/weapons/typed_weapon_family.gd`.**
  - Add `@export var letter_glyph := ""`.
- **`data/weapons/*.tres`.**
  - Edit each of the five family resources to set `letter_glyph` to the assigned letter. Use Godot's text editor or hand-edit the `.tres` `letter_glyph = "X"` lines if they already contain other property assignments.
- **`scenes/pickups/WeaponChip.tscn`.**
  - Add a `Label` child named `LetterGlyph` parented to the chip root (sibling of `Sprite2D`). Center-align horizontally and vertically. Position at the chip center. Size the label rect to cover the chip body. Set a font size such that a single character reads roughly 60-70% of the chip body's visual radius — `theme_override_font_sizes/font_size = 24` is a reasonable starting value with the default font (tune live).
  - Set `modulate = Color.WHITE` on the label.
- **`src/pickups/weapon_chip.gd`.**
  - In `_apply_family_tint` (rename to `_apply_family_identity` if the rename is cleaner; otherwise add a peer `_apply_letter_glyph`), after the existing sprite tint, also set:
    - `var label := get_node_or_null("LetterGlyph") as Label`
    - If `label != null and family != null:` `label.text = family.letter_glyph` and `label.visible = !family.letter_glyph.is_empty()`.
    - If `family == null` or label is missing, the label stays hidden / unchanged.
- **What not to touch in this slice.** `EnergyMeter` layout and color constants beyond what's already wired, `GridMeter`, `DefenseGrid`, `TypedWeapon`, the per-family tuning fields (`max_energy`, `firing_cost`, `fire_interval`, `projectile_damage`, `projectile_speed`, `archetype`, `spread_*`, `pierce`, `tint_color`), `WeaponChipCarrier`, `CarrierSpawner`, `FuelCellCarrier`, `FuelCellCarrierSpawner`, `BaselineEnemy`, `EliteEnemy`, `EnemyFormation`, `EnemySpawner`, projectile sprites, run-end overlay, pickup-burst visuals.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/persist-at-zero-clip.mp4` (or stills) — clip showing the player equipped with a typed weapon, draining the meter to `0` by firing, the HUD bar reading empty with the family tint still visible, the player holding the fire button at `0` with no projectiles produced and no error, then catching a fuel cell and the same family resuming fire. Confirms zero-energy persistence end-to-end.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/different-family-swap-at-zero-clip.mp4` (or stills) — clip showing the player at `0` energy holding family A, catching a chip of family B, and the slot swapping to B at full energy. Confirms the T011 different-family swap rule survives unchanged at zero.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/same-family-refill-at-zero-clip.mp4` (or stills) — clip showing the player at `0` energy holding family A, catching a chip of family A, and the slot refilling to full with the family unchanged. Confirms the T011 same-family refill rule survives unchanged at zero.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/chip-letter-vocabulary.png` — single composite still showing all 5 common-tier chips (S, P, H, R, D) side by side in the live playfield. Each chip's letter must be readable at gameplay framerate and the family tint must remain visible behind the letter.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/event-log.txt` — captured event log from a short live run showing at least one `typed_weapon_silent` line, at least one `typed_weapon_resumed` line, normal `typed_weapon_refilled` and `typed_weapon_partial_refilled` lines around the silent/resumed beats, and **zero** `typed_weapon_expired` lines (signal is retired).
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/persist-verification.txt` — output of the verifier script. Must end in `PERSIST_AT_ZERO_VERIFICATION_OK`.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] At `0` energy with a typed weapon equipped, the HUD energy bar reads empty but the family tint and stylebox are still visible. The bar does not transition to a "no weapon" empty state.
- [ ] At `0` energy, holding the fire input produces no typed projectiles. No errors, no warnings.
- [ ] The pea shooter continues to auto-fire at full cadence while the typed weapon is silent.
- [ ] Catching a same-family chip while at `0` energy refills the meter to full and resumes firing. The family is unchanged.
- [ ] Catching a different-family chip while at `0` energy swaps to the new family at full energy. The previous (empty) family is lost as designed; this matches the T011 swap rule.
- [ ] Catching a fuel cell while at `0` energy restores `fuel_cell_refill_fraction * max_energy` (currently 30%) and resumes firing. The family is unchanged.
- [ ] All five common-tier chips display their assigned letter (S / P / H / R / D) centered on the chip body in a contrasting color. The family tint is still visible behind the letter. A reviewer can identify the family from the letter alone at gameplay framerate.
- [ ] The carrier hull is unchanged — letters do not appear on the carrier, only on the chip after the carrier drops it.
- [ ] The event log shows one `typed_weapon_silent` line per zero-edge transition and one `typed_weapon_resumed` line per refill back above zero. No `typed_weapon_expired` lines are present in the log.
- [ ] No regressions: pea-shooter fire, baseline enemy descent, elite enemy descent, fuel-cell carrier behavior, weapon-chip carrier cadence, Defense Grid leak path, EnergyMeter / GridMeter layout, run-end overlay, T020 grid alignment.
- [ ] CLAUDE.md "Energy is dual-role" invariant has been updated to match the 2026-05-22 design log entry.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_persist_at_zero.gd` output ends in `PERSIST_AT_ZERO_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/verify_persist_at_zero.gd > tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/persist-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/capture_live_persist_evidence.gd > tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/live-capture.txt
git status > tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/git-status.txt
```

Visual evidence (the four clips, the chip-letter composite still) is produced from the live `Main.tscn` scene tree by `capture_live_persist_evidence.gd`. The capture script may force-equip families, force-set `current_energy` to a known fraction (including `0.0`), and force-spawn chips of specified families at known positions to make each clip deterministic. The chip-letter composite is captured by spawning one chip of each of the five families at fixed positions and taking a single frame.

The verifier script `verify_persist_at_zero.gd` must exercise (at minimum):

1. `TypedWeaponSlot` equipped with family A at `current_energy = full` fires repeatedly until `current_energy == 0`. After the last fire: assert `slot.has_weapon() == true`, `slot.current_family_id() == "A"`, and `typed_weapon_silent("A")` was emitted exactly once across the drain.
2. Same slot at `current_energy == 0` receives a `_fire_once` call (or simulates `Input.is_action_pressed`). Assert no projectile is spawned, no error is raised, `active_weapon` is still non-null, and `current_family_id() == "A"`.
3. Same slot at `current_energy == 0` receives `apply_chip_pickup(family_A)`. Assert `current_energy == max_energy`, `typed_weapon_refilled("A")` fired exactly once, `typed_weapon_resumed("A")` fired exactly once, and `slot.current_family_id() == "A"`.
4. Same slot drained back to `0`, then receives `apply_chip_pickup(family_B)` with B ≠ A. Assert `slot.current_family_id() == "B"`, `current_energy == max_energy` (of B), `chip_pickup_applied("B", true)` fired exactly once. The `typed_weapon_resumed` signal is **expected** to fire on the swap as well, because the new family starts above zero.
5. Same slot drained back to `0`, then receives `apply_fuel_cell_pickup()`. Assert `current_energy == 0.30 * max_energy` (within tolerance), `typed_weapon_partial_refilled` fired with the actual restored amount, and `typed_weapon_resumed` fired exactly once. The family is unchanged.
6. `TypedWeaponSlot.typed_weapon_expired` is **not** a defined signal on the slot (`has_signal("typed_weapon_expired") == false`). The signal has been retired.
7. The five `.tres` weapon-family resources each have `letter_glyph` set to their assigned letter (`"S"`, `"P"`, `"H"`, `"R"`, `"D"`).
8. A `WeaponChip` instantiated with each of the five families has a visible, non-empty `LetterGlyph` label whose `text` matches the family's `letter_glyph`. A `WeaponChip` instantiated with no family (or a family whose `letter_glyph` is empty) has `LetterGlyph.visible == false`.
9. Prints `PERSIST_AT_ZERO_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-22 | Created and activated. Pre-flight Q&A with user resolved the three opinion gaps the design log left open for this tuning pass: **different-family swap at zero energy** keeps the existing T011 rule (swap to new family at full), preserving the "do I commit to my current family?" decision unchanged. **Letter placement** is **chip-only** in v1 (carrier stays tint-only); minimal sprite work, the carrier already telegraphs family well enough from across the playfield. **Per-family letters** use the role-letter convention `S` (Wide Spread) / `P` (Piercing Lance) / `H` (Heavy Slug) / `R` (Rapid Stream) / `D` (debug_plasma). The 2026-05-22 design log entries for "Typed weapon persists at zero energy" and "Weapon-chip readability via stylized family-letter glyph" were written before this task to lock the decisions in the canonical log. |
| 2026-05-22 | Implemented zero-energy family persistence, retired the `typed_weapon_expired` signal and HUD expiry timeout, added `typed_weapon_silent` / `typed_weapon_resumed` edge logging, added common-tier chip letter glyphs, and updated the CLAUDE.md energy invariant. Added T021 verifier and live evidence capture scripts. Evidence generated under `tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs/`; `verify_persist_at_zero.gd`, focused T010/T011/T013 regressions, and headless smoke pass. |
| 2026-05-22 | Reran T021 verifier, headless smoke, and live evidence capture; all exited 0. Added an append-only design-log clarification retiring `typed_weapon_expired` outright for v1 so `decisions.md` matches the task acceptance criteria and verifier. |
| 2026-05-23 | Human reviewer approved T021 evidence. Moved task to completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
