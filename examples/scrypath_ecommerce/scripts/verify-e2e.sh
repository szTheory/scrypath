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

run_id="${E2E_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$-${RANDOM}${RANDOM}}"
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]; then
  echo "E2E_RUN_ID must contain only letters, digits, dot, underscore or dash." >&2
  exit 64
fi
job_started_at="${E2E_JOB_STARTED_AT:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
if [[ ! "$job_started_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  echo "E2E_JOB_STARTED_AT must use UTC ISO form YYYY-MM-DDTHH:MM:SSZ." >&2
  exit 64
fi
job_started_epoch="$(date -u -d "$job_started_at" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$job_started_at" +%s 2>/dev/null || true)"
if [[ ! "$job_started_epoch" =~ ^[0-9]+$ ]]; then
  echo "E2E_JOB_STARTED_AT must be an ISO timestamp accepted by date." >&2
  exit 64
fi
finalization_margin="${E2E_FINALIZATION_MARGIN_SECONDS:-300}"
if [[ ! "$finalization_margin" =~ ^[0-9]+$ ]]; then
  echo "E2E_FINALIZATION_MARGIN_SECONDS must be a non-negative whole number." >&2
  exit 64
fi
deadline_epoch="${E2E_DEADLINE_EPOCH:-$((job_started_epoch + docker_timeout))}"
if [[ ! "$deadline_epoch" =~ ^[1-9][0-9]*$ ]] || (( deadline_epoch - finalization_margin <= $(date +%s) || deadline_epoch - 60 <= $(date +%s) )); then
  echo "E2E_DEADLINE_EPOCH must be in the future with enough time reserved for finalization." >&2
  exit 64
fi
finalization_deadline_epoch=$((deadline_epoch - 60))

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

run_execution_bounded() {
  local remaining=$((deadline_epoch - finalization_margin - $(date +%s)))
  if (( remaining <= 0 )); then
    echo "Full verification deadline reached before finalization reserve." >&2
    return 124
  fi
  if (( remaining > docker_timeout )); then remaining="$docker_timeout"; fi
  run_bounded "$remaining" "$@"
}

run_verification_bounded() {
  if [[ "$scope" == "full" ]]; then
    run_execution_bounded "$@"
  else
    run_bounded "$docker_timeout" "$@"
  fi
}

run_finalization_bounded() {
  local remaining=$((finalization_deadline_epoch - $(date +%s)))
  if (( remaining <= 0 )); then
    echo "Evidence finalization reached the upload reserve deadline." >&2
    return 124
  fi
  if (( remaining > finalize_timeout )); then remaining="$finalize_timeout"; fi
  run_bounded "$remaining" "$@"
}

hash_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
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
project="${E2E_PROJECT_NAME:-scrypath_ecommerce_verify_${scope}_${safe_sha}_$$}"
if [[ ! "$project" =~ ^[a-z0-9][a-z0-9_-]{0,62}$ ]]; then
  echo "E2E_PROJECT_NAME must be a lowercase Compose project name." >&2
  exit 64
fi
export E2E_PROJECT_NAME="$project"
artifact_parent="$example_dir/test-results/docker-${scope}"
artifact_dir="$artifact_parent/$run_id"
mkdir -p "$artifact_parent"
if ! mkdir -m 700 "$artifact_dir"; then
  echo "Refusing to reuse existing run evidence directory: $artifact_dir" >&2
  exit 73
fi
compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml)
if [[ "$scope" == "full" ]]; then
  compose+=(-f compose.phase173.yaml)
fi
repo_root="$(cd "$example_dir/../.." && pwd)"
build_helper="$repo_root/scripts/ci/ecommerce_build.cjs"

export E2E_SCOPE="$scope"
export SCRYPATH_SOURCE_SHA="$(git rev-parse HEAD)"
export PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION:-1.60.0}"
export E2E_RUN_ID="$run_id"
export E2E_CONTAINER_ARTIFACT_DIR="/tmp/$run_id"
export E2E_JOB_STARTED_AT="$job_started_at"
export E2E_DEADLINE_EPOCH="$deadline_epoch"
export E2E_FINALIZATION_MARGIN_SECONDS="$finalization_margin"
export E2E_SOURCE_MODE="${E2E_SOURCE_MODE:-local}"
if [[ "$E2E_SOURCE_MODE" != "local" && "$E2E_SOURCE_MODE" != "hosted" ]]; then
  echo "E2E_SOURCE_MODE must be local or hosted." >&2
  exit 64
fi
export E2E_EVENT_NAME="${E2E_EVENT_NAME:-local}"
export E2E_GIT_REF="${E2E_GIT_REF:-$(git branch --show-current 2>/dev/null || printf 'local')}"
export E2E_EVENT_SHA="${E2E_EVENT_SHA:-$SCRYPATH_SOURCE_SHA}"
export E2E_WORKFLOW_RUN_ID="${E2E_WORKFLOW_RUN_ID:-$run_id}"
export E2E_WORKFLOW_RUN_ATTEMPT="${E2E_WORKFLOW_RUN_ATTEMPT:-1}"
export E2E_JOB_NAME="${E2E_JOB_NAME:-local-ecommerce-e2e}"
export E2E_JOB_CONCLUSION="${E2E_JOB_CONCLUSION:-success}"

dirty_files="$(git status --porcelain --untracked-files=all 2>/dev/null || true)"
source_dirty=false
source_fingerprint=""
if [[ -n "$dirty_files" ]]; then
  source_dirty=true
  source_fingerprint="$(node "$build_helper" fingerprint)"
fi
export E2E_SOURCE_FINGERPRINT="$source_fingerprint"
printf '{"mode":"%s","checkout_head":"%s","built_source_sha":"%s","event_sha":"%s","dirty":%s,"dirty_fingerprint":"%s","job_started_at":"%s","run_id":"%s"}\n' \
  "$E2E_SOURCE_MODE" "$SCRYPATH_SOURCE_SHA" "$SCRYPATH_SOURCE_SHA" "$E2E_EVENT_SHA" \
  "$source_dirty" "$source_fingerprint" "$job_started_at" "$run_id" >"$artifact_dir/source.json"

prebuilt_mode=0
if [[ -n "${E2E_PREBUILT_MANIFEST:-}" || -n "${E2E_IMAGE_OVERRIDE:-}" ]]; then
  if [[ -z "${E2E_PREBUILT_MANIFEST:-}" || -z "${E2E_IMAGE_OVERRIDE:-}" ]]; then
    echo "Prebuilt verification requires both E2E_PREBUILT_MANIFEST and E2E_IMAGE_OVERRIDE." >&2
    exit 64
  fi
  if [[ "$mode" == "--readiness-only" ]]; then
    echo "Prebuilt readiness-only mode is unsupported; run the canonical browser verifier instead." >&2
    exit 64
  fi
  if [[ ! -f "$E2E_PREBUILT_MANIFEST" || ! -f "$E2E_IMAGE_OVERRIDE" ]]; then
    echo "Prebuilt handoff manifest or image override does not exist." >&2
    exit 69
  fi
  prebuilt_mode=1
  compose+=(-f "$E2E_IMAGE_OVERRIDE")
fi

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
browser_image_id=""
application_image_id=""
standalone_image_id=""
compose_model_digest=""
compose_validation_status="not_run"
artifact_copy_started_at=""
artifact_copy_ended_at=""
artifact_copy_exit_code=0

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
  printf '{\n  "run_id": "%s",\n  "scope": "%s",\n  "original_exit_status": %s,\n  "artifact_copy_status": "%s",\n  "readiness": {\n    "status": "%s",\n    "routes": {\n      "mounted_ops": "%s",\n      "standalone_ops": "%s"\n    }\n  },\n  "cleanup": {\n    "project": "%s",\n    "status": "%s",\n    "containers": %s,\n    "networks": %s,\n    "volumes": %s\n  }\n}\n' \
    "$run_id" "$scope" \
    "$original_status" "$artifact_status_label" "$readiness_status" \
    "$mounted_route_status" "$standalone_route_status" "$project" "$cleanup_state" \
    "$owned_containers_count" "$owned_networks_count" "$owned_volumes_count" \
    >"$artifact_dir/lifecycle.json"
}

collect_artifacts() {
  artifact_copy_started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if ! run_finalization_bounded "${compose[@]}" logs --no-color --tail 200 >"$artifact_dir/compose.log" 2>&1; then
    echo "Could not collect bounded Compose diagnostics for '$project'." >&2
    artifact_copy_status=1
  fi

  local browser_id
  browser_id="$(run_finalization_bounded "${compose[@]}" ps -aq browser 2>>"$artifact_dir/finalization.log")"
  local lookup_status=$?
  if (( lookup_status != 0 )); then
    echo "Could not identify the owned browser container for artifact collection." >&2
    artifact_copy_status=1
    return
  fi

  if [[ -n "$browser_id" ]]; then
    browser_image_id="$(run_finalization_bounded docker inspect --format '{{.Image}}' "$browser_id" 2>>"$artifact_dir/finalization.log")"
    local browser_lookup_status=$?
    if (( browser_lookup_status != 0 )) || [[ ! "$browser_image_id" =~ ^sha256:[a-f0-9]{64}$ ]]; then
      echo "Could not identify the immutable browser image used by this run." >&2
      artifact_copy_status=1
    fi
    for service in web standalone_ops; do
      local service_id service_image service_status
      service_id="$(run_finalization_bounded "${compose[@]}" ps -aq "$service" 2>>"$artifact_dir/finalization.log")"
      service_status=$?
      if (( service_status == 0 )) && [[ -n "$service_id" ]]; then
        service_image="$(run_finalization_bounded docker inspect --format '{{.Image}}' "$service_id" 2>>"$artifact_dir/finalization.log")"
        service_status=$?
        if [[ "$service" == "web" ]]; then application_image_id="$service_image"; else standalone_image_id="$service_image"; fi
      fi
    done
    artifact_copy_started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if ! run_finalization_bounded docker cp "$browser_id:$E2E_CONTAINER_ARTIFACT_DIR/." \
      "$artifact_dir" >>"$artifact_dir/finalization.log" 2>&1; then
      echo "Could not copy the run-owned browser evidence directory." >&2
      artifact_copy_status=1
    fi
    artifact_copy_ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    artifact_copy_exit_code="$artifact_copy_status"
    if [[ "$scope" == "full" && "$mode" != "--readiness-only" && "$run_status" == "0" ]]; then
      for required in phase105-playwright-list.json phase105-playwright.json stages.json phase105-evidence.ndjson admin-light-parity.json contrast-report.json playwright-report/index.html; do
        if [[ ! -s "$artifact_dir/$required" ]]; then
          echo "Current run is missing required browser evidence: $required" >&2
          artifact_copy_status=1
          artifact_copy_exit_code=1
        fi
      done
    fi
  elif [[ "$mode" != "--readiness-only" && "$scope" == "full" && "$readiness_started" == "1" && "$run_status" == "0" ]]; then
    echo "Successful full verification did not retain an owned browser container for artifact collection." >&2
    artifact_copy_status=1
  fi
  artifact_copy_ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  artifact_copy_exit_code="$artifact_copy_status"
  if [[ -s "$artifact_dir/phase105-playwright-list.json" && ! -e "$artifact_dir/phase105-inventory.json" ]]; then
    cp "$artifact_dir/phase105-playwright-list.json" "$artifact_dir/phase105-inventory.json" || artifact_copy_status=1
  fi
}

record_artifact_copy_stage() {
  local started ended code current base
  started="${artifact_copy_started_at:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
  ended="${artifact_copy_ended_at:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
  code="$artifact_copy_status"
  current='{"inventory":{"started_at":null,"ended_at":null,"exit_code":null},"browser":{"started_at":null,"ended_at":null,"exit_code":null},"light_parity":{"started_at":null,"ended_at":null,"exit_code":null},"contrast":{"started_at":null,"ended_at":null,"exit_code":null}}'
  if [[ -f "$artifact_dir/stages.json" && ! -L "$artifact_dir/stages.json" ]]; then
    current="$(cat "$artifact_dir/stages.json" 2>/dev/null)"
  fi
  if [[ "$current" == \{*\} ]]; then
    base="${current%?}"
    printf '%s,"artifact_copy":{"started_at":"%s","ended_at":"%s","exit_code":%s}}\n' "$base" "$started" "$ended" "$code" >"$artifact_dir/stages.json"
  else
    printf '{"artifact_copy":{"started_at":"%s","ended_at":"%s","exit_code":%s}}\n' "$started" "$ended" "$code" >"$artifact_dir/stages.json"
  fi
  printf '{"operation":"artifact_copy","started_at":"%s","ended_at":"%s","exit_code":%s}\n' \
    "$started" "$ended" "$code" >>"$artifact_dir/phase105-evidence.ndjson"
}

write_run_metadata() {
  local copied_files="" item separator
  printf '{"scope":"%s","project":"%s","run_id":"%s","validation_status":"%s","model_digest":"sha256:%s","targets":["web","standalone_ops","browser"]}\n' \
    "$scope" "$project" "$run_id" "$compose_validation_status" "$compose_model_digest" >"$artifact_dir/compose-model.json"
  for item in phase105-playwright-list.json phase105-inventory.json phase105-playwright.json phase105-evidence.ndjson phase105-evidence.json phase105-evidence-summary.md stages.json source.json compose-model.json admin-light-parity.json contrast-report.json lifecycle.json playwright-report/index.html; do
    if [[ -s "$artifact_dir/$item" ]]; then
      separator=,
      [[ -n "$copied_files" ]] || separator=""
      copied_files+="$separator\"$item\""
    fi
  done
  printf '{"run_id":"%s","source":"%s","copy_status":"%s","diagnostic_only":%s,"acceptance_eligible":false,"allowlist":["%s/phase105-playwright-list.json","%s/phase105-playwright.json","%s/phase105-evidence.ndjson","%s/playwright-report/","%s/test-results/","%s/ui-review-artifacts/iteration3-journeys/"],"copied_files":[%s]}\n' \
    "$run_id" "$E2E_CONTAINER_ARTIFACT_DIR" "$([[ "$artifact_copy_status" == 0 ]] && printf success || printf failed)" "$([[ "$mode" == "--readiness-only" ]] && printf true || printf false)" \
    "$E2E_CONTAINER_ARTIFACT_DIR" "$E2E_CONTAINER_ARTIFACT_DIR" "$E2E_CONTAINER_ARTIFACT_DIR" \
    "$E2E_CONTAINER_ARTIFACT_DIR" "$E2E_CONTAINER_ARTIFACT_DIR" "$E2E_CONTAINER_ARTIFACT_DIR" "$copied_files" >"$artifact_dir/artifact-manifest.json"
}

aggregate_full_evidence() {
  local conclusion="success"
  if (( original_exit_status != 0 || artifact_copy_status != 0 || cleanup_status != 0 )); then conclusion="failure"; fi
  if [[ ! "$browser_image_id" =~ ^sha256:[a-f0-9]{64}$ ]]; then
    echo "Strict evidence aggregation requires the immutable browser image for this run." >&2
    return 76
  fi
  run_finalization_bounded docker run --rm -i \
    -v "$artifact_dir:/evidence" \
    -e E2E_SCOPE="$scope" -e E2E_RUN_ID="$run_id" -e SCRYPATH_SOURCE_SHA="$SCRYPATH_SOURCE_SHA" \
    -e E2E_SOURCE_MODE="$E2E_SOURCE_MODE" -e E2E_SOURCE_DIRTY="$source_dirty" -e E2E_SOURCE_FINGERPRINT="$source_fingerprint" \
    -e E2E_EVENT_SHA="$E2E_EVENT_SHA" -e E2E_EVENT_NAME="$E2E_EVENT_NAME" -e E2E_GIT_REF="$E2E_GIT_REF" \
    -e E2E_WORKFLOW_RUN_ID="$E2E_WORKFLOW_RUN_ID" -e E2E_WORKFLOW_RUN_ATTEMPT="$E2E_WORKFLOW_RUN_ATTEMPT" \
    -e E2E_JOB_NAME="$E2E_JOB_NAME" -e E2E_JOB_CONCLUSION="$conclusion" \
    -e E2E_COMPOSE_PROJECT="$project" -e E2E_COMPOSE_MODEL_DIGEST="sha256:$compose_model_digest" \
    -e E2E_BROWSER_IMAGE_ID="$browser_image_id" -e E2E_APPLICATION_IMAGE_ID="$application_image_id" \
    -e E2E_PLAYWRIGHT_VERSION="$PLAYWRIGHT_VERSION" -e E2E_ARTIFACT_COPY_STARTED_AT="$artifact_copy_started_at" \
    -e E2E_ARTIFACT_COPY_ENDED_AT="$artifact_copy_ended_at" -e E2E_ARTIFACT_COPY_EXIT_CODE="$artifact_copy_status" \
    "$browser_image_id" bash -s <<'CONTAINER_SCRIPT'
set -Eeuo pipefail
node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = "/evidence";
const read = (name) => JSON.parse(fs.readFileSync(path.join(root, name), "utf8"));
const maybeRead = (name) => { try { return read(name); } catch { return null; } };
const stages = maybeRead("stages.json") || {};
stages.artifact_copy = {
  started_at: process.env.E2E_ARTIFACT_COPY_STARTED_AT || new Date().toISOString(),
  ended_at: process.env.E2E_ARTIFACT_COPY_ENDED_AT || new Date().toISOString(),
  exit_code: Number(process.env.E2E_ARTIFACT_COPY_EXIT_CODE || 1)
};
fs.writeFileSync(path.join(root, "stages.json"), `${JSON.stringify(stages)}\n`);
const lifecycle = maybeRead("lifecycle.json") || {};
const walk = (directory, prefix = "") => {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.isSymbolicLink()) throw new Error(`refusing symlink in evidence bundle: ${path.join(prefix, entry.name)}`);
    const relative = path.posix.join(prefix, entry.name);
    if (entry.isDirectory()) files.push(...walk(path.join(directory, entry.name), relative));
    else files.push(relative);
  }
  return files;
};
const allowed = (name) => name.startsWith("test-results/") || name.startsWith("playwright-report/") || name.startsWith("ui-review-artifacts/iteration3-journeys/") || name.startsWith("logs/") || name.startsWith("compose/");
const copiedFiles = walk(root).filter(allowed);
const artifacts = copiedFiles.map((name) => ({ path: name, required: false, copied: true, copy_status: "success" }));
fs.writeFileSync(path.join(root, "artifact-manifest.json"), `${JSON.stringify({run_id:process.env.E2E_RUN_ID,copied_from:`/tmp/${process.env.E2E_RUN_ID}`,copy_status:Number(process.env.E2E_ARTIFACT_COPY_EXIT_CODE||1)===0?"success":"failed",allowlist:["phase105-playwright-list.json","phase105-playwright.json","phase105-evidence.ndjson","playwright-report/","test-results/","ui-review-artifacts/iteration3-journeys/"],copied_files:copiedFiles}, null, 2)}\n`);
const status = (name) => maybeRead(name)?.status || "missing";
const failed = Object.entries(stages).filter(([, stage]) => Number.isInteger(stage?.exit_code) && stage.exit_code !== 0).sort((a,b) => Date.parse(a[1].started_at||"")-Date.parse(b[1].started_at||""))[0];
const dirty = process.env.E2E_SOURCE_DIRTY === "true";
const sourceSha = process.env.SCRYPATH_SOURCE_SHA;
const fingerprint = dirty ? process.env.E2E_SOURCE_FINGERPRINT : null;
const image = (id) => ({built_id:id,runtime_id:id,source_sha:sourceSha,source_fingerprint:fingerprint});
const input = {
  source:{mode:process.env.E2E_SOURCE_MODE,checkout_head:sourceSha,built_source_sha:sourceSha,event_sha:process.env.E2E_EVENT_SHA,dirty,dirty_fingerprint:fingerprint},
  images:{application:image(process.env.E2E_APPLICATION_IMAGE_ID),browser:image(process.env.E2E_BROWSER_IMAGE_ID)},
  compose:{scope:process.env.E2E_SCOPE,project:process.env.E2E_COMPOSE_PROJECT,targets:["browser","standalone_ops","web"],model_digest:process.env.E2E_COMPOSE_MODEL_DIGEST},
  browser:{engine:"chromium",version:process.env.E2E_PLAYWRIGHT_VERSION,package:"@playwright/test",package_version:require("@playwright/test/package.json").version},
  workflow:{event:process.env.E2E_EVENT_NAME,ref:process.env.E2E_GIT_REF,sha:process.env.E2E_EVENT_SHA,run_id:process.env.E2E_WORKFLOW_RUN_ID,run_attempt:Number(process.env.E2E_WORKFLOW_RUN_ATTEMPT),job_name:process.env.E2E_JOB_NAME,job_conclusion:process.env.E2E_JOB_CONCLUSION},
  stages,checkers:{light_parity:{path:"admin-light-parity.json",status:status("admin-light-parity.json")},contrast:{path:"contrast-report.json",status:status("contrast-report.json")}},
  cleanup:{status:lifecycle.cleanup?.status,project:lifecycle.cleanup?.project,containers:lifecycle.cleanup?.containers,networks:lifecycle.cleanup?.networks,volumes:lifecycle.cleanup?.volumes},
  allowed_skips:[],artifacts,first_failure:failed?{stage:failed[0],exit_code:failed[1].exit_code}:Number(lifecycle.original_exit_status)===0?null:{stage:"verifier",exit_code:Number(lifecycle.original_exit_status)||1}
};
fs.writeFileSync(path.join(root,"phase105-evidence-input.json"),`${JSON.stringify(input,null,2)}\n`);
NODE
node /app/scripts/ci/ecommerce_evidence.cjs write-evidence --run-dir /evidence
CONTAINER_SCRIPT
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
    run_finalization_bounded "${compose[@]}" down --volumes --remove-orphans --timeout 10
    cleanup_status=$?
    cleanup_state="clean"
  fi

  owned_containers="$(run_finalization_bounded docker ps -aq --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
  container_query_status=$?
  owned_networks="$(run_finalization_bounded docker network ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
  network_query_status=$?
  owned_volumes="$(run_finalization_bounded docker volume ls -q --filter "label=com.docker.compose.project=$project" 2>>"$artifact_dir/finalization.log")"
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
  record_artifact_copy_stage
  write_run_metadata
  echo "Verifier lifecycle: original_exit_status=$original_exit_status artifact_copy_status=$artifact_copy_status cleanup_status=$cleanup_status"
  echo "Verifier ownership: project=$project containers=$owned_containers_count networks=$owned_networks_count volumes=$owned_volumes_count cleanup=$cleanup_state"

  local evidence_status=0
  if [[ "$scope" == "full" && "$mode" != "--readiness-only" ]]; then
    aggregate_full_evidence
    evidence_status=$?
    if (( evidence_status != 0 )); then
      echo "Strict full-run evidence aggregation failed with exit $evidence_status." >&2
    fi
  fi
  if (( original_exit_status != 0 )); then
    exit "$original_exit_status"
  elif (( artifact_copy_status != 0 )); then
    exit 74
  elif (( cleanup_status != 0 )); then
    exit 75
  fi
  if (( evidence_status != 0 )); then
    exit 76
  fi
  exit 0
}
trap cleanup EXIT

if (( prebuilt_mode )); then
  if ! run_verification_bounded node "$build_helper" verify-handoff --manifest "$E2E_PREBUILT_MANIFEST"; then
    run_status=69
    echo "Prebuilt image handoff validation failed; refusing to start Compose." >&2
    exit "$run_status"
  fi
fi

echo "Validating Compose model for '$scope' verification..."
if run_verification_bounded "${compose[@]}" config --quiet; then
  compose_validation_status=0
  compose_model_digest="$(run_verification_bounded "${compose[@]}" config | hash_stdin)"
else
  run_status=$?
  compose_validation_status="$run_status"
  exit "$run_status"
fi

echo "Starting isolated Docker verifier project '$project'..."
if [[ "$mode" == "--readiness-only" ]]; then
  readiness_started=1
  run_verification_bounded "${compose[@]}" build web standalone_ops browser || run_status=$?
  if (( run_status == 0 )); then
    run_verification_bounded "${compose[@]}" run --rm -T -e E2E_READINESS_ONLY=1 browser || run_status=$?
  fi
else
  [[ "$scope" != "full" ]] || readiness_started=1
  if (( prebuilt_mode )); then
    run_verification_bounded "${compose[@]}" up --no-build --pull never --abort-on-container-exit --exit-code-from browser browser || run_status=$?
  else
    run_verification_bounded "${compose[@]}" up --build --abort-on-container-exit --exit-code-from browser browser || run_status=$?
  fi
fi

if (( prebuilt_mode )) && (( run_status == 0 )); then
  run_verification_bounded node "$build_helper" verify-handoff --manifest "$E2E_PREBUILT_MANIFEST" --runtime || run_status=$?
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
