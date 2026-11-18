defmodule ScrypathOps.Clock do
  @moduledoc false

  # Mix compiles a mounted dependency in :prod even inside a test build. Use
  # the top-level build profile, falling back to Mix for direct task invocation.
  # MIX_ENV=prod builds always use system time, regardless of runtime config.
  if System.get_env("MIX_ENV", Atom.to_string(Mix.env())) == "test" do
    def utc_now do
      case Application.fetch_env(:scrypath_ops, :test_clock_file) do
        :error -> DateTime.utc_now()
        {:ok, path} -> fixture_time!(path)
      end
    end

    defp fixture_time!(path) when is_binary(path) do
      data = File.open!(path, [:read, :binary], &IO.binread(&1, 129))

      case data do
        value when is_binary(value) and byte_size(value) <= 128 ->
          value = String.trim_trailing(value, "\n")

          with true <- String.ends_with?(value, "Z"),
               {:ok, datetime, 0} <- DateTime.from_iso8601(value) do
            datetime
          else
            _ -> raise ArgumentError, "test clock fixture must contain a UTC ISO8601 timestamp"
          end

        _ ->
          raise ArgumentError, "test clock fixture must contain at most 128 bytes"
      end
    end

    defp fixture_time!(_path),
      do: raise(ArgumentError, "test clock fixture path must be a string")
  else
    def utc_now, do: DateTime.utc_now()
  end
end
