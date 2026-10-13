defmodule ScrypathOpsWeb.DesignTokensContractTest do
  @moduledoc """
  Guards the design-token system against silent drift.

  Tailwind v4 generates `*-ops-*` utilities from the `@theme` block in
  `assets/css/app.css`. A typo like `rounded-ops-xl` (no such token) does not error —
  it silently produces no style. This contract scans every operator template for
  `*-ops-*` utility usage and every `var(--…)` reference, and asserts each resolves to
  a token actually defined in `app.css`. New tokens are picked up automatically; new
  typos fail the build.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()
  @web_root Path.join(__DIR__, "../../lib/scrypath_ops_web") |> Path.expand()
  @ops_ui Path.join(@web_root, "components/ops_ui.ex")
  @token_catalog Path.join(__DIR__, "../../assets/css/DESIGN-TOKENS.md") |> Path.expand()

  # Utility prefix → the `@theme` namespace whose tail it consumes. Longer prefixes
  # first so the regex alternation prefers `px-ops-` over `p-ops-`.
  @spacing_prefixes ~w(px py pt pb pl pr mx my mt mb ml mr gap-x gap-y space-x space-y gap p m)

  defp css, do: File.read!(@app_css)

  defp ops_ui, do: File.read!(@ops_ui)

  defp rule(selector) do
    [_, body] = Regex.run(~r/^\s*#{Regex.escape(selector)}\s*\{([^}]*)\}/ms, css())
    body
  end

  defp defined_tokens do
    Regex.scan(~r/--([a-z0-9-]+)\s*:/, css())
    |> Enum.map(fn [_, name] -> name end)
    |> MapSet.new()
  end

  # Tails defined for a namespace, e.g. namespace "text-ops" → ["xs", "sm", ...].
  defp tails(namespace) do
    Regex.scan(~r/--#{Regex.escape(namespace)}-([a-z0-9-]+)\s*:/, css())
    |> Enum.map(fn [_, tail] -> tail end)
    |> MapSet.new()
  end

  defp allowed_utilities do
    text = for t <- tails("text-ops"), do: "text-ops-#{t}"
    leading = for t <- tails("leading-ops"), do: "leading-ops-#{t}"
    rounded = for t <- tails("radius-ops"), do: "rounded-ops-#{t}"
    shadow = for t <- tails("shadow-ops"), do: "shadow-ops-#{t}"
    ease = for t <- tails("ease-ops"), do: "ease-ops-#{t}"
    z = for t <- tails("z-index-ops"), do: "z-ops-#{t}"

    spacing =
      for t <- tails("spacing-ops"), p <- @spacing_prefixes, do: "#{p}-ops-#{t}"

    MapSet.new(text ++ leading ++ rounded ++ shadow ++ ease ++ z ++ spacing)
  end

  defp template_files do
    Path.wildcard(Path.join(@web_root, "**/*.{ex,heex}"))
  end

  # Strip backtick-delimited inline code so doc-comment prose (e.g. `text-ops-h*`,
  # `var(--control-h-*)`) never reads as a real class/var reference. Live class lists
  # and `var()` calls are never wrapped in backticks.
  defp scannable(content), do: Regex.replace(~r/`[^`]*`/, content, " ")

  defp used_utilities do
    prefix_alt =
      (~w(text leading rounded shadow z ease) ++ @spacing_prefixes)
      |> Enum.join("|")

    re = ~r/\b(?:#{prefix_alt})-ops-[a-z0-9-]+/

    for file <- template_files(),
        match <- Regex.scan(re, scannable(File.read!(file))),
        do: {Path.relative_to(file, @web_root), hd(match)}
  end

  defp used_css_vars do
    for file <- template_files(),
        [_, name] <- Regex.scan(~r/var\(--([a-z0-9-]+)\)/, scannable(File.read!(file))),
        do: {Path.relative_to(file, @web_root), name}
  end

  test "every *-ops-* utility used in templates resolves to a defined @theme token" do
    allowed = allowed_utilities()

    orphans =
      used_utilities()
      |> Enum.reject(fn {_file, util} -> MapSet.member?(allowed, util) end)
      |> Enum.uniq()

    assert orphans == [],
           "Found *-ops-* utilities with no matching token in app.css @theme.\n" <>
             "Either fix the typo or add the token.\n" <>
             Enum.map_join(orphans, "\n", fn {file, util} -> "  #{util}  (#{file})" end)
  end

  test "every var(--…) referenced in templates is defined in app.css" do
    defined = defined_tokens()

    orphans =
      used_css_vars()
      |> Enum.reject(fn {_file, name} -> MapSet.member?(defined, name) end)
      |> Enum.uniq()

    assert orphans == [],
           "Found var(--…) references with no matching custom property in app.css.\n" <>
             Enum.map_join(orphans, "\n", fn {file, name} -> "  --#{name}  (#{file})" end)
  end

  test "operator modal visibility and layering support focus at mount" do
    assert ops_ui() =~ "modal modal-open ops-modal z-ops-modal"
    assert rule(".ops-modal") =~ "z-index: var(--z-index-ops-modal)"
    assert rule(".ops-modal") =~ "transition: opacity var(--duration-ops-fast)"
    assert css() =~ ~r/@starting-style\s*\{\s*\.ops-modal\.modal-open\s*\{\s*visibility: visible;/
    assert css() =~ "--z-index-ops-modal: 90;"
  end

  test "shell and overlay layers consume the named stacking roles" do
    assert css() =~ "--z-index-ops-header: 30;"
    assert css() =~ "--z-index-ops-sidebar: 35;"
    assert css() =~ "--z-index-ops-skip-link: 50;"
    assert css() =~ "--z-index-ops-flash: 60;"
    assert css() =~ "--z-index-ops-drawer: 75;"
    assert css() =~ "--z-index-ops-palette: 80;"
    assert rule(".ops-header") =~ "z-index: var(--z-index-ops-header)"
    assert rule(".ops-sidebar") =~ "z-index: var(--z-index-ops-sidebar)"
    assert rule(".ops-mobile-nav") =~ "z-index: var(--z-index-ops-drawer)"
    assert rule(".ops-cmdk") =~ "z-index: var(--z-index-ops-palette)"
    assert rule(".ops-modal") =~ "transition: opacity var(--duration-ops-fast)"
    assert css() =~ "--duration-ops-fast: 120ms;"
  end

  test "the token catalog lists all current OpsUi exports with component roles" do
    exports =
      Regex.scan(~r/^\s*def (ops_\w+)\(/m, ops_ui())
      |> Enum.map(fn [_, name] -> name end)

    catalog = File.read!(@token_catalog)

    missing = Enum.reject(exports, &String.contains?(catalog, "`#{&1}`"))
    assert missing == [], "Add these OpsUi exports to DESIGN-TOKENS.md: #{inspect(missing)}"

    assert catalog =~ "Primary task weights are 400 for body/value text and 600"
    assert catalog =~ "The existing 11px/12px scale remains reserved"
  end

  test "shared actions and responsive panels consume the named roles" do
    assert rule(".ops-command-hint") =~ "font-size: var(--text-ops-body)"
    assert ops_ui() =~ "text-ops-body font-semibold"
    assert ops_ui() =~ "p-ops-4 sm:p-ops-panel"

    cta = rule(".ops-intent-card__cta")
    assert cta =~ "min-height: var(--control-h-lg)"
    assert cta =~ "font-size: var(--text-ops-body)"

    retained = rule(".ops-time__retained")
    assert retained =~ "font-size: var(--text-ops-body)"
    assert rule(".ops-notice-surface__cue") =~ "margin-top: var(--spacing-ops-1)"

    posture_live = File.read!(Path.join(@web_root, "live/posture_live.ex"))
    assert posture_live =~ "space-y-ops-4"
    assert posture_live =~ "gap-ops-4"
    refute posture_live =~ "space-y-4"
    refute posture_live =~ "gap-4"
    refute posture_live =~ "mt-2"
    refute posture_live =~ "mt-4"
    refute posture_live =~ "mb-4"

    nav_targets = rule(".ops-nav-trigger,\n  .ops-nav-close")
    assert nav_targets =~ "min-width: var(--control-h-lg)"
    assert nav_targets =~ "min-height: var(--control-h-lg)"

    dialog_target = rule(".btn.ops-icon-btn")
    assert dialog_target =~ "min-width: var(--control-h-lg)"
    assert dialog_target =~ "min-height: var(--control-h-lg)"
  end

  test "quiet action states use neutral hover and press while keeping focus and selection distinct" do
    assert css() =~ ".ops-btn:hover:not(:disabled):not(.btn-primary):not(.btn-error)"
    assert css() =~ "background: var(--ops-surface-2)"
    assert css() =~ ".ops-btn:active:not(:disabled):not(.btn-primary):not(.btn-error)"
    assert css() =~ ".ops-btn[aria-pressed=\"true\"]"
    assert css() =~ "outline: 2px solid var(--color-primary)"
    assert css() =~ "outline-offset: 2px"
    assert css() =~ ".ops-btn:disabled"
  end

  test "muted text and neutral links override Tailwind's utility layer for AA contrast" do
    overrides =
      css()
      |> String.split("/* Cascade-safe operator text contrast.", parts: 2)
      |> List.last()

    refute overrides == css()
    refute overrides =~ "@layer"
    assert overrides =~ ".ops-shell .text-base-content\\/60"
    assert overrides =~ "color: var(--ops-text-muted)"
    assert overrides =~ ".ops-shell a.link:not(.link-primary):not(.text-primary)"
    assert overrides =~ "color: var(--color-base-content)"
  end

  test "refresh hook reapplies server eligibility after a LiveView patch" do
    hooks = File.read!(Path.join(__DIR__, "../../assets/js/ops_hooks.js") |> Path.expand())

    assert hooks =~ "readServerEligibility"
    assert hooks =~ "updated()"
    assert hooks =~ "this.serverDisabled || loading"
    assert hooks =~ "dataset.opsRefreshEligible !== \"true\""
  end
end
