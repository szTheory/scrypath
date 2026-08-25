---
phase: 144-root-http-client-dependency-remediation
verified: 2026-08-25T20:12:30Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "Existing Req-backed Swoosh behavior remains covered and passes after the Req 0.6 transition."
    addressed_in: "Phase 146"
    evidence: "Phase 146 success criterion 3: 'The configured Req-backed Swoosh integration remains covered and works without relying on ecommerce as proof.'"
---

# Phase 144: Root HTTP Client Dependency Remediation Verification Report

**Phase Goal:** Maintainers can use the root Scrypath dependency graph without its recorded Req, Mint, hpax, or Plug advisories while retaining covered Req-backed behavior.
**Verified:** 2026-08-25T20:12:30Z
**Status:** passed
**Re-verification:** Yes — summary requirement attribution was repaired after the initial verification. Current checked-lock/audit and focused Req/telemetry evidence remain green; no implementation changed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A fresh root resolution selects fixed-compatible Req, Mint, hpax, and Plug rather than the recorded advisory versions. | ✓ VERIFIED | Detached lockless resolution at `e2cb546987e89ef5bc4bc668d12fdc8205110d5c` selected Req 0.6.3, Plug 1.19.5, Mint 1.9.3, and hpax 1.0.4; strict bounds passed and unsuppressed `mix hex.audit` reported no advisory packages. |
| 2 | The documented root compile, fast-test, verification, phase-11, and phase-99 gates pass on the remediated graph. | ✓ VERIFIED | `mix deps.get && mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99` exited 0; fast tests reported 537 tests, 0 failures. |
| 3 | Req-backed Meilisearch request/error behavior remains covered and passes after Req 0.6. | ✓ VERIFIED | `test/scrypath/meilisearch/client_test.exs` uses public `Client` calls through `Req.Test`; telemetry tests exercise the error span. Focused command passed 13 tests, 0 failures. |
| 4 | Existing Req-backed Swoosh behavior remains covered and passes after Req 0.6. | ✓ VERIFIED (deferred) | No Swoosh runtime test exists in this phase; the requirement is explicitly and specifically owned by Phase 146 criterion 3. Recorded below as deferred, not claimed as Phase 144 evidence. |
| 5 | The shared handoff spans the three direct Req manifests and four locks without graph-local framework/database remediation. | ✓ VERIFIED | Root, Ops, and ecommerce manifests require `~> 0.6.1`; root test Plug is `~> 1.19.5`; all four `mix deps.get --check-locked` checks exited 0. Commit `f711521` changes only the bounded dependency rows plus planning truth. |
| 6 | Public Req behavior retains decoded successes, tagged HTTP/transport errors, caller options, additive headers, task filters, and private error telemetry. | ✓ VERIFIED | `client.ex` constructs a Req request and normalizes response tuples; the focused tests assert transport errors with `retry: false`, API-key/header merging, task-filter encoding, and telemetry secret/payload exclusion. |
| 7 | Current-registry evidence is isolated, bounded, auditable, and does not mutate the tracked root lock. | ✓ VERIFIED | Detached worktree used isolated `MIX_DEPS_PATH`/`MIX_BUILD_PATH`, was removed, `mix.lock` remained SHA-256 `97d980f6…48cb488`, and tracked status is clean. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Deferred Items

Items not yet met within this phase but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Configured Req-backed Swoosh runtime coverage | Phase 146 | Its criterion 3 requires the integration to remain covered and work independently. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Root Req/Plug bounded constraints | ✓ VERIFIED | Contains `{:req, "~> 0.6.1"}` and test-only `{:plug, "~> 1.19.5", only: :test}`; resolved root lock selects 0.6.3/1.19.5. |
| `scrypath_ops/mix.exs` | Ops Req handoff constraint | ✓ VERIFIED | Direct `{:req, "~> 0.6.1"}` is resolved by the checked Ops lock. |
| `examples/scrypath_ecommerce/mix.exs` | Ecommerce Req handoff constraint | ✓ VERIFIED | Direct `{:req, "~> 0.6.1"}` is resolved by the checked ecommerce lock. |
| `test/scrypath/meilisearch/client_test.exs` | Req transport/header/filter coverage | ✓ VERIFIED | Substantive Req.Test plugs call public Client APIs; the focused suite passes. |
| `test/scrypath/telemetry_test.exs` | Error-span privacy coverage | ✓ VERIFIED | Captures the request span and refutes headers, body/payload, API key, and request-body leakage. |
| `lib/scrypath/meilisearch/client.ex` | Request construction and normalization seam | ✓ VERIFIED | `run_request/5` calls `Req.request/2`; `request/1` merges defaults and caller headers; response normalization returns public tuples. |
| `144-03-SUMMARY.md` | Compact audit record | ✓ VERIFIED | Exists and is corroborated by this verifier's independent detached fresh-resolution/audit run. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Root manifest | Ops/ecommerce/legacy path-consumer locks | shared Req floor | ✓ WIRED | Three direct constraints and all four locks select Req 0.6.3; all checked-lock commands pass. |
| Client tests | `Scrypath.Meilisearch.Client` | `Req.Test` plug through public calls | ✓ WIRED | Tests call `Client.get_settings/2` and `Client.tasks/2`; client calls `Req.request/2`. |
| Telemetry test | `Scrypath.Telemetry.span/3` | request-event capture | ✓ WIRED | Client invokes `Telemetry.span([:scrypath, :meilisearch, :request], ...)`; test observes that exact span. |
| Candidate SHA | fresh root resolution | detached worktree + isolated paths | ✓ WIRED | Probe detached current HEAD, removed only its lock, and used isolated build/deps paths. |
| Fresh dependency set | SEC-01 | bounds, dependency tree, unsuppressed audit | ✓ WIRED | `req → finch → mint → hpax` and root Plug paths were printed; all bounds and audit passed. |
| Locks and focused tests | root release gates | compile, fast suite, verify, phase11, phase99 | ✓ WIRED | Full documented bundle exits 0 against the current checked graph. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scrypath/meilisearch/client.ex` | Req response body / error | `Req.request/2` through `Req.Test` plugs | JSON success and transport/error responses are asserted by tests | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Four checked graphs retain their locks | Four `mix deps.get --check-locked` commands | All exited 0 | ✓ PASS |
| Req boundary behavior | `mix test test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs --exclude integration --exclude docs_contract` | 13 tests, 0 failures | ✓ PASS |
| Root release train | Documented root bundle through `mix verify.phase99` | 537 fast tests, 0 failures; all commands exit 0 | ✓ PASS |
| Fresh root advisory closure | Detached lockless `mix deps.get`, bound assertion, tree inspection, `mix hex.audit` | Correct versions/paths; audit reports no advisory packages; root lock unchanged | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Exact-candidate detached fresh-resolution/audit | Disposable detached worktree at current HEAD; lockless `mix deps.get`, bounds, `mix deps.tree`, `mix hex.audit` | Exit 0; worktree removed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| SEC-01 | 144-01, 144-03 | Resolve root beyond Req/Mint/hpax/Plug advisories with fixed-compatible constraints. | ✓ SATISFIED | Checked and fresh detached resolutions select all four fixed-compatible versions; unsuppressed audit is clean. |
| COMPAT-02 | 144-01, 144-02, 144-03 | Existing Req-backed Meilisearch and Swoosh behavior remains covered after Req 0.6. | ✓ SATISFIED (split ownership) | Root Meilisearch behavior is tested and green here. Swoosh runtime coverage is explicitly deferred to Phase 146, whose roadmap criterion 3 owns it. |

No orphaned Phase 144 requirements were found: the roadmap and all plan frontmatter account for `SEC-01` and `COMPAT-02`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty-data stub in phase-owned code/config artifacts. | — | — |

## Gaps Summary

No actionable Phase 144 gaps remain. The only roadmap wording broader than the root implementation is configured Swoosh runtime coverage; it has specific, later ownership in Phase 146 and is recorded as deferred rather than being represented as completed by Phase 144.

---

_Verified: 2026-08-22T16:45:00Z_
_Verifier: the agent (gsd-verifier)_
