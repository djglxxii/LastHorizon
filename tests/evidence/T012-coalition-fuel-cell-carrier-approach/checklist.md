# T012 Checklist

- [x] Fuel-cell carriers spawn on a 30 s cadence, with first spawn after the full first interval.
- [x] Carrier launches from below the bottom edge, reaches about mid-screen, then descends slowly with gentle sway.
- [x] Carrier exits through the bottom if ignored and does not damage the Defense Grid.
- [x] Direct player contact during descent consumes the carrier and plays the reused pickup burst.
- [x] EnergyMeter is unchanged on collection; partial refill is deferred to T013.
- [x] Pea bullets and typed projectiles pass through without damaging the carrier or despawning early.
- [x] Fuel-cell carrier sprite is visually distinct from the weapon-chip carrier at gameplay scale.
- [x] New signals are limited to `fuel_cell_carrier_spawned(position)` and `fuel_cell_collected(spawn_position)`.
- [x] Weapon-chip carrier cadence, chip behavior, enemy behavior, HUD layout, Defense Grid behavior, and projectile behavior are unchanged.
- [x] Headless smoke prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [x] `verify_fuel_cell_carrier.gd` output ends in `FUEL_CELL_VERIFICATION_OK`.
