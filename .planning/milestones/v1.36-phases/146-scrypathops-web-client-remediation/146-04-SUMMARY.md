---
phase: 146-scrypathops-web-client-remediation
plan: "04"
subsystem: testing
tags: [elixir, swoosh, req, security, verification]
requires:
  - phase: 146-scrypathops-web-client-remediation
    plan: "03"
    provides: detached fresh-resolution and unsuppressed Hex-audit evidence for 59d2e6a
provides:
  - discriminating raw-JSON Req.Test proof for Swoosh.ApiClient.Req decode precedence
  - isolated verifier-driven test-only closure commit with exact path and ancestry evidence
affects: [147-ecommerce-mounted-ops-remediation-and-closure-evidence, phase-146-reverification]
tech-stack:
  added: []
  patterns: [direct Req.Test raw-response contract, exact closure diff-tree proof]
key-files:
  created: [.planning/phases/146-scrypathops-web-client-remediation/146-04-SUMMARY.md]
  modified: [scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs]
key-decisions:
  - "Retained conflicting decode_body: true and used an application/json response so raw-body preservation is genuinely discriminating."
  - "Preserved 59d2e6a as the dependency-remediation commit and closed only the verifier-discovered test gap in ff1531c."
patterns-established:
  - "Raw-response precedence tests must use JSON when exercising a decode_body conflict; text/plain cannot distinguish decoded from preserved payloads."
requirements-completed: [SEC-03]
coverage:
  - id: D1
    description: "Swoosh.ApiClient.Req preserves the exact raw JSON binary despite caller decode_body: true."
    requirement: SEC-03
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs#initializes-and-posts-Swoosh-owned-request-options-through-Req.Test
        status: pass
    human_judgment: false
  - id: D2
    description: "The focused closure is isolated after the dependency remediation and all required Ops/root gates remain green."
    requirement: SEC-03
    verification:
      - kind: other
        ref: "mix verify.opsui; mix compile --warnings-as-errors; mix test --exclude integration --exclude docs_contract --include requires_clean_workspace; mix verify --exclude integration; mix verify.phase11; mix verify.phase99"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-24
status: complete
---

# Phase 146 Plan 04: Raw JSON Req Contract Closure Summary

**Swoosh’s production-selected Req client now has a discriminating JSON-response contract proving it returns the exact raw binary despite a conflicting decode_body option.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-24T21:58:20Z
- **Completed:** 2026-08-24T22:01:00Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Replaced the blind text/plain fixture with an `application/json` response containing `~s({"accepted":true})` while retaining `decode_body: true` in `client_options`.
- Asserted that `Swoosh.ApiClient.Req.post/4` returns the exact unparsed JSON binary and retained all request URL, headers, user-agent, body, forwarding, normalization, initialization, and transport-error coverage.
- Preserved the exact Ops manifest and lock hashes, with `59d2e6a894d97a16fd8acc624281c8b2c38777c1` as the dependency remediation and `ff1531c9d6972b62f42636a693b57fad69159170` as the sole test-only closure.

## Verification

| Gate | Command | Exit |
| --- | --- | --- |
| Focused contract | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` | 0 (2 tests) |
| Focused formatting | `cd scrypath_ops && mix format --check-formatted test/scrypath_ops/swoosh_api_client_req_test.exs` | 0 |
| Ops precommit | `cd scrypath_ops && mix precommit` | 0 (2 doctests, 154 tests) |
| Checked lock | `cd scrypath_ops && mix deps.get --check-locked` | 0 |
| Ops compile | `cd scrypath_ops && mix compile --warnings-as-errors` | 0 |
| Ops audit | `cd scrypath_ops && mix hex.audit` | 0 (unsuppressed) |
| Ops application gate | `mix verify.opsui` | 0 (2 doctests, 154 tests) |
| Root main-ci compile | `mix compile --warnings-as-errors` | 0 |
| Root main-ci tests | `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` | 0 (2 properties, 538 tests) |
| Root repo hygiene | `mix verify --exclude integration` | 0 |
| Root release truth | `mix verify.phase11` | 0 |
| Root phase99 trust | `mix verify.phase99` | 0 |

`scrypath_ops/mix.exs` SHA-256 remained `a624ce14afb45f37d4c027ad5b7de748be94dbc312401c3e62f908998d0bd07e`; `scrypath_ops/mix.lock` remained `30c54587258cf29674af0b5e9f1c71799ac44f82ef9227fd6d9e2d1776588ea4` before and after every gate.

## Task Commit

1. **Task 1: Harden the raw-JSON contract and prove the isolated closure** - `ff1531c` (test)

## Commit-Path Proof

- Dependency-remediation candidate: `59d2e6a894d97a16fd8acc624281c8b2c38777c1`.
- Closure: `ff1531c9d6972b62f42636a693b57fad69159170`, subject `test(146-04): harden Swoosh raw JSON contract`.
- `git merge-base --is-ancestor 59d2e6a ff1531c`: passed.
- Exactly one post-candidate commit touches the focused test: passed.
- `git diff-tree --no-commit-id --name-only -r ff1531c` equals only `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs`: passed.

## Files Created/Modified

- `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` - returns JSON from Req.Test and proves raw JSON preservation through the real Swoosh Req client.

## Decisions Made

- Kept the conflicting caller option intact and moved the fixture to JSON rather than changing production configuration, making the expected raw-body behavior observable.
- Kept the closure strictly test-only and separately labeled; no manifest, lock, runtime, UI, route, schema, provider, CI, ecommerce, or public API path changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Matched Plug’s normalized JSON content-type header**
- **Found during:** Task 1
- **Issue:** Plug appends `; charset=utf-8` after the fixture sets the required `application/json` media type, so an exact bare-media-type assertion failed.
- **Fix:** Asserted the actual normalized `application/json; charset=utf-8` response header while retaining the JSON media type and exact raw-body assertion.
- **Files modified:** `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs`
- **Verification:** Focused contract, formatting, Ops precommit, audit, and all planned Ops/root gates passed.
- **Commit:** `ff1531c`

**Total deviations:** 1 auto-fixed (Rule 1 bug).
**Impact:** The correction is limited to framework-normalized header truth; the intended raw-JSON precedence proof is stronger and scope remains test-only.

## Known Stubs

None.

## Next Phase Readiness

Phase 146 is ready for code review and phase re-verification. The pre-existing user-owned changes to `.planning/REQUIREMENTS.md`, `.planning/config.json`, and `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` remain unstaged and untouched.

## Self-Check: PASSED

- Confirmed the focused test exists and closure commit `ff1531c` exists.
- Confirmed the closure diff contains only the focused test path, its subject matches, and `59d2e6a` remains its ancestor.
- Confirmed the Ops manifest and lock retain their recorded SHA-256 values.
