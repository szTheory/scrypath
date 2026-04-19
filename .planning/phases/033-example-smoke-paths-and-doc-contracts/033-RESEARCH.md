# Phase 33 — Technical research: example smoke paths and doc contracts

**Question:** What do we need to know to plan **Phase 33** (root-facing docs and tests agree on **cwd** for `scripts/smoke.sh` and example integration smoke; extend `docs_contract_test`) well?

**Answer:** This phase is a **small, mechanical doc + contract-test alignment**. The filesystem already has **exactly one** `smoke.sh` at `examples/phoenix_meilisearch/scripts/smoke.sh` (no `scripts/smoke.sh` at the repository root). Several **published** markdown files still echo **`./scripts/smoke.sh`** in a **repo-root voice**, which reads like “run this from where you cloned Scrypath” and fails because `./scripts/smoke.sh` is not there. The example script **does** `cd` to its app root internally (`dirname "$0")/..`), so **`bash examples/phoenix_meilisearch/scripts/smoke.sh`** from the monorepo root would work today—but docs must not teach **`./scripts/smoke.sh` without an explicit `cd examples/phoenix_meilisearch` (or equivalent path)** per **REQUIREMENTS.md** Phase 33 success criteria. Planning should enumerate **line-level edits**, pick **one canonical phrasing pattern**, add **`docs_contract_test.exs` blocks** that lock both **positive** (required substrings / ordering) and **filesystem** invariants, and **defer** golden-path **CI narrative** fixes to **Phase 34** (`INT-GOLDEN-PATH-CI-STORY`) unless scope explicitly expands.

## Key files (authoritative today)

| Path | Role |
|------|------|
| `examples/phoenix_meilisearch/scripts/smoke.sh` | Sole smoke script; lines 5–6 `cd` to example app root |
| `README.md` | Root adopter entry; **line 19** bundles Compose + **`./scripts/smoke.sh`** without `cd` |
| `CONTRIBUTING.md` | **Line 43** `phoenix-example-integration` row ends with **`./scripts/smoke.sh`** for “approximate locally” |
| `guides/golden-path.md` | **Line 126** lists **`./scripts/smoke.sh`** inside the example runbook bullet (cwd ambiguity); **lines 126–127** also carry **CI wording** misaligned with PR job (Phase 34) |
| `examples/phoenix_meilisearch/README.md` | Already correct: **lines 35–38** “From this directory” + `./scripts/smoke.sh` |
| `test/scrypath/docs_contract_test.exs` | Extend here (or tightly adjacent module) for cwd / path contracts |
| `.planning/v1.6-MILESTONE-AUDIT.md` | Gaps **INT-ROOT-SMOKE-PATH**, **INT-DOCS-CONTRACT-DEPTH** justify this phase |
| `.planning/REQUIREMENTS.md` | Phase 33 success criteria (lines 108–111) + REQ traceability rows |

## Findings

### 1. Filesystem truth (locks planning scope)

- **Glob:** only `examples/phoenix_meilisearch/scripts/smoke.sh` exists.
- Repo root **`scripts/`** contains **`verify_phase11_docker.sh`** only — **no** `scripts/smoke.sh`.
- Therefore any maintainer doc that says literally **`./scripts/smoke.sh`** without prior **`cd examples/phoenix_meilisearch`** (or without a **root-relative path** to the script) is **objectively wrong** for a reader standing in the clone root.

### 2. Root-facing doc defects (concrete lines to edit)

**`README.md` — ~line 19** (Integration smoke paragraph)

- Current (abridged): mentions `examples/phoenix_meilisearch`, Compose, and **`./scripts/smoke.sh`** in one breath.
- **Risk:** Readers infer repo-root execution.
- **Replacement patterns (pick one style and use consistently):**
  - **Pattern A (matches REQUIREMENTS wording):**  
    `cd examples/phoenix_meilisearch` then `./scripts/smoke.sh` in a **two-line fenced shell block** or inline `` `cd examples/phoenix_meilisearch && ./scripts/smoke.sh` ``.
  - **Pattern B (“equivalent”):** From repo root, `` `bash examples/phoenix_meilisearch/scripts/smoke.sh` `` (script already resolves its own `ROOT`; still spell out **path from clone root** so `./scripts/...` never appears in root voice).

**`CONTRIBUTING.md` — line 43** (`phoenix-example-integration` table cell)

- Trailing clause: “or **`./scripts/smoke.sh`**” — read from **clone root** after the table, this is the **same failure mode** called out in **`v1.6-MILESTONE-AUDIT.md`** flow “CONTRIBUTING phoenix-example-integration local approximation”.
- **Fix:** Same as README — either **`cd examples/phoenix_meilisearch && ./scripts/smoke.sh`** or **`bash examples/phoenix_meilisearch/scripts/smoke.sh`** with a short “from repository root” fragment.

**`guides/golden-path.md` — ~line 126**

- Bullet embeds **`./scripts/smoke.sh`** as part of “what the runbook covers”; link target is correct (`examples/phoenix_meilisearch/README.md`).
- **Phase 33:** Clarify cwd in prose (e.g. “from **`examples/phoenix_meilisearch/`**, the runbook documents **`./scripts/smoke.sh`** …”) so the substring **`./scripts/smoke.sh`** is never **orphaned** in a root-voice paragraph.
- **Phase 34 (do not conflate):** **Lines 126–127** “**local** / optional CI wiring” vs **`.github/workflows/ci.yml`** `phoenix-example-integration` on PRs — **INT-GOLDEN-PATH-CI-STORY**; only touch if Phase 33 scope explicitly includes CI copy.

### 3. Files that are already safe or lower priority

- **`examples/phoenix_meilisearch/README.md`:** Canonical; keep as **source of truth** for env + commands.
- **`CHANGELOG.md`:** References **`scripts/smoke.sh`** inside an **example app** bullet (not `./scripts` from root) — optional polish only if you want historical entries to mirror the new canonical phrase.
- **`.planning/**` phase artifacts:** Mention `./scripts/smoke.sh` in verification/history; **not** “published adopter” paths under Phase 33 success criteria, but align if you want grep consistency.

### 4. `docs_contract_test.exs` today (Phase 32 patterns to extend)

- Module reads **`@readme`**, **`@contributing`**, **`@guides["guides/golden-path.md"]`** (via `@guides`).
- **Phase 29** test **`"phase 29 golden path guide and adoption readme contract"`** (lines 103–131) asserts golden-path + README **anchors** but does **not** assert smoke **cwd** safety.
- **Phase 32** test **`"phase 32 AUDT-01 planning hygiene contracts"`** (lines 527–564) shows the **Nyquist** pattern: `File.read!` planning files + **`refute`/`assert_contains_all`** literals.

## Risks

| Risk | Mitigation |
|------|------------|
| **Over-scoping into Phase 34** (golden-path CI story) | Treat **INT-GOLDEN-PATH-CI-STORY** as **34** unless product owner expands **33**. |
| **Brittle regex** on Markdown | Prefer **`assert_contains_all` / `ordered?`** on **short stable phrases** over complex multiline regex. |
| **False sense of security** | Pair **string contracts** with **`File.regular?("examples/phoenix_meilisearch/scripts/smoke.sh")`** and **`refute File.regular?("scripts/smoke.sh")`** so a mistaken “add root wrapper named smoke.sh” does not silently satisfy prose-only tests. |
| **HexDocs / ExDoc** | Only **published** trees need hygiene; `.planning/` remains exempt from “no `ADPT-NN`” style rules per existing **`@published_markdown_for_hygiene`** list — do not move planning strings into that list. |

## Verification approach (executor checklist)

1. Before edits: `test -f examples/phoenix_meilisearch/scripts/smoke.sh` and `test ! -f scripts/smoke.sh` from repo root.
2. After doc edits: `mix test test/scrypath/docs_contract_test.exs`.
3. Grep gate (manual or CI-local): from repo root, `rg '\./scripts/smoke\.sh' README.md CONTRIBUTING.md guides/golden-path.md` — every hit must be **scoped** (e.g. only inside a line that also states **`cd examples/phoenix_meilisearch`**, or replace `./scripts/` with **root-relative `examples/phoenix_meilisearch/scripts/smoke.sh`**).
4. Optional full slice: `mix verify.phase5 --skip-integration` if other docs changed in the same PR.

---

## Validation Architecture

**Nyquist / contract-testing for Phase 33**

### Framework

- **ExUnit** via **`mix test`**; contract module **`test/scrypath/docs_contract_test.exs`** (already included in **`mix verify.phase11`** / phase gates per existing task sources).

### Quick command

```bash
mix test test/scrypath/docs_contract_test.exs
```

### How contract tests should lock smoke path wording

1. **Filesystem invariants (cheap, high signal)** — new test block, e.g. **`"example smoke script path exists; root scripts/smoke.sh does not"`**:
   - `assert File.regular?("examples/phoenix_meilisearch/scripts/smoke.sh")`
   - `refute File.regular?("scripts/smoke.sh")` (guard against reintroducing wrong location)

2. **Grep-able positive strings (after doc edits)** — new test block, e.g. **`"root-facing docs document example smoke cwd (Phase 33)"`**:
   - **`@readme`**: require one of:
     - **`cd examples/phoenix_meilisearch`** near the integration-smoke story, **or**
     - explicit **`examples/phoenix_meilisearch/scripts/smoke.sh`** / **`bash examples/phoenix_meilisearch/scripts/smoke.sh`**
   - **`@contributing`**: same for the **`phoenix-example-integration`** narrative (the cell that today ends with **`./scripts/smoke.sh`**).
   - **`@guides["guides/golden-path.md"]`**: require that **`./scripts/smoke.sh`** only appears **paired** with **`examples/phoenix_meilisearch`** / **`cd`** / “**from this directory**”-class wording (choose one explicit pattern in implementation).

3. **Forbidden patterns (use carefully)** — optional **`refute`** on **`README.md`** / **`CONTRIBUTING.md`** if you adopt a **strict** policy such as: no bare substring **`./scripts/smoke.sh`** at all in those two files (forces root-relative or `&&` form). This is **stricter** than the audit wording; only adopt if editors agree.

4. **Ordering** — reuse existing **`ordered?/2`** if you need “`cd examples/phoenix_meilisearch` appears **before** first `./scripts/smoke.sh`” inside a single file.

### Per-requirement sampling notes

| REQ-ID | What to sample in plans / UAT |
|--------|-------------------------------|
| **ADPT-01** | **README** integration paragraph + **golden-path** runbook bullets: a new reader never tries **`./scripts/smoke.sh`** from clone root on the “happy path” links. |
| **EXAM-02** | **Example README** remains canonical; **CONTRIBUTING** row still points at **`examples/phoenix_meilisearch`** env table; contract test asserts **local approximation** wording matches **cwd** truth. |
| **VRFY-02** | **CONTRIBUTING** CI table: default **`test`** job vs integration jobs unchanged; only the **smoke footnote** copy is corrected + locked by test. |
| **AUDT-01** | Close **`INT-DOCS-CONTRACT-DEPTH`** angle: contract tests **assert documented shell paths** against **repo layout** (smoke script location); optional follow-up: one-line note in **`v1.6-MILESTONE-AUDIT.md`** or milestone close checklist when gap is verified (separate commit if policy requires audit doc updates only after merge). |

### Suggested new `test` blocks (names are suggestions for `033-01-PLAN.md`)

1. **`"example smoke script exists only under phoenix_meilisearch"`** — filesystem asserts above.
2. **`"README and CONTRIBUTING document example smoke without repo-root ./scripts/smoke.sh"`** — string/ordered asserts per chosen canonical pattern.
3. **(Optional)** **`"golden path runbook bullet stays linked to example README"`** — extend existing phase 29 test or add sibling assert so golden-path edits do not drop **`examples/phoenix_meilisearch/README.md`** while tightening cwd language.

---

Next: **`033-CONTEXT.md`** (if used in this repo), **`033-VALIDATION.md`**, and **`033-01-PLAN.md`** for execution.

## RESEARCH COMPLETE
