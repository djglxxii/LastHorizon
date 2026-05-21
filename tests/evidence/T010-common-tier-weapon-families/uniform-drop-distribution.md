# Uniform Drop Distribution

`verify_weapon_pool.gd` seeds the RNG and samples 100 `CarrierSpawner._spawn_carrier()` calls from the five-entry `weapon_pool`.

Observed counts:

| Family ID | Count |
|---|---:|
| `debug_plasma` | 23 |
| `common_wide_spread` | 13 |
| `common_piercing_lance` | 20 |
| `common_heavy_slug` | 22 |
| `common_rapid_stream` | 22 |

Each family appears, and no entry is structurally starved or dominant. The spread is normal sampling noise for uniform random selection over 100 rolls.
