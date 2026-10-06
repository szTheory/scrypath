#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-}"
smoke=0
if [[ "${2:-}" == "--smoke" ]]; then smoke=1; fi
case "$scope" in
  shell|status|time|copy) ;;
  *) echo "Usage: $0 {shell|status|time|copy} [--smoke]" >&2; exit 64 ;;
esac
if [[ $# -gt 2 || ( $# -eq 2 && "$smoke" != 1 ) ]]; then
  echo "Usage: $0 {shell|status|time|copy} [--smoke]" >&2
  exit 64
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 69
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$example_dir/../.." && pwd)"
cd "$example_dir"

source_sha="$(git -C "$repo_root" rev-parse HEAD)"
safe_sha="$(printf '%s' "$source_sha" | tr -cd '[:alnum:]_-')"
project="scrypath_phase173_${safe_sha:0:10}_${scope}_$$"
artifact_dir="$example_dir/test-results/phase173-${scope}-${safe_sha:0:10}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.phase173.yaml)
export SCRYPATH_SOURCE_SHA="$source_sha"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"
export E2E_SCOPE="phase173-${scope}"

status=0
cleanup_status=0
collect_artifacts() {
  mkdir -p "$artifact_dir"
  "${compose[@]}" logs --no-color >"$artifact_dir/compose.log" 2>&1 || true
  printf '%s\n' "$source_sha" > "$artifact_dir/source-sha.txt"
  local browser_id
  browser_id="$("${compose[@]}" ps -aq browser 2>/dev/null || true)"
  if [[ -n "$browser_id" ]]; then
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/test-results/." "$artifact_dir/test-results" >/dev/null 2>&1 || true
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/playwright-report/." "$artifact_dir/playwright-report" >/dev/null 2>&1 || true
  fi
}
cleanup() {
  local original_status=$?
  trap - EXIT
  set +e
  collect_artifacts
  "${compose[@]}" down --volumes --remove-orphans
  cleanup_status=$?
  if [[ -n "$(docker ps -aq --filter "label=com.docker.compose.project=$project")" ]]; then
    echo "Phase 173 cleanup left task-owned containers behind: $project" >&2
    cleanup_status=1
  fi
  if (( original_status != 0 )); then exit "$original_status"; fi
  exit "$cleanup_status"
}
trap cleanup EXIT

echo "Validating disposable Phase 173 Compose stack '$project'..."
"${compose[@]}" config --quiet

if (( smoke )); then
  echo "Starting disposable Phase 173 services for source-to-render smoke checks..."
  "${compose[@]}" up --build -d postgres meilisearch web ops
  ready=0
  for attempt in $(seq 1 360); do
    if "${compose[@]}" exec -T web curl --silent --fail http://127.0.0.1:4002/admin/search/phase173/health >/dev/null 2>&1 \
      && "${compose[@]}" exec -T ops curl --silent --fail http://127.0.0.1:4003/ops/phase173/health >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 2
  done
  if (( ! ready )); then echo "Fixture routes did not become ready." >&2; exit 1; fi

  mounted="$("${compose[@]}" exec -T web curl --silent --fail --cookie-jar /tmp/phase173-web-cookies http://127.0.0.1:4002/admin/search/phase173/health)"
  standalone="$("${compose[@]}" exec -T ops curl --silent --fail --cookie-jar /tmp/phase173-ops-cookies http://127.0.0.1:4003/ops/phase173/health)"
  printf '%s' "$mounted" > "$artifact_dir/mounted-health.html"
  printf '%s' "$standalone" > "$artifact_dir/standalone-health.html"
  [[ "$mounted" == *"Search health"* && "$mounted" == *"ScrypathEcommerce.Catalog.Product"* ]] || {
    echo "Mounted route did not render source-derived ecommerce posture." >&2; exit 1;
  }
  [[ "$standalone" == *"Search health"* && "$standalone" == *"ScrypathOps.Test.OpsPostA"* ]] || {
    echo "Standalone route did not render source-derived Ops posture." >&2; exit 1;
  }
  for target in \
    "web http://127.0.0.1:4002/admin/search/phase173/assets/css/app.css" \
    "web http://127.0.0.1:4002/admin/search/phase173/assets/js/app.js" \
    "ops http://127.0.0.1:4003/ops/phase173/assets/css/app.css" \
    "ops http://127.0.0.1:4003/ops/phase173/assets/js/app.js"; do
    read -r service url <<< "$target"
    echo "Checking Ops asset: $service $url"
    cookie_file="/tmp/phase173-${service}-cookies"
    response="$("${compose[@]}" exec -T "$service" sh -c 'curl --silent --show-error --cookie "$1" --write-out "\nhttp_status=%{http_code}" "$2"' sh "$cookie_file" "$url")"
    http_status="${response##*http_status=}"
    if [[ "$http_status" != "200" ]]; then
      echo "Ops asset request failed ($http_status): ${response%$'\n'http_status=*}" >&2
      exit 1
    fi
  done
  echo "Phase 173 smoke assertions passed: two production PostureLive renders and four Ops asset URLs."
else
  echo "Running Phase 173 '$scope' browser verification in a disposable Compose project..."
  "${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || status=$?
  if (( status != 0 )); then echo "Phase 173 browser verification failed (scope=$scope, exit=$status)." >&2; exit "$status"; fi
fi
