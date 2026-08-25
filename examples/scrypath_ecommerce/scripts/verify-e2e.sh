#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-focused}"
case "$scope" in
  focused|full) ;;
  *)
    echo "Usage: $0 [focused|full]" >&2
    exit 64
    ;;
esac

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 69
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example_dir="$(cd "$script_dir/.." && pwd)"
cd "$example_dir"

sha="$(git rev-parse --short=8 HEAD 2>/dev/null || printf 'workspace')"
safe_sha="$(printf '%s' "$sha" | tr -cd '[:alnum:]_-')"
project="scrypath_ecommerce_verify_${scope}_${safe_sha}_$$"
artifact_dir="$example_dir/test-results/docker-${scope}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml)

export E2E_SCOPE="$scope"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"

run_status=0
cleanup_status=0

collect_artifacts() {
  mkdir -p "$artifact_dir"
  "${compose[@]}" logs --no-color >"$artifact_dir/compose.log" 2>&1 || true

  local browser_id
  browser_id="$("${compose[@]}" ps -aq browser 2>/dev/null || true)"
  if [[ -n "$browser_id" ]]; then
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/test-results/." \
      "$artifact_dir/test-results" >/dev/null 2>&1 || true
    docker cp "$browser_id:/app/examples/scrypath_ecommerce/playwright-report/." \
      "$artifact_dir/playwright-report" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  local original_status=$?
  trap - EXIT
  set +e

  collect_artifacts

  if [[ "${KEEP_E2E_STACK:-0}" == "1" ]]; then
    echo "KEEP_E2E_STACK=1: preserving Compose project '$project' for debugging."
  else
    "${compose[@]}" down --volumes --remove-orphans
    cleanup_status=$?

    if [[ -n "$(docker ps -aq --filter "label=com.docker.compose.project=$project")" ]]; then
      echo "Verifier cleanup left project containers behind: $project" >&2
      cleanup_status=1
    fi
  fi

  if (( original_status != 0 )); then
    exit "$original_status"
  fi
  exit "$cleanup_status"
}
trap cleanup EXIT

echo "Validating Compose model for '$scope' verification..."
"${compose[@]}" config --quiet

echo "Starting isolated Docker verifier project '$project'..."
"${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || run_status=$?

if (( run_status != 0 )); then
  echo "Docker verifier failed (scope=$scope, exit=$run_status)." >&2
  exit "$run_status"
fi

echo "Docker verifier passed (scope=$scope)."
