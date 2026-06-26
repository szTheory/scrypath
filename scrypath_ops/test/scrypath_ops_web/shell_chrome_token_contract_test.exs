defmodule ScrypathOpsWeb.ShellChromeTokenContractTest do
  @moduledoc """
  Locks SHELL-DARK-01 shell chrome CSS invariants as static source assertions.

  This is a pure file-read contract over `assets/css/app.css`, modeled on the
  existing surface-depth and motion token contracts.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()
  @design_tokens Path.join(__DIR__, "../../assets/css/DESIGN-TOKENS.md") |> Path.expand()

  defp css, do: File.read!(@app_css)
  defp design_tokens, do: File.read!(@design_tokens)

  test ".ops-shell wash keeps exactly one radial layer plus one linear floor per rule" do
    blocks =
      Regex.scan(
        ~r/(?:^|\n)\s*(?:\[data-theme="dark"\]\s+|html:not\(\[data-theme="light"\]\)\s+)?\.ops-shell\s*\{([^{}]*)\}/,
        css()
      )
      |> Enum.map(fn [_, body] -> body end)

    assert blocks != [], "Expected at least one .ops-shell background rule."

    for body <- blocks do
      assert Regex.scan(~r/radial-gradient/, body) |> length() == 1,
             ".ops-shell must keep exactly one quiet radial wash per rule."

      assert Regex.scan(~r/linear-gradient/, body) |> length() == 1,
             ".ops-shell must keep exactly one linear page-floor gradient per rule."

      assert body =~ "circle at top left",
             ".ops-shell radial wash must stay anchored at the top-left brand corner."
    end
  end

  test ".ops-header dark seated separation is mirrored in explicit and system dark" do
    source = css()

    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-header\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-panel-dark\)/,
             source
           ),
           ".ops-header explicit-dark separation must use --shadow-ops-panel-dark."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-header\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-panel-dark\)/,
             source
           ),
           ".ops-header system-dark separation must mirror --shadow-ops-panel-dark."
  end

  test "theme toggle shell selectors and dark mirrors are present" do
    source = css()

    for selector <- [".ops-theme-toggle", ".ops-theme-toggle__pill", ".ops-theme-toggle__button"] do
      assert source =~ selector, "Expected #{selector} to have a CSS contract."
    end

    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-theme-toggle\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-panel-dark\)/,
             source
           ),
           ".ops-theme-toggle explicit-dark treatment must use --shadow-ops-panel-dark."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-theme-toggle\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-panel-dark\)/,
             source
           ),
           ".ops-theme-toggle system-dark treatment must mirror --shadow-ops-panel-dark."
  end

  test "active nav keeps the AA primary-strong selected fill and mirrored dark glow" do
    source = css()

    assert Regex.match?(
             ~r/\.ops-nav-item-active\s*\{[^{}]*background:\s*var\(--color-primary-strong\)/,
             source
           ),
           ".ops-nav-item-active must use the AA-safe --color-primary-strong fill."

    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-nav-item-active\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-glow\)/,
             source
           ),
           ".ops-nav-item-active explicit-dark glow must be present."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-nav-item-active\s*\{[^{}]*box-shadow:[^{}]*var\(--shadow-ops-glow\)/,
             source
           ),
           ".ops-nav-item-active system-dark glow must mirror explicit dark."
  end

  test "live brand mark selector is the shell proof target, not only the stale route mark" do
    source = css()

    assert source =~ ".ops-brand-mark",
           "The live inline SVG brand mark needs a CSS/proof selector."

    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-brand-mark\s*\{/,
             source
           ),
           ".ops-brand-mark explicit-dark treatment must exist."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-brand-mark\s*\{/,
             source
           ),
           ".ops-brand-mark system-dark treatment must mirror explicit dark."
  end

  test "palette and flash overlay shadows are mirrored in both dark paths" do
    source = css()

    for selector <- [".ops-cmdk__panel", ".ops-flash"] do
      assert Regex.match?(
               Regex.compile!(
                 ~s/\\[data-theme="dark"\\]\\s+#{Regex.escape(selector)}\\s*\\{[^{}]*box-shadow:\\s*var\\(--shadow-ops-overlay\\),\\s*var\\(--shadow-ops-panel-dark\\)/
               ),
               source
             ),
             "#{selector} explicit-dark overlay shadow must compose overlay first, panel-dark second."

      assert Regex.match?(
               Regex.compile!(
                 ~s/html:not\\(\\[data-theme="light"\\]\\)\\s+#{Regex.escape(selector)}\\s*\\{[^{}]*box-shadow:\\s*var\\(--shadow-ops-overlay\\),\\s*var\\(--shadow-ops-panel-dark\\)/
               ),
               source
             ),
             "#{selector} system-dark overlay shadow must mirror explicit dark."
    end
  end

  test "design tokens document palette and flash overlay composition" do
    source = design_tokens()

    assert source =~ ".ops-cmdk__panel"
    assert source =~ ".ops-flash"
    assert source =~ "--shadow-ops-overlay"
    assert source =~ "--shadow-ops-panel-dark"
    assert source =~ "overlay first"
  end
end
