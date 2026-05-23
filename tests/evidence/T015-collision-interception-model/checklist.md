# T015 reviewer checklist

- [x] Full-energy baseline and elite collisions drain enemy HP worth of typed-weapon energy, consume the enemy, and do not damage the Grid when energy covers HP.
- [x] Partial-energy elite collision drains the remaining 5 energy to 0, consumes the elite, and applies exactly 15 collision damage to the Grid.
- [x] Zero-energy baseline contact does not consume the enemy; it later leaks for the full 10 Grid damage.
- [x] Zero-energy elite contact does not consume the enemy; it later leaks for the full 40 Grid damage.
- [x] Cluster contact resolves at most one collision per 0.15 s cooldown window and logs `collision_cooldown_suppressed`.
- [x] Collision feedback is visible as ship flash, camera shake, and energy-meter collision flash.
- [x] Collision consumes through `consume_for_collision`; projectile `take_damage`, killed, and leaked paths remain separate.
- [x] T021 zero-energy persistence remains the gate: `current_energy() > 0.0` intercepts, `has_weapon()` is not used as the collision gate.
- [x] `CLAUDE.md` and `docs/design/decisions.md` contain the superseding no-cap collision wording.
- [x] `verify_collision.gd` ends in `COLLISION_VERIFICATION_OK`.
