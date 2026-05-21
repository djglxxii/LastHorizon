# T020 Regression Checklist

- [x] T006 formation descent still uses per-formation `EnemyFormation` blocks; bottom-exit cleanup remains owned by `EnemyFormation`.
- [x] T007 pea-shooter and typed-weapon damage paths were not changed.
- [x] T008 Defense Grid leak damage and run-end code were not changed.
- [x] T009 weapon-chip carrier spawning, chip drop, chip drift, and pickup burst code were not changed.
- [x] T010 common-tier weapon family resources, projectile sprites, projectile behavior, and chip/carrier tinting were not changed.
- [x] T011 same-family refill and different-family swap code paths were not changed.
- [x] `BaselineEnemy._physics_process` sway behavior was not changed; T020 only clamps the amplitude before `configure_sway`.
- [x] `EnemySpawner.descent_speed` remains `32.5`; T020 changes only `spawn_interval_seconds` and stagger placement.
- [x] No global-armada-grid refactor was introduced; `EnemySpawner` still spawns `EnemyFormation` instances.
