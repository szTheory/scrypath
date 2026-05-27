# Phase 97 Scope Guard (`SCOPE-01`)

## Banned capability classes

Phase 97 through Phase 99 are contract-hardening-only slices. The following runtime-breadth classes are explicitly banned during this milestone:

- autocomplete/suggestions
- vector or hybrid retrieval
- public backend broadening
- new public runtime API categories

## Reopen policy

Scope expansion is allowed only when all three conditions are met:

1. reviewed outside-adopter signal or reproducible production bug evidence exists;
2. `.planning/REQUIREMENTS.md` is explicitly updated with the new requirement;
3. `.planning/ROADMAP.md` is explicitly updated with the corresponding phase scope before execution.

## Enforcement

This file is the Phase 97 source of truth for `SCOPE-01`. Phase 98 and Phase 99 work must reference this guard when evaluating whether a proposed change widens runtime breadth.
