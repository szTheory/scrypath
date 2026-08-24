---
phase: 146-scrypathops-web-client-remediation
verified: 2026-08-24T21:43:02Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The configured Req-backed Swoosh integration remains covered and works without relying on ecommerce as proof."
    status: partial
    reason: "The real Swoosh.ApiClient.Req path is invoked and the focused test passes, but its only raw-response case uses text/plain. That result is identical whether Swoosh overrides conflicting client_options[:decode_body] = true to false or incorrectly lets Req decode JSON responses. The required Swoosh-owned decode_body precedence and raw JSON-body invariant are therefore not proven."
    artifacts:
      - path: "scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs"
        issue: "The Req.Test stub returns text/plain instead of JSON with application/json while the caller supplies decode_body: true."
    missing:
      - "Return a JSON application/json response from the Req.Test stub and assert Swoosh.ApiClient.Req.post/4 returns the original JSON binary despite client_options decode_body: true."
---

# Phase 146: ScrypathOps Web/Client Remediation Verification Report

**Phase Goal:** Maintainers can independently run ScrypathOps on its fixed-compatible web, LiveView, mailer, HTTP, database, and transitive dependency graph.
**Verified:** 2026-08-24T21:43:02Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A fresh ScrypathOps resolution selects fixed-compatible bounded web, LiveView, Swoosh, Req, and applicable transitive versions without recorded advisories. | ✓ VERIFIED | Current checked lock selects Phoenix 1.8.12, LiveView 1.1.33, Bandit 1.12.5, Swoosh 1.26.3, Postgrex 0.22.4, Req 0.6.3, Plug 1.19.5, Mint 1.9.3, and hpax 1.0.4. Fresh lockless exact-SHA evidence in `146-03-SUMMARY.md` records compatible selections (including transitive Plug 1.20.3) and an unsuppressed `mix hex.audit` exit 0; the verifier independently reran the current checked-lock audit, also exit 0. |
| 2 | `mix verify.opsui` and the named required root regression gates pass against the standalone remediated ScrypathOps graph. | ✓ VERIFIED | Verifier reran `mix verify.opsui`: 2 doctests and 154 tests, 0 failures. `146-02-SUMMARY.md` records the exact candidate SHA and zero exits for `main-ci`, `repo-hygiene`, `release-truth`, and `phase99-trust`; all are planning-only descendants of the candidate. |
| 3 | The configured Req-backed Swoosh integration remains covered and works without relying on ecommerce as proof. | ✗ FAILED | `prod.exs` selects `Swoosh.ApiClient.Req`, `test.exs` retains `Swoosh.Adapters.Test` and `api_client: false`, and the direct service-free Req.Test module passes. However, the passing happy-path stub emits text/plain, so it cannot distinguish raw preservation from an erroneous JSON decode when `client_options` supplies `decode_body: true`. |
| 4 | Any Postgrex update uses only a stable published release confirmed fixed by both the live advisory and Hex registry; otherwise this batch stops without a substitute version. | ✓ VERIFIED | Current live Hex predicate confirms stable, unretired Postgrex 0.22.4; current EEF CNA predicate confirms affected `>= 0.19.3, < 0.22.4`. Manifest and lock select `~> 0.22.4` / 0.22.4. |
| 5 | The ScrypathOps manifest and lockfile form one isolated, explained third commit with no unrelated upgrades. | ✓ VERIFIED | `59d2e6a` is the sole commit in its implementation range touching the owned paths and changes exactly `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock`, and the focused contract test. No UI, route, schema, provider, CI, ecommerce, or public API file appears. |

**Score:** 4/5 truths verified (0 present, behavior-unverified)

### Decision Contract Coverage (D-01–D-22)

| Decision | Status | Actual code/evidence |
| --- | --- | --- |
| D-01, D-03, D-04, D-05 | ✓ VERIFIED | Exact direct bounds are present; forbidden dependencies remain transitive/no override; checked lock and recorded exact-SHA fresh range matrix are causal and audit-clean. |
| D-02 | ✓ VERIFIED | Current dual live Hex/EEF-CNA predicates pass for stable, unretired 0.22.4 and the fixed advisory boundary. |
| D-06 | ✓ VERIFIED | Direct `Swoosh.ApiClient.Req.init/0` and `post/4` use a per-test `Req.Test` plug, with no provider traffic. |
| D-07 | ✗ FAILED | Headers and body precedence, normalization, and transport-error shape are tested; `decode_body: false` precedence/raw JSON body preservation is not discriminated by text/plain. |
| D-08, D-09 | ✓ VERIFIED | Test configuration remains Test adapter + disabled API client; production still selects Req; `ScrypathOps.Mailer` is unchanged. |
| D-10, D-12 | ✓ VERIFIED | Current `mix verify.opsui` passed; candidate diff has no UI-owned file and no ecommerce/browser proof is substituted. |
| D-11 | ✓ VERIFIED | Current `mix hex.audit` was unsuppressed and exited 0; no copied exploit tests or permanent lane exists. |
| D-13, D-16, D-18, D-19 | ✓ VERIFIED | No source compatibility fix was added; exact one implementation commit and scope inspection show the required stop/isolation boundaries. |
| D-14, D-15, D-17 | ✓ VERIFIED | Candidate summaries record ordered named deterministic gates, detached fresh resolver/audit, cleanup, lock/dirty-baseline preservation, and compact evidence only. |
| D-20, D-21, D-22 | ✓ VERIFIED | Diff and current passing Ops gate show familiar Mix interfaces and no capability/UI/schema/provider/CI/policy modernization expansion. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scrypath_ops/mix.exs` | Six approved fixed-compatible requirements | ✓ VERIFIED | Contains Phoenix `~> 1.8.9`, LiveView `~> 1.1.33`, Bandit `~> 1.12.1`, Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, Req `~> 0.6.1`; no override/direct Plug/Mint/hpax/Finch/Ecto/Decimal ownership. |
| `scrypath_ops/mix.lock` | Causal deterministic standalone resolution | ✓ VERIFIED | `mix deps.get --check-locked` passed; selected fixed cohort and transitive dependency versions match the contract. |
| `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` | Direct, service-free production Req-client contract | ⚠️ PARTIAL | Substantive and executed (2 tests pass), but its text/plain response leaves the required decode-body precedence invariant untested. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scrypath_ops/mix.exs` | `scrypath_ops/mix.lock` | Mix checked-lock resolution | ✓ WIRED | Fresh `mix deps.get --check-locked` succeeded and retained the lock. |
| `Swoosh.ApiClient.Req.post/4` | `Req.Test` | `email.private[:client_options]` `plug` tuple, retry disabled | ⚠️ PARTIAL | Direct test reaches the selected client and Req.Test; raw JSON / forced-decode precedence is not proven. |
| `config/prod.exs` | `Swoosh.ApiClient.Req` | `config :swoosh, api_client: ...` | ✓ WIRED | Production selection is explicit and unchanged. |
| Live Hex + EEF CNA | Postgrex manifest bound | fail-closed jq predicates | ✓ WIRED | Both predicates freshly passed before this report. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Swoosh Req contract | response body | `Req.Test` plug → real `Swoosh.ApiClient.Req.post/4` → Req response | Service-free synthetic transport response; text/plain branch only | ⚠️ PARTIAL |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Real Swoosh Req service-free contract | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` | 2 tests, 0 failures | ✗ INSUFFICIENT — not discriminating for decode-body contract |
| Checked lock / compile | `cd scrypath_ops && mix deps.get --check-locked && mix compile --warnings-as-errors` | Exit 0 | ✓ PASS |
| Unsuppressed advisory audit | `cd scrypath_ops && mix hex.audit` | Exit 0; no retired/advisory packages | ✓ PASS |
| Standalone Ops application | `mix verify.opsui` | 2 doctests, 154 tests, 0 failures | ✓ PASS |
| Live Postgrex evidence | Hex + EEF CNA `curl | jq` predicates | Both true | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Exact-SHA detached fresh resolver/audit | Candidate `59d2e6a` disposable worktree procedure recorded in `146-03-SUMMARY.md` | Compatible nine-package matrix, exact selected Plug live predicate, audit, and cleanup recorded PASS | PASS — corroborating historical evidence; no summary claim was used to excuse the failed client contract |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SEC-03 | 146-01, 146-02, 146-03 | Independently resolve ScrypathOps beyond recorded web, LiveView, mailer, HTTP, and database advisories. | ✗ BLOCKED | Dependency, audit, and Ops evidence are green, but the required configured Req-backed Swoosh raw/decode precedence behavior is not actually covered. |
| EVID-03 | 146-01, 146-03 | Block Postgrex changes until live advisory and Hex confirm a stable published fixed release. | ✓ SATISFIED | Fresh dual live predicates pass and the manifest/lock use 0.22.4. |

No orphaned Phase 146 requirements: all plans declare SEC-03 and/or EVID-03, the only roadmap requirements assigned to the phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` | 20 | Happy-path response is `Req.Test.text/2` / text/plain | 🛑 Blocker | The contractual `decode_body: false` precedence can regress with no test failure. |

No phase-owned source file contains an unreferenced `TBD`, `FIXME`, or `XXX` debt marker. The user-owned working-tree modifications to `.planning/REQUIREMENTS.md`, `.planning/config.json`, and `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` were preserved.

### Human Verification Required

None. The missing proof is deterministic and should be repaired with an automated Req.Test case, not a human checkpoint.

### Gaps Summary

WR-01 is a real must-have failure, not merely a code-review preference. Swoosh source currently documents and implements `Keyword.merge(options, required_options)` with `decode_body: false`; presence of that source code is useful but cannot replace the specified behavioral proof. The current test supplies a conflicting `decode_body: true`, but text/plain remains a binary under either setting. Add an `application/json` response and assert the raw JSON binary remains unchanged. Rerun the focused contract, checked-lock/compile, `mix verify.opsui`, and audit before re-verification.

---

_Verified: 2026-08-24T21:43:02Z_
_Verifier: the agent (gsd-verifier)_
