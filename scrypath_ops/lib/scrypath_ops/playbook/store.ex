defmodule ScrypathOps.Playbook.Store do
  @moduledoc """
  Filesystem helpers for operator playbook JSON under a single **absolute** workspace root.

  All mutating APIs accept **basename-only** names (see `safe_basename?/1`). Resolved paths
  must remain under the configured root after `Path.expand/1` to mitigate traversal.
  """

  @basename_regex ~r/\A[\w.\-]+\.json\z/

  @doc """
  Returns true if `name` is a safe basename (no path separators), ending in `.json`.
  """
  @spec safe_basename?(term()) :: boolean()
  def safe_basename?(name) when is_binary(name), do: Regex.match?(@basename_regex, name)
  def safe_basename?(_), do: false

  @doc """
  Lists `*.json` files directly under `root` (non-recursive). `root` must be absolute.
  """
  @spec list_workspace_json(Path.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_workspace_json(root) when is_binary(root) do
    with {:ok, root_abs} <- absolute_root(root) do
      case File.ls(root_abs) do
        {:ok, names} ->
          json =
            names
            |> Enum.filter(&safe_basename?/1)
            |> Enum.sort()

          {:ok, json}

        {:error, _} = err ->
          err
      end
    end
  end

  def list_workspace_json(_), do: {:error, :invalid_root}

  @doc """
  Reads a workspace file by basename.
  """
  @spec read_workspace_file(Path.t(), String.t()) :: {:ok, binary()} | {:error, term()}
  def read_workspace_file(root, name) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name),
         {:ok, data} <- File.read(path) do
      {:ok, data}
    end
  end

  def read_workspace_file(_, _), do: {:error, :invalid_args}

  @doc """
  Writes UTF-8 data to a workspace file by basename (overwrites).
  """
  @spec save_workspace_file(Path.t(), String.t(), iodata()) :: :ok | {:error, term()}
  def save_workspace_file(root, name, data) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name) do
      File.write(path, data)
    end
  end

  def save_workspace_file(_, _, _), do: {:error, :invalid_args}

  @doc """
  Deletes a workspace file by basename.
  """
  @spec delete_workspace_file(Path.t(), String.t()) :: :ok | {:error, term()}
  def delete_workspace_file(root, name) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name) do
      File.rm(path)
    end
  end

  def delete_workspace_file(_, _), do: {:error, :invalid_args}

  @doc """
  Renames a workspace JSON file by basename (`from_name` → `to_name`).

  Returns `{:error, :target_exists}` if the destination path already exists (no overwrite).
  """
  @spec rename_workspace_file(Path.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def rename_workspace_file(root, from_name, to_name)
      when is_binary(root) and is_binary(from_name) and is_binary(to_name) do
    if safe_basename?(from_name) and safe_basename?(to_name) do
      with {:ok, from_path} <- resolved_path(root, from_name),
           {:ok, to_path} <- resolved_path(root, to_name) do
        cond do
          not File.exists?(from_path) ->
            {:error, :rename_failed}

          File.exists?(to_path) ->
            {:error, :target_exists}

          true ->
            case File.rename(from_path, to_path) do
              :ok -> :ok
              {:error, _} -> {:error, :rename_failed}
            end
        end
      end
    else
      {:error, :outside_workspace}
    end
  end

  def rename_workspace_file(_, _, _), do: {:error, :invalid_args}

  @doc """
  Duplicates a workspace JSON file by reading `from_name` and writing `to_name`.

  Returns `{:error, :target_exists}` if `to_name` already exists.
  """
  @spec duplicate_workspace_file(Path.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def duplicate_workspace_file(root, from_name, to_name)
      when is_binary(root) and is_binary(from_name) and is_binary(to_name) do
    if safe_basename?(from_name) and safe_basename?(to_name) do
      with {:ok, to_path} <- resolved_path(root, to_name) do
        if File.exists?(to_path) do
          {:error, :target_exists}
        else
          with {:ok, body} <- read_workspace_file(root, from_name) do
            save_workspace_file(root, to_name, body)
          end
        end
      end
    else
      {:error, :outside_workspace}
    end
  end

  def duplicate_workspace_file(_, _, _), do: {:error, :invalid_args}

  @doc """
  Suggests a free duplicate basename `"{stem}-n.json"` for `n >= 1` under `root`.

  `from_name` must be a safe `*.json` basename; `stem` is `Path.rootname/1` of that name.
  """
  @spec suggest_duplicate_basename(Path.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def suggest_duplicate_basename(root, from_name)
      when is_binary(root) and is_binary(from_name) do
    if safe_basename?(from_name) do
      stem = Path.rootname(from_name)

      with {:ok, names} <- list_workspace_json(root) do
        taken = MapSet.new(names)

        suggested =
          Enum.find_value(1..512, fn n ->
            candidate = "#{stem}-#{n}.json"
            if MapSet.member?(taken, candidate), do: nil, else: candidate
          end)

        case suggested do
          nil -> {:error, :no_duplicate_name}
          name -> {:ok, name}
        end
      end
    else
      {:error, :outside_workspace}
    end
  end

  def suggest_duplicate_basename(_, _), do: {:error, :invalid_args}

  defp absolute_root(root) do
    root_abs = Path.expand(Path.join(root, "."))

    if Path.type(root_abs) == :absolute do
      {:ok, root_abs}
    else
      {:error, :relative_root}
    end
  end

  defp resolved_path(root, name) do
    cond do
      not safe_basename?(name) ->
        {:error, :outside_workspace}

      true ->
        with {:ok, root_abs} <- absolute_root(root) do
          joined = Path.join(root_abs, name) |> Path.expand()

          if under_root?(root_abs, joined) do
            {:ok, joined}
          else
            {:error, :outside_workspace}
          end
        end
    end
  end

  defp under_root?(root_abs, path) do
    root_prefix =
      if String.ends_with?(root_abs, "/") do
        root_abs
      else
        root_abs <> "/"
      end

    path == root_abs or String.starts_with?(path, root_prefix)
  end
end
