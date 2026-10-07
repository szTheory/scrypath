# Deferred Items

- Pre-existing warning in `lib/scrypath/sync.ex:61`: Dialyzer reports incompatible types in `Scrypath.Sync.sync_related/3` around `decorate_result/2`. It is outside Phase 174-01's changed source and did not block focused verification.
- Existing Ops precommit flake outside Plan 174-04: `ScrypathOpsWeb.SyncDriftLiveTest` test "recovery failure arriving after its selected schema is removed clears pending status" fails in the complete suite because its `on_exit` callback attempts to stop a linked Agent that already exited with the test process. The single test passes in isolation; no Plan 174-04 files participate in this fixture. Defer repair to the Sync and drift test owner.
