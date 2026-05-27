defmodule Mix.Tasks.Verify.Phase97Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase97 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase97 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase97")
        Mix.Task.run("verify.phase97", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase97 and scope guard verification" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase97"])
        end)

      assert output =~ "verify.phase97"
      assert output =~ "canonical contract freeze and scope guard verification"
    end

    test "source defines focused test and docs command path" do
      source = File.read!("lib/mix/tasks/verify.phase97.ex")

      assert source =~ ~S|"test/mix/tasks/verify.phase97_test.exs"|
      assert source =~ ~S|"test/mix/tasks/workflow_wiring_test.exs"|
      assert source =~ ~S|"test/scrypath/docs_contract_test.exs"|
      assert source =~ ~S|Mix.Task.run("docs", ["--warnings-as-errors"])|
      assert source =~ "verify.phase97: canonical contract freeze and scope guard checks"
    end
  end
end
