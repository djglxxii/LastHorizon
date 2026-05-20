# T003 Input Checklist

Date: 2026-05-20

Pea-shooter input independence was checked with `verify_pea_shooter.gd` using synthetic keyboard, mouse, gamepad, and movement input while the shooter ran for the same duration as a no-input pass.

- [x] No input: pea shooter fired continuously.
- [x] Space key: did not start, stop, pause, or change fire count.
- [x] Left mouse button: did not start, stop, pause, or change fire count.
- [x] Gamepad south face button (`JOY_BUTTON_A`): did not start, stop, pause, or change fire count.
- [x] Movement-style input (`A`, `D`, `ui_left`, `ui_right` coverage from T002): did not start, stop, pause, or change fire count.
- [x] Directly repositioning the player changed later bullet spawn x-positions, proving bullets spawn from the ship's current position.

Verification artifact: `tests/evidence/T003-auto-fire-pea-shooter/fire-rate-verification.txt`.
