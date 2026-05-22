# Ramp density curve

| t (s) | elite_chance | elites / slots | observed density |
|---:|---:|---:|---:|
| 0 | 0.00 | 0 / 15 | 0.00 |
| 30 | 0.07 | 0 / 15 | 0.00 |
| 60 | 0.13 | 1 / 15 | 0.07 |
| 90 | 0.20 | 2 / 15 | 0.13 |
| 150 | 0.20 | 4 / 15 | 0.27 |

Event-log snippet:

```text
ramp_sample t=0 elite_chance=0.00 elites=0 slots=15 density=0.00
ramp_sample t=30 elite_chance=0.07 elites=0 slots=15 density=0.00
ramp_sample t=60 elite_chance=0.13 elites=1 slots=15 density=0.07
elite_spawned slot_row=0 slot_col=4 formation_age=60.00 elite_chance=0.13
ramp_sample t=90 elite_chance=0.20 elites=2 slots=15 density=0.13
elite_spawned slot_row=0 slot_col=2 formation_age=90.00 elite_chance=0.20
elite_spawned slot_row=1 slot_col=4 formation_age=90.00 elite_chance=0.20
ramp_sample t=150 elite_chance=0.20 elites=4 slots=15 density=0.27
elite_spawned slot_row=0 slot_col=3 formation_age=150.00 elite_chance=0.20
elite_spawned slot_row=1 slot_col=0 formation_age=150.00 elite_chance=0.20
elite_spawned slot_row=1 slot_col=2 formation_age=150.00 elite_chance=0.20
elite_spawned slot_row=2 slot_col=1 formation_age=150.00 elite_chance=0.20
```
