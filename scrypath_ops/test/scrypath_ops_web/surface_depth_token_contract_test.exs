defmodule ScrypathOpsWeb.SurfaceDepthTokenContractTest do
  @moduledoc """
  Locks the SCREEN-DARK-01 surface-depth value contract as static CSS assertions.

  Phase 187 deleted `--ops-surface-2`: the dark order is now `--ops-sunken` below `--ops-bg`
  below `--ops-surface-1`, and the card and row fills point at the Panel token.

  This is a pure file-read + regex contract over `assets/css/app.css`, modeled on
  `MotionContractTest`. It pins values that must stay stable while later tasks wire
  the browser depth assertions.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

  defp css, do: File.read!(@app_css)

  # A few lines copied from the root test helper (this is a separate Mix project,
  # so copying is cheaper than a dependency): the live value of a property from the
  # dark daisyUI theme block, and WCAG 2.x relative luminance of a #rrggbb color.
  defp dark_theme_value(property) do
    [block] =
      for [block] <- Regex.scan(~r/@plugin\s+"[^"]*daisyui-theme"\s*\{[^{}]*\}/s, css()),
          block =~ ~r/^\s*name:\s*"dark"\s*;/m,
          do: block

    [_, value] = Regex.run(~r/^\s*#{Regex.escape(property)}:\s*(#[0-9a-fA-F]{6});/m, block)
    value
  end

  defp luminance("#" <> hex) do
    {value, ""} = Integer.parse(hex, 16)

    [red, green, blue] =
      for shift <- [16, 8, 0] do
        channel = Bitwise.band(Bitwise.bsr(value, shift), 255) / 255

        if channel <= 0.03928,
          do: channel / 12.92,
          else: :math.pow((channel + 0.055) / 1.055, 2.4)
      end

    0.2126 * red + 0.7152 * green + 0.0722 * blue
  end

  test "dark surfaces rise in luminance from --ops-sunken through --ops-bg to --ops-surface-1" do
    # The relationship is the contract, not a color: a recessed dark surface sits below the
    # page, and the Panel sits above it. Values are read live from the dark theme block.
    [sunken, page, surface_1] =
      for property <- ["--ops-sunken", "--ops-bg", "--ops-surface-1"] do
        property |> dark_theme_value() |> luminance()
      end

    assert sunken < page,
           "Dark --ops-sunken must be darker than the --ops-bg page (#{sunken} vs #{page})."

    assert page < surface_1,
           "Dark --ops-surface-1 must be lighter than the --ops-bg page (#{page} vs #{surface_1})."
  end

  test "the retired --ops-surface-2 role is neither declared nor consumed" do
    # Raised surfaces are --color-base-100 (Panel); hover and recessed ones are --ops-sunken.
    refute css() =~ "ops-surface-2",
           "--ops-surface-2 was deleted in Phase 187; use --color-base-100 (raised) or --ops-sunken (recessed or hover)."
  end

  test ".ops-data-card dark fill references the Panel token" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--color-base-100\)/,
             css()
           ),
           ".ops-data-card explicit-dark fill must reference var(--color-base-100), not a hardcoded color."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--color-base-100\)/,
             css()
           ),
           ".ops-data-card system-dark fill must mirror var(--color-base-100)."
  end

  test "non-search result rows keep an opaque dark Panel fill" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-result-row:not\(\.ops-search-hit\)\s*\{[^{}]*background:\s*var\(--color-base-100\)/,
             css()
           ),
           ".ops-result-row explicit-dark fill must reference var(--color-base-100), not a hardcoded color."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-result-row:not\(\.ops-search-hit\)\s*\{[^{}]*background:\s*var\(--color-base-100\)/,
             css()
           ),
           ".ops-result-row system-dark fill must mirror var(--color-base-100)."
  end

  test "dark hover-border boost resolves to primary 55% on the paired row/item selector" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-result-row:not\(\.ops-search-hit\):hover,\s*\[data-theme="dark"\]\s+\.ops-object-item:hover\s*\{[^{}]*border-color:\s*color-mix\(in oklch,\s*var\(--color-primary\)\s*55%,\s*transparent\)/,
             css()
           ),
           "Dark hover-border boost must keep the paired .ops-result-row/.ops-object-item selector at primary 55%."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-result-row:not\(\.ops-search-hit\):hover,\s*html:not\(\[data-theme="light"\]\)\s+\.ops-object-item:hover\s*\{[^{}]*border-color:\s*color-mix\(in oklch,\s*var\(--color-primary\)\s*55%,\s*transparent\)/,
             css()
           ),
           "System-dark hover-border boost must mirror the paired selector at primary 55%."
  end

  test "base shared hover rule stays primary 32% with the neutral mid shadow" do
    assert Regex.match?(
             ~r/\.ops-result-row:hover,\s*\.ops-object-item:hover\s*\{[^{}]*border-color:\s*color-mix\(in oklch,\s*var\(--color-primary\)\s*32%,\s*transparent\);[^{}]*box-shadow:\s*var\(--shadow-ops-mid\)/,
             css()
           ),
           "Base shared hover rule must remain paired at primary 32% plus var(--shadow-ops-mid) for light and fallback."
  end
end
