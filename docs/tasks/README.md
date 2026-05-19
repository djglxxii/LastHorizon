# Task Workflow

This directory is the execution queue for Last Horizon v1 prototype work. Every unit of engineering work corresponds to exactly one task file in `planned/`, `active/`, `blocked/`, or `completed/`. `INDEX.md` is the quick scan summary; the source of truth for a task's state is which directory holds its file.

## States

```
planned/    Specified but not started. Ordered by intended execution.
active/     Currently being worked on. At most one task here at a time.
blocked/    Started but cannot proceed due to an external dependency.
completed/  Accepted by human reviewer. Immutable after completion.
```

## Lifecycle

```
create task → planned → active → evidence ready → human review → completed
                       └─→ blocked → active when blocker is resolved
```

## Rules

### One active task at a time

Moving a second task to `active/` while one is already there is forbidden. If the active task is stalled, either complete it with reduced scope (documented in the task's **Scope changes** section) or move it to `blocked/`.

### Every task has human-verifiable acceptance evidence

The task file must describe:

- What artifacts the reviewer will inspect.
- Where those artifacts live under `tests/evidence/T###-name/`.
- What the reviewer should check.
- The command used to regenerate the evidence where practical.

### Stop for review at every boundary

When the active task's evidence is ready, **stop and report to the user**. Do not pick up a new task until the user explicitly approves completion and designates the next task. This is the load-bearing rule of the workflow.

### Task files are append-mostly

While a task is active, update its **Progress log** with dated entries. Do not delete prior history. Reductions or expansions in scope go into **Scope changes**, not by editing the original Scope section.

### Blockers name the blocker precisely

A blocked task must include:

- The external system or dependency that is blocking.
- The exact symptom observed.
- A minimal reproduction.
- What resolution is needed before the task can resume.

## Task ID convention

Tasks are numbered `T###` in creation order. The filename is `T###-short-kebab-name.md`. IDs are never reused, even for cancelled tasks. (Cancelled tasks move to `completed/` with a Scope changes note explaining the cancellation, not deleted.)

## Spec just-in-time

Only the next 1–2 tasks need full specifications. Later milestones are tracked as one-liners in `INDEX.md` until they move toward `active/`. Pre-specifying everything risks specifying out-of-date work, because each task's shape depends on what the prior task taught us.

## Pre-flight before activating a task

Before moving a task from `planned/` to `active/`:

- Re-read the relevant entries in `docs/design/decisions.md` and the corresponding section of `docs/PLAN.md`.
- Re-read the prior task's evidence to confirm the foundation is in place.
- Confirm the task file's **Pre-flight** checklist items are satisfied.

If any of those steps surface a contradiction with the design log, raise it to the user before starting work — don't paper over it in code.
