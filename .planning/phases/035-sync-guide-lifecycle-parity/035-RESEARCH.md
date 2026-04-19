# Phase 35 — Technical research: sync guide lifecycle parity

**Phase:** 035 — sync-guide-lifecycle-parity  
**Question:** What do we need to know to plan README ↔ **`guides/sync-modes-and-visibility.md`** authority repair well?

## Summary

**`v1.6-MILESTONE-AUDIT.md`** gap **`INT-SYNC-GUIDE-AUTHORITY`**: README positions **`guides/sync-modes-and-visibility.md`** as the normative place for lifecycle, Phoenix, and recovery language, and shows a **single-line operator lifecycle** progression that does **not** appear in the guide today. The guide already covers Phoenix implications, recovery posture per mode, and “accepted work ≠ visibility” — the drift is **terminological continuity** (the explicit state chain), not missing conceptual depth.

**Recommended closure (matches 035-CONTEXT D-01–D-09):** enrich the guide with one **canonical operator lifecycle** subsection (same chain as README, short gloss, how `:inline` / `:oban` / `:manual` sit on that chain without duplicating the full mode tables), add a **surgical README precision** sentence (guide wins on conflict; README chain matches guide §), and extend **`docs_contract_test.exs`** with **stable substring locks** on the lifecycle string in the guide (and optionally README) following phase 33–34 style.

## Findings

### Current README (authority + chain)

```122:128:README.md
The full contract—lifecycle states, Phoenix implications, recovery language, and what “success” in a controller or LiveView really means—lives in **`guides/sync-modes-and-visibility.md`**. Treat that guide as the authority; keep README as the compact decision surface.

All three modes share one operator-facing lifecycle:

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`
```

### Current guide shape

- **`## The Contract`** table defines the three modes at a high level.
- Per-mode sections (`:inline`, `:oban`, `:manual`) already carry **visibility**, **failure modes**, and **recovery posture**.
- **`## Phoenix Implications`** and **`## Recovery Still Matters`** cover README’s “Phoenix / recovery” promise — but the **named progression** (`requested` → …) is absent.

### Doc contract precedent

- **`test/scrypath/docs_contract_test.exs`** already uses **`assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [...])`** in the phase-6 bundle test (~L228).
- Phase 34 added a **dedicated** narrow test for README ↔ golden-path parity; phase 35 can mirror that pattern for **README ↔ sync-guide lifecycle string** if we want belt-and-suspenders, or extend the **existing** sync-modes assertion list only (035-CONTEXT D-05: prefer minimal tokens).

### Product / ecosystem pattern

- **Scout / Searchkick-style split:** README = orientation + decision surface; long doc = contract. Scrypath already follows this; the fix is to **not** narrow README alone (hides vocabulary from GitHub-first readers) but to **make the authority sentence true** with a small normative block in the guide.

### Footguns

- **Dual spec:** If both README and guide show the chain, README must state **guide wins** on disagreement (D-01).
- **Brittle tests:** Avoid ordered multi-paragraph locks; prefer **one canonical lifecycle string** (same monospace line as README) plus maybe **section heading** anchor string.

## Recommendations for planning

1. Insert **`## Operator lifecycle`** (or **`## Shared operator lifecycle`**) **immediately after** **`## The Contract`**, before **`## :inline`**, containing:
   - The **exact** lifecycle line from README (backtick monospace).
   - 1–3 sentences per **node** or a **compact table** (executor choice) clarifying **search visibility** vs **queue/repo** implications where it matters.
   - One short paragraph mapping **`:inline`**, **`:oban`**, **`:manual`** to “where callers typically observe progress” on the shared chain — **without** copying the full per-mode sections.
2. README: after the authority paragraph, add **one** sentence: normative semantics live in the guide; **if README and guide disagree, the guide wins**; the lifecycle line matches the guide section (optional markdown link to heading anchor once stable).
3. **`docs_contract_test.exs`**: add the lifecycle string (or the minimal token set agreed in CONTEXT) to **`assert_contains_all`** for **`guides/sync-modes-and-visibility.md`**; optionally assert README still contains the same backtick line.

## Validation Architecture

> Nyquist / Dimension 8 — doc-only phase: verification is **contract tests + human read** of the new guide section for tone duplication.

| Dimension | How we sample | Automated signal |
|-----------|----------------|-------------------|
| **Doc parity** | After every task touching markdown | `mix test test/scrypath/docs_contract_test.exs` |
| **Published hygiene** | Same run | Existing `published markdown avoids internal planning...` test |
| **Elixir fence validity** | Same suite | Existing fence parser tests (if any in suite scope) |

**Manual-only:** Read **`guides/sync-modes-and-visibility.md`** from top through **`## :inline`** — confirm the lifecycle subsection does not **repeat** the full three-mode contract table and reads as **one** progression gloss.

**Wave 0:** Not applicable — no new test framework; reuse repo **`mix test`**.

## RESEARCH COMPLETE
