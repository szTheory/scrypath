#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-}"
mode="${2:-}"
if [[ "$scope" != "shell" && "$scope" != "status" && "$scope" != "time" && "$scope" != "copy" ]] || [[ -n "$mode" && "$mode" != "--smoke" ]] || [[ "$#" -gt 2 ]]; then
  echo "Usage: $0 <shell|status|time|copy> [--smoke]" >&2
  exit 64
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 69
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example_dir="$(cd "$script_dir/.." && pwd)"
cd "$example_dir"

source_sha="$(git rev-parse HEAD 2>/dev/null || printf 'workspace')"
safe_sha="$(printf '%s' "$source_sha" | tr -cd '[:alnum:]_-')"
project="scrypath_phase173_${scope}_${safe_sha:0:8}_$$"
artifact_dir="${TMPDIR:-/tmp}/scrypath-phase173/${project}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml -f compose.phase173.yaml)

export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"
export SCRYPATH_SOURCE_SHA="$source_sha"
export E2E_SCOPE="phase173_${scope}"
export PHASE173_STANDALONE_BASE_URL="http://standalone_ops:4003"
export PHASE173_SCREENSHOT_DIR="/app/examples/scrypath_ecommerce/test-results/phase173"

run_status=0
cleanup_status=0

collect_artifacts() {
  mkdir -p "$artifact_dir"
  "${compose[@]}" logs --no-color >"$artifact_dir/compose.log" 2>&1 || true

  local browser_id
  browser_id="$("${compose[@]}" ps -aq browser 2>/dev/null || true)"
  if [[ -n "$browser_id" ]]; then
    mkdir -p "$artifact_dir/screenshots" "$artifact_dir/playwright-results"
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/test-results/phase173/." \
      "$artifact_dir/screenshots" >/dev/null 2>&1 || true
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/test-results/." \
      "$artifact_dir/playwright-results" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  local original_status=$?
  trap - EXIT
  set +e

  collect_artifacts
  "${compose[@]}" down --volumes --remove-orphans
  cleanup_status=$?

  if [[ -n "$(docker ps -aq --filter "label=com.docker.compose.project=$project")" || \
        -n "$(docker volume ls -q --filter "label=com.docker.compose.project=$project")" || \
        -n "$(docker network ls -q --filter "label=com.docker.compose.project=$project")" ]]; then
    echo "Verifier cleanup left Compose resources behind: $project" >&2
    cleanup_status=1
  fi

  if (( original_status != 0 )); then
    exit "$original_status"
  fi
  exit "$cleanup_status"
}
trap cleanup EXIT

mounted_url="http://127.0.0.1:4002/admin/search/phase173/health"
standalone_url="http://127.0.0.1:4003/ops/phase173/health"

wait_for_service_url() {
  local service="$1" url="$2"
  for _attempt in $(seq 1 180); do
    if "${compose[@]}" exec -T "$service" curl --silent --fail --max-time 5 "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for $service route $url" >&2
  return 70
}

echo "Validating the Phase 173 Compose model for '$scope'..."
"${compose[@]}" config --quiet
if [[ "$mode" == "--smoke" ]]; then
  "${compose[@]}" build web standalone_ops
else
  "${compose[@]}" build web standalone_ops browser
fi
echo "Starting unique disposable project '$project'..."
"${compose[@]}" up -d web standalone_ops

wait_for_service_url web "$mounted_url"
wait_for_service_url standalone_ops "$standalone_url"

mounted_html="$("${compose[@]}" exec -T web curl --silent --show-error --fail "$mounted_url")"
standalone_html="$("${compose[@]}" exec -T standalone_ops curl --silent --show-error --fail "$standalone_url")"

for expected in "ScrypathEcommerce.Catalog.Product" "phase173_product"; do
  if [[ "$mounted_html" != *"$expected"* ]]; then
    echo "Mounted PostureLive did not render source-derived value '$expected'." >&2
    exit 71
  fi
done

for expected in "ScrypathOps.Phase173FixtureSchema" "phase173_phase173_fixture_schema"; do
  if [[ "$standalone_html" != *"$expected"* ]]; then
    echo "Standalone PostureLive did not render source-derived value '$expected'." >&2
    exit 71
  fi
done

for pair in "web /assets/css/app.css" "web /admin/search/assets/css/app.css" "web /assets/js/app.js" \
            "standalone_ops /assets/css/app.css" "standalone_ops /assets/js/app.js"; do
  read -r service path <<<"$pair"
  port=4002
  [[ "$service" == "standalone_ops" ]] && port=4003
  asset_url="http://127.0.0.1:$port$path"
  if ! "${compose[@]}" exec -T "$service" curl --silent --fail --max-time 5 "$asset_url" >/dev/null 2>&1; then
    status="$("${compose[@]}" exec -T "$service" curl --silent --output /dev/null --write-out '%{http_code}' \
      --max-time 5 "$asset_url" 2>/dev/null || true)"
    echo "Asset probe failed for $service $path (HTTP ${status:-unreachable})." >&2
    "${compose[@]}" exec -T "$service" curl --silent --show-error --include --max-time 5 "$asset_url" 2>&1 | head -c 600 >&2 || true
    echo >&2
    exit 72
  fi
done

if [[ "$mode" == "--smoke" ]]; then
  echo "Phase 173 '$scope' source-to-render smoke passed for both entrypoints and their CSS/JS assets."
  exit 0
fi

echo "Running the isolated Phase 173 browser suite for '$scope'..."
"${compose[@]}" up --no-build --abort-on-container-exit --exit-code-from browser browser || run_status=$?
if (( run_status != 0 )); then
  echo "Phase 173 browser suite failed (scope=$scope, exit=$run_status)." >&2
  exit "$run_status"
fi

echo "Phase 173 browser suite passed (scope=$scope). Source SHA: $source_sha"
