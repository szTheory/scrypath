defmodule Mix.Tasks.Verify.Phase107Test do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 argument contract" do
    test "verify.phase107 does not accept arguments" do
      assert_raise Mix.Error, ~r/verify\.phase107 does not accept arguments, got: stray/, fn ->
        Mix.Task.reenable("verify.phase107")
        Mix.Task.run("verify.phase107", ["stray"])
      end
    end
  end

  describe "task marker and focused execution path" do
    test "help output names verify.phase107" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.phase107"])
        end)

      assert output =~ "verify.phase107"
      assert output =~ "There is no documentation for this task"
    end

    test "source defines focused phase107 checks" do
      source = File.read!("lib/mix/tasks/verify.phase107.ex")

      assert source =~
               ~S|"examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs"|

      assert source =~ ~S|"test/mix/tasks/verify.phase107_test.exs"|
      assert source =~ "verify.phase107: ecommerce readiness regression checks"
      assert source =~ "Phase 107 ecommerce readiness regression guard"
    end
  end
end
