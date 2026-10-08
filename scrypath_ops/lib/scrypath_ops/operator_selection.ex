defmodule ScrypathOps.OperatorSelection do
  @moduledoc false

  @doc "Returns the canonical, prefix-free identity for an already loaded schema module."
  def canonical(module) when is_atom(module) do
    module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  def canonical(_module), do: nil

  @doc "Resolves an explicit URL selection, leaving fleet overviews unselected by default."
  def resolve_explicit(params, allowlist) when is_map(params) and is_list(allowlist) do
    cond do
      allowlist == [] -> :setup
      Map.has_key?(params, "schema") -> resolve(params, allowlist)
      true -> {:ok, nil}
    end
  end

  @doc "Resolves URL params against the current allowlist without creating atoms."
  def resolve(params, allowlist) when is_map(params) and is_list(allowlist) do
    case allowlist do
      [] ->
        :setup

      [first | _] ->
        if Map.has_key?(params, "schema") do
          requested = Map.get(params, "schema")

          case Enum.find(allowlist, &(canonical(&1) == requested)) do
            nil -> :unavailable
            module -> {:ok, module}
          end
        else
          {:ok, first}
        end
    end
  end

  @doc "Builds a mounted-path handoff with a safely encoded canonical schema identity."
  def path(mount_path, destination, schema)
      when is_binary(mount_path) and is_binary(destination) and is_atom(schema) and
             not is_nil(schema) do
    base = String.trim_trailing(mount_path, "/")
    query = URI.encode_query(%{"schema" => canonical(schema)})
    "#{base}/#{destination}?#{query}"
  end

  def path(mount_path, destination, nil)
      when is_binary(mount_path) and is_binary(destination),
      do: "#{String.trim_trailing(mount_path, "/")}/#{destination}"

  def path(_mount_path, _destination, _schema), do: nil
end
