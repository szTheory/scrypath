defmodule Mix.Tasks.Verify.Phase108Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase108 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase108 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase108")
        Mix.Task.run("verify.phase108", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase108" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase108"])
        end)

      assert output =~ "verify.phase108"
      assert output =~ "There is no documentation for this task"
    end

    test "source defines focused phase108 checks" do
      source = File.read!("lib/mix/tasks/verify.phase108.ex")

      assert source =~ ~S|"test/scrypath/phase108_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify.phase108_test.exs"|
      assert source =~ "verify.phase108: truth alignment and closeout proof checks"
      assert source =~ "Phase 108 truth alignment and closeout proof verification"
    end
  end
end
