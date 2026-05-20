# T004 Input Checklist

- [x] Pea shooter begins firing without player input.
- [x] Holding `fire_typed` (Space, left mouse, gamepad south) emits the typed weapon while the debug slot has energy.
- [x] Holding `fire_typed` drains only the typed-weapon energy pool; the pea shooter continues at its own cadence.
- [x] Releasing `fire_typed` stops typed-weapon shots; the pea shooter continues firing.
- [x] When the typed-weapon energy reaches 0, the typed stream stops and the pea shooter continues uninterrupted.
- [x] Pressing `fire_typed` after expiry emits no typed-weapon projectiles because the slot is empty.
- [x] No HUD energy meter, enemies, collision, pickups, or carriers were introduced in this task.
