# T011 Reviewer Checklist

- [x] Catching a chip of the same family as the held weapon refills the meter to that family's `max_energy`, does not change the equipped family, and produces a visible HUD flash on the EnergyMeter.
- [x] Catching a chip of a different family while equipped swaps to the new family at the new family's `max_energy`, with no HUD flash.
- [x] The previous family's remaining energy is discarded on swap; the new meter reads the new family's `max_energy`.
- [x] First chip catch from the no-weapon state equips the rolled family at full energy with no refill flash.
- [x] `chip_pickup_applied(family_id, granted_new_family)` payload semantics are correct: `true` on first equip, `false` on same-family refill, `true` on different-family swap.
- [x] `typed_weapon_refilled(family_id)` fires only on the same-family refill case and only with the held family's id.
- [x] The refill flash is visible at gameplay framerate. If the bar changes during a flash, `EnergyMeter.flash_refill()` restores styling from the current bar value via `set_energy(_bar.value, _bar.max_value)`.
- [x] No changes were made to baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter layout, the 5 family resources, projectile sprites/tints, pea-shooter behavior, carrier sweep speed/sway/spawn interval, chip drift speed/sway, pickup burst, or run-end overlay.
- [x] Headless smoke exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [x] `verify_refill_swap.gd` output ends in `REFILL_SWAP_VERIFICATION_OK`.

