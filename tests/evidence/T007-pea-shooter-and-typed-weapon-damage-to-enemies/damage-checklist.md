# T007 Damage Checklist

- [x] Pea bullets that intersect a baseline enemy deal `1.0` damage and are freed on contact. After 5 pea hits, the enemy dies.
- [x] Typed-weapon projectiles deal `3.0` damage per hit and are freed on contact. After 2 typed hits, a fresh baseline enemy dies.
- [x] Each landed hit spawns a small floating damage number at the hit position that drifts upward and fades over about `0.4s`. The numeric value matches the damage dealt.
- [x] When a baseline enemy is killed, a small `10`-fragment pixel burst plays at the death position for about `0.2s`. The enemy node is queued for free immediately.
- [x] Formation survivors are not re-packed. When killed children are freed, remaining enemies continue descending under the same formation transform.
- [x] Enemies that survive and reach the bottom still despawn silently with no Grid effect, no run-end, and no feedback.
- [x] The player ship still passes through enemies without consequence.
- [x] The energy meter, HUD, pea-shooter cadence, formation descent speed, and spawner cadence are unchanged versus T006.
- [x] `pea_bullet.gd` carries exported `damage = 1.0`; `typed_projectile.gd` reads damage from its family resource; `TypedWeaponFamily.projectile_damage` and `debug_plasma.tres` are `3.0`; `BaselineEnemy.max_hp` is `5.0`.
- [x] No level-keyed damage scaling, rarity tiers, crit handling, AOE, or pierce behavior were introduced.
- [x] Headless smoke exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [x] No carriers, pickups, enemy bullets, Defense Grid meter, or run-end were introduced.
