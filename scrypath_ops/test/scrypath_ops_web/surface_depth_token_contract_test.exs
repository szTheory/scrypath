defmodule ScrypathOpsWeb.SurfaceDepthTokenContractTest do
  @moduledoc """
  Locks the SCREEN-DARK-01 surface-depth value contract as static CSS assertions.

  This is a pure file-read + regex contract over `assets/css/app.css`, modeled on
  `MotionContractTest`. It pins values that must stay stable while later tasks wire
  the browser depth assertions.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

  defp css, do: File.read!(@app_css)

  test "--ops-surface-2 stays #1b2230 for dark raised surfaces" do
    assert Regex.match?(~r/--ops-surface-2:\s*#1b2230;/, css()),
           "Dark --ops-surface-2 drifted from the locked #1b2230 elevation token."
  end

  test ".ops-data-card dark fill references --ops-surface-2" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
             css()
           ),
           ".ops-data-card explicit-dark fill must reference var(--ops-surface-2), not a hardcoded color."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
             css()
           ),
           ".ops-data-card system-dark fill must mirror var(--ops-surface-2)."
  end

  test ".ops-result-row dark fill references --ops-surface-2" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-result-row\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
             css()
           ),
           ".ops-result-row explicit-dark fill must reference var(--ops-surface-2), not a hardcoded color."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-result-row\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
             css()
           ),
           ".ops-result-row system-dark fill must mirror var(--ops-surface-2)."
  end

  test "dark hover-border boost resolves to primary 55% on the paired row/item selector" do
    assert Regex.match?(
             ~r/\[data-theme="dark"\]\s+\.ops-result-row:hover,\s*\[data-theme="dark"\]\s+\.ops-object-item:hover\s*\{[^{}]*border-color:\s*color-mix\(in oklch,\s*var\(--color-primary\)\s*55%,\s*transparent\)/,
             css()
           ),
           "Dark hover-border boost must keep the paired .ops-result-row/.ops-object-item selector at primary 55%."

    assert Regex.match?(
             ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-result-row:hover,\s*html:not\(\[data-theme="light"\]\)\s+\.ops-object-item:hover\s*\{[^{}]*border-color:\s*color-mix\(in oklch,\s*var\(--color-primary\)\s*55%,\s*transparent\)/,
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
