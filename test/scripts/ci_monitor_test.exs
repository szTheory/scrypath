defmodule Scrypath.CIMonitorTest do
  use ExUnit.Case, async: true

  @script "scripts/ci_monitor.cjs"
  @sha "0123456789abcdef0123456789abcdef01234567"

  @tag readiness_tracer: true
  test "collect-readiness joins one explicit successful attempt to its real hashed attestation archive", ctx do
    archive_dir = Path.join(ctx.root, "archive")
    File.mkdir_p!(archive_dir)

    attestation = %{
      schema: 1,
      authority: "github-actions-exact-sha",
      repository: "szTheory/scrypath",
      workflow: "CI",
      run_id: "123",
      run_attempt: "2",
      run_url: "https://github.com/szTheory/scrypath/actions/runs/123",
      event: "workflow_dispatch",
      head_sha: @sha,
      required_jobs: [
        "core (required)",
        "package (required)",
        "repository-contracts (required)",
        "backend (required)",
        "ecommerce-mounted (required)"
      ],
      coverage: %{
        outcome: "success",
        artifact_id: "10",
        artifact_url: "https://api.github.com/repos/szTheory/scrypath/actions/artifacts/10",
        artifact_digest: "sha256:" <> String.duplicate("a", 64)
      }
    }

    attestation_path = Path.join(archive_dir, "closeout-attestation.json")
    File.write!(attestation_path, Jason.encode!(attestation))

    archive_path = Path.join(ctx.root, "fixture.zip")
    {zip_output, 0} = System.cmd("zip", ["-q", archive_path, "closeout-attestation.json"], cd: archive_dir)
    _ = zip_output
    archive_bytes = File.read!(archive_path)
    archive_sha = :crypto.hash(:sha256, archive_bytes) |> Base.encode16(case: :lower)
    File.write!(ctx.archive, archive_bytes)
    File.write!(ctx.attestation, Jason.encode!(attestation))

    {output, 0} = run_collect_readiness(ctx, archive_sha, "success")
    receipt = Jason.decode!(output)

    assert receipt["repository"] == "szTheory/scrypath"
    assert receipt["head_sha"] == @sha
    assert receipt["run_id"] == "123"
    assert receipt["run_attempt"] == 2
    assert receipt["attestation_member"]["content"]["run_attempt"] == "2"
    assert receipt["attestation_archive"]["sha256"] == archive_sha
    assert receipt["attestation_member"]["sha256"] ==
             (:crypto.hash(:sha256, Jason.encode!(attestation)) |> Base.encode16(case: :lower))
    assert receipt["jobs"] |> Enum.map(& &1["name"]) |> Enum.sort() ==
             [
               "core (required)",
               "package (required)",
               "repository-contracts (required)",
               "backend (required)",
               "ecommerce-mounted (required)",
               "coverage (advisory)",
               "closeout-attestation"
             ]
             |> Enum.sort()
    assert receipt["coverage_artifact"]["id"] == "10"
    assert receipt["limitations"] != []
    calls = File.read!(ctx.calls)
    refute calls =~ "workflow run"
    refute calls =~ "--method"
    refute calls =~ "/protection/"
  end

  @tag readiness_tracer: true
  test "collect-readiness rejects source, attempt, and archive-byte mismatches", ctx do
    for {scenario, expected} <- [
          {"wrong_sha", "requested source SHA"},
          {"wrong_attempt", "requested run attempt"},
          {"changed_archive", "attestation archive digest"}
        ] do
      {output, status} = run_collect_readiness(ctx, String.duplicate("a", 64), scenario)
      assert status != 0
      assert output =~ expected
    end
  end

  setup do
    root =
      Path.join(System.tmp_dir!(), "scrypath-ci-monitor-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    state = Path.join(root, "state")
    calls = Path.join(root, "calls")
    gh = Path.join(root, "gh")
    git = Path.join(root, "git")
    archive = Path.join(root, "attestation.zip")
    attestation = Path.join(root, "attestation.json")

    File.write!(gh, fake_gh())
    File.write!(git, fake_git())
    File.chmod!(gh, 0o755)
    File.chmod!(git, 0o755)

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, gh: gh, git: git, state: state, calls: calls, archive: archive, attestation: attestation}
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

  defp run_collect_readiness(ctx, archive_sha, scenario) do
    System.cmd(
      System.find_executable("node") || "node",
      [
        @script,
        "collect-readiness",
        "--repo",
        "szTheory/scrypath",
        "--sha",
        @sha,
        "--run",
        "123",
        "--attempt",
        "2",
        "--output",
        Path.join(ctx.root, "receipt.json")
      ],
      env: [
        {"GH_BIN", ctx.gh},
        {"GIT_BIN", ctx.git},
        {"FAKE_STATE", ctx.state},
        {"FAKE_SCENARIO", scenario},
        {"FAKE_SHA", @sha},
        {"FAKE_ARCHIVE", ctx.archive},
        {"FAKE_ATTESTATION", ctx.attestation},
        {"FAKE_ARCHIVE_SHA", archive_sha},
        {"FAKE_CALLS", ctx.calls}
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
    if [ -n "$FAKE_CALLS" ]; then printf '%s\n' "$*" >> "$FAKE_CALLS"; fi
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
      if [ -n "$FAKE_ARCHIVE" ]; then
      case "$*" in
        *'/actions/artifacts/2/zip'*)
          if [ "$FAKE_SCENARIO" = "changed_archive" ]; then printf '%s' 'changed-bytes'; else cat "$FAKE_ARCHIVE"; fi
          exit 0
          ;;
        *'/actions/workflows/77'*)
          printf '%s\n' '{"id":77,"name":"CI","path":".github/workflows/ci.yml"}'
          exit 0
          ;;
        *'/attempts/2/jobs?'*)
          printf '%s\n' '[{"jobs":[{"id":201,"name":"core (required)","status":"completed","conclusion":"success"},{"id":202,"name":"package (required)","status":"completed","conclusion":"success"},{"id":203,"name":"repository-contracts (required)","status":"completed","conclusion":"success"},{"id":204,"name":"backend (required)","status":"completed","conclusion":"success"},{"id":205,"name":"ecommerce-mounted (required)","status":"completed","conclusion":"success"},{"id":206,"name":"coverage (advisory)","status":"completed","conclusion":"success"},{"id":207,"name":"closeout-attestation","status":"completed","conclusion":"success"}]}]'
          exit 0
          ;;
        *'/runs/123/artifacts?'*)
          printf '[{"artifacts":[{"id":10,"name":"coverage-report-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/10","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}},{"id":2,"name":"closeout-attestation-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/2","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}}]}]\n' "$FAKE_SHA" "$(printf '%064d' 0 | tr '0' 'a')" "$FAKE_SHA" "$FAKE_SHA" "$FAKE_ARCHIVE_SHA" "$FAKE_SHA"
          exit 0
          ;;
        *'/runs/123/attempts/2'*)
          sha="$FAKE_SHA"
          attempt=2
          if [ "$FAKE_SCENARIO" = "wrong_sha" ]; then sha=ffffffffffffffffffffffffffffffffffffffff; fi
          if [ "$FAKE_SCENARIO" = "wrong_attempt" ]; then attempt=3; fi
          printf '{"id":123,"run_attempt":%s,"workflow_id":77,"head_sha":"%s","event":"workflow_dispatch","status":"completed","conclusion":"success","html_url":"https://github.com/szTheory/scrypath/actions/runs/123","created_at":"2026-09-30T00:00:00Z","updated_at":"2026-09-30T00:01:00Z","repository":{"full_name":"szTheory/scrypath"},"head_repository":{"full_name":"szTheory/scrypath"}}\n' "$attempt" "$sha"
          exit 0
          ;;
      esac
      fi
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
