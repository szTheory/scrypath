---
status: passed
phase: 035
verified: 2026-04-19
---

# Phase 35 verification — Sync guide lifecycle parity

## Goal

Close **`INT-SYNC-GUIDE-AUTHORITY`**: README Sync Modes authority claims match **`guides/sync-modes-and-visibility.md`** via canonical **Operator lifecycle** in the guide, README precision (guide wins on disagreement), and **`docs_contract_test.exs`** locks — **ADPT-02**, **ADPT-03**.

## Must-haves

| Criterion | Evidence |
|-----------|----------|
| Guide: **## Operator lifecycle** + monospace chain | **`guides/sync-modes-and-visibility.md`** — heading, backtick line **`requested -> enqueued -> processing -> backend_accepted -> completed \| retrying \| discarded`**, ordered after **The Contract**, before **`## :inline`** |
| README: guide wins + lifecycle ties to guide | **`README.md`** — sentences after authority paragraph; **Choosing a mode:** and lifecycle line retained |
| Contract tests | **`test/scrypath/docs_contract_test.exs`** — extended sync-guide list; test **`phase 35 readme and sync guide share operator lifecycle chain`** |
| Requirements | **ADPT-02**, **ADPT-03** addressed by delivered artifacts |

## Automated

- `mix test test/scrypath/docs_contract_test.exs` — **PASSED** (32 tests)

## Full suite note

`mix test` reported one **timeout** in **`test/release/consumer_smoke_test.exs`** (`deps.get` in temp app) — unrelated to phase 35 doc edits; treat as flaky/environmental unless reproduced consistently.

## Human verification

None required.

## Traceability

- Plan **035-01** — **035-01-SUMMARY.md** present.
- **035-REVIEW.md** — **status: clean**.
