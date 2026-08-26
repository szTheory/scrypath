defmodule Scrypath.Phase147E2EContractTest do
  use ExUnit.Case, async: true

  @moduletag :phase147_e2e_contract

  @example "examples/scrypath_ecommerce"
  @makefile File.read!(Path.join(@example, "Makefile"))
  @compose_base File.read!(Path.join(@example, "compose.yaml"))
  @compose File.read!(Path.join(@example, "compose.e2e.yaml"))
  @runner File.read!(Path.join(@example, "scripts/verify-e2e.sh"))
  @browser_runner File.read!(Path.join(@example, "docker-playwright.sh"))
  @runtime_config File.read!(Path.join(@example, "config/runtime.exs"))
  @ci File.read!(".github/workflows/ci.yml")
  @contributing File.read!("CONTRIBUTING.md")

  test "focused and full verification share one zero-touch Docker lifecycle" do
    assert @makefile =~ "verify-mounted:"
    assert @makefile =~ "./scripts/verify-e2e.sh focused"
    assert @makefile =~ "verify-e2e:"
    assert @makefile =~ "./scripts/verify-e2e.sh full"

    assert @compose =~ "ports: !reset []"
    assert @compose =~ "PLAYWRIGHT_BASE_URL: http://web:4002"

    assert @compose =~
             "SCRYPATH_OPS_PLAYBOOK_DIR: /app/examples/scrypath_ecommerce/priv/playbooks"

    assert @compose =~ "e2e_playbooks:/app/examples/scrypath_ecommerce/priv/playbooks"
    assert @compose =~ "condition: service_healthy"

    assert @compose_base =~ "start_period: 5m"
    assert @compose_base =~ "retries: 60"

    assert @runner =~ "--abort-on-container-exit"
    assert @runner =~ "--exit-code-from browser"
    assert @runner =~ "down --volumes --remove-orphans"
    assert @runner =~ "KEEP_E2E_STACK"

    assert @browser_runner =~ "e2e/harness.spec.ts e2e/operator.spec.ts"
    assert @browser_runner =~ "ready_count >= 3"
    assert @browser_runner =~ "curl --silent --fail --max-time 5"
    assert @browser_runner =~ "npm run test:e2e"
    assert @browser_runner =~ "npm run test:e2e:admin-light-parity"
    assert @browser_runner =~ "node contrast-checker.mjs"

    assert @runtime_config =~ "SCRYPATH_OPS_PLAYBOOK_DIR"
    assert @runtime_config =~ "config :scrypath_ops, playbook_workspace_dir: Path.expand(path)"
  end

  test "Playwright image version matches the resolved package lock" do
    lock = @example |> Path.join("package-lock.json") |> File.read!() |> Jason.decode!()
    resolved = get_in(lock, ["packages", "node_modules/@playwright/test", "version"])
    dockerfile = File.read!(Path.join(@example, "Dockerfile.e2e"))

    assert resolved == "1.60.0"
    assert dockerfile =~ "ARG PLAYWRIGHT_VERSION=#{resolved}"
    assert dockerfile =~ "mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble"
  end

  test "focused job is uniquely required while full E2E remains advisory" do
    assert @ci =~ "ecommerce-mounted:"
    assert @ci =~ "name: ecommerce-mounted (required)"
    assert @ci =~ "mix verify.ecommerce_mounted"
    assert @ci =~ "ecommerce-mounted-artifacts"

    assert @contributing =~ "**`ecommerce-mounted`**"
    assert @contributing =~ "`ecommerce-e2e` is advisory today"
    refute @contributing =~ "phase105-e2e is now required"
  end
end
