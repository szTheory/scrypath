# Phase 117 Plan: Shared Ops Component System

**Status:** Pending
**Requirements:** COMP-01, A11Y-01

## Tasks

- Extend `ScrypathOpsWeb.OpsUi` with notices, metrics, empty states, schema selects, toolbars, code blocks, and modal wrappers.
- Replace repeated hand-rolled fragments where the component contract is stable.
- Keep behavior unchanged; this phase is presentation and semantics.

## Verification

- Component-level rendered HTML assertions through existing LiveView tests.
- A11y contract updates for focus, labels, semantic headings, and modal semantics.
