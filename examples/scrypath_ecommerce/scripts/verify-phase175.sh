#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-}"
if [[ "$scope" != repair || $# -ne 1 ]]; then
  echo "Usage: $0 repair" >&2
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
diff_sha="$(
  {
    git -C "$repo_root" diff --binary HEAD
    git -C "$repo_root" ls-files --others --exclude-standard | sort | while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      printf '%s\0' "$file"
      shasum -a 256 "$repo_root/$file"
    done
  } | shasum -a 256 | awk '{print $1}'
)"
safe_sha="$(printf '%s' "$source_sha" | tr -cd '[:alnum:]_-')"
project="scrypath_phase175_${safe_sha:0:10}_${scope}_$$"
if [[ ! "$project" =~ ^scrypath_phase175_${safe_sha:0:10}_${scope}_[a-zA-Z0-9_-]+$ ]]; then
  echo "Generated Phase 175 Compose project identity is invalid." >&2
  exit 64
fi
artifact_dir="${PHASE175_EVIDENCE_DIR:-$example_dir/test-results/phase175-${scope}-${safe_sha:0:10}-$$}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.phase175.yaml)

assert_no_existing_resources() {
  local containers volumes networks
  containers="$(docker ps -aq --filter "label=com.docker.compose.project=$project")"
  volumes="$(docker volume ls -q --filter "label=com.docker.compose.project=$project")"
  networks="$(docker network ls -q --filter "label=com.docker.compose.project=$project")"
  if [[ -n "$containers$volumes$networks" ]]; then
    echo "Refusing to claim pre-existing Docker resources for '$project'." >&2
    return 1
  fi
}
assert_no_existing_resources

export SCRYPATH_SOURCE_SHA="$source_sha"
export E2E_SCOPE="phase175-${scope}"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"

status=0
cleanup_status=0
started=0
mkdir -p "$artifact_dir"
collect_artifacts() {
  "${compose[@]}" logs --no-color --tail 5000 >"$artifact_dir/compose.log" 2>&1 || true
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
  if (( started )); then
    "${compose[@]}" down --volumes --remove-orphans
    cleanup_status=$?
  fi
  local containers volumes networks
  containers="$(docker ps -aq --filter "label=com.docker.compose.project=$project")"
  volumes="$(docker volume ls -q --filter "label=com.docker.compose.project=$project")"
  networks="$(docker network ls -q --filter "label=com.docker.compose.project=$project")"
  if [[ -n "$containers$volumes$networks" ]]; then
    printf 'Phase 175 cleanup left owned resources: containers=%s volumes=%s networks=%s\n' \
      "${containers:-none}" "${volumes:-none}" "${networks:-none}" >&2
    cleanup_status=1
  fi
  printf 'cleanup_status=%s\nproject=%s\nsource_sha=%s\n' "$cleanup_status" "$project" "$source_sha" > "$artifact_dir/cleanup.txt"
  if (( original_status != 0 )); then exit "$original_status"; fi
  exit "$cleanup_status"
}
trap cleanup EXIT

echo "Validating isolated Phase 175 Compose project '$project'..."
"${compose[@]}" config --quiet
started=1
echo "Running only the Phase 175 mounted/standalone repair browser scope..."
"${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || status=$?
if (( status != 0 )); then
  echo "Phase 175 browser verification failed (scope=$scope, exit=$status)." >&2
  exit "$status"
fi

echo "Phase 175 browser verification passed; bounded artifacts: $artifact_dir"
