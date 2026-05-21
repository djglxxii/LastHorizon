# Refill Ignores Family In T010

This is the intentional T010/T011 boundary.

`verify_weapon_pool.gd` equips `common_heavy_slug`, lowers its energy to `10`, then applies a `common_rapid_stream` chip. The slot keeps `common_heavy_slug`, refills Heavy Slug to full energy, and emits `chip_pickup_applied("common_heavy_slug", false)`.

T011 owns the different-family swap-at-full behavior.
