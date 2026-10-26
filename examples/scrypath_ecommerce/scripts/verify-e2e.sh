#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-focused}"
mode="${2:-}"
if [[ "$#" -gt 2 ]]; then
  echo "Usage: $0 [focused|full [--readiness-only]]" >&2
  exit 64
fi
case "$scope" in
  focused|full) ;;
  *)
    echo "Usage: $0 [focused|full [--readiness-only]]" >&2
    exit 64
    ;;
esac
case "$mode" in
  "") ;;
  --readiness-only)
    if [[ "$scope" != "full" ]]; then
      echo "--readiness-only is supported only with full scope." >&2
      exit 64
    fi
    ;;
  *)
    echo "Usage: $0 [focused|full [--readiness-only]]" >&2
    exit 64
    ;;
esac

docker_timeout="${E2E_DOCKER_TIMEOUT_SECONDS:-900}"
finalize_timeout="${E2E_FINALIZE_TIMEOUT_SECONDS:-30}"
if [[ ! "$docker_timeout" =~ ^[1-9][0-9]*$ || ! "$finalize_timeout" =~ ^[1-9][0-9]*$ ]]; then
  echo "E2E Docker timeouts must be positive whole seconds." >&2
  exit 64
fi

run_bounded() {
  local timeout_seconds="$1"
  shift
  "$@" &
  local command_pid=$!
  local deadline=$((SECONDS + timeout_seconds))
  local process_state

  while kill -0 "$command_pid" 2>/dev/null; do
    process_state="$(ps -o stat= -p "$command_pid" 2>/dev/null || true)"
    if [[ -z "$process_state" || "$process_state" == Z* ]]; then
      break
    fi
    if (( SECONDS >= deadline )); then
      kill -TERM "$command_pid" 2>/dev/null || true
      sleep 1
      if kill -0 "$command_pid" 2>/dev/null; then
        kill -KILL "$command_pid" 2>/dev/null || true
      fi
      wait "$command_pid" 2>/dev/null || true
      echo "External Docker operation timed out after ${timeout_seconds}s: $*" >&2
      return 124
    fi
    sleep 1
  done

  wait "$command_pid"
}

if ! run_bounded "$finalize_timeout" docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 69
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example_dir="$(cd "$script_dir/.." && pwd)"
cd "$example_dir"

sha="$(git rev-parse --short=8 HEAD 2>/dev/null || printf 'workspace')"
safe_sha="$(printf '%s' "$sha" | tr -cd '[:alnum:]_-')"
project="scrypath_ecommerce_verify_${scope}_${safe_sha}_$$"
artifact_dir="$example_dir/test-results/docker-${scope}-${safe_sha}_$$"
mkdir -p "$artifact_dir"
compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml)
if [[ "$scope" == "full" ]]; then
  compose+=(-f compose.phase173.yaml)
fi

export E2E_SCOPE="$scope"
export SCRYPATH_SOURCE_SHA="$(git rev-parse HEAD)"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"

run_status=0
artifact_copy_status=0
cleanup_status=0
cleanup_state="pending"
readiness_started=0
readiness_status="not_run"
mounted_route_status="not_run"
standalone_route_status="not_run"
owned_containers_count=0
owned_networks_count=0
owned_volumes_count=0

resource_count() {
  local resources="$1"
  if [[ -z "$resources" ]]; then
    echo 0
  else
    printf '%s\n' "$resources" | awk 'NF { count++ } END { print count + 0 }'
  fi
}

record_lifecycle() {
  local original_status="$1"
  local artifact_status_label="passed"
  (( artifact_copy_status == 0 )) || artifact_status_label="failed"
  printf '{\n  "original_exit_status": %s,\n  "artifact_copy_status": "%s",\n  "readiness": {\n    "status": "%s",\n    "routes": {\n      "mounted_ops": "%s",\n      "standalone_ops": "%s"\n    }\n  },\n  "cleanup": {\n    "project": "%s",\n    "status": "%s",\n    "containers": %s,\n    "networks": %s,\n    "volumes": %s\n  }\n}\n' \
    "$original_status" "$artifact_status_label" "$readiness_status" \
    "$mounted_route_status" "$standalone_route_status" "$project" "$cleanup_state" \
    "$owned_containers_count" "$owned_networks_count" "$owned_volumes_count" \
    >"$artifact_dir/lifecycle.json"
}

collect_artifacts() {
  if ! mkdir -p "$artifact_dir"; then
    echo "Could not create verifier artifact directory: $artifact_dir" >&2
    artifact_copy_status=1
    return
  fi

  if ! run_bounded "$finalize_timeout" "${compose[@]}" logs --no-color --tail 200 >"$artifact_dir/compose.log" 2>&1; then
    echo "Could not collect bounded Compose diagnostics for '$project'." >&2
    artifact_copy_status=1
  fi

  local browser_id
  browser_id="$(run_bounded "$finalize_timeout" "${compose[@]}" ps -aq browser 2>>"$artifact_dir/finalization.log")"
  local lookup_status=$?
  if (( lookup_status != 0 )); then
    echo "Could not identify the owned browser container for artifact collection." >&2
    artifact_copy_status=1
    return
  fi

  if [[ -n "$browser_id" ]]; then
    if ! run_bounded "$finalize_timeout" docker cp "$browser_id:/app/examples/scrypath_ecommerce/test-results/." \
      "$artifact_dir/test-results" >>"$artifact_dir/finalization.log" 2>&1; then
      echo "Could not copy the owned browser test-results artifacts." >&2
      artifact_copy_status=1
    fi
    if ! run_bounded "$finalize_timeout" docker cp "$browser_id:/app/examples/scrypath_ecommerce/playwright-report/." \
      "$artifact_dir/playwright-report" >>"$artifact_dir/finalization.log" 2>&1; then
      echo "Could not copy the owned browser Playwright report artifacts." >&2
      artifact_copy_status=1
    fi
  elif [[ "$mode" != "--readiness-only" && "$scope" == "full" && "$readiness_started" == "1" && "$run_status" == "0" ]]; then
    echo "Successful full verification did not retain an owned browser container for artifact collection." >&2
    artifact_copy_status=1
  fi
}

cleanup() {
  local original_exit_status=$?
  local container_query_status network_query_status volume_query_status
  local owned_containers owned_networks owned_volumes
  trap - EXIT
  set +e

  collect_artifacts

  if [[ "${KEEP_E2E_STACK:-0}" == "1" ]]; then
    cleanup_state="preserved_not_clean"
    cleanup_status=1
    echo "KEEP_E2E_STACK=1: preserving Compose project '$project'; verifier status is not clean."
  else
    run_bounded "$finalize_timeout" "${compose[@]}" down --volumes --remove-orphans --timeout 10
    cleanup_status=$?
    cleanup_state="clean"
  fi

  owned_containers="$(run_bounded "$finalize_timeout" docker ps -aq --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
  container_query_status=$?
  owned_networks="$(run_bounded "$finalize_timeout" docker network ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
  network_query_status=$?
  owned_volumes="$(run_bounded "$finalize_timeout" docker volume ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
  volume_query_status=$?
  owned_containers_count="$(resource_count "$owned_containers")"
  owned_networks_count="$(resource_count "$owned_networks")"
  owned_volumes_count="$(resource_count "$owned_volumes")"

  if (( container_query_status != 0 || network_query_status != 0 || volume_query_status != 0 )); then
    echo "Verifier cleanup could not enumerate every owned Docker resource for '$project'." >&2
    cleanup_status=1
  fi
  if (( owned_containers_count > 0 || owned_networks_count > 0 || owned_volumes_count > 0 )); then
    echo "Verifier cleanup left owned resources behind: project=$project containers=$owned_containers_count networks=$owned_networks_count volumes=$owned_volumes_count" >&2
    cleanup_status=1
  fi
  if [[ "${KEEP_E2E_STACK:-0}" != "1" ]] && (( cleanup_status != 0 )); then
    cleanup_state="failed"
  fi

  if [[ "$scope" != "full" ]]; then
    readiness_status="not_applicable"
    mounted_route_status="not_applicable"
    standalone_route_status="not_applicable"
  elif [[ "$readiness_started" == "1" ]]; then
    if (( original_exit_status == 0 )); then
      readiness_status="passed"
      mounted_route_status="passed"
      standalone_route_status="passed"
    else
      readiness_status="failed_or_incomplete"
      mounted_route_status="unknown"
      standalone_route_status="unknown"
    fi
  fi

  if ! record_lifecycle "$original_exit_status"; then
    echo "Could not write verifier lifecycle evidence for '$project'." >&2
    artifact_copy_status=1
  fi
  echo "Verifier lifecycle: original_exit_status=$original_exit_status artifact_copy_status=$artifact_copy_status cleanup_status=$cleanup_status"
  echo "Verifier ownership: project=$project containers=$owned_containers_count networks=$owned_networks_count volumes=$owned_volumes_count cleanup=$cleanup_state"

  if (( original_exit_status != 0 )); then
    exit "$original_exit_status"
  elif (( artifact_copy_status != 0 )); then
    exit 74
  elif (( cleanup_status != 0 )); then
    exit 75
  fi
  exit 0
}
trap cleanup EXIT

echo "Validating Compose model for '$scope' verification..."
run_bounded "$docker_timeout" "${compose[@]}" config --quiet

echo "Starting isolated Docker verifier project '$project'..."
if [[ "$mode" == "--readiness-only" ]]; then
  readiness_started=1
  run_bounded "$docker_timeout" "${compose[@]}" build web standalone_ops browser || run_status=$?
  if (( run_status == 0 )); then
    run_bounded "$docker_timeout" "${compose[@]}" run --rm -T -e E2E_READINESS_ONLY=1 browser || run_status=$?
  fi
else
  [[ "$scope" != "full" ]] || readiness_started=1
  run_bounded "$docker_timeout" "${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || run_status=$?
fi

if (( run_status != 0 )); then
  echo "Docker verifier failed (scope=$scope, exit=$run_status)." >&2
  exit "$run_status"
fi

if [[ "$mode" == "--readiness-only" ]]; then
  echo "Readiness-only diagnostic passed; full browser acceptance was not run."
else
  echo "Docker verifier passed (scope=$scope)."
fi
