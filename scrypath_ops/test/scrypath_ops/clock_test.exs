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
end
