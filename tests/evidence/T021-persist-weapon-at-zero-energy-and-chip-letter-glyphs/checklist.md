# T021 reviewer checklist

- [x] At `0` energy with a typed weapon equipped, the HUD energy bar reads empty but remains styled as a held weapon rather than `-- / --`.
- [x] At `0` energy, another fire input produces no typed projectiles and no errors.
- [x] The pea shooter remains available as the baseline offense while the typed weapon is silent.
- [x] Same-family chip at `0` refills to full and preserves the family.
- [x] Different-family chip at `0` swaps to the new family at full energy.
- [x] Fuel cell at `0` restores 30% energy and resumes typed fire.
- [x] All five common-tier chips show centered letters `S`, `P`, `H`, `R`, `D` while preserving tint.
- [x] Carrier hulls remain letter-free.
- [x] Event log includes `typed_weapon_silent` and `typed_weapon_resumed`, and has no `typed_weapon_expired` lines.
- [x] Headless smoke and `verify_persist_at_zero.gd` pass.
