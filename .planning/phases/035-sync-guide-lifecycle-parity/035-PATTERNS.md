# Phase 35 — Pattern map

**Purpose:** Closest in-repo analogs for doc + contract-test work.

## Primary analog

| New / edited artifact | Role | Closest existing analog |
|----------------------|------|---------------------------|
| `guides/sync-modes-and-visibility.md` | Normative operator semantics | Same file today: per-mode sections + Phoenix block — **extend**, do not replace |
| `README.md` Sync Modes | Compact surface + CTA | Phase **034-01-PLAN**: README edits with **`docs_contract_test`** guards |
| `test/scrypath/docs_contract_test.exs` | Stable string locks | **`assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [...])`** ~L228; phase **034** dedicated parity test pattern ~L101 |

## Code excerpt — contract style

```elixir
assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [
  "search visibility is an operational concern",
  # ... extend with lifecycle line / heading per 035-01-PLAN
])
```

## PATTERN MAPPING COMPLETE

