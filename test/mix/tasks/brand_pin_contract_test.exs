defmodule Mix.Tasks.BrandPinContractTest do
  # Gate 1 of the v1.46 gate budget: the offline brand pin. Deletion trigger,
  # expected churn per UI PR and the full ledger are recorded in CONTRIBUTING.md
  # (added in Plan 03 of phase 186). The online re-download check is deliberately
  # NOT here; it lives only in `mix brand.update` and never runs in CI.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Brand.Update
  alias Mix.Tasks.Verify.Brand

  @root Path.expand("../../..", __DIR__)

  # Test-owned copy of the pinned archive hash. Editing brand/brand.pin.json
  # alone must fail this test; a refresh changes both keys in the same PR.
  @expected_zip_sha256 "3fc6d80f597eb232b6c25d5929cbe9dbbe6503c346c1360456ea839f3334be88"

  defp read_pin!(root \\ @root) do
    root |> Path.join("brand/brand.pin.json") |> File.read!() |> Jason.decode!()
  end

  describe "committed pin" do
    test "pin source fields equal the test-owned expectations" do
      source = read_pin!()["source"]

      assert source["zip_sha256"] == @expected_zip_sha256
      assert source["zip_size"] == 6_729_996
      assert source["zip_entries"] == 108
      assert source["zip_uncompressed_bytes"] == 8_912_608
      assert source["repository_commit"] == "ced7c40e"
    end

    test "verify.brand check!/1 accepts the committed tree" do
      assert Brand.check!(@root) == :ok
    end

    test "verify.brand run/1 reports the asset count and total bytes" do
      output = capture_io(fn -> Brand.run([]) end)

      assert output =~ "verify.brand: ok (44 assets, 326773 bytes)"
    end

    test "verify.brand run/1 rejects arguments" do
      assert_raise Mix.Error, ~r/does not accept arguments/, fn -> Brand.run(["--online"]) end
    end

    test "the adopted allowlist has 44 entries whose repo paths equal the pinned paths" do
      adopted = Update.adopted_members()
      pinned = read_pin!()["assets"]

      assert length(adopted) == 44
      assert Enum.sort(Enum.map(adopted, & &1.path)) == Enum.sort(Enum.map(pinned, & &1["path"]))
    end
  end
end
