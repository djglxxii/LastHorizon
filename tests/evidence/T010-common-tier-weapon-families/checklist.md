# T010 Reviewer Checklist

- [x] Five families exist in the drop pool: `debug_plasma`, `common_wide_spread`, `common_piercing_lance`, `common_heavy_slug`, `common_rapid_stream`.
- [x] Each `.tres` loads with expected tuning fields populated (`weapon-pool-verification.txt`).
- [x] Carriers entering the playfield are visibly tinted to the rolled family (`carrier-tint-readout.png`).
- [x] Dropped chip colors match carrier family colors (`carrier-tint-readout.png`, `chip-color-roster.png`).
- [x] Wide Spread fires three projectiles in a fan and spends one firing cost (`wide-spread-clip.png`, `weapon-pool-verification.txt`).
- [x] Piercing Lance passes through enemies and damage is applied at most once per target (`piercing-lance-clip.png`, `weapon-pool-verification.txt`).
- [x] Heavy Slug fires slowly with a chunky projectile and larger per-shot meter drop (`heavy-slug-clip.png`).
- [x] Rapid Stream fires quickly with thin projectiles and faster held-fire meter drain (`rapid-stream-clip.png`).
- [x] First chip catch from no-weapon state equips the rolled family at full energy (`equip-from-empty-each-family.md`).
- [x] Catching a different-family chip while equipped refills the held family and discards the rolled family for T010 (`refill-ignores-family-in-t010.md`).
- [x] Carrier rolls are uniform across the five families over the sampled run (`uniform-drop-distribution.md`).
- [x] `default_pickup_family` is removed from `TypedWeaponSlot` and `Player.tscn`; no current code path references it.
- [x] Headless smoke exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [x] `verify_weapon_pool.gd` output ends in `WEAPON_POOL_VERIFICATION_OK`.

No intentional changes were made to baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter HUD layout, pea-shooter behavior, carrier sweep speed/sway/cadence, chip drift speed/sway, pickup burst, or run-end overlay.
