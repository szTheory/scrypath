defmodule Mix.Tasks.Verify.Phase99Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase99 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase99 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase99")
        Mix.Task.run("verify.phase99", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase99" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase99"])
      end)

      assert output =~ "verify.phase99"
    end

    test "source defines focused test and docs command path" do
      source = File.read!("lib/mix/tasks/verify.phase99.ex")

      assert source =~ ~S|"test/scrypath/phase99_contract_test.exs"|
      assert source =~ ~S|"test/scrypath/phase111_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify.phase99_test.exs"|
      assert source =~ ~S|"test/mix/tasks/workflow_wiring_test.exs"|
      assert source =~ ~S|Mix.Task.run("docs", ["--warnings-as-errors"])|

      assert source =~
               "verify.phase99: drift-gate trust lane with phase100 install/release, phase101 compatibility-truth closure, and phase111 advisory-proof stability contract checks"

      assert source =~ "install/release"
      assert source =~ "phase101 compatibility-truth closure"
      assert source =~ "phase111 advisory-proof stability contract"
    end
  end
end
