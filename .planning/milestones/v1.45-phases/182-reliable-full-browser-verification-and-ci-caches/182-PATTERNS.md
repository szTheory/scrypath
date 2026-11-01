# Phase 182: Reliable full browser verification and CI caches - Pattern Map

**Mapped:** 2026-10-26  
**Files analyzed:** 10 named implementation paths  
**Analogs found:** 10 / 10 (no direct precedent for the implied strict reconciler, Bake handoff, or safe cache split)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven / batch | `.github/workflows/ci.yml` | exact baseline |
| `examples/scrypath_ecommerce/scripts/verify-e2e.sh` | utility | batch / file-I/O | `examples/scrypath_ecommerce/scripts/verify-phase173.sh` | role + flow |
| `examples/scrypath_ecommerce/docker-playwright.sh` | utility | batch | same file; `playwright.config.ts` | exact baseline |
| `examples/scrypath_ecommerce/playwright.config.ts` | config | batch | same file | exact baseline |
| `examples/scrypath_ecommerce/e2e/ui_followup.spec.ts` | test | request-response | `e2e/ui_baseline.spec.ts` | role + flow |
| `examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts` | test | request-response / file-I/O screenshots | `e2e/ui_baseline.spec.ts` | role-match |
| `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts` | test | request-response / file-I/O screenshots | `lib/scrypath/oban/job_args.ex` for the error-tag contract | partial |
| `scripts/ci/phase105_evidence.sh` (or one coherent replacement) | utility | file-I/O / transform | `e2e/admin-light-baseline-check.mjs` | partial |
| `test/mix/tasks/workflow_wiring_test.exs` | test | file-I/O / contract | same file | exact baseline |
| `test/mix/tasks/verify_capability_test.exs` | test | file-I/O / task dispatch | same file | exact baseline |

## Pattern Assignments

### `examples/scrypath_ecommerce/scripts/verify-e2e.sh` (utility, batch / file-I/O)

**Analogs:** `examples/scrypath_ecommerce/scripts/verify-phase173.sh` for bounded readiness and cleanup; current `verify-e2e.sh` for canonical invocation and scope ownership.

The current verifier builds one project name and Compose argv, then validates and starts that project:

```bash
# verify-e2e.sh:23-27
sha="$(git rev-parse --short=8 HEAD 2>/dev/null || printf 'workspace')"
safe_sha="$(printf '%s' "$sha" | tr -cd '[:alnum:]_-')"
project="scrypath_ecommerce_verify_${scope}_${safe_sha}_$$"
artifact_dir="$example_dir/test-results/docker-${scope}"
compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml)
```

For the fuller readiness/teardown pattern, `verify-phase173.sh` uses an explicit bounded URL probe and preserves the first failing status:

```bash
# verify-phase173.sh:77-100
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
...
wait_for_service_url web "$mounted_url"
wait_for_service_url standalone_ops "$standalone_url"
```

```bash
# verify-phase173.sh:51-70
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
  if (( original_status != 0 )); then exit "$original_status"; fi
  exit "$cleanup_status"
}
```

Append `compose.phase173.yaml` only for `full`, retaining the same unique project. The current E2E verifier already validates the model, gathers logs before teardown, and preserves the original failure, but suppresses report-copy failures and checks only leftover containers (`verify-e2e.sh:36-47, 50-72, 76-84`). Reuse the Phase 173 volume/network check and route-specific waits; keep `KEEP_E2E_STACK=1` as the explicit debug escape.

### `examples/scrypath_ecommerce/docker-playwright.sh` and `playwright.config.ts` (utility/config, batch)

**Analogs:** current `docker-playwright.sh`, `playwright.config.ts`, and `package.json`.

The config is already the serial, single Chromium source of truth and retains failure traces. Use it for both inventory and actual execution, with the same config and project selection:

```typescript
// playwright.config.ts:3-23
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  retries: 0,
  workers: 1,
  use: { baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002", trace: "retain-on-failure" },
  reporter: process.env.CI
    ? [["list"], ["html", { open: "never" }], ["json", { outputFile: "test-results/phase105-playwright.json" }]]
    : "list",
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }]
});
```

`package.json:10-12` provides the current execution and discovery forms: `playwright test --workers=1` and `playwright test --list`. `docker-playwright.sh:44-57` runs the full unfiltered suite before deterministic follow-ups and gathers each command's status; keep one browser invocation and do not turn discovery into a substitute for execution.

### `e2e/ui_followup.spec.ts` and `e2e/ui_iteration3.spec.ts` (test, request-response)

**Analog:** `examples/scrypath_ecommerce/e2e/ui_baseline.spec.ts`.

The current guard is hostname-aware and scopes the refusal to the retained loopback preview on port 4002:

```typescript
// ui_baseline.spec.ts:5-7
test.beforeEach(async ({ baseURL }) => {
  test.skip(!baseURL || (["127.0.0.1", "localhost"].includes(new URL(baseURL).hostname) && new URL(baseURL).port === "4002"), "Use the isolated Docker verifier or a dedicated local port.");
});
```

Apply this truth table consistently to both follow-up suites: Docker's `http://web:4002` runs; the retained localhost/127.0.0.1 preview on 4002 skips before fixture mutations; an explicitly isolated local port remains usable. Existing follow-up guards are port-only (`ui_followup.spec.ts:7-9`, `ui_iteration3.spec.ts:5-7`), which wrongly catches Docker's internal port.

### `e2e/admin_screenshots.spec.ts` (test, request-response)

**Analog:** `lib/scrypath/oban/job_args.ex` for the source error classification.

The browser assertion currently expects `unknown_module` at `admin_screenshots.spec.ts:54-59`. The decoder distinguishes unknown backend from unknown schema and tags backend lookup accordingly:

```elixir
# lib/scrypath/oban/job_args.ex:16-30
@type tag ::
        {:unknown_schema, String.t()}
        | {:unknown_backend, String.t()}
...
with {:ok, schema} <- fetch_schema(args),
     {:ok, backend} <- fetch_module(args, "backend", :unknown_backend, &full_backend?/1),
```

Reconcile the expected text against the rendered fixture using this contract; retain the unknown/unavailable versus healthy/empty distinction.

### `scripts/ci/phase105_evidence.sh` (utility, file-I/O / transform)

**Analog:** `examples/scrypath_ecommerce/e2e/admin-light-baseline-check.mjs` for explicit inputs, deterministic report writing, and isolated self-tests.

That checker derives paths from arguments/defaults, writes a versioned report, and returns a result from a pure-ish check function (`admin-light-baseline-check.mjs:25-30, 61-77`). Its self-test creates temporary inputs and checks pass and fail outcomes (`:80-114`). This is a good small-script/report test shape for strict synthetic Playwright reports and artifact-copy failures.

The current Phase 105 evidence script is the legacy evidence authority, not a strictness pattern to copy. Its `readJson` returns `null` for malformed/missing files and `readNdjson` returns `[]` (`phase105_evidence.sh:47-66`); it then writes summary JSON and Markdown (`:252-253`). Keep one authoritative aggregate, make missing/malformed required input fail eligibility, and derive the readable summary from that aggregate.

### `.github/workflows/ci.yml` (config, event-driven / batch)

**Analogs:** current workflow cache steps, `ecommerce-e2e` advisory job, and the tracked Dockerfiles used by that job.

Current Mix cache steps combine `deps` and `_build` and key only root `mix.lock` / `mix.exs`; example at `ci.yml:28-35`:

```yaml
- uses: actions/cache@caa296126883cff596d87d8935842f9db880ef25 # v5
  with:
    path: |-
      deps
      _build
    key: ${{ runner.os }}-test-elixir-1.19.0-otp-28.1-${{ hashFiles('mix.lock', 'mix.exs') }}
- run: mix deps.get
```

Cache behavior is repeated across the BEAM jobs. Keep `mix deps.get` and verification after restore; key resolved outputs by the full applicable graph, platform, exact Elixir/OTP, and env/target/profile. Separate any compatible download-archive fallback from strict resolved `deps`/`_build` reuse. The local graph includes path dependencies (`scrypath_ops/mix.exs:41-45`, ecommerce `mix.exs:34-42`).

The existing Docker application recipe preserves manifest-before-source ordering (`examples/scrypath_ecommerce/Dockerfile:18-32`), and the browser recipe copies its package lock before full source (`Dockerfile.e2e:7-11`). Preserve that cache-friendly layer structure. `ci.yml:341-366` is the existing scheduled/manual advisory lane and seven-day artifact upload to extend; raw verifier step outcome must remain distinct from the advisory job conclusion.

### `test/mix/tasks/workflow_wiring_test.exs` (test, file-I/O / contract)

**Analog:** the existing ExUnit workflow contract blocks in the same file.

Current tests extract a workflow job block and assert canonical routing, then assert source wiring in shell/config files (`workflow_wiring_test.exs:463-525`). Cache coverage currently checks action-pin count only (`:178-181`). Keep tests in this repository-contract lane, but add behavioral cases for service scope, guard truth table, inventory/result identity, retries/skips/duplicates, missing reports, copy failure, and cache-key invalidation. Use synthetic reports or Docker command doubles; string presence alone cannot prove those behaviors.

### `test/mix/tasks/verify_capability_test.exs` (test, file-I/O / task dispatch)

**Analog:** the existing canonical capability vocabulary and strict-argument cases in the same file.

The test currently confirms that the mounted and full E2E task modules remain part of the canonical capability set (`verify_capability_test.exs:4-21, 31-53`). Keep this check if wiring assertions are adjusted so the Make and Mix entrypoints stay on the approved full/focused commands.

## Shared Patterns

### Disposable Compose lifecycle

**Sources:** `examples/scrypath_ecommerce/scripts/verify-e2e.sh:23-27, 36-47, 50-72`; `examples/scrypath_ecommerce/scripts/verify-phase173.sh:51-100`.

Use one unique project and one Compose argv for validate, up, diagnostics, and down. Collect before teardown; preserve the first failure; check owned containers, volumes, and networks afterwards. Full scope adds the standalone overlay and waits on both fixture routes. Focused scope stays on its existing model.

### Playwright execution and artifacts

**Sources:** `playwright.config.ts:3-23`; `docker-playwright.sh:44-69`; `verify-e2e.sh:36-47`.

Keep one serial, zero-retry Chromium run and the built-in JSON/HTML reporters. Copy only run-owned reports/screenshots/traces before teardown. Required report/copy failures block clean eligibility without replacing an earlier browser failure.

### Cache boundaries

**Sources:** `.github/workflows/ci.yml:28-35`; `examples/scrypath_ecommerce/Dockerfile:18-32`; root/Ops/ecommerce Mix dependency declarations at `mix.exs:108-123`, `scrypath_ops/mix.exs:41-45`, and `examples/scrypath_ecommerce/mix.exs:34-42`.

Separate cache concerns by portability: stable recipe-specific Docker GHA scopes for the app/browser images; only verified download archives may omit locks within matching platform/toolchain/env/graph; compiled BEAM/deps reuse needs strict lock and toolchain boundaries. Caches accelerate normal commands and never decide whether resolution, compilation, tests, or verification run.

## No Analog Found

| Needed capability | Gap |
|---|---|
| Strict Playwright inventory-to-JSON reconciliation by file/title/project identity, attempts, skips and retry status | `playwright test --list` and JSON output exist, but no tracked helper compares the discovered inventory to every executed result. The legacy evidence script tolerates missing/malformed input. Keep the checker inside the one evidence authority or define one new helper; do not create a second receipt authority. |
| Compose-derived Bake prebuild with checked source/image handoff and no-build Compose execution | No tracked workflow currently runs Buildx Bake or verifies a prebuilt image handoff. The local verifier uses `compose up --build` (`verify-e2e.sh:79-80`). Implement from the approved research and prove resolved-model, tag, source, and runtime-image parity before relying on it. |
| Correctly split Hex download fallback from compiled BEAM cache reuse | Current CI combines `deps` and `_build` under root-only lock keys. No existing safe split/cache-key helper is present. |

## Metadata

**Analog search scope:** `.github/workflows/ci.yml`, `examples/scrypath_ecommerce/{scripts,e2e,*.yaml,Dockerfile*}`, `scripts/ci`, `test/mix/tasks`, Mix manifests, and the relevant job-argument decoder.  
**Tracked-source gate:** All named analogs were confirmed by `git ls-files`; no ignored runtime mirror paths are referenced.  
**Project skills:** No `.codex/skills/` or `.agents/skills/` directories contained project skills.
