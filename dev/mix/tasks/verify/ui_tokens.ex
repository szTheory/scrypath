defmodule Mix.Tasks.Verify.UiTokens do
  @moduledoc false
  use Mix.Task

  @extension "org.scrypath"
  @supported_types [
    "color",
    "cubicBezier",
    "dimension",
    "duration",
    "fontFamily",
    "fontWeight",
    "number",
    "shadow",
    "string"
  ]

  @impl true
  def run([]) do
    root = Path.dirname(Mix.Project.project_file())

    check!(
      Path.join(root, "brandbook/tokens/tokens.json"),
      Path.join(root, "scrypath_ops/assets/css/app.css")
    )
  end

  def run(args),
    do: Mix.raise("verify.ui_tokens does not accept arguments: #{Enum.join(args, " ")}")

  @doc false
  def check!(json_path, css_path) do
    tokens =
      json_path
      |> File.read!()
      |> Jason.decode!(objects: :ordered_objects)
      |> normalize_json!("$")

    validate_document!(tokens)
    css_themes = css_path |> File.read!() |> parse_css_themes!()
    validate_ops_mirror!(tokens, css_themes)
    :ok
  rescue
    error in [ArgumentError, Jason.DecodeError, File.Error] ->
      Mix.raise("UI token contract: #{Exception.message(error)}")
  end

  defp normalize_json!(%Jason.OrderedObject{values: pairs}, path) do
    keys = Enum.map(pairs, &elem(&1, 0))

    if length(keys) != length(Enum.uniq(keys)) do
      duplicate =
        keys
        |> Enum.frequencies()
        |> Enum.find_value(fn {key, count} -> if count > 1, do: key end)

      raise ArgumentError, "#{path}: duplicate JSON key #{inspect(duplicate)}"
    end

    Map.new(pairs, fn {key, value} ->
      {key, normalize_json!(value, "#{path}.#{key}")}
    end)
  end

  defp normalize_json!(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.map(fn {value, index} -> normalize_json!(value, "#{path}[#{index}]") end)
  end

  defp normalize_json!(value, _path), do: value

  defp validate_document!(tokens) when is_map(tokens) do
    expected = [
      "$description",
      "$extensions",
      "color",
      "font",
      "motion",
      "ops",
      "radius",
      "shadow",
      "space"
    ]

    assert_keys!(tokens, expected, "$")
    validate_description!(tokens["$description"], "$")
    validate_extensions!(tokens["$extensions"], "$")
    org_extension!(tokens["$extensions"], "$")

    token_index = collect_tokens!(tokens, [], nil, %{})

    if map_size(token_index) == 0 do
      raise ArgumentError, "$: document contains no tokens"
    end

    Enum.each(token_index, fn {path, token} ->
      value = resolve_token!(path, token_index, [])
      validate_typed_value!(token.type, value, path)
    end)

    validate_group_type!(tokens["color"], "color", "color")
    validate_group_type!(tokens["font"]["family"], "font.family", "fontFamily")
    validate_group_type!(tokens["font"]["size"], "font.size", "dimension")
    validate_group_type!(tokens["font"]["leading"], "font.leading", "number")
    validate_group_type!(tokens["font"]["weight"], "font.weight", "fontWeight")
    validate_group_type!(tokens["space"], "space", "dimension")
    validate_group_type!(tokens["radius"], "radius", "dimension")
    validate_group_type!(tokens["shadow"], "shadow", "shadow")
    validate_group_type!(tokens["motion"]["duration"], "motion.duration", "duration")
    validate_group_type!(tokens["motion"]["ease"], "motion.ease", "cubicBezier")

    unless is_map(tokens["ops"]) do
      raise ArgumentError, "ops must be a DTCG group"
    end

    :ok
  end

  defp validate_document!(_tokens), do: raise(ArgumentError, "$: root must be a DTCG group")

  defp collect_tokens!(node, path, inherited_type, acc) when is_map(node) do
    own_type = Map.get(node, "$type", inherited_type)

    if Map.has_key?(node, "$value") do
      allowed = ["$value", "$type", "$description", "$extensions"]
      assert_subset_keys!(node, allowed, display_path(path))

      type =
        own_type ||
          raise(ArgumentError, "#{display_path(path)}: token has no inherited or explicit $type")

      ensure_supported_type!(type, display_path(path))
      validate_optional_metadata!(node, display_path(path))

      if path == [] do
        raise ArgumentError, "$: root cannot be a token"
      end

      Map.put(acc, Enum.join(path, "."), %{type: type, value: node["$value"], metadata: node})
    else
      assert_group_metadata!(node, display_path(path))
      validate_optional_metadata!(node, display_path(path))

      children = Map.drop(node, ["$type", "$description", "$extensions"])

      if map_size(children) == 0 and path != [] do
        raise ArgumentError, "#{display_path(path)}: empty groups are unsupported"
      end

      Enum.reduce(children, acc, fn {key, child}, result ->
        validate_name!(key, path)
        collect_tokens!(child, path ++ [key], own_type, result)
      end)
    end
  end

  defp collect_tokens!(_node, path, _inherited_type, _acc) do
    raise ArgumentError, "#{display_path(path)}: group or token must be an object"
  end

  defp validate_name!(name, path) when is_binary(name) do
    if name == "" or String.contains?(name, [".", "{", "}"]) or String.starts_with?(name, "$") do
      raise ArgumentError, "#{display_path(path)}: unsupported DTCG name #{inspect(name)}"
    end
  end

  defp validate_name!(name, path),
    do: raise(ArgumentError, "#{display_path(path)}: invalid name #{inspect(name)}")

  defp validate_optional_metadata!(node, path) do
    if Map.has_key?(node, "$description"), do: validate_description!(node["$description"], path)
    if Map.has_key?(node, "$extensions"), do: validate_extensions!(node["$extensions"], path)
    :ok
  end

  defp validate_description!(description, _path)
       when is_binary(description) and description != "", do: :ok

  defp validate_description!(_description, path),
    do: raise(ArgumentError, "#{path}: $description must be a non-empty string")

  defp validate_extensions!(extensions, path) when is_map(extensions) do
    if map_size(extensions) == 0 do
      raise ArgumentError, "#{path}: $extensions must contain a namespaced extension"
    end

    Enum.each(Map.keys(extensions), fn namespace ->
      unless Regex.match?(~r/^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*)+$/, namespace) do
        raise ArgumentError, "#{path}: extension key #{inspect(namespace)} is not namespaced"
      end
    end)
  end

  defp validate_extensions!(_extensions, path),
    do: raise(ArgumentError, "#{path}: $extensions must be an object")

  defp org_extension!(extensions, path) do
    case extensions[@extension] do
      extension when is_map(extension) -> extension
      _ -> raise ArgumentError, "#{path}: missing #{@extension} extension"
    end
  end

  defp ensure_supported_type!(type, _path) when type in @supported_types, do: :ok

  defp ensure_supported_type!(type, path),
    do: raise(ArgumentError, "#{path}: unsupported $type #{inspect(type)}")

  defp validate_group_type!(group, path, expected_type) when is_map(group) do
    unless Map.get(group, "$type") == expected_type do
      raise ArgumentError, "#{path}: expected group $type #{inspect(expected_type)}"
    end
  end

  defp validate_group_type!(_group, path, _expected_type),
    do: raise(ArgumentError, "#{path}: expected a typed group")

  defp resolve_token!(path, tokens, stack) do
    if path in stack do
      raise ArgumentError, "#{path}: token reference cycle: #{Enum.join(stack ++ [path], " -> ")}"
    end

    case tokens[path] do
      nil ->
        raise ArgumentError, "#{path}: unresolved token reference"

      %{value: value, type: type} ->
        case value do
          <<"{", reference::binary-size(byte_size(value) - 2), "}">> ->
            target = resolve_path!(reference, path)

            case tokens[target] do
              nil ->
                raise ArgumentError, "#{path}: unresolved token reference #{inspect(reference)}"

              %{type: ^type} ->
                resolve_token!(target, tokens, stack ++ [path])

              %{type: target_type} ->
                raise ArgumentError,
                      "#{path}: #{type} reference cannot target #{target_type} token #{target}"
            end

          value ->
            value
        end
    end
  end

  defp resolve_path!(reference, path) do
    if reference == "" or String.contains?(reference, ["{", "}"]) do
      raise ArgumentError,
            "#{display_path(path)}: malformed token reference #{inspect(reference)}"
    end

    reference
  end

  defp validate_typed_value!("color", value, path), do: validate_color!(value, path)
  defp validate_typed_value!("dimension", value, path), do: validate_dimension!(value, path)
  defp validate_typed_value!("number", value, path), do: validate_number!(value, path)
  defp validate_typed_value!("fontFamily", value, path), do: validate_font_family!(value, path)
  defp validate_typed_value!("fontWeight", value, path), do: validate_font_weight!(value, path)
  defp validate_typed_value!("duration", value, path), do: validate_duration!(value, path)
  defp validate_typed_value!("cubicBezier", value, path), do: validate_cubic_bezier!(value, path)
  defp validate_typed_value!("shadow", value, path), do: validate_shadow!(value, path)
  defp validate_typed_value!("string", value, _path) when is_binary(value), do: :ok

  defp validate_typed_value!("string", _value, path),
    do: raise(ArgumentError, "#{path}: string token must have a string $value")

  defp validate_color!(value, path) when is_map(value) do
    assert_keys!(value, ["colorSpace", "components", "hex", "alpha"], path, optional: ["alpha"])

    unless value["colorSpace"] == "srgb" do
      raise ArgumentError, "#{path}: only sRGB color values are supported"
    end

    components = value["components"]

    unless is_list(components) and length(components) == 3 and
             Enum.all?(components, &unit_interval?/1) do
      raise ArgumentError, "#{path}: sRGB components must be three numbers in [0, 1]"
    end

    if Map.has_key?(value, "alpha") and not unit_interval?(value["alpha"]) do
      raise ArgumentError, "#{path}: color alpha must be a number in [0, 1]"
    end

    expected_hex = components_to_hex(components)

    unless is_binary(value["hex"]) and String.downcase(value["hex"]) == expected_hex do
      raise ArgumentError, "#{path}: color components do not agree with the hex fallback"
    end
  end

  defp validate_color!(value, path) when is_binary(value) do
    unless alias?(value),
      do: raise(ArgumentError, "#{path}: color must be a typed sRGB object or token reference")
  end

  defp validate_color!(_value, path), do: raise(ArgumentError, "#{path}: invalid color value")

  defp validate_dimension!(%{"value" => number, "unit" => unit} = value, path) do
    assert_keys!(value, ["value", "unit"], path)

    unless finite_number?(number) and number > 0 and unit in ["px", "rem"] do
      raise ArgumentError, "#{path}: dimension must be a positive px or rem value"
    end
  end

  defp validate_dimension!(value, path) when is_binary(value) do
    unless alias?(value),
      do:
        raise(ArgumentError, "#{path}: dimension must be a value/unit object or token reference")
  end

  defp validate_dimension!(_value, path),
    do: raise(ArgumentError, "#{path}: invalid dimension value")

  defp validate_number!(value, path) do
    unless finite_number?(value), do: raise(ArgumentError, "#{path}: number token must be finite")
  end

  defp validate_font_family!(value, _path) when is_binary(value) and value != "", do: :ok

  defp validate_font_family!(value, path) when is_list(value) do
    unless value != [] and Enum.all?(value, &(is_binary(&1) and &1 != "")) do
      raise ArgumentError, "#{path}: fontFamily must be a non-empty string or array of strings"
    end
  end

  defp validate_font_family!(_value, path),
    do: raise(ArgumentError, "#{path}: invalid fontFamily value")

  defp validate_font_weight!(value, path) do
    unless is_integer(value) and value in 1..1000 do
      raise ArgumentError, "#{path}: fontWeight must be an integer in [1, 1000]"
    end
  end

  defp validate_duration!(%{"value" => value, "unit" => unit} = duration, path) do
    assert_keys!(duration, ["value", "unit"], path)

    unless finite_number?(value) and value >= 0 and unit in ["ms", "s"] do
      raise ArgumentError, "#{path}: duration must use a non-negative value and ms or s unit"
    end
  end

  defp validate_duration!(_value, path),
    do: raise(ArgumentError, "#{path}: invalid duration value")

  defp validate_cubic_bezier!(value, path) when is_list(value) and length(value) == 4 do
    x1 = Enum.at(value, 0)
    x2 = Enum.at(value, 2)

    unless Enum.all?(value, &finite_number?/1) and x1 >= 0 and x1 <= 1 and x2 >= 0 and x2 <= 1 do
      raise ArgumentError,
            "#{path}: cubicBezier needs four finite numbers and x coordinates in [0, 1]"
    end
  end

  defp validate_cubic_bezier!(_value, path),
    do: raise(ArgumentError, "#{path}: cubicBezier must contain four numbers")

  defp validate_shadow!(value, path) when is_list(value) and value != [] do
    Enum.with_index(value)
    |> Enum.each(fn {layer, index} -> validate_shadow_layer!(layer, "#{path}[#{index}]") end)
  end

  defp validate_shadow!(value, path) when is_map(value), do: validate_shadow_layer!(value, path)

  defp validate_shadow!(value, path) when is_binary(value) do
    unless value == "none",
      do: raise(ArgumentError, "#{path}: only CSS none is supported as a string shadow override")
  end

  defp validate_shadow!(_value, path), do: raise(ArgumentError, "#{path}: invalid shadow value")

  defp validate_shadow_layer!(layer, path) when is_map(layer) do
    assert_keys!(layer, ["color", "offsetX", "offsetY", "blur", "spread", "type"], path)
    validate_color!(layer["color"], "#{path}.color")

    Enum.each(
      ["offsetX", "offsetY", "blur", "spread"],
      &validate_shadow_dimension!(layer[&1], "#{path}.#{&1}")
    )

    unless layer["type"] in ["dropShadow", "innerShadow"] do
      raise ArgumentError, "#{path}: shadow type must be dropShadow or innerShadow"
    end
  end

  defp validate_shadow_layer!(_layer, path),
    do: raise(ArgumentError, "#{path}: shadow layers must be objects")

  defp validate_shadow_dimension!(%{"value" => value, "unit" => unit} = dimension, path) do
    assert_keys!(dimension, ["value", "unit"], path)

    unless finite_number?(value) and unit in ["px", "rem"] do
      raise ArgumentError, "#{path}: shadow dimension must use px or rem"
    end
  end

  defp validate_shadow_dimension!(_value, path),
    do: raise(ArgumentError, "#{path}: invalid shadow dimension")

  defp validate_ops_mirror!(tokens, css_themes) do
    ops = tokens["ops"]
    assert_keys!(ops, ["dark", "light", "$description", "$extensions"], "ops")
    validate_description!(ops["$description"], "ops")
    validate_extensions!(ops["$extensions"], "ops")
    org_extension!(ops["$extensions"], "ops")
    token_index = collect_tokens!(tokens, [], nil, %{})

    Enum.each(["dark", "light"], fn theme ->
      validate_ops_theme!(theme, ops[theme], css_themes[theme], token_index)
    end)

    :ok
  end

  defp validate_ops_theme!(theme, group, css_properties, token_index) when is_map(group) do
    path = "ops.#{theme}"
    property_tokens = flatten_ops_group!(group, path, %{})

    mapped =
      Enum.reduce(property_tokens, %{}, fn {token_path, metadata}, acc ->
        extension = org_extension!(metadata["$extensions"], token_path)
        css = extension["css"]

        unless is_map(css) and is_binary(css["name"]) and is_binary(css["expression"]) do
          raise ArgumentError, "#{token_path}: org.scrypath.css must define name and expression"
        end

        if Map.has_key?(acc, css["name"]) do
          raise ArgumentError, "#{path}: duplicate mapping for #{css["name"]}"
        end

        Map.put(acc, css["name"], {token_path, css["expression"], extension})
      end)

    expected_keys = Map.keys(css_properties) |> Enum.sort()
    actual_keys = Map.keys(mapped) |> Enum.sort()

    unless actual_keys == expected_keys do
      raise ArgumentError,
            "#{path}: mapped CSS property set differs (missing #{inspect(expected_keys -- actual_keys)}, extra #{inspect(actual_keys -- expected_keys)})"
    end

    Enum.each(css_properties, fn {name, expression} ->
      {token_path, declared_expression, extension} = mapped[name]

      unless declared_expression == expression do
        raise ArgumentError,
              "#{token_path}: CSS expression mapping for #{name} does not match the live CSS source"
      end

      value = resolve_token!(token_path, token_index, [])
      expected_type = css_value_type!(expression, token_path)
      actual_type = token_index[token_path].type

      unless actual_type == expected_type do
        raise ArgumentError,
              "#{token_path}: CSS #{name} requires #{expected_type}, found #{actual_type}"
      end

      compare_css_value!(expression, value, extension, theme, token_index, token_path)
    end)
  end

  defp validate_ops_theme!(_theme, _group, _css_properties, _token_index),
    do: raise(ArgumentError, "ops theme must be a group")

  defp flatten_ops_group!(group, path, acc) do
    group
    |> Map.drop(["$description", "$extensions", "$type"])
    |> Enum.reduce(acc, fn {key, value}, result ->
      token_path = "#{path}.#{key}"

      if is_map(value) and Map.has_key?(value, "$value") do
        Map.put(result, token_path, value)
      else
        raise ArgumentError, "#{token_path}: nested and non-token Ops mappings are unsupported"
      end
    end)
  end

  defp css_value_type!("color-mix(" <> _expression, path) do
    if path do
      "color"
    end
  end

  defp css_value_type!("#" <> _color, _path), do: "color"

  defp css_value_type!(value, path) do
    cond do
      Regex.match?(~r/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:px|rem)$/, value) -> "dimension"
      Regex.match?(~r/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/, value) -> "number"
      true -> raise ArgumentError, "#{path}: unsupported CSS expression #{inspect(value)}"
    end
  end

  defp compare_css_value!("#" <> _ = expression, value, _extension, _theme, _tokens, path) do
    expected = css_hex_color!(expression, path)
    validate_color!(value, path)
    actual_hex = value["hex"]

    unless String.downcase(actual_hex) == String.downcase(expected["hex"]) and
             close_components?(value["components"], expected["components"]) and
             Map.get(value, "alpha", 1) == 1 do
      raise ArgumentError, "#{path}: typed color does not match CSS #{expression}"
    end
  end

  defp compare_css_value!("color-mix(" <> _ = expression, value, extension, theme, tokens, path) do
    case Regex.run(
           ~r/^color-mix\(in oklch,\s*var\((--[a-z0-9-]+)\)\s+(\d+(?:\.\d+)?)%,\s*transparent\)$/,
           expression
         ) do
      [_, reference_name, percent] ->
        expected_reference = "{ops.#{theme}.#{String.trim_leading(reference_name, "--")}}"
        reference = extension["reference"]

        unless reference == expected_reference do
          raise ArgumentError, "#{path}: muted color must map to #{expected_reference}"
        end

        target_path = String.slice(expected_reference, 1, byte_size(expected_reference) - 2)
        target = resolve_token!(target_path, tokens, [])
        expected_alpha = parse_number!(percent, path) / 100

        unless is_map(target) and is_map(value) and value["colorSpace"] == target["colorSpace"] and
                 close_components?(value["components"], target["components"]) and
                 String.downcase(value["hex"]) == String.downcase(target["hex"]) and
                 value["alpha"] == expected_alpha do
          raise ArgumentError,
                "#{path}: typed muted color must preserve the referenced color at alpha #{expected_alpha}"
        end

      _ ->
        raise ArgumentError, "#{path}: unsupported color-mix expression"
    end
  end

  defp compare_css_value!(expression, value, _extension, _theme, _tokens, path) do
    case Regex.run(~r/^([+-]?(?:\d+(?:\.\d*)?|\.\d+))(px|rem)$/, expression,
           capture: :all_but_first
         ) do
      [number, unit] ->
        unless is_map(value) and value["unit"] == unit and
                 value["value"] == parse_number!(number, path) do
          raise ArgumentError, "#{path}: typed dimension does not match CSS #{expression}"
        end

      nil ->
        expected = parse_number!(expression, path)

        unless value == expected,
          do: raise(ArgumentError, "#{path}: typed number does not match CSS #{expression}")
    end
  end

  defp parse_css_themes!(css) do
    blocks =
      Regex.scan(~r/@plugin\s+"[^"]*daisyui-theme"\s*\{([^{}]*)\}/s, css, capture: :all_but_first)

    unless length(blocks) == 2 do
      raise ArgumentError, "CSS must contain exactly two bounded daisyui-theme blocks"
    end

    Enum.reduce(blocks, %{}, fn [body], themes ->
      name = theme_name!(body)

      if Map.has_key?(themes, name) do
        raise ArgumentError, "CSS contains duplicate #{name} theme blocks"
      end

      Map.put(themes, name, parse_theme_properties!(body, name))
    end)
    |> then(fn themes ->
      unless Map.keys(themes) |> Enum.sort() == ["dark", "light"] do
        raise ArgumentError, "CSS must define exactly one dark and one light theme"
      end

      themes
    end)
  end

  defp theme_name!(body) do
    case Regex.run(~r/^\s*name:\s*"(dark|light)"\s*;/m, body) do
      [_, name] -> name
      _ -> raise ArgumentError, "CSS theme block has a missing or unsupported name"
    end
  end

  defp parse_theme_properties!(body, theme) do
    body
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, properties ->
      line = String.trim(line)

      cond do
        line == "" ->
          properties

        String.starts_with?(line, "--") ->
          case Regex.run(~r/^(--[a-z0-9-]+):\s*([^;{}]+);$/, line, capture: :all_but_first) do
            [name, expression] ->
              if Map.has_key?(properties, name) do
                raise ArgumentError, "CSS #{theme} theme defines #{name} more than once"
              end

              Map.put(properties, name, String.trim(expression))

            _ ->
              raise ArgumentError,
                    "CSS #{theme} theme contains an unsupported custom property declaration"
          end

        Regex.match?(~r/^(name|default|prefersdark|color-scheme):\s*[^;{}]+;$/, line) ->
          properties

        true ->
          raise ArgumentError,
                "CSS #{theme} theme contains an unsupported declaration #{inspect(line)}"
      end
    end)
  end

  defp css_hex_color!("#" <> digits, path) do
    unless Regex.match?(~r/^(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/, digits) do
      raise ArgumentError, "#{path}: unsupported CSS hex color"
    end

    expanded =
      if byte_size(digits) == 3,
        do: digits |> String.graphemes() |> Enum.map_join(&(&1 <> &1)),
        else: digits

    components = for <<pair::binary-size(2) <- expanded>>, do: String.to_integer(pair, 16) / 255
    %{"components" => components, "hex" => "##{expanded}"}
  end

  defp components_to_hex(components) do
    encoded =
      Enum.map_join(components, fn component ->
        component
        |> Kernel.*(255)
        |> round()
        |> Integer.to_string(16)
        |> String.pad_leading(2, "0")
      end)

    "##{String.downcase(encoded)}"
  end

  defp close_components?(left, right)
       when is_list(left) and is_list(right) and length(left) == length(right) do
    Enum.zip(left, right) |> Enum.all?(fn {a, b} -> abs(a - b) < 1.0e-12 end)
  end

  defp close_components?(_left, _right), do: false

  defp assert_keys!(map, expected, path, opts \\ [])

  defp assert_keys!(map, expected, path, opts) when is_map(map) do
    optional = Keyword.get(opts, :optional, [])
    actual = Map.keys(map) |> Enum.sort()
    required = expected -- optional
    missing = required -- actual
    extra = actual -- expected

    if missing != [] or extra != [] do
      raise ArgumentError,
            "#{path}: invalid keys (missing #{inspect(missing)}, extra #{inspect(extra)})"
    end
  end

  defp assert_keys!(_map, _expected, path, _opts),
    do: raise(ArgumentError, "#{path}: expected an object")

  defp assert_subset_keys!(map, allowed, path) when is_map(map) do
    extra = Map.keys(map) -- allowed
    if extra != [], do: raise(ArgumentError, "#{path}: unsupported properties #{inspect(extra)}")
  end

  defp assert_subset_keys!(_map, _allowed, path),
    do: raise(ArgumentError, "#{path}: expected an object")

  defp assert_group_metadata!(map, path) when is_map(map) do
    unknown =
      map
      |> Map.keys()
      |> Enum.filter(
        &(String.starts_with?(&1, "$") and &1 not in ["$type", "$description", "$extensions"])
      )

    if unknown != [],
      do: raise(ArgumentError, "#{path}: unsupported group properties #{inspect(unknown)}")
  end

  defp assert_group_metadata!(_map, path), do: raise(ArgumentError, "#{path}: expected an object")

  defp alias?(value), do: Regex.match?(~r/^\{[^{}]+\}$/, value)
  defp unit_interval?(value), do: finite_number?(value) and value >= 0 and value <= 1
  defp finite_number?(value) when is_integer(value), do: true
  defp finite_number?(value) when is_float(value), do: value == value and abs(value) < 1.0e308
  defp finite_number?(_value), do: false

  defp parse_number!(value, path) do
    case Float.parse(value) do
      {number, ""} -> number
      _ -> raise ArgumentError, "#{path}: invalid numeric CSS value #{inspect(value)}"
    end
  end

  defp display_path([]), do: "$"
  defp display_path(path), do: Enum.join(path, ".")
end
