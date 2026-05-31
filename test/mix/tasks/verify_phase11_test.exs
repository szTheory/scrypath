defmodule Mix.Tasks.Verify.Phase11Test do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.Phase11

  describe "release agreement checks" do
    test "returns file-specific mismatches when version sources disagree" do
      fixture = %{
        mix_version: "0.3.8",
        source_ref: "v0.3.8",
        manifest_version: "0.3.7",
        release_type: "elixir",
        include_v_in_tag: true,
        top_changelog_version: "0.3.8"
      }

      assert {:error, messages} = Phase11.validate_release_agreement(fixture)

      assert Enum.any?(messages, &String.contains?(&1, "mix.exs version=0.3.8"))
      assert Enum.any?(messages, &String.contains?(&1, ".release-please-manifest.json version=0.3.7"))
    end

    test "rejects release-please config drift for root package settings" do
      fixture = %{
        mix_version: "0.3.8",
        source_ref: "v0.3.8",
        manifest_version: "0.3.8",
        release_type: "node",
        include_v_in_tag: false,
        top_changelog_version: "0.3.8"
      }

      assert {:error, messages} = Phase11.validate_release_agreement(fixture)
      assert Enum.any?(messages, &String.contains?(&1, "release-please-config.json"))
    end

    test "validates top CHANGELOG heading against current release line" do
      fixture = %{
        mix_version: "0.3.8",
        source_ref: "v0.3.8",
        manifest_version: "0.3.8",
        release_type: "elixir",
        include_v_in_tag: true,
        top_changelog_version: "0.3.7"
      }

      assert {:error, messages} = Phase11.validate_release_agreement(fixture)
      assert Enum.any?(messages, &String.contains?(&1, "CHANGELOG.md"))
      assert Enum.any?(messages, &String.contains?(&1, "0.3.7"))
    end

    test "passes when all semantic release sources agree" do
      fixture = %{
        mix_version: "0.3.8",
        source_ref: "v0.3.8",
        manifest_version: "0.3.8",
        release_type: "elixir",
        include_v_in_tag: true,
        top_changelog_version: "0.3.8"
      }

      assert :ok = Phase11.validate_release_agreement(fixture)
    end
  end
end
