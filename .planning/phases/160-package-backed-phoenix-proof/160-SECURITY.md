---
phase: 160
slug: package-backed-phoenix-proof
status: secured
audited: 2026-09-24
threats_open: 0
---

# Phase 160 Security Verification

**Verdict:** SECURED — all six declared controls are mitigated. The remaining
real-service package acceptance is a phase verification gap, not an open
security threat.

| Threat | Severity | Status | Evidence |
|---|---|---|---|
| T-160-01 — secret disclosure through child output | Medium | Mitigated | `package.ex` redacts configured secret values; Mix and Hex homes are isolated and only the explicit example file set is staged. |
| T-160-02 — package dependency provenance substitution | High | Mitigated | The lock parser checks URL and tag in the same string-keyed `scrypath` entry, including Mix's revision-before-options git tuple. The regression rejects a tag present only on another entry. |
| T-160-03 — cleanup of task-owned workspace | Low | Mitigated | The task cleans its owned temp root in `after`, validates root ownership before removal, and supports explicit failure retention. Tests cover success and injected dependency, compile, and integration-test failures, plus artifact failure cleanup. |
| T-160-SC — dependency source confusion | Medium | Mitigated | The example lockfile is staged; isolated Mix/Hex homes and the exact local artifact provenance check constrain staged dependency resolution. |
| T-160-04 — advisory CI proof ordering | Medium | Mitigated | The path-backed and package-backed commands run in order in the same advisory Phoenix service job; the docs contract checks this topology. |
| T-160-05 — credential exposure in operator docs | Low | Mitigated | Maintainer and example documentation list required environment variable names and safe local defaults without credential values. |

No unregistered threat flags were found in either plan summary. The package
integration still needs an exact-SHA hosted run with Postgres and Meilisearch;
that acceptance is recorded in `160-VERIFICATION.md` and `160-VALIDATION.md`.
