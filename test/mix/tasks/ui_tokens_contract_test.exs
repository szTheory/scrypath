defmodule Mix.Tasks.UiTokensContractTest do
  use ExUnit.Case, async: false

  @root Path.expand("../../..", __DIR__)

  test "brandbook token document uses DTCG token structures" do
    tokens =
      @root
      |> Path.join("brandbook/tokens/tokens.json")
      |> File.read!()
      |> Jason.decode!()

    assert Map.has_key?(tokens, "$description"),
           "the whole token document must use DTCG metadata properties"

    refute Map.has_key?(tokens, "$schema"), "the stale external schema pointer must be removed"
    assert is_map(tokens["color"]["primitive"]["night"])
  end
end
