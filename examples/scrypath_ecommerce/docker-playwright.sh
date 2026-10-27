#!/usr/bin/env bash

set -euo pipefail

scope="${E2E_SCOPE:-focused}"
base_url="${PLAYWRIGHT_BASE_URL:-http://web:4002}"
readiness_only="${E2E_READINESS_ONLY:-0}"
run_id="${E2E_RUN_ID:-local-${scope}}"
artifact_dir="${E2E_ARTIFACT_DIR:-/tmp/scrypath-e2e-${run_id}}"

if [[ "$readiness_only" != "0" && "$readiness_only" != "1" ]]; then
  echo "E2E_READINESS_ONLY must be 0 or 1." >&2
  exit 64
fi
if [[ "$readiness_only" == "1" && "$scope" != "full" ]]; then
  echo "Readiness-only diagnostics require full scope." >&2
  exit 64
fi
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]; then
  echo "E2E_RUN_ID must contain only letters, digits, dot, underscore or dash." >&2
  exit 64
fi
if [[ "$artifact_dir" != /* || "${artifact_dir##*/}" != "$run_id" || "$artifact_dir" == *"/../"* || "$artifact_dir" == */.. ]]; then
  echo "E2E_ARTIFACT_DIR must be an absolute, run-owned directory ending in E2E_RUN_ID." >&2
  exit 64
fi

mkdir -p "$(dirname "$artifact_dir")"
if [[ -e "$artifact_dir" ]]; then
  echo "Refusing to reuse existing browser evidence directory: $artifact_dir" >&2
  exit 73
fi
mkdir -m 700 "$artifact_dir"

# Docker builds copy the checkout, so remove only the generated locations this
# verifier owns before the run. The containing browser container is disposable.
rm -rf "$PWD/playwright-report" "$PWD/test-results/phase105-playwright.json" \
  "$PWD/test-results/phase105-playwright-list.json" "$PWD/test-results/phase105-inventory.json" \
  "$PWD/test-results/admin-screenshots" "$PWD/ui-review-artifacts/iteration3-journeys"
mkdir -p "$PWD/test-results" "$PWD/ui-review-artifacts"
: >"$artifact_dir/phase105-evidence.ndjson"
E2E_ARTIFACT_DIR="$artifact_dir" node -e 'const fs = require("node:fs"); const root = process.env.E2E_ARTIFACT_DIR; const initial = Object.fromEntries(["inventory", "browser", "light_parity", "contrast"].map((name) => [name, {started_at:null, ended_at:null, exit_code:null}])); fs.writeFileSync(`${root}/stages.json`, `${JSON.stringify(initial)}\n`);'

record_stage() {
  local name="$1" code="$2" started="$3" ended="$4"
  E2E_STAGE_NAME="$name" E2E_STAGE_CODE="$code" E2E_STAGE_STARTED="$started" E2E_STAGE_ENDED="$ended" E2E_ARTIFACT_DIR="$artifact_dir" node -e '
    const fs = require("node:fs");
    const path = require("node:path");
    const root = process.env.E2E_ARTIFACT_DIR;
    const file = path.join(root, "stages.json");
    const stages = JSON.parse(fs.readFileSync(file, "utf8"));
    stages[process.env.E2E_STAGE_NAME] = {
      started_at: process.env.E2E_STAGE_STARTED,
      ended_at: process.env.E2E_STAGE_ENDED,
      exit_code: Number(process.env.E2E_STAGE_CODE)
    };
    fs.writeFileSync(file, `${JSON.stringify(stages)}\n`);
    fs.appendFileSync(path.join(root, "phase105-evidence.ndjson"), `${JSON.stringify({operation: process.env.E2E_STAGE_NAME, started_at: process.env.E2E_STAGE_STARTED, ended_at: process.env.E2E_STAGE_ENDED, exit_code: Number(process.env.E2E_STAGE_CODE)})}\n`);
  '
}

mark_stage_failure() {
  local name="$1" code="$2"
  E2E_STAGE_NAME="$name" E2E_STAGE_CODE="$code" E2E_ARTIFACT_DIR="$artifact_dir" node -e '
    const fs = require("node:fs");
    const path = require("node:path");
    const root = process.env.E2E_ARTIFACT_DIR;
    const file = path.join(root, "stages.json");
    const stages = JSON.parse(fs.readFileSync(file, "utf8"));
    const stage = stages[process.env.E2E_STAGE_NAME] || {};
    stage.ended_at = new Date().toISOString();
    stage.exit_code = Number(process.env.E2E_STAGE_CODE);
    stages[process.env.E2E_STAGE_NAME] = stage;
    fs.writeFileSync(file, `${JSON.stringify(stages)}\n`);
    fs.appendFileSync(path.join(root, "phase105-evidence.ndjson"), `${JSON.stringify({operation: process.env.E2E_STAGE_NAME, ended_at: stage.ended_at, exit_code: stage.exit_code})}\n`);
  '
}

stage_remaining_seconds() {
  local now deadline reserve cutoff
  now="$(date +%s)"
  deadline="${E2E_DEADLINE_EPOCH:-0}"
  reserve="${E2E_FINALIZATION_MARGIN_SECONDS:-300}"
  if [[ ! "$deadline" =~ ^[0-9]+$ || ! "$reserve" =~ ^[0-9]+$ || "$deadline" == "0" ]]; then
    echo "A positive E2E_DEADLINE_EPOCH and non-negative finalization margin are required." >&2
    return 64
  fi
  cutoff=$((deadline - reserve))
  if (( cutoff <= now )); then
    echo "The full-browser execution deadline has expired or left no finalization margin." >&2
    return 124
  fi
  echo $((cutoff - now))
}

run_stage() {
  local name="$1" output="$2"
  shift 2
  local started ended remaining code
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if remaining="$(stage_remaining_seconds)"; then
    if command -v timeout >/dev/null 2>&1; then
      timeout --signal=TERM --kill-after=10 "${remaining}s" "$@" >"$output" 2>&1
      code=$?
    else
      "$@" >"$output" 2>&1 &
      local pid=$! cutoff=$((SECONDS + remaining)) state
      code=0
      while kill -0 "$pid" 2>/dev/null; do
        state="$(ps -o stat= -p "$pid" 2>/dev/null || true)"
        [[ -n "$state" && "$state" != Z* ]] || break
        if (( SECONDS >= cutoff )); then
          kill -TERM "$pid" 2>/dev/null || true
          sleep 1
          kill -KILL "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true
          code=124
          break
        fi
        sleep 1
      done
      if (( code == 0 )); then wait "$pid"; code=$?; fi
    fi
  else
    code=$?
  fi
  ended="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  record_stage "$name" "$code" "$started" "$ended"
  return "$code"
}

if [[ "$scope" == "full" ]]; then
  readiness_timeout="${E2E_READINESS_TIMEOUT_SECONDS:-180}"
  curl_timeout="${E2E_CURL_TIMEOUT_SECONDS:-5}"
  if [[ ! "$readiness_timeout" =~ ^[1-9][0-9]*$ || ! "$curl_timeout" =~ ^[1-9][0-9]*$ ]]; then
    echo "E2E readiness and curl timeouts must be positive whole seconds." >&2
    exit 64
  fi

  readiness_remaining="$(stage_remaining_seconds)" || exit $?
  if (( readiness_remaining < readiness_timeout )); then readiness_timeout="$readiness_remaining"; fi
  deadline=$((SECONDS + readiness_timeout))
  curl_before_deadline() {
    local url="$1"
    local remaining=$((deadline - SECONDS))
    local request_timeout="$curl_timeout"
    if (( remaining <= 0 )); then
      return 1
    fi
    if (( remaining < request_timeout )); then
      request_timeout="$remaining"
    fi
    curl --silent --fail --max-time "$request_timeout" "$url" >/dev/null 2>&1
  }

  echo "Confirming the mounted web service is stable at $base_url within ${readiness_timeout}s..."
  ready_count=0
  while (( SECONDS < deadline && ready_count < 3 )); do
    if curl_before_deadline "${base_url%/}/"; then
      ready_count=$((ready_count + 1))
    else
      ready_count=0
    fi
    if (( ready_count < 3 && SECONDS < deadline )); then
      sleep 1
    fi
  done
  if (( ready_count < 3 )); then
    echo "Mounted web service did not remain ready for three consecutive checks before the readiness deadline." >&2
    exit 70
  fi

  wait_for_fixture_route() {
    local label="$1"
    local url="$2"
    while (( SECONDS < deadline )); do
      if curl_before_deadline "$url"; then
        echo "$label fixture route is ready: $url"
        return 0
      fi
      if (( SECONDS < deadline )); then
        sleep 1
      fi
    done
    echo "Timed out waiting for $label fixture route $url before the ${readiness_timeout}s readiness deadline." >&2
    return 70
  }

  mounted_ops_url="${base_url%/}/admin/search/phase173/health"
  standalone_base_url="${PHASE173_STANDALONE_BASE_URL:-http://standalone_ops:4003}"
  standalone_ops_url="${standalone_base_url%/}/ops/phase173/health"
  wait_for_fixture_route "Mounted Ops" "$mounted_ops_url" || exit $?
  wait_for_fixture_route "Standalone Ops" "$standalone_ops_url" || exit $?
else
  echo "Confirming the mounted web service is stable at $base_url..."
  ready_count=0
  for _attempt in $(seq 1 60); do
    if curl --silent --fail --max-time 5 "$base_url/" >/dev/null; then
      ready_count=$((ready_count + 1))
      if (( ready_count >= 3 )); then
        break
      fi
    else
      ready_count=0
    fi
    sleep 1
  done

  if (( ready_count < 3 )); then
    echo "Mounted web service did not remain ready for three consecutive checks." >&2
    exit 70
  fi
fi

if [[ "$readiness_only" == "1" ]]; then
  echo "Readiness-only diagnostic passed; Playwright and full-browser acceptance were not run."
  exit 0
fi

case "$scope" in
  phase173_shell)
    echo "Running Phase 173 shell proof against mounted and standalone PostureLive..."
    exec npx playwright test e2e/phase173_shell.spec.ts --workers=1 --retries=0
    ;;
  phase173_time)
    echo "Running Phase 173 operational-time proof against mounted and standalone PostureLive..."
    exec npx playwright test e2e/phase173_time.spec.ts --workers=1 --retries=0
    ;;
  phase173_status)
    echo "Running Phase 173 status and action proof against mounted and standalone PostureLive..."
    exec npx playwright test e2e/phase173_status_actions.spec.ts --workers=1 --retries=0
    ;;
  phase173_copy)
    echo "Running Phase 173 timestamp-copy proof against mounted and standalone PostureLive..."
    exec npx playwright test e2e/phase173_copy.spec.ts --workers=1 --retries=0
    ;;
  focused)
    echo "Running focused mounted integration/browser proof..."
    exec npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1 --retries=0
    ;;
  full)
    echo "Running the full advisory ecommerce browser and deterministic visual lane..."
    browser_status=0
    light_status=0
    contrast_status=0
    export E2E_ARTIFACT_DIR="$artifact_dir"
    export E2E_PLAYWRIGHT_REPORT="$artifact_dir/phase105-playwright.json"
    export E2E_HTML_REPORT_DIR="$artifact_dir/playwright-report"
    export E2E_PLAYWRIGHT_OUTPUT_DIR="$artifact_dir/test-results"
    export ADMIN_SCREENSHOT_DIR="$artifact_dir/test-results/admin-screenshots"
    export ADMIN_LIGHT_PARITY_REPORT="$artifact_dir/admin-light-parity.json"
    export CONTRAST_REPORT_DIR="$artifact_dir/test-results/contrast"

    inventory_started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    run_stage inventory "$artifact_dir/phase105-playwright-list.json" \
      npx playwright test --config "$PWD/playwright.config.ts" --project=chromium \
      --workers=1 --retries=0 --list --reporter=json || browser_status=$?
    if (( browser_status == 0 )); then
      if ! cp "$artifact_dir/phase105-playwright-list.json" "$artifact_dir/phase105-inventory.json"; then browser_status=74; fi
    fi
    if (( browser_status == 0 )); then
      node -e '
        const fs = require("node:fs");
        const report = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const count = (suites) => (suites || []).reduce((n, suite) => n + (suite.specs || []).length + count(suite.suites || []), 0);
        if (!report || !Array.isArray(report.suites) || count(report.suites) < 1 || (report.errors || []).length) process.exit(65);
      ' "$artifact_dir/phase105-playwright-list.json" || browser_status=65
    fi
    if (( browser_status != 0 )); then mark_stage_failure inventory "$browser_status"; fi

    if (( browser_status == 0 )); then
      run_stage browser "$artifact_dir/browser.log" \
        npm run test:e2e -- --config "$PWD/playwright.config.ts" --project=chromium --workers=1 --retries=0 || browser_status=$?
      if (( browser_status == 0 )) && { [[ ! -s "$E2E_PLAYWRIGHT_REPORT" ]] || [[ ! -s "$E2E_HTML_REPORT_DIR/index.html" ]]; }; then
        echo "Full browser execution did not produce its current-run JSON and HTML reports." >&2
        browser_status=74
        mark_stage_failure browser "$browser_status"
      fi
    fi

    if [[ -d "$PWD/ui-review-artifacts/iteration3-journeys" ]]; then
      mkdir -p "$artifact_dir/ui-review-artifacts"
      cp -a "$PWD/ui-review-artifacts/iteration3-journeys" "$artifact_dir/ui-review-artifacts/"
    fi

    run_stage light_parity "$artifact_dir/light-parity.log" \
      npm run test:e2e:admin-light-parity || light_status=$?
    run_stage contrast "$artifact_dir/contrast.log" node contrast-checker.mjs || contrast_status=$?
    if [[ -s "$artifact_dir/test-results/contrast/contrast-report.token.json" ]]; then
      cp "$artifact_dir/test-results/contrast/contrast-report.token.json" "$artifact_dir/contrast-report.json"
    fi

    if (( browser_status == 0 && light_status == 0 && contrast_status == 0 )); then
      exit 0
    fi

    printf 'Full E2E failures: inventory_or_browser=%s light_parity=%s contrast=%s\n' \
      "$browser_status" "$light_status" "$contrast_status" >&2
    if (( browser_status != 0 )); then exit "$browser_status"; fi
    if (( light_status != 0 )); then exit "$light_status"; fi
    exit "$contrast_status"
    ;;
  *)
    echo "Unsupported E2E_SCOPE '$scope' (expected phase173_shell, phase173_time, phase173_status, phase173_copy, focused, or full)." >&2
    exit 64
    ;;
esac
