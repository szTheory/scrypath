defmodule ScrypathOpsWeb.MotionContractTest do
  @moduledoc """
  Static CSS contract for ScrypathOps motion, read straight from `assets/css/app.css`.

  Phase 133 shipped a path-motion vocabulary (`.ops-path-*`, a code-block shimmer, a violet
  and a copper glow, and a glowing route mark) and this file used to lock how those rules
  animated. Phase 187 retired the whole vocabulary with the old identity: the Selection
  Signature (a 2px Plum line) replaced every glow, and nothing in ops draws a decorative
  path, glint or aura any more.

  So the contract now runs the other way. It asserts that none of those families, and
  neither glow token, can come back into the stylesheet. A planted stylesheet proves each
  matcher still rejects what it should, so the absence check cannot pass by matching nothing.

  The duration-token rule (every `transition` and `animation` names a `--duration-ops-*`
  token and no raw millisecond literal) arrives with the motion proof in Plan 09 of the
  same phase, where it is checked against the whole stylesheet instead of one vocabulary.

  This is a pure file-read plus regex assertion: no database, no browser, `async: true`.
  It runs inside `mix verify.ops_ui` because it is an ExUnit test under `scrypath_ops/test`.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

  # Each retired family with the pattern that finds it. The patterns match selectors and
  # token names, so a rule, a custom property or a Tailwind utility spelled with the name
  # all count.
  @retired_families [
    {"path-motion", ~r/ops-path/},
    {"copper", ~r/ops-copper/},
    {"glow utility", ~r/\.ops-glow\b/},
    {"code-block shimmer", ~r/ops-code-block--shimmer/},
    {"route mark", ~r/ops-route-mark/},
    {"glow tokens", ~r/shadow-ops-glow/}
  ]

  defp css, do: File.read!(@app_css)

  # Names of the retired families found in `source`, in declaration order of the list above.
  defp retired_families_in(source) do
    for {name, pattern} <- @retired_families, Regex.match?(pattern, source), do: name
  end

  test "no path-motion, shimmer, copper, glow or route-mark rule remains" do
    assert retired_families_in(css()) == [],
           "Phase 187 retired these families; they must not return to app.css: " <>
             Enum.join(retired_families_in(css()), ", ")
  end

  test "the matchers reject a planted stylesheet for every retired family" do
    planted = """
    .ops-path-trace::after { transform: scaleX(0); }
    .ops-copper-badge { color: red; }
    .ops-glow { box-shadow: var(--shadow-ops-glow); }
    .ops-code-block--shimmer:hover::after { opacity: 1; }
    .ops-route-mark { background: linear-gradient(135deg, red, blue); }
    """

    assert retired_families_in(planted) ==
             Enum.map(@retired_families, fn {name, _pattern} -> name end)

    for {name, pattern} <- @retired_families do
      refute Regex.match?(pattern, ".ops-panel { color: var(--color-base-content); }"),
             "the #{name} matcher must not fire on an ordinary rule"
    end
  end
end
