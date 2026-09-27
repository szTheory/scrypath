---
phase: "167"
slug: "dated-readiness-and-closeout"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 167 — Validation Strategy

> Draft validation contract for the dated readiness assessment and exact-source closeout.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python standard-library `unittest` for the current-phase structural contract; existing ExUnit for the readiness documentation contract if its source changes |
| **Config file** | None; follow the archived standalone checker and fixture pattern |
| **Quick run command** | `python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v` |
| **Full suite command** | Focused Python contract suite, then `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/readiness_contract_test.exs` if the support guide changes |
| **Estimated runtime** | Local Python checks under 10 seconds; hosted exact-source closeout is an external gate |

---

## Sampling Rate

- **After every task commit:** Run the focused Python structural/history-preservation suite when its Wave 0 test exists.
- **After every plan wave:** Run the focused suite and any applicable existing support-guide contract.
- **Before `$gsd-verify-work`:** Confirm local contract checks and the applicable candidate/final-source closeout evidence.
- **Max feedback latency:** 10 seconds for local Python checks; hosted closeout latency is external.

---

## Per-Task Verification Map

Task IDs and wave assignments will be filled from the accepted plans.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Pending plan assignment | Pending | Pending | GATE-04 | — | Historical evidence remains unchanged; structural checks do not claim semantic readiness | unit + source preservation | `python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v` | Wave 0 planned | ⬜ pending |
| Pending plan assignment | Pending | Pending | CLOSE-03 | — | Source identities and owned cleanup have explicit, bounded dispositions | unit + source inspection | `python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v` | Wave 0 planned | ⬜ pending |
| Pending plan assignment | Pending | Pending | VERIFY-02 | — | Every software claim joins to a named scenario and exact source; advisory result stays distinct from required gates | evidence join + hosted closeout | `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"` | Existing topology | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Add a current-phase structural checker and focused standard-library fixtures without changing the archived Phase 164 checker.
- [ ] Cover historical assessment byte preservation, six-condition shape and status arithmetic, truthful date fields, exact source/receipt identities, and current owned-cleanup disposition.
- [ ] Keep structural validation separate from semantic readiness and hosted source attestation.

---

## Manual-Only Verifications

All software acceptance claims use automated scenario evidence or exact-SHA hosted evidence; routine human UAT is not required. The six-condition semantic assessment remains a maintainer evidence judgment and must cite its sources and claim limits; the structural checker cannot approve it.

---

## Validation Sign-Off

- [ ] All accepted plan tasks have `<automated>` verification or a Wave 0 dependency.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers each planned MISSING reference.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 10 seconds for focused local checks.
- [ ] Set `nyquist_compliant: true` only after the strategy is validated against the accepted plans.

**Approval:** pending
