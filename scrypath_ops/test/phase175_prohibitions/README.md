These targets adapt existing ExUnit assertions to GSD’s Node test prohibition producer. They add no dependencies or duplicate behavioral assertions. Prepare the Ops test dependencies/build/database using the normal test environment, and inherit the Elixir/OTP and database settings from your shell. Run the targets serially from the repository root:

```sh
node --test --test-concurrency=1 scrypath_ops/test/phase175_prohibitions/*.test.cjs
```

The plan descriptors supply known-bad and clean JSON subjects for producer checks. Each bad subject modifies only the in-memory LiveView module in a disposable test BEAM. Clean controls compile the current source too. A setup, compilation, missing-test or malformed-report error cannot count as behavioral fail-first evidence. Set `PHASE175_PROHIB_EVIDENCE_DIR` to an external directory to retain raw ExUnit logs.
