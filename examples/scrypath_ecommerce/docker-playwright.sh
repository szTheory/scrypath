#!/usr/bin/env bash

set -euo pipefail

scope="${E2E_SCOPE:-focused}"
base_url="${PLAYWRIGHT_BASE_URL:-http://web:4002}"
readiness_only="${E2E_READINESS_ONLY:-0}"

if [[ "$readiness_only" != "0" && "$readiness_only" != "1" ]]; then
  echo "E2E_READINESS_ONLY must be 0 or 1." >&2
  exit 64
fi
if [[ "$readiness_only" == "1" && "$scope" != "full" ]]; then
  echo "Readiness-only diagnostics require full scope." >&2
  exit 64
fi

if [[ "$scope" == "full" ]]; then
  readiness_timeout="${E2E_READINESS_TIMEOUT_SECONDS:-180}"
  curl_timeout="${E2E_CURL_TIMEOUT_SECONDS:-5}"
  if [[ ! "$readiness_timeout" =~ ^[1-9][0-9]*$ || ! "$curl_timeout" =~ ^[1-9][0-9]*$ ]]; then
    echo "E2E readiness and curl timeouts must be positive whole seconds." >&2
    exit 64
  fi

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
    judge_status=0

    npm run test:e2e || browser_status=$?
    npm run test:e2e:admin-light-parity || light_status=$?
    node contrast-checker.mjs || contrast_status=$?

    if [[ "${OPS_UI_LLM_JUDGE:-0}" == "1" || "${OPS_UI_LLM_JUDGE_REQUIRED:-0}" == "1" ]]; then
      npm run test:e2e:ops-ui-visual-judge || judge_status=$?
    fi

    if (( browser_status == 0 && light_status == 0 && contrast_status == 0 && judge_status == 0 )); then
      exit 0
    fi

    printf 'Full E2E failures: browser=%s light_parity=%s contrast=%s visual_judge=%s\n' \
      "$browser_status" "$light_status" "$contrast_status" "$judge_status" >&2
    exit 1
    ;;
  *)
    echo "Unsupported E2E_SCOPE '$scope' (expected phase173_shell, phase173_time, phase173_status, phase173_copy, focused, or full)." >&2
    exit 64
    ;;
esac
