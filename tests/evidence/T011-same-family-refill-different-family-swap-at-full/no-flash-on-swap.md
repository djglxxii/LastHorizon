# No Flash On Swap

Verified by `verify_refill_swap.gd` and the live capture.

A different-family pickup from Heavy Slug to Rapid Stream emits `chip_pickup_applied("common_rapid_stream", true)` and does not emit `typed_weapon_refilled`. The live `different-family-swap-clip.png` shows the meter in its normal active style after the swap, with the Rapid Stream projectile pattern visible.

