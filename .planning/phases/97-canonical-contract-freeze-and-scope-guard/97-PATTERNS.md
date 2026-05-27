# Phase 97: Canonical Contract Freeze and Scope Guard - Pattern Map

**Mapped:** 2026-05-27  
**Files analyzed:** 17 likely Phase 97 touchpoints  
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` (new) | planning ledger | transform | `.planning/REQUIREMENTS.md` traceability table + `97-VALIDATION.md` per-task mapping rows | role-match |
| `.planning/PROJECT.md` | governance truth | transform | existing v1.27 canonical contract + non-goals section | exact |
| `.planning/ROADMAP.md` | milestone routing | transform | existing v1.27 phase/success criteria + requirement coverage table | exact |
| `.planning/REQUIREMENTS.md` | requirement registry | transform | existing v1.27 requirement/traceability format | exact |
| `.planning/STATE.md` | milestone posture | transform | existing blocker/concern + lane discipline entries | exact |
| `guides/support-and-compatibility.md` | canonical adopter authority | contract | existing support/proof authority guide shape | exact |
| `README.md` | entry routing (reference surface) | request-response | existing "Start here / Support and readiness / Outside integrations" block | exact |
| `CONTRIBUTING.md` | maintainer routing (reference surface) | request-response | existing "single authority" bullets + verify matrix | exact |
| `guides/outside-adopter-intake.md` | evidence contract | request-response | existing classing + evidence bundle template | exact |
| `lib/mix/tasks/verify.phase97.ex` (new) | phase gate task | batch | `lib/mix/tasks/verify.phase96.ex` | exact-shape |
| `mix.exs` | CLI alias registration | transform | existing `preferred_envs` `verify.phase*` entries | exact |
| `test/scrypath/docs_contract_test.exs` | docs drift gate seam | transform | existing bounded `assert_contains_all/ordered?/String.contains?` assertions | exact |
| `test/mix/tasks/verify.phase97_test.exs` (new) | task behavior test | request-response | `test/mix/tasks/verify_adopter_test.exs` + `verify_workspace_clean_test.exs` | role-match |
| `test/mix/tasks/workflow_wiring_test.exs` | wiring guardrail | transform | existing `mix.exs` preferred_env assertions | exact |
| `.github/workflows/ci.yml` (optional for phase 97) | CI gate wiring | batch | existing phase verify steps + adopter-verify job style | role-match |
| `guides/golden-path.md` (only if needed for one-hop consistency) | wayfinding surface | request-response | existing authority handoff links to support/example guides | role-match |
| `examples/phoenix_meilisearch/README.md` (only if contradiction fix touches proof wording) | live runbook authority | request-response | existing CI parity and env table sections | exact |

## Pattern Assignments

### 1) Freeze ledger shape before broad docs edits

**Apply to:** `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md`  
**Why it matters:** D-10/D-11 require one stable mapping contract consumed by phases 98/99. Avoid ad-hoc prose.

**Analog A (traceability table shape):** `.planning/REQUIREMENTS.md`
```md
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRUTH-01 | Phase 97 | Pending |
| TRUTH-02 | Phase 97 | Pending |
```

**Analog B (verification anchor columns):** `97-VALIDATION.md`
```md
| Task ID | Plan | Wave | Requirement | ... | Automated Command | ... |
|---------|------|------|-------------|-----|-------------------|-----|
| 97-01-01 | 01 | 1 | TRUTH-01 | ... | rg "CST-TRUTH-01-INSTALL..." ... |
```

**Phase 97 pattern decision:** build the new ledger as a compact table with one row per requirement statement mapping:
`Requirement -> Canonical Statement ID -> Owner Surfaces -> Verify/Test Anchor`.

---

### 2) Canonical-authority doc + reference-only entry surfaces

**Apply to:** `guides/support-and-compatibility.md`, `README.md`, `CONTRIBUTING.md`, `guides/outside-adopter-intake.md`  
**Why it matters:** D-01/D-02 require one normative wording authority and link-based routing elsewhere.

**Canonical authority pattern:** `guides/support-and-compatibility.md`
```md
This guide is the single current support and readiness authority for Scrypath.
...
- `mix verify.adopter` is the fast path.
- `mix verify.adopter --live` is the canonical live proof.
```

**Reference routing pattern:** `README.md`
```md
**Support and readiness:** ... use [guides/support-and-compatibility.md](guides/support-and-compatibility.md).
**Outside integrations and evidence:** ... [guides/outside-adopter-intake.md](guides/outside-adopter-intake.md).
```

**Maintainer anti-duplication pattern:** `CONTRIBUTING.md`
```md
... keep that guide as the single authority instead of turning this file into a second matrix.
... refer to [guides/outside-adopter-intake.md]...
```

---

### 3) Contradiction fixes must be narrow and evidence-oriented

**Apply to:** `guides/outside-adopter-intake.md` (and only minimum aligned surfaces in phase 97)  
**Why it matters:** phase 97 allows coherence fixes, not full phase 98 rewrite.

**Current risk signal to resolve in-scope:** install snippet mismatch  
- `README.md` currently shows `{:scrypath, "~> 0.3"}`  
- `guides/outside-adopter-intake.md` currently says `{:scrypath, "~> 1.0"}`

**Evidence bundle pattern to preserve:** `guides/outside-adopter-intake.md`
```md
Please fill out:
1. Adopter context and Environment matrix
2. Scrypath Ref or Hex version
3. Chosen proof path and Sync mode
```

**Phase 97 guard:** fix only trust-breaking contradictions (version/ref truth, release-vs-main wording, proof-command boundary), defer broad copy harmonization to phase 98.

---

### 4) Phase verify task pattern is standardized and hermetic

**Apply to:** `lib/mix/tasks/verify.phase97.ex`  
**Why it matters:** repository uses narrow `verify.phaseNN` gates as trust spines.

**Analog:** `lib/mix/tasks/verify.phase96.ex`
```elixir
defmodule Mix.Tasks.Verify.Phase96 do
  @shortdoc "Runs focused facet value search verification (Phase 96)"

  @focused_tests [
    "test/scrypath/search_test.exs",
    "test/scrypath/meilisearch_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)
    run_test!(@focused_tests, "Phase 96 facet value search verification")
    Mix.Task.run("docs", ["--warnings-as-errors"])
  end
end
```

**Phase 97 copy-forward:** same `ensure_no_args!`, focused tests, and docs warning gate; only change focused file list and label.

---

### 5) Docs-contract assertions should pin anchors, not paragraphs

**Apply to:** `test/scrypath/docs_contract_test.exs`  
**Why it matters:** phase 97 wants durable contract checks without brittle prose snapshotting.

**Bounded assertion pattern:**
```elixir
assert_contains_all(@support_guide, [
  "Phoenix + Meilisearch",
  "`:inline`",
  "`:manual`",
  "`:oban`",
  "outside-adopter evidence"
])
```

**Ordering contract pattern:**
```elixir
assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_head, "mix deps.get", "mix test")
```

**Plan impact:** add phase-97-specific assertions for canonical statement IDs/anchors and release-vs-main wording markers, but keep checks string/ordering based.

---

### 6) New phase task tests should mirror existing task-test style

**Apply to:** `test/mix/tasks/verify.phase97_test.exs` (new), `test/mix/tasks/workflow_wiring_test.exs` (optional extension)  
**Why it matters:** keeps gate behavior auditable without overtesting docs prose.

**Analog A (arg guards + progress marker):** `test/mix/tasks/verify_adopter_test.exs`
```elixir
assert_raise Mix.Error, ~r/does not accept arguments/, fn -> ... end
...
output = capture_io(fn -> Mix.Task.run("verify.adopter", ["--fast"]) end)
assert output =~ ~r/verify\.adopter: running fast adopter contracts/
```

**Analog B (preferred_env registration):** `test/mix/tasks/workflow_wiring_test.exs`
```elixir
envs = Scrypath.MixProject.cli()[:preferred_envs]
assert envs[:"verify.workspace_clean"] == :test
```

**Phase 97 copy-forward:** verify no-args behavior, focused test list marker strings, and `mix.exs` alias registration for `"verify.phase97": :test`.

---

### 7) CI and contributor docs should keep required-check posture lean

**Apply to:** `CONTRIBUTING.md`, optional `.github/workflows/ci.yml` phase-97 step  
**Why it matters:** v1.27 gate strategy explicitly avoids required-check noise.

**Required-check contract pattern:** `CONTRIBUTING.md`
```md
Treat **`main-ci`**, **`repo-hygiene`**, and **`release-truth`** as the only routine merge blockers...
```

**Workflow wiring analog:** `.github/workflows/ci.yml`
```yaml
- name: Adopter verify (`mix verify.adopter`)
  run: mix verify.adopter
```

**Phase 97 guard:** if `mix verify.phase97` is wired into CI, keep it in feature-lane trust coverage context and do not implicitly broaden always-required gates beyond the documented strategy.

## Shared Patterns to Reuse Directly

1. **Authority routing:** keep normative policy in `guides/support-and-compatibility.md`; other docs link to it.  
2. **Ledger-first freeze:** write `97-CONTRACT-TRACEABILITY.md` before broad surface reconciliation.  
3. **Hermetic phase gate:** implement `verify.phase97` in existing `verify.phaseNN` style (`app.start`, no args, focused tests, docs warnings).  
4. **Bounded docs contracts:** assert stable terms/order/anchors via `docs_contract_test.exs`, not full paragraph snapshots.  
5. **Task-level tests for gate behavior:** model new task tests on `verify_adopter_test.exs` and wiring assertions on `workflow_wiring_test.exs`.  
6. **Lean required checks:** preserve `main-ci` / `repo-hygiene` / `release-truth` as baseline merge blockers.

## Anti-Patterns (Phase 97 Scope Guard)

- Do not expand runtime capability classes (autocomplete/suggestions, vector/hybrid, backend broadening, new public runtime APIs).  
- Do not perform phase-98-scale prose rewrites while freezing phase-97 contract statements.  
- Do not introduce parser-heavy docs lint systems; reuse existing string/ordering assertion seams.  
- Do not create a second canonical policy surface outside `guides/support-and-compatibility.md`.  

## Metadata

**Analog search scope:** `.planning/` v1.27 files, `guides/`, root docs, `lib/mix/tasks/`, `test/scrypath/docs_contract_test.exs`, `test/mix/tasks/`, `.github/workflows/ci.yml`  
**Pattern extraction date:** 2026-05-27
