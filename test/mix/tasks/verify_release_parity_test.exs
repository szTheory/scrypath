defmodule Mix.Tasks.Verify.ReleaseParityTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify.ReleaseParity

  describe "compute/2 (pure path-diff)" do
    test "returns :parity when git paths and hex paths match (D-08)" do
      git = MapSet.new(["lib/a.ex", "guides/x.md", "docs/releasing.md"])
      hex = MapSet.new(["lib/a.ex", "guides/x.md", "docs/releasing.md"])
      assert ReleaseParity.compute(git, hex) == :parity
    end

    test "returns drift tuple with sorted only_in_git and empty only_in_hex" do
      git = MapSet.new(["lib/a.ex", "lib/b.ex", "lib/c.ex"])
      hex = MapSet.new(["lib/a.ex"])
      assert ReleaseParity.compute(git, hex) == {:drift, ["lib/b.ex", "lib/c.ex"], []}
    end

    test "returns drift tuple when hex tarball has extra file not in git tag" do
      git = MapSet.new(["lib/a.ex"])
      hex = MapSet.new(["lib/a.ex", "lib/leaked.ex"])
      assert ReleaseParity.compute(git, hex) == {:drift, [], ["lib/leaked.ex"]}
    end
  end

  describe "render_json/4 (D-11 stable field order)" do
    test "emits documented JSON shape for drift" do
      json = ReleaseParity.render_json("0.3.0", :drift, ["lib/b.ex"], [])
      decoded = Jason.decode!(json)

      assert decoded == %{
               "version" => "0.3.0",
               "status" => "drift",
               "only_in_git" => ["lib/b.ex"],
               "only_in_hex" => []
             }
    end

    test "emits documented JSON shape for parity (empty lists)" do
      json = ReleaseParity.render_json("0.3.0", :parity, [], [])
      decoded = Jason.decode!(json)

      assert decoded["version"] == "0.3.0"
      assert decoded["status"] == "ok"
      assert decoded["only_in_git"] == []
      assert decoded["only_in_hex"] == []
    end
  end

  describe "retry_until!/4 (D-12 CDN retry)" do
    test "halts on first :ok after transient :error" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      result =
        ReleaseParity.retry_until!("stub fetch", 3, 1, fn ->
          n = Agent.get_and_update(counter, &{&1 + 1, &1 + 1})
          if n == 0, do: {:error, "transient"}, else: :ok
        end)

      assert result == :ok
      assert Agent.get(counter, & &1) == 2
    end

    test "Mix.raises after exhausting attempts with all :error returns" do
      assert_raise Mix.Error, ~r/failed after 2 attempts/, fn ->
        ReleaseParity.retry_until!("stub fetch", 2, 1, fn -> {:error, "still broken"} end)
      end
    end
  end

  describe "parse_version!/1 (Security V5 injection guard)" do
    test "rejects shell-meta chars" do
      assert_raise Mix.Error, ~r/semver/, fn ->
        ReleaseParity.parse_version!(["; rm -rf /"])
      end
    end

    test "rejects partial versions" do
      assert_raise Mix.Error, ~r/semver/, fn ->
        ReleaseParity.parse_version!(["0.3"])
      end
    end

    test "rejects leading v prefix" do
      assert_raise Mix.Error, ~r/semver/, fn ->
        ReleaseParity.parse_version!(["v0.3.0"])
      end
    end

    test "accepts canonical semver" do
      assert ReleaseParity.parse_version!(["0.3.0"]) == "0.3.0"
    end

    test "accepts pre-release suffix" do
      assert ReleaseParity.parse_version!(["1.0.0-rc.1"]) == "1.0.0-rc.1"
    end

    test "raises on missing argument" do
      assert_raise Mix.Error, ~r/expects exactly one version/, fn ->
        ReleaseParity.parse_version!([])
      end
    end
  end

  describe "integration canary (D-21)" do
    @tag :integration
    test "mix verify.release_parity 0.3.0 exits 0 against live Hex" do
      {_output, exit_status} =
        System.cmd("mix", ["verify.release_parity", "0.3.0"], stderr_to_stdout: true)

      assert exit_status == 0,
             "Expected exit 0 for known-good 0.3.0 (D-21 canary), got #{exit_status}"
    end
  end
end
