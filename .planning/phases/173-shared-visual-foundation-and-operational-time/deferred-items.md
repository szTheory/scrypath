# Phase 173 deferred items

## Existing Ops shell contract failures

Observed while running the Task 1 contract after the retained theme-label test passed:

- `OpsShellContractTest` test `flash component exposes durable passive alert chrome` expects the info flash to use `role="alert"`; the current info flash renders `role="status"`.
- `OpsShellContractTest` test `standalone and mounted LiveSockets share all operator hooks` expects an older three-hook import string; the current bundle imports `OpsRefreshButton` and `OpsToast` too.

These failures are unrelated to the theme preference and shell palette changes. The Task 1 test passes in isolation. Keep these stale assertions out of this plan's implementation scope; reconcile them in the test-owning follow-up.

**Observed command:** `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs`
