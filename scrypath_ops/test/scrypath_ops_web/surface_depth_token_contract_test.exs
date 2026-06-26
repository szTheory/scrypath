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

  # Plan 02 appends the dark hover-border boost tripwire after the selector exists.
end
