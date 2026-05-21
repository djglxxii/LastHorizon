# Family Roster

Chip color readout: `chip-color-roster.png`.

| Family ID | Display name | Tint | Archetype | Energy | Cost | Interval | Speed | Damage | Projectile sprite |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| `debug_plasma` | Debug Plasma | `Color(0.30, 0.95, 1.00)` | Single | 100 | 1.0 | 0.10 | 760 | 3.0 | `typed-plasma-bolt.png` |
| `common_wide_spread` | Wide Spread | `Color(1.00, 0.62, 0.18)` | Spread, 3 shots, 24 deg | 100 | 2.0 | 0.18 | 640 | 1.0 | `wide-spread-shard.png` |
| `common_piercing_lance` | Piercing Lance | `Color(0.85, 0.30, 1.00)` | Pierce | 100 | 2.0 | 0.20 | 980 | 2.0 | `piercing-lance-bolt.png` |
| `common_heavy_slug` | Heavy Slug | `Color(1.00, 0.88, 0.28)` | Single | 100 | 6.0 | 0.45 | 560 | 8.0 | `heavy-slug-orb.png` |
| `common_rapid_stream` | Rapid Stream | `Color(0.55, 1.00, 0.30)` | Single | 100 | 0.7 | 0.05 | 880 | 0.6 | `rapid-stream-dart.png` |

All five families are loaded by `verify_weapon_pool.gd`; each has a non-empty ID, display name, positive max energy, non-zero tint, and loaded projectile sprite.
