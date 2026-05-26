# Phase 93: Reflection and Runtime Enforcement - Validation Plan

This validation plan ensures that the Phase 93 success criteria are covered by automated tests, meeting the Nyquist compliance standard.

## 1. Reflection Validation (`93-01-PLAN.md`)

**Goal:** `schema_capabilities/1` accurately reflects the presence or absence of a `tenant_field:` on the schema via the `:tenant` key.

**Automated Tests Needed (`test/scrypath/metadata_test.exs`):**
- [x] Test that `schema_capabilities/1` returns `tenant: nil` for a schema without a declared `tenant_field:` (e.g., `FacetableMovie`).
- [x] Test that `schema_capabilities/1` returns `tenant: :<field_name>` for a mock schema with a defined `__scrypath__(:tenant_field)`.

**Execution:** Covered in `93-01-PLAN.md` Task 2 (`mix test test/scrypath/metadata_test.exs`).

## 2. Runtime Enforcement Validation (`93-02-PLAN.md`)

**Goal:** `tenant_scope:` option is parsed, enforced, and automatically injected into `filter:` during validation. Caller-supplied `filter:` cannot shadow it.

**Automated Tests Needed (`test/scrypath/options_test.exs`):**
- [x] Test successful injection: `tenant_scope: 123` correctly injects the tenant field and value into the `filter:` keyword list.
- [x] Test successful injection with existing filters: `tenant_scope: 123` merges alongside existing, non-conflicting filters.
- [x] Test anti-shadowing (Conflict): Providing `tenant_scope:` alongside the tenant field in `filter:` raises an `ArgumentError`.
- [x] Test missing declaration: Providing `tenant_scope:` for a schema lacking `tenant_field:` raises an `ArgumentError`.

**Execution:** Covered in `93-02-PLAN.md` Task 2 (`mix test test/scrypath/options_test.exs`).

## Summary

The tests outlined above guarantee both reflection accuracy and inescapable runtime scope enforcement, achieving 100% automated coverage for the phase's critical paths.