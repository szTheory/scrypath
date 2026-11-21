#!/usr/bin/env bash
# Cheap pre-push subset of the required CI lanes. Run it from a committed tree, before `git push`:
#
#   export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5   # if asdf manages your toolchain
#   scripts/ci/pre_push.sh
#
# Every step is a check CI already runs; nothing new is invented here. It takes about a minute with a
# warm build and covers the checks that fail most often for the cheapest price: workflow lint, format,
# warning-free compile, Credo, workspace cleanliness, the workflow wiring and namespace-fence tests,
# and the Node tests for the path classifiers, the BEAM cache planner, the UI tokens and the state pairs.
#
# It does NOT replace the hosted gate. It cannot run `mix verify.core` (about 7 minutes),
# `mix verify.repository_contracts` (about 6 minutes), `mix verify.backend` (needs Meilisearch and
# Postgres services), `mix verify.package`, `ops-ui`, or the Docker `ecommerce-mounted` lane. See the
# "Local-first checklist" in .planning/reference/CI-EFFICIENCY.md for the full lane-by-lane map and
# what each local mirror cannot cover. A step whose tool is missing is reported as SKIPPED, never as
# passed, and the script then exits 2 so a skip is not mistaken for a green run.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 2

failed=()
skipped=()
passed=()

# step <label> <command...>: runs the command, records pass or fail, keeps going.
step() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  if "$@"; then
    passed+=("$label")
  else
    failed+=("$label")
  fi
}

skip() {
  printf '\n==> %s\n    SKIPPED: %s\n' "$1" "$2"
  skipped+=("$1 ($2)")
}

if command -v actionlint >/dev/null 2>&1; then
  step "actionlint on every workflow" actionlint .github/workflows/*.yml
else
  skip "actionlint on every workflow" "actionlint is not installed (brew install actionlint)"
fi

step "mix format --check-formatted" mix format --check-formatted
step "mix compile --warnings-as-errors" env MIX_ENV=test mix compile --warnings-as-errors
step "mix credo --strict" env MIX_ENV=test mix credo --strict
step "mix verify.workspace_clean" env MIX_ENV=test mix verify.workspace_clean
step "workflow wiring and namespace fence tests" env MIX_ENV=test mix test --warnings-as-errors \
  test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_namespace_fence_test.exs
step "path classifier and BEAM cache node tests" node --test \
  scripts/ci/ecommerce_path_classifier.test.cjs scripts/ci/compat_path_classifier.test.cjs \
  scripts/ci/beam_cache.test.cjs

if [ -d examples/scrypath_ecommerce/node_modules/pngjs ]; then
  step "UI token and state pair node tests" node --test \
    examples/scrypath_ecommerce/ui-tokens.test.mjs scripts/ci/ui_state_pairs.test.cjs
else
  skip "UI token and state pair node tests" \
    "run: PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --ignore-scripts --prefix examples/scrypath_ecommerce"
fi

printf '\n==== pre-push summary ====\n'
printf 'passed:  %d\n' "${#passed[@]}"
for label in "${skipped[@]+"${skipped[@]}"}"; do printf 'SKIPPED: %s\n' "$label"; done
for label in "${failed[@]+"${failed[@]}"}"; do printf 'FAILED:  %s\n' "$label"; done
printf 'Not run here (hosted CI is the gate): core, package, repository-contracts, backend, ops-ui, ecommerce-mounted.\n'

if [ "${#failed[@]}" -gt 0 ]; then exit 1; fi
if [ "${#skipped[@]}" -gt 0 ]; then exit 2; fi
exit 0
