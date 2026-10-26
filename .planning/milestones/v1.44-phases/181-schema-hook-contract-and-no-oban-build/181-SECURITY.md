---
phase: "181"
slug: "schema-hook-contract-and-no-oban-build"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
source_sha: c47c1216d0ae2e5c491751551f9aa019c619b3c6
created: "2026-10-26"
---

# Phase 181 — Security

This is an inline L1 audit of the register authored in Plans 181-01 and 181-02.
The repeated T-181-SC row is one threat. Neither summary adds a Threat Flag.
All seven mitigation controls are present; the one accepted supply-chain risk
retains its existing plan disposition. With no open registered threats and L1
configured, secure-phase permits the audit to close without a separate auditor.
No independent review or new maintainer risk acceptance is claimed.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Verification gate → release evidence | A green core gate must prove a real build without Oban | Build artifacts and compiler output |
| Library → Oban store | Related enqueue must retain shared uniqueness | Job options and document ids |
| Library macro → adopter compiler | Injected behaviour and arity warnings affect adopter builds | Schema definitions and diagnostics |
| Published hooks → runtime dispatch | Callback declarations must match existing probes | Hook names, arities and documented outcomes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-181-01 | Repudiation / tampering | False-green no-Oban compile | high | mitigate | `NoOptionalDeps.run/1` isolates MIX_BUILD_PATH, removes cached optional-dependency dirs, compiles with `--force --no-optional-deps --warnings-as-errors`, and asserts optional deps and the conditional UpsertWorker beam absent. Seam tests and the actual core gate pass. Earlier RED remains recorded in 181-01-SUMMARY.md. | closed |
| T-181-02 | Tampering | Related job uniqueness | medium | mitigate | RelatedEnqueue calls shared `Enqueue.job_changeset/4` with `[]`; builder applies `unique_opts/0`. The core run covers related job-policy assertions and real Oban Lite uniqueness tests. | closed |
| T-181-03 | Tampering | Compiler suppression creep | medium | mitigate | Workflow-wiring contract checks mix.exs and compiler-option mutation; WR-03 now parses literal suppression options and rejects other namespaces and dynamic targets. Repository scan finds only three targeted Oban sites. | closed |
| T-181-04 | Denial of service | Core check skipped | medium | mitigate | Capability.run_core/2 runs verify then verify.no_optional_deps. Its sequence test passes; existing ci.yml core (required) invokes verify.core. Local execution printed the absence-proof line. Hosted execution is pending. | closed |
| T-181-05 | Denial of service | False-positive hook warnings | medium | mitigate | `__before_compile__/1` warns only for a public hook name with no expected arity, uses IO.warn rather than raise, and supplies the definition line. Correct, absent, helper-arity and annotated hooks pass diagnostic tests. | closed |
| T-181-06 | Tampering | Hook contract drift | low | mitigate | Schema test compares a nonempty set of runtime `schema_module` probes to optional callbacks; passes. IN-05 remains a known guard limitation for future differently named variables. | closed |
| T-181-07 | Denial of service | New adopter @impl warnings | low | mitigate | Schema moduledoc and Unreleased upgrade note explain `@impl Scrypath.Schema`. Mixed-behaviour fixtures reproduce the warnings for all three hooks and verify the annotation remedy. | closed |
| T-181-SC | Tampering | Dependency installation | low | accept | Existing plans add no dependencies. `git diff f21cd4b1 c47c1216 -- mix.exs mix.lock` is empty. Package build uses the existing lock and declared dependencies. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-181-SC | T-181-SC | No new package/dependency graph in this phase; retain the plan's low-risk disposition | Existing Plans 181-01 and 181-02 | 2026-10-26 |

No additional risk was accepted during this audit. Informational review items
IN-01–IN-05 remain open in the disposition ledger, including the custom
MIX_BUILD_PATH isolation concern (IN-04). The security verdict covers the authored
register and does not erase those findings or certify arbitrary build environments.

## Evidence and Limits

At the source SHA above, from `/Users/jon/projects/scrypath`:

- `mix verify.core --exclude integration --exclude docs_contract`: 953 tests,
  5 properties, 0 failures; compiler, Credo, docs and no-Oban build pass.
- `mix verify.package`: 81 tests, 0 failures and successful unpacked Hex build.
- Focused docs/package metadata tests: 79 tests, 0 failures.

No hosted SHA-bound run, live backend test, release or merge is claimed by this
record. The no-Oban gate ran with the checkout's normal `_build` path. Controls
were inspected and exercised inline; no separate security auditor ran.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-26 | 8 | 8 | 0 | Codex, inline L1 control verification |

## Sign-Off

- [x] All threats have a disposition
- [x] Existing accepted risk documented with plan provenance
- [x] `threats_open: 0` confirmed (no open registered threats at any severity)
- [x] `status: verified` set in frontmatter

**Verification:** 2026-10-26; automated evidence plus L1 source inspection.
