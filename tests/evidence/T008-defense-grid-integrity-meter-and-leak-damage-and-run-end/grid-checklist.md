# T008 Grid Checklist

- [x] At run start, the EnergyMeter is legible at the bottom-left and the GridMeter is legible at the bottom-right in the same bottom band.
- [x] Initial Grid value reads `GRID 100 / 100` and the bar is full.
- [x] When a baseline enemy crosses the planet line, a planet-impact pixel burst plays at the crossing position. The burst uses a cooler palette than the T007 kill burst.
- [x] Each leak debits exactly `10.0` from the Grid. The bar flashes, tweens to the new value, and the numeric label updates.
- [x] A leaked enemy does not also spawn the T007 kill burst; a killed enemy does not debit the Grid.
- [x] After 10 leaks, the Grid reads `GRID 0 / 100`; the tree pauses, formations freeze, and the `DEFENSE GRID FAILED` overlay appears.
- [x] Pressing R on the overlay reloads the scene; the restart evidence shows Grid restored to `GRID 100 / 100` with a fresh armada descending.
- [x] Headless smoke exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [x] `verify_grid.gd` output ends in `GRID_VERIFICATION_OK` and shows `grid_failed` fires exactly once.
- [x] No enemy-fire system, collision response, Grid-repair pickups, score readout, audio, or screen shake were introduced.
- [x] T007 damage behavior still verifies: pea-shot kills take 5 hits, typed-weapon kills take 2 hits, damage numbers and kill bursts still spawn.
