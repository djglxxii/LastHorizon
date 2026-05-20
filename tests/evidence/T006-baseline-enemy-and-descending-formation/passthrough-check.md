# T006 Passthrough Check

- Pea bullets and typed-weapon projectiles have no collision or damage path to enemies in T006. `BaselineEnemy` exposes `max_hp`, but no damage handling method or HP decrement exists yet.
- Enemies have no collision shape and no callbacks. Player movement is unchanged, so the player can pass through enemy positions without stop, bounce, damage, or energy loss.
- This is intentional task scope. T007 adds projectile damage to enemies; T015 adds player/enemy collision response.
