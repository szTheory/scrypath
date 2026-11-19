defmodule Scrypath.TestSupport.UiTokens do
  @moduledoc false
  # Resolved-token helper for the UI contract tests (Phase 186, TOK-03).
  #
  # The contract tests used to mutate the theme CSS by pinning an old color
  # literal (for example `--ops-bg: <old hex>;`). A recolor then broke them for
  # reasons unrelated to what they guard. These helpers read the LIVE value from
  # one named daisyUI theme block instead, and derive each mutation from it, so
  # the tests keep their meaning across a recolor.
  #
  # Blocks are selected by the `name: "<mode>"` declaration inside
  # `@plugin "../vendor/daisyui-theme" { ... }`, never by first match. The dark
  # block happens to come first in the file, so a bare global-false replace of a
  # property would hit dark only by accident.

  @theme_block ~r/@plugin\s+"[^"]*daisyui-theme"\s*\{[^{}]*\}/s

  @doc "The text of the single theme block whose `name:` is `mode` (light or dark)."
  @spec theme_block!(String.t(), String.t()) :: String.t()
  def theme_block!(css, mode) when is_binary(css) and is_binary(mode) do
    blocks =
      @theme_block
      |> Regex.scan(css)
      |> List.flatten()
      |> Enum.filter(&Regex.match?(~r/^\s*name:\s*"#{Regex.escape(mode)}"\s*;/m, &1))

    case blocks do
      [block] -> block
      [] -> raise ArgumentError, "no #{mode} daisyUI theme block in the CSS"
      _many -> raise ArgumentError, "more than one #{mode} daisyUI theme block in the CSS"
    end
  end

  @doc """
  The live value of `property` (for example `"--ops-bg"`) from the named theme block only.
  Raises when the property is missing or declared more than once in that block.
  """
  @spec theme_value!(String.t(), String.t(), String.t()) :: String.t()
  def theme_value!(css, mode, property) do
    pattern = ~r/^[ \t]*#{Regex.escape(property)}:[ \t]*([^;{}\n]+);[ \t]*$/m

    case Regex.scan(pattern, theme_block!(css, mode), capture: :all_but_first) do
      [[value]] ->
        String.trim(value)

      [] ->
        raise ArgumentError, "#{property} is not declared in the #{mode} theme block"

      _many ->
        raise ArgumentError, "#{property} is declared more than once in the #{mode} theme block"
    end
  end

  @doc "Replace the value of `property` in the named theme block only; other blocks are untouched."
  @spec replace_theme_value!(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def replace_theme_value!(css, mode, property, new_value) do
    _live = theme_value!(css, mode, property)
    block = theme_block!(css, mode)
    pattern = ~r/^([ \t]*#{Regex.escape(property)}:[ \t]*)[^;{}\n]+;/m

    changed =
      Regex.replace(pattern, block, fn _whole, prefix -> prefix <> new_value <> ";" end,
        global: false
      )

    String.replace(css, block, changed, global: false)
  end

  @doc "Declare `property` twice in a row inside the named theme block."
  @spec duplicate_theme_declaration!(String.t(), String.t(), String.t()) :: String.t()
  def duplicate_theme_declaration!(css, mode, property) do
    _live = theme_value!(css, mode, property)
    block = theme_block!(css, mode)
    pattern = ~r/^([ \t]*#{Regex.escape(property)}:[ \t]*[^;{}\n]+;)$/m

    changed =
      Regex.replace(
        pattern,
        block,
        fn _whole, declaration -> declaration <> "\n" <> declaration end,
        global: false
      )

    String.replace(css, block, changed, global: false)
  end

  @doc "A different, valid, lowercase `#rrggbb` derived from `hex` (red channel plus one, wrapping at the top)."
  @spec bump_hex(String.t()) :: String.t()
  def bump_hex(hex) do
    {red, green, blue} = hex_to_rgb!(hex)
    red = if red == 255, do: 254, else: red + 1

    "#" <>
      Enum.map_join([red, green, blue], fn channel ->
        channel |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(2, "0")
      end)
  end

  @doc "The three sRGB channels as floats in 0..1."
  @spec rgb_components(String.t()) :: [float()]
  def rgb_components(hex) do
    {red, green, blue} = hex_to_rgb!(hex)
    [red / 255, green / 255, blue / 255]
  end

  @doc "The same color written as `rgb(r g b)`."
  @spec rgb_function(String.t()) :: String.t()
  def rgb_function(hex) do
    {red, green, blue} = hex_to_rgb!(hex)
    "rgb(#{red} #{green} #{blue})"
  end

  @doc "WCAG 2.x relative luminance of a `#rrggbb` color."
  @spec relative_luminance(String.t()) :: float()
  def relative_luminance(hex) do
    [red, green, blue] = hex |> rgb_components() |> Enum.map(&linear/1)
    0.2126 * red + 0.7152 * green + 0.0722 * blue
  end

  defp linear(channel) when channel <= 0.03928, do: channel / 12.92
  defp linear(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)

  defp hex_to_rgb!(hex) do
    case Regex.run(~r/\A#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})\z/, to_string(hex)) do
      [_whole, red, green, blue] ->
        {String.to_integer(red, 16), String.to_integer(green, 16), String.to_integer(blue, 16)}

      nil ->
        raise ArgumentError, "expected a #rrggbb color, got #{inspect(hex)}"
    end
  end
end
