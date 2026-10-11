defmodule ScrypathOps.Playbook.Store do
  @moduledoc """
  Filesystem helpers for operator playbook JSON under a single **absolute** workspace root.

  All mutating APIs accept **basename-only** names (see `safe_basename?/1`). Resolved paths
  must remain under the configured root after `Path.expand/1` to mitigate traversal. Reads and
  overwrites verify the opened file descriptor against the basename's link metadata before doing
  I/O, so a symlink cannot redirect an operation outside the workspace. Listing and destructive
  actions accept regular files only.
  """

  @basename_regex ~r/\A[\w.\-]+\.json\z/
  @read_chunk_size 65_536

  require Record
  Record.defrecordp(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))

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
            |> Enum.filter(&regular_workspace_entry?(Path.join(root_abs, &1)))
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
    with {:ok, path} <- resolved_path(root, name) do
      with_workspace_file(path, [:read, :binary, :raw], &read_all/1)
    end
  end

  def read_workspace_file(_, _), do: {:error, :invalid_args}

  @doc """
  Writes UTF-8 data to a workspace file by basename (overwrites).
  """
  @spec save_workspace_file(Path.t(), String.t(), iodata()) :: :ok | {:error, term()}
  def save_workspace_file(root, name, data) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name) do
      save_workspace_file_at(path, data)
    end
  end

  def save_workspace_file(_, _, _), do: {:error, :invalid_args}

  @doc """
  Creates a workspace file by basename without replacing an existing file.

  Exclusive creation makes the existence check and file creation one filesystem operation.
  Returns `{:error, :target_exists}` if another writer already created the destination.
  """
  @spec create_workspace_file(Path.t(), String.t(), iodata()) :: :ok | {:error, term()}
  def create_workspace_file(root, name, data) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name) do
      case File.write(path, data, [:binary, :exclusive]) do
        {:error, :eexist} -> {:error, :target_exists}
        result -> result
      end
    end
  end

  def create_workspace_file(_, _, _), do: {:error, :invalid_args}

  @doc """
  Deletes a workspace file by basename.
  """
  @spec delete_workspace_file(Path.t(), String.t()) :: :ok | {:error, term()}
  def delete_workspace_file(root, name) when is_binary(root) and is_binary(name) do
    with {:ok, path} <- resolved_path(root, name) do
      case regular_workspace_entry?(path) do
        true -> File.rm(path)
        false -> {:error, :outside_workspace}
      end
    end
  end

  def delete_workspace_file(_, _), do: {:error, :invalid_args}

  @doc """
  Renames a workspace JSON file by basename (`from_name` → `to_name`).

  Creates a hard link at the destination before removing the source, making destination creation
  no-replace. Returns `{:error, :target_exists}` if the destination path already exists. The
  workspace filesystem must support hard links.
  """
  @spec rename_workspace_file(Path.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def rename_workspace_file(root, from_name, to_name)
      when is_binary(root) and is_binary(from_name) and is_binary(to_name) do
    if safe_basename?(from_name) and safe_basename?(to_name) do
      with {:ok, from_path} <- resolved_path(root, from_name),
           {:ok, to_path} <- resolved_path(root, to_name) do
        rename_without_replacing(from_path, to_path)
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
            create_workspace_file(root, to_name, body)
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

  defp with_workspace_file(path, modes, callback) do
    case :file.open(path, modes) do
      {:ok, file} ->
        try do
          case safe_workspace_file?(path, file) do
            true -> callback.(file)
            false -> {:error, :outside_workspace}
          end
        after
          :file.close(file)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_all(file), do: read_chunks(file, [])

  defp read_chunks(file, chunks) do
    case :file.read(file, @read_chunk_size) do
      {:ok, chunk} -> read_chunks(file, [chunk | chunks])
      :eof -> {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}
      {:error, reason} -> {:error, reason}
    end
  end

  defp save_workspace_file_at(path, data) do
    case overwrite_workspace_file(path, data) do
      {:error, :enoent} ->
        create_or_retry_workspace_file(path, data)

      result ->
        result
    end
  end

  defp create_or_retry_workspace_file(path, data) do
    case :file.open(path, [:write, :binary, :raw, :exclusive]) do
      {:ok, file} ->
        try do
          :file.write(file, data)
        after
          :file.close(file)
        end

      {:error, :eexist} ->
        overwrite_workspace_file(path, data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp overwrite_workspace_file(path, data) do
    with_workspace_file(path, [:read, :write, :binary, :raw], fn file ->
      with {:ok, _position} <- :file.position(file, :bof),
           :ok <- :file.truncate(file),
           :ok <- :file.write(file, data) do
        :ok
      end
    end)
  end

  defp safe_workspace_file?(path, file) do
    with {:ok, %File.Stat{type: :regular} = path_info} <- File.lstat(path),
         {:ok, descriptor_info} <- :file.read_file_info(file) do
      same_file?(path_info, descriptor_info)
    else
      _ -> false
    end
  end

  defp same_file?(%File.Stat{} = path_info, descriptor_info) do
    descriptor_type = file_info(descriptor_info, :type)
    descriptor_device = file_info(descriptor_info, :major_device)
    descriptor_inode = file_info(descriptor_info, :inode)

    cond do
      path_info.type != :regular or descriptor_type != :regular ->
        false

      path_info.inode > 0 and descriptor_inode > 0 ->
        path_info.major_device == descriptor_device and path_info.inode == descriptor_inode

      true ->
        path_info.size == file_info(descriptor_info, :size) and
          path_info.mode == file_info(descriptor_info, :mode) and
          path_info.mtime == file_info(descriptor_info, :mtime) and
          path_info.ctime == file_info(descriptor_info, :ctime)
    end
  end

  defp regular_workspace_entry?(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} -> true
      _ -> false
    end
  end

  defp rename_without_replacing(from_path, to_path) do
    with {:ok, %File.Stat{type: :regular} = source_info} <- File.lstat(from_path) do
      case File.ln(from_path, to_path) do
        :ok ->
          case File.lstat(to_path) do
            {:ok, %File.Stat{type: :regular} = destination_info} ->
              if same_file_stats?(source_info, destination_info) do
                case File.lstat(from_path) do
                  {:ok, current_source} when current_source.type == :regular ->
                    if same_file_stats?(source_info, current_source) do
                      case File.rm(from_path) do
                        :ok ->
                          :ok

                        {:error, :enoent} ->
                          remove_created_link(to_path, source_info)
                          {:error, :rename_failed}

                        {:error, _} ->
                          {:error, :rename_failed}
                      end
                    else
                      remove_created_link(to_path, source_info)
                      {:error, :rename_failed}
                    end

                  {:error, :enoent} ->
                    remove_created_link(to_path, source_info)
                    {:error, :rename_failed}

                  _ ->
                    remove_created_link(to_path, source_info)
                    {:error, :rename_failed}
                end
              else
                {:error, :rename_failed}
              end

            _ ->
              # File.ln never follows a destination symlink. Leave a changed entry
              # untouched rather than risk deleting another writer's destination.
              {:error, :outside_workspace}
          end

        {:error, :eexist} ->
          {:error, :target_exists}

        {:error, _} ->
          {:error, :rename_failed}
      end
    else
      {:ok, _non_regular} -> {:error, :outside_workspace}
      {:error, _} -> {:error, :rename_failed}
    end
  end

  defp same_file_stats?(left, right) do
    if left.inode > 0 and right.inode > 0 do
      left.major_device == right.major_device and left.inode == right.inode
    else
      left.type == right.type and left.size == right.size and left.mode == right.mode and
        left.mtime == right.mtime and left.ctime == right.ctime
    end
  end

  defp remove_created_link(path, expected_info) do
    case File.lstat(path) do
      {:ok, current_info} when current_info.type == :regular ->
        if same_file_stats?(expected_info, current_info), do: File.rm(path)

      _ ->
        :ok
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
