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

    for {name, modes} <- Map.drop(tokens["shadow"], ["$type"]), {mode, token} <- modes do
      assert_shadow!(token, @legacy_shadows[name][mode])
    end

    for {name, token} <- Map.drop(tokens["motion"]["duration"], ["$type"]) do
      assert_duration!(token["$value"], root["--sp-dur-#{name}"])
    end

    [_, curve] = Regex.run(~r/^cubic-bezier\(([^)]+)\)$/, root["--sp-ease"])

    assert tokens["motion"]["ease"]["$value"] ==
             Enum.map(String.split(curve, ","), &css_number!/1)
  end

  defp assert_shadow!(%{"$value" => "none", "$type" => "string"}, "none"), do: :ok

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

    %{
      "color" => color,
      "offsetX" => shadow_dimension!(offset_x),
      "offsetY" => shadow_dimension!(offset_y),
      "blur" => shadow_dimension!(blur),
      "spread" => shadow_dimension!(spread),
      "type" => if(inset?, do: "innerShadow", else: "dropShadow")
    }
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
