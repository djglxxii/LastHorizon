# T001 — Project Bootstrap

| Field | Value |
|---|---|
| ID | T001 |
| State | planned |
| Phase | M0 — Repo bootstrap |
| Depends on | none |
| Plan reference | `docs/PLAN.md` — M0 |

## Goal

Initialize the v1 prototype so subsequent gameplay tasks can begin: pinned Godot engine wrapper, headless boot smoke test, repo skeleton, `.gitignore` for engine state and build artifacts, and a minimal boot scene that the smoke test can load. Aligned with ADR-0001 (Godot 4.x + GDScript) and the conventions in `docs/PLAN.md`.

## Scope

- **In scope:**
  - `tools/setup_godot.sh` (or equivalent) that downloads and pins a specific Godot 4.x version into `tools/` and provides a wrapper executable. The wrapper path and version is documented in the task evidence.
  - `tools/run_headless_smoke.sh` (or equivalent) that runs the wrapper in `--headless` mode against the project and exits cleanly.
  - `project.godot` configured for a narrow vertical viewport consistent with the design log's ~9:16 invariant. Specific viewport dimensions are an implementation detail of this task.
  - `scenes/main/Main.tscn` as the boot scene with a single placeholder script that prints a recognizable boot message and exits cleanly under headless mode.
  - `.gitignore` covering `.godot/` editor state, the local Godot download under `tools/`, build exports, and imported asset caches.
  - Folder skeleton under `src/` matching the layout in `docs/PLAN.md` (empty directories represented by `.gitkeep`).
- **Out of scope:**
  - Player movement, enemies, weapons, pickups, Grid logic, or any HUD beyond the boot message.
  - Final renderer choice (`gl_compatibility` vs. `forward_plus`) — document the choice in implementation notes when it is made; it does not need its own ADR yet.
  - CI integration. Any automated tests beyond the headless boot smoke.

## Scope changes

None.

## Pre-flight

- [ ] Confirm the chosen Godot 4.x version is downloadable from the official source for the target platform.
- [ ] Confirm `docs/decisions/0001-engine-and-language.md` is the current authoritative tech-stack decision (no superseding ADR exists).

## Implementation notes

- Repo root is the Godot project root (`project.godot` lives at repo root).
- The pinned engine is downloaded into `tools/` and is **not** committed; the bootstrap script downloads it reproducibly. The script itself is committed.
- The wrapper executable can be a thin shell script that execs the downloaded binary, or a direct symlink — either is fine. Document the choice in evidence.
- The headless smoke runs the wrapper with `--headless --path .` and a `--quit` (or equivalent) flag. The boot message uses GDScript `print()` so it appears on stdout.
- The boot-scene script is the simplest viable GDScript that prints and exits in headless mode. Do not attempt gameplay logic here.
- Pin the Godot version explicitly in the bootstrap script (e.g., `GODOT_VERSION=4.x.y` near the top), so future agents can find and revisit it without grepping.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T001-project-bootstrap/godot-version.txt` — output of `tools/godot/bin/godot --version` after bootstrap.
- `tests/evidence/T001-project-bootstrap/headless-smoke.txt` — full stdout of the headless smoke run, showing the boot message and clean exit.
- `tests/evidence/T001-project-bootstrap/repo-tree.txt` — `find . -type d` snapshot (excluding `.git`, the downloaded engine, and `.godot` editor state) showing the directory skeleton.
- `tests/evidence/T001-project-bootstrap/git-status.txt` — `git status` after the work, demonstrating that engine downloads and editor state are correctly ignored.

**Reviewer checklist:**

- [ ] `tools/setup_godot.sh` runs cleanly from a fresh checkout.
- [ ] `tools/godot/bin/godot --version` reports the pinned Godot 4.x version.
- [ ] The headless smoke prints the boot message and exits with status 0.
- [ ] `repo-tree.txt` shows the expected skeleton (`src/{game,player,weapons,enemies,carriers,grid,ui}/` with `.gitkeep`, plus `tools/`, `tests/`, `assets/`, `scenes/main/`).
- [ ] `git-status.txt` shows no untracked engine binaries or editor state — only authored source.

**Rerun command:**

```bash
tools/setup_godot.sh
tools/godot/bin/godot --version > tests/evidence/T001-project-bootstrap/godot-version.txt
tools/run_headless_smoke.sh > tests/evidence/T001-project-bootstrap/headless-smoke.txt
find . -type d -not -path './.git*' -not -path './tools/godot/*' -not -path './.godot*' | sort > tests/evidence/T001-project-bootstrap/repo-tree.txt
git status > tests/evidence/T001-project-bootstrap/git-status.txt
```

## Progress log

| Date | Entry |
|---|---|
| 2026-05-19 | Created, state: planned. |

## Blocker

None.
