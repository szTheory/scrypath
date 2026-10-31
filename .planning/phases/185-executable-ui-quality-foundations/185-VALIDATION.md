---
phase: "185"
slug: "executable-ui-quality-foundations"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-30"
---

# Phase 185 — Validation Strategy

Planning contract only; no implementation verification is claimed. Final task IDs and wave assignments are filled from the verified plans.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing root ExUnit, Node built-in tests, Phoenix ConnCase and Docker Playwright |
| Configuration | `mix.exs`, `dev/mix/tasks/verify.phase99.ex`, existing demo browser configuration |
| Quick required command | `mix verify.repository_contracts` |
| Core regression command | `mix test --exclude integration --exclude docs_contract` |
| Built mounted proof | `mix verify.ecommerce_mounted` |
| Full browser proof | `mix verify.ecommerce_e2e` |
| Feedback target | Focused pure scanner/token/contrast tests within 60 seconds; required command target 120 seconds; measure during execution |

Select the installed supported Elixir/OTP toolchain explicitly before local Mix commands. No package installation or new framework is planned. Preserve the five required CI jobs and advisory/path-scoped lanes.

## Sampling Rate

- Every task: focused automated tests including negative fixtures for the changed behavior.
- Every wave: canonical `mix verify.repository_contracts`; run built/browser checks when their inputs change.
- Before phase completion: CONTRIBUTING changed-scope verification and exact-source terminal closeout after tracked writes, with receipt outside frozen source.
- Long Docker/browser checks do not replace fast pure checks. No watch commands.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Pending final plan IDs | Pending | Pending | UIF-01 | Pending plan threat model | Trusted source, exact multiset and monotone history; missing evidence fails | ExUnit/temporary Git repositories | `mix verify.repository_contracts` | New tests required | Pending |
| Pending final plan IDs | Pending | Pending | UIF-02 | Pending plan threat model | Both generated bundles preserve supported utility namespaces and rendering | Build/browser | `mix verify.ecommerce_mounted` | Extend existing infrastructure | Pending |
| Pending final plan IDs | Pending | Pending | UIF-03 | Pending plan threat model | Fixed local redirect; mounted auth and storefront root preserved | ConnCase/browser | `mix verify.ops_ui` and `mix verify.ecommerce_mounted` | Extend existing route tests | Pending |
| Pending final plan IDs | Pending | Pending | UIF-04 | Pending plan threat model | Raw text/focus thresholds and malformed inputs fail through required command | ExUnit/Node | `mix verify.repository_contracts` | New root contracts required | Pending |
| Pending final plan IDs | Pending | Pending | UIF-05 | Pending plan threat model | Exact typed CSS/JSON mirror; independent mutations fail | Root ExUnit | `mix verify.repository_contracts` | New root contracts required | Pending |
| Pending final plan IDs | Pending | Pending | UIF-06 | Pending plan threat model | Paid/mock execution removed; historical receipts retain meaning | ExUnit/Node | `mix verify.repository_contracts` and `node --test scripts/ci/ecommerce_evidence.test.cjs` | Extend existing tests | Pending |

## Wave 0 Requirements

- [ ] Scanner/source-discovery and exact multiset negative fixtures, including trusted-ref bootstrap/history and cleanup reversals.
- [ ] Canonical command integration proving scanner/contrast/token subprocess failures propagate.
- [ ] Contrast below-threshold, dark-only, live-focus binding and malformed-input fixtures.
- [ ] Typed DTCG validator and independent CSS-only/JSON-only drift fixtures.
- [ ] Dual build-output assertions and matched rendering/state preservation proof using disposable stacks.
- [ ] Judge producer/consumer retirement and historical evidence compatibility tests.

Each owning plan creates tests before naming them as runnable verification. No new framework or dependency.

## Rendered Preservation and Review Boundaries

The approved UI-SPEC requires matched evidence for eight screens, three appearance modes and three viewports, plus full-page/hover/focus/compact-navigation and held-out state coverage. Map every UI consideration backstop to explicit tests or inspected matched captures. Use the same browser/platform/data/route/state/viewport and source-bound pre-change/candidate pair; report the intentional standalone generator redirect separately. Inspect actual images and copy. Capture completion is not pixel parity or independent design approval.

Retained-preview preflight is stopped. Preserve that stop and data. Disposable build/browser stacks have distinct projects, ports and artifacts and do not prove the retained preview is current. Store review evidence under `ui-review-artifacts/`, outside Playwright cleanup. No human UAT gate, simulated approval or automatic visual-baseline update.

## Validation Sign-Off

- [ ] Every final task has automated verification or explicit earlier test prerequisites.
- [ ] No three consecutive tasks lack fast automated feedback.
- [ ] Missing test paths are created by owning plans before invocation.
- [ ] No watch mode; measured focused feedback meets the target or documented limit.
- [ ] All six requirements and approved UI backstops mapped to concrete final task IDs.
- [ ] Implementation evidence reviewed before `nyquist_compliant` changes.

Approval: pending implementation evidence. This document records planned checks, not completed tests.
