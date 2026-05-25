# Phase 88: Evidence-Backed Papercuts And Next-Pull Verdict - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/related-data-and-reindexing.md` | guide | documentation | `guides/getting-started.md` | exact |
| `test/scrypath/docs_contract_test.exs` | test | validation | `test/scrypath/docs_contract_test.exs` | exact |
| `.planning/ROADMAP.md` | planning | documentation | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | planning | documentation | `.planning/STATE.md` | exact |
| `.planning/REQUIREMENTS.md` | planning | documentation | `.planning/REQUIREMENTS.md` | exact |

## Pattern Assignments

### `guides/related-data-and-reindexing.md` (guide, documentation)

**Analog:** `guides/getting-started.md`

**Core Pattern: Context-based orchestration with concrete Elixir blocks** (lines 43-61):
```elixir
defmodule MyApp.Content do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def search_posts(query, opts \\ []) do
    Scrypath.search(Post, query,
      Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
    )
  end

  def publish_post(post, attrs) do
    with {:ok, post} <- update_post(post, attrs),
         {:ok, _sync} <-
           Scrypath.sync_record(Post, post,
             backend: Scrypath.Meilisearch,
             sync_mode: :inline
           ) do
      {:ok, post}
    end
  end
end
```

---

### `test/scrypath/docs_contract_test.exs` (test, validation)

**Analog:** `test/scrypath/docs_contract_test.exs`

**Core Pattern: String inclusion assertion for guides** (lines 540-554):
```elixir
    assert_contains_all(@guides["guides/drift-recovery.md"], [
      "Symptom",
      "Diagnosis",
      "Action",
      "Verify",
      "Scrypath.failed_sync_work",
      "mix scrypath.failed",
      "failed_work_counts",
      "mix scrypath.index.contract_drift",
      "Scrypath.index_contract_drift",
      "mix scrypath.settings.diff",
      "relevance-tuning.md",
      "multi-index-search.md",
      "sync-modes-and-visibility.md"
    ])
```
*(Note: To test the new guide, it must be added to the `@guide_paths` list at the top of the test module.)*

---

### `.planning/ROADMAP.md` (planning, documentation)

**Analog:** `.planning/ROADMAP.md`

**Core Pattern: Updating milestone block to show completion** (lines 53-54):
```markdown
- [x] **`v1.22` shipped + archived in-repo** (**2026-05-24**) — *Composition And Real-App Depth* — phases **83–85**, **12** requirements — [archive](milestones/v1.22-ROADMAP.md) · [requirements](milestones/v1.22-REQUIREMENTS.md) · [audit](milestones/v1.22-MILESTONE-AUDIT.md)
- [ ] **`v1.23` active** (**opened 2026-05-24**) — *Outside-Adopter Evidence And Support-Truth Reconciliation* — phases **86–88**, **8** requirements — [requirements](REQUIREMENTS.md)
```

---

### `.planning/STATE.md` (planning, documentation)

**Analog:** `.planning/STATE.md`

**Core Pattern: Closing state block** (lines 35-37):
```markdown
- **Phase 87 plan 02 complete:** Both submissions successfully passed the human verification checkpoint as genuine outside-adopter attempts and were classified as Class A (Defended-path). The findings were recorded in the evidence ledger, establishing a PASS state for the defended-path gate.
- **v1.15 close:** Second slice shipped **OPS2-01**–**OPS2-08** across phases **62–64**; persistence authority **(A)** file + GitOps; **OPSUI-FUT-02** / **Tier C** unchanged — **`milestones/v1.15-REQUIREMENTS.md`**.
- **v1.16 open:** Prioritize **execution honesty** over new indexing features; **stub-first OPSUI CI** unchanged; parallel **`.planning/research/`** refresh **skipped** at open (existing research retained).
```

---

### `.planning/REQUIREMENTS.md` (planning, documentation)

**Analog:** `.planning/REQUIREMENTS.md`

**Core Pattern: Standard markdown requirement table checklist update**

## Shared Patterns

### Elixir Code Block Validation
**Source:** `test/scrypath/docs_contract_test.exs`
**Apply to:** All guides
```elixir
  test "all Elixir code fences in docs stay syntactically valid" do
    for snippet <-
          extract_elixir_fences(@readme) ++
            extract_elixir_fences(@architecture) ++
            extract_elixir_fences(@release_docs) ++
            guide_fences() do
      assert {:ok, _quoted} = Code.string_to_quoted(snippet)
    end
  end
```
*(When adding Elixir blocks to guides, `docs_contract_test.exs` will automatically parse and test their syntactic validity if they are in `@guides`.)*

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | | | |

## Metadata

**Analog search scope:** `guides/`, `test/`, `.planning/`
**Files scanned:** 5
**Pattern extraction date:** 2026-05-24
