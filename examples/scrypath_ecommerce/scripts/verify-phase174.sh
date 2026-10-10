#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-}"
if [[ "$scope" != recovery || $# -ne 1 ]]; then
  echo "Usage: $0 recovery" >&2
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
diff_sha="$(git -C "$repo_root" diff --binary HEAD | shasum -a 256 | awk '{print $1}')"
safe_sha="$(printf '%s' "$source_sha" | tr -cd '[:alnum:]_-')"
project="${PHASE174_PROJECT_ID:-scrypath_phase174_${safe_sha:0:10}_${scope}_$$}"
if [[ ! "$project" =~ ^scrypath_phase174_${safe_sha:0:10}_${scope}_[a-zA-Z0-9_-]+$ ]]; then
  echo "PHASE174_PROJECT_ID must remain in this source/scope's unique project namespace." >&2
  exit 64
fi
artifact_dir="$example_dir/test-results/phase174-${scope}-${safe_sha:0:10}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.phase174.yaml)
export SCRYPATH_SOURCE_SHA="$source_sha"
export E2E_SCOPE="phase174-${scope}"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"

status=0
cleanup_status=0
collect_artifacts() {
  mkdir -p "$artifact_dir"
  "${compose[@]}" logs --no-color >"$artifact_dir/compose.log" 2>&1 || true
  printf '%s\n' "$source_sha" > "$artifact_dir/source-sha.txt"
  printf '%s\n' "$diff_sha" > "$artifact_dir/worktree-diff-sha256.txt"
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
  local containers volumes networks
  containers="$(docker ps -aq --filter "label=com.docker.compose.project=$project")"
  volumes="$(docker volume ls -q --filter "label=com.docker.compose.project=$project")"
  networks="$(docker network ls -q --filter "label=com.docker.compose.project=$project")"
  if [[ -n "$containers$volumes$networks" ]]; then
    printf 'Phase 174 cleanup left task-owned resources: containers=%s volumes=%s networks=%s\n' \
      "${containers:-none}" "${volumes:-none}" "${networks:-none}" >&2
    cleanup_status=1
  fi
  printf 'cleanup_status=%s\nproject=%s\n' "$cleanup_status" "$project" > "$artifact_dir/cleanup.txt"
  if (( original_status != 0 )); then exit "$original_status"; fi
  exit "$cleanup_status"
}
trap cleanup EXIT

echo "Validating isolated Phase 174 Compose stack '$project'..."
"${compose[@]}" config --quiet
echo "Running only the Phase 174 recovery browser scope..."
"${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || status=$?
if (( status != 0 )); then
  echo "Phase 174 browser verification failed (scope=$scope, exit=$status)." >&2
  exit "$status"
fi

echo "Phase 174 recovery browser verification passed; artifacts: $artifact_dir"
