defmodule ScrypathOps.Playbook.RunFailure do
  @moduledoc """
  Normalizes playbook run failures into a stable, JSON-serializable map.
  """

  alias ScrypathOps.Playbook.DocResolver

  @type context :: keyword()

  @registry [
    {:playbook_not_validated, "validation", "Playbook must be validated before it can run.",
     :playbook_schema, :none},
    {:stub_hard_failure, "backend", "Search adapter returned a forced hard failure.",
     :playbook_troubleshooting, :schema_mode},
    {:invalid_playbook_shape, "validation", "Playbook shape is not valid for execution.",
     :playbook_schema, :schema_mode},
    {{:config, :missing_backend}, "config", "Scrypath backend is not configured.",
     :playbook_operator_config, :mode},
    {{:config, :empty_allowlist}, "config", "Schema allowlist is empty.",
     :playbook_operator_config, :none},
    {{:config, :no_schema}, "config", "Schema is not on the configured allowlist.",
     :playbook_schema_no_schema, :schema_mode},
    {{:config, :invalid_query}, "validation", "Query field is invalid.",
     :playbook_schema_invalid_query, :schema_mode},
    {{:config, :invalid_entries}, "validation", "Entries list is invalid.",
     :playbook_schema_invalid_entries, :mode},
    {{:config, :invalid_entry_shape}, "validation", "An entry has an invalid shape.",
     :playbook_schema_invalid_entry_shape, :mode}
  ]

  @spec enrich(term(), context()) :: map()
  def enrich(reason, context \\ []) do
    context = sanitize_context(context)
    {failure_class, message, doc_ref, copy_strategy} = lookup(reason)

    %{
      failure_class: failure_class,
      reason: normalize_reason(reason),
      message: message,
      copy: build_copy(copy_strategy, context),
      doc: DocResolver.resolve(doc_ref)
    }
  end

  def from_reason(reason, context \\ []), do: enrich(reason, context)
  def doc_ref(reason), do: reason |> lookup() |> elem(2)

  defp lookup({:page_size_out_of_range, _size, _max} = reason) do
    {"validation", page_size_message(reason), :playbook_schema_page_size, :page_size}
  end

  defp lookup(reason) do
    Enum.find_value(@registry, fn
      {^reason, failure_class, message, doc_ref, copy_strategy} ->
        {failure_class, message, doc_ref, copy_strategy}

      _ ->
        nil
    end) || {"unknown", unknown_message(reason), :playbook_troubleshooting, :none}
  end

  defp normalize_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp normalize_reason(reason), do: inspect(reason, limit: 120)

  defp unknown_message(reason),
    do: "Playbook run failed: #{inspect(reason, limit: 120)}."

  defp page_size_message({:page_size_out_of_range, size, max}),
    do: "Playbook run failed: page.size #{size} is outside 1..#{max}."

  defp sanitize_context(context) when is_list(context) do
    context
    |> Keyword.take([:basename, :schema, :mode, :page_size, :max_page_size])
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case normalize_context_value(key, value) do
        nil -> acc
        normalized -> Map.put(acc, key, normalized)
      end
    end)
  end

  defp sanitize_context(_), do: %{}

  defp normalize_context_value(key, value)
       when key in [:basename, :schema, :mode] and is_binary(value),
       do: value

  defp normalize_context_value(key, value)
       when key in [:page_size, :max_page_size] and is_integer(value),
       do: value

  defp normalize_context_value(_, _), do: nil

  defp build_copy(:none, _context), do: %{}
  defp build_copy(:mode, context), do: take_copy(context, [:mode])
  defp build_copy(:schema_mode, context), do: take_copy(context, [:schema, :mode])

  defp build_copy(:page_size, context),
    do: take_copy(context, [:schema, :mode, :page_size, :max_page_size])

  defp take_copy(context, keys) do
    Map.take(context, [:basename | keys])
  end
end
