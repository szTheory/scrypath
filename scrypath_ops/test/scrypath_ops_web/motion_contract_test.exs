defmodule ScrypathOpsWeb.MotionContractTest do
  @moduledoc """
  Locks the DARKMOTION-01 motion discipline (Phase 133, decision D-05) as a
  static CSS contract over the `.ops-path-*` / `.ops-code-block--shimmer`
  path-motion vocabulary in `assets/css/app.css`.

  This is a pure file-read + regex assertion — no DB, no browser, `async: true`.
  It runs automatically inside `mix verify.opsui` because it is an ExUnit test
  under `scrypath_ops/test`, so future edits to the path-motion rules cannot
  silently regress the locked rules:

    1. Transform/opacity-only — a path-motion rule must not animate (or end-state)
       a layout/visual property outside {transform, opacity, box-shadow}. A
       `filter:`/`width:`/`background-position:`/`stroke-dashoffset:` etc. inside
       one of these blocks fails the build.
    2. Tokenized duration <300ms — every `transition:`/`animation:` in a
       path-motion block must reference a `--duration-ops-*` token (all ≤240ms by
       definition) and contain NO raw `\\d+ms` / `\\d+s` literal.
    3. Dual-dark-path — a dark-only path glow end state authored under
       `[data-theme="dark"]` must be mirrored under the system-dark
       `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` path.

  Mirrors the shape of `design_tokens_contract_test.exs` (path-expanded `@app_css`,
  `File.read!`, `Regex.scan`).
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

  # Animatable properties allowed in a path-motion rule. Everything else that can
  # animate layout/paint is forbidden (transform/opacity/box-shadow only — A3
  # patch-safe). `box-shadow` is allowed because the quiet glow rides it.
  @allowed_animated_props ~w(transform opacity box-shadow)

  # Forbidden animatable layout/paint properties (the locked DARKMOTION-01 ban
  # list). If any of these appears as a *declaration* inside a path-motion block
  # the motion is no longer transform/opacity-only. These needles live only in
  # this test, never in app.css.
  #
  # NOTE: `inset` (the positioning shorthand) is deliberately NOT banned — the
  # line-draw `::after` is authored with `inset: auto 0 0 0` + `border-bottom` +
  # `border-image` *precisely* to avoid the banned `width`/`height`/`top`/`left`
  # longhand while staying static (not animated). Banning `inset` would flag that
  # intentional static positioning. The runtime motion is scaleX + opacity only.
  @forbidden_props ~w(
    width height top left margin
    filter background-position stroke-dashoffset stroke-dasharray
  )

  defp css, do: File.read!(@app_css)

  # Extract every CSS rule (selector + declaration block) whose selector text
  # mentions a path-motion class. Returns [{selector, body}] where body is the
  # text between `{` and the matching `}` (these rules have no nested braces).
  defp path_motion_blocks do
    Regex.scan(~r/([^{}]*?(?:ops-path|ops-code-block--shimmer)[^{}]*?)\{([^{}]*)\}/, css())
    |> Enum.map(fn [_, selector, body] -> {String.trim(selector), body} end)
  end

  test "every path-motion block animates only transform/opacity/box-shadow" do
    _ = @allowed_animated_props

    violations =
      for {selector, body} <- path_motion_blocks(),
          prop <- @forbidden_props,
          # A real *declaration* of the forbidden prop: `prop:` at a token
          # boundary. `border-bottom`/`border-image` etc. do not match `width:`
          # and are static (not in a transition), so they are not flagged.
          Regex.match?(~r/(?<![a-z-])#{Regex.escape(prop)}\s*:/, body) do
        {selector, prop}
      end

    assert violations == [],
           "Path-motion rules may only animate transform/opacity/box-shadow.\n" <>
             "Found forbidden animatable property declarations in .ops-path-* blocks:\n" <>
             Enum.map_join(violations, "\n", fn {sel, prop} -> "  #{prop}:  in  #{sel}" end)
  end

  test "every path-motion transition/animation uses a --duration-ops-* token, no raw literal" do
    blocks = path_motion_blocks()

    # Collect every transition:/animation: declaration value across path-motion
    # blocks. Each must reference a --duration-ops-* token and carry no raw
    # ms/s literal (a literal would mean an untokenized, possibly ≥300ms motion).
    timing_decls =
      for {selector, body} <- blocks,
          [_, kind, value] <-
            Regex.scan(~r/\b(transition|animation)\s*:\s*([^;]+);/, body) do
        {selector, kind, String.trim(value)}
      end

    missing_token =
      Enum.reject(timing_decls, fn {_sel, _kind, value} ->
        Regex.match?(~r/var\(--duration-ops-/, value)
      end)

    raw_literal =
      Enum.filter(timing_decls, fn {_sel, _kind, value} ->
        # A bare number followed by ms/s (e.g. `200ms`, `0.2s`) that is NOT part
        # of a token name. Token references are `var(--duration-ops-fast)`, never
        # a raw `200ms`, so any `\d+(ms|s)` here is an untokenized literal.
        Regex.match?(~r/(?<![\w-])\d+(?:\.\d+)?(?:ms|s)\b/, value)
      end)

    assert missing_token == [],
           "Every path-motion transition/animation must reference a --duration-ops-* token.\n" <>
             Enum.map_join(missing_token, "\n", fn {sel, kind, v} ->
               "  #{kind}: #{v}  in  #{sel}"
             end)

    assert raw_literal == [],
           "Path-motion durations must be --duration-ops-* tokens (all ≤240ms), not raw literals.\n" <>
             Enum.map_join(raw_literal, "\n", fn {sel, kind, v} ->
               "  #{kind}: #{v}  in  #{sel}"
             end)
  end

  test "every dark-only path glow end state is mirrored in both dark paths" do
    source = css()

    # The dark-only path glow end states this phase ships ride the persistent
    # `.ops-object-item-active` server-state class (Precedent D): a violet
    # `var(--shadow-ops-glow)` composed onto the existing inset ring. It MUST be
    # authored in BOTH the explicit-dark and the system-dark mirror.
    #
    # Collect the selectors that set a glow end state under each dark context and
    # assert symmetry. Implemented by scanning for the active-path glow rule in
    # each dark branch.

    # Explicit theme path: `[data-theme="dark"] <selector> { ... var(--shadow-ops-glow) ... }`
    explicit_dark =
      Regex.scan(
        ~r/\[data-theme="dark"\]\s+([^{}\n]*?ops-[a-z0-9-]+)[^{}]*\{[^{}]*var\(--shadow-ops-glow/,
        source
      )
      |> Enum.map(fn [_, sel] -> String.trim(sel) end)
      |> MapSet.new()

    # System path: inside `@media (prefers-color-scheme: dark)`, a
    # `html:not([data-theme="light"]) <selector> { ... var(--shadow-ops-glow) ... }`
    system_dark =
      Regex.scan(
        ~r/html:not\(\[data-theme="light"\]\)\s+([^{}\n]*?ops-[a-z0-9-]+)[^{}]*\{[^{}]*var\(--shadow-ops-glow/,
        source
      )
      |> Enum.map(fn [_, sel] -> String.trim(sel) end)
      |> MapSet.new()

    # Restrict the symmetry assertion to path/active anchors (the surface this
    # phase governs). Other dark glow compositions (e.g. the recommended intent
    # card) predate Phase 133 and have their own dual-path coverage; we only
    # assert that whatever path-active glow exists in one dark branch exists in
    # the other.
    path_explicit =
      explicit_dark |> Enum.filter(&String.contains?(&1, "object-item-active")) |> MapSet.new()

    path_system =
      system_dark |> Enum.filter(&String.contains?(&1, "object-item-active")) |> MapSet.new()

    only_explicit = MapSet.difference(path_explicit, path_system)
    only_system = MapSet.difference(path_system, path_explicit)

    assert MapSet.size(only_explicit) == 0,
           "Dark-only path glow authored under [data-theme=\"dark\"] but missing the system-dark mirror:\n" <>
             Enum.map_join(only_explicit, "\n", &"  #{&1}")

    assert MapSet.size(only_system) == 0,
           "Dark-only path glow authored under @media(prefers-color-scheme:dark) but missing the [data-theme=\"dark\"] path:\n" <>
             Enum.map_join(only_system, "\n", &"  #{&1}")

    # Functional integrity: this phase DID ship an active-path dark glow, so the
    # symmetry set must be non-empty (a silent regression that removed both would
    # otherwise pass vacuously). If a future phase removes the active-path glow
    # entirely this guard should be revisited.
    assert MapSet.size(path_explicit) >= 1,
           "Expected at least one active-path dark glow end state (.ops-object-item-active) " <>
             "in the [data-theme=\"dark\"] path; found none — did the dual-dark-path glow regress?"
  end
end
