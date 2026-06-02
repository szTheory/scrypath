defmodule Mix.Tasks.Verify.Phase106Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase106 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase106 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase106")
        Mix.Task.run("verify.phase106", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase106" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase106"])
        end)

      assert output =~ "verify.phase106"
      assert output =~ "There is no documentation for this task"
    end

    test "source defines focused phase106 checks" do
      source = File.read!("lib/mix/tasks/verify.phase106.ex")

      assert source =~ ~S|"test/scrypath/schema_test.exs"|
      assert source =~ ~S|"test/scrypath/sync/related_test.exs"|
      assert source =~ ~S|"test/scrypath/sync/related_worker_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify.phase106_test.exs"|
      assert source =~ "verify.phase106: fan-out reflection contract checks"
      assert source =~ "Phase 106 fan-out reflection contract verification"
    end
  end
end
