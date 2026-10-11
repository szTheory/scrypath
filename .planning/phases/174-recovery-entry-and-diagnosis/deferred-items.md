# Deferred Items

- `make -C examples/scrypath_ecommerce verify-mounted` ran the updated operator journey successfully, but the unrelated `e2e/harness.spec.ts` showcase check failed because `getByRole("heading", { name: "Search" })` also matches “Run a search to see results.” Fix belongs to the existing harness assertion owner.
- `scrypath_ops/mix precommit` ran 250 tests and 2 doctests but failed 2 unrelated existing `SyncDriftLiveTest` teardown cases (`GenServer.stop` on an already stopped process); this plan does not own Sync and drift.
