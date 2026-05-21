# T011 — Same-Family Refill / Different-Family Swap-at-Full

| Field | Value |
|---|---|
| ID | T011 |
| State | completed |
| Phase | M4 — Weapon pickups |
| Depends on | T010 |
| Plan reference | `docs/PLAN.md` — M4 |

## Goal

Close the T010 boundary: replace `TypedWeaponSlot.apply_chip_pickup()`'s "always refill when equipped" behavior with the 2026-05-19 committed semantics — **same-family pickups refill the meter to full; different-family pickups swap to the new family at full energy**. The previous family's remaining energy is discarded on swap. The same-family refill case gets a legible HUD flash so the no-state-change is visible; the swap case snaps with no extra HUD treatment (the projectile-pattern change is the readability). This is the load-bearing slice that makes the energy economy decision the design log assumed: "stick with what's working" versus "commit to a new tool."

## Scope

- **In scope:**
  - **`TypedWeaponSlot.apply_chip_pickup(family)` branch logic.** Replace the body of the `active_weapon != null` branch with a family-id comparison:
    - If `active_weapon == null` → `equip(family)`, emit `chip_pickup_applied(family.family_id, true)`. (Unchanged from T010.)
    - If `active_weapon != null` and `family.family_id == active_weapon.family.family_id` → refill `current_energy` to `max_energy`, emit `typed_weapon_energy_changed(...)`, emit `chip_pickup_applied(family.family_id, false)`, emit new `typed_weapon_refilled(family.family_id)`. **Do not** re-instantiate the `TypedWeapon`; preserve the existing instance so any future per-instance state (none today, but the door stays open) is not silently reset.
    - If `active_weapon != null` and `family.family_id != active_weapon.family.family_id` → swap: discard the current `TypedWeapon` (its remaining energy is intentionally lost), `equip(family)` (which constructs a fresh `TypedWeapon` at `max_energy`), emit `chip_pickup_applied(family.family_id, true)`. Do **not** emit `typed_weapon_refilled` on swap — the refill signal is the same-family-only beat.
  - **`chip_pickup_applied(family_id, granted_new_family)` payload semantics.** The boolean now strictly means "the active family is different than it was before this pickup." Same-family refill → `false`. Different-family swap → `true`. First equip from no weapon → `true`. This is a behavior change relative to T010, where any pickup-while-equipped emitted `false`. Document the change in the Progress log; the T009/T010 verifiers' expectations of the third case need an update (see Verifier updates below).
  - **New `typed_weapon_refilled(family_id: String)` signal on `TypedWeaponSlot`.** Fires only on the same-family refill case (not on first equip, not on swap). HUD listens on this and runs a brief refill flash. Keeping this as a dedicated signal — rather than overloading `chip_pickup_applied` with a "was refill" param — keeps each signal's meaning singular and makes future audio/VFX hooks trivial.
  - **`EnergyMeter.flash_refill()` method.** Briefly pulses the bar's fill and border to a brighter accent color, then restores the normal style after ~0.25 s. Implementation: introduce two constants `REFILL_FLASH_FILL` (a near-white cyan-leaning accent, e.g. `Color(0.78, 1.0, 0.98, 1.0)`) and `REFILL_FLASH_BORDER` (a brighter cyan than `ACTIVE_BORDER`, e.g. `Color(0.62, 1.0, 1.0, 1.0)`). The method overrides those stylebox colors immediately, then awaits a `SceneTreeTimer` of `0.25` s and re-applies `set_energy(current, max)` to restore the normal active style. If `set_energy` is called again during the flash (e.g., the player fires and drains the bar), let it overwrite — the most-recent state wins; no need to cancel the pending timer because the restoration call is idempotent against the current values. The 0.25 s figure is a starting point; the load-bearing constraint is that the flash is unmistakably visible at gameplay framerate and does not bleed into the next typed-weapon shot.
  - **HUD wiring.** `src/ui/hud.gd` connects to the new `typed_weapon_refilled` signal and forwards to `_energy_meter.flash_refill()`. No layout changes. No new HUD nodes.
  - **No new pickup-burst variants.** The existing `pickup_burst` already fires on chip collect (T009); it stays as-is and is the "the chip was caught" beat regardless of whether the result is first-equip, refill, or swap. The flash is HUD-only.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. The new signal wiring, branch logic, and `flash_refill` method must load and run cleanly headless.

- **Out of scope:**
  - **Per-rarity behavior, rare and legendary tier weapons.** M4 ships common-only per `tasks/INDEX.md`; rarity-aware pickup logic is post-v1.
  - **Audio cues for refill or swap.** No audio system in v1.
  - **Held-family lock / "are you sure?" before swap.** The design log explicitly chose snap-swap (2026-05-19); no confirmation prompt.
  - **Discard animation for the lost energy on swap.** Decision is instant; old energy disappears in the same frame the new family equips.
  - **Animated fill-up to max on refill.** The bar snaps to max; the flash is the readability, not a value tween.
  - **Family-tinted HUD borders.** EnergyMeter does not adopt the family's `tint_color`. Family identity is read from the projectile pattern and the chip/carrier tint, not the HUD.
  - **A 'SWAP' or 'REFILL' floating text label.** Considered and rejected during pre-flight Q&A in favor of a meter-only flash plus snap-swap.
  - **Changes to the drop pool, carrier sweep / sway, chip drift, spawn cadence, baseline enemy behavior, formation descent, Defense Grid, pea shooter, run-end overlay.** None of those are touched.
  - **Tuning iteration on the 5 family resources.** Tuning belongs to M7.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [x] T010 accepted; the 5-family drop pool, carrier/chip tint, archetype-aware firing, and the always-refill placeholder in `apply_chip_pickup` are at HEAD.
- [x] Re-read 2026-05-19 "Same-family pickup refills energy; different-family swaps at full" — confirm: same-family ⇒ full refill, no swap, no other state change; different-family ⇒ swap at full, previous family's remaining energy discarded. Confirm the HUD-feedback implication ("must clearly signal 'your meter just refilled, no swap'") is owned by this task.
- [x] Re-read 2026-05-19 "Remove weapon levels" — confirm the swap semantics here are pure tool-choice, not power-loss. Discarding the previous family's energy is the only cost; there is no level loss to model.
- [x] Re-read 2026-05-16 "Per-weapon-family firing cost" — confirm the refill case must reset to the **new family's** `max_energy` in the swap branch, not blindly carry forward the previous family's max. (Because `equip(family)` constructs a fresh `TypedWeapon` whose `max_energy` comes from the new family's resource, this is automatic — but it is the load-bearing reason we re-`equip` rather than just refilling and reassigning.)
- [x] Re-read 2026-05-16 "Auto-fire pea shooter; typed-weapon energy doubles as shield and ammo" — confirm: when the player picks up a different-family chip while holding a near-empty meter, they are effectively trading a near-spent shield for a full one of a different family. That is the intended texture. No special-casing for low-energy swaps.
- [x] Re-read the T010 task file's "out of scope" note that explicitly defers swap-branch logic to T011 — confirm T011 is the agreed slice for it and there are no carry-over concerns.
- [x] Grep for callers of `apply_chip_pickup` and consumers of `chip_pickup_applied` before changing payload semantics. Expected callers: `WeaponChip._try_collect_from` (no change needed; calls with the chip's family). Expected listeners: any verifier scripts under `tests/evidence/T009-.../` and `tests/evidence/T010-.../` that assert specific `granted_new_family` values for the "while equipped, different family" path will need updating to expect `true` (was `true` for first equip, `false` for any-while-equipped under T010; under T011 it is `true` for swap and `false` only for same-family refill).

## Implementation notes

- **Branch ordering in `apply_chip_pickup`.** Check the `null` case first (first equip), then the same-family case (refill), then fall through to the swap case. This ordering makes the most common runtime path (refill or swap while already equipped) fast and keeps the source readable.
- **Family identity comparison.** Use `family.family_id == active_weapon.family.family_id` rather than identity-comparing the `TypedWeaponFamily` resource pointer. Resource pointer equality would fail across editor reloads or if a family is duplicated into a variant `.tres`; `family_id` is the stable identity carried by every resource. Push a `push_warning` once if either side of the comparison is empty string (defensive — a malformed `.tres` would otherwise route into the refill branch by accident).
- **`equip(family)` is the swap implementation.** Calling `equip(new_family)` already constructs a fresh `TypedWeapon`, resets `_time_until_next_shot`, and emits `typed_weapon_energy_changed` with the new family's max. Reusing `equip` keeps the swap path consistent with first-equip semantics and means no new code path can drift from `equip`. The signal emission for the swap case happens after `equip` and emits `chip_pickup_applied(family.family_id, true)` directly.
- **`typed_weapon_refilled` emission order.** Emit `typed_weapon_energy_changed` first (so HUD sees the bar at max), then `chip_pickup_applied`, then `typed_weapon_refilled`. The flash fires last so the bar is already visually at max when the flash starts; a flash that arrives before the value update would look like a glitch.
- **`EnergyMeter.flash_refill()` timer.** Use `get_tree().create_timer(0.25)` and `await timer.timeout`. If the meter is freed during the flash, the `await` resumes against a freed instance — guard with `if !is_inside_tree(): return` after the await before applying styles. Do not store a member `Timer` node for this; the lightweight one-shot pattern is enough.
- **Restoring the normal style after the flash.** Re-invoke `set_energy(current_energy, max_energy)` using the bar's current `value` and `max_value` instead of caching the original colors. That way, if the bar dropped during the flash (e.g., the player fired), the restored style matches the current ratio (e.g., the LOW_FILL color if the bar is now ≤ 25 %). Reading `_bar.value` and `_bar.max_value` directly is simplest.
- **Signal naming consistency.** `typed_weapon_refilled` mirrors the existing `typed_weapon_fired` / `typed_weapon_expired` / `typed_weapon_energy_changed` family-name prefix on `TypedWeaponSlot`. Don't shorten to `refilled` — keep the prefix.
- **What not to touch in this slice.** EnergyMeter HUD layout, color constants for the non-flash states (`ACTIVE_FILL`, `LOW_FILL`, `EMPTY_BACKGROUND`, etc.), GridMeter, DefenseGrid leak path, baseline enemy HP/descent, formation spawner cadence, pea shooter, carrier sweep speed/sway/spawn interval (which T010 left at 20.0 — leave it), chip drift speed/sway, pickup burst visuals, run-end overlay, the 5 family resources, projectile sprites, archetype firing logic.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/same-family-refill-clip.mp4` (or stills) — clip showing the player holding one family (e.g., Wide Spread), catching a chip of the **same** family while the meter is partially drained, and the meter snapping to full with a visible flash. The equipped family must remain Wide Spread before and after; the projectile pattern is unchanged.
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/different-family-swap-clip.mp4` (or stills) — clip showing the player holding one family (e.g., Heavy Slug at partial energy), catching a chip of a **different** family (e.g., Rapid Stream), and the meter snapping to the new family's max with the projectile pattern visibly changing to Rapid Stream on the next trigger pull.
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/swap-discards-energy.md` — short note confirming that, on a different-family swap, the previous family's remaining energy is discarded (the new meter reads the new family's `max_energy`, not the old family's remaining + new family's max).
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/no-flash-on-first-equip.md` — short note confirming the refill flash does **not** fire on the first chip catch from the no-weapon state. (First equip is a distinct beat; the flash is the same-family beat.)
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/no-flash-on-swap.md` — short note confirming the refill flash does **not** fire on a different-family swap. (The snap is the only feedback; the flash would mislead the player into reading the swap as a refill.)
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/refill-swap-verification.txt` — output of the verifier script. Must end in `REFILL_SWAP_VERIFICATION_OK`.
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/headless-smoke.txt` — rerun of `tools/run_headless_smoke.sh`; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T011-same-family-refill-different-family-swap-at-full/git-status.txt` — `git status` after the work, confirming no generated Godot/editor state slipped in.

**Reviewer checklist:**

- [ ] Catching a chip of the **same** family as the held weapon refills the meter to that family's `max_energy`, does **not** change the equipped family, and produces a visible HUD flash on the EnergyMeter. The projectile pattern after the pickup is identical to before.
- [ ] Catching a chip of a **different** family while equipped swaps to the new family at the new family's `max_energy`, with no HUD flash. The previous family's remaining energy is discarded — the new meter reads the new family's `max_energy`, not a carried-forward partial. The projectile pattern, sprite, and tint on the next trigger pull match the new family.
- [ ] First chip catch from the no-weapon state equips the rolled family at full energy with **no** refill flash — first equip is its own beat.
- [ ] `chip_pickup_applied(family_id, granted_new_family)` payload semantics are correct: `true` on first equip, `false` on same-family refill, `true` on different-family swap.
- [ ] `typed_weapon_refilled(family_id)` fires only on the same-family refill case and only with the held family's id.
- [ ] The refill flash is visible at gameplay framerate and does not bleed past the next typed-weapon shot. If the player drains the bar during the flash, the bar's color returns to the appropriate ratio-based style (`LOW_FILL` if ≤ 25 %, etc.) after the flash, not to the active full-color style.
- [ ] No changes to baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter layout, the 5 family resources, projectile sprites/tints, pea-shooter behavior, carrier sweep speed/sway/spawn interval (still 20.0 s from the T010 review), chip drift speed/sway, pickup burst, or run-end overlay.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_refill_swap.gd` output ends in `REFILL_SWAP_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T011-same-family-refill-different-family-swap-at-full/verify_refill_swap.gd > tests/evidence/T011-same-family-refill-different-family-swap-at-full/refill-swap-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T011-same-family-refill-different-family-swap-at-full/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T011-same-family-refill-different-family-swap-at-full/capture_live_refill_swap_evidence.gd > tests/evidence/T011-same-family-refill-different-family-swap-at-full/live-capture.txt
git status > tests/evidence/T011-same-family-refill-different-family-swap-at-full/git-status.txt
```

Visual evidence (`same-family-refill-clip.mp4`, `different-family-swap-clip.mp4`) is produced from the live `Main.tscn` scene tree by `capture_live_refill_swap_evidence.gd`. The capture script may force-equip a known family and force-spawn a same-family then different-family chip in succession to make each clip deterministic, mirroring the T009/T010 capture approach.

The verifier script `verify_refill_swap.gd` must exercise (at minimum):

1. A `TypedWeaponSlot` starts with no weapon. `apply_chip_pickup(family_A)` → asserts the slot equips family_A, `chip_pickup_applied("A", true)` fired exactly once, and `typed_weapon_refilled` did **not** fire.
2. With family_A equipped at partial energy, `apply_chip_pickup(family_A)` → asserts the slot still has family_A, `current_energy == max_energy`, `chip_pickup_applied("A", false)` fired exactly once, and `typed_weapon_refilled("A")` fired exactly once.
3. With family_A equipped at partial energy (say 30 % of family_A's max), `apply_chip_pickup(family_B)` → asserts the slot now has family_B, `current_energy == family_B.max_energy` (not family_A's partial + family_B's max; not family_A's remaining at all), `chip_pickup_applied("B", true)` fired exactly once, and `typed_weapon_refilled` did **not** fire.
4. Same as case 3 but family_A and family_B have **different** `max_energy` values, to confirm the new meter is the new family's max and not a stale value. (Recommend using the existing `common_heavy_slug` and `common_rapid_stream` resources; if both ship the same `max_energy = 100.0` today, the assertion is on the `family_id` swap, not the value.)
5. Prints `REFILL_SWAP_VERIFICATION_OK` and exits 0.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-21 | Created and activated. Pre-flight Q&A with user resolved the three opinion gaps the design log left open: same-family refill uses an EnergyMeter flash-only treatment (no floating label); different-family swap snaps with no extra HUD effect; discarded energy on swap is instant (no drain animation). T011 is the slice that closes the T010 boundary on swap-branch logic. |
| 2026-05-21 | Implemented the refill/swap branch. `chip_pickup_applied(family_id, granted_new_family)` now means the active family changed: first equip and different-family swap emit `true`, same-family refill emits `false`. Added `typed_weapon_refilled(family_id)` for the same-family-only HUD flash, wired HUD to `EnergyMeter.flash_refill()`, and updated the T010 verifier's mismatch-pickup compatibility expectation to the new T011 swap semantics. |
| 2026-05-21 | Acceptance evidence is ready under `tests/evidence/T011-same-family-refill-different-family-swap-at-full/`. `refill-swap-verification.txt` ends in `REFILL_SWAP_VERIFICATION_OK`; `headless-smoke.txt` ends in `LAST_HORIZON_BOOT_SMOKE_OK`; `live-capture.txt` regenerated the same-family refill flash and different-family swap stills. Stop here for human review per the task workflow. |
| 2026-05-21 | Human review accepted T011. Moved the task to `docs/tasks/completed/` and marked it completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
