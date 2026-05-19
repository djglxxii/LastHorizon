# Task Index

Master list for Last Horizon v1 prototype work. The authoritative state of any task is the directory holding its file; this index is a scan summary.

See [`README.md`](README.md) for workflow rules and [`../PLAN.md`](../PLAN.md) for the architectural plan and milestone list.

**Rule:** at most one task may be in `active/` at a time. Tasks move to `completed/` only after explicit human approval.

## Current focus

- **Active:** T002 — Player ship + horizontal movement
- **Blocked:** none
- **Next proposed:** T003 — Auto-fire pea shooter

## M0 — Repo bootstrap

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T001 | Project bootstrap | completed | none | tool output + smoke log |

## M1 — Player baseline

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T002 | Player ship + horizontal movement | active | T001 | video/screens + input checklist |
| T003 | Auto-fire pea shooter | one-liner | T002 | video/screens + event log |

## M2 — Typed weapon + energy meter

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T004 | Typed-weapon slot + dual-role energy meter | one-liner | T003 | video/screens + event log |
| T005 | Energy-meter HUD readout | one-liner | T004 | video/screens + checklist |

## M3 — Enemy baseline + Defense Grid

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T006 | Baseline enemy + descending formation | one-liner | T005 | video/screens + event log |
| T007 | Pea shooter + typed weapon damage to enemies | one-liner | T006 | video/screens + event log |
| T008 | Defense Grid Integrity meter + leak damage + run-end | one-liner | T007 | video/screens + event log |

## M4 — Weapon pickups

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T009 | Weapon-chip carrier + drop spawn | one-liner | T008 | video/screens + event log |
| T010 | 3–4 common-tier weapon families | one-liner | T009 | video/screens + event log |
| T011 | Same-family refill / different-family swap-at-full | one-liner | T010 | video/screens + event log |

## M5 — Fuel cells

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T012 | Coalition fuel-cell carrier approach | one-liner | T011 | video/screens + event log |
| T013 | Partial energy refill on fuel-cell pickup | one-liner | T012 | video/screens + event log |

## M6 — Elite enemy + collision

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T014 | Elite/heavy enemy type | one-liner | T013 | video/screens + event log |
| T015 | Collision interception model | one-liner | T014 | video/screens + event log |
| T016 | Brief post-hit invulnerability | one-liner | T015 | video/screens + event log |

## M7 — Playtest packaging

| ID | Title | State | Depends on | Evidence type |
|---|---|---|---|---|
| T017 | Tuning constants consolidation | one-liner | T016 | code + manual checklist |
| T018 | Playtest event log capture | one-liner | T017 | event log + manual checklist |
| T019 | Manual playtest protocol document | one-liner | T018 | playtest checklist + scope answers |

## Legend

- `tool output + smoke log` — command output proving local setup and clean boot.
- `video/screens + input checklist` — visual evidence plus reviewer input notes.
- `video/screens + event log` — visual evidence plus logged gameplay events.
- `video/screens + checklist` — visual evidence plus reviewer checklist.
- `code + manual checklist` — reviewer reads code with a focused checklist.
- `playtest checklist + scope answers` — written manual playtest result mapped to the seven scope questions.
- `one-liner` — milestone is committed but no task file exists yet. The task file is drafted just-in-time when the task approaches `active/`.
