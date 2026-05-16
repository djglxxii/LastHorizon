# Last Horizon

A roguelite vertical shoot-'em-up. You defend a single planet through a sequence of faction-themed stages — each a long descending armada that culminates in a faction boss, leading to a final coalition warlord encounter.

The combat loop fuses Space Invaders descending-formation pressure with a Blazing Lazers-style typed-weapon economy. Your ship has a permanent pea shooter that auto-fires, plus one player-controlled temporary typed weapon drawn from a large faction-gated weapon pool. The typed weapon's energy meter is dual-role: it is both your sacrificial shield against enemy fire and the fuel that powers the weapon, so every shot is a tactical spend. The ship cannot be destroyed — the only run-ending failure is the shared Defense Grid Integrity meter (protecting both ship and planet) reaching zero. Defeating a faction unlocks its weapons into a persistent cross-run "reverse-engineered" rare drop pool, so subsequent runs feel different even before the first clear.

**Status:** pre-production. Design exploration in progress; no engine or framework selected yet. The active design log is at [`docs/design/decisions.md`](docs/design/decisions.md).

## Repository layout

```
docs/
  research/      — external research and references
  design/        — game design document and design notes
  decisions/     — architecture / tech decision records
src/             — game source code (engine TBD)
assets/          — art, audio, fonts, source files for content
tests/           — automated tests
```

See [`docs/README.md`](docs/README.md) for the documentation index.
