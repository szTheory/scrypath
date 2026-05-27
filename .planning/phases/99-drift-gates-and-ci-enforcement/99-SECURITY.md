---
phase: 99
slug: drift-gates-and-ci-enforcement
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-27
---

# Phase 99 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Documentation authority surfaces | `README.md`, `CONTRIBUTING.md`, support/intake guides, and example runbook must stay token-consistent for install/support/proof contracts. | Maintainer/operator expectations for supported and live-proof paths. |
| Verify task and local gate boundary | `mix verify.phase99` task implementation and alias wiring (`mix.exs`, task tests) define what trust checks are actually enforced locally/CI. | Trust-lane enforcement intent crossing into executable gate behavior. |
| CI required-check policy boundary | `.github/workflows/ci.yml` required job naming and `CONTRIBUTING.md` required/advisory policy wording drive merge expectations. | Branch-protection required-check identity and merge-governance policy. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T99-P1-001 | Integrity Drift (High) | Docs/proof contract surfaces | mitigate | Phase-owned deterministic contract suite (`test/scrypath/phase99_contract_test.exs`) validated via `mix verify.phase99` (36 tests, 0 failures). | closed |
| T99-P1-002 | False-Positive Noise (Medium) | Phase 99 contract tests | mitigate | Snapshot helpers remain banned; no `assert_snapshot`, `snapshot_assert`, or `matches_snapshot` tokens present. | closed |
| T99-P1-003 | Scope Creep (High) | Trust-hardening docs edits | mitigate | Runtime scope-expansion terms not present in audited docs surfaces; edits remain trust-contract scoped. | closed |
| T99-P2-001 | Coverage Bypass (High) | Phase 99 verify gate wiring | mitigate | `verify.phase99` token present across task implementation, task tests, and CLI preferred env wiring. | closed |
| T99-P2-002 | Gate Noise Regression (Medium) | `Mix.Tasks.Verify.Phase99` focused suite | mitigate | Focused suite contains only phase99 trust files; no live/service suite tokens in gate task source. | closed |
| T99-P2-003 | Alias Drift (Medium) | Alias parity across code/tests/docs | mitigate | `verify.phase97`/`verify.phase98`/`verify.phase99` tokens aligned across `mix.exs`, workflow wiring tests, and contributor docs. | closed |
| T99-P3-001 | Required-Check Rename Drift (High) | CI + docs/test required token parity | mitigate | Stable `phase99-trust` token present across workflow, docs, workflow wiring tests, and phase contract tests. | closed |
| T99-P3-002 | Policy Ambiguity (Medium) | Required vs advisory policy wording | mitigate | `CONTRIBUTING.md` explicitly defines required merge blockers and advisory heavy/live boundary language. | closed |
| T99-P3-003 | Scope Expansion Through CI Policy (High) | Required-check policy scope | mitigate | No heavy/live required-gate wording for disallowed jobs in `CONTRIBUTING.md` (`phase5-verification`, `phase13-verification`, `phoenix-example-integration`). | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-27 | 9 | 9 | 0 | Codex (secure-phase audit) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-27
