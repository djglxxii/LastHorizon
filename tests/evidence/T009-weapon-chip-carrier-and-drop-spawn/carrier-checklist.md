# T009 Reviewer Checklist

- [x] Run start has no typed weapon equipped; EnergyMeter renders empty in `boot-no-weapon.png`.
- [x] Weapon-chip carriers spawn on a timer by `CarrierSpawner` with default `spawn_interval_seconds = 8.0`.
- [x] Carrier entry side alternates left/right per spawn for deterministic coverage.
- [x] Carrier sprite is a distinct cargo/chip ship, not the baseline enemy sprite.
- [x] Carrier sweeps horizontally with vertical sine sway and exits silently with no Grid damage (`carrier-sweep-*`, `live-capture.txt`).
- [x] Carrier HP is `2.0`: two pea hits at `1.0` damage or one debug plasma hit at `3.0` damage kills it.
- [x] Carrier death spawns a chip and the existing enemy kill burst (`carrier-kill-drops-chip-*`).
- [x] Chip drifts downward with large horizontal sway and no magnetism (`chip-sweep-and-collect-*`).
- [x] Chip expiry at the planet line is silent and does not debit the Grid (`chip-expires-at-planet-line-*`, `live-capture.txt`).
- [x] Chip collection plays a distinct pickup burst and fills the EnergyMeter (`chip-sweep-and-collect-03-energy-full.png`).
- [x] First chip catch equips `debug_plasma`; later catches refill the current `debug_plasma` family (`carrier-verification.txt`).
- [x] Formation descent, GridMeter, EnergyMeter layout, pea shooter, projectile damage, and run-end overlay are unchanged. User-approved tuning updates after review: baseline enemy HP was reduced from `5.0` to `2.5`, and `debug_plasma` firing cost was reduced from `5.0` to `1.0`.
- [x] No enemy fire, player collision response, fuel-cell carrier, repair carrier, audio, screen shake, or HUD additions were introduced.
- [x] Headless smoke prints `LAST_HORIZON_BOOT_SMOKE_OK` (`headless-smoke.txt`).
- [x] Headless verifier prints `CARRIER_VERIFICATION_OK` (`carrier-verification.txt`).
