---
phase: 106
slug: fan-out-reflection-contract-repair
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-31
---

# Phase 106 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Schema declaration reflection boundary | `use Scrypath, fan_outs:` declarations in adopter schemas become generated `__scrypath__(:fan_outs)` metadata. | Fan-out target and resolver metadata crossing from compile-time declaration into runtime reflection. |
| Related sync runtime boundary | `Scrypath.sync_related/3` and `Scrypath.Sync.RelatedWorker` consume owner-schema fan-out reflection to resolve and upsert related target records. | Owner records or document IDs, fan-out keys, resolver output, backend config. |
| Phase verification boundary | `mix verify.phase106` defines the focused local proof for the fan-out reflection repair without promoting broader CI or public API surface. | Phase contract claims crossing into executable test selection and Mix task wiring. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-106-001 | Tampering (Medium) | Generated fan-out metadata | mitigate | `lib/scrypath/schema.ex` defines `def __scrypath__(:fan_outs), do: @scrypath_config.fan_outs`; `test/scrypath/schema_test.exs` asserts the exact reflected keyword list for ordinary `use Scrypath, fan_outs:` declarations. Current detection: `mix test test/scrypath/schema_test.exs` passed, 9 tests, 0 failures. | closed |
| T-106-002 | Integrity (Medium) | Owner-only and generated related-sync compatibility | mitigate | Existing hand-written owner fixtures remain in `test/scrypath/sync/related_test.exs` and `test/scrypath/sync/related_worker_test.exs`; generated ordinary-source fixtures now prove inline and worker consumption through `Scrypath.sync_related/3` and `RelatedWorker.perform/1`. Current detection: related sync/worker tests passed, 13 tests, 0 failures. | closed |
| T-106-003 | Scope Creep (High) | Public fan-out API and validation surface | mitigate | No `Scrypath.FanOuts`, `schema_fan_outs`, or `__scrypath_generated__` tokens exist in `lib/` or `test/`; `mix verify.phase106` is a focused service-free gate and no CI topology promotion was added. Current detection: forbidden-token `rg` check passed and `mix verify.phase106` passed, 25 tests, 0 failures. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-31 | 3 | 3 | 0 | Codex (secure-phase audit) |

---

## Audit Notes

- Summary threat flags: none found in `106-01-SUMMARY.md`.
- `106-REVIEW.md` records three advisory warnings around Mix task argument ordering, explicit Oban enqueue assertions, and conditional worker-test loading. These are test-hardening follow-ups, not open Phase 106 security threats, because all plan-time threat mitigations are present and current detection commands pass.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-31
