defmodule ScrypathOps.ClockTest do
  use ExUnit.Case, async: false

  setup do
    previous = Application.fetch_env(:scrypath_ops, :test_clock_file)
    path = Path.join(System.tmp_dir!(), "scrypath-clock-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm(path)

      case previous do
        {:ok, value} -> Application.put_env(:scrypath_ops, :test_clock_file, value)
        :error -> Application.delete_env(:scrypath_ops, :test_clock_file)
      end
    end)

    %{path: path}
  end

  test "ordinary posture observations honor the disposable test clock", %{path: path} do
    File.write!(path, "2026-10-31T12:34:56Z\n")
    Application.put_env(:scrypath_ops, :test_clock_file, path)

    assert ScrypathOps.Posture.summary([], []).refreshed_at == ~U[2026-10-31 12:34:56Z]
  end

  test "unconfigured test builds keep system time" do
    Application.delete_env(:scrypath_ops, :test_clock_file)
    before = DateTime.utc_now()
    actual = ScrypathOps.Clock.utc_now()
    after_call = DateTime.utc_now()

    assert DateTime.compare(actual, before) in [:eq, :gt]
    assert DateTime.compare(actual, after_call) in [:eq, :lt]
  end

  test "configured missing files fail instead of drifting to wall time", %{path: path} do
    Application.put_env(:scrypath_ops, :test_clock_file, path)
    assert_raise File.Error, fn -> ScrypathOps.Clock.utc_now() end
  end

  test "invalid or oversized clocks fail closed", %{path: path} do
    Application.put_env(:scrypath_ops, :test_clock_file, path)

    for value <- ["", "not a date", "2026-10-31T12:34:56+01:00", String.duplicate("x", 129)] do
      File.write!(path, value)
      assert_raise ArgumentError, fn -> ScrypathOps.Clock.utc_now() end
    end
  end

  test "production compiled clock ignores test configuration", %{path: path} do
    File.write!(path, "2026-10-31T12:34:56Z\n")
    source = Path.expand("../../lib/scrypath_ops/clock.ex", __DIR__)

    script = """
    Mix.start()
    Mix.env(:prod)
    Code.compile_file(#{inspect(source)})
    Application.put_env(:scrypath_ops, :test_clock_file, #{inspect(path)})
    before = DateTime.utc_now()
    actual = ScrypathOps.Clock.utc_now()
    after_call = DateTime.utc_now()
    true = DateTime.compare(actual, before) in [:eq, :gt]
    true = DateTime.compare(actual, after_call) in [:eq, :lt]
    IO.puts("PRODUCTION_SYSTEM_CLOCK")
    """

    assert {output, 0} =
             System.cmd("elixir", ["-e", script],
               stderr_to_stdout: true,
               env: [{"MIX_ENV", "prod"}]
             )

    assert output =~ "PRODUCTION_SYSTEM_CLOCK"
  end

  test "test build keeps the fixture clock when Mix compiles it as a production dependency", %{
    path: path
  } do
    File.write!(path, "2026-10-31T12:34:56Z\n")
    source = Path.expand("../../lib/scrypath_ops/clock.ex", __DIR__)

    script = """
    Mix.start()
    Mix.env(:prod)
    Code.compile_file(#{inspect(source)})
    Application.put_env(:scrypath_ops, :test_clock_file, #{inspect(path)})
    IO.puts("DEPENDENCY_CLOCK=" <> DateTime.to_iso8601(ScrypathOps.Clock.utc_now()))
    """

    assert {output, 0} =
             System.cmd("elixir", ["-e", script],
               stderr_to_stdout: true,
               env: [{"MIX_ENV", "test"}]
             )

    assert output =~ "DEPENDENCY_CLOCK=2026-10-31T12:34:56Z"
  end
end
