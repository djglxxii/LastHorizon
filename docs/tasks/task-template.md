# T### — Short Title

| Field | Value |
|---|---|
| ID | T### |
| State | planned / active / blocked / completed |
| Phase | M# — phase name |
| Depends on | T###, T###, or none |
| Plan reference | `docs/PLAN.md` section name |

## Goal

One or two sentences describing what this task delivers and why it is next.

## Scope

- **In scope:**
- **Out of scope:**

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

## Pre-flight

- [ ] Prerequisites beyond task dependencies (e.g., specific design log entries to re-read, external tool availability).

## Implementation notes

Relevant code paths, algorithms, configuration, and file locations. Reference `docs/PLAN.md` for larger architectural context. Keep this lean — implementation notes are intent, not instructions.

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T###-name/<file>` — what it is and how it was produced.

**Reviewer checklist:**

- [ ] Artifact shows the expected feature or behavior.
- [ ] Rerun command works.
- [ ] No known regression in prior tasks' evidence.

**Rerun command:**

```bash
# command(s) to regenerate the evidence
```

## Progress log

| Date | Entry |
|---|---|
| YYYY-MM-DD | Created, state: planned. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
