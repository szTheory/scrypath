# Phase 159: Audit Gap Closure — Coverage Wiring and Verification Provenance - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 41 planned new/modified files (3 implementation/docs, 2 canonical Phase 159 receipts, 33 phase-local retrospective records, 1 audit, 2 phase-validation artifacts)  
**Analogs found:** 41 / 41

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | same file: `ecommerce-e2e` job | exact |
| `test/mix/tasks/workflow_wiring_test.exs` | test | transform | same file: job-scoped workflow assertions | exact |
| `CONTRIBUTING.md` | documentation | request-response | same file: CI job table and local command guidance | exact |
| `159-EVIDENCE-MATRIX.md` | documentation | transform | `147-CLOSURE-EVIDENCE.md` as summarized by `147-VERIFICATION.md` | role-match |
| `159-CLOSURE-RECEIPT.md` | documentation | batch | `136-DUALVERIFY-REPORT.md` | role-match |
| `148-quality-baseline/148-{SUMMARY,VERIFICATION,VALIDATION}.md` | documentation | batch | `147-03-SUMMARY.md`, `147-VERIFICATION.md`, `159-VALIDATION.md` | role-match |
| `{149..158}-*/{N}-{SUMMARY,VERIFICATION,VALIDATION}.md` | documentation | batch | `147-03-SUMMARY.md`, `147-VERIFICATION.md`, `159-VALIDATION.md` | role-match |
| `.planning/v1.37-MILESTONE-AUDIT.md` | documentation | transform | same file: three-source audit and final verdict | exact |
| `159-VALIDATION.md` | documentation | transform | same file: per-task verification map / Wave 0 checklist | exact |

`{149..158}-*` denotes the eleven phase directories named from the roadmap: 149 Runtime Safety Hardening through 158 Ratchet Closeout. They do not exist yet; create their phase directories and exactly three retrospective files each. These are not plan-execution reconstructions.

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml` `ecommerce-e2e` (lines 222-247).

**Trigger and advisory pattern** (lines 222-227):

```yaml
ecommerce-e2e:
  name: ecommerce-e2e (advisory)
  if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
  runs-on: ubuntu-latest
  continue-on-error: true
```

Copy its checkout/setup-beam/cache/dependency setup (lines 228-238), changing only the job/name/command. Preserve top-level `permissions: contents: read` (lines 11-12); no token, permission, or service is required.

**Always-upload, pinned artifact pattern** (lines 239-247):

```yaml
- run: mix verify.ecommerce_e2e
- name: Upload advisory E2E evidence
  if: always()
  uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7
  with:
    name: ecommerce-e2e-evidence
    path: examples/scrypath_ecommerce/test-results/docker-full
    if-no-files-found: warn
    retention-days: 7
```

For coverage, use a separate preceding `- run: mix verify.coverage`, an informational name containing `${{ github.sha }}`, `path: cover/`, and the same `always`, full SHA pin, warning, and seven-day values. Artifact collection is not producer success; the receipt must record both command/job conclusion and artifact metadata.

### `test/mix/tasks/workflow_wiring_test.exs` (test, transform)

**Analog:** same file, focused CI contract assertions and parser helper (lines 10-17, 410-430).

```elixir
ci = File.read!(@ci_yml)
core_job = workflow_job_block(ci, "core")

assert core_job =~ "mix verify.core"
...
defp workflow_job_block(content, job_name) do
  marker = "\n  #{job_name}:\n"
  {start_idx, marker_len} = :binary.match(content, marker)
  rest = binary_part(content, start_idx + marker_len, byte_size(content) - start_idx - marker_len)

  case Regex.run(~r/\n  [a-zA-Z0-9_-]+:\n/, rest, return: :index) do
    [{next_idx, _}] -> binary_part(rest, 0, next_idx)
    nil -> rest
  end
end
```

Add one `describe "TEST-05 ... coverage wiring"` block. Read the file once, isolate `workflow_job_block(ci, "coverage")`, and assert only within that block: exact event guard, `continue-on-error: true`, `mix verify.coverage`, upload-step `if: always()`, immutable upload-artifact pin, informational artifact name/SHA binding, `path: cover/`, `if-no-files-found: warn`, and `retention-days: 7`. Do not use a whole-workflow assertion that could pass from another job.

### `CONTRIBUTING.md` (documentation, request-response)

**Analog:** current capability command explanation (lines 49-58) and CI topology table (lines 114-131).

```markdown
# Produce a built-in line-coverage report for the fast suite. This is
# informational; Scrypath does not enforce a coverage percentage.
mix verify.coverage
```

```markdown
| **`ecommerce-e2e`** | Scheduled/manual advisory Docker/browser proof. `mix verify.ecommerce_e2e` runs the full lane and always uploads its bounded evidence bundle. |
...
Treat **`core`**, **`package`**, **`repository-contracts`**, **`backend`**, and **`ecommerce-mounted`** as required merge gates.
```

Extend this in the same two places: retain local reproduction plus state that `coverage` is scheduled/manual, advisory, and informational; point maintainers to the run artifact/re-dispatch recovery path. Do not imply a threshold, PR gate, badge, or hosted service.

### `159-EVIDENCE-MATRIX.md` (documentation, transform)

**Analog:** Phase 147 exact-SHA closure evidence pattern, verified in `.planning/milestones/v1.36-phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-VERIFICATION.md` lines 29-37 and 86-96.

```markdown
| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SEC-04 | 147-01, 147-02 | Independently remediate ecommerce on green mounted sources | ✓ SATISFIED | Fixed bounds/lock, current clean audit, canonical paths, exact-SHA evidence. |
```

Make this Phase 159 document the one canonical 31-row source. Each row must retain original owning phase and add: implementation commit/source locations; tests and commands; exactly one evidence class (`historically proven`, `present-state verified`, `supported by prior committed evidence`, or `historically unprovable`); exact SHA/date/environment or hosted run; limitation; and disposition. TEST-01 remains historically unprovable unless an extraction parent contains the relevant contract test and that parent passes in the detached probe. A waiver is narrow and explicit, never a rewritten requirement or synthetic pass.

### `159-CLOSURE-RECEIPT.md` (documentation, batch)

**Analog:** `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md` (lines 14-36, 45-58) plus its exact source identity fields (lines 16-25).

```markdown
| Field | Value |
| --- | --- |
| Source commit | `0494d92385c242da2fbb2c0bb0abd8775456639c` |
| Starting git status | Dirty working tree with pre-existing UI/demo changes; see `Starting Dirty Tree Transcript` below. |

| Gate | Command | Result |
| --- | --- | --- |
| Root ops UI gate | `mix verify.opsui` | PASS: 2 doctests, 147 tests, 0 failures. |
```

Record D-18 commands, versions, date, SHA, exit/result and scope for the local bundle. Separately record the one hosted exact-SHA run: URL, trigger, attempt, workflow SHA/source SHA, required/advisory conclusions, coverage artifact name/path/digest/retention, and any unavailable advisory lane. Link to the matrix; do not duplicate its 31 narratives.

### Retrospective phase indexes — `148..158` `SUMMARY.md`, `VERIFICATION.md`, `VALIDATION.md` (documentation, batch)

**Summary analog:** `.planning/milestones/v1.36-phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-03-SUMMARY.md` lines 21-31: a bounded receipt and explicit preservation note.

```markdown
## Preservation

- The pre-existing ... changes are preserved as user-owned working-tree changes and excluded from the Phase 147 closure commit.
...
## Self-Check: PASSED

- Four independent, nonempty rows appear in required order.
```

**Verification analog:** `147-VERIFICATION.md` lines 17-39 and 86-96.

```markdown
### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
...
### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
```

**Validation analog:** current `159-VALIDATION.md` lines 37-56, especially the per-task map and Wave 0 ordering.

```markdown
| Task ID | Plan | Wave | Requirement | ... | Automated Command | File Exists | Status |
| ... | ... | ... | ... | --- | --- | --- | --- |
```

For every phase, summary begins with an explicit retrospective/not-contemporaneous disclaimer and a link to `159-EVIDENCE-MATRIX.md`. Verification links only that phase's requirements to current/provenance evidence and marks the class/limits; it must not assert a historical action merely from a fresh run. Validation is created after that phase's summary and verification, performs a real requirement-specific Nyquist judgment, and must not copy a blanket pass template. Keep all three short indexes rather than parallel evidence sources.

### `.planning/v1.37-MILESTONE-AUDIT.md` (documentation, transform)

**Analog:** same file's fail-closed audit matrix (lines 276-328) and verdict contract (lines 257-265).

```markdown
The formal GSD milestone audit also fails closed because phases 148–158 were executed directly and have no phase `SUMMARY.md`, `VERIFICATION.md`, or `VALIDATION.md` artifacts.
...
| Requirement | Phase | REQUIREMENTS.md | SUMMARY.md | VERIFICATION.md | Formal status |
```

Rerun only after coverage structural proof, the canonical matrix, phase-local records/validations, local receipt, and exact-SHA hosted receipt exist. Update facts and scores from those inputs; preserve TEST-01 as a scoped override/waiver if chronology remains irrecoverable. Never convert a provenance limitation into “passed” because current tests succeed.

### `159-VALIDATION.md` (documentation, transform)

**Analog:** same file's current structure (lines 37-75). Keep the task-to-command table and Wave 0 dependencies current as implementation proceeds; set `nyquist_compliant: true` only after the phase-local inputs and real checks exist.

## Shared Patterns

### Advisory CI and artifact provenance

**Sources:** `.github/workflows/ci.yml` lines 222-247; `test/mix/tasks/workflow_wiring_test.exs` lines 420-430.  
**Apply to:** CI job and its structural test.

The job guard is schedule/manual only; `continue-on-error: true` keeps it advisory. Every action stays fully SHA-pinned, permissions remain read-only, and an upload step uses `if: always()` with warning-on-absence and seven-day retention. Scope all assertions through `workflow_job_block/2`.

### Evidence-class discipline

**Sources:** `159-CONTEXT.md` D-07–D-11; `147-VERIFICATION.md` lines 104-108.  
**Apply to:** matrix, receipt, all retrospective verification/validation reports, and re-audit.

Current tests prove current behavior. Prior committed receipts support only what they actually record. Historical characterization is proven only by a parent-snapshot test-presence and passing probe. Any other timeline is explicitly historically unprovable, with a narrow waiver when required.

### Exact-SHA receipts and independent lanes

**Sources:** `136-DUALVERIFY-REPORT.md` lines 16-36; `147-VERIFICATION.md` lines 72-84.  
**Apply to:** closure receipt and hosted evidence.

Capture SHA, command, timestamp, environment, result, and lane classification. Keep required proof distinct from advisory/path-scoped/unavailable proof; artifact presence never substitutes for a successful producer.

### Repository-owned changes only

**Source:** observed `git status --short` before mapping.  
**Apply to:** every execution task.

The worktree already has user-owned changes to `.planning/ROADMAP.md`, two UAT files, the Phase 159 `.gitkeep`, and `.planning/research/.cache/`. Preserve them; detached parent probes must never use or mutate the primary checkout.

## No Analog Found

None. The repository has close role matches for workflow wiring, contributor CI documentation, exact-SHA receipts, verification reports, and validation contracts. The retrospective disclaimer/evidence-class taxonomy is Phase 159-specific policy, but it composes those existing report patterns rather than requiring a new artifact format.

## Metadata

**Analog search scope:** `.github/workflows/`, `test/mix/tasks/`, `lib/mix/tasks/`, `CONTRIBUTING.md`, `.planning/phases/`, `.planning/milestones/`, milestone audit and quality ledger.  
**Files scanned:** 15 primary code/evidence artifacts plus phase/roadmap indexes.  
**Pattern extraction date:** 2026-08-26
