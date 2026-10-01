# Phase 170: Documentation and Readiness Closeout - Pattern Map

**Mapped:** 2026-09-30
**Files analyzed:** 10 implementation/documentation targets; additional completion records listed separately
**Analogs found:** 10 / 10 at role or exact-pattern level; terminal evidence schema is new

## Scope and conventions

The file names for new tooling below are recommendations, not locked decisions. Prefer a small sibling collector to extending dispatch with semantic assessment. No product behavior, operator UI, CI lane, or publication pipeline is added by this map. Documentation is classified as `component` with `transform` flow: it transforms supported behavior into adopter or maintainer guidance.

Read repository AGENTS.md. Neither project skill directory exposed a SKILL.md. Relevant local guidance is `prompts/scrypath-milestone-ratchet-roadmap.txt:129-145`: keep a concise README route map, preserve precise operational limits, use canonical owners, and avoid unrelated cleanup. All analog paths named below were checked with `git ls-files -- <path>` and are tracked repository files. No installation/runtime mirror is used.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | component (documentation) | transform | `guides/golden-path.md` | role-match |
| `guides/jtbd-and-user-flows.md` | component (documentation) | transform | `guides/golden-path.md` | role-match |
| `guides/sync-modes-and-visibility.md` | component (documentation) | transform | `guides/golden-path.md` | role-match |
| `lib/scrypath.ex` (only if canonical wording needs adjustment) | provider (API documentation) | request-response | existing `lib/scrypath.ex` | exact |
| `test/scrypath/docs_contract_test.exs` | test | file-I/O | existing `test/scrypath/docs_contract_test.exs` | exact |
| `scripts/readiness_evidence.cjs` (proposed) | utility | request-response, file-I/O, transform | `scripts/ci_monitor.cjs` | role-match |
| `test/scripts/readiness_evidence_test.exs` (proposed) | test | file-I/O, request-response | `test/scripts/ci_monitor_test.exs` | exact |
| `CONTRIBUTING.md` (collector usage only, if needed) | component (documentation) | transform | existing `CONTRIBUTING.md` | exact |
| `.planning/reference/PRE-OPERATOR-UI-READINESS.md` | component (authority/navigation) | transform | existing authority's dated evidence and cleanup sections | exact |
| `.planning/phases/170-documentation-and-readiness-closeout/170-READINESS-INPUTS.json` (proposed frozen inputs) | model | transform | `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/check_readiness.py` | role-match |

Counts: 5 exact, 5 role-match. A sibling script is one option; extending `scripts/ci_monitor.cjs` and `test/scripts/ci_monitor_test.exs` instead preserves the same assignments and reduces new files. Do not implement both layouts.

### Other files and outputs implied by closeout

- `guides/golden-path.md`: preservation boundary and analog, not a selected rewrite; retain inline-first sequence.
- `.github/workflows/ci.yml` and `.github/workflows/release-please.yml`, `docs/releasing.md`: reuse as execution inputs; no change required by the selected design.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, phase plan summaries and verification report: bookkeeping/configuration with transform flow. Update through the normal phase workflow **before** final attestation. Planner must enumerate exact summary/report names once plan count is known.
- `.planning/PROJECT.md`: conditional support/product claim reconciliation only. `.planning/reference/milestone-candidates.md` and `.planning/reference/MILESTONE-ARC.md`: reconcile only if the actual milestone boundary changes their current posture. Their established headings remain their local format; this map does not propose a broad rewrite.
- Release-owned version/changelog edits belong to Release Please. Do not manually introduce speculative version changes in the docs plan.
- Dedicated GitHub issue and final dated comment: external record, not a tracked assessment file. Terminal record must not be generated into tracked source after its final attestation.
- Historical Phase 167 assessment is an immutable input, never a modification target.

## Pattern Assignments

### README and JTBD routes (component, transform)

**Analog:** `guides/golden-path.md:1-11`. Reuse task-first heading, explicit outcome, bounded tutorial scope, and direct relative links. README-relative destinations have a `guides/` prefix; guide-relative destinations do not.

**Concrete navigation excerpt** (`guides/golden-path.md:5-7`):

```markdown
If you want the shared request-edge story for browser params, `Scrypath.QueryParams`, optional `Scrypath.Phoenix`, and context-owned runtime calls, read [Request-edge search](request-edge-search.md). This guide stays focused on the first indexed document and first search.

When you need **`Scrypath.search_many/2`**, federation weights, or **`:all`** expansion across several schemas, read next: [Multi-index search](multi-index-search.md).
```

**Apply:** consolidate README's early navigation and Phoenix Wayfinding into one useful task route map; remove repeated JTBD positioning while retaining distinct destinations. Preserve README installation/schema example (`README.md:14-24,67-83`) and the existing caveat at line 164. Keep a short selection summary for all three modes and link to guide and `Scrypath.sync_record/3` API documentation. Do not copy the tutorial's entire narrative into the README.

**Validation:** inventory old destinations and account for every useful unique route. Build ExDoc to validate rendered API links; do not assume a source Markdown link and generated ExDoc link resolve identically.

### Sync guide and public API ownership

**Analog:** `guides/golden-path.md:9-11` for bounded operational wording; exact canonical source `lib/scrypath.ex:156-173` for return semantics.

**Canonical excerpt** (`lib/scrypath.ex:159-166`):

```elixir
  On success, `{:ok, map}` includes at least **`:mode`** (for example `:inline`, `:oban`, or `:manual`)
  and **`:status`**:

  * **`:status` `:accepted`** — work was queued or accepted by the backend or queue layer; documents may
    not be queryable yet. This is normal for `:manual`, `:oban`, and sometimes `:inline` when no
    Meilisearch task wait applies. See [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md).
  * **`:status` `:completed`** — the `:inline` path finished, including waiting for a terminal Meilisearch
    task when `sync_mode: :inline` and the backend returned a task handle.
```

This excerpt is content inside `@sync_public_ops_doc`, not executable statements. The same attribute is assigned to `@doc` at line 175. Retain its shared ownership; no new wrapper or runtime function is needed.

**Apply:** correct `guides/sync-modes-and-visibility.md:9` from “What completed work means” to wording describing the observable return boundary. Preserve the detailed lifecycle at lines 25-39 in the guide. The API's conditional inline behavior matters: avoid replacing it with an unconditional promise that every inline operation yields `:completed`.

**Error contract** (`lib/scrypath.ex:170-172`):

```text
Tagged `{:error, reason}` tuples may include `{:timeout, _}`, `{:task_failed, _}`,
`{:invalid_options, _, _}`, and other operational heads. For user-facing copy,
normalize them through your own application boundary instead of depending on internal helpers.
```

### Focused documentation assertions (test, file-I/O)

**Analog:** `test/scrypath/docs_contract_test.exs`. Keep the existing module and exclusion tag.

**Imports/setup excerpt** (lines 1-7):

```elixir
defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true
  @moduletag :docs_contract

  @readme File.read!("README.md")
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")
  @architecture File.read!("ARCHITECTURE.md")
```

**Apply:** adjust only assertions superseded by consolidation. Research identifies lines 391-465 and 785-804 as the affected contract regions: return/lifecycle details belong in canonical API/guide checks, while README checks should enforce mode summary, visibility warning, first-result route and useful navigation. Do not retain duplicate prose simply to satisfy old phrase assertions. Do not add this whole historical suite to required default CI.

### Factual collector (utility, request-response/file-I/O)

**Analog:** `scripts/ci_monitor.cjs`. Copy standard-library imports and executable injection, argument arrays, error propagation and JSON output; do not copy dispatch or branch-protection mutation into a read-only collector.

**Imports and injected binaries** (lines 3-9):

```javascript
"use strict";
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const GH = process.env.GH_BIN || "gh";
const GIT = process.env.GIT_BIN || "git";
```

**Core subprocess pattern** (lines 23-30):

```javascript
function run(bin, args, options = {}) {
  const result = spawnSync(bin, args, {
    cwd: options.cwd || process.cwd(),
    encoding: "utf8",
    env: process.env,
    input: options.input,
    maxBuffer: 20 * 1024 * 1024,
  });
```

**Fail-closed validation** (lines 125-137):

```javascript
function artifactFor(artifacts, name, sha) {
  const matches = (artifacts || []).filter(
    (artifact) => artifact.name === name && artifact.expired === false,
  );
  if (matches.length !== 1) {
    throw new Error(`expected exactly one live ${name} artifact, found ${matches.length}`);
  }
  const artifact = matches[0];
  if (!artifact.digest || !artifact.id || artifact.workflow_run?.head_sha !== sha) {
    throw new Error(`${name} is missing its id/digest or is not bound to ${sha}`);
  }
  return artifact;
}
```

**Error handling:** lines 32-38 throw on spawn/nonzero exit; lines 48-54 wrap invalid JSON; lines 340-341 route to `fail(error.message)`, which writes stderr and exits 1 (18-20). Preserve stdout for structured output.

**Adaptation required:** the existing monitor's jobs endpoint (182-185) is not attempt-specific and its receipt (211-236) does not validate downloaded attestation bytes. Use the research's explicit attempt join, pagination, downloaded archive hashing, attestation payload checks and missing/duplicate/expired evidence rejection. Keep attestation archive digest separate from the JSON member checksum. Metadata alone is insufficient. Do not infer maintainer judgment from these checks.

### Collector tests (test, file-I/O/request-response)

**Analog:** `test/scripts/ci_monitor_test.exs:7-22,25-47,78-101`. Each test gets a temporary directory and executable fake binaries; cleanup uses `on_exit`. Exercise the real script with `System.cmd`, no live GitHub calls.

**Positive case** (25-33):

```elixir
  test "closeout accepts only the newly dispatched exact-SHA run and both artifacts", ctx do
    {output, 0} = run_closeout(ctx, "success")
    payload = Jason.decode!(output)

    assert payload["authority"] == "github-actions-exact-sha"
    assert payload["head_sha"] == @sha
    assert payload["run_id"] == 123
    assert payload["coverage_artifact"]["digest"] == "sha256:coverage"
    assert payload["closeout_artifact"]["digest"] == "sha256:closeout"
```

**Negative case** (36-41):

```elixir
  test "closeout fails closed when a required job fails", ctx do
    {output, status} = run_closeout(ctx, "failed_job")
    assert status != 0
    assert output =~ "backend (required) must have exactly one successful job"
  end
```

Reuse `GH_BIN`, `GIT_BIN`, `FAKE_STATE`, `FAKE_SCENARIO`, `FAKE_SHA` injection (93-99). New fixtures must include real small artifact bytes and their valid hash; existing `sha256:coverage` strings are fake metadata, not valid byte-verification fixtures. Cover wrong SHA/repository/run/attempt, mismatched payload/artifact digest, pagination, duplicate/missing/failed jobs, expired/missing artifact, malformed record, unsupported READY and missing maintainer provenance.

### Readiness inputs and authority (model/component, transform)

**Analog:** `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/check_readiness.py:29-48,51-66,90-121`. Borrow invariant shape and history-byte comparison; do not run this phase-bound checker unchanged against Phase 170 or copy its obsolete claim inventory.

**Structural error pattern** (51-65):

```python
class ContractError(ValueError):
    """A source, receipt, path, or history invariant is missing or malformed."""

def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)

def read_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ContractError(f"cannot read {label}: {error}") from error
    require(isinstance(value, dict), f"{label} must be a JSON object")
```

Port the invariant pattern into the chosen collector runtime instead of adding Python solely for this excerpt. Historical preservation compares pinned Git bytes with current bytes (90-121); extend the frozen input list to Phase 167 history. Keep the exact six condition texts at authority lines 64-69. Track bounded baseline/claim/workflow mappings and cleanup disposition before freeze; collect final-source receipt and publish the decision afterward externally.

**Authority evidence table pattern** (`.planning/reference/PRE-OPERATOR-UI-READINESS.md:99-100`):

```markdown
| # | Approved condition | Status | Evidence date | Assessment date | Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |
|---|---|---|---|---|---|---|
```

Use this separation of dates, evidence and limits in the external terminal comment. Add a dedicated issue pointer to the live authority before final attestation. Preserve its historical assessment body; append dated external corrections instead of silently replacing decisions.

### Contributor command documentation (component, transform)

**Analog:** `CONTRIBUTING.md:67-83`: command block followed by exact promise, source boundary and limitation. Document collector invocation and required explicit inputs next to existing closeout usage if a durable command is added. Do not claim the collector evaluates semantic readiness or grants permission.

## Shared Patterns

### Source identity and final-write boundary

**Source:** `CONTRIBUTING.md:76-83`; apply to every tracked completion file.

```text
Closeout uses two stages: attest the pending candidate, commit all final
tracking and verification artifacts, then attest the exact final SHA. Do not
write tracked files after the final successful run.
```

Schedule summaries, verification, state, cleanup and any archive decision before the final source is attested. Preserve candidate, integrated main, final tracked source and published package/tag as distinct identities. A matching tree supports bounded behavior reuse, not reassignment of a CI run to another commit.

### Attestation producer contract

**Source:** `.github/workflows/ci.yml:304-316`; collector consumes these existing fields:

```yaml
            --arg run_id "$GITHUB_RUN_ID" \
            --arg run_attempt "$GITHUB_RUN_ATTEMPT" \
            --arg run_url "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" \
            --arg event "$GITHUB_EVENT_NAME" \
            --arg head_sha "$GITHUB_SHA" \
```

The producer also records repository, required job names and coverage ID/URL/digest. Artifact retention is seven days (324), so retain the compact payload and necessary receipt facts inside the terminal comment. Do not assume an artifact link is durable content storage.

### Authentication, authorization and logging

No application auth pattern is needed. Existing monitor invokes `gh auth status` (141); reuse established CLI credentials for read-only collection and never dump environment/auth output into public evidence. Posting the accountable maintainer decision is a separate authorized action. Throw factual errors with actionable messages; stdout is JSON and stderr carries failures.

### Verification scope

Use research/CONTRIBUTING's existing commands: `mix docs --warnings-as-errors`, `mix verify.phase112`, `mix verify.adopter`, touched docs assertions, and focused script fixtures. Test infrastructure edits require the warnings-as-errors command in CONTRIBUTING 85-89. Existing package/release and exact-SHA lanes remain authoritative. No tests or external mutations were run during this mapping.

## No Analog Found

| File/output | Role | Data Flow | Reason |
|---|---|---|---|
| Final external GitHub terminal comment with frozen-source/attempt/artifact joins | model | transform, external publication | No existing complete terminal protocol matches D-04–D-07; use proposed RESEARCH record shape, historical condition/limit table and existing factual attestation fields. |
| New JSON evidence block schema inside terminal comment | model | transform | Historical checker has different phase claims and a Markdown schema. Define/version the narrow schema early; do not present it as an existing API. |

## Metadata

**Analog search scope:** root docs, `guides/`, `lib/scrypath.ex`, `scripts/`, `test/scripts/`, focused docs tests, CI workflow and tracked historical readiness tooling.
**Primary analog families:** adopter routing; documentation assertions; CI collector; fake CLI tests; historical structural validator.
**Files scanned:** 15 source/documentation files or focused sections, plus phase context/research and tracked-path inventory. Search stopped once these families covered the work.
**Pattern extraction date:** 2026-09-30.
**Tool limitation:** filesystem Read/Write tools were unavailable; reads used shell tools and this sole output was written with the available patch tool. No source, guide, test, historical assessment or unrelated working-tree file was modified.
