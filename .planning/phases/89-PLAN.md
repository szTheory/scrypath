---
phase: 89-related-data
---

# Phase 89: Related-Data Fan-Out API Plans

The executable plans for Phase 89 have been generated in the standard structured format at:

- `.planning/phases/89-related-data/89-01-PLAN.md`
- `.planning/phases/89-related-data/89-02-PLAN.md`
- `.planning/phases/89-related-data/89-03-PLAN.md`

You can execute them sequentially using the GSD orchestrator:

```bash
/gsd-execute-phase 89-related-data
```

## Summary of Plans

### 89-01: Design the `Scrypath.sync_related/3` entrypoint
- **Objective**: Design the `Scrypath.sync_related/3` entrypoint and underlying capability struct for associating parent-child schemas.
- **Tasks**: Update `Scrypath.Options` to include `fan_outs` and expose the `sync_related/3` delegation function in the `Scrypath` module.

### 89-02: Update core execution runtime
- **Objective**: Update core execution runtime to explicitly accept and validate related-data fan-out intents.
- **Tasks**: Implement resolver logic, telemetry span `[:scrypath, :sync, :related, :resolve]`, and pass documents to target sync.

### 89-03: Establish baseline hermetic tests
- **Objective**: Establish baseline hermetic tests ensuring explicit orchestration overrides auto-magic execution.
- **Tasks**: Test end-to-end flow with `:inline` and `:oban` sync modes in `test/scrypath/sync/related_test.exs`.
