defmodule Scrypath.NoHumanGatesContractTest do
  use ExUnit.Case, async: true

  @forbidden_plan_markers [
    "checkpoint:human-verify",
    "<human-check>",
    "verification: backstop"
  ]

  test "incomplete plans contain no post-implementation human verification gates" do
    violations =
      ".planning/phases/**/*-PLAN.md"
      |> Path.wildcard()
      |> Enum.reject(&File.exists?(String.replace_suffix(&1, "-PLAN.md", "-SUMMARY.md")))
      |> Enum.flat_map(fn path ->
        content = File.read!(path)

        for marker <- @forbidden_plan_markers, String.contains?(content, marker) do
          "#{path}: #{marker}"
        end
      end)

    assert violations == [],
           "incomplete plans must replace human verification with executable evidence:\n#{Enum.join(violations, "\n")}"
  end

  test "active verification and UAT artifacts carry no unresolved human-test debt" do
    verification_violations =
      ".planning/phases/**/*-VERIFICATION.md"
      |> Path.wildcard()
      |> Enum.filter(&(frontmatter_status(&1) == "human_needed"))

    uat_violations =
      ".planning/phases/**/*-UAT.md"
      |> Path.wildcard()
      |> Enum.filter(
        &(frontmatter_status(&1) in ~w(testing partial diagnosed blocked human_needed))
      )

    assert verification_violations ++ uat_violations == [],
           "human verification/UAT debt must be shifted left into automation"
  end

  defp frontmatter_status(path) do
    path
    |> File.read!()
    |> String.split("---", parts: 3)
    |> Enum.at(1, "")
    |> then(&Regex.run(~r/^status:\s*([^\s]+)\s*$/m, &1, capture: :all_but_first))
    |> case do
      [status] -> status
      _ -> nil
    end
  end
end
