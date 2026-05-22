# Zero elites at run start

The t=0 ramp sample uses `EnemySpawner.current_elite_chance()` before any run age has accumulated.

```text
t=0 elite_chance=0.00 elites=0 slots=15
```

Opening formations therefore spawn as pure baseline blocks until the ramp has a non-zero chance to roll elites.
