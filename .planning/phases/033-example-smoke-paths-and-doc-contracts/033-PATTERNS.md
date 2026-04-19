# Phase 33 — Pattern map: example smoke paths and doc contracts

Maps **files to create or modify** (from `033-RESEARCH.md`) to **closest analogs** in the repo, especially `test/scrypath/docs_contract_test.exs` and Phase 32 planning/doc-contract patterns.

## Targets from research (authoritative list)

| Action | Path | Role |
|--------|------|------|
| **Modify** | `README.md` | Root adopter entry; integration smoke paragraph must not imply `./scripts/smoke.sh` from clone root without `cd` or root-relative path. |
| **Modify** | `CONTRIBUTING.md` | `phoenix-example-integration` row / footnote; same cwd failure mode as README. |
| **Modify** | `guides/golden-path.md` | Runbook bullet must scope `./scripts/smoke.sh` to example app directory or equivalent wording. **Defer** CI narrative vs `ci.yml` to Phase 34 unless scope expands. |
| **Modify** | `test/scrypath/docs_contract_test.exs` | Add filesystem + string contracts for smoke script location and root-facing doc phrasing. |
| **Reference only** | `examples/phoenix_meilisearch/README.md` | Canonical “from this directory” + `./scripts/smoke.sh`; align root docs to this voice. |
| **Reference only** | `examples/phoenix_meilisearch/scripts/smoke.sh` | Sole smoke script; `ROOT` + internal `cd` (see excerpt below). |
| **Optional** | `CHANGELOG.md`, `.planning/**` | Polish / grep consistency; not required by published-adopter success criteria in RESEARCH. |

**Create:** none required for Phase 33 core deliverable beyond normal phase artifacts (`033-01-PLAN.md`, etc.). **Optional follow-up:** one-line audit note in `.planning/v1.6-MILESTONE-AUDIT.md` when gap verified (separate commit if policy requires).

---

## Closest analog: smoke script layout (filesystem + bash)

**Analog:** `examples/phoenix_meilisearch/scripts/smoke.sh` — the only `smoke.sh` in the tree; repo root has `scripts/verify_phase11_docker.sh` but **no** `scripts/smoke.sh`.

```5:6:examples/phoenix_meilisearch/scripts/smoke.sh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
```

**Implication for docs:** `bash examples/phoenix_meilisearch/scripts/smoke.sh` from clone root works because of the above; root-facing markdown must never present orphaned `./scripts/smoke.sh` without prior `cd examples/phoenix_meilisearch` or an explicit root-relative path (per `033-RESEARCH.md` Patterns A/B).

---

## Closest analog: `docs_contract_test.exs` module shape

**Pattern:** module-level `File.read!` attributes (`@readme`, `@contributing`, `@guides`), then `test "..." do ... end` blocks. Guides are keyed paths in `@guides`.

```1:7:test/scrypath/docs_contract_test.exs
defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @architecture File.read!("ARCHITECTURE.md")
  @contributing File.read!("CONTRIBUTING.md")
```

```20:34:test/scrypath/docs_contract_test.exs
  @guide_paths [
    "guides/drift-recovery.md",
    "guides/getting-started.md",
    "guides/golden-path.md",
    ...
  ]
  @guides Enum.into(@guide_paths, %{}, fn path -> {path, File.read!(path)} end)
```

**Phase 29 analog (golden path + README adoption contract):** extend or sibling-test this block — it already locks `examples/phoenix_meilisearch/README.md` and Compose-style strings but **not** smoke cwd safety.

```103:131:test/scrypath/docs_contract_test.exs
  test "phase 29 golden path guide and adoption readme contract" do
    golden = @guides["guides/golden-path.md"]

    assert_contains_all(golden, [
      "Scrypath.search",
      ...
      "examples/phoenix_meilisearch/README.md",
      ...
    ])
    ...
    assert ordered?(@readme, "## Sync Modes", "## Search")
    assert ordered?(@readme, "## Versioning and upgrades", "## Search")
  end
```

**Phase 32 analog (Nyquist / planning invariants):** `File.read!` inside the test + `refute` / `assert_contains_all` on stable literals — same style as new Phase 33 blocks that read `@readme` / `@contributing` / `golden` (no need to add planning paths to `@published_markdown_for_hygiene`).

```527:564:test/scrypath/docs_contract_test.exs
  test "phase 32 AUDT-01 planning hygiene contracts (Nyquist invariants)" do
    state_md = File.read!(".planning/STATE.md")
    ...
    refute String.contains?(state_md, "pending_triage_v1_6"),
           "STATE.md must not retain pending_triage_v1_6 after AUDT-01 triage"

    assert_contains_all(state_md, [
      ...
    ])
    ...
  end
```

**CONTRIBUTING / CI analog:** existing test already asserts example path and job name; Phase 33 adds **smoke cwd** assertions in the same file, not a new module.

```288:302:test/scrypath/docs_contract_test.exs
  test "CONTRIBUTING documents default test path and live integration jobs (VRFY)" do
    assert_contains_all(@contributing, [
      ...
      "**`phoenix-example-integration`**",
      "examples/phoenix_meilisearch"
    ])
    ...
  end
```

---

## Test helpers to reuse (do not reimplement)

Defined at the bottom of `docs_contract_test.exs`:

| Helper | Purpose |
|--------|---------|
| `assert_contains_all(content, snippets)` | Assert each string is a substring of `content` (stable phrase contract). |
| `ordered?(content, first, second)` | Assert first needle appears before second (e.g. `cd` before `./scripts/smoke.sh` in one file). |
| `String.contains?/2`, `@readme =~ pattern`, `refute` | Positive/negative substring or regex checks. |
| `File.regular?/1` | Filesystem invariant: example smoke exists; root `scripts/smoke.sh` does not. |

```578:595:test/scrypath/docs_contract_test.exs
  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected docs to include #{inspect(snippet)}"
    end)
  end

  defp ordered?(content, first, second) do
    {first_index, second_index} =
      ...
    first_index < second_index
  end
```

**Hygiene guard (do not expand for Phase 33):** `@published_markdown_for_hygiene` lists shipped narrative paths; `.planning/` stays exempt from REQ-ID regex hygiene — keep new smoke-path tests on `@readme` / `@contributing` / `@guides["guides/golden-path.md"]` and optional `File.read!` for other paths only if explicitly in scope.

```36:44:test/scrypath/docs_contract_test.exs
  @published_markdown_for_hygiene [
    "README.md",
    "ARCHITECTURE.md",
    ...
    | @guide_paths
  ]
```

---

## Closest analog: Phase 32 execute plan (verification + file lists)

**Analog:** `.planning/phases/032-planning-and-state-hygiene/032-01-PLAN.md` — YAML frontmatter lists `files_modified`; each task’s `<verify>` runs `mix test test/scrypath/docs_contract_test.exs`.

```7:14:.planning/phases/032-planning-and-state-hygiene/032-01-PLAN.md
files_modified:
  - .planning/STATE.md
  - .planning/REQUIREMENTS.md
  ...
```

```64:68:.planning/phases/032-planning-and-state-hygiene/032-01-PLAN.md
  <verify>
    <automated>mix test test/scrypath/docs_contract_test.exs</automated>
  </verify>
```

**Phase 32 research analog:** `.planning/phases/032-planning-and-state-hygiene/032-RESEARCH.md` — calls out **Nyquist / dimension 8** regression via the same `mix test` slice; Phase 33 matches that posture for doc edits + new asserts.

---

## Closest analog: release gate already includes docs contract

**Analog:** `lib/mix/tasks/verify.phase11.ex` includes `test/scrypath/docs_contract_test.exs` in its task list — new tests run under the existing phase-11 rollup without new task wiring.

```23:23:lib/mix/tasks/verify.phase11.ex
        "test/scrypath/docs_contract_test.exs"
```

---

## Suggested new test names (map to `033-RESEARCH.md`)

Research suggests these **test description strings** as plan anchors:

1. **`"example smoke script exists only under phoenix_meilisearch"`** — `assert File.regular?("examples/phoenix_meilisearch/scripts/smoke.sh")`, `refute File.regular?("scripts/smoke.sh")`.
2. **`"README and CONTRIBUTING document example smoke without repo-root ./scripts/smoke.sh"`** — `assert_contains_all` / optional `ordered?` / optional strict `refute String.contains?` for bare `./scripts/smoke.sh` if team adopts strict policy.
3. **(Optional)** **`"golden path runbook bullet stays linked to example README"`** — sibling or extension of phase 29 test so tightening cwd language does not drop `examples/phoenix_meilisearch/README.md`.

---

## Doc phrasing analog: example README (canonical)

**Analog:** `examples/phoenix_meilisearch/README.md` — “From this directory” + `./scripts/smoke.sh` is correct because cwd is the example app root. Root docs should **either** mirror two-step `cd` + script **or** use root-relative `bash examples/phoenix_meilisearch/scripts/smoke.sh` (RESEARCH Patterns A/B).

---

## Out of scope analog (defer to Phase 34)

**Analog:** `guides/golden-path.md` lines called out in RESEARCH for **CI story** vs `.github/workflows/ci.yml` — align with **INT-GOLDEN-PATH-CI-STORY** in Phase 34; existing CI contract test is the pointer pattern:

```304:314:test/scrypath/docs_contract_test.exs
  test "CI workflow includes Phoenix example integration job wired to example path" do
    assert_contains_all(@ci_workflow, [
      "phoenix-example-integration:",
      "examples/phoenix_meilisearch",
      ...
    ])
  end
```

Phase 33 touches golden-path **only** for cwd-safe smoke wording unless scope explicitly expands.
