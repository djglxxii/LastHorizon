# No Flash On First Equip

Verified by `verify_refill_swap.gd`.

The first pickup from an empty `TypedWeaponSlot` equips `common_wide_spread` at full energy and emits `chip_pickup_applied("common_wide_spread", true)`. It does not emit `typed_weapon_refilled`, so the HUD refill flash is not triggered on first equip.

