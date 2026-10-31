defmodule ScrypathOps.Clock do
  @moduledoc false

  # This fixture seam is compiled only in test builds. Production observations
  # always use system time, even if test configuration is accidentally supplied.
  if Mix.env() == :test do
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
