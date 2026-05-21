# Equip From Empty, Each Family

`verify_weapon_pool.gd` applies one chip for each of the five families to a fresh `TypedWeaponSlot` with `active_weapon == null`.

Result:

- `debug_plasma` equips at full energy and emits `granted_new_family=true`.
- `common_wide_spread` equips at full energy and emits `granted_new_family=true`.
- `common_piercing_lance` equips at full energy and emits `granted_new_family=true`.
- `common_heavy_slug` equips at full energy and emits `granted_new_family=true`.
- `common_rapid_stream` equips at full energy and emits `granted_new_family=true`.

The live stills show the expected projectile behavior once equipped: `wide-spread-clip.png`, `piercing-lance-clip.png`, `heavy-slug-clip.png`, and `rapid-stream-clip.png`.
