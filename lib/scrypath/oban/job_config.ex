defmodule Scrypath.Oban.JobConfig do
  @moduledoc false

  @doc """
  Merges JSON job args for runtime Meilisearch / index hints into a keyword
  passed to `Scrypath.Config.resolve!/1` inside Oban workers.
  """
  @spec merge_job_runtime_opts(keyword(), map()) :: keyword()
  def merge_job_runtime_opts(keyword, args) when is_list(keyword) and is_map(args) do
    keyword
    |> put_from_arg(args, "meilisearch_url", :meilisearch_url)
    |> put_from_arg(args, "index_prefix", :index_prefix)
  end

  defp put_from_arg(kw, args, str_key, atom_key) do
    case Map.get(args, str_key) do
      v when is_binary(v) and v != "" -> Keyword.put(kw, atom_key, v)
      _ -> kw
    end
  end
end
