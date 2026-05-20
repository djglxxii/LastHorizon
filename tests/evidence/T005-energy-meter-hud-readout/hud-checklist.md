# T005 HUD Checklist

- [x] Meter is visible during play and placed inside the main playfield.
- [x] Meter fill is proportional to `typed_weapon_slot.current_energy() / typed_weapon_slot.max_energy()`.
- [x] Holding typed-fire drops the meter at the debug plasma family's firing cost cadence.
- [x] Meter reaches empty when the typed weapon expires.
- [x] Meter transitions to an inactive dim state after expiry.
- [x] Pea shooter continues firing after typed-weapon expiry.
- [x] HUD is sourced from `TypedWeaponSlot` signals and methods; no parallel energy owner was added.
- [x] Refill behavior was not manually exercised because pickups/refill paths are not implemented until M4. The HUD will update on the existing `typed_weapon_energy_changed` signal when future equip/refill paths emit it.
- [x] No Defense Grid Integrity meter, weapon icon, family name, burn-rate indicator, rarity framing, side-panel content, or hit-drain visualization was added.
