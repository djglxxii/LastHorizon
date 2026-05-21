# Swap Discards Energy

Verified by `verify_refill_swap.gd`.

- Heavy Slug was equipped at 30% energy.
- Picking up Rapid Stream swapped the active family to `common_rapid_stream`.
- The resulting meter used Rapid Stream's `max_energy`, not Heavy Slug's remaining energy.
- A synthetic check with `verify_family_a.max_energy = 40.0` and `verify_family_b.max_energy = 125.0` confirmed the swap resets to the new family's max (`125.0`).

