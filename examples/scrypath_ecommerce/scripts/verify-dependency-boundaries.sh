#!/usr/bin/env bash

set -Eeuo pipefail

mode="${1:-}"
if [[ "$#" -ne 1 || ( "$mode" != "--static-contract-only" && "$mode" != "--runtime" ) ]]; then
  echo "Usage: $0 --static-contract-only | --runtime" >&2
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

if [[ "$mode" == "--runtime" ]]; then
  command -v docker >/dev/null 2>&1 || fail "Docker CLI is required for --runtime"
  command -v curl >/dev/null 2>&1 || fail "curl is required for --runtime"
  command -v node >/dev/null 2>&1 || fail "Node.js is required for source identity checks"
  docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is required for --runtime"
  docker info >/dev/null 2>&1 || fail "Docker engine is unavailable for --runtime"

  helper="$repo_root/scripts/ci/ecommerce_build.cjs"
  [[ -f "$helper" ]] || fail "source identity helper is missing: scripts/ci/ecommerce_build.cjs"

  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  run_id="${timestamp}-$$-${RANDOM}${RANDOM}"
  safe_run_id="$(printf '%s' "$run_id" | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')"
  project_prefix="scrypath_dependency_boundary_${safe_run_id}"
  preview_project="${E2E_PROJECT_NAME:-}"
  [[ "$project_prefix" != "$preview_project" && "$project_prefix" != "scrypath_ecommerce" ]] ||
    fail "runtime proof project name must be unique and separate from the retained preview"

  artifact_parent="${SCRYPATH_DEPENDENCY_BOUNDARY_ARTIFACT_DIR:-${TMPDIR:-/tmp}}"
  mkdir -p "$artifact_parent"
  artifact_parent="$(cd "$artifact_parent" && pwd -P)"
  case "$artifact_parent/" in
    "$repo_root/"*) fail "runtime receipts must be outside the repository checkout" ;;
  esac
  artifact_dir="$(mktemp -d "$artifact_parent/scrypath-dependency-boundary-${safe_run_id}.XXXXXX")"
  compose_file=""
  builder_container=""
  runtime_projects=()
  runtime_compose_files=()
  runtime_images=()
  runtime_image_ids=()
  runtime_envs=()
  runtime_host_ports=()
  runtime_cleanup_status=0

  sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$1" | awk '{print $1}'
    else
      shasum -a 256 "$1" | awk '{print $1}'
    fi
  }

  sha256_text() {
    if command -v sha256sum >/dev/null 2>&1; then
      printf '%s' "$1" | sha256sum | awk '{print $1}'
    else
      printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
    fi
  }

  write_receipt() {
    local final_status="$1"
    DEPENDENCY_BOUNDARY_RECEIPT="$artifact_dir/runtime-receipt.json" \
    DEPENDENCY_BOUNDARY_STATUS="$final_status" \
    DEPENDENCY_BOUNDARY_RUN_ID="$run_id" \
    DEPENDENCY_BOUNDARY_PROJECT="$project_prefix" \
    DEPENDENCY_BOUNDARY_SOURCE_SHA="$source_sha" \
    DEPENDENCY_BOUNDARY_SOURCE_FINGERPRINT="$source_fingerprint" \
    DEPENDENCY_BOUNDARY_RECIPE_SHA="$recipe_sha" \
    DEPENDENCY_BOUNDARY_BUILDER_IMAGE="$builder_image" \
    DEPENDENCY_BOUNDARY_TEST_IMAGE="$test_image" \
    DEPENDENCY_BOUNDARY_PROD_IMAGE="$prod_image" \
    DEPENDENCY_BOUNDARY_IMAGES="${runtime_image_ids[*]}" \
    DEPENDENCY_BOUNDARY_ENVS="${runtime_envs[*]}" \
    DEPENDENCY_BOUNDARY_PORTS="${runtime_host_ports[*]}" \
    DEPENDENCY_BOUNDARY_CLEANUP_STATUS="$runtime_cleanup_status" \
      node - "$artifact_dir/runtime-receipt.json" <<'NODE'
const fs = require("node:fs");
const path = process.argv[2];
const split = (value) => value ? value.trim().split(/\s+/) : [];
const receipt = {
  schema_version: 1,
  status: process.env.DEPENDENCY_BOUNDARY_STATUS,
  run_id: process.env.DEPENDENCY_BOUNDARY_RUN_ID,
  project_prefix: process.env.DEPENDENCY_BOUNDARY_PROJECT,
  checkout_sha: process.env.DEPENDENCY_BOUNDARY_SOURCE_SHA,
  source_fingerprint: process.env.DEPENDENCY_BOUNDARY_SOURCE_FINGERPRINT,
  dockerfile_sha256: process.env.DEPENDENCY_BOUNDARY_RECIPE_SHA,
  images: {
    asset_builder: process.env.DEPENDENCY_BOUNDARY_BUILDER_IMAGE,
    runtime_test: process.env.DEPENDENCY_BOUNDARY_TEST_IMAGE,
    runtime_prod: process.env.DEPENDENCY_BOUNDARY_PROD_IMAGE,
    immutable_ids: split(process.env.DEPENDENCY_BOUNDARY_IMAGES),
  },
  runtime: {
    environments: split(process.env.DEPENDENCY_BOUNDARY_ENVS),
    loopback_ports: split(process.env.DEPENDENCY_BOUNDARY_PORTS).map(Number),
  },
  cleanup_status: Number(process.env.DEPENDENCY_BOUNDARY_CLEANUP_STATUS),
};
fs.writeFileSync(path, `${JSON.stringify(receipt, null, 2)}\n`);
NODE
  }

  cleanup_runtime_proof() {
    local original_status="$?"
    local index project file leftover status=0 tag
    trap - EXIT
    set +e

    if [[ -n "$builder_container" ]]; then
      docker rm -f "$builder_container" >/dev/null 2>&1 || status=1
    fi

    for index in "${!runtime_projects[@]}"; do
      project="${runtime_projects[$index]}"
      file="${runtime_compose_files[$index]}"
      docker compose -p "$project" -f "$file" down --volumes --remove-orphans --timeout 10 \
        >>"$artifact_dir/cleanup.log" 2>&1 || status=1

      for resource in containers networks volumes; do
        case "$resource" in
          containers) leftover="$(docker ps -aq --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/cleanup.log")" ;;
          networks) leftover="$(docker network ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/cleanup.log")" ;;
          volumes) leftover="$(docker volume ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/cleanup.log")" ;;
        esac
        if [[ -n "$leftover" ]]; then
          printf 'Runtime proof left owned %s for %s: %s\n' "$resource" "$project" "$leftover" >&2
          status=1
        fi
      done
    done

    for tag in "${runtime_images[@]}"; do
      docker image rm -f "$tag" >>"$artifact_dir/cleanup.log" 2>&1 || status=1
    done

    runtime_cleanup_status="$status"
    if (( original_status == 0 && status != 0 )); then original_status=75; fi
    write_receipt "$([[ "$original_status" == "0" ]] && printf passed || printf failed)"
    printf 'DEPENDENCY_BOUNDARY case=cleanup status=%s artifacts=%s\n' \
      "$([[ "$status" == "0" ]] && printf passed || printf failed)" "$artifact_dir"
    exit "$original_status"
  }

  source_sha="$(git -C "$repo_root" rev-parse HEAD)"
  source_fingerprint="$(node "$helper" fingerprint)"
  recipe_sha="$(sha256_file "$dockerfile")"
  root_lock_sha="$(sha256_file "$repo_root/mix.lock")"
  ops_lock_sha="$(sha256_file "$repo_root/scrypath_ops/mix.lock")"
  host_lock_sha="$(sha256_file "$repo_root/examples/scrypath_ecommerce/mix.lock")"
  label_args=(
    --label "org.opencontainers.image.revision=$source_sha"
    --label "org.opencontainers.image.source-fingerprint=$source_fingerprint"
    --label "org.scrypath.dependency-boundary.recipe-sha256=$recipe_sha"
  )
  builder_image="${project_prefix}:asset-builder"
  test_image="${project_prefix}:runtime-test"
  prod_image="${project_prefix}:runtime-prod"

  trap cleanup_runtime_proof EXIT
  printf 'DEPENDENCY_BOUNDARY case=source run=%s sha=%s fingerprint=%s dockerfile=%s artifacts=%s\n' \
    "$run_id" "$source_sha" "$source_fingerprint" "$recipe_sha" "$artifact_dir"
  printf 'DEPENDENCY_BOUNDARY case=build target=asset_builder mode=cache\n'
  if ! docker build --file "$dockerfile" --target asset_builder "${label_args[@]}" -t "$builder_image" "$repo_root" \
    >"$artifact_dir/build-asset-builder.log" 2>&1; then
    tail -n 100 "$artifact_dir/build-asset-builder.log" >&2
    fail "asset_builder image build failed; log: $artifact_dir/build-asset-builder.log"
  fi
  runtime_images+=("$builder_image")

  test_build_cache_args=()
  # Keep the acceptance path cold by default; local retries may reuse verified BuildKit layers.
  if [[ "${SCRYPATH_DEPENDENCY_BOUNDARY_COLD:-1}" != "0" ]]; then
    test_build_cache_args+=(--no-cache)
  fi
  test_build_mode="cold"
  [[ "${SCRYPATH_DEPENDENCY_BOUNDARY_COLD:-1}" == "0" ]] && test_build_mode="cached"
  printf 'DEPENDENCY_BOUNDARY case=build target=runtime_test mode=%s\n' "$test_build_mode"
  if ! docker build "${test_build_cache_args[@]}" --file "$dockerfile" --target runtime_test "${label_args[@]}" -t "$test_image" "$repo_root" \
    >"$artifact_dir/build-runtime-test.log" 2>&1; then
    tail -n 100 "$artifact_dir/build-runtime-test.log" >&2
    fail "runtime_test image build failed; log: $artifact_dir/build-runtime-test.log"
  fi
  runtime_images+=("$test_image")

  printf 'DEPENDENCY_BOUNDARY case=build target=runtime_prod mode=independent\n'
  if ! docker build --file "$dockerfile" --target runtime_prod "${label_args[@]}" -t "$prod_image" "$repo_root" \
    >"$artifact_dir/build-runtime-prod.log" 2>&1; then
    tail -n 100 "$artifact_dir/build-runtime-prod.log" >&2
    fail "runtime_prod image build failed; log: $artifact_dir/build-runtime-prod.log"
  fi
  runtime_images+=("$prod_image")

  for image in "$builder_image" "$test_image" "$prod_image"; do
    source_label="$(docker image inspect --format='{{ index .Config.Labels "org.opencontainers.image.revision" }}' "$image")"
    fingerprint_label="$(docker image inspect --format='{{ index .Config.Labels "org.opencontainers.image.source-fingerprint" }}' "$image")"
    recipe_label="$(docker image inspect --format='{{ index .Config.Labels "org.scrypath.dependency-boundary.recipe-sha256" }}' "$image")"
    [[ "$source_label" == "$source_sha" ]] || fail "$image source SHA label does not match this checkout"
    [[ "$fingerprint_label" == "$source_fingerprint" ]] || fail "$image fingerprint label does not match this checkout"
    [[ "$recipe_label" == "$recipe_sha" ]] || fail "$image recipe label does not match the Dockerfile"
  done

  builder_container="$(docker create "$builder_image")"
  for asset in \
    "scrypath_ops/priv/static/assets/js/app.js" \
    "scrypath_ops/priv/static/assets/css/app.css" \
    "examples/scrypath_ecommerce/priv/static/assets/js/app.js" \
    "examples/scrypath_ecommerce/priv/static/assets/css/app.css"; do
    source="/app/$asset"
    destination="$artifact_dir/builder/$asset"
    mkdir -p "$(dirname "$destination")"
    docker cp "$builder_container:$source" "$destination" >/dev/null
    [[ -s "$destination" ]] || fail "asset_builder produced an empty asset: $asset"
    printf '%s %s\n' "$(sha256_file "$destination")" "$asset" >>"$artifact_dir/builder-assets.sha256"
  done
  docker rm "$builder_container" >/dev/null
  builder_container=""

  write_target_asset_set() {
    local image="$1" environment="$2" container asset source destination
    container="$(docker create "$image")"
    for asset in \
      "scrypath_ops/priv/static/assets/js/app.js" \
      "scrypath_ops/priv/static/assets/css/app.css" \
      "examples/scrypath_ecommerce/priv/static/assets/js/app.js" \
      "examples/scrypath_ecommerce/priv/static/assets/css/app.css"; do
      source="/app/$asset"
      destination="$artifact_dir/targets/$environment/$asset"
      mkdir -p "$(dirname "$destination")"
      docker cp "$container:$source" "$destination" >/dev/null
      [[ -s "$destination" ]] || fail "$image contains an empty static output: $asset"
      printf '%s %s\n' "$(sha256_file "$destination")" "$asset" >>"$artifact_dir/targets/$environment/assets.sha256"
    done
    docker rm "$container" >/dev/null
  }

  write_target_asset_set "$test_image" test
  write_target_asset_set "$prod_image" prod
  diff -u "$artifact_dir/builder-assets.sha256" "$artifact_dir/targets/test/assets.sha256" ||
    fail "runtime_test static output differs from asset_builder output"
  diff -u "$artifact_dir/builder-assets.sha256" "$artifact_dir/targets/prod/assets.sha256" ||
    fail "runtime_prod static output differs from asset_builder output"

  for environment in test prod; do
    if [[ "$environment" == "test" ]]; then
      image="$test_image"
      port=4002
      ops_port=4003
      database="scrypath_ecommerce_test"
      database_password="postgres"
      database_url=""
      secret="$(printf '%064d' 1)"
      ops_database="scrypath_ops_${safe_run_id}_test"
      ops_database_url=""
      ops_command="exec /bin/sh /app/examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh"
    else
      image="$prod_image"
      port=4000
      ops_port=4003
      database="scrypath_ecommerce_prod"
      database_password="scrypath-boundary-pass"
      database_url="ecto://postgres:$database_password@postgres:5432/$database"
      secret="$(printf '%064d' 2)"
      ops_database="scrypath_ops_${safe_run_id}_prod"
      ops_database_url="ecto://postgres:$database_password@postgres:5432/$ops_database"
      ops_command="cd /app/scrypath_ops && mix ecto.create --quiet && mix ecto.migrate --quiet && exec env PHX_SERVER=true PORT=$ops_port MIX_ENV=prod mix run --no-start -e 'Application.put_env(:scrypath_ops, :standalone, true); {:ok, _} = Application.ensure_all_started(:scrypath_ops); Process.sleep(:infinity)'"
    fi

    project="${project_prefix}_${environment}"
    [[ "$project" != "${preview_project:-}" && "$project" != "scrypath_ecommerce" ]] ||
      fail "refusing to use retained preview Compose project '$project'"
    compose_file="$artifact_dir/compose-$environment.yaml"
    cat >"$compose_file" <<COMPOSE
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: $database_password
      POSTGRES_DB: $database
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 2s
      timeout: 2s
      retries: 40
  meilisearch:
    image: getmeili/meilisearch:v1.15
    environment:
      MEILI_NO_ANALYTICS: "true"
    healthcheck:
      test: ["CMD", "curl", "--silent", "--fail", "http://127.0.0.1:7700/health"]
      interval: 2s
      timeout: 2s
      retries: 40
  web:
    image: $image
    environment:
      MIX_ENV: $environment
      PHX_SERVER: "true"
      PORT: "$port"
      PGHOST: postgres
      PGPORT: "5432"
      PGUSER: postgres
      PGPASSWORD: $database_password
      PGDATABASE: $database
      DATABASE_URL: "$database_url"
      SECRET_KEY_BASE: "$secret"
      POOL_SIZE: "4"
      OPSUI_AUTH_MODE: basic
      DEMO_SEED_ON_START: "0"
      SCRYPATH_E2E_NO_SANDBOX: "1"
      SCRYPATH_MEILISEARCH_URL: http://meilisearch:7700
    ports:
      - "127.0.0.1::$port"
    depends_on:
      postgres:
        condition: service_healthy
      meilisearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "--silent", "--fail", "http://127.0.0.1:$port/"]
      interval: 3s
      timeout: 5s
      start_period: 5m
      retries: 60
  ops:
    image: $image
    command: ["/bin/sh", "-lc", "$ops_command"]
    environment:
      MIX_ENV: "$environment"
      PHX_SERVER: "true"
      PORT: "$ops_port"
      SCRYPATH_OPS_PORT: "$ops_port"
      SCRYPATH_OPS_TEST_DATABASE: "$ops_database"
      PGHOST: postgres
      PGPORT: "5432"
      PGUSER: postgres
      PGPASSWORD: $database_password
      PGDATABASE: "$ops_database"
      DATABASE_URL: "$ops_database_url"
      SECRET_KEY_BASE: "$secret"
      POOL_SIZE: "4"
      OPSUI_AUTH_MODE: basic
      SCRYPATH_MEILISEARCH_URL: http://meilisearch:7700
    ports:
      - "127.0.0.1::$ops_port"
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "--silent", "--fail", "http://127.0.0.1:$ops_port/ops/health"]
      interval: 3s
      timeout: 5s
      start_period: 5m
      retries: 60
COMPOSE
    runtime_projects+=("$project")
    runtime_compose_files+=("$compose_file")

    docker compose -p "$project" -f "$compose_file" config --quiet ||
      fail "$environment runtime Compose configuration is invalid"
    model_config="$(docker compose -p "$project" -f "$compose_file" config)"
    model_sha="$(sha256_text "$model_config")"
    image_id="$(docker image inspect --format='{{.Id}}' "$image")"
    docker compose -p "$project" -f "$compose_file" up -d --wait --wait-timeout 600 \
      >"$artifact_dir/compose-$environment-up.log" 2>&1 || {
        tail -n 100 "$artifact_dir/compose-$environment-up.log" >&2
        docker compose -p "$project" -f "$compose_file" logs --no-color --tail 160 \
          >"$artifact_dir/compose-$environment-services.log" 2>&1 || true
        cat "$artifact_dir/compose-$environment-services.log" >&2
        fail "$environment runtime target did not start; see $artifact_dir/compose-$environment-up.log"
      }

    container_id="$(docker compose -p "$project" -f "$compose_file" ps -q web)"
    [[ -n "$container_id" ]] || fail "$environment runtime target has no running web container"
    [[ "$(docker inspect --format='{{.Image}}' "$container_id")" == "$image_id" ]] ||
      fail "$environment web container image ID differs from the built target"
    actual_mix_env="$(docker compose -p "$project" -f "$compose_file" exec -T web sh -lc 'printf %s "$MIX_ENV"')"
    [[ "$actual_mix_env" == "$environment" ]] || fail "$environment target is running MIX_ENV=$actual_mix_env"

    runtime_envs+=("$environment")
    runtime_image_ids+=("$image_id")

    ops_container_id="$(docker compose -p "$project" -f "$compose_file" ps -q ops)"
    [[ -n "$ops_container_id" ]] || fail "$environment target has no running standalone Ops container"
    [[ "$(docker inspect --format='{{.Image}}' "$ops_container_id")" == "$image_id" ]] ||
      fail "$environment standalone Ops container image ID differs from the built target"

    for lock in \
      "/app/mix.lock:$root_lock_sha" \
      "/app/scrypath_ops/mix.lock:$ops_lock_sha" \
      "/app/examples/scrypath_ecommerce/mix.lock:$host_lock_sha"; do
      lock_path="${lock%%:*}"
      expected_lock="${lock#*:}"
      actual_lock="$(docker compose -p "$project" -f "$compose_file" exec -T web sh -lc "sha256sum '$lock_path' | awk '{print \$1}'")"
      [[ "$actual_lock" == "$expected_lock" ]] || fail "$environment image lock identity differs at $lock_path"
    done

    docker compose -p "$project" -f "$compose_file" exec -T web sh -lc '
      set -eu
      for root in /app /app/scrypath_ops /app/examples/scrypath_ecommerce; do
        test ! -e "$root/_build/dev" || { echo "builder _build/dev leaked into $root" >&2; exit 1; }
        test ! -e "$root/config/dev.exs" || { echo "development config leaked into $root" >&2; exit 1; }
      done
      for dependency in \
        "/app/scrypath_ops/_build/$MIX_ENV/lib/esbuild" \
        "/app/scrypath_ops/_build/$MIX_ENV/lib/tailwind" \
        "/app/examples/scrypath_ecommerce/_build/$MIX_ENV/lib/esbuild" \
        "/app/examples/scrypath_ecommerce/_build/$MIX_ENV/lib/tailwind"; do
        test ! -e "$dependency" || { echo "asset wrapper was compiled into the runtime graph: $dependency" >&2; exit 1; }
      done
    ' || fail "$environment target contains a builder dependency, dev build, or dev config"

    for project_dir in /app/scrypath_ops /app/examples/scrypath_ecommerce; do
      deps_output="$(docker compose -p "$project" -f "$compose_file" exec -T web sh -lc "cd '$project_dir' && MIX_ENV='$environment' mix deps")"
      for forbidden_dep in esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller; do
        if printf '%s\n' "$deps_output" | grep -Eq "^[*] $forbidden_dep[[:space:]]"; then
          fail "$environment dependency graph in $project_dir includes forbidden $forbidden_dep"
        fi
      done
      printf '%s\n' "$deps_output" >"$artifact_dir/targets/$environment/$(basename "$project_dir")-deps.txt"
    done

    probe="$artifact_dir/runtime-probe.exs"
    cat >"$probe" <<'ELIXIR'
environment = System.fetch_env!("MIX_ENV")
for {app, label} <- [{:scrypath_ops, "ops"}, {:scrypath_ecommerce, "host"}] do
  case Application.load(app) do
    :ok -> :ok
    {:error, {:already_loaded, ^app}} -> :ok
    other -> raise "#{label} app metadata could not load: #{inspect(other)}"
  end

  applications = Application.spec(app, :applications) || []
  optional = Application.spec(app, :optional_applications) || []
  forbidden = [:esbuild, :tailwind, :phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller]
  leaked = Enum.filter(forbidden, &(&1 in applications or &1 in optional))
  leaked == [] || raise "#{label} .app requirements include builder/diagnostic apps: #{inspect(leaked)}"

  module = if app == :scrypath_ops, do: ScrypathOps.Application, else: ScrypathEcommerce.Application
  Code.ensure_loaded!(module)
  code_path = module |> :code.which() |> to_string()
  String.contains?(code_path, "_build/#{environment}/lib/") ||
    raise "#{label} module resolved outside the #{environment} build: #{code_path}"

  IO.puts("DEPENDENCY_BOUNDARY_APP label=#{label} env=#{environment} required=#{inspect(applications)} optional=#{inspect(optional)} code=#{code_path}")
end

forbidden_modules = [Esbuild, Tailwind, Phoenix.LiveDashboard, Phoenix.LiveDashboard.RequestLogger, Telemetry.Metrics, :telemetry_poller]
loaded = Enum.filter(forbidden_modules, &Code.ensure_loaded?/1)
loaded == [] || raise "runtime loaded builder/diagnostic modules: #{inspect(loaded)}"

started = Application.started_applications() |> Enum.map(&elem(&1, 0))
IO.puts("DEPENDENCY_BOUNDARY_STARTED env=#{environment} apps=#{inspect(started)}")
if environment == "test" do
  sandbox = Application.get_env(:scrypath_ecommerce, :sandbox)
  IO.puts("DEPENDENCY_BOUNDARY_SANDBOX env=test value=#{inspect(sandbox)}")
end
IO.puts("DEPENDENCY_BOUNDARY_APP_PROBE result=passed")
ELIXIR
    host_probe="$artifact_dir/probe-$environment.exs"
    cp "$probe" "$host_probe"
    docker compose -p "$project" -f "$compose_file" cp "$host_probe" "web:/tmp/dependency-boundary-probe.exs" >/dev/null
    docker compose -p "$project" -f "$compose_file" exec -T web sh -lc \
      "cd /app/examples/scrypath_ecommerce && PHX_SERVER=false MIX_ENV='$environment' mix run /tmp/dependency-boundary-probe.exs" \
      >"$artifact_dir/targets/$environment/app-probe.log" 2>&1 || {
        cat "$artifact_dir/targets/$environment/app-probe.log" >&2
        fail "$environment app metadata probe failed"
      }
    grep -Fq "DEPENDENCY_BOUNDARY_APP_PROBE result=passed" "$artifact_dir/targets/$environment/app-probe.log" ||
      fail "$environment app probe omitted its completion marker"
    if [[ "$environment" == "test" ]]; then
      grep -Fq 'DEPENDENCY_BOUNDARY_SANDBOX env=test value=false' "$artifact_dir/targets/$environment/app-probe.log" ||
        fail "test runtime target did not disable the SQL sandbox for standalone HTTP asset requests"
    fi

    port_line="$(docker compose -p "$project" -f "$compose_file" port web "$port")"
    host_port="${port_line##*:}"
    [[ "$host_port" =~ ^[0-9]+$ ]] || fail "$environment target did not receive a random loopback port: $port_line"
    [[ "$host_port" != "4000" && "$host_port" != "4002" ]] ||
      fail "$environment runtime proof collided with a retained-preview port"
    runtime_host_ports+=("$host_port")
    base_url="http://127.0.0.1:$host_port"
    curl --silent --show-error --fail --max-time 30 "$base_url/" -o "$artifact_dir/targets/$environment/storefront.html" ||
      fail "$environment storefront route did not return successfully"
    curl --silent --show-error --fail --location --max-time 30 "$base_url/admin/search/health" \
      -o "$artifact_dir/targets/$environment/ops-health.html" ||
      fail "$environment mounted Ops health route did not return successfully"

    check_served_asset() {
      local path="$1" expected="$2" content_kind="$3" name response headers actual url
      name="$(printf '%s' "$path" | sed -E 's#^https?://##; s#[^[:alnum:]_.-]+#_#g')"
      response="$artifact_dir/targets/$environment/served-$name"
      headers="$artifact_dir/targets/$environment/headers-$name"
      if [[ "$path" == http://* || "$path" == https://* ]]; then
        url="$path"
      else
        url="$base_url$path"
      fi
      local status
      status="$(curl --silent --show-error --location --compressed --max-time 30 \
        --dump-header "$headers" --output "$response" --write-out '%{http_code}' \
        "$url")" || fail "$environment request failed before receiving $path"
      if [[ "$status" != "200" ]]; then
        docker compose -p "$project" -f "$compose_file" logs --no-color --tail 100 web \
          >"$artifact_dir/targets/$environment/web-logs-$name.log" 2>&1 || true
        printf 'Dependency boundary HTTP response: environment=%s status=%s path=%s body=' \
          "$environment" "$status" "$path" >&2
        head -c 500 "$response" >&2 || true
        printf '\n' >&2
        fail "$environment did not serve $path (HTTP $status); headers: $headers"
      fi
      cmp -s "$expected" "$response" || fail "$environment served bytes differ from built output at $path"
      actual="$(sha256_file "$response")"
      [[ "$actual" == "$(sha256_file "$expected")" ]] || fail "$environment response digest differs at $path"
      tr '[:upper:]' '[:lower:]' <"$headers" | grep -Fq "content-type:" ||
        fail "$environment response omitted Content-Type at $path"
      tr '[:upper:]' '[:lower:]' <"$headers" | grep -F "content-type:" | grep -Fq "$content_kind" ||
        fail "$environment response has the wrong Content-Type at $path"
      printf 'DEPENDENCY_BOUNDARY_ASSET env=%s path=%s sha256=%s content_type=%s status=passed\n' \
        "$environment" "$path" "$actual" "$content_kind"
    }

    check_served_asset "/assets/js/app.js" \
      "$artifact_dir/targets/$environment/examples/scrypath_ecommerce/priv/static/assets/js/app.js" javascript
    check_served_asset "/assets/css/app.css" \
      "$artifact_dir/targets/$environment/examples/scrypath_ecommerce/priv/static/assets/css/app.css" text/css
    ops_port_line="$(docker compose -p "$project" -f "$compose_file" port ops "$ops_port")"
    ops_host_port="${ops_port_line##*:}"
    [[ "$ops_host_port" =~ ^[0-9]+$ ]] || fail "$environment standalone Ops target did not receive a random loopback port: $ops_port_line"
    [[ "$ops_host_port" != "4000" && "$ops_host_port" != "4002" ]] ||
      fail "$environment standalone Ops proof collided with a retained-preview port"
    runtime_host_ports+=("$ops_host_port")
    ops_base_url="http://127.0.0.1:$ops_host_port"
    curl --silent --show-error --fail --location --max-time 30 "$ops_base_url/ops/health" \
      -o "$artifact_dir/targets/$environment/ops-health.html" ||
      fail "$environment standalone Ops health route did not return successfully"
    grep -Fq 'href="/assets/css/app.css' "$artifact_dir/targets/$environment/ops-health.html" ||
      fail "$environment standalone Ops page omitted its built CSS route"
    grep -Fq 'src="/assets/js/app.js' "$artifact_dir/targets/$environment/ops-health.html" ||
      fail "$environment standalone Ops page omitted its built JS route"
    check_served_asset "$ops_base_url/assets/js/app.js?v=$(sha256_file "$artifact_dir/targets/$environment/scrypath_ops/priv/static/assets/js/app.js")" \
      "$artifact_dir/targets/$environment/scrypath_ops/priv/static/assets/js/app.js" javascript
    check_served_asset "$ops_base_url/assets/css/app.css?v=$(sha256_file "$artifact_dir/targets/$environment/scrypath_ops/priv/static/assets/css/app.css")" \
      "$artifact_dir/targets/$environment/scrypath_ops/priv/static/assets/css/app.css" text/css

    model_digest="$model_sha"
    printf 'DEPENDENCY_BOUNDARY case=runtime env=%s project=%s image_id=%s mix_env=%s model_sha256=%s port=127.0.0.1:%s status=passed\n' \
      "$environment" "$project" "$image_id" "$actual_mix_env" "$model_digest" "$host_port"
  done

  [[ "$(node "$helper" fingerprint)" == "$source_fingerprint" ]] ||
    fail "checkout source fingerprint changed while the runtime proof was running"
  printf 'Runtime dependency boundary proof passed (test/prod graphs, owned cleanup, and four served assets per target).\n'
fi
