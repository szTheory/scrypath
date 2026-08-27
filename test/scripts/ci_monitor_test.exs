defmodule Scrypath.CIMonitorTest do
  use ExUnit.Case, async: true

  @script "scripts/ci_monitor.cjs"
  @sha "0123456789abcdef0123456789abcdef01234567"

  setup do
    root =
      Path.join(System.tmp_dir!(), "scrypath-ci-monitor-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    state = Path.join(root, "state")
    gh = Path.join(root, "gh")
    git = Path.join(root, "git")

    File.write!(gh, fake_gh())
    File.write!(git, fake_git())
    File.chmod!(gh, 0o755)
    File.chmod!(git, 0o755)

    on_exit(fn -> File.rm_rf!(root) end)
    %{gh: gh, git: git, state: state}
  end

  test "closeout accepts only the newly dispatched exact-SHA run and both artifacts", ctx do
    {output, 0} = run_closeout(ctx, "success")
    payload = Jason.decode!(output)

    assert payload["authority"] == "github-actions-exact-sha"
    assert payload["head_sha"] == @sha
    assert payload["run_id"] == 123
    assert payload["coverage_artifact"]["digest"] == "sha256:coverage"
    assert payload["closeout_artifact"]["digest"] == "sha256:closeout"
  end

  test "closeout fails closed when a required job fails", ctx do
    {output, status} = run_closeout(ctx, "failed_job")

    assert status != 0
    assert output =~ "backend (required) must have exactly one successful job"
  end

  test "closeout fails closed when an exact-SHA artifact is missing", ctx do
    {output, status} = run_closeout(ctx, "missing_artifact")

    assert status != 0
    assert output =~ "expected exactly one live closeout-attestation-#{@sha} artifact"
  end

  test "protect reconciles only the required status-check contract", ctx do
    {output, 0} =
      System.cmd(
        System.find_executable("node") || "node",
        [@script, "protect", "--branch", "main", "--apply"],
        env: [
          {"GH_BIN", ctx.gh},
          {"GIT_BIN", ctx.git},
          {"FAKE_STATE", ctx.state},
          {"FAKE_SCENARIO", "protection"},
          {"FAKE_SHA", @sha}
        ],
        stderr_to_stdout: true
      )

    payload = Jason.decode!(output)
    assert payload["applied"]
    assert payload["converged"]

    assert Enum.map(payload["after"]["checks"], & &1["context"]) == [
             "backend (required)",
             "core (required)",
             "ecommerce-mounted (required)",
             "package (required)",
             "repository-contracts (required)"
           ]
  end

  defp run_closeout(ctx, scenario) do
    System.cmd(
      System.find_executable("node") || "node",
      [
        @script,
        "closeout",
        "--branch",
        "gsd/test",
        "--sha",
        @sha,
        "--timeout-seconds",
        "2",
        "--poll-seconds",
        "0"
      ],
      env: [
        {"GH_BIN", ctx.gh},
        {"GIT_BIN", ctx.git},
        {"FAKE_STATE", ctx.state},
        {"FAKE_SCENARIO", scenario},
        {"FAKE_SHA", @sha}
      ],
      stderr_to_stdout: true
    )
  end

  defp fake_git do
    ~S"""
    #!/bin/sh
    case "$1" in
      branch) printf '%s\n' 'gsd/test' ;;
      rev-parse) printf '%s\n' "$FAKE_SHA" ;;
      ls-remote) printf '%s\t%s\n' "$FAKE_SHA" 'refs/heads/gsd/test' ;;
      push) exit 0 ;;
      *) exit 1 ;;
    esac
    """
  end

  defp fake_gh do
    ~S"""
    #!/bin/sh
    command="$1 $2"
    if [ "$command" = "auth status" ]; then exit 0; fi
    if [ "$command" = "repo view" ]; then printf '%s\n' 'szTheory/scrypath'; exit 0; fi
    if [ "$command" = "workflow run" ]; then touch "$FAKE_STATE"; exit 0; fi
    if [ "$command" = "run list" ]; then
      if [ -f "$FAKE_STATE" ]; then
        printf '[{"databaseId":123,"headSha":"%s","status":"completed","conclusion":"success","url":"https://example.test/runs/123","createdAt":"2026-08-26T22:00:00Z"}]\n' "$FAKE_SHA"
      else
        printf '[]\n'
      fi
      exit 0
    fi
    if [ "$command" = "run watch" ]; then exit 0; fi
    if [ "$1" = "api" ]; then
      case "$*" in
        *'/protection/required_status_checks'*)
          if [ "$FAKE_SCENARIO" != "protection" ]; then exit 1; fi
          if [ "$2" = "--method" ]; then
            input=$(cat)
            printf '%s' "$input" > "$FAKE_STATE"
            printf '%s\n' "$input"
          elif [ -f "$FAKE_STATE" ]; then
            cat "$FAKE_STATE"
          else
            printf '{"strict":true,"checks":[{"context":"main-ci","app_id":15368}]}\n'
          fi
          exit 0
          ;;
      esac
      case "$2" in
        *'/jobs?'*)
          backend=success
          if [ "$FAKE_SCENARIO" = "failed_job" ]; then backend=failure; fi
          printf '{"jobs":[{"name":"core (required)","conclusion":"success"},{"name":"package (required)","conclusion":"success"},{"name":"repository-contracts (required)","conclusion":"success"},{"name":"backend (required)","conclusion":"%s"},{"name":"ecommerce-mounted (required)","conclusion":"success"},{"name":"coverage (advisory)","conclusion":"success"},{"name":"closeout-attestation","conclusion":"success"}]}\n' "$backend"
          ;;
        *'/artifacts?'*)
          if [ "$FAKE_SCENARIO" = "missing_artifact" ]; then
            printf '{"artifacts":[{"id":1,"name":"coverage-report-%s","expired":false,"digest":"sha256:coverage","expires_at":"2026-09-02T00:00:00Z","workflow_run":{"head_sha":"%s"}}]}\n' "$FAKE_SHA" "$FAKE_SHA"
          else
            printf '{"artifacts":[{"id":1,"name":"coverage-report-%s","expired":false,"digest":"sha256:coverage","expires_at":"2026-09-02T00:00:00Z","workflow_run":{"head_sha":"%s"}},{"id":2,"name":"closeout-attestation-%s","expired":false,"digest":"sha256:closeout","expires_at":"2026-09-02T00:00:00Z","workflow_run":{"head_sha":"%s"}}]}\n' "$FAKE_SHA" "$FAKE_SHA" "$FAKE_SHA" "$FAKE_SHA"
          fi
          ;;
        *) exit 1 ;;
      esac
      exit 0
    fi
    exit 1
    """
  end
end
