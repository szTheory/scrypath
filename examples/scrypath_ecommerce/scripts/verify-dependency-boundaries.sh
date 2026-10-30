#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$#" -ne 1 || "$1" != "--static-contract-only" ]]; then
  echo "Usage: $0 --static-contract-only" >&2
  exit 64
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
default_root="$(cd -- "$script_dir/../../.." && pwd)"
repo_root="${SCRYPATH_DEPENDENCY_BOUNDARY_ROOT:-$default_root}"

dockerfile="$repo_root/examples/scrypath_ecommerce/Dockerfile"
e2e_entrypoint="$repo_root/examples/scrypath_ecommerce/docker-e2e-entrypoint.sh"
standalone_entrypoint="$repo_root/examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh"
host_prod_config="$repo_root/examples/scrypath_ecommerce/config/prod.exs"
host_runtime_config="$repo_root/examples/scrypath_ecommerce/config/runtime.exs"
ops_prod_config="$repo_root/scrypath_ops/config/prod.exs"
ops_runtime_config="$repo_root/scrypath_ops/config/runtime.exs"

fail() {
  printf 'Dependency boundary contract failed: %s\n' "$*" >&2
  exit 1
}

for required_file in \
  "$dockerfile" \
  "$e2e_entrypoint" \
  "$standalone_entrypoint" \
  "$host_prod_config" \
  "$host_runtime_config" \
  "$ops_prod_config" \
  "$ops_runtime_config"; do
  [[ -f "$required_file" ]] || fail "required source is missing: ${required_file#"$repo_root/"}"
done

stage_count() {
  local stage="$1"
  awk -v stage="$stage" '$1 == "FROM" && $NF == stage { count++ } END { print count + 0 }' "$dockerfile"
}

docker_stage() {
  local wanted_stage="$1"
  awk -v stage="$wanted_stage" '
    $1 == "FROM" && $NF == stage { found = 1; active = 1; next }
    active && $1 == "FROM" { active = 0 }
    active { print }
    END { if (!found) exit 1 }
  ' "$dockerfile"
}

stage_contains() {
  local source="$1"
  local expected="$2"
  [[ "$source" == *"$expected"* ]]
}

stage_fixed_count() {
  local stage="$1"
  local expected="$2"
  docker_stage "$stage" | awk -v needle="$expected" 'index($0, needle) { count++ } END { print count + 0 }'
}

builder_scope_has_wrappers() {
  local app_path="$1"
  awk -v app_path="$app_path" '
    $1 == "FROM" && $NF == "asset_builder" { found_stage = 1; active = 1; next }
    active && $1 == "FROM" { active = 0 }
    active {
      if (index($0, "(cd " app_path) > 0) {
        in_scope = 1
        found_scope = 1
      }
      if (in_scope && index($0, "mix assets.setup") > 0) setup = 1
      if (in_scope && index($0, "mix assets.build)") > 0) {
        build = 1
        in_scope = 0
      }
    }
    END { exit !(found_stage && found_scope && setup && build) }
  ' "$dockerfile"
}

for stage in beam_base asset_builder runtime_prod runtime_test; do
  [[ "$(stage_count "$stage")" -eq 1 ]] || fail "Dockerfile must declare stage $stage exactly once"
done

[[ "$(awk '$1 == "FROM" { stage = $NF } END { print stage }' "$dockerfile")" == runtime_test ]] ||
  fail "runtime_test must remain the default final Docker stage"
grep -Fq 'FROM hexpm/elixir:1.19.0-erlang-28.1-debian-bookworm-20260518 AS beam_base' "$dockerfile" ||
  fail "beam_base must retain the supported Elixir/OTP base image"

asset_stage="$(docker_stage asset_builder)" || fail "asset_builder stage is missing"
prod_stage="$(docker_stage runtime_prod)" || fail "runtime_prod stage is missing"
test_stage="$(docker_stage runtime_test)" || fail "runtime_test stage is missing"

stage_contains "$asset_stage" 'ENV MIX_ENV=dev' || fail "asset_builder must use MIX_ENV=dev"
stage_contains "$prod_stage" 'ENV MIX_ENV=prod' || fail "runtime_prod must use MIX_ENV=prod"
stage_contains "$test_stage" 'ENV MIX_ENV=test' || fail "runtime_test must use MIX_ENV=test"

for app_path in /app/scrypath_ops /app/examples/scrypath_ecommerce; do
  builder_scope_has_wrappers "$app_path" || fail "asset_builder must run assets.setup and assets.build inside $app_path"
done

for asset in \
  /app/scrypath_ops/priv/static/assets/js/app.js \
  /app/scrypath_ops/priv/static/assets/css/app.css \
  /app/examples/scrypath_ecommerce/priv/static/assets/js/app.js \
  /app/examples/scrypath_ecommerce/priv/static/assets/css/app.css; do
  [[ "$(stage_fixed_count asset_builder "test -s $asset")" -eq 1 ]] ||
    fail "asset_builder must declare exactly one non-empty output check for $asset"
done

for stage in runtime_test runtime_prod; do
  [[ "$(stage_fixed_count "$stage" 'COPY --from=asset_builder ')" -eq 2 ]] ||
    fail "$stage may copy only the two priv/static trees from asset_builder"

  for copy in \
    'COPY --from=asset_builder /app/scrypath_ops/priv/static /app/scrypath_ops/priv/static' \
    'COPY --from=asset_builder /app/examples/scrypath_ecommerce/priv/static /app/examples/scrypath_ecommerce/priv/static'; do
    stage_contains "$(docker_stage "$stage")" "$copy" || fail "$stage is missing the approved static-only handoff: $copy"
  done

  stage_contains "$(docker_stage "$stage")" 'COPY --exclude=**/config/dev.exs . .' ||
    fail "$stage must exclude development configuration from copied source"
  stage_contains "$(docker_stage "$stage")" 'mix deps.get --check-locked' ||
    fail "$stage must resolve its own locked runtime dependencies"
  stage_contains "$(docker_stage "$stage")" '(cd /app/scrypath_ops && mix deps.get --check-locked)' ||
    fail "$stage must independently resolve the Ops dependency graph"
  stage_contains "$(docker_stage "$stage")" '(cd /app/examples/scrypath_ecommerce && mix deps.get --check-locked)' ||
    fail "$stage must independently resolve the host dependency graph"
  stage_contains "$(docker_stage "$stage")" 'mix compile --warnings-as-errors' ||
    fail "$stage must compile its root application with warnings treated as errors"
  stage_contains "$(docker_stage "$stage")" '(cd /app/scrypath_ops && mix compile --warnings-as-errors)' ||
    fail "$stage must compile Ops in its own runtime environment"
  stage_contains "$(docker_stage "$stage")" '(cd /app/examples/scrypath_ecommerce && mix compile --warnings-as-errors)' ||
    fail "$stage must compile the host in its own runtime environment"
done

stage_contains "$prod_stage" '(cd /app/scrypath_ops && mix phx.digest)' ||
  fail "runtime_prod must digest Ops static output in the production environment"
stage_contains "$prod_stage" '(cd /app/examples/scrypath_ecommerce && mix phx.digest)' ||
  fail "runtime_prod must digest host static output in the production environment"
! stage_contains "$test_stage" 'mix phx.digest' || fail "production digest tasks must not leak into runtime_test"

for config in "$host_prod_config" "$ops_prod_config"; do
  grep -Fq 'cache_static_manifest: "priv/static/cache_manifest.json"' "$config" ||
    fail "production config must name its static digest manifest: ${config#"$repo_root/"}"
done

for runtime_config in "$host_runtime_config" "$ops_runtime_config"; do
  grep -Fq 'DATABASE_URL' "$runtime_config" ||
    fail "production database input must be declared at runtime: ${runtime_config#"$repo_root/"}"
  grep -Fq 'SECRET_KEY_BASE' "$runtime_config" ||
    fail "production signing secret must be declared at runtime: ${runtime_config#"$repo_root/"}"
done
for runtime_input in PGUSER PGPASSWORD PGHOST PGDATABASE; do
  grep -Fq "\"$runtime_input\"" "$host_runtime_config" ||
    fail "host production runtime must read $runtime_input explicitly"
done

for entrypoint in "$e2e_entrypoint" "$standalone_entrypoint"; do
  if grep -En '(^|[[:space:]])mix[[:space:]]+(assets\.(setup|build|deploy)|esbuild(\.install)?|tailwind(\.install)?)([[:space:]]|$)' "$entrypoint"; then
    fail "runtime entrypoint must not install or build asset wrappers: ${entrypoint#"$repo_root/"}"
  fi
done

for asset in \
  /app/scrypath_ops/priv/static/assets/js/app.js \
  /app/scrypath_ops/priv/static/assets/css/app.css \
  /app/examples/scrypath_ecommerce/priv/static/assets/js/app.js \
  /app/examples/scrypath_ecommerce/priv/static/assets/css/app.css; do
  grep -Fq "$asset" "$e2e_entrypoint" || fail "mounted E2E entrypoint must assert prebuilt output: $asset"
done
for asset in priv/static/assets/css/app.css priv/static/assets/js/app.js; do
  grep -Fq "$asset" "$standalone_entrypoint" || fail "standalone entrypoint must assert prebuilt output: $asset"
done

printf 'Static dependency boundary contract passed (4 current-source assets, output-only handoff, clean runtime entrypoints).\n'
