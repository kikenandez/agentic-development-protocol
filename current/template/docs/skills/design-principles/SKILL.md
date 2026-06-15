---
name: design-principles
description: Design tokens, component patterns, and business invariants for UI work. DO trigger for any frontend/designer task. Do NOT trigger for backend-only work.
---

# Design principles

**Purpose:** stable domain knowledge for the designer lane — tokens, component conventions, accessibility floor, brand constraints. Stable means it doesn't churn weekly; per-feature design decisions live in plans, not here.

## Tokens

| Token | Value | Usage |
|---|---|---|
| <<<COLOR_PRIMARY>>> | | primary actions only |
| <<<COLOR_DANGER>>> | | destructive actions only |
| <<<SPACING_SCALE>>> | | all margins/paddings from this scale |
| <<<TYPE_SCALE>>> | | no ad-hoc font sizes |

## Component conventions

- Reuse before create: check <<<COMPONENT_DIR>>> first; a new component needs n≥2 call sites or a written justification in the task Result.
- State handling: <<<STATE_CONVENTION>>> (e.g. "server state via react-query, UI state via local useState — no global store for UI state").
- File placement: <<<COMPONENT_FILE_CONVENTION>>>.

## Accessibility floor (non-negotiable)

- Interactive elements: keyboard-reachable, visible focus state.
- Color contrast ≥ WCAG AA; never color as the only signal.
- Images/icons that convey meaning carry alt/aria labels.

## Business invariants visible in the UI

| # | Invariant | Why |
|---|---|---|
| 1 | <<<UI_INVARIANT_1>>> (e.g. "prices always show currency + VAT state") | <<<WHY_1>>> |

## Maintenance

Owned by the designer lane; the architect merges changes (process.md §4). Entries follow the n-counter: a one-off design decision is a plan detail, not a principle.
