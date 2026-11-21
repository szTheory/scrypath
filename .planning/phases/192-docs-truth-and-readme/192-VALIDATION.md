---
phase: "192"
slug: docs-truth-and-readme
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-20"
---

# Phase 192 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: the "Validation Architecture" section of `192-RESEARCH.md`. No human UAT: every row is an executable check.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0, OTP 28); set `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` |
| **Config file** | `test/test_helper.exs` (excludes `:integration`, `:requires_clean_workspace`, `:postgres` by default) |
| **Quick run command** | `mix test test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract`, then `mix verify.package` and `mix verify.repository_contracts` on the committed head |
| **Estimated runtime** | quick about 3 s; doc-pin set about 3 s; full lanes about 19 min hosted |

---

## Sampling Rate

- **After every task commit:** the quick run command plus `mix format --check-formatted` on touched files.
- **After every plan wave / before each push:** `scripts/ci/pre_push.sh`, the doc-pin set (the `docs_contract` and related files, run by hand because `docs_contract_test.exs` is excluded from `core` and from `pre_push.sh`), and `mix docs --warnings-as-errors`; then the full suite command on the committed head.
- **Before `/gsd-verify-work`:** all required hosted lanes green on the exact head SHA.
- **Max feedback latency:** 5 s for the cheap checks.

---

## Per-Task Verification Map

| Check | Plan | Wave | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------|------|------|-------------|----------|-----------|-------------------|-------------|--------|
| Invariant plus planted cases | 01 | 1 | TRUTH-01 | unqualified repo-only task line in a shipped guide fails; qualified passes; list derived from the task directories; real shipped files clean | unit (in-memory strings plus real scan) | `mix test test/release/shipped_docs_contract_test.exs` | ❌ W0 | ⬜ pending |
| Pin inventory, contract and pin set | 01, 02 | 1, 2 | TRUTH-01, TRUTH-02 | every old pin accounted for; contract block passes the same qualifier | inventory plus pin set | the doc-pin set command in the plan; `192-PIN-INVENTORY.md` | ❌ W0 | ⬜ pending |
| README contract | 04 | 4 | README-01, README-02 | word cap, at most 3 onward links, no route block, prerequisite before first fence, quick path ends in a `Scrypath.search/3` result, schema parity, time-promise phrases fail, URL rules | unit (file reads) | `mix test test/scrypath/readme_contract_test.exs` | ❌ W0 | ⬜ pending |
| Owner map | 02 | 2 | README-03 | note exists and names one owner per required claim | table-shape test | same README test file | ❌ W0 | ⬜ pending |
| Built-docs scan and source link rule | 03 | 3 | TRUTH-03 | no self-link, unresolved extras link or dead anchor in extras pages; planted cases fail; header pin green | built-docs scan | `mix test test/release/package_metadata_test.exs` | extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/release/shipped_docs_contract_test.exs` — TRUTH-01 and TRUTH-02
- [ ] `test/scrypath/readme_contract_test.exs` — README-01 to README-03
- [ ] TRUTH-03 tests inside `test/release/package_metadata_test.exs` (`BuiltDocsBrandTest`)
- [ ] `192-PIN-INVENTORY.md` and `.planning/reference/CLAIM-OWNER-MAP.md`

---

## Manual-Only Verifications

All phase behaviors have automated verification. Recorded limits (what the checks do not prove): that the README reads better to a newcomer, time to first search, that the quick path runs against a live Meilisearch, live hex.pm or hexdocs.pm behavior, and that a qualifier sentence is itself accurate. None is a UAT item.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under 5 s for cheap checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
