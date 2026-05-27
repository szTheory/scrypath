defmodule Mix.Tasks.Verify.Phase98Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase98 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase98 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase98")
        Mix.Task.run("verify.phase98", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase98" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase98"])
        end)

      assert output =~ "verify.phase98"
      assert output =~ "There is no documentation for this task"
    end

    test "source defines focused test and docs command path" do
      source = File.read!("lib/mix/tasks/verify.phase98.ex")

      assert source =~ ~S|"test/scrypath/phase98_contract_test.exs"|
      assert source =~ ~S|"test/scrypath/readiness_contract_test.exs"|
      assert source =~ ~S|"test/scrypath/docs_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify.phase98_test.exs"|
      assert source =~ ~S|Mix.Task.run("docs", ["--warnings-as-errors"])|
      assert source =~ "verify.phase98: surface reconciliation and adopter-flow checks"
    end
  end
end
