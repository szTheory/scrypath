defmodule ScrypathOpsWeb.ReskinComponentContractTest do
  @moduledoc false
  # Phase 187 component contract for the ScrypathOps re-skin: the phase's one new required
  # component and LiveView contract file, in the `ops-ui (path-scoped)` lane (see CONTRIBUTING
  # "Required-gate budget"). Plans 05 and 06 add their describes to this file; they do not add
  # another required file.
  #
  # What each describe proves, in plain terms:
  #   - E-01 `ops_sync_status`: each status renders its word first and then one decorative 16px
  #     bar icon with its own shape, so the status reads without color, and an unknown status is
  #     rejected when the component is compiled.
  #   - E-03 `ops_condition`: "Not observed", "Not checked", "Queue not used" and "Unavailable"
  #     are plain muted words with no icon, no status and no color of their own, so something
  #     nobody looked at can never read as healthy or as failed.
  #   - E-17 notices, statuses and verdicts: one Panel surface with a 2px inline-start rule. Failed
  #     color only for errors, Retrying amber for warnings and partial results, Control Edge for
  #     everything else; no cue dot, no tint, no shadow, no Plum or green.
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.OpsUi

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @ops_ui Path.expand("../../lib/scrypath_ops_web/components/ops_ui.ex", __DIR__)
  @condition_words ["Not observed", "Not checked", "Queue not used", "Unavailable"]

  @status_words %{
    failed: "Failed",
    retrying: "Retrying",
    pending: "Pending",
    clear: "Clear"
  }

  @status_shapes %{
    failed: "notched",
    retrying: "bottom-filled",
    pending: "hollow",
    clear: "filled"
  }

  # The tree of one rendered status: {tag, attrs, children}, whitespace between tags dropped.
  defp status_tree(status) do
    [tree] =
      (&OpsUi.ops_sync_status/1)
      |> render_component(%{status: status})
      |> LazyHTML.from_fragment()
      |> LazyHTML.to_tree(skip_whitespace_nodes: true)

    tree
  end

  describe "E-01 ops_sync_status" do
    for status <- [:failed, :retrying, :pending, :clear] do
      test "#{status} renders its word first and then one decorative bar icon" do
        status = unquote(status)
        {"span", attrs, [word, icon]} = status_tree(status)

        assert List.keyfind(attrs, "data-sync-status", 0) == {"data-sync-status", "#{status}"}
        assert {"span", word_attrs, [word_text]} = word
        assert List.keyfind(word_attrs, "class", 0) == {"class", "ops-sync-status__word"}
        assert word_text == @status_words[status]

        assert {"svg", icon_attrs, [{"path", _path_attrs, []}]} = icon
        icon_attrs = Map.new(icon_attrs)

        assert icon_attrs["class"] == "ops-sync-status__icon"
        assert icon_attrs["data-shape"] == @status_shapes[status]
        assert icon_attrs["aria-hidden"] == "true"
        assert icon_attrs["focusable"] == "false"
        assert icon_attrs["height"] == "16"
        assert icon_attrs["viewBox"] == "0 0 8.63 16"
        assert icon_attrs["fill"] == "currentColor"
        refute Map.has_key?(icon_attrs, "role")
        refute Map.has_key?(icon_attrs, "aria-label")
        refute Map.has_key?(icon_attrs, "aria-labelledby")
      end
    end

    test "exactly one status element and one icon per render" do
      for status <- Map.keys(@status_words) do
        doc =
          (&OpsUi.ops_sync_status/1)
          |> render_component(%{status: status})
          |> LazyHTML.from_fragment()

        assert doc |> LazyHTML.query("[data-sync-status]") |> Enum.count() == 1
        assert doc |> LazyHTML.query("svg") |> Enum.count() == 1
        assert doc |> LazyHTML.query("[data-sync-status=#{status}]") |> Enum.count() == 1
      end
    end

    test "the four shapes are drawn with four distinct paths" do
      paths =
        for status <- Map.keys(@status_words) do
          {"span", _attrs, [_word, {"svg", _icon_attrs, [{"path", path_attrs, []}]}]} =
            status_tree(status)

          {"d", d} = List.keyfind(path_attrs, "d", 0)
          d
        end

      assert length(paths) == 4
      assert paths |> Enum.uniq() |> length() == 4
    end

    test "an unknown status is rejected at compile time by the attr's closed value list" do
      status_attr =
        OpsUi.__components__()
        |> Map.fetch!(:ops_sync_status)
        |> Map.fetch!(:attrs)
        |> Enum.find(&(&1.name == :status))

      assert status_attr.required
      assert status_attr.type == :atom
      assert Keyword.fetch!(status_attr.opts, :values) == [:failed, :retrying, :pending, :clear]
    end
  end

  describe "E-03 ops_condition" do
    for word <- ["Not observed", "Not checked", "Queue not used", "Unavailable"] do
      test "#{word} is a plain word with no icon and no status" do
        word = unquote(word)
        html = render_component(&OpsUi.ops_condition/1, %{word: word})
        doc = LazyHTML.from_fragment(html)

        assert [condition] = doc |> LazyHTML.query(".ops-condition") |> Enum.to_list()
        assert String.trim(LazyHTML.text(condition)) == word

        assert doc |> LazyHTML.query("svg") |> Enum.count() == 0
        refute html =~ "hero-"
        refute html =~ "data-sync-status"
        refute html =~ "data-shape"
      end
    end

    test "the condition set is closed" do
      word_attr =
        OpsUi.__components__()
        |> Map.fetch!(:ops_condition)
        |> Map.fetch!(:attrs)
        |> Enum.find(&(&1.name == :word))

      assert word_attr.required
      assert Keyword.fetch!(word_attr.opts, :values) == @condition_words
      refute "Unknown" in @condition_words
    end

    test "the stylesheet paints a condition as muted body text with no status color" do
      [_, body] = Regex.run(~r/\n  \.ops-condition \{([^}]*)\}/, File.read!(@app_css))

      assert body =~ "color: var(--ops-text-muted)"
      assert body =~ "font-weight: 400"
      refute body =~ "--ops-status-"
    end
  end

  # kind => the one rule modifier it must render (UI-SPEC "Notices, verdicts, overlays")
  @kind_modifiers [
    info: "neutral",
    success: "neutral",
    running: "neutral",
    warning: "warning",
    partial: "warning",
    error: "error"
  ]

  defp render_status(kind, neutral \\ false) do
    assigns = %{kind: kind, neutral: neutral}

    rendered_to_string(~H"""
    <OpsUi.ops_status kind={@kind} neutral={@neutral} title="Title" role="status">
      Body text
    </OpsUi.ops_status>
    """)
  end

  defp render_notice(kind) do
    assigns = %{kind: kind}

    rendered_to_string(~H"""
    <OpsUi.ops_notice kind={@kind} title="Title">Body text</OpsUi.ops_notice>
    """)
  end

  defp render_verdict(kind) do
    assigns = %{kind: kind}

    rendered_to_string(~H"""
    <OpsUi.ops_verdict kind={@kind} status={:failed} headline="Headline">Evidence</OpsUi.ops_verdict>
    """)
  end

  defp surface_modifiers(html) do
    [surface] =
      html |> LazyHTML.from_fragment() |> LazyHTML.query(".ops-notice-surface") |> Enum.to_list()

    [classes] = LazyHTML.attribute(surface, "class")

    classes
    |> String.split()
    |> Enum.filter(&String.starts_with?(&1, "ops-notice-surface--"))
  end

  defp css_rule(selector) do
    [_, body] = Regex.run(~r/^\s*#{Regex.escape(selector)}\s*\{([^}]*)\}/m, File.read!(@app_css))
    body
  end

  describe "E-17 notices, statuses and verdicts" do
    for {kind, modifier} <- @kind_modifiers do
      test "ops_status #{kind} renders the Panel surface with the #{modifier} rule" do
        kind = unquote(kind)
        html = render_status(kind)

        assert surface_modifiers(html) == ["ops-notice-surface--#{unquote(modifier)}"]

        assert html
               |> LazyHTML.from_fragment()
               |> LazyHTML.query("[data-status-kind]")
               |> LazyHTML.attribute("data-status-kind") == ["#{kind}"]

        refute html =~ "ops-notice-surface__cue"
        refute html =~ ~r/ops-tone-(info|success|warning|partial|error|running)/
        refute html =~ "ops-notice-surface--raised"
        refute html =~ "text-base-content/"
      end

      test "ops_notice #{kind} renders the same surface and rule" do
        html = render_notice(unquote(kind))

        assert surface_modifiers(html) == ["ops-notice-surface--#{unquote(modifier)}"]
        refute html =~ "ops-notice-surface__cue"
        refute html =~ ~r/ops-tone-(info|success|warning|partial|error|running)/
        refute html =~ "text-base-content/"
      end

      test "ops_verdict #{kind} shares the surface and keeps its kind readable" do
        html = render_verdict(unquote(kind))

        assert surface_modifiers(html) == ["ops-notice-surface--#{unquote(modifier)}"]

        assert html
               |> LazyHTML.from_fragment()
               |> LazyHTML.query("[data-verdict-kind]")
               |> LazyHTML.attribute("data-verdict-kind") == ["#{unquote(kind)}"]

        # The status word replaces the old icon: one status component, no verdict icon.
        assert html =~ ~s(data-sync-status="failed")
        refute html =~ "ops-verdict__icon"
        refute html =~ "ops-verdict-icon"
        refute html =~ "hero-"
      end
    end

    test "the neutral kind and the neutral attr are neutral rules, and the attr never hides an error" do
      assert surface_modifiers(render_status(:neutral)) == ["ops-notice-surface--neutral"]
      assert surface_modifiers(render_status(:info, true)) == ["ops-notice-surface--neutral"]

      # Existing call sites pass `neutral` on errors; the kind still decides the rule.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <OpsUi.ops_status kind={:error} title="Title" neutral>Body text</OpsUi.ops_status>
        """)

      assert surface_modifiers(html) == ["ops-notice-surface--error"]
    end

    test "the stylesheet draws a Panel with a 2px inline-start rule and no shadow or tint" do
      surface = css_rule(".ops-notice-surface")

      assert surface =~ "border: 1px solid var(--color-base-300)"
      assert surface =~ "border-inline-start-width: 2px"
      assert surface =~ "background-color: var(--color-base-100)"
      assert surface =~ "box-shadow: none"

      assert css_rule(".ops-notice-surface--error") =~
               "border-inline-start-color: var(--ops-status-failed)"

      assert css_rule(".ops-notice-surface--warning") =~
               "border-inline-start-color: var(--ops-status-retrying)"

      assert css_rule(".ops-notice-surface--neutral") =~
               "border-inline-start-color: var(--ops-control-edge)"

      assert css_rule(".ops-notice-surface--error .ops-notice-surface__title") =~
               "color: var(--ops-status-failed)"

      assert css_rule(".ops-notice-surface--warning .ops-notice-surface__title") =~
               "color: var(--ops-status-retrying)"

      # No rule of the scheme mixes in a retired color, tints, or reaches for Plum or green.
      for selector <- [
            ".ops-notice-surface",
            ".ops-notice-surface--error",
            ".ops-notice-surface--warning",
            ".ops-notice-surface--neutral",
            ".ops-notice-surface__title",
            ".ops-notice-surface--error .ops-notice-surface__title",
            ".ops-notice-surface--warning .ops-notice-surface__title"
          ] do
        body = css_rule(selector)
        refute body =~ "color-mix(", selector

        for retired <-
              ~w(--color-primary --color-success --color-info --color-warning --color-error) do
          refute body =~ "var(#{retired})", "#{selector} uses #{retired}"
        end
      end
    end

    test "no cue dot, tinted tone or tinted badge rule is left in the stylesheet or component" do
      css = File.read!(@app_css)
      source = File.read!(@ops_ui)

      for retired <- [
            ~r/\.ops-tone-(info|success|warning|partial|error|running)\b/,
            ~r/\.ops-badge-[a-z]+\b/,
            ~r/\.ops-notice-surface__cue/,
            ~r/\.ops-notice-surface--raised/,
            ~r/\.ops-verdict__icon/,
            ~r/\.ops-metric__cue/
          ] do
        refute css =~ retired, "stylesheet still has #{inspect(retired)}"
      end

      for retired <- ["ops-notice-surface__cue", "verdict_icon", "tone_class(", "badge_class("] do
        refute source =~ retired, "ops_ui.ex still has #{retired}"
      end
    end

    test "a badge is plain muted text and a tone chip rides the same surface" do
      badge = css_rule(".ops-badge")

      assert badge =~ "color: var(--ops-text-muted)"
      refute badge =~ "border"
      refute badge =~ "background"
      refute badge =~ "color-mix("

      assigns = %{}

      html =
        rendered_to_string(~H"""
        <OpsUi.ops_badge kind={:error}>Search failed</OpsUi.ops_badge>
        """)

      assert html =~ "ops-badge"
      assert html =~ "Search failed"
      refute html =~ ~r/ops-badge-[a-z]+/

      chip =
        rendered_to_string(~H"""
        <OpsUi.ops_tone_chip kind={:error} label="Index" value="differs" />
        """)

      assert chip =~ "ops-tone-chip"
      assert surface_modifiers(chip) == ["ops-notice-surface--error"]
    end
  end
end
