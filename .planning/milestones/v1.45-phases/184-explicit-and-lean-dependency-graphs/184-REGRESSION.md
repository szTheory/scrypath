# Phase 184 — Prior-phase regression gate

Prior milestone verification records for Phases 182 and 183 supplied the executable regression scope. Twenty ExUnit files and six Node test files were retained; two helper modules were excluded as non-test inputs. Existing CONTRIBUTING commands were used explicitly because the generic workflow fallback does not detect Mix; no `true` or unexecuted fallback is claimed.

At source `779c13312de1f2a774d39ad6928aac60d2eecfac`, the scoped ExUnit command ran one-shot with warnings as errors, integration excluded and docs contracts included, under `gsd-tools run-with-timeout 600`. It exited 0 with 257 tests and no failures. `node --test scripts/ci/*.test.cjs` separately exited 0 with all 127 checks passing and no skips. No watch mode or timeout occurred. The full current package/backend/mounted/compatibility/browser proof additionally passed in hosted run 41153254156.

Exact executable command, scope, result and raw log are external in `/private/tmp/scrypath-phase184-execution/regression-current-result.json`, `regression-root-current.log` and `candidate-repair-node.log`. Source/helper discovery remains in `regression-evidence.json`; current executable-only scope follows.

- `test/mix/tasks/verify.phase106_test.exs`
- `test/mix/tasks/verify.phase107_test.exs`
- `test/mix/tasks/verify.phase108_test.exs`
- `test/mix/tasks/verify.phase112_test.exs`
- `test/mix/tasks/verify.phase97_test.exs`
- `test/mix/tasks/verify.phase98_test.exs`
- `test/mix/tasks/verify.phase99_test.exs`
- `test/mix/tasks/verify_adopter_test.exs`
- `test/mix/tasks/verify_capability_test.exs`
- `test/mix/tasks/verify_namespace_fence_test.exs`
- `test/mix/tasks/verify_phoenix_example_package_test.exs`
- `test/mix/tasks/verify_workspace_clean_test.exs`
- `test/mix/tasks/workflow_wiring_test.exs`
- `test/release/consumer_smoke_test.exs`
- `test/release/package_contents_test.exs`
- `test/release/package_metadata_test.exs`
- `test/scrypath/docs_contract_test.exs`
- `test/scrypath/phase108_contract_test.exs`
- `test/scrypath/phase111_contract_test.exs`
- `test/scrypath/phase99_contract_test.exs`
- `scripts/ci/beam_cache.test.cjs`
- `scripts/ci/ecommerce_build.test.cjs`
- `scripts/ci/ecommerce_evidence.test.cjs`
- `scripts/ci/ecommerce_lifecycle.test.cjs`
- `scripts/ci/ecommerce_target.test.cjs`
- `scripts/ci/phase182_acceptance.test.cjs`
