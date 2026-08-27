defmodule Scrypath.Options.Settings do
  @moduledoc false

  @recognized_subkeys [
    :synonyms,
    :typo_tolerance,
    :ranking_rules,
    :distinct_attribute,
    :stop_words
  ]

  @legacy_camel_allowlist [
    :searchableAttributes,
    :sortableAttributes,
    :filterableAttributes,
    :displayedAttributes,
    :typoTolerance
  ]

  @legacy_camel_strings Enum.map(@legacy_camel_allowlist, &Atom.to_string/1)

  @attribute_keys [
    :searchable_attributes,
    :sortable_attributes,
    :filterable_attributes,
    :displayed_attributes
  ]

  @meilisearch_default_ranking_rules [:words, :typo, :proximity, :attribute, :sort, :exactness]

  @nested_schema [
    synonyms: [type: {:or, [:map, {:list, :any}]}, required: false],
    typo_tolerance: [
      type: {:or, [:keyword_list, :map]},
      keys: [
        enabled: [type: :boolean, required: false],
        min_word_size_for_typos: [type: :map, required: false],
        disable_on_words: [type: {:list, :string}, required: false],
        disable_on_attributes: [type: {:list, :string}, required: false]
      ],
      required: false
    ],
    ranking_rules: [type: {:list, {:or, [:atom, :string]}}, required: false],
    ranking_rules_strict?: [type: :boolean, required: false],
    distinct_attribute: [type: {:or, [:atom, :string, nil]}, required: false],
    stop_words: [type: {:list, :string}, required: false],
    searchable_attributes: [type: {:list, :any}, required: false],
    sortable_attributes: [type: {:list, :any}, required: false],
    filterable_attributes: [type: {:list, :any}, required: false],
    displayed_attributes: [type: {:list, :any}, required: false]
  ]

  @spec validate(term()) :: {:ok, map()} | {:error, String.t()}
  def validate(value) when is_map(value) do
    canonical = normalize(value)

    case validate_recognized_subkeys(canonical) do
      :ok -> {:ok, check_ranking_rules_completeness(canonical)}
      {:error, message} -> {:error, message}
    end
  end

  def validate(value) do
    if Macro.quoted_literal?(value) do
      case Code.eval_quoted(value) do
        {evaluated, _binding} when is_map(evaluated) -> validate(evaluated)
        _ -> {:error, "expected settings to be a plain map"}
      end
    else
      {:error, "expected settings to be a plain map"}
    end
  end

  @spec normalize(map()) :: map()
  def normalize(value) when is_map(value) do
    entries = Enum.map(value, fn {raw_key, val} -> {raw_key, canonicalize_key(raw_key), val} end)

    if Enum.any?(entries, fn {raw_key, _, _} -> camel_case_source_key?(raw_key) end) do
      IO.puts(
        :stderr,
        "[scrypath] a schema declared settings using camelCase keys. Canonical form is snake_case atom keys for recognized settings. Both forms work; No action required."
      )
    end

    {recognized, unrecognized} = Enum.split_with(entries, fn {_, key, _} -> is_atom(key) end)

    recognized_map = Map.new(recognized, fn {_, key, val} -> {key, val} end)
    unrecognized_map = Map.new(unrecognized, fn {_, {:unrecognized, key}, val} -> {key, val} end)

    Map.put(recognized_map, :__unrecognized__, unrecognized_map)
  end

  @spec canonicalize_key(term()) :: atom() | {:unrecognized, term()}
  def canonicalize_key(key) when is_atom(key) do
    cond do
      key in @recognized_subkeys ->
        key

      key in @attribute_keys ->
        key

      key in @legacy_camel_allowlist ->
        key |> Atom.to_string() |> Macro.underscore() |> String.to_existing_atom()

      true ->
        {:unrecognized, key}
    end
  end

  def canonicalize_key(key) when is_binary(key) do
    if key in @legacy_camel_strings do
      legacy = Enum.find(@legacy_camel_allowlist, &(Atom.to_string(&1) == key))
      canonicalize_key(legacy)
    else
      existing = safe_existing_atom(Macro.underscore(key))

      if existing in @recognized_subkeys or existing in @attribute_keys,
        do: existing,
        else: {:unrecognized, key}
    end
  end

  def canonicalize_key(key), do: {:unrecognized, key}

  @spec validate_recognized_subkeys(map()) :: :ok | {:error, String.t()}
  def validate_recognized_subkeys(canonical) when is_map(canonical) do
    canonical
    |> Map.delete(:__unrecognized__)
    |> Map.to_list()
    |> NimbleOptions.validate(@nested_schema)
    |> case do
      {:ok, _} -> :ok
      {:error, %NimbleOptions.ValidationError{} = error} -> {:error, Exception.message(error)}
    end
  end

  @spec check_ranking_rules_completeness(map()) :: map()
  def check_ranking_rules_completeness(canonical) when is_map(canonical) do
    rules = canonical[:ranking_rules]

    if is_list(rules) and Map.get(canonical, :ranking_rules_strict?) != false do
      normalized = Enum.map(rules, &normalize_rule/1)
      missing = @meilisearch_default_ranking_rules -- normalized

      if missing != [] do
        IO.puts(
          :stderr,
          "[scrypath] ranking_rules is missing the following Meilisearch defaults: #{inspect(missing)}. Add them or set ranking_rules_strict?: false. This is a warning; reindex will hard-error (TUNE-04)."
        )
      end
    end

    canonical
  end

  defp normalize_rule(rule) when is_atom(rule), do: rule
  defp normalize_rule(rule) when is_binary(rule), do: safe_existing_atom(rule) || rule
  defp normalize_rule(rule), do: rule

  defp camel_case_source_key?(key) when is_atom(key), do: key in @legacy_camel_allowlist
  defp camel_case_source_key?(key) when is_binary(key), do: String.match?(key, ~r/[A-Z]/)
  defp camel_case_source_key?(_), do: false

  defp safe_existing_atom(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end
end
