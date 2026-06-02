defmodule Mix.Tasks.Verify.Phase112Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase112 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase112 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase112")
        Mix.Task.run("verify.phase112", ["stray"])
      end
    end
  end

  describe "task marker, focused execution path, and preferred env" do
    test "help output names verify.phase112" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase112"])
        end)

      assert output =~ "verify.phase112"
    end

    test "source defines focused phase112 checks" do
      source = File.read!("lib/mix/tasks/verify.phase112.ex")

      assert source =~ ~S|"test/scrypath/phase112_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify.phase112_test.exs"|
      assert source =~ "Runs public website and docs truth alignment checks (Phase 112)"
      assert source =~ "verify.phase112: public website and docs truth alignment checks"
      assert source =~ "Phase 112 public website and docs truth alignment verification"
    end

    test "mix project registers verify.phase112 preferred env as test" do
      assert Scrypath.MixProject.cli()[:preferred_envs][:"verify.phase112"] == :test
    end
  end
end
