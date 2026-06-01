---
phase: 112
slug: public-website-and-docs-truth-alignment
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 112 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| planning truth -> public scope guide | Internal scope-guard posture is translated into adopter-facing public documentation. | Scope policy, feature-lane reopen criteria, non-goal statements |
| root public docs -> HexDocs publication | README and guide-map routes must point to published guide surfaces. | Public docs links and ExDoc extras/navigation metadata |
| new scope guide -> guide maps and maintainer docs | The canonical reopen rule can drift when summarized into guide-index or maintainer-support prose. | Reopen trigger language and scope authority links |
| done posture -> future-feature commentary | Maintainer docs can accidentally re-open product breadth through casual wording. | Future-work guidance, support posture, JTBD framing |
| canonical docs/guides -> website copy | Website summaries can drift into broader or less honest claims than the underlying guides support. | Claim envelope, fit/non-fit positioning, route-map links |
| website source pages -> built site | Route-map or heading changes must survive the static website build and check. | Static HTML source and generated `website/dist` output |
| public truth surfaces -> focused contract suite | Drift in claim envelope or route-map boundaries must be translated into deterministic assertions without noisy repo-wide scanning. | Public copy tokens, route tokens, negative claim families |
| task source/help -> maintainer behavior | Task help, source, registration, and contributor docs must stay aligned so maintainers can run the proof. | Mix task source, test list, preferred env registration, CONTRIBUTING guidance |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-112-01 | Tampering | `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md` | mitigate | Scope pressure routes to `guides/scope-and-reopen-policy.md` from README, support, and intake surfaces; each surface stays route-first instead of duplicating policy bodies. Evidence: `README.md:30`, `guides/support-and-compatibility.md:112`, `guides/outside-adopter-intake.md:17`. | closed |
| T-112-02 | Elevation of Privilege | `guides/scope-and-reopen-policy.md` | mitigate | The policy guide is the canonical authority and freezes the three reopen triggers plus current out-of-scope classes. Evidence: `guides/scope-and-reopen-policy.md:1`, `guides/scope-and-reopen-policy.md:13`, `guides/scope-and-reopen-policy.md:14`, `guides/scope-and-reopen-policy.md:15`, `guides/scope-and-reopen-policy.md:23`. | closed |
| T-112-03 | Denial of Service | `mix.exs` ExDoc registration | mitigate | The new guide is registered in ExDoc extras and the Getting Started group; `mix docs --warnings-as-errors` passed on 2026-06-01. Evidence: `mix.exs:173`, `mix.exs:204`. | closed |
| T-112-04 | Tampering | `guides/overview.md`, `guides/sync-modes-and-visibility.md` | mitigate | Guide-map and sync-semantics docs use the canonical descriptor and route scope pressure to the policy guide while keeping sync semantics narrow. Evidence: `guides/overview.md:3`, `guides/overview.md:27`, `guides/sync-modes-and-visibility.md:3`, `guides/sync-modes-and-visibility.md:126`. | closed |
| T-112-05 | Elevation of Privilege | `docs/operator-support.md`, `docs/jtbd-gap-map.md` | mitigate | Maintainer-facing docs use the exact three-trigger rule and preserve feature-lane reopening through the scope policy. Evidence: `docs/operator-support.md:31`, `docs/jtbd-gap-map.md:79`, `docs/jtbd-gap-map.md:191`. | closed |
| T-112-06 | Tampering | `website/src/pages/*.html` copy | mitigate | Website pages use the fixed Ecto-native claim envelope and route scope/fit claims to policy surfaces. Evidence: `website/src/pages/index.html:6`, `website/src/pages/evaluate.html:105`, `website/src/pages/evaluate.html:114`. | closed |
| T-112-07 | Denial of Service | route-map links | mitigate | Website docs routes include README and scope-policy links; static build and website check passed on 2026-06-01. Evidence: `website/src/pages/docs.html:20`. | closed |
| T-112-08 | Elevation of Privilege | website information architecture | mitigate | Website operators/evaluate pages remain summary-depth and route feature pressure into the policy path; runbook-depth tokens are guarded by the Phase 112 contract test. Evidence: `website/src/pages/operators.html:14`, `website/src/pages/operators.html:113`, `test/scrypath/phase112_contract_test.exs:110`. | closed |
| T-112-09 | Tampering | `test/scrypath/phase112_contract_test.exs` | mitigate | Contract tests assert positive route/claim tokens, scoped misleading-claim negatives, and website-only runbook-token checks; `mix verify.phase112` passed on 2026-06-01. Evidence: `test/scrypath/phase112_contract_test.exs:55`, `test/scrypath/phase112_contract_test.exs:57`, `test/scrypath/phase112_contract_test.exs:110`. | closed |
| T-112-10 | Repudiation | `lib/mix/tasks/verify.phase112.ex`, `test/mix/tasks/verify.phase112_test.exs` | mitigate | The Mix task has an auditable focused test list, no-arg guard, progress marker, and self-tests for source/help/registration. Evidence: `lib/mix/tasks/verify.phase112.ex:8`, `lib/mix/tasks/verify.phase112.ex:17`, `lib/mix/tasks/verify.phase112.ex:30`, `test/mix/tasks/verify.phase112_test.exs:7`, `test/mix/tasks/verify.phase112_test.exs:27`. | closed |
| T-112-11 | Denial of Service | `mix.exs`, `CONTRIBUTING.md` discoverability | mitigate | `verify.phase112` is registered for the test env and documented in CONTRIBUTING for public truth-copy changes. Evidence: `mix.exs:69`, `CONTRIBUTING.md:73`. | closed |
| T-112-SC | Tampering | npm/pip/cargo installs | accept | Phase 112 introduced no new package-manager installs; plans 112-01 through 112-04 accepted this as an explicit non-change supply-chain risk. No implementation dependency changes were required for the security verification. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-112-01 | T-112-SC | Phase 112 reused existing tooling and introduced no npm, pip, or cargo package-manager installs, so there is no new supply-chain surface to mitigate in this phase. | GSD security verification | 2026-06-01 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Threats found | 12 |
| Closed | 12 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 12 | 12 | 0 | Codex / gsd-secure-phase |

## Verification Evidence

| Command | Result |
|---------|--------|
| `mix docs --warnings-as-errors` | passed |
| `npm --prefix website run build && npm --prefix website run check` | passed |
| `mix verify.phase112` | passed, 8 tests, 0 failures |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-01
