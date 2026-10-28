defmodule Mix.Tasks.Verify.PhoenixExample.LockGraph do
  @moduledoc false

  @required_packages ["mint", "hpax"]

  @doc false
  def parse!(source) when is_binary(source) do
    ast =
      case Code.string_to_quoted(source, emit_warnings: false) do
        {:ok, parsed} -> parsed
        {:error, _reason} -> raise ArgumentError, "invalid Mix lock syntax"
      end

    pairs =
      case ast do
        {:%{}, _meta, entries} when is_list(entries) -> entries
        _ -> raise ArgumentError, "Mix lock must contain one literal map"
      end

    entries =
      Enum.reduce(pairs, %{}, fn pair, acc ->
        {key, value} = map_pair!(pair)
        normalized_key = normalize_key!(literal!(key))

        if Map.has_key?(acc, normalized_key) do
          raise ArgumentError, "duplicate normalized Mix lock key: #{normalized_key}"
        end

        Map.put(acc, normalized_key, literal!(value))
      end)

    if map_size(entries) == 0 do
      raise ArgumentError, "Mix lock graph is empty"
    end

    entries
  end

  @doc false
  def assert_package!(source_lock, resolved_lock, expected_url, expected_tag, expected_revision)
      when is_binary(expected_url) and is_binary(expected_tag) and is_binary(expected_revision) do
    source = parse!(source_lock)
    resolved = parse!(resolved_lock)

    identity!(source_lock)
    identity!(resolved_lock)

    if Map.delete(source, "scrypath") != Map.delete(resolved, "scrypath") do
      raise ArgumentError, "resolved Mix lock graph changed outside the Scrypath entry"
    end

    assert_artifact_entry!(
      Map.get(resolved, "scrypath"),
      expected_url,
      expected_tag,
      expected_revision
    )

    :ok
  end

  @doc false
  def assert_unchanged!(before, after_fetch) when is_binary(before) and is_binary(after_fetch) do
    if before == after_fetch do
      :ok
    else
      raise ArgumentError, "Mix lock bytes changed during the path proof"
    end
  end

  @doc false
  def identity!(source) when is_binary(source) do
    entries = parse!(source)
    missing = Enum.reject(@required_packages, &Map.has_key?(entries, &1))

    if missing != [] do
      raise ArgumentError,
            "Mix lock graph is incomplete; missing required packages: #{Enum.join(missing, ", ")}"
    end

    packages =
      entries
      |> Enum.map(fn {name, entry} -> {name, package_version!(name, entry)} end)
      |> Enum.sort_by(&elem(&1, 0))

    %{
      sha256: :crypto.hash(:sha256, source) |> Base.encode16(case: :lower),
      packages: packages
    }
  end

  defp map_pair!({:"=>", _meta, [key, value]}), do: {key, value}
  defp map_pair!({key, value}), do: {key, value}
  defp map_pair!(_other), do: raise(ArgumentError, "Mix lock map contains an invalid entry")

  defp literal!(value) when is_atom(value) or is_binary(value) or is_number(value), do: value
  defp literal!(value) when is_list(value), do: Enum.map(value, &literal!/1)

  defp literal!({:{}, _meta, values}) when is_list(values) do
    values |> Enum.map(&literal!/1) |> List.to_tuple()
  end

  defp literal!({:%{}, _meta, pairs}) when is_list(pairs) do
    Enum.reduce(pairs, %{}, fn pair, acc ->
      {key, value} = map_pair!(pair)
      normalized_key = normalize_key!(literal!(key))

      if Map.has_key?(acc, normalized_key) do
        raise ArgumentError, "duplicate normalized Mix lock map key: #{normalized_key}"
      end

      Map.put(acc, normalized_key, literal!(value))
    end)
  end

  defp literal!({left, right}), do: {literal!(left), literal!(right)}

  defp literal!(_other) do
    raise ArgumentError, "Mix lock contains an executable or unsupported non-literal expression"
  end

  defp normalize_key!(key) when is_binary(key), do: key
  defp normalize_key!(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key!(_key), do: raise(ArgumentError, "Mix lock keys must be atoms or strings")

  defp package_version!(
         _name,
         {:hex, _app, version, _checksum, _builds, _deps, _repo, _repo_checksum}
       )
       when is_binary(version),
       do: version

  defp package_version!(_name, {:git, _url, _ref, _options}), do: "git"
  defp package_version!(_name, {:path, _path, _options}), do: "path"

  defp package_version!(name, _entry) do
    raise ArgumentError, "Mix lock entry for #{name} is incomplete or has an unsupported source"
  end

  defp assert_artifact_entry!(
         {:git, url, revision, options},
         expected_url,
         expected_tag,
         expected_revision
       )
       when url == expected_url and is_list(options) do
    cond do
      revision != expected_revision ->
        raise ArgumentError,
              "resolved Scrypath lock entry does not have the expected artifact revision"

      Enum.any?(options, &match?({:tag, ^expected_tag}, &1)) ->
        :ok

      true ->
        raise ArgumentError,
              "resolved Scrypath lock entry does not have the expected artifact tag"
    end
  end

  defp assert_artifact_entry!(_entry, _expected_url, _expected_tag, _expected_revision) do
    raise ArgumentError, "resolved Scrypath lock entry does not match the expected artifact"
  end
end
