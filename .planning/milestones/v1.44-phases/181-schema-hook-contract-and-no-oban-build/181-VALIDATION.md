---
phase: "181"
slug: "schema-hook-contract-and-no-oban-build"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-26"
validated: "2026-10-26"
source_sha: c47c1216d0ae2e5c491751551f9aa019c619b3c6
pending_hosted_evidence: false
hosted_source_sha: cd3eb07f037b73e8c1f4e0d579513f18ec17f50e
hosted_run: https://github.com/szTheory/scrypath/actions/runs/40368375825
---

# Phase 181 — Validation Strategy

> Post-execution audit: local behavioral checks and exact-SHA hosted core pass.
> Run 40368375825 at cd3eb07f includes the isolated no-Oban absence proof.
> This closes the automated shipping dependency without manual UAT.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0 / OTP 28.1), `Code.with_diagnostics/1` |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath/schema_test.exs test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_no_optional_deps_test.exs test/scrypath/sync/related_worker_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` + `mix verify.package` |
| **Estimated runtime** | ~120 seconds (quick ~20s; no-Oban isolated build ~60s) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command plus `mix verify.no_optional_deps`
- **After every plan wave:** `mix compile --warnings-as-errors --force`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green, plus green `core (required)` on the PR's exact SHA
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | Failing direction | File Exists | Status |
|-----|----------|-----------|-------------------|-------------------|-------------|--------|
| HYG-01 | Three hooks are `@optional_callbacks` on `Scrypath.Schema` | unit | `mix test test/scrypath/schema_test.exs` | missing optional callbacks fail | ✅ present | ✅ local pass |
| HYG-01 | Callbacks present in docs chunk | unit | same | missing callback docs fail | ✅ present | ✅ local pass |
| HYG-01 | `use Scrypath` modules carry `@behaviour Scrypath.Schema` | unit | same | missing behaviour attribute fails | ✅ present | ✅ local pass |
| HYG-01 | Wrong-arity hook flagged at compile | unit | same (`Code.with_diagnostics`) | wrong arity must produce a located warning | ✅ present | ✅ local pass |
| HYG-01 | Correct hooks → zero diagnostics | unit | same | guards over-eager check | ✅ present | ✅ local pass |
| HYG-01 | HexDocs build warning-free | docs | `mix docs --warnings-as-errors` | broken `c:` links | ✅ existing | ✅ local pass |
| HYG-02 | No-Oban build compiles with `--warnings-as-errors` | build | `mix verify.no_optional_deps` | fails at `lib/scrypath/sync.ex:74:12` once task is isolated | ✅ present | ✅ local pass |
| HYG-02 | Task proves Oban absent (no false green) | unit | `mix test test/mix/tasks/verify_no_optional_deps_test.exs` | fake build dir with `lib/oban` → `Mix.Error` | ✅ present | ✅ local pass |
| HYG-02 | `verify.core` runs the no-Oban build | unit | `mix test test/mix/tasks/verify_capability_test.exs` | sequence assertion fails until composed | ✅ present | ✅ local pass |
| HYG-02 | No blanket suppression | contract | `mix test test/mix/tasks/workflow_wiring_test.exs` (or new contract test) | adding `elixirc_options` / `put_compiler_option` fails it | ✅ present | ✅ local pass |
| HYG-02 | Related Oban enqueue unchanged | unit | `mix test test/scrypath/sync/related_worker_test.exs test/scrypath/sync_test.exs test/scrypath/oban_test.exs` | job-shape / unique assertions | ✅ existing | ✅ local pass |
| HYG-02 | Runs on phase PR in a required lane | hosted | `core (required)` log shows the no-optional-deps compile | exact-SHA PR run | n/a | ✅ run 40368375825 / cd3eb07f |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/mix/tasks/verify_no_optional_deps_test.exs` — seam tests for build-path isolation, env, and optional-dep absence guard (pure function, no subprocess compile)
- [x] Injectable runner for `Capability.run(:core, …)` so the sequence is testable without running the real gate

---

## Manual-Only Verifications

All phase behaviors have automated verification (hosted CI evidence is exact-SHA, not human UAT).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 120s (target retained; not measured in this audit)
- [x] `nyquist_compliant: true` set in frontmatter

**Audit:** local coverage and hosted core evidence complete. The feedback-latency target above remains unmeasured; no timing guarantee, manual approval or independent audit is claimed.


## Requirement and Task Coverage Audit — 2026-10-26

The audit read both plans and summaries and matched their six tasks to existing
executable coverage. No missing local test was found, so no additional test-only
validation pass was needed after the review fixes.

| Task | Requirement | Behavioral evidence | Result |
|------|-------------|---------------------|--------|
| 181-01 task 1 | HYG-02 | NoOptionalDeps seam tests, related enqueue/worker tests, real Oban Lite uniqueness tests; actual isolated compile | COVERED locally |
| 181-01 task 2 | HYG-02 | Capability core sequence and workflow-wiring contracts, including WR-03 negative cases | COVERED locally |
| 181-01 task 3 | HYG-02 | Core gate plus docs-contract/package-metadata suite; hosted core job 121732151292 at cd3eb07f | COVERED: hosted absence proof recorded |
| 181-02 task 1 | HYG-01 | Schema callback/reflection, docs chunk and located wrong-arity diagnostic tests | COVERED locally |
| 181-02 task 2 | HYG-01 | Correct/absent/helper/private/mixed-behaviour fixtures and runtime-probe drift guard | COVERED locally |
| 181-02 task 3 | HYG-01 | Warning-free docs build within core and package contract/build | COVERED locally |

Additional review-fix cases pin the public custom-id enqueue exception and prove
that `@impl Scrypath.Schema` resolves mixed-behaviour diagnostics. The AST guard
accepts targeted Oban MFAs and rejects non-Oban, blanket and dynamic targets.

### Fresh Local Results

All commands ran inline in `/Users/jon/projects/scrypath` on source
`c47c1216d0ae2e5c491751551f9aa019c619b3c6`, Elixir 1.19.0 / OTP 28.1.
Set `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1` to reproduce.

| Command | Evidence |
|---------|----------|
| Focused schema/enqueue/workflow-wiring tests, warnings as errors | 90 tests, 0 failures |
| `mix verify.core --exclude integration --exclude docs_contract` | 953 tests, 5 properties, 0 failures; formatting, workspace cleanliness, strict compile, Credo and docs pass |
| Actual no-Oban compile within core | 148 files compiled; `Verified optional dependencies absent from isolated build: oban` |
| `mix verify.package` | 81 tests, 0 failures; unpacked package build passes |
| `mix test --warnings-as-errors test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract` | 79 tests, 0 failures |

### Hosted Evidence — 2026-10-26

[PR #122 run 40368375825](https://github.com/szTheory/scrypath/actions/runs/40368375825)
ran at `cd3eb07f037b73e8c1f4e0d579513f18ec17f50e`. Its
[core job 121732151292](https://github.com/szTheory/scrypath/actions/runs/40368375825/job/121732151292)
passed with `5 properties, 953 tests, 0 failures (101 excluded)` and
`Verified optional dependencies absent from isolated build: oban`.
The backend job also passed the shared real-Postgres suite: 1 property,
15 tests, 0 failures. These receipts close the hosted coverage gap for this
source. Subsequent tracking-only commits still need their own required checks;
milestone closeout attestations remain separate. No human UAT is required.

## Validation Audit 2026-10-26

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |
| Pending hosted | 0 |
