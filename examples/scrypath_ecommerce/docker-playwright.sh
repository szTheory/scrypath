#!/usr/bin/env bash

set -euo pipefail

scope="${E2E_SCOPE:-focused}"
base_url="${PLAYWRIGHT_BASE_URL:-http://web:4002}"
playbook_dir="/app/examples/scrypath_ecommerce/priv/playbooks"

# Both containers share this disposable volume. Seed it here so browser-side
# cleanup and server-side playbook writes observe the same files.
if ! find "$playbook_dir" -maxdepth 1 -name '*.json' -print -quit | grep --quiet .; then
  cp /opt/scrypath-e2e-playbooks/*.json "$playbook_dir/"
fi

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

case "$scope" in
  focused)
    echo "Running focused mounted integration/browser proof..."
    exec npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1 --retries=0
    ;;
  phase173-shell)
    echo "Running the shared-shell production LiveView and preference contract proof..."
    exec npx playwright test e2e/phase173_shell.spec.ts --workers=1 --retries=0
    ;;
  phase173-time)
    echo "Running exact operational time and evidence disclosure proof..."
    PLAYWRIGHT_JUNIT_OUTPUT_NAME=test-results/phase173-time.xml \
      exec npx playwright test e2e/phase173_time.spec.ts --workers=1 --retries=0 --reporter=junit
    ;;
  phase173-status)
    echo "Running production status and quiet-action proof..."
    PLAYWRIGHT_JUNIT_OUTPUT_NAME=test-results/phase173-status.xml \
      exec npx playwright test e2e/phase173_status_actions.spec.ts --workers=1 --retries=0 --reporter=junit
    ;;
  phase173-copy)
    echo "Running production timestamp-copy proof..."
    PLAYWRIGHT_JUNIT_OUTPUT_NAME=test-results/phase173-copy.xml \
      exec npx playwright test e2e/phase173_copy.spec.ts --workers=1 --retries=0 --reporter=junit
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
    echo "Unsupported E2E_SCOPE '$scope' (expected focused, phase173-shell, phase173-time, phase173-status, phase173-copy, or full)." >&2
    exit 64
    ;;
esac
