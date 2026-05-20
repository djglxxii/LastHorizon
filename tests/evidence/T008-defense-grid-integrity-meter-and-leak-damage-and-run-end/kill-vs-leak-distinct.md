# Kill vs Leak VFX

The T007 kill burst and T008 planet-impact burst are separate scenes and use different palettes:

- Kill burst: `scenes/vfx/PixelBurst.tscn`, mixed teal, cyan, magenta, and yellow fragments. Evidence reference: `../T007-pea-shooter-and-typed-weapon-damage-to-enemies/kill-burst-detail.png`.
- Leak impact: `scenes/vfx/PlanetImpact.tscn`, mostly cool cyan/blue/white fragments with a small red accent. Evidence reference: `leak-feedback-02-impact.png`.

The leak path queues the enemy for free through `BaselineEnemy._leak()` and does not call `_kill()`, so it does not spawn the T007 kill burst.
