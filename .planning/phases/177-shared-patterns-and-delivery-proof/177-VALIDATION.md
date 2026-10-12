---
phase: "177"
slug: "shared-patterns-and-delivery-proof"
status: audited
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-11"
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for the six-surface UI audit and bounded delivery evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView; Playwright for existing browser lanes |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/package.json` |
| **Quick run command** | `mix verify.ops_ui` from the repository root |
| **Full phase UI command** | `mix verify.ops_ui`, plus only the affected existing screenshot, contrast, browser, or mounted target |
| **Estimated runtime** | Not measured in the current shell; record observed duration when the corresponding lane runs |

There is no approved new framework, dependency, CI service, or paid visual judge in scope. The final exact-SHA closeout is `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`, after all tracked completion bookkeeping.

## Sampling Rate

- After a task changes Ops UI source or a contract test, run `mix verify.ops_ui`.
- For a token/color change, also run `make contrast` and the relevant existing `make contrast-matrix` lane.
- For every changed rendered slice, capture and directly inspect matched before/after screenshots at light, dark, and System-dark across 390×844, 768×900, and 1440×900; run the existing browser/layout/state target for that slice. System-dark capture leaves `phx:theme` unset, emulates dark `colorScheme`, and asserts System mode and effective dark. If the matching route/state is absent from existing fixtures, extend only the existing screenshot matrix with that fixture-backed capture.
- Run `make verify-mounted` only if the change touches a recovery handoff; keep its task-owned cleanup and evidence.
- Before completion, run the existing source-specific checks required for the final diff, record exact-SHA hosted review/check evidence, decide release/no-release from the Hex package file set, and only then run exact-SHA closeout.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-----------------------------|-------------|--------|
| 177-01 T1–T3; 177-02 T1–T2; 177-03 T1–T2; 177-04 T1–T2 | Plans 177-01 through 177-04 | Waves 1–4 | OPUX-26 | — | Preserve contextual grouping, eligibility, truthful states, complete identity/reasons, and distinct safe actions across six surfaces. | ExUnit behavioral suites + Ops UI gate; catalog contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 HEX_HOME=/private/tmp/scrypath-phase177-hex mix verify.ops_ui` (rerun: 2 doctests, 302 tests, 0 failures); Plan 177-01 token contract 8 tests, Plan 177-02 contract 9 tests; Plans 177-03/04 six named LiveView suites (68 and 55 focused tests) recorded passing in summaries | ✅ Existing tests | ✅ green |
| 177-01 T2–T3; 177-02 T2; 177-03 T1–T2; 177-04 T1–T2 | Plans 177-01 through 177-04 | Waves 1–4 | OPUX-27 | — | Preserve keyboard access, visible focus, reduced motion, theme behavior, safe task identity, and responsive content/control reachability. | ExUnit + browser/layout/contrast; direct six-surface image inspection | Existing run records: `npm run test:e2e:admin-depth` (38 passed); full Ops gate above; `make contrast` (0 AA failures); `make contrast-matrix` (3 scenarios); 90-image matrix (10 route/state captures × 3 themes × 3 widths), with selected before/after pairs directly inspected. Evidence and image/source limits are documented in `177-UI-AUDIT.md` and summaries; these browser/image lanes were not rerun in this audit. | ✅ Existing screenshot matrix and lanes | ✅ green (per recorded exact-source evidence) |
| 177-05 T1–T3 | Plan 177-05 | Wave 5 | OPUX-28 | T-177-05, T-177-06 | Bind claims to source identities and exact check SHAs; preserve unresolved hosted facts and task-owned cleanup boundaries. | Trace artifact validator + hosted evidence + package gate + final attestation | 20-row ordered trace validator and `git diff --check` passed; summary records `mix verify.package` (81 tests, package built) and five required checks on PR head `38e5752523c9906854af678e5a57f62bbb1d2d25`. User waiver of formal review is recorded and is not represented as a review. Final exact-source `ci_monitor.cjs closeout` has not run and remains a separate pending phase closeout. | ✅ Trace and evidence records exist | ⚠️ partial; attestation pending |

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements; extend the current Playwright screenshot matrix for direct visual samples without installing a new framework, dependency, or service.
- Create the committed 20-requirement evidence trace and root `DESIGN.md` as planned artifacts; visually inspect all six surfaces before deciding whether any source correction is warranted.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Direct before/after rendered-image inspection across the six surfaces | OPUX-27 | Visual pattern drift and hierarchy need direct inspection in addition to automated layout/state/contrast evidence. This is an execution record, not pending routine human UAT. | The existing screenshot matrix captures each representative state for all six surfaces in explicit light, explicit dark, and System-dark at 390×844, 768×900, and 1440×900. System-dark leaves `phx:theme` unset, emulates dark `colorScheme`, and asserts System mode and effective dark. For each changed slice inspect matched before/after images for all nine theme/viewport combinations; if its exact route/state is not in the current fixtures, add a fixture-backed entry to that existing matrix. Record generated paths and exact source/route/state/theme/viewport identities. Automated behavior/layout/contrast evidence stays separate and complementary. |
| Reviewed PR source and hosted required checks | OPUX-28 | Local test results cannot establish that a reviewer approved the delivered PR head or that hosted checks ran on that same SHA. | Record PR URL, reviewed head SHA, review commit, each required run URL and tested SHA, and outcome. Leave unavailable evidence explicitly unresolved. |

## Validation Sign-Off

- [x] Every planned task has an automated verification command or documented artifact gate.
- [x] Sampling continuity has no three consecutive tasks without executable or artifact verification.
- [x] Wave 0 creates no new framework/dependency and covers only actual missing validation artifacts.
- [x] No watch-mode flags are used.
- [x] Feedback latency is recorded from actual runs; no runtime estimate is invented. The rerun of `mix verify.ops_ui` completed in about 17 seconds after dependency compilation began.
- [ ] `nyquist_compliant: true` is set after execution evidence is complete. OPUX-28's exact-source final attestation remains pending.

**Approval:** partial — OPUX-26 and OPUX-27 validation is filled; OPUX-28 is locally trace-validated, with final exact-source attestation pending.
