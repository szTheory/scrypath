# Phase 34 — Technical research: golden path, README, and CI alignment

**Question:** What do we need to know to plan **Phase 34** (canonical first-schema story across README ↔ `guides/golden-path.md`; golden-path prose matches **`phoenix-example-integration`** on PRs) well?

**Answer:** This phase closes **`v1.6-MILESTONE-AUDIT.md`** gaps **INT-GOLDEN-VS-README-SCHEMA** and **INT-GOLDEN-PATH-CI-STORY**. Today **`guides/golden-path.md`** already shows **`field :status, :string`** in the schema fence (aligned with **`examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex`**). **`README.md` Quick Path** still shows **`field :status, Ecto.Enum, values: [:draft, :published]`** while the same Quick Path **`PostController`** example filters with **`status: "published"`** — string filter + enum field is a footgun for copy-paste adopters. The golden path **Integration smoke** section (**~L122–L127**) claims the example proof is **“local / optional CI wiring”**; **`.github/workflows/ci.yml`** defines **`phoenix-example-integration`** on **`pull_request:`** (and **`push:`** to **`main`**), with **Postgres 16** + **Meilisearch v1.15**, **`cd examples/phoenix_meilisearch && mix test`**, and **`SCRYPATH_EXAMPLE_INTEGRATION=1`** — so the narrative must not imply CI is optional or local-only fiction. **`test/scrypath/docs_contract_test.exs`** currently **requires** the substring **`optional CI wiring`** in test **`"golden path scopes example smoke script..."`** (Phase 33 anchor); Phase 34 **replaces** that anchor with strings that lock the **new** truthful CI story and adds a **narrow README ↔ golden-path `status` parity** check per **034-CONTEXT.md** D-07–D-08. README **Quick Path** must be **slimmed** (D-09): drop the **three** large duplicate Elixir fences (schema + context + controller) in favor of short prose + **at most one** micro-fence, while **rewriting** the **`"README opens with installation, quick path..."`** test so it no longer requires **`MyApp.Content`**, **`MyAppWeb.PostController`**, etc. **inside `@readme` alone** — those strings remain available from **`guides/golden-path.md`** and the existing **`"guide snippets stay aligned..."`** test that joins README + all guides.

## Key files (authoritative today)

| Path | Role |
|------|------|
| `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` | Canonical **`field(:status, :string)`** |
| `README.md` | Quick Path **Ecto.Enum** drift; three-fence duplicate of golden path |
| `guides/golden-path.md` | Canonical ADPT-01 spine; **CI bullet** misaligned with `ci.yml` |
| `.github/workflows/ci.yml` | **`on: pull_request:`** + job **`phoenix-example-integration`** |
| `CONTRIBUTING.md` | Job ↔ purpose table (reference for wording; avoid duplicating full matrix in golden path) |
| `test/scrypath/docs_contract_test.exs` | Phase 33 **`optional CI wiring`** lock; README Quick Path assertions |
| `.planning/phases/034-golden-path-readme-and-ci-alignment/034-CONTEXT.md` | Locked decisions D-01–D-10 |

## Findings

### 1. Schema parity (INT-GOLDEN-VS-README-SCHEMA)

- Align README Quick Path schema fence with golden path + example: **`field :status, :string`**.
- Keep **`filter: [status: "published"]`** in any retained controller snippet **only** if controller fence remains; if Quick Path drops controller fence, parity is via golden path + guide-snippet test only.

### 2. CI parity (INT-GOLDEN-PATH-CI-STORY)

- Replace **“local / optional CI wiring”** with copy that states **GitHub Actions** runs **`phoenix-example-integration`** on **pull requests** (and optionally **pushes to `main`** if you mirror `ci.yml` literally — **do not invent** triggers).
- Second bullet should still point at **`CONTRIBUTING.md`** for the full job ↔ purpose table (D-06).

### 3. Contract tests

- Update **`"golden path scopes example smoke script to the phoenix_meilisearch example (Phase 33)"`**: remove dependency on **`optional CI wiring`**; add stable tokens agreed in implementation (e.g. **`phoenix-example-integration`**, **`pull request`**, **`GitHub Actions`** — pick one set and keep grep-friendly).
- Add **new** test (e.g. **Phase 34**): **`@readme`** and **`guides/golden-path.md`** both contain **`field :status, :string`** (and optionally matching **`use Scrypath`** field list lines — keep **narrow** per D-08).
- Refactor **`"README opens with installation, quick path..."`** expectations for slim Quick Path: preserve installation ordering, **`{:scrypath, "~> 0.3"}`**, **Start here** / **`guides/golden-path.md`**, transport/Oban lines; **replace** the block that requires full **`MyApp.*`** fences inside README with assertions appropriate to the new teaser (e.g. presence of **`## Quick Path`**, link to golden path, **`field :status, :string`** in README if one schema fence remains, or **only** prose + micro-snippet per executor choice).

### 4. Elixir fence validity

- **`test "all Elixir code fences in docs stay syntactically valid"`** must still pass after README edits — any remaining ```elixir fence must **`Code.string_to_quoted/1`** successfully.

## Risks

| Risk | Mitigation |
|------|------------|
| Over-asserting byte-identical fences between README and golden path | D-08: token-level parity only (`field :status, :string`, shared `use Scrypath` field lines if both keep schema fence). |
| Dropping VRFY / adoption anchors from README tests | D-10: update tests in the same PR as doc edits; run **`mix test test/scrypath/docs_contract_test.exs`**. |
| Bare **`ADPT-NN`** tokens in user docs | Hygiene test forbids them — do not paste REQ IDs into README/golden path. |

## Verification approach (executor checklist)

1. `mix test test/scrypath/docs_contract_test.exs`
2. `mix compile --warnings-as-errors` (if any `.ex` touched — typically not)
3. Optional: `rg 'optional CI wiring' README.md guides/golden-path.md` — should be **empty** after Phase 34 doc edits

---

## Validation Architecture

**Nyquist / contract-testing for Phase 34**

### Framework

- **ExUnit** via **`mix test`**; primary module **`test/scrypath/docs_contract_test.exs`**.

### Quick command

```bash
mix test test/scrypath/docs_contract_test.exs
```

### Sampling strategy

- After **every** doc or test edit task: run the quick command above.
- Before phase verification / PR: same command (full contract module is fast).

### Contract dimensions to lock

1. **README ↔ golden-path `status` parity** — both published files contain **`field :status, :string`** (and narrow extras per D-08).
2. **Golden path ↔ CI** — golden path **Integration smoke** section contains **`phoenix-example-integration`** and truthful **pull request** (or equivalent) phrasing; **must not** contain **`optional CI wiring`** after this phase.
3. **README Quick Path shape** — section exists and routes to golden path without three duplicate full-stack fences unless tests are explicitly updated to allow (preferred: **slim** per D-09 + test update).

### Manual-only

- Subjective read of README flow (optional); automated contracts are the gate.

## RESEARCH COMPLETE
