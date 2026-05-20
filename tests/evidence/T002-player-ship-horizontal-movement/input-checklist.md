# T002 Input Checklist

Date: 2026-05-19

Environment: Godot 4.6.2 headless scripts from the repository root.

## Automated movement check

Command:

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T002-player-ship-horizontal-movement/verify_player_movement.gd
```

Observed output:

```text
PLAYER_MOVEMENT_VERIFICATION_OK
```

Checked:

- [x] Built-in `ui_left` action moves the player left and clamps at x=24.
- [x] Built-in `ui_right` action moves the player right and clamps at x=516.
- [x] `A` key moves the player left and clamps at x=24.
- [x] `D` key moves the player right and clamps at x=516.
- [x] Movement keeps the player at fixed y=850.

## Manual reviewer check

- [ ] Run the project interactively and confirm physical keyboard input feels correct.
- [ ] If a gamepad is available, confirm left-stick horizontal input moves and clamps the player.
