defmodule Mix.Tasks.ScrypathOps.Playbooks.Validate do
  @shortdoc "Validate playbook_format 1 JSON files in a directory (no Meilisearch)"

  @moduledoc """
  Decodes and runs `ScrypathOps.Playbook.V1.validate/1` on each eligible `*.json`
  file in a single directory (non-recursive).

  Only basenames passing `ScrypathOps.Playbook.Store.safe_basename?/1` are considered.

  Run from the `scrypath_ops` app directory:

      mix scrypath_ops.playbooks.validate examples/playbooks

  Exits with status **1** on the first invalid file after printing `basename: reason` to stderr.
  """

  use Mix.Task

  alias ScrypathOps.Playbook.{Store, V1}

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile")

    case positional_dirs(args) do
      [dir] ->
        validate_dir(dir)

      [] ->
        Mix.raise("expected exactly one directory argument")

      many ->
        Mix.raise("expected exactly one directory argument, got: #{inspect(many)}")
    end
  end

  defp positional_dirs(args) do
    args
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&String.starts_with?(&1, "-"))
  end

  defp validate_dir(dir) do
    abs = Path.expand(dir)

    unless File.dir?(abs) do
      Mix.raise("not a directory: #{inspect(abs)}")
    end

    names =
      case File.ls(abs) do
        {:ok, names} ->
          names
          |> Enum.filter(&Store.safe_basename?/1)
          |> Enum.sort()

        {:error, reason} ->
          Mix.raise("cannot read directory #{inspect(abs)}: #{inspect(reason)}")
      end

    if names == [] do
      Mix.shell().info("No eligible *.json playbooks found under #{abs}")
    else
      Enum.each(names, fn name -> validate_one_file(abs, name) end)
      Mix.shell().info("Validated #{length(names)} playbook(s) under #{abs}")
    end
  end

  defp validate_one_file(dir_abs, name) do
    path = Path.join(dir_abs, name)

    with {:ok, bytes} <- File.read(path),
         {:ok, map} <- V1.decode(bytes),
         {:ok, _} <- V1.validate(map) do
      :ok
    else
      {:error, {:invalid_json, reason}} ->
        fail(name, {:invalid_json, reason})

      {:error, {:invalid_playbook, reason}} ->
        fail(name, {:invalid_playbook, reason})

      {:error, reason} ->
        fail(name, reason)
    end
  end

  defp fail(name, reason) do
    Mix.shell().error("#{name}: #{inspect(reason)}")
    exit({:shutdown, 1})
  end
end
