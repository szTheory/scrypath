defmodule ScrypathOpsWeb.MotionContractTest do
  @moduledoc """
  Static CSS contract for ScrypathOps motion, read straight from `assets/css/app.css` and the
  built stylesheet.

  Two rules live here, both pure file reads plus regex, no database, no browser, `async: true`.
  They run inside `mix verify.ops_ui` because they are ExUnit tests under `scrypath_ops/test`.

  1. The old identity's motion cannot come back. Phase 133 shipped a path-motion vocabulary
     (`.ops-path-*`, a code-block shimmer, a violet and a copper glow, and a glowing route mark).
     Phase 187 retired all of it: the Selection Signature (a 2px Plum line) replaced every glow.
     A planted stylesheet proves each matcher still rejects what it should, so the absence check
     cannot pass by matching nothing.

  2. Every duration is a brand token. The brand book owns four durations (`instant` 80 ms,
     `quick` 160 ms, `base` 240 ms, `advance` 600 ms) and six easings. Every `transition` and
     `animation` declaration in the source stylesheet names a `--duration-ops-*` token or is zero;
     a raw millisecond or second literal fails, the 600 ms `advance` token is consumed only by a
     named allowlist (empty in v1.46), and the daisyUI component durations ops renders are
     overridden to tokens. A planted stylesheet proves each matcher fires. The reduced-motion
     rule is the one literal that stays (`0.01ms`, one iteration). The computed proof in a real
     browser is `e2e/admin_path_motion.spec.ts` (P-12).
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()
  @built_css Path.join(__DIR__, "../../priv/static/assets/css/app.css") |> Path.expand()

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

  # The brand durations, and the old names that stay as `var()` aliases for one milestone
  # (alias => the brand token it resolves to).
  @brand_durations %{
    "instant" => "80ms",
    "quick" => "160ms",
    "base" => "240ms",
    "advance" => "600ms"
  }
  @duration_aliases %{
    "fast" => "instant",
    "status" => "quick",
    "standard" => "base",
    "slow" => "base"
  }

  # Selectors that may consume `--duration-ops-advance`: the progress line, which v1.46 does not
  # ship. Empty on purpose; adding a name here is a product decision, not a test edit.
  @advance_allowlist []

  # The six brand easings (brand book, "Motion: timing and easing") and the old names that alias
  # them: `standard` is `resolve`, `out` is `resolve`, `in-out` is `sweep`.
  @brand_easings %{
    "strike" => "cubic-bezier(0.1, 0.9, 0.2, 1)",
    "resolve" => "cubic-bezier(0.2, 0.8, 0.2, 1)",
    "settle" => "cubic-bezier(0.3, 0, 0.2, 1)",
    "sweep" => "cubic-bezier(0.45, 0, 0.25, 1)",
    "exit" => "cubic-bezier(0.4, 0, 1, 1)",
    "advance" => "cubic-bezier(0.45, 0, 0.2, 1)"
  }
  @easing_aliases %{"standard" => "resolve", "out" => "resolve", "in-out" => "sweep"}

  # The daisyUI components ops renders, each with the token its own transitions run on. daisyUI
  # sets these durations as literals (`.btn` 0.2s, `.modal` 0.3s, `.modal-box` 0.3s and 0.2s,
  # `.checkbox` 0.2s and its mark 0.3s and 0.1s, `.card` outline 0.2s, `.radio` 0.2s), so ops
  # overrides each in the same layer, after the vendor rule.
  @daisy_overrides [
    {".btn", "transition-duration", "quick"},
    {".checkbox", "transition-duration", "quick"},
    {".checkbox::before", "transition-duration", "quick"},
    {".radio", "transition-duration", "quick"},
    {".radio:checked", "animation-duration", "quick"},
    {".card", "transition-duration", "quick"},
    {".modal", "transition-duration", "base"},
    {".modal-box", "transition-duration", "base"}
  ]

  defp css, do: File.read!(@app_css)

  defp strip_comments(source), do: Regex.replace(~r{/\*.*?\*/}s, source, "")

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

  # ── Duration tokens ────────────────────────────────────────────────────────────────────

  # Every duration problem in `source`, as `{property, value, reason}`. A declaration of
  # `transition`, `transition-duration`, `animation` or `animation-duration` passes when each time
  # in it is a `--duration-ops-*` reference to a known token (the 600 ms `advance` token only for
  # a selector on the allowlist) or a zero. The reduced-motion rule's `0.01ms !important` is the
  # one literal that stays.
  defp duration_offenders(source) do
    ~r/([^{};]+)\{([^{}]*)\}/s
    |> Regex.scan(strip_comments(source))
    |> Enum.flat_map(fn [_all, selector, body] ->
      ~r/(?<![\w-])(transition-duration|transition|animation-duration|animation)\s*:\s*([^;]+)/
      |> Regex.scan(body)
      |> Enum.flat_map(fn [_decl, property, value] ->
        offenders_in_value(String.trim(selector), property, String.trim(value))
      end)
    end)
  end

  defp offenders_in_value(selector, property, value) do
    literals =
      for [literal, _n, _unit] <- Regex.scan(~r/(?<![\w.-])(\d*\.?\d+)(ms|s)\b/, value),
          not zero_time?(literal),
          value != "0.01ms !important",
          do: {property, value, "raw duration literal #{literal}"}

    tokens =
      for [_ref, name] <- Regex.scan(~r/var\(\s*--duration-ops-([a-z-]+)\s*\)/, value),
          reason = token_problem(name, selector),
          do: {property, value, reason}

    literals ++ tokens
  end

  defp zero_time?(literal), do: literal in ["0s", "0ms", "0.0s", "0.0ms"]

  defp token_problem("advance", selector) do
    if Enum.any?(@advance_allowlist, &String.contains?(selector, &1)),
      do: nil,
      else: "the advance token is for the progress line only (selector #{selector})"
  end

  defp token_problem(name, _selector) do
    known = Map.keys(@brand_durations) ++ Map.keys(@duration_aliases)
    if name in known, do: nil, else: "unknown duration token --duration-ops-#{name}"
  end

  test "every transition and animation duration in the source stylesheet is a duration token or 0" do
    assert duration_offenders(css()) == []
  end

  test "the duration matcher rejects a planted stylesheet and accepts the real forms" do
    planted = """
    .a { transition: opacity 150ms ease; }
    .b { animation: ops-fade-in 1s linear; }
    .c { transition-duration: .2s; }
    .d { transition: color var(--duration-ops-advance) ease; }
    .e { animation: x var(--duration-ops-sting) ease; }
    .f { transition: color 600ms; }
    """

    assert Enum.map(duration_offenders(planted), fn {property, _value, reason} ->
             {property, reason}
           end) == [
             {"transition", "raw duration literal 150ms"},
             {"animation", "raw duration literal 1s"},
             {"transition-duration", "raw duration literal .2s"},
             {"transition", "the advance token is for the progress line only (selector .d)"},
             {"animation", "unknown duration token --duration-ops-sting"},
             {"transition", "raw duration literal 600ms"}
           ]

    accepted = """
    .ok1 { transition: opacity var(--duration-ops-fast) var(--ease-ops-exit); }
    .ok2 { transition-duration: var(--duration-ops-quick); }
    .ok3 { animation: ops-modal-in var(--duration-ops-base) var(--ease-ops-resolve); }
    .ok4 { transition-duration: 0s; animation-duration: 0ms; }
    .ok5 { transition: transform var(--duration-ops-instant), color var(--duration-ops-standard); }
    @media (prefers-reduced-motion: reduce) { * { transition-duration: 0.01ms !important; } }
    /* .commented { transition: opacity 150ms; } */
    """

    assert duration_offenders(accepted) == []
  end

  test "the brand durations are the source and the old names are var() aliases" do
    source = css()

    for {name, value} <- @brand_durations do
      assert source =~ "--duration-ops-#{name}: #{value};",
             "--duration-ops-#{name} must be #{value}"
    end

    for {old, brand} <- @duration_aliases do
      assert source =~ "--duration-ops-#{old}: var(--duration-ops-#{brand});",
             "--duration-ops-#{old} must alias --duration-ops-#{brand}"
    end

    declared =
      ~r/(?<![\w-])--duration-ops-([a-z-]+)\s*:/
      |> Regex.scan(strip_comments(source))
      |> Enum.map(fn [_decl, name] -> name end)
      |> Enum.sort()

    assert declared == Enum.sort(Map.keys(@brand_durations) ++ Map.keys(@duration_aliases))
  end

  test "no rule consumes the advance token and no sting duration exists" do
    source = strip_comments(css())

    refute source =~ "var(--duration-ops-advance)",
           "the advance token has no consumer in v1.46 (the progress line is not shipped)"

    refute source =~ ~r/\b1650\b|duration-ops-sting/

    # The one 600ms in the file is the token's own declaration.
    refute String.replace(source, "--duration-ops-advance: 600ms;", "") =~
             ~r/(?<![\w.-])600ms/
  end

  test "the brand easings are the book's six curves and the old names alias them" do
    source = strip_comments(css())

    for {name, curve} <- @brand_easings do
      assert source =~ "--ease-ops-#{name}: #{curve};", "--ease-ops-#{name} must be #{curve}"
    end

    for {old, brand} <- @easing_aliases do
      assert source =~ "--ease-ops-#{old}: var(--ease-ops-#{brand});",
             "--ease-ops-#{old} must alias --ease-ops-#{brand}"
    end
  end

  test "Tailwind's default transition duration is the quick token" do
    assert css() =~
             ~r/@theme\s+inline\s*\{[^}]*--default-transition-duration:\s*var\(--duration-ops-quick\);[^}]*\}/
  end

  # The rules of `source` as `{selectors, body}`, splitting each selector list on commas.
  defp rules(source) do
    for [_all, selector, body] <- Regex.scan(~r/([^{};]+)\{([^{}]*)\}/s, strip_comments(source)) do
      {selector
       |> String.split(",")
       |> Enum.map(&(&1 |> String.trim() |> String.replace(~r/\s+/, " "))), body}
    end
  end

  defp overridden?(source, selector, property, token) do
    wanted = "#{property}: var(--duration-ops-#{token})"

    Enum.any?(rules(source), fn {selectors, body} ->
      Enum.any?(selectors, &(normalise(&1) == normalise(selector))) and body =~ wanted
    end)
  end

  # `::before` and `:before` are the same selector; the built stylesheet may print either.
  defp normalise(selector), do: String.replace(selector, "::before", ":before")

  test "daisyUI component durations that ops renders are overridden to tokens" do
    for {label, source} <- [source: css(), built: File.read!(@built_css)],
        {selector, property, token} <- @daisy_overrides do
      assert overridden?(source, selector, property, token),
             "#{label} stylesheet: #{selector} must set #{property}: var(--duration-ops-#{token})"
    end
  end

  test "the override check fails when a component keeps its vendor duration" do
    refute overridden?(
             ".btn { transition-duration: 0.2s; }",
             ".btn",
             "transition-duration",
             "quick"
           )

    assert overridden?(
             ".x, .btn { transition-duration: var(--duration-ops-quick); }",
             ".btn",
             "transition-duration",
             "quick"
           )
  end

  test "reduced motion keeps the global rule at one iteration and 0.01ms" do
    source = strip_comments(css())

    assert source =~
             ~r/@media\s*\(prefers-reduced-motion:\s*reduce\)\s*\{\s*\*,\s*\*::before,\s*\*::after\s*\{[^}]*transition-duration:\s*0\.01ms\s*!important;[^}]*animation-duration:\s*0\.01ms\s*!important;[^}]*animation-iteration-count:\s*1\s*!important;/s
  end
end
