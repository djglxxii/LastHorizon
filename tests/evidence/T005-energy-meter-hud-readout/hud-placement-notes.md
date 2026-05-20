# T005 HUD Placement Notes

The energy meter is anchored inside the playable field at `x=155..385`, `y=926..956`, below the player ship and shield glow with a small bottom margin. This keeps the dual-role energy state in the player's defensive band while placing it as low as possible without clipping against the viewport edge.

The tradeoff is that the meter is farther from the projectile stream than the first pass, but it no longer competes with the ship/shield silhouette and still avoids the future side-panel space.
