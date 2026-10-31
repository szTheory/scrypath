defmodule Mix.Tasks.UiTokensContractTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 600_000
  @root Path.expand("../../..", __DIR__)
  @token_path "brandbook/tokens/tokens.json"
  @css_path "scrypath_ops/assets/css/app.css"
  @legacy_shadows %{
    "sm" => %{
      "light" => "0 1px 2px rgba(20,25,35,.06), 0 1px 1px rgba(20,25,35,.04)",
      "dark" => "0 1px 2px rgba(0,0,0,.5)"
    },
    "md" => %{
      "light" => "0 4px 12px rgba(20,25,35,.08), 0 1px 2px rgba(20,25,35,.05)",
      "dark" => "0 6px 18px rgba(0,0,0,.55)"
    },
    "lg" => %{
      "light" => "0 12px 32px rgba(20,25,35,.12), 0 2px 6px rgba(20,25,35,.06)",
      "dark" => "0 18px 44px rgba(0,0,0,.6)"
    },
    "glow" => %{
      "light" => "none",
      "dark" => "0 0 0 1px rgba(108,92,231,.25), 0 8px 30px rgba(108,92,231,.18)"
    }
  }

  test "brandbook token document uses DTCG token structures" do
    tokens = read_tokens!(@root)

    assert Map.has_key?(tokens, "$description")
    refute Map.has_key?(tokens, "$schema")
    refute Map.has_key?(tokens, "_meta")
    assert tokens["color"]["$type"] == "color"
    assert tokens["color"]["primitive"]["night"]["$value"]["colorSpace"] == "srgb"
    assert is_map(tokens["ops"]["light"])
    assert is_map(tokens["ops"]["dark"])

    assert tokens["ops"]["$extensions"]["org.scrypath"]["mode_group_convention"] =~
             "does not claim a standardized DTCG mode resolver convention"
  end

  test "bounded validator accepts the whole CSS-authoritative source and preserves brand values" do
    token_file = Path.join(@root, @token_path)
    css_file = Path.join(@root, @css_path)

    assert Mix.Tasks.Verify.UiTokens.check!(token_file, css_file) == :ok

    assert_brand_values!(
      read_tokens!(@root),
      File.read!(Path.join(@root, "brandbook/tokens/tokens.css"))
    )
  end

  test "bounded validator rejects duplicate keys, bad types, bad colors and unresolved aliases" do
    json = File.read!(Path.join(@root, @token_path))
    css = File.read!(Path.join(@root, @css_path))
    {json_file, css_file, temp} = fixture_paths!()
    File.write!(css_file, css)

    duplicate_key =
      String.replace(
        json,
        "{\n  \"$description\":",
        "{\n  \"$description\": \"duplicate\",\n  \"$description\":",
        global: false
      )

    File.write!(json_file, duplicate_key)

    assert_raise Mix.Error, ~r/duplicate JSON key/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    tokens = Jason.decode!(json)

    bad_color =
      put_in(tokens, ["color", "primitive", "night", "$value", "components", Access.at(0)], 0.5)

    assert_rejected!(
      bad_color,
      json_file,
      css_file,
      ~r/components do not agree with the hex fallback/
    )

    bad_alpha = put_in(tokens, ["ops", "dark", "ops-text-muted", "$value", "alpha"], 1.01)
    assert_rejected!(bad_alpha, json_file, css_file, ~r/color alpha must be a number in \[0, 1\]/)

    bad_curve = put_in(tokens, ["motion", "ease", "$value", Access.at(0)], 2.0)
    assert_rejected!(bad_curve, json_file, css_file, ~r/cubicBezier needs four finite numbers/)

    unresolved =
      put_in(tokens, ["color", "semantic", "bg", "light", "$value"], "{color.primitive.unknown}")

    assert_rejected!(unresolved, json_file, css_file, ~r/unresolved token reference/)

    cyclic =
      tokens
      |> put_in(["color", "semantic", "bg", "light", "$value"], "{color.semantic.bg.dark}")
      |> put_in(["color", "semantic", "bg", "dark", "$value"], "{color.semantic.bg.light}")

    assert_rejected!(cyclic, json_file, css_file, ~r/token reference cycle/)
    File.rm_rf!(temp)
  end

  test "bounded validator rejects CSS key, expression, and typed-value drift" do
    json = File.read!(Path.join(@root, @token_path))
    css = File.read!(Path.join(@root, @css_path))
    {json_file, css_file, temp} = fixture_paths!()
    File.write!(json_file, json)

    changed_css = String.replace(css, "--ops-bg: #111419;", "--ops-bg: #121519;", global: false)
    refute changed_css == css
    File.write!(css_file, changed_css)

    assert_raise Mix.Error, ~r/CSS expression mapping for --ops-bg/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    duplicate_css =
      String.replace(css, "  --ops-bg: #111419;", "  --ops-bg: #111419;\n  --ops-bg: #111419;",
        global: false
      )

    File.write!(css_file, duplicate_css)

    assert_raise Mix.Error, ~r/defines --ops-bg more than once/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    tokens = Jason.decode!(json)

    changed_json =
      put_in(tokens, ["ops", "dark", "ops-bg", "$value", "hex"], "#121519")
      |> put_in(["ops", "dark", "ops-bg", "$value", "components"], [18 / 255, 21 / 255, 25 / 255])

    File.write!(json_file, Jason.encode!(changed_json, pretty: true))
    File.write!(css_file, css)

    assert_raise Mix.Error, ~r/typed color does not match CSS #111419/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    File.rm_rf!(temp)
  end

  test "bounded validator rejects dark-only mapping gaps and CSS value drift" do
    json = File.read!(Path.join(@root, @token_path))
    css = File.read!(Path.join(@root, @css_path))
    tokens = Jason.decode!(json)
    {json_file, css_file, temp} = fixture_paths!()

    missing_dark_mapping = update_in(tokens, ["ops", "dark"], &Map.delete(&1, "ops-bg"))
    File.write!(json_file, Jason.encode!(missing_dark_mapping, pretty: true))
    File.write!(css_file, css)

    assert_raise Mix.Error, ~r/ops\.dark: mapped CSS property set differs.*--ops-bg/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    extra_token =
      tokens["ops"]["dark"]["ops-bg"]
      |> put_in(["$extensions", "org.scrypath", "css", "name"], "--ops-extra")
      |> put_in(["$extensions", "org.scrypath", "css", "expression"], "#111419")

    extra_dark_mapping = put_in(tokens, ["ops", "dark", "ops-extra"], extra_token)
    File.write!(json_file, Jason.encode!(extra_dark_mapping, pretty: true))

    assert_raise Mix.Error, ~r/ops\.dark: mapped CSS property set differs.*--ops-extra/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    css_drift_cases = [
      {"--ops-text-muted", "64%, transparent", "63%, transparent"},
      {"--ops-text-muted", "var(--color-base-content)", "var(--color-primary)"},
      {"--radius-selector", "0.25rem", "0.3rem"},
      {"--depth", "--depth: 1;", "--depth: 2;"}
    ]

    for {property, old, new} <- css_drift_cases do
      changed_css = replace_dark_theme!(css, old, new)
      refute changed_css == css
      File.write!(json_file, json)
      File.write!(css_file, changed_css)

      assert_raise Mix.Error, ~r/CSS expression mapping for #{Regex.escape(property)}/, fn ->
        Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
      end
    end

    File.rm_rf!(temp)
  end

  @tag :token_review
  test "review rejects inactive CSS themes and quoted theme lookalikes" do
    {json_file, css_file, temp} = fixture_paths!()
    on_exit(fn -> File.rm_rf!(temp) end)
    File.cp!(Path.join(@root, @token_path), json_file)
    css = File.read!(Path.join(@root, @css_path))
    [dark] = Regex.run(~r/@plugin\s+"[^\"]*daisyui-theme"\s*\{\s*name:\s*"dark";[^{}]*\}/s, css)

    for replacement <- ["/*\n#{dark}\n*/", ".caption { content: '#{dark}'; }"] do
      File.write!(css_file, String.replace(css, dark, replacement, global: false))

      assert_raise Mix.Error, ~r/exactly two.*theme blocks/, fn ->
        Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
      end
    end
  end

  @tag :token_review
  test "review retains CSS none as extension metadata instead of an undefined token type" do
    tokens = read_tokens!(@root)
    refute Map.has_key?(tokens["shadow"]["glow"], "light")

    assert get_in(tokens, [
             "shadow",
             "glow",
             "$extensions",
             "org.scrypath",
             "css_literals",
             "light"
           ]) == "none"

    {json_file, css_file, temp} = fixture_paths!()
    on_exit(fn -> File.rm_rf!(temp) end)
    File.cp!(Path.join(@root, @css_path), css_file)

    for bad <- [
          put_in(tokens, ["space", "review"], %{"$type" => "string", "$value" => "none"}),
          put_in(tokens, ["shadow", "sm", "light"], %{"$type" => "shadow", "$value" => "none"})
        ] do
      assert_rejected!(bad, json_file, css_file, ~r/unsupported \$type|invalid shadow/)
    end
  end

  @tag :token_review
  test "review accepts standard shadow layers and validates inset" do
    {json_file, css_file, temp} = fixture_paths!()
    on_exit(fn -> File.rm_rf!(temp) end)
    File.cp!(Path.join(@root, @css_path), css_file)
    tokens = read_tokens!(@root)

    standard =
      update_in(tokens, ["shadow", "sm", "light", "$value"], fn layers ->
        Enum.map(layers, &Map.delete(&1, "type"))
      end)

    File.write!(json_file, Jason.encode!(standard))
    assert Mix.Tasks.Verify.UiTokens.check!(json_file, css_file) == :ok
    inset = put_in(standard, ["shadow", "sm", "light", "$value", Access.at(0), "inset"], true)
    File.write!(json_file, Jason.encode!(inset))
    assert Mix.Tasks.Verify.UiTokens.check!(json_file, css_file) == :ok
    bad = put_in(inset, ["shadow", "sm", "light", "$value", Access.at(0), "inset"], "yes")
    assert_rejected!(bad, json_file, css_file, ~r/inset must be a boolean/)
  end

  @tag :token_review
  test "review accepts finite zero and negative dimensions with explicit units" do
    {json_file, css_file, temp} = fixture_paths!()
    on_exit(fn -> File.rm_rf!(temp) end)
    File.cp!(Path.join(@root, @css_path), css_file)

    for value <- [0, -1, 0.25] do
      tokens =
        put_in(read_tokens!(@root), ["space", "review"], %{
          "$value" => %{"value" => value, "unit" => "px"}
        })

      File.write!(json_file, Jason.encode!(tokens))
      assert Mix.Tasks.Verify.UiTokens.check!(json_file, css_file) == :ok
    end
  end

  @tag :token_review
  test "review bounds source bytes JSON nesting token count and alias depth" do
    {json_file, css_file, temp} = fixture_paths!()
    on_exit(fn -> File.rm_rf!(temp) end)
    json = File.read!(Path.join(@root, @token_path))
    css = File.read!(Path.join(@root, @css_path))
    File.write!(css_file, css)
    File.write!(json_file, json <> String.duplicate(" ", 2_097_153))

    assert_raise Mix.Error, ~r/source exceeds/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    File.write!(json_file, json)
    File.write!(css_file, css <> String.duplicate(" ", 2_097_153))

    assert_raise Mix.Error, ~r/source exceeds/, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end

    File.write!(css_file, css)
    nested = Enum.reduce(1..70, nil, fn _, inner -> [inner] end)
    deep = put_in(Jason.decode!(json), ["$extensions", "org.scrypath", "nested"], nested)
    assert_rejected!(deep, json_file, css_file, ~r/JSON nesting exceeds/)

    many =
      Enum.reduce(1..4100, Jason.decode!(json), fn n, tokens ->
        put_in(tokens, ["color", "primitive", "review-#{n}"], %{
          "$value" => "{color.primitive.night}"
        })
      end)

    assert_rejected!(many, json_file, css_file, ~r/token count exceeds/)

    aliases =
      Enum.reduce(1..40, Jason.decode!(json), fn n, tokens ->
        target = if n == 40, do: "night", else: "review-#{n + 1}"

        put_in(tokens, ["color", "primitive", "review-#{n}"], %{
          "$value" => "{color.primitive.#{target}}"
        })
      end)

    assert_rejected!(aliases, json_file, css_file, ~r/alias depth exceeds/)
  end

  test "brandbook documentation separates the warm palette from the CSS-authoritative Ops mirror" do
    readme = File.read!(Path.join(@root, "brandbook/README.md"))
    brand_css = File.read!(Path.join(@root, "brandbook/tokens/tokens.css"))
    example = File.read!(Path.join(@root, "brandbook/tokens/daisyui-theme.example.js"))
    ops_css = File.read!(Path.join(@root, @css_path))

    assert readme =~ "warm `--sp-*`"
    assert readme =~ "separate from the live ScrypathOps interface theme"
    assert readme =~ "DTCG 2025.10"
    assert readme =~ "ops.light` / `ops.dark` project mirror"
    assert readme =~ "`mix verify.repository_contracts`"
    assert readme =~ "This source contract does not validate rendered UI output."
    refute readme =~ "the palette mirrors the\nlive `scrypath_ops` theme"
    assert brand_css =~ "Separate from the live ScrypathOps interface theme."
    assert brand_css =~ "--sp-primary:      #5B4AD1;"
    assert brand_css =~ "--sp-copper-500:   #C17A3E;"

    assert example =~ "The live Ops source of truth is scrypath_ops/assets/css/app.css."
    assert example =~ "separate from the warm --sp-*"
    assert example =~ "export default { light: scrypathLight, dark: scrypathDark }"

    assert js_theme_values!(example, "Light") == css_theme_values!(ops_css, "light")
    assert js_theme_values!(example, "Dark") == css_theme_values!(ops_css, "dark")
  end

  @tag :contrast_child
  test "canonical repository contracts pass clean copies and reject each independent token source mutation" do
    root = copy_repository!()

    {clean_output, clean_status} = canonical(root)
    assert clean_status == 0, "clean canonical command failed:\n#{clean_output}"

    css_path = Path.join(root, @css_path)
    original_css = File.read!(css_path)

    changed_css =
      String.replace(original_css, "--ops-bg: #111419;", "--ops-bg: #121519;", global: false)

    refute changed_css == original_css
    File.write!(css_path, changed_css)

    {css_output, css_status} = canonical(root)
    assert css_status != 0, "CSS-only canonical mutation unexpectedly passed"
    assert css_output =~ "UI token contract" or css_output =~ "UiTokensContractTest"

    File.write!(css_path, original_css)
    json_path = Path.join(root, @token_path)
    tokens = read_tokens!(root)

    changed_tokens =
      put_in(tokens, ["ops", "dark", "ops-bg", "$value", "hex"], "#121519")
      |> put_in(["ops", "dark", "ops-bg", "$value", "components"], [18 / 255, 21 / 255, 25 / 255])

    File.write!(json_path, Jason.encode!(changed_tokens, pretty: true))
    {json_output, json_status} = canonical(root)
    assert json_status != 0, "JSON-only canonical mutation unexpectedly passed"
    assert json_output =~ "UI token contract" or json_output =~ "UiTokensContractTest"
  end

  defp assert_brand_values!(tokens, css) do
    root = css |> css_block!(":root") |> css_variables!()
    dark = css |> css_block!(~s|[data-theme="dark"]|) |> css_variables!()

    for {name, token} <- tokens["color"]["primitive"] do
      assert brand_color!(tokens, "color.primitive.#{name}") ==
               String.downcase(root["--sp-#{name}"])

      assert token["$type"] == "color"
    end

    for {name, modes} <- tokens["color"]["semantic"], {mode, _token} <- modes do
      values = if mode == "dark", do: dark, else: root

      assert brand_color!(tokens, "color.semantic.#{name}.#{mode}") ==
               String.downcase(values["--sp-#{name}"])
    end

    for {name, token} <- tokens["color"]["status"] do
      assert brand_color!(tokens, "color.status.#{name}") == String.downcase(root["--sp-#{name}"])
      assert token["$type"] == "color"
    end

    for {name, token} <- Map.drop(tokens["font"]["family"], ["$type"]) do
      css_family =
        root["--sp-font-#{name}"]
        |> String.split(",")
        |> Enum.map(&(String.trim(&1) |> String.trim("\"")))

      assert token["$value"] == css_family
    end

    for {name, token} <- Map.drop(tokens["font"]["size"], ["$type"]) do
      assert_dimension!(token["$value"], root["--sp-text-#{name}"])
    end

    for {name, token} <- Map.drop(tokens["font"]["leading"], ["$type"]) do
      assert token["$value"] == css_number!(root["--sp-leading-#{name}"])
    end

    assert Map.new(Map.drop(tokens["font"]["weight"], ["$type"]), fn {name, token} ->
             {name, token["$value"]}
           end) ==
             %{"regular" => 400, "medium" => 500, "semibold" => 600, "bold" => 700}

    for {name, token} <- Map.drop(tokens["space"], ["$type"]) do
      assert_dimension!(token["$value"], root["--sp-#{name}"])
    end

    for {name, token} <- Map.drop(tokens["radius"], ["$type"]) do
      assert_dimension!(token["$value"], root["--sp-radius-#{name}"])
    end

    for {name, modes} <- Map.drop(tokens["shadow"], ["$type"]),
        {mode, css} <- @legacy_shadows[name] do
      token =
        if css == "none",
          do: get_in(modes, ["$extensions", "org.scrypath", "css_literals", mode]),
          else: modes[mode]

      assert_shadow!(token, css)
    end

    for {name, token} <- Map.drop(tokens["motion"]["duration"], ["$type"]) do
      assert_duration!(token["$value"], root["--sp-dur-#{name}"])
    end

    [_, curve] = Regex.run(~r/^cubic-bezier\(([^)]+)\)$/, root["--sp-ease"])

    assert tokens["motion"]["ease"]["$value"] ==
             Enum.map(String.split(curve, ","), &css_number!/1)
  end

  defp assert_shadow!("none", "none"), do: :ok

  defp assert_shadow!(%{"$value" => value, "$type" => "shadow"}, css) do
    actual = if is_list(value), do: value, else: [value]
    expected = css |> split_shadow_layers!() |> Enum.map(&shadow_layer!/1)
    assert actual == expected
  end

  defp assert_shadow!(token, css),
    do: flunk("unexpected shadow token #{inspect(token)} for #{css}")

  defp shadow_layer!(css) do
    words = Regex.scan(~r/rgba?\([^)]*\)|\S+/, css) |> List.flatten()
    inset? = List.last(words) == "inset"
    words = if inset?, do: Enum.drop(words, -1), else: words
    color_text = List.last(words)
    dimensions = Enum.drop(words, -1)
    [offset_x, offset_y, blur | tail] = dimensions
    spread = if tail == [], do: "0px", else: hd(tail)
    color = shadow_color!(color_text)

    layer = %{
      "color" => color,
      "offsetX" => shadow_dimension!(offset_x),
      "offsetY" => shadow_dimension!(offset_y),
      "blur" => shadow_dimension!(blur),
      "spread" => shadow_dimension!(spread)
    }

    if inset?, do: Map.put(layer, "inset", true), else: layer
  end

  defp shadow_color!(css) do
    [_, red, green, blue, alpha] =
      Regex.run(~r/^rgba?\((\d+),\s*(\d+),\s*(\d+),?\s*(\.\d+)?\)$/, css)

    components = Enum.map([red, green, blue], &(String.to_integer(&1) / 255))

    hex =
      "#" <>
        Enum.map_join(
          [red, green, blue],
          &(String.to_integer(&1) |> Integer.to_string(16) |> String.pad_leading(2, "0"))
        )

    %{
      "colorSpace" => "srgb",
      "components" => components,
      "hex" => String.upcase(hex),
      "alpha" => if(alpha in [nil, ""], do: 1, else: css_number!(alpha))
    }
  end

  defp shadow_dimension!("0"), do: %{"value" => 0, "unit" => "px"}
  defp shadow_dimension!(value), do: dimension_value!(value)

  defp split_shadow_layers!(css) do
    {layers, current, _depth} =
      css
      |> String.to_charlist()
      |> Enum.reduce({[], [], 0}, fn char, {layers, current, depth} ->
        cond do
          char == ?, and depth == 0 ->
            {[current |> Enum.reverse() |> to_string() |> String.trim() | layers], [], depth}

          char == ?( ->
            {layers, [char | current], depth + 1}

          char == ?) ->
            {layers, [char | current], depth - 1}

          true ->
            {layers, [char | current], depth}
        end
      end)

    [current |> Enum.reverse() |> to_string() |> String.trim() | layers] |> Enum.reverse()
  end

  defp dimension_value!(css) do
    [_, value, unit] = Regex.run(~r/^([+-]?(?:\d+(?:\.\d*)?|\.\d+))(px|rem)$/, css)
    %{"value" => css_number!(value), "unit" => unit}
  end

  defp assert_dimension!(value, css), do: assert(value == dimension_value!(css))

  defp assert_duration!(value, css) do
    [_, number, unit] = Regex.run(~r/^(\d+(?:\.\d+)?)(ms|s)$/, css)
    assert value == %{"value" => css_number!(number), "unit" => unit}
  end

  defp css_number!(value) do
    value = String.trim(value)
    value = if String.starts_with?(value, "."), do: "0" <> value, else: value

    value =
      if String.starts_with?(value, "-."), do: "-0" <> String.slice(value, 1..-1//1), else: value

    case Float.parse(value) do
      {number, ""} -> number
      _ -> flunk("invalid numeric CSS value #{inspect(value)}")
    end
  end

  defp brand_color!(tokens, path) do
    value = token_at!(tokens, path)["$value"]

    case value do
      <<"{", _::binary>> ->
        reference = String.slice(value, 1, byte_size(value) - 2)
        brand_color!(tokens, reference)

      %{"hex" => hex} ->
        String.downcase(hex)
    end
  end

  defp token_at!(tokens, path) do
    Enum.reduce(String.split(path, "."), tokens, &Map.fetch!(&2, &1))
  end

  defp css_block!(css, selector) do
    pattern = Regex.compile!(Regex.escape(selector) <> "\\s*\\{([^{}]*)\\}", "s")
    [_, body] = Regex.run(pattern, css)
    body
  end

  defp css_variables!(body) do
    Regex.scan(~r/(--sp-[a-z0-9-]+):\s*([^;]+);/, body, capture: :all_but_first)
    |> Map.new(fn [name, value] -> {name, String.trim(value)} end)
  end

  defp js_theme_values!(source, mode) do
    [_, block] = Regex.run(~r/export const scrypath#{mode} = \{([^{}]*)\};/s, source)

    Regex.scan(~r/^\s*("--[a-z0-9-]+"):\s*"([^"]*)",?\s*$/m, block, capture: :all_but_first)
    |> Map.new(fn [quoted_name, value] -> {String.trim(quoted_name, "\""), value} end)
  end

  defp css_theme_values!(source, mode) do
    blocks =
      Regex.scan(~r/@plugin\s+"[^"]*daisyui-theme"\s*\{([^{}]*)\}/s, source,
        capture: :all_but_first
      )

    [[body]] =
      Enum.filter(blocks, fn [block] ->
        Regex.run(~r/^\s*name:\s*"#{mode}"\s*;/m, block) != nil
      end)

    body
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\s*(--[a-z0-9-]+):\s*([^;{}]+);\s*$/, line, capture: :all_but_first) do
        [name, value] -> [{name, String.trim(value)}]
        nil -> []
      end
    end)
    |> Map.new()
  end

  defp replace_dark_theme!(css, old, new) do
    pattern = ~r/@plugin\s+"[^"]*daisyui-theme"\s*\{[^{}]*\}/s

    changed =
      Regex.replace(pattern, css, fn block ->
        if block =~ ~r/\bname:\s*"dark";/ do
          String.replace(block, old, new, global: false)
        else
          block
        end
      end)

    if changed == css, do: flunk("dark theme did not contain #{inspect(old)}")
    changed
  end

  defp fixture_paths! do
    temp =
      Path.join(
        System.tmp_dir!(),
        "scrypath-token-contract-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temp)
    on_exit(fn -> File.rm_rf!(temp) end)
    {Path.join(temp, "tokens.json"), Path.join(temp, "app.css"), temp}
  end

  defp assert_rejected!(tokens, json_file, css_file, message) do
    File.write!(json_file, Jason.encode!(tokens, pretty: true))

    assert_raise Mix.Error, message, fn ->
      Mix.Tasks.Verify.UiTokens.check!(json_file, css_file)
    end
  end

  defp read_tokens!(root), do: root |> Path.join(@token_path) |> File.read!() |> Jason.decode!()

  defp canonical(root) do
    System.cmd("mix", ["verify.repository_contracts"],
      cd: root,
      stderr_to_stdout: true,
      env: [{"ERL_FLAGS", "+S 4"}, {"GITHUB_EVENT_NAME", nil}]
    )
  end

  defp copy_repository! do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-token-contract-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(root) end)

    {output, status} =
      System.cmd("git", ["clone", "--quiet", "--shared", @root, root], stderr_to_stdout: true)

    assert status == 0, output

    {remote_output, remote_status} =
      System.cmd(
        "git",
        ["remote", "set-url", "origin", "https://github.com/szTheory/scrypath.git"],
        cd: root,
        stderr_to_stdout: true
      )

    assert remote_status == 0, remote_output

    for path <- [
          @token_path,
          @css_path,
          "dev/mix/tasks/verify/ui_tokens.ex",
          "dev/mix/tasks/verify.phase99.ex",
          "test/mix/tasks/ui_tokens_contract_test.exs"
        ] do
      File.cp!(Path.join(@root, path), Path.join(root, path))
    end

    for path <- ["deps", "_build"] do
      File.cp_r!(Path.join(@root, path), Path.join(root, path))
    end

    helper = Path.join(root, "test/test_helper.exs")

    File.write!(
      helper,
      String.replace(
        File.read!(helper),
        "ExUnit.configure(exclude: exclude)",
        "ExUnit.configure(exclude: [:contrast_child | exclude])"
      )
    )

    root
  end
end
