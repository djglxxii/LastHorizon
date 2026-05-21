# Refill While Equipped

Evidence:

- `carrier-verification.txt` calls `TypedWeaponSlot.apply_chip_pickup()` a second time after lowering active weapon energy.
- The verifier asserts the active family remains `debug_plasma`, energy returns to max, and `chip_pickup_applied` fires with `granted_new_family=false`.

Result: in T009, every chip is generic. Empty slot equips `debug_plasma`; an already-equipped slot refills the same family to full.
