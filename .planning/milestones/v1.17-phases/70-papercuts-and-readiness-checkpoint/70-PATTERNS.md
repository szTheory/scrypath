# Phase 70: Papercuts and readiness checkpoint - Pattern Map

**Mapped:** 2026-04-22  
**Files analyzed:** 14 likely Phase 70 touchpoints  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/verify.adopter.ex` | config | request-response | `lib/mix/tasks/verify.adopter.ex` | exact |
| `lib/mix/tasks/verify.opsui.ex` | config | request-response | `lib/mix/tasks/verify.opsui.ex` | exact |
| `lib/scrypath/errors.ex` | utility | request-response | `lib/scrypath/errors.ex` | exact |
| `test/mix/tasks/verify_adopter_test.exs` | test | request-response | `test/mix/tasks/verify_adopter_test.exs` | exact |
| `test/scrypath/docs_contract_test.exs` | test | transform | `test/scrypath/docs_contract_test.exs` | exact |
| `README.md` | config | request-response | `README.md` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |
| `examples/phoenix_meilisearch/README.md` | config | request-response | `examples/phoenix_meilisearch/README.md` | exact |
| `guides/support-and-compatibility.md` | config | request-response | `guides/support-and-compatibility.md` via `test/scrypath/docs_contract_test.exs` assertions | role-match |
| `guides/common-mistakes.md` | config | request-response | `guides/common-mistakes.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md` + `.planning/milestones/v1.16-MILESTONE-AUDIT.md` | role-match |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md` | role-match |
| `.planning/STATE.md` | config | transform | `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md` | role-match |
| `.planning/milestones/v1.17-MILESTONE-AUDIT.md` | config | transform | `.planning/milestones/v1.16-MILESTONE-AUDIT.md` | exact-shape |

## Pattern Assignments

### `lib/mix/tasks/verify.adopter.ex` / `lib/mix/tasks/verify.opsui.ex` (task help, warnings, bounded papercuts)

**Analog:** `lib/mix/tasks/verify.adopter.ex`

Use the existing task pattern: public `@shortdoc` + `@moduledoc`, strict flag parsing, explicit fast/live split, loud prerequisite failures, and orchestration-only subprocesses.

**Imports / task shell pattern** ([lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:1)):
```elixir
defmodule Mix.Tasks.Verify.Adopter do
  use Mix.Task

  @shortdoc "Runs fast adopter contracts, or the live Phoenix example proof with --live"
```

**Strict args + no hidden fallback** ([lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:47)):
```elixir
{opts, argv, invalid} =
  OptionParser.parse(args,
    strict: [fast: :boolean, live: :boolean]
  )

ensure_valid_args!(opts, argv, invalid)
```

**Explicit branch wording** ([lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:61)):
```elixir
defp run_fast! do
  Mix.shell().info("==> verify.adopter: running fast adopter contracts")
  run_test!(@fast_tests, "fast adopter contracts")
end
```

**Loud prerequisites with copy-pastable example** ([lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:116)):
```elixir
if missing != [] do
  Mix.raise("""
  verify.adopter --live requires environment variables: #{Enum.join(missing, ", ")}

  Example:
    SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live
  """)
end
```

**Orchestration-only subprocess rule** ([lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:35)):
```elixir
# CI mirrors GitHub Actions (non-interactive).
Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")
script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"
```

**Planner guidance:** reuse this shape for any papercut in task help or error output. Do not add service bootstrapping, retries, or new semantic task families unless Phase 70 evidence proves a real gap.

### `lib/scrypath/errors.ex` (library-facing papercut help text)

**Analog:** `lib/scrypath/errors.ex`

Phase 70 help-text improvements should follow the existing error style: identify the failure class, then route the caller to the smallest authoritative guide set.

**Error-message pattern** ([lib/scrypath/errors.ex](/Users/jon/projects/scrypath/lib/scrypath/errors.ex:7)):
```elixir
{:timeout, _} ->
  "Inline sync stopped waiting for a Meilisearch task before it reached a terminal state (inline timeout). The task may still complete in the background. Read guides/sync-modes-and-visibility.md and guides/common-mistakes.md — accepted work is not the same thing as search visibility."
```

**Validation/help-link pattern** ([lib/scrypath/errors.ex](/Users/jon/projects/scrypath/lib/scrypath/errors.ex:11)):
```elixir
{:invalid_options, field, message} ->
  "Invalid options (#{field}): #{message} See guides/multi-index-search.md ..."
```

**Planner guidance:** if a papercut is wording-only, keep the change here or in existing Mix task help. Do not invent new error structs, new public return tuples, or a new doc taxonomy.

### `test/mix/tasks/verify_adopter_test.exs` (bounded papercut regressions for task surfaces)

**Analog:** task contract pattern described in [69-01-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/69-adopter-verify-spine/69-01-PLAN.md:124)

The precedent is narrow task-semantic coverage: bad args, missing env, and one progress marker. Not end-to-end duplication of docs contracts.

**Plan precedent** ([69-01-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/69-adopter-verify-spine/69-01-PLAN.md:124)):
```md
Add `"verify.adopter": :test` to `Scrypath.MixProject.cli/0` ...
Create `test/mix/tasks/verify_adopter_test.exs` ...
cover stray/unknown arg rejection, `--live` prerequisite failures ...
Keep the file focused on task semantics rather than duplicating docs-contract assertions ...
```

**Planner guidance:** if Phase 70 touches `verify.adopter` or a neighboring task, add or update one focused task test file. Keep it on semantics, not prose snapshots.

### `test/scrypath/docs_contract_test.exs` (docs-contract extensions for maintainer/adopter truth)

**Analog:** `test/scrypath/docs_contract_test.exs`

This is the strongest precedent for Phase 70. Extend the existing file with narrow string/order assertions, not snapshot-style prose freezing.

**Bounded string/order contract pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:433)):
```elixir
test "phase 69 adopter verify task keeps fast and live contracts explicit" do
  assert_contains_all(@verify_adopter, [
    "fast, auth-free, service-free adopter contract slice",
    "mix verify.adopter --live",
    "examples/phoenix_meilisearch",
    "SCRYPATH_EXAMPLE_INTEGRATION",
    "PGPORT",
    "SCRYPATH_MEILISEARCH_URL"
  ])
end
```

**Order-only contract pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:488)):
```elixir
ci_window = String.slice(ci_tail, 0, 1200)

assert ordered?(ci_window, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(ci_window, "mix deps.get", "mix test")
```

**Published-doc hygiene pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:67)):
```elixir
test "published markdown avoids internal planning and task artifact strings" do
  ...
  refute Regex.match?(re, body),
         "remove #{label} from published doc #{path} ..."
end
```

**Planning/bookkeeping invariant pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:933)):
```elixir
test "phase 32 AUDT-01 planning hygiene contracts (Nyquist invariants)" do
  state_md = File.read!(".planning/STATE.md")
  ...
  assert String.contains?(v16_audit, "requirements: 8/8")
end
```

**Planner guidance:** for Phase 70, prefer adding 1-3 new assertions tied to the specific papercut or milestone-close fact. Avoid large helper systems or parsing markdown structure.

### `README.md`, `CONTRIBUTING.md`, `examples/phoenix_meilisearch/README.md` (docs truth without scope widening)

**Analog:** current docs surfaces

These files already separate authority:

- README is compact routing and public-surface framing.
- CONTRIBUTING is maintainer verify/CI truth.
- example README is canonical live proof/runbook.

**README routing pattern** ([README.md](/Users/jon/projects/scrypath/README.md:17)):
```md
**Start here:** ... [guides/golden-path.md]
**Canonical example proof:** ... [examples/phoenix_meilisearch/README.md]
**Support contract:** ... [guides/support-and-compatibility.md]
**Adopter verification (maintainers):** ... `mix verify.adopter`
```

**CONTRIBUTING authority pattern** ([CONTRIBUTING.md](/Users/jon/projects/scrypath/CONTRIBUTING.md:9)):
```md
- Runtime, version, and support truth live in `guides/support-and-compatibility.md`; update that guide instead of widening compatibility claims in README or CONTRIBUTING.
- Sync modes ... live in `guides/sync-modes-and-visibility.md`—update that guide instead of duplicating semantics ...
```

**Example README authority pattern** ([examples/phoenix_meilisearch/README.md](/Users/jon/projects/scrypath/examples/phoenix_meilisearch/README.md:39)):
```md
## CI proof path (`phoenix-example-integration`)
mix verify.adopter --live

cd examples/phoenix_meilisearch
mix deps.get
mix test
```

**Planner guidance:** Phase 70 doc edits should route to the current authority instead of copying more semantics into README/CONTRIBUTING. If a papercut is “confusing wording,” fix the authority doc first, then add a small docs-contract assertion.

### `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` (readiness checkpoint and milestone-close rolling truth)

**Analog:** [67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:48)

Phase 67 is the direct precedent for readiness bookkeeping: rolling files update only after evidence exists, and wording stays concrete about close state.

**Rolling-truth plan pattern** ([67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:114)):
```md
Update the rolling planning files ... only after plans 01 and 02 are actually implemented and verified.
...
Do not introduce “shipped”, “archived”, `passed`, or Hex-facing language here unless the close conditions are objectively met ...
```

**Conditional historical promotion pattern** ([67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:143)):
```md
Branch A: if `v1.16` is genuinely closed, add the new historical entry ...
Branch B: if `v1.16` is not genuinely closed, keep `.planning/MILESTONES.md` unchanged ...
```

**Summary phrasing pattern** ([67-03-SUMMARY.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-SUMMARY.md:45)):
```md
- Marked OPS3-04 through OPS3-06 complete in the rolling requirements and roadmap/project/state files.
- Added the frozen `v1.16-ROADMAP.md`, `v1.16-REQUIREMENTS.md`, and `v1.16-MILESTONE-AUDIT.md` archive trio.
- ... while keeping the Hex story explicitly separate.
```

**Planner guidance:** Phase 70 should reuse this exact sequencing for INTG-05/INTG-06. No readiness language before evidence exists.

### `.planning/milestones/v1.17-MILESTONE-AUDIT.md` (historical bookkeeping)

**Analog:** `.planning/milestones/v1.16-MILESTONE-AUDIT.md` and `.planning/milestones/v1.15-MILESTONE-AUDIT.md`

Use the same YAML-frontmatter + verdict + evidence pointers + residuals structure.

**Audit header pattern** ([.planning/milestones/v1.16-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.16-MILESTONE-AUDIT.md:1)):
```yaml
---
milestone: v1.16
milestone_name: Playbook execution & operator honesty
audited: 2026-04-22T23:59:00Z
status: passed
scores:
  requirements: 6/6
  phases: 3/3
  integration: 4/4
  flows: 4/4
...
---
```

**Evidence-pointer section pattern** ([.planning/milestones/v1.16-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.16-MILESTONE-AUDIT.md:29)):
```md
## Evidence pointers

- **Phase 65:** ...
- **Phase 66:** ...
- **Phase 67:** ...
```

**Residual honesty pattern** ([.planning/milestones/v1.15-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.15-MILESTONE-AUDIT.md:41)):
```md
## Residual (non-blocking)

- **Automation:** CLI milestone completion remains manual ...
- **Hex:** No version change in `mix.exs` ...
```

**Planner guidance:** use the same sections for v1.17. If readiness is not achieved, change `status`, scores, and verdict truthfully; do not preserve `passed` by inertia.

## Shared Patterns

### Bounded papercut fixes backed by tests/contracts

**Sources:**  
- [67-01-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-01-PLAN.md:149)  
- [68-02-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/68-example-proof-and-support-contract/68-02-PLAN.md:130)  
- [69-02-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/69-adopter-verify-spine/69-02-PLAN.md:106)

**Apply to:** every candidate papercut in Phase 70

**Pattern to copy:**
```md
- name one bounded truth
- tie it to one existing file surface
- add one regression test / contract assertion that fails on recurrence
- avoid “while here” expansions
```

### Warning/error/help-text improvements

**Sources:**  
- [lib/scrypath/errors.ex](/Users/jon/projects/scrypath/lib/scrypath/errors.ex:7)  
- [lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:116)  
- [lib/mix/tasks/verify.workspace_clean.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.workspace_clean.ex:105)

**Apply to:** Mix task help, Mix task failure text, library-facing errors

**Pattern to copy:**
```elixir
Mix.raise("""
<state the exact missing precondition or invalid input>

Example:
  <copy-pastable invocation>
""")
```

And for library errors:
```elixir
"<short failure summary>. See <authority guide>; for common adopter confusion see guides/common-mistakes.md."
```

### Docs-contract extensions

**Source:** [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:1000)

**Apply to:** README, CONTRIBUTING, example README, support/common-mistakes/sync guide, planning invariants

**Pattern to copy:**
```elixir
assert_contains_all(content, ["small", "stable", "facts"])
assert ordered?(window, "command A", "command B")
refute Regex.match?(re, body)
```

### Readiness/milestone-close bookkeeping

**Sources:**  
- [67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:130)  
- [.planning/milestones/v1.16-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.16-MILESTONE-AUDIT.md:25)

**Apply to:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, new `v1.17-*` audit/archive files

**Pattern to copy:**
```md
- update rolling files only after evidence exists
- freeze archive/audit files with exact scores and residuals
- keep Hex publish separate from in-repo milestone close
- if readiness is partial, say so explicitly instead of softening it into “passed”
```

## Likely Phase 70 Plan Boundaries

### Boundary 1: Bounded papercuts only

Best precedent: [67-01-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-01-PLAN.md:149), [68-02-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/68-example-proof-and-support-contract/68-02-PLAN.md:130)

- Limit to **no more than three** adopter-friction issues, matching the roadmap cap in [ROADMAP.md](/Users/jon/projects/scrypath/.planning/ROADMAP.md:90).
- Each issue should map to one existing surface (`verify.adopter`, `verify.opsui`, `Scrypath.Errors`, docs wording, example README, or a narrow library seam).
- Each issue must add one regression test, docs-contract assertion, or example assertion.

### Boundary 2: Contract/doc/help-text alignment

Best precedent: [69-02-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/69-adopter-verify-spine/69-02-PLAN.md:106)

- If any papercut changes public wording, pair it with the smallest README / CONTRIBUTING / example README / support-guide update needed.
- Route to the current authority doc instead of duplicating semantics.
- Lock the changed fact with `docs_contract_test.exs` rather than adding a new contract suite.

### Boundary 3: Readiness checkpoint and milestone-close decision

Best precedent: [67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:130), [.planning/milestones/v1.16-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.16-MILESTONE-AUDIT.md:25)

- Make the milestone-close artifact a separate final plan unless the papercut list is trivial.
- Treat “ready for more outside integration feedback” as an explicit verdict, not an implied outcome.
- Keep historical bookkeeping conditional on actual close status.

## Anti-Patterns To Avoid

### Over-broad scope

Avoid turning “papercuts” into another feature slice. The repo has already locked the public surface and the roadmap explicitly forbids widening it in Phase 70; see [README.md](/Users/jon/projects/scrypath/README.md:97) and [ROADMAP.md](/Users/jon/projects/scrypath/.planning/ROADMAP.md:90).

### Prose snapshotting

Do not freeze entire paragraphs in `docs_contract_test.exs`. Follow the bounded assertion style from [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:433): strings, atoms, env vars, filenames, job names, and ordering only.

### Accidental public-surface expansion

Do not add new top-level APIs, new semantic command families, or new “secondary truth” docs for a papercut. Existing docs already separate responsibilities:

- README routes
- CONTRIBUTING explains maintainer verify/CI
- example README owns live proof
- support/sync guides own semantics

### Hidden orchestration in Mix tasks

Do not make `verify.adopter` or sibling tasks provision services, wait for readiness, or silently fall back. Reuse the explicit orchestration-only rule in [lib/mix/tasks/verify.adopter.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.adopter.ex:27) and [lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:18).

### Milestone-close overclaiming

Do not mark `passed`, `shipped`, or archived status before evidence exists. Reuse the conditional close model from [67-03-PLAN.md](/Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md:143) and the residual honesty in [.planning/milestones/v1.15-MILESTONE-AUDIT.md](/Users/jon/projects/scrypath/.planning/milestones/v1.15-MILESTONE-AUDIT.md:41).

## No Analog Found

None. Phase 70’s target work fits existing repo patterns directly; the planner should prefer reuse over invention.

## Metadata

**Analog search scope:** `.planning/phases/67-69`, `.planning/milestones/`, `lib/mix/tasks/`, `lib/scrypath/`, `test/scrypath/`, `README.md`, `CONTRIBUTING.md`, `examples/phoenix_meilisearch/README.md`, `guides/common-mistakes.md`  
**Files scanned:** 18 required files + focused analog reads  
**Pattern extraction date:** 2026-04-22

## RESEARCH COMPLETE

Pattern mapping for Phase 70 is complete. The planner should reuse the bounded-contract, authority-doc, orchestration-only, and truthful-milestone-close patterns above.
