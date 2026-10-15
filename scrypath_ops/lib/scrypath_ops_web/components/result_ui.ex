defmodule ScrypathOpsWeb.ResultUi do
  @moduledoc "Readable search-hit fields, preserving the returned data and raw inspection."
  use Phoenix.Component
  import ScrypathOpsWeb.OpsUi

  attr(:hit, :map, required: true)
  attr(:position, :integer, required: true)
  attr(:schema, :atom, default: nil)

  def result_hit(assigns) do
    {title_key, title} = lead_text(assigns.hit, ~w(name title sku))
    {description_key, description} = lead_text(assigns.hit, ~w(description summary body content))

    fields =
      assigns.hit
      |> Enum.reject(fn {key, _} -> key in [title_key, description_key] end)
      |> Enum.sort_by(fn {key, _} -> to_string(key) end)

    assigns =
      assigns
      |> assign(:title, title || "Result #{assigns.position}")
      |> assign(:description, description)
      |> assign(:fields, fields)
      |> assign(
        :raw,
        inspect(assigns.hit,
          pretty: true,
          limit: :infinity,
          printable_limit: :infinity,
          charlists: :as_lists
        )
      )

    ~H"""
    <.ops_result_row title={@title} class="ops-search-hit ops-readable-hit">
      <p :if={@schema} class="ops-hit-source">{schema_name(@schema)} · Result {@position}</p>
      <p :if={@description} class="ops-hit-description">{@description}</p>
      <dl :if={@fields != []} class="ops-hit-fields">
        <div :for={{key, value} <- Enum.take(@fields, 6)}>
          <dt>{field_label(key)}</dt>
          <dd><.result_value value={value} /></dd>
        </div>
      </dl>
      <details :if={length(@fields) > 6} class="ops-value-details">
        <summary>Other fields ({length(@fields) - 6})</summary>
        <dl class="ops-hit-fields">
          <div :for={{key, value} <- Enum.drop(@fields, 6)}>
            <dt>{field_label(key)}</dt>
            <dd><.result_value value={value} /></dd>
          </div>
        </dl>
      </details>
      <.ops_disclosure summary="Raw hit payload" variant={:compact}>
        <.ops_code_block variant={:compact} text={@raw} copy copy_label="Copy hit payload" />
      </.ops_disclosure>
    </.ops_result_row>
    """
  end

  attr(:value, :any, required: true)
  attr(:depth, :integer, default: 0)

  def result_value(assigns) do
    ~H"""
    <%= cond do %>
      <% is_nil(@value) -> %>
        <span class="ops-value-null">null</span>
      <% is_binary(@value) -> %>
        <span :if={@value != ""}>{@value}</span>
        <span :if={@value == ""} class="ops-value-null">Empty string</span>
      <% is_number(@value) or is_boolean(@value) -> %>
        <span class="tabular-nums">{to_string(@value)}</span>
      <% @depth >= 3 -> %>
        <span class="ops-value-null">Nested value — see Raw hit payload</span>
      <% is_map(@value) -> %>
        <details class="ops-value-details">
          <summary>
            {map_size(@value)} {if map_size(@value) == 1, do: "field", else: "fields"}
          </summary>
          <dl class="ops-hit-fields">
            <div :for={
              {key, value} <-
                @value |> Enum.sort_by(fn {key, _} -> to_string(key) end) |> Enum.take(20)
            }>
              <dt>{field_label(key)}</dt>
              <dd><.result_value value={value} depth={@depth + 1} /></dd>
            </div>
          </dl>
          <p :if={map_size(@value) > 20} class="ops-value-null">
            First 20 fields shown; Raw hit payload contains the full value.
          </p>
        </details>
      <% is_list(@value) -> %>
        <details class="ops-value-details">
          <summary>{length(@value)} {if length(@value) == 1, do: "item", else: "items"}</summary>
          <ol>
            <li :for={value <- Enum.take(@value, 20)}>
              <.result_value value={value} depth={@depth + 1} />
            </li>
          </ol>
          <p :if={length(@value) > 20} class="ops-value-null">
            First 20 items shown; Raw hit payload contains the full value.
          </p>
        </details>
      <% true -> %>
        <span>{inspect(@value)}</span>
    <% end %>
    """
  end

  defp lead_text(hit, keys) do
    Enum.find_value(keys, {nil, nil}, fn key ->
      Enum.find_value([key, existing_key(key)], fn candidate ->
        case Map.get(hit, candidate) do
          value when is_binary(value) and value != "" -> {candidate, value}
          _ -> nil
        end
      end)
    end)
  end

  # Only these fixed developer-owned names are atomized; never external hit keys.
  defp existing_key("name"), do: :name
  defp existing_key("title"), do: :title
  defp existing_key("sku"), do: :sku
  defp existing_key("description"), do: :description
  defp existing_key("summary"), do: :summary
  defp existing_key("body"), do: :body
  defp existing_key("content"), do: :content

  defp field_label(key), do: key |> to_string() |> String.replace("_", " ") |> String.capitalize()
  defp schema_name(schema), do: schema |> Module.split() |> List.last()
end
