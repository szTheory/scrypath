defmodule Scrypath.ReadinessContractTest do
  use ExUnit.Case, async: true

  alias Scrypath.Release.ShippedDocs

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")

  test "canonical support guide exists and active short docs route to it" do
    assert File.regular?("guides/support-and-compatibility.md")

    assert String.contains?(@readme, "guides/support-and-compatibility.md")
    assert String.contains?(@contributing, "guides/support-and-compatibility.md")
  end

  test "canonical outside-adopter intake guide routes from short docs" do
    assert File.regular?("guides/outside-adopter-intake.md")

    assert String.contains?(@readme, "guides/outside-adopter-intake.md")
    assert String.contains?(@contributing, "guides/outside-adopter-intake.md")
    assert String.contains?(@support_guide, "outside-adopter-intake.md")
  end

  test "intake guide states the evidence and proof boundaries" do
    intake = File.read!("guides/outside-adopter-intake.md")
    assert String.contains?(intake, "outside-adopter-evidence.md")
    assert String.contains?(intake, "Class A")
    assert String.contains?(intake, "Class D")
    assert String.contains?(intake, "phoenix_meilisearch/README.md")
    assert String.contains?(intake, "Repo-clone")
    assert String.contains?(intake, "Hex-package")
  end

  test "support guide states the defended branch-tip readiness contract" do
    assert String.contains?(@support_guide, "Elixir")
    assert String.contains?(@support_guide, "OTP")
    assert String.contains?(@support_guide, "Phoenix + Meilisearch")
    assert String.contains?(@support_guide, "`:inline`")
    assert String.contains?(@support_guide, "`:manual`")
    assert String.contains?(@support_guide, "`:oban`")

    # Stronger than the old substring: the guide must name the task AND say it is a source-checkout
    # task. Companion: test/release/shipped_docs_contract_test.exs (real-file invariant).
    assert_qualified_adopter_mention(@support_guide, "guides/support-and-compatibility.md")
    assert String.contains?(@support_guide, "outside-adopter evidence")
    assert String.contains?(@support_guide, "Hex")
  end

  test "mix help verify.adopter matches the real fast/live contract" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Task.reenable("help")
        Mix.Task.run("help", ["verify.adopter"])
      end)

    assert String.contains?(output, "mix test test/scrypath/readiness_contract_test.exs")
    assert String.contains?(output, "mix test test/mix/tasks/verify_adopter_test.exs")
    assert String.contains?(output, "SCRYPATH_EXAMPLE_INTEGRATION")
    assert String.contains?(output, "PGPORT")
    assert String.contains?(output, "SCRYPATH_MEILISEARCH_URL")
    assert String.contains?(output, "cd examples/phoenix_meilisearch")
    assert String.contains?(output, "mix deps.get")
    assert String.contains?(output, "mix test")
  end

  test "maintainer docs and example runbook agree on the live proof path" do
    # The README is no longer a home for the proof spine: the shipped-docs invariant
    # (test/release/shipped_docs_contract_test.exs) forbids an unqualified mention there, so only
    # the maintainer-facing CONTRIBUTING half of this agreement stays demanded.
    assert String.contains?(@contributing, "mix verify.adopter")
    assert String.contains?(@contributing, "mix verify.adopter --live")
    assert String.contains?(@contributing, "phoenix-example")
    assert String.contains?(@contributing, "SCRYPATH_EXAMPLE_INTEGRATION")
    assert String.contains?(@contributing, "PGPORT")
    assert String.contains?(@contributing, "SCRYPATH_MEILISEARCH_URL")
    assert String.contains?(@example_readme, "mix verify.phoenix_example")
    assert String.contains?(@example_readme, "SCRYPATH_EXAMPLE_INTEGRATION")
    assert String.contains?(@example_readme, "PGPORT")
    assert String.contains?(@example_readme, "SCRYPATH_MEILISEARCH_URL")
  end

  # Names the adopter proof task in at least one unit, and every such unit carries the
  # source-checkout qualifier (the same unit rule the shipped-docs invariant enforces).
  defp assert_qualified_adopter_mention(text, doc) do
    units =
      text
      |> ShippedDocs.units()
      |> Enum.filter(&("verify.adopter" in ShippedDocs.mentions(&1.text, ["verify.adopter"])))

    refute units == [], "#{doc} no longer names mix verify.adopter"

    for unit <- units do
      assert ShippedDocs.unit_qualified?(unit),
             "#{doc}:#{unit.line} names mix verify.adopter without the source-checkout qualifier"
    end
  end
end
