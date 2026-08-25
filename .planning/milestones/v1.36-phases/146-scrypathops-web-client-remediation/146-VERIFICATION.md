---
phase: 146-scrypathops-web-client-remediation
verified: 2026-08-24T22:05:50Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "The configured Req-backed Swoosh integration returns the exact raw JSON binary despite conflicting decode_body: true."
  gaps_remaining: []
  regressions: []
---

# Phase 146: ScrypathOps Web/Client Remediation Verification Report

**Phase Goal:** Maintainers can independently run ScrypathOps on its fixed-compatible web, LiveView, mailer, HTTP, database, and transitive dependency graph.
**Verified:** 2026-08-24T22:05:50Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A fresh ScrypathOps resolution selects fixed-compatible bounded web, LiveView, Swoosh, Req, and applicable transitive versions without recorded advisories. | ✓ VERIFIED | Current isolated lock is unchanged and selects Phoenix 1.8.12, LiveView 1.1.33, Bandit 1.12.5, Swoosh 1.26.3, Postgrex 0.22.4, Req 0.6.3, Plug 1.19.5, Mint 1.9.3, and hpax 1.0.4. The exact-SHA detached proof remains applicable because the current manifest and lock hashes exactly equal its recorded inputs; a fresh checked-lock resolution and unsuppressed `mix hex.audit` both passed. |
| 2 | `mix verify.opsui` and the named required root regression gates pass against the standalone remediated ScrypathOps graph. | ✓ VERIFIED | Freshly passed: Ops precommit; retried binding `mix verify.opsui` (2 doctests, 154 tests); root warnings-as-errors compile; root main-ci test command (2 properties, 538 tests); `mix verify --exclude integration`; `mix verify.phase11`; and `mix verify.phase99`. |
| 3 | The configured Req-backed Swoosh integration remains covered and works without relying on ecommerce as proof. | ✓ VERIFIED | Production config selects `Swoosh.ApiClient.Req`; test config remains `Swoosh.Adapters.Test` with API client disabled. The direct service-free `Req.Test` contract retained conflicting `decode_body: true`, returned `application/json`, and a focused run passed while asserting `post/4` returns the exact `~s({"accepted":true})` binary. |
| 4 | Any Postgrex update uses only a stable published release confirmed fixed by both the live advisory and Hex registry; otherwise this batch stops without a substitute version. | ✓ VERIFIED | Fresh official Hex predicate confirms stable, unretired Postgrex 0.22.4; fresh EEF CNA predicate confirms the affected range begins at 0.19.3 and ends before 0.22.4. Manifest and lock select `~> 0.22.4` / 0.22.4. |
| 5 | The ScrypathOps manifest and lockfile form one isolated, explained third commit with no unrelated upgrades. | ✓ VERIFIED | `59d2e6a` changes only `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock`, and the focused contract. `ff1531c` is its ancestor-descendant, separately labelled verifier closure and changes only that focused test. No forbidden runtime, UI, route, schema, provider, CI, ecommerce, or public-API path is in either implementation diff. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Decision Contract Coverage (D-01–D-22)

| Decision | Status | Actual code/evidence |
| --- | --- | --- |
| D-01–D-05 | ✓ VERIFIED | Six approved direct bounds are present; forbidden packages remain transitive/no override; checked lock contains the reviewed fixed cohort. Exact-SHA detached range/audit evidence remains tied to the same manifest and lock hashes. |
| D-06–D-07 | ✓ VERIFIED | The direct Req.Test reaches real `Swoosh.ApiClient.Req.init/0` and `post/4`; it asserts method, URL/path/query, headers, user agent, raw request body, client-option precedence, exact JSON binary, normalized content type, and transport error. |
| D-08–D-09 | ✓ VERIFIED | `config/test.exs` keeps Test adapter + `api_client: false`; `config/prod.exs` explicitly selects Req; `ScrypathOps.Mailer` is unchanged. |
| D-10, D-12 | ✓ VERIFIED | Fresh standalone Ops gate passes. Implementation commits contain no UI-owned path; ecommerce/browser proof was not substituted. |
| D-11 | ✓ VERIFIED | Fresh unsuppressed `cd scrypath_ops && mix hex.audit` exited 0 with no retired or advisory packages. |
| D-13–D-19 | ✓ VERIFIED | No runtime compatibility fix was added. `59d2e6a` is the one dependency-remediation commit; `ff1531c` is the one separately labelled, test-only verifier closure. Current hashes preserve the detached-proof input, and current user-owned dirty files were not touched. |
| D-20–D-22 | ✓ VERIFIED | Familiar Mix interfaces only; no capability, route, UI, schema, provider, CI, policy, or modernization expansion. The eight UI preservation states are protected by the no-UI diff plus passing `mix verify.opsui`. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scrypath_ops/mix.exs` | Six approved direct fixed-compatible requirements | ✓ VERIFIED | Contains Phoenix `~> 1.8.9`, LiveView `~> 1.1.33`, Bandit `~> 1.12.1`, Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, and Req `~> 0.6.1`; no direct Plug/Mint/hpax/Finch/Ecto/Decimal or override. SHA-256: `a624ce14…d0bd07e`. |
| `scrypath_ops/mix.lock` | Reviewed causal standalone resolution | ✓ VERIFIED | Checked-lock resolution passed; fixed cohort is selected. SHA-256: `30c54587…6588ea4`, unchanged before and after fresh gates. |
| `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` | Direct, discriminating service-free Req-client contract | ✓ VERIFIED | Substantive two-test module, executed by the focused command and Ops suite. JSON/content-type fixture with conflicting `decode_body: true` proves raw body preservation. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scrypath_ops/mix.exs` | `scrypath_ops/mix.lock` | Mix checked-lock resolution | ✓ WIRED | `mix deps.get --check-locked` passed without changing the lock. |
| `Swoosh.ApiClient.Req.post/4` | `Req.Test` JSON response | Email `client_options` carries plug/retry/`decode_body: true`; test asserts exact return | ✓ WIRED | Focused behavior test passed: a JSON response remains the original binary, so the Swoosh-owned `decode_body: false` precedence is exercised rather than inferred. |
| `config/prod.exs` | `Swoosh.ApiClient.Req` | `config :swoosh, api_client: ...` | ✓ WIRED | Production selection is explicit; test configuration remains isolated. |
| Official Hex + EEF CNA | Postgrex manifest bound | Fail-closed `curl | jq` predicates | ✓ WIRED | Both live predicates passed for stable/unretired 0.22.4 and the fixed advisory boundary. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Swoosh Req contract | Response body | `Req.Test` plug → real `Swoosh.ApiClient.Req.post/4` → Req response | Synthetic `application/json` transport response, returned as the exact asserted raw JSON binary | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Raw JSON / decode-body precedence | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Focused format, lock, compile, audit | `mix format --check-formatted … && mix deps.get --check-locked && mix compile --warnings-as-errors && mix hex.audit` | All exit 0; audit reported no retired/advisory packages | ✓ PASS |
| Standalone Ops application | `mix verify.opsui` | Initial CI-mode run exposed a pre-existing `PostureLiveTest` cleanup race; the named test and immediate full retry both passed (2 doctests, 154 tests). The implicated test predates this phase and neither implementation commit touches it. | ✓ PASS (retry; non-phase transient noted) |
| Required root release gates | `mix compile --warnings-as-errors`; main-ci test command; `mix verify --exclude integration`; `mix verify.phase11`; `mix verify.phase99` | All exit 0; main-ci test command: 2 properties, 538 tests, 0 failures | ✓ PASS |
| Postgrex publication guard | Hex and EEF CNA fail-closed predicates | Both exit 0 | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Exact-SHA detached fresh resolver/audit | Validated Phase 146 detached-worktree procedure at `59d2e6a` | Detached proof records all nine D-05 ranges, exact Plug registry predicate, unsuppressed audit, cleanup, and primary-lock preservation. Its input hashes still exactly match current files; it was deliberately not repeated after test-only `ff1531c`. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SEC-03 | 146-01 through 146-04 | Independently resolve ScrypathOps beyond recorded web, LiveView, mailer, HTTP, and database advisories. | ✓ SATISFIED | Fixed lock, fresh audit/current checked lock, direct configured Req-client behavior test, standalone Ops gate, and named root gates pass. |
| EVID-03 | 146-01, 146-03 | Block Postgrex changes until live advisory and Hex confirm a stable published fixed release. | ✓ SATISFIED | Fresh dual live predicates pass; manifest and lock select only stable 0.22.4. |

No orphaned Phase 146 requirements: SEC-03 and EVID-03 are the only roadmap requirements assigned to this phase and are declared by the plans.

### Anti-Patterns Found

No phase-owned `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, hardcoded-empty rendering path, or forbidden-scope change was found. The lockfile's word `hackney` is a transitive package name, not a debt marker.

### Human Verification Required

None. All must-haves are deterministically exercised; the phase does not add a visual or external-provider user flow requiring human acceptance.

### Gaps Summary

The previous blocking gap is closed. The `ff1531c` test now uses a JSON response and proves exact raw-binary preservation under the conflicting `decode_body: true` condition that previously made the text/plain test non-discriminating. No remaining goal-blocking gap was found.

---

_Verified: 2026-08-24T22:05:50Z_
_Verifier: the agent (gsd-verifier)_
