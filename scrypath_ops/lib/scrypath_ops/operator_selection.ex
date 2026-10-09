defmodule ScrypathOps.OperatorSelection do
  @moduledoc false

  @doc "Returns the canonical, prefix-free identity for an already loaded schema module."
  def canonical(module) when is_atom(module) do
    module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  def canonical(_module), do: nil

  @doc "Returns the overview's local URL without a misleading schema selection."
  def overview_path(uri) when is_binary(uri) do
    parsed = URI.parse(uri)
    params = URI.decode_query(parsed.query || "") |> Map.delete("schema")
    query = if map_size(params) == 0, do: nil, else: URI.encode_query(params)
    URI.to_string(%URI{path: parsed.path, query: query, fragment: parsed.fragment})
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
  def path(mount_path, "health", _schema) when is_binary(mount_path),
    do: "#{String.trim_trailing(mount_path, "/")}/health"

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
