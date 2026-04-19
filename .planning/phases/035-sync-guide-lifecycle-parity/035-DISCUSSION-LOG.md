# Phase 35: Sync guide lifecycle parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **035-CONTEXT.md** — this log preserves alternatives considered.

**Date:** 2026-04-19  
**Phase:** 35 — Sync guide lifecycle parity  
**Areas discussed:** Authority repair strategy, Lifecycle string placement, Doc contract / verify, README promise scope  
**Method:** Four parallel **generalPurpose** research subagents + orchestrator synthesis (user requested one-shot deep research: ecosystem idioms, Laravel Scout / Searchkick patterns, DX, footguns).

---

## 1. Authority repair strategy

| Option | Description | Selected |
|--------|-------------|----------|
| A — Enrich guide | Guide owns full lifecycle semantics; README authority sentence stays maximal | Partial |
| B — Narrow README | Soften or remove claims until README cannot be falsified | Rejected as sole strategy |
| C — Hybrid | Guide expansion + surgical README precision (“guide wins on conflict”) | ✓ |

**User's choice:** **Hybrid (C)** — enrich **`guides/sync-modes-and-visibility.md`**, add explicit **guide wins on conflict** / normative vs summary framing in **README**; avoids README-only retreat that hides operator vocabulary from GitHub-first readers.

**Notes:** Elixir/Hex idioms favor README as routing + ExDoc/repo guides as versioned depth; Scout/Searchkick succeed when README stays decision-oriented and deep docs own failure modes.

---

## 2. Lifecycle string placement

| Option | Description | Selected |
|--------|-------------|----------|
| Guide only | Chain only in guide | Rejected — README already carries high-signal chain |
| README only | Chain only in README | Rejected — guide must fulfill README pointer |
| Duplicated full spec | Two full specifications | Rejected — drift footgun |
| README teaser + guide canonical | One line in README; expanded section in guide + anchor | ✓ |

**User's choice:** **README teaser + guide canonical** with cross-link.

**Notes:** Matches Kubernetes / Sidekiq pattern — one canonical narrative, shallow repeat at entrypoint.

---

## 3. Doc contract / mix verify

| Option | Description | Selected |
|--------|-------------|----------|
| No new tests | Editorial only | Rejected — audit class can regress |
| Max substring / prose twins | Lock long identical sentences | Rejected — fights rewording |
| Minimal stable-token parity | `assert_contains_all` on lifecycle vocabulary / guide | ✓ |

**User's choice:** Extend **`docs_contract_test.exs`** with **minimal** locks (stable tokens, existing guide assertion pattern).

**Notes:** Treat identifiers and operator vocabulary as contract; avoid marketing string duplication.

---

## 4. README promise scope

| Option | Description | Selected |
|--------|-------------|----------|
| Surgical guide parity | Add lifecycle vocabulary to guide | ✓ (primary) |
| README diet | Strip promises heavily | Rejected — risks ADPT-02 regression |

**User's choice:** **Surgical guide parity** as primary fix; README table / heuristics preserved; at most one precision tweak to authority sentence.

**Notes:** Subagent consensus — Phoenix/recovery already strong in guide; gap is **terminological continuity** for the lifecycle chain.

---

## Claude's Discretion

Exact heading text, table vs prose for state gloss, and exact test token list — see **035-CONTEXT.md**.

## Deferred Ideas

None captured.
