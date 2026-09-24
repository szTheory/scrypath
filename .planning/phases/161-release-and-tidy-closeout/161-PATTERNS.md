# Phase 161: Release and Tidy Closeout - Pattern Map

**Mapped:** 2026-09-24  
**Files analyzed:** 9 likely new or modified files  
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `mix.lock` | config | dependency resolution | `mix.lock` | exact existing file |
| `examples/phoenix_meilisearch/README.md` | documentation | request-response proof runbook | same file | exact existing file |
| `CONTRIBUTING.md` | documentation | batch verification guidance | same file | exact existing file |
| `docs/releasing.md` | documentation | event-driven release guidance | same file | exact existing file |
| `test/scrypath/docs_contract_test.exs` | test | file-I/O, contract validation | same file | exact existing file |
| `.planning/phases/161-release-and-tidy-closeout/161-VALIDATION.md` | planning evidence | batch verification | `.planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md` | role and flow match |
| `.planning/phases/161-release-and-tidy-closeout/161-VERIFICATION.md` | planning evidence | batch verification | `.planning/phases/160-package-backed-phoenix-proof/160-VERIFICATION.md` | role and flow match |
| Phase 161 `*-SUMMARY.md` files, as plans are executed | planning evidence | batch closeout | `.planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md` | role and flow match |
| `.planning/STATE.md` / `.planning/ROADMAP.md`, only for milestone disposition | planning state | event-driven closeout | current same files; Phase 160 verification and summary supply evidence structure | partial, conditional |

`mix.exs`, `CHANGELOG.md`, `.release-please-manifest.json`, and release workflow files are **read-only parity references** for this phase unless the dependency solver or Release Please generated PR demonstrates a necessary change. The current instructions call for reuse of release automation, not a new workflow. No source module is implied. Do not edit unrelated worktree entries to satisfy cleanup.

## Pattern Assignments

### `mix.lock` (config, dependency resolution)

**Analog:** tracked `mix.lock` itself. Its Finch edge at line 19 declares `{:mint, "~> 1.8", ...}`; line 26 resolves Mint `1.9.3` with package hashes and dependency metadata. Preserve Hex's resolver-produced tuple and review the graph diff; never hand-author checksums.

```elixir
# mix.lock:19 (excerpt)
{:mint, "~> 1.8", [hex: :mint, repo: "hexpm", optional: false]}
# mix.lock:26 (existing resolved entry prefix)
"mint": {:hex, :mint, "1.9.3", ...}
```

The target is Mint `1.10.1` or later per D-01. Keep Mint transitive if the existing Finch range resolves it. `mix verify.deep_quality` is the canonical audit path (`CONTRIBUTING.md:37`, `.github/workflows/ci.yml:134-150`).

### `examples/phoenix_meilisearch/README.md` (documentation, request-response proof runbook)

**Analog:** same tracked file, lines 3-7, 27-46, 66-71. Extend its existing proof boundary and runbook rather than opening a second runbook.

```markdown
<!-- examples/phoenix_meilisearch/README.md:5-7 -->
This README is the proof/runbook surface for the real-service path.
From the repository root, `mix verify.phoenix_example` runs this live proof using the example's normal `path:` dependency. `mix verify.phoenix_example --package` builds and unpacks Scrypath from the current checkout, stages an isolated copy of the example, and runs the same integration scenarios against the locally tagged package artifact.
```

Keep the prerequisite table at lines 29-35 and ordered CI commands at lines 39-46 aligned with `.github/workflows/ci.yml`. The four scenario bullets at lines 68-71 are the concrete coverage vocabulary: inline, Oban, related-data inline, and related-data Oban. Add a precise synthetic/contract-evidence limit next to these claims; Phase 160's hosted real-service proof is documented in `160-VALIDATION.md:45-60`.

### `CONTRIBUTING.md` (documentation, batch verification guidance)

**Analog:** same tracked file, lines 26-40, 67-83, 92-100. Keep detailed service setup in the example README and give maintainers commands plus a link.

```markdown
<!-- CONTRIBUTING.md:37-40 -->
| Deep quality | `mix verify.deep_quality` | No-optional-deps, namespace, Hex audit, and Dialyzer checks |
| Phoenix example | `mix verify.phoenix_example` / `mix verify.phoenix_example --package` | Live path-backed and package-backed consumer proof (`mix verify.adopter --live`) |
```

The candidate/final exact-SHA invocation is at lines 67-83:

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch "$(git branch --show-current)" \
  --sha "$(git rev-parse HEAD)"
```

The helper validates a full SHA (`scripts/ci_monitor.cjs:119-123`) and checks the five required jobs, coverage, closeout attestation, and SHA-bound artifacts (`scripts/ci_monitor.cjs:187-209`). Preserve this distinction when wording required versus advisory results.

### `docs/releasing.md` (documentation, event-driven release guidance)

**Analog:** same tracked file, lines 3-5, 21-29, 49-73, 98-123. Use its maintainer source-of-truth style and existing ordered release procedure.

```markdown
<!-- docs/releasing.md:5,111-112 (excerpt) -->
Release Please owns the version bump, changelog PR, and Git tag for Scrypath.
When `release_created == true`, the `publish-hex` job checks out `tag_name` and runs `mix hex.publish --yes`.
```

The implemented workflow scopes `HEX_API_KEY` to `publish-hex` (`.github/workflows/release-please.yml:41-53`) and runs `mix verify.package`, dry-run, publish, `mix verify.release_publish`, then `mix verify.release_parity` in order (`.github/workflows/release-please.yml:75-94`). Record actual release evidence or a precise `release-ready` blocker without changing this automation.

### `test/scrypath/docs_contract_test.exs` (test, file-I/O and contract validation)

**Analog:** same tracked file, lines 1-14, 702-728, 793-815. Extend the existing job-scoped test for DOC-01 language and evidence boundaries.

```elixir
# test/scrypath/docs_contract_test.exs:1-10,702-709 (excerpt)
defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true
  @moduletag :docs_contract
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @ci_workflow File.read!(".github/workflows/ci.yml")

  test "Phoenix package proof follows path proof in its existing advisory service job" do
    [_, job] =
      Regex.run(~r/  phoenix-example:\n(.*?)(?=\n  [a-z][a-z0-9-]*:\n|\z)/s, @ci_workflow)
    assert job =~ "continue-on-error: true"
    assert ordered?(job, "mix verify.phoenix_example", "mix verify.phoenix_example --package")
```

The rest of that test asserts Postgres/Meilisearch service images, environment names in both docs, and the normal example `path:` dependency (`:706-728`). Follow the `assert_contains_all` style for new documentation promises. The release contract test at lines 793-815 protects auth-free CI and key-scoped publish wording. This is the existing focused test location; no new harness is indicated.

### `161-VALIDATION.md` (planning evidence, batch verification)

**Analog:** tracked `160-VALIDATION.md`, lines 1-34 and 45-60. Copy the requirement-to-automated-evidence table and separate local test results from exact-SHA hosted proof.

```markdown
<!-- .planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md:25-34 (shape) -->
| Behavior | Requirement | Test Type | Automated Command / Evidence | Coverage Status | Acceptance Status |
|----------|-------------|-----------|------------------------------|-----------------|-------------------|
```

For Phase 161, map DOC-01 to the docs contract, HYGIENE-01 to docs/package checks and owned-resource inventory, REL-01 to Mint audit plus final-SHA CI and publish/parity evidence, and CLOSE-01 to ownership-based cleanup and shipped/release-ready disposition. Phase 160's lines 45-60 show exact SHA, run, job, ordered steps, log markers, and advisory finding reported separately. Replace all Phase 160 values with Phase 161 results.

### `161-VERIFICATION.md` (planning evidence, batch verification)

**Analog:** tracked `160-VERIFICATION.md`, lines 1-5, 44-75. Reuse front matter, observable-truth table, required-artifact table, and evidence links.

```markdown
<!-- .planning/phases/160-package-backed-phoenix-proof/160-VERIFICATION.md:1-5,53-56 (shape) -->
---
phase: 160-package-backed-phoenix-proof
verified: 2026-09-24T13:03:59Z
status: passed
score: 4/4 must-haves verified
---
| # | Truth | Status | Evidence |
```

Populate new phase identifiers and observed outcomes. A published disposition needs Hex, HexDocs, and tarball/tag parity evidence from the existing release workflow. A blocked publication needs `release-ready`, the specific external blocker, and exact resume action; do not copy Phase 160's `passed`/published wording uncritically.

### Phase 161 `*-SUMMARY.md` files (planning evidence, batch closeout)

**Analog:** tracked `160-03-SUMMARY.md`, lines 62-111. Use its Accomplishments, Files Created/Modified, Decisions Made, Issues Encountered, and Next Phase Readiness sections; cite exact run/SHA/job and distinguish advisory from required results.

```markdown
<!-- .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md:93-96 (shape) -->
## Decisions Made
- The candidate SHA, individual job, ordered command steps, and package log markers are the acceptance authority.
```

Phase 161 must update this evidence to the final source SHA. Its release status follows D-03/D-04, rather than inherited Phase 160 candidate status.

### `.planning/STATE.md` / `.planning/ROADMAP.md` (planning state, event-driven closeout)

**Analog:** current tracked state and roadmap are the authority for their own format; `160-VERIFICATION.md:1-5` and `160-03-SUMMARY.md:109-111` show how phase completion evidence is summarized. Update these only if the orchestrator's normal closeout writes milestone state. Apply the distinction between `shipped` and `release-ready` from Phase 161 context D-03/D-04. Preserve unrelated state entries.

## Shared Patterns

### Exact-SHA evidence

**Sources:** `CONTRIBUTING.md:67-83`, `scripts/ci_monitor.cjs:119-123,187-209`. Apply to validation, verification, summaries, and final closeout. The helper rejects non-full SHAs and requires one successful instance of each named job plus digest-bearing SHA-bound artifacts.

### Release and credential boundary

**Sources:** `.github/workflows/release-please.yml:18-53,75-94`, `docs/releasing.md:49-73,98-123`. Release Please generates version/tag; publish uses that tag and a job-scoped Hex key, then validates package visibility, HexDocs, and parity. Authentication/authorization here is workflow permissions and publish secret scoping; there is no application auth pattern to copy.

### Proof boundary and error/cleanup handling

**Sources:** `examples/phoenix_meilisearch/README.md:39-71`, `.planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md:45-60`, `lib/mix/tasks/verify/phoenix_example/package.ex:204-237`. Documentation must distinguish contract/synthetic checks from hosted live-service proof. Cleanup remains confined to resources demonstrably owned by the milestone or package task; unrelated status entries in the Phase 161 research inventory remain untouched.

## No Analog Found

No wholly new source or workflow file is required. The conditional `release-ready` final disposition has no exact previous published artifact to copy; apply D-04 explicitly in the Phase 161 evidence files.

## Metadata

**Analog search scope:** root Mix files, `examples/phoenix_meilisearch/`, `docs/`, `test/scrypath/`, `.github/workflows/`, `scripts/`, and Phase 160 planning artifacts.  
**Tracked-source gate:** every named analog above was checked with `git ls-files`; no runtime mirror path is used.  
**Pattern extraction date:** 2026-09-24.
