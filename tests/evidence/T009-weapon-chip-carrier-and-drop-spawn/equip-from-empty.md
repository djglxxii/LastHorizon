# Equip From Empty

Evidence:

- `boot-no-weapon.png` shows the run start state with the EnergyMeter empty (`-- / --`) and only the pea shooter active.
- `chip-sweep-and-collect-03-energy-full.png` shows the first collected chip filling the EnergyMeter to `100 / 100`.
- `carrier-verification.txt` exercises `TypedWeaponSlot.apply_chip_pickup()` from `active_weapon == null` and verifies `debug_plasma` is equipped at full energy with `granted_new_family=true`.

Result: the T004 debug bootstrap is removed. The first successful chip catch is what grants the typed weapon.
