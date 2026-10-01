defmodule Scrypath.CIMonitorTest do
  use ExUnit.Case, async: true

  @script "scripts/ci_monitor.cjs"
  @sha "0123456789abcdef0123456789abcdef01234567"
  @final_sha "fedcba9876543210fedcba9876543210fedcba98"

  @tag readiness_tracer: true
  test "collect-readiness joins one explicit successful attempt to its real hashed attestation archive",
       ctx do
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
        artifact_url: "https://github.com/szTheory/scrypath/actions/runs/123/artifacts/10",
        artifact_digest: String.duplicate("a", 64)
      }
    }

    attestation_path = Path.join(archive_dir, "closeout-attestation.json")
    File.write!(attestation_path, Jason.encode!(attestation))

    archive_path = Path.join(ctx.root, "fixture.zip")

    {zip_output, 0} =
      System.cmd("zip", ["-q", archive_path, "closeout-attestation.json"], cd: archive_dir)

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

    assert receipt["attestation_member"]["content"]["coverage"]["artifact_digest"] ==
             String.duplicate("a", 64)

    assert receipt["attestation_member"]["sha256"] ==
             :crypto.hash(:sha256, Jason.encode!(attestation)) |> Base.encode16(case: :lower)

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

  test "collect-readiness refuses an output file inside the source checkout", ctx do
    output_path = Path.join(File.cwd!(), ".ci-monitor-readiness-output-forbidden.json")
    on_exit(fn -> File.rm(output_path) end)

    {output, status} =
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
          output_path
        ],
        env: [{"GH_BIN", ctx.gh}, {"GIT_BIN", ctx.git}, {"FAKE_SHA", @sha}],
        stderr_to_stdout: true
      )

    assert status != 0
    assert output =~ "--output must be outside the source checkout"
    refute File.exists?(output_path)
  end

  @tag readiness_tracer: true
  test "collect-readiness rejects source, attempt, and archive-byte mismatches", ctx do
    archive_sha = write_archive_fixture(ctx, :valid)
    bytes = File.read!(ctx.archive)
    <<prefix::binary-size(byte_size(bytes) - 1), final>> = bytes
    File.write!(ctx.changed_archive, prefix <> <<Bitwise.bxor(final, 1)>>)

    for {scenario, expected} <- [
          {"wrong_sha", "requested source SHA"},
          {"wrong_attempt", "requested run attempt"},
          {"changed_archive", "attestation archive digest"}
        ] do
      {output, status} = run_collect_readiness(ctx, archive_sha, scenario)
      assert status != 0
      assert output =~ expected
    end
  end

  test "collect-readiness exhausts attempt pages and rejects ambiguous or mismatched GitHub facts",
       ctx do
    for {scenario, expected} <- [
          {"wrong_repo", "requested repository"},
          {"wrong_workflow", "CI workflow metadata"},
          {"wrong_run", "different run or requested run attempt"},
          {"malformed_attempt", "invalid JSON"},
          {"duplicate_job", "exactly one successful job"},
          {"missing_job", "exactly one successful job"},
          {"failed_job", "exactly one successful job"},
          {"duplicate_artifact", "exactly one live"},
          {"expired_artifact", "exactly one live"},
          {"retry_overlap", "exactly one live"}
        ] do
      {output, status} = run_collect_readiness(ctx, String.duplicate("a", 64), scenario)
      assert status != 0
      assert output =~ expected
    end
  end

  test "collect-readiness bounds failed and oversized downloads and rejects malformed archive layouts",
       ctx do
    for {scenario, expected} <- [
          {"download_failed", "failed"},
          {"oversized_archive", "safe limit"}
        ] do
      {output, status} = run_collect_readiness(ctx, String.duplicate("a", 64), scenario)
      assert status != 0
      assert output =~ expected
    end

    for {layout, expected} <- [
          {:extra_member, "must contain only one closeout-attestation.json member"},
          {:traversal_member, "must contain only one closeout-attestation.json member"},
          {:duplicate_member, "must contain only one closeout-attestation.json member"},
          {:malformed_json, "invalid JSON"},
          {{:coverage_id, "999"}, "coverage artifact identity/digest"},
          {:coverage_digest, "coverage artifact identity/digest"},
          {:coverage_url, "coverage artifact identity/digest"}
        ] do
      archive_sha = write_archive_fixture(ctx, layout)
      {output, status} = run_collect_readiness(ctx, archive_sha, "archive_fixture")
      assert status != 0
      assert output =~ expected
    end
  end

  test "validate-readiness accepts frozen input shape without judgments and confirms discoverable issue",
       ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "inputs")
    {output, 0} = run_validate_readiness(ctx, source.root, record, "inputs")
    payload = Jason.decode!(output)

    assert payload["result"] == "FACTUAL_ONLY_VALID"
    assert payload["stage"] == "inputs"
    assert payload["semantic_decision"] == nil
    assert File.read!(ctx.calls) =~ "repos/szTheory/scrypath/issues/123"

    record = %{record | issue: %{record.issue | title: "Different issue"}}
    {output, status} = run_validate_readiness(ctx, source.root, record, "inputs")
    assert status != 0
    assert output =~ "title, author, or published body"
  end

  test "validate-readiness accepts explicitly pending delivery with its next action", ctx do
    source = readiness_source(ctx)

    record =
      readiness_record(source, "inputs")
      |> Map.put(:delivery, %{
        disposition: "pending",
        reason: "Plans 04/05 own candidate delivery and release disposition."
      })

    {output, 0} = run_validate_readiness(ctx, source.root, record, "inputs")

    assert Jason.decode!(output)["stage"] == "inputs"
  end

  test "draft validation permits only reasoned pending issue and delivery inputs", ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "draft")
    {output, 0} = run_validate_readiness(ctx, source.root, record, "draft")
    assert Jason.decode!(output)["semantic_decision"] == nil
    refute File.exists?(ctx.calls)
  end

  test "validate-readiness rejects duplicate fields, missing claims, and mutated historical bytes",
       ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "inputs")
    path = Path.join(ctx.root, "duplicate.json")
    File.write!(path, ~s({"schema":1,"schema":1}))
    {output, status} = run_validate_path(ctx, source.root, path, "inputs")
    assert status != 0
    assert output =~ "duplicate JSON field"

    record = %{
      record
      | baseline: %{record.baseline | claims: Enum.drop(record.baseline.claims, 1)}
    }

    {output, status} = run_validate_readiness(ctx, source.root, record, "inputs")
    assert status != 0
    assert output =~ "24 unique baseline claim IDs"

    record = readiness_record(source, "inputs")

    record = %{
      record
      | preserved_history:
          Enum.reject(record.preserved_history, &(&1.path == source.assessment_path))
    }

    {output, status} = run_validate_readiness(ctx, source.root, record, "inputs")
    assert status != 0
    assert output =~ "167-dated-readiness-and-closeout/167-ASSESSMENT.md"

    record = readiness_record(source, "inputs")
    File.write!(Path.join(source.root, source.archive_path), "changed historical bytes\n")
    {output, status} = run_validate_readiness(ctx, source.root, record, "inputs")
    assert status != 0
    assert output =~ "historical bytes"
  end

  test "terminal validation requires supplied judgments and never derives readiness", ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "terminal")
    {output, 0} = run_validate_readiness(ctx, source.root, record, "terminal")
    payload = Jason.decode!(output)

    assert payload["result"] == "FACTUAL_ONLY_VALID"
    assert payload["decision"] == "NOT READY"
    assert payload["approval"] == nil
    assert payload["rendered_markdown"] =~ "Record SHA-256:"

    reordered = %{
      record
      | conditions: Enum.reverse(record.conditions),
        baseline: %{record.baseline | claims: Enum.reverse(record.baseline.claims)}
    }

    {reordered_output, 0} = run_validate_readiness(ctx, source.root, reordered, "terminal")
    assert Jason.decode!(reordered_output)["rendered_markdown"] == payload["rendered_markdown"]

    assert payload["rendered_markdown"] =~
             "Candidate source: #{@sha}; squash-main source: #{@sha}; local artifact: #{@sha}."

    [first_condition | remaining_conditions] = record.conditions
    malicious_url = "https://github.com/szTheory/scrypath/compare/main...candidate?note=)"

    malicious_condition = %{
      first_condition
      | evidence: [
          %{
            url: malicious_url,
            label: "][click](https://evil.example) <img src=x onerror=alert(1)>"
          }
        ],
        rationale: "[forged](https://evil.example) <script>alert(1)</script>\n| fake cell",
        limits: "`code` _emphasis_"
    }

    malicious = %{
      record
      | conditions: [malicious_condition | remaining_conditions],
        blockers: ["<iframe src=\"https://evil.example\">"],
        revisit_triggers: ["![link](https://evil.example)"]
    }

    {malicious_output, 0} = run_validate_readiness(ctx, source.root, malicious, "terminal")
    rendered = Jason.decode!(malicious_output)["rendered_markdown"]
    assert rendered =~ "\\]\\[click\\]\\(https://evil.example\\) &lt;img"
    assert rendered =~ "note=%29"
    assert rendered =~ "\\[forged\\]\\(https://evil.example\\) &lt;script&gt;"
    assert rendered =~ "\\| fake cell"
    assert rendered =~ "\\`code\\` \\_emphasis\\_"
    assert rendered =~ "&lt;iframe"
    assert rendered =~ "!\\[link\\]\\(https://evil.example\\)"
    refute rendered =~ "<script>"
    refute rendered =~ "<img"
    refute rendered =~ "<iframe"

    correction =
      Map.put(record, :correction, %{
        supersedes_assessment_id: "Readiness-20260929T120000Z",
        corrected_at_utc: "2026-09-30T12:00:00Z",
        reason: "Append-only correction with updated evidence attribution."
      })

    {correction_output, 0} = run_validate_readiness(ctx, source.root, correction, "terminal")

    assert Jason.decode!(correction_output)["rendered_markdown"] =~
             "Correction: supersedes Readiness-20260929T120000Z"

    record = %{record | decision: "READY FOR OPERATOR UI"}
    [first | rest] = record.conditions
    record = %{record | conditions: [%{first | status: "FAIL"} | rest]}
    {output, status} = run_validate_readiness(ctx, source.root, record, "terminal")
    assert status != 0
    assert output =~ "READY requires six supplied PASS judgments"

    record = readiness_record(source, "terminal")
    [condition | rest] = record.conditions

    record = %{
      record
      | conditions: [
          %{
            condition
            | evidence: [%{url: "https://example.invalid/evidence", label: "untrusted"}]
          }
          | rest
        ]
    }

    {output, status} = run_validate_readiness(ctx, source.root, record, "terminal")
    assert status != 0
    assert output =~ "approved public evidence host"
  end

  test "terminal validation allows the final attested source to differ from its planning parent",
       ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "terminal")

    record = %{
      record
      | final_source: %{sha: @final_sha},
        attestation: fixture_collector_receipt(@final_sha)
    }

    assert record.source_identities.final_planning_source.sha == @sha
    assert record.final_source.sha == @final_sha

    {output, 0} = run_validate_readiness(ctx, source.root, record, "terminal")
    payload = Jason.decode!(output)
    assert payload["result"] == "FACTUAL_ONLY_VALID"
    assert payload["rendered_markdown"] =~ "Final planning parent: #{@sha}"
    assert payload["rendered_markdown"] =~ "Final attested source: #{@final_sha}"

    mismatched_receipt = %{record | attestation: fixture_collector_receipt(@sha)}

    {invalid_output, status} =
      run_validate_readiness(ctx, source.root, mismatched_receipt, "terminal")

    assert status != 0

    assert invalid_output =~
             "final attestation receipt repository/source/event/outcome does not join the supplied final source"
  end

  test "terminal validation accepts collector UTC timestamps with millisecond precision", ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "terminal")
    assessed_at = "2026-09-30T12:00:00.123Z"

    record = %{
      record
      | cutoff: "2026-09-30T11:59:59.456Z",
        assessed_at_utc: assessed_at,
        attestation: %{record.attestation | collected_at_utc: "2026-09-30T12:00:00.789Z"}
    }

    record =
      Map.put(record, :correction, %{
        supersedes_assessment_id: "Readiness-20260929T120000Z",
        corrected_at_utc: assessed_at,
        reason: "Collector-native millisecond timestamp precision."
      })

    {output, 0} = run_validate_readiness(ctx, source.root, record, "terminal")
    assert Jason.decode!(output)["result"] == "FACTUAL_ONLY_VALID"

    for timestamp <- ["2026-09-30T12:00:00.12Z", "2026-09-30T12:00:00.1234Z"] do
      invalid = %{record | attestation: %{record.attestation | collected_at_utc: timestamp}}
      {invalid_output, status} = run_validate_readiness(ctx, source.root, invalid, "terminal")
      assert status != 0
      assert invalid_output =~ "second- or millisecond-precision UTC timestamp ending in Z"
    end
  end

  test "verify-readiness-comment confirms explicit issue, author, body, and unique authority",
       ctx do
    source = readiness_source(ctx)
    record = readiness_record(source, "terminal")

    record =
      Map.put(record, :correction, %{
        supersedes_assessment_id: "Readiness-20260929T120000Z",
        corrected_at_utc: "2026-09-30T12:00:00Z",
        reason: "Append-only correction with updated evidence attribution."
      })

    {validation, 0} = run_validate_readiness(ctx, source.root, record, "terminal")
    body = Jason.decode!(validation)["rendered_markdown"]
    assert body =~ "Correction: supersedes Readiness-20260929T120000Z; 2026-09-30T12:00:00Z"

    comment = %{
      id: 999,
      issue_url: "https://api.github.com/repos/szTheory/scrypath/issues/123",
      html_url: "https://github.com/szTheory/scrypath/issues/123#issuecomment-999",
      user: %{login: "maintainer"},
      body: body
    }

    comment_path = Path.join(ctx.root, "comment.json")
    comments_path = Path.join(ctx.root, "comments.json")
    File.write!(comment_path, Jason.encode!(comment))
    File.write!(comments_path, Jason.encode!([comment]))
    {output, 0} = run_verify_comment(ctx, source.root, comment_path, comments_path, record)
    assert Jason.decode!(output)["result"] == "FACTUAL_ONLY_VALID"

    File.write!(comments_path, Jason.encode!([comment, comment]))
    {output, status} = run_verify_comment(ctx, source.root, comment_path, comments_path, record)
    assert status != 0
    assert output =~ "duplicate terminal authority comments"

    for altered <- [
          %{comment | body: comment.body <> "\nEdited after publication."},
          %{comment | user: %{login: "someone-else"}},
          %{comment | issue_url: "https://api.github.com/repos/other/project/issues/123"}
        ] do
      File.write!(comment_path, Jason.encode!(altered))
      File.write!(comments_path, Jason.encode!([altered]))
      {output, status} = run_verify_comment(ctx, source.root, comment_path, comments_path, record)
      assert status != 0
      assert output =~ "edited, duplicated, on another issue, or authored by another login"
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
    changed_archive = Path.join(root, "changed-attestation.zip")
    attestation = Path.join(root, "attestation.json")

    File.write!(gh, fake_gh())
    File.write!(git, fake_git())
    File.chmod!(gh, 0o755)
    File.chmod!(git, 0o755)

    on_exit(fn -> File.rm_rf!(root) end)

    %{
      root: root,
      gh: gh,
      git: git,
      state: state,
      calls: calls,
      archive: archive,
      changed_archive: changed_archive,
      attestation: attestation
    }
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
        {"FAKE_CHANGED_ARCHIVE", ctx.changed_archive},
        {"FAKE_ATTESTATION", ctx.attestation},
        {"FAKE_ARCHIVE_SHA", archive_sha},
        {"FAKE_CALLS", ctx.calls}
      ],
      stderr_to_stdout: true
    )
  end

  defp write_archive_fixture(ctx, layout) do
    archive_dir = Path.join(ctx.root, "archive-fixture")
    File.mkdir_p!(archive_dir)
    archive = Path.join(ctx.root, "layout.zip")
    File.rm(archive)

    attestation = archive_fixture_attestation(layout)
    member = if layout == :malformed_json, do: "{bad json", else: Jason.encode!(attestation)
    File.write!(Path.join(archive_dir, "closeout-attestation.json"), member)
    File.write!(Path.join(archive_dir, "extra.txt"), "extra\n")
    write_archive!(archive_dir, archive, layout)

    bytes = File.read!(archive)
    File.write!(ctx.archive, bytes)
    File.write!(ctx.attestation, Jason.encode!(attestation))
    :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  end

  defp archive_fixture_attestation(layout) do
    coverage_id =
      case layout do
        {:coverage_id, id} -> id
        _ -> "10"
      end

    coverage_digest =
      if layout == :coverage_digest,
        do: String.duplicate("d", 64),
        else: String.duplicate("a", 64)

    coverage_url =
      if layout == :coverage_url,
        do: "https://github.com/szTheory/scrypath/actions/runs/123/artifacts/999",
        else: "https://github.com/szTheory/scrypath/actions/runs/123/artifacts/10"

    %{
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
        artifact_id: coverage_id,
        artifact_url: coverage_url,
        artifact_digest: coverage_digest
      }
    }
  end

  defp write_archive!(archive_dir, archive, layout) do
    if layout in [:extra_member, :traversal_member, :duplicate_member] do
      write_multi_entry_archive!(archive_dir, archive, layout)
    else
      {_, 0} = System.cmd("zip", ["-q", archive, "closeout-attestation.json"], cd: archive_dir)
    end
  end

  defp write_multi_entry_archive!(archive_dir, archive, layout) do
    mode =
      case layout do
        :extra_member -> "extra"
        :traversal_member -> "traversal"
        :duplicate_member -> "duplicate"
      end

    script =
      "import sys, zipfile, warnings; warnings.filterwarnings('ignore', category=UserWarning); " <>
        "z=zipfile.ZipFile(sys.argv[1], 'w'); z.write(sys.argv[2], 'closeout-attestation.json'); " <>
        "z.write(sys.argv[3], 'extra.txt') if sys.argv[4] == 'extra' else None; " <>
        "z.writestr('../outside.txt', 'bad') if sys.argv[4] == 'traversal' else None; " <>
        "z.writestr('closeout-attestation.json', 'duplicate') if sys.argv[4] == 'duplicate' else None; z.close()"

    {_, 0} =
      System.cmd("python3", [
        "-c",
        script,
        archive,
        Path.join(archive_dir, "closeout-attestation.json"),
        Path.join(archive_dir, "extra.txt"),
        mode
      ])
  end

  defp run_validate_readiness(ctx, source_root, record, stage) do
    path = Path.join(ctx.root, "#{stage}-record.json")
    File.write!(path, Jason.encode!(record))

    if stage == "terminal" do
      common =
        ~w(schema cutoff baseline important_workflows invalidators findings opportunities preserved_history issue source_identities delivery cleanup tracked_inputs assumptions)a

      inputs =
        record
        |> Map.take(common)
        |> Map.put(
          :conditions,
          Enum.map(record.conditions, fn condition -> Map.take(condition, [:id, :text]) end)
        )

      input_path = Path.join(ctx.root, "frozen-inputs.json")
      receipt_path = Path.join(ctx.root, "collector-receipt.json")
      File.write!(input_path, Jason.encode!(inputs))
      File.write!(receipt_path, Jason.encode!(record.attestation))

      args = [
        @script,
        "validate-readiness",
        "--stage",
        "terminal",
        "--inputs",
        input_path,
        "--receipt",
        receipt_path,
        "--record",
        path,
        "--source-root",
        source_root
      ]

      run_readiness_cli(ctx, args)
    else
      run_validate_path(ctx, source_root, path, stage)
    end
  end

  defp run_validate_path(ctx, source_root, path, stage) do
    args = [@script, "validate-readiness", "--stage", stage, "--source-root", source_root]

    args =
      if stage == "terminal", do: args ++ ["--record", path], else: args ++ ["--inputs", path]

    run_readiness_cli(ctx, args)
  end

  defp run_readiness_cli(ctx, args) do
    System.cmd(System.find_executable("node") || "node", args,
      env: [
        {"GH_BIN", ctx.gh},
        {"GIT_BIN", ctx.git},
        {"FAKE_STATE", ctx.state},
        {"FAKE_SCENARIO", "readiness_issue"},
        {"FAKE_SHA", @sha},
        {"FAKE_CALLS", ctx.calls}
      ],
      stderr_to_stdout: true
    )
  end

  defp run_verify_comment(ctx, source_root, comment_path, comments_path, record) do
    File.write!(Path.join(ctx.root, "comment-record.json"), Jason.encode!(record))

    System.cmd(
      System.find_executable("node") || "node",
      [
        @script,
        "verify-readiness-comment",
        "--repo",
        "szTheory/scrypath",
        "--issue",
        "123",
        "--comment",
        "999",
        "--record",
        Path.join(ctx.root, "comment-record.json"),
        "--maintainer",
        "maintainer",
        "--source-root",
        source_root
      ],
      env: [
        {"GH_BIN", ctx.gh},
        {"GIT_BIN", ctx.git},
        {"FAKE_STATE", ctx.state},
        {"FAKE_SCENARIO", "readiness_issue"},
        {"FAKE_SHA", @sha},
        {"FAKE_CALLS", ctx.calls},
        {"FAKE_COMMENT_JSON", comment_path},
        {"FAKE_COMMENTS_JSON", comments_path}
      ],
      stderr_to_stdout: true
    )
  end

  defp readiness_source(ctx) do
    root = Path.join(ctx.root, "source")
    authority_path = Path.join(root, ".planning/reference/PRE-OPERATOR-UI-READINESS.md")

    archive_path =
      Path.join(
        root,
        ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-history.md"
      )

    baseline_path =
      Path.join(
        root,
        ".planning/milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md"
      )

    findings_path =
      Path.join(
        root,
        ".planning/milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md"
      )

    assessment_path =
      Path.join(
        root,
        ".planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md"
      )

    File.mkdir_p!(Path.dirname(authority_path))
    File.mkdir_p!(Path.dirname(archive_path))
    File.mkdir_p!(Path.dirname(baseline_path))
    File.mkdir_p!(Path.dirname(findings_path))
    File.mkdir_p!(Path.dirname(assessment_path))

    authority =
      "# Current readiness\n\n## Phase 164 dated assessment\nHistorical authority bytes.\n"

    archive = "Pinned historical archive bytes.\n"
    findings = "Pinned Phase 163 findings bytes.\n"
    assessment = "Pinned Phase 167 assessment bytes.\n"

    claim_dimensions = %{
      "C-02" => 1,
      "C-22" => 1,
      "C-03" => 2,
      "C-07" => 2,
      "C-08" => 2,
      "C-09" => 2,
      "C-04" => 2,
      "C-11" => 2,
      "C-01" => 3,
      "C-12" => 3,
      "C-10" => 3,
      "C-18" => 3,
      "C-13" => 4,
      "C-14" => 4,
      "C-15" => 4,
      "C-16" => 4,
      "C-17" => 4,
      "C-05" => 5,
      "C-06" => 5,
      "C-19" => 5,
      "C-21" => 6,
      "C-20" => 6,
      "C-23" => 7,
      "C-24" => 7
    }

    baseline =
      "# Phase 162 fixture\n\n## Claim matrix\n\n" <>
        Enum.map_join(claim_dimensions, fn {id, dimension} -> "| #{id} | #{dimension} |\n" end)

    File.write!(authority_path, authority)
    File.write!(archive_path, archive)
    File.write!(baseline_path, baseline)
    File.write!(findings_path, findings)
    File.write!(assessment_path, assessment)
    File.write!(Path.join(root, "CONTRIBUTING.md"), "Contributor contract fixture.\n")
    {_, 0} = System.cmd("git", ["init", "--quiet"], cd: root)
    {_, 0} = System.cmd("git", ["config", "user.name", "Fixture"], cd: root)
    {_, 0} = System.cmd("git", ["config", "user.email", "fixture@example.test"], cd: root)
    {_, 0} = System.cmd("git", ["add", "."], cd: root)
    {_, 0} = System.cmd("git", ["commit", "--quiet", "-m", "fixture baseline"], cd: root)
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: root)
    suffix = "## Phase 164 dated assessment\nHistorical authority bytes.\n"

    %{
      root: root,
      git_sha: String.trim(sha),
      authority_path: ".planning/reference/PRE-OPERATOR-UI-READINESS.md",
      authority_digest: :crypto.hash(:sha256, suffix) |> Base.encode16(case: :lower),
      archive_path:
        ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-history.md",
      archive_digest: :crypto.hash(:sha256, archive) |> Base.encode16(case: :lower),
      baseline_path:
        ".planning/milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md",
      baseline_digest: :crypto.hash(:sha256, baseline) |> Base.encode16(case: :lower),
      findings_path:
        ".planning/milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md",
      findings_digest: :crypto.hash(:sha256, findings) |> Base.encode16(case: :lower),
      assessment_path:
        ".planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md",
      assessment_digest: :crypto.hash(:sha256, assessment) |> Base.encode16(case: :lower),
      claim_dimensions: claim_dimensions
    }
  end

  defp readiness_record(source, stage) do
    dimensions = [
      "Public API consistency, ergonomics, compatibility, and error behavior",
      "Core indexing and search correctness, including writes/deletes, inline/manual/Oban synchronization, related data, tenancy, search, facets, federation, settings, and recovery",
      "Ecto, Oban, Meilisearch, Phoenix, and packaged-consumer seams, including representative supported version/runtime combinations",
      "Operational honesty, observability, backfill/reindex safety, failure reporting, and supportability",
      "First-hour and ongoing developer experience, documentation, examples, diagnostics, and adopter issue intake",
      "Security, privacy, dependency health, configuration boundaries, and release/supply-chain integrity",
      "Architecture, readability, maintainability, measured performance, and test/CI signal-to-cost"
    ]

    condition_texts = [
      "Every baseline dimension above has been assessed; evidence coverage and known limits are visible.",
      "Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.",
      "Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.",
      "Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.",
      "Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.",
      "Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout."
    ]

    claim_ids =
      ~w(C-02 C-22 C-03 C-07 C-08 C-09 C-04 C-11 C-01 C-12 C-10 C-18 C-13 C-14 C-15 C-16 C-17 C-05 C-06 C-19 C-21 C-20 C-23 C-24)

    claims =
      Enum.map(claim_ids, fn id ->
        %{
          id: id,
          dimension_id: source.claim_dimensions[id],
          claim: "A bounded claim #{id}.",
          source: "Phase 162 approved baseline",
          evidence_date: "2026-09-25",
          assessment_date: "2026-09-30",
          relevant_paths: [%{path: "CONTRIBUTING.md", disposition: "current"}],
          comparison: "Retained within the approved bounded claim.",
          disposition: "reusable within its stated boundary",
          limits: "This structural test does not make a semantic readiness judgment.",
          baseline_freshness: "reusable within its stated boundary",
          named_invalidator: "Revisit when the named workflow source changes."
        }
      end)

    base = %{
      schema: 1,
      cutoff: "2026-09-30T12:00:00Z",
      baseline: %{
        dimensions:
          Enum.with_index(dimensions, 1) |> Enum.map(fn {name, id} -> %{id: id, name: name} end),
        claims: claims
      },
      important_workflows: [
        %{
          id: "WF-01",
          description: "A declared workflow",
          claims: ["C-02"],
          evidence: ["A named source receipt supports the workflow."],
          supports: "A bounded adopter workflow.",
          limits: "One representative fixture only."
        }
      ],
      invalidators: [
        %{
          id: "INV-01",
          path: "CONTRIBUTING.md",
          claims: ["C-02"],
          reason: "Recheck when source contracts change."
        }
      ],
      findings: [],
      opportunities: [],
      preserved_history: [
        %{
          path: source.authority_path,
          git_source: source.git_sha,
          scope: "named_suffix",
          heading: "## Phase 164 dated assessment",
          sha256: source.authority_digest
        },
        %{
          path: source.archive_path,
          git_source: source.git_sha,
          scope: "whole_file",
          sha256: source.archive_digest
        },
        %{
          path: source.baseline_path,
          git_source: source.git_sha,
          scope: "whole_file",
          sha256: source.baseline_digest
        },
        %{
          path: source.findings_path,
          git_source: source.git_sha,
          scope: "whole_file",
          sha256: source.findings_digest
        },
        %{
          path: source.assessment_path,
          git_source: source.git_sha,
          scope: "whole_file",
          sha256: source.assessment_digest
        }
      ],
      conditions:
        Enum.with_index(condition_texts, 1)
        |> Enum.map(fn {text, id} -> %{id: id, text: text} end),
      issue: %{
        repository: "szTheory/scrypath",
        status: "created",
        number: 123,
        url: "https://github.com/szTheory/scrypath/issues/123",
        proposed_title: "Test readiness issue",
        proposed_body_sha256:
          :crypto.hash(:sha256, "Terminal decision fixture.") |> Base.encode16(case: :lower),
        title: "Test readiness issue",
        author_login: "maintainer",
        published_body_sha256:
          :crypto.hash(:sha256, "Terminal decision fixture.") |> Base.encode16(case: :lower),
        created_at: "2026-09-30T12:00:00Z",
        approval_provenance: "Explicit fixture authorization."
      },
      source_identities: %{
        candidate: %{sha: @sha},
        squash_main: %{sha: @sha},
        final_planning_source: %{sha: @sha},
        local_artifact: %{sha: @sha},
        published: %{version: "not-published", tag: "not-published", sha: "not-published"}
      },
      delivery: %{disposition: "deferred", reason: "Publication is not part of this record."},
      cleanup: %{status: "complete", items: []},
      tracked_inputs: [%{path: "CONTRIBUTING.md", disposition: "present"}],
      assumptions:
        Enum.map(1..7, fn index ->
          %{
            id: "EA-167-#{String.pad_leading(Integer.to_string(index), 2, "0")}",
            status: "unresolved",
            reason: "Inherited edge semantics remain author-unresolved."
          }
        end)
    }

    case stage do
      "inputs" ->
        base

      "draft" ->
        %{
          base
          | issue: %{
              repository: "szTheory/scrypath",
              status: "pending",
              reason: "Issue creation remains a later explicit action."
            },
            delivery: %{
              disposition: "pending",
              reason: "Delivery evidence has not been collected yet."
            }
        }

      "terminal" ->
        judgments =
          Enum.map(base.conditions, fn condition ->
            Map.merge(condition, %{
              status: "PASS",
              rationale: "Maintainer supplied judgment.",
              evidence: [
                %{
                  url: "https://github.com/szTheory/scrypath/actions/runs/123",
                  label: "Exact-source receipt"
                }
              ],
              evidence_date: "2026-09-30",
              assessment_date: "2026-09-30",
              limits: "Bounded to the supplied evidence."
            })
          end)

        Map.merge(base, %{
          assessment_id: "Readiness-20260930T120000Z",
          assessed_at_utc: "2026-09-30T12:00:00Z",
          maintainer: %{
            login: "maintainer",
            decision_provenance: "Explicit maintainer assessment."
          },
          conditions: judgments,
          decision: "NOT READY",
          final_source: %{sha: @sha},
          attestation: fixture_collector_receipt(),
          delivery_identity: %{
            disposition: "deferred",
            release: "not-published",
            package: "not-published"
          },
          blockers: ["One baseline claim remains unresolved."],
          revisit_triggers: ["A new source invalidator or hosted receipt."]
        })
    end
  end

  defp fixture_collector_receipt(sha \\ @sha) do
    required_jobs = [
      "core (required)",
      "package (required)",
      "repository-contracts (required)",
      "backend (required)",
      "ecommerce-mounted (required)"
    ]

    coverage_digest = String.duplicate("a", 64)
    archive_digest = String.duplicate("b", 64)
    coverage_url = "https://api.github.com/repos/szTheory/scrypath/actions/artifacts/10"
    coverage_action_url = "https://github.com/szTheory/scrypath/actions/runs/123/artifacts/10"

    content = %{
      schema: 1,
      authority: "github-actions-exact-sha",
      repository: "szTheory/scrypath",
      workflow: "CI",
      run_id: "123",
      run_attempt: "2",
      run_url: "https://github.com/szTheory/scrypath/actions/runs/123",
      event: "workflow_dispatch",
      head_sha: sha,
      required_jobs: required_jobs,
      coverage: %{
        outcome: "success",
        artifact_id: "10",
        artifact_url: coverage_action_url,
        artifact_digest: coverage_digest
      }
    }

    jobs =
      Enum.with_index(required_jobs ++ ["coverage (advisory)", "closeout-attestation"], 201)
      |> Enum.map(fn {name, id} ->
        %{id: id, name: name, status: "completed", conclusion: "success"}
      end)

    %{
      schema: 1,
      authority: "github-actions-exact-sha",
      repository: "szTheory/scrypath",
      head_sha: sha,
      source: %{head_sha: sha},
      workflow: %{id: "77", name: "CI", path: ".github/workflows/ci.yml"},
      run_id: "123",
      run_attempt: 2,
      run_url: "https://github.com/szTheory/scrypath/actions/runs/123",
      event: "workflow_dispatch",
      status: "completed",
      conclusion: "success",
      created_at: "2026-09-30T00:00:00Z",
      updated_at: "2026-09-30T00:01:00Z",
      jobs: jobs,
      coverage_artifact: %{
        id: "10",
        name: "coverage-report-#{sha}",
        url: coverage_url,
        digest: "sha256:" <> coverage_digest,
        expires_at: "2026-10-07T00:00:00Z"
      },
      attestation_artifact: %{
        id: "11",
        name: "closeout-attestation-#{sha}",
        url: "https://api.github.com/repos/szTheory/scrypath/actions/artifacts/11",
        digest: "sha256:" <> archive_digest,
        expires_at: "2026-10-07T00:00:00Z"
      },
      attestation_archive: %{sha256: archive_digest},
      attestation_member: %{
        name: "closeout-attestation.json",
        sha256: String.duplicate("c", 64),
        content: content
      },
      collected_at_utc: "2026-09-30T12:00:00Z",
      limitations: ["Factual fixture only."]
    }
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
        *'/issues/123/comments?'*)
          printf '[{"comments":%s}]\n' "$(cat "$FAKE_COMMENTS_JSON")"
          exit 0
          ;;
        *'/issues/comments/999'*)
          cat "$FAKE_COMMENT_JSON"
          exit 0
          ;;
        *'/issues/123'*)
          printf '%s\n' '{"number":123,"html_url":"https://github.com/szTheory/scrypath/issues/123","state":"open","title":"Test readiness issue","body":"Terminal decision fixture.","created_at":"2026-09-30T12:00:00Z","user":{"login":"maintainer"}}'
          exit 0
          ;;
      esac
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
          if [ "$FAKE_SCENARIO" = "changed_archive" ]; then cat "$FAKE_CHANGED_ARCHIVE"
          elif [ "$FAKE_SCENARIO" = "download_failed" ]; then printf '%s\n' 'download failed' >&2; exit 1
          elif [ "$FAKE_SCENARIO" = "oversized_archive" ]; then dd if=/dev/zero bs=1048576 count=9 2>/dev/null
          else cat "$FAKE_ARCHIVE"; fi
          exit 0
          ;;
        *'/actions/workflows/77'*)
          if [ "$FAKE_SCENARIO" = "wrong_workflow" ]; then
            printf '%s\n' '{"id":77,"name":"CI","path":".github/workflows/release.yml"}'
          else
            printf '%s\n' '{"id":77,"name":"CI","path":".github/workflows/ci.yml"}'
          fi
          exit 0
          ;;
        *'/attempts/2/jobs?'*)
          if [ "$FAKE_SCENARIO" = "duplicate_job" ]; then
            printf '%s\n' '[{"jobs":[{"id":201,"name":"core (required)","status":"completed","conclusion":"success"},{"id":202,"name":"package (required)","status":"completed","conclusion":"success"},{"id":203,"name":"repository-contracts (required)","status":"completed","conclusion":"success"},{"id":204,"name":"backend (required)","status":"completed","conclusion":"success"},{"id":205,"name":"ecommerce-mounted (required)","status":"completed","conclusion":"success"},{"id":206,"name":"coverage (advisory)","status":"completed","conclusion":"success"},{"id":207,"name":"closeout-attestation","status":"completed","conclusion":"success"}]},{"jobs":[{"id":208,"name":"core (required)","status":"completed","conclusion":"success"}]}]'
          elif [ "$FAKE_SCENARIO" = "missing_job" ]; then
            printf '%s\n' '[{"jobs":[{"id":201,"name":"core (required)","status":"completed","conclusion":"success"},{"id":202,"name":"package (required)","status":"completed","conclusion":"success"},{"id":203,"name":"repository-contracts (required)","status":"completed","conclusion":"success"},{"id":204,"name":"backend (required)","status":"completed","conclusion":"success"},{"id":205,"name":"ecommerce-mounted (required)","status":"completed","conclusion":"success"},{"id":206,"name":"coverage (advisory)","status":"completed","conclusion":"success"}]}]'
          else
            backend=success
            if [ "$FAKE_SCENARIO" = "failed_job" ]; then backend=failure; fi
            printf '{"jobs":[{"id":201,"name":"core (required)","status":"completed","conclusion":"success"},{"id":202,"name":"package (required)","status":"completed","conclusion":"success"},{"id":203,"name":"repository-contracts (required)","status":"completed","conclusion":"success"},{"id":204,"name":"backend (required)","status":"completed","conclusion":"%s"},{"id":205,"name":"ecommerce-mounted (required)","status":"completed","conclusion":"success"},{"id":206,"name":"coverage (advisory)","status":"completed","conclusion":"success"},{"id":207,"name":"closeout-attestation","status":"completed","conclusion":"success"}]}\n' "$backend"
          fi
          exit 0
          ;;
        *'/runs/123/artifacts?'*)
          if [ "$FAKE_SCENARIO" = "duplicate_artifact" ] || [ "$FAKE_SCENARIO" = "retry_overlap" ]; then
            printf '[{"artifacts":[{"id":10,"name":"coverage-report-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/10","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}},{"id":2,"name":"closeout-attestation-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/2","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}},{"id":3,"name":"closeout-attestation-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/3","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}}]}]\n' "$FAKE_SHA" "$(printf '%064d' 0 | tr '0' 'a')" "$FAKE_SHA" "$FAKE_SHA" "$FAKE_ARCHIVE_SHA" "$FAKE_SHA" "$FAKE_SHA" "$FAKE_ARCHIVE_SHA" "$FAKE_SHA"
          else
            expiration=false
            if [ "$FAKE_SCENARIO" = "expired_artifact" ]; then expiration=true; fi
            printf '[{"artifacts":[{"id":10,"name":"coverage-report-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/10","expired":%s,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}},{"id":2,"name":"closeout-attestation-%s","url":"https://api.github.com/repos/szTheory/scrypath/actions/artifacts/2","expired":false,"digest":"sha256:%s","expires_at":"2026-10-07T00:00:00Z","workflow_run":{"id":123,"head_sha":"%s"}}]}]\n' "$FAKE_SHA" "$expiration" "$(printf '%064d' 0 | tr '0' 'a')" "$FAKE_SHA" "$FAKE_SHA" "$FAKE_ARCHIVE_SHA" "$FAKE_SHA"
          fi
          exit 0
          ;;
        *'/runs/123/attempts/2'*)
          sha="$FAKE_SHA"
          attempt=2
          run_id=123
          repo=szTheory/scrypath
          if [ "$FAKE_SCENARIO" = "wrong_sha" ]; then sha=ffffffffffffffffffffffffffffffffffffffff; fi
          if [ "$FAKE_SCENARIO" = "wrong_attempt" ]; then attempt=3; fi
          if [ "$FAKE_SCENARIO" = "wrong_run" ]; then run_id=124; fi
          if [ "$FAKE_SCENARIO" = "wrong_repo" ]; then repo=other/project; fi
          if [ "$FAKE_SCENARIO" = "malformed_attempt" ]; then printf '%s\n' '{bad json'; exit 0; fi
          printf '{"id":%s,"run_attempt":%s,"workflow_id":77,"head_sha":"%s","event":"workflow_dispatch","status":"completed","conclusion":"success","html_url":"https://github.com/szTheory/scrypath/actions/runs/123","created_at":"2026-09-30T00:00:00Z","updated_at":"2026-09-30T00:01:00Z","repository":{"full_name":"%s"},"head_repository":{"full_name":"%s"}}\n' "$run_id" "$attempt" "$sha" "$repo" "$repo"
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
