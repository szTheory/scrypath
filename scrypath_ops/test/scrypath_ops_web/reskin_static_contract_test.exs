defmodule ScrypathOpsWeb.ReskinStaticContractTest do
  @moduledoc false
  # Phase 187 static contract for the ScrypathOps re-skin: one required gate in the
  # `ops-ui (path-scoped)` lane (see CONTRIBUTING "Required-gate budget"). It reads the source
  # stylesheet, the tracked built stylesheet, the served static files and the rendered output.
  # It never copies a hash, size or glyph list from a plan: the font hashes are recomputed from
  # the files, and the glyph coverage was read with fontTools from the pinned files (see below).
  #
  # What each describe proves, in plain terms:
  #   - E-14 font faces: the stylesheets declare exactly the two brand families and their two
  #     metric-adjusted fallbacks, with the pinned numbers, relative hash-pinned URLs, and no
  #     reference to the brand's display face.
  #   - E-15 font serving: the fonts are served with the right type and an immutable cache header
  #     at the mount prefix, and the stylesheet's relative URLs land on that path at any depth.
  #   - E-14 glyph coverage: every non-ASCII character that the six screens render, or that a CSS
  #     `content:` string can render, is either in the shipped font subsets or on a short, named
  #     fallback list. A character outside both would silently fall back to a system font.
  #   - E-13 brand assets: the lockups, symbol, favicon SVG and ICO that ops serves are
  #     byte-identical to their pinned `brand/` sources under the frozen file names, the ICO holds
  #     16 and 32 px entries, and the shell shows both lockups at 136 px wide.
  #   - E-15 preload: the standalone root layout links the SVG and ICO favicons and preloads the
  #     interface font with `crossorigin`; the mounted host layout never preloads.
  #   - E-10 control glyphs only: the nine control Heroicons are the only icons the source can
  #     render, every rendered svg sits inside a control (or is a sync-status shape), and no
  #     screen draws an icon in its nav, headings, flash, counts, refresh or import. A planted
  #     name outside the list fails the scan.
  #   - No infinite animation: neither the source stylesheet nor `lib/` can loop an animation or
  #     spin a loader (the render-level half is E-16 in the component contract file).
  #   - E-18 durations in lib: no Tailwind duration utility or `JS.transition` time in `lib/` is
  #     off the brand scale (the stylesheet half is `motion_contract_test.exs`).
  #   - E-12 retired patterns: one scan over the ops stylesheet, `lib/`, the ops JavaScript and the
  #     ecommerce host's `app.js` finds none of the patterns the re-skin retired (the old identity's
  #     class families, capital transforms, loops, the error button, alpha text utilities, the two
  #     old RGB triplets and the old progress-bar hex), and allows a gradient only in the two named
  #     rules. Planted cases for each family prove the scan fires.
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.CoreComponents
  alias ScrypathOpsWeb.OpsUi

  @ops_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("..", @ops_root)
  @host_layout Path.join(
                 @repo_root,
                 "examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/components/layouts.ex"
               )

  # Served file (relative to scrypath_ops/priv/static) => its pinned source under brand/.
  @brand_assets [
    {"images/scrypath-wordmark.svg", "assets/logo/scrypath-lockup-light.svg"},
    {"images/scrypath-wordmark-inverse.svg", "assets/logo/scrypath-lockup-dark.svg"},
    {"images/logo.svg", "assets/logo/scrypath-symbol-light.svg"},
    {"favicon.svg", "assets/icon/favicon.svg"},
    {"favicon.ico", "assets/icon/favicon.ico"}
  ]
  @app_css Path.join(@ops_root, "assets/css/app.css")
  @built_css Path.join(@ops_root, "priv/static/assets/css/app.css")
  @fonts_dir Path.join(@ops_root, "priv/static/assets/fonts")

  @font_files ~w(ui.woff2 mono.woff2)

  @font_url ~r/url\("(\.\.\/fonts\/([a-z]+\.woff2)\?v=([0-9a-f]{64}))"\)/

  # Glyph coverage, read with fontTools 4.62.1 from the pinned scrypath_ops/priv/static/assets/fonts
  # ui.woff2 (Hanken Grotesk) and mono.woff2 (Sometype Mono) on 2026-11-19. Beyond printable ASCII
  # (U+0020 to U+007E, in both), both subsets carry exactly: U+00A0, U+00B0, the Latin-1 letters
  # U+00C0 to U+00FF (including the multiplication and division signs), U+2013, U+2014, U+2018,
  # U+2019, U+201C, U+201D, U+2022, U+2026, U+2190, U+2192 and U+2212. The mono subset also has
  # U+2191 and U+2193; the Hanken subset does not, so they are not listed (a rendered up or down
  # arrow fails this test until it is moved to a mono-only element or added to the allowlist).
  @covered MapSet.new(
             [0x00A0, 0x00B0, 0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026] ++
               [0x2190, 0x2192, 0x2212] ++ Enum.to_list(0x00C0..0x00FF)
           )

  # Neither subset carries these three. They render from the metric-adjusted fallback faces and
  # then system-ui or ui-monospace. This is the whole named allowlist; growing it is a decision.
  @fallback_allowlist %{0x00B7 => "·", 0x203A => "›", 0x2318 => "⌘"}

  # LD-6, the whole set of Heroicons ScrypathOps may render. Each one is a control affordance
  # with an accessible name; none stands in for a word. Growing this list is a design decision.
  @control_glyphs ~w(hero-bars-3 hero-x-mark hero-chevron-down hero-clipboard-document
                     hero-sun-micro hero-moon-micro hero-computer-desktop-micro
                     hero-arrow-top-right-on-square hero-magnifying-glass)

  # The controls a rendered Heroicon may sit in: the nearest enclosing button or link, named by
  # tag and class (or `#id`). A status shape is not a Heroicon and is checked separately.
  @control_owners [
    {"button", "ops-nav-trigger"},
    {"button", "ops-nav-close"},
    {"button", "ops-command-hint"},
    {"button", "ops-theme-toggle__button"},
    {"button", "ops-time__stamp"},
    {"button", "ops-quiet-action"},
    {"button", "ops-icon-btn"},
    {"button", "ops-flash__close"},
    {"button", "#saved-search-picker-button"},
    {"a", "ops-help-link"}
  ]

  # The six screens, plus the all-statuses Search health fixture (five rows, every status word).
  @glyph_screens [
    {"Control room", "/ops"},
    {"Search health", "/ops/health"},
    {"Failed sync work", "/ops/failed-sync"},
    {"Sync and index", "/ops/sync-and-index"},
    {"Search", "/ops/search"},
    {"Help", "/ops/help"},
    {"Search health (all-statuses fixture)", "/ops/phase173/health?scenario=all-statuses"}
  ]

  defp sha256(path) do
    path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  defp css_files, do: [source: File.read!(@app_css), built: File.read!(@built_css)]

  defp font_face_blocks(css) do
    ~r/@font-face\s*\{[^}]*\}/ |> Regex.scan(css) |> Enum.map(&hd/1)
  end

  defp block_declaration(block, property) do
    case Regex.run(~r/(?:^|[\s{;])#{Regex.escape(property)}:\s*([^;}]+)/, block) do
      [_, value] -> value |> String.trim() |> String.replace(~r/\s+/, " ")
      nil -> nil
    end
  end

  # Failures (as strings naming the code point and where it was found) for every character in
  # `text` that is neither ASCII, nor in the shipped subsets, nor on the named fallback list.
  defp glyph_failures(text, where) do
    text
    |> String.to_charlist()
    |> Enum.filter(&(&1 > 0x7E))
    |> Enum.uniq()
    |> Enum.reject(&(MapSet.member?(@covered, &1) or Map.has_key?(@fallback_allowlist, &1)))
    |> Enum.map(fn cp ->
      "U+#{cp |> Integer.to_string(16) |> String.pad_leading(4, "0")} (#{<<cp::utf8>>}) " <>
        "is in the rendered output of #{where} but in neither font subset nor the fallback allowlist"
    end)
  end

  # Text the browser would paint: text nodes plus the attributes that render as text.
  defp rendered_text(html) do
    doc = LazyHTML.from_fragment(html)

    attributes =
      for name <- ~w(title aria-label placeholder alt value),
          value <- doc |> LazyHTML.query("[#{name}]") |> LazyHTML.attribute(name),
          do: value

    Enum.join([LazyHTML.text(doc) | attributes], "\n")
  end

  # Every string a `content:` declaration in the source stylesheet can paint, with CSS escapes
  # (a backslash plus hex digits) decoded to their characters.
  defp css_content_strings(css) do
    ~r/(?<![\w-])content:\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/
    |> Regex.scan(css)
    |> Enum.map(fn [_, quoted] ->
      quoted
      |> String.slice(1..-2//1)
      |> then(
        &Regex.replace(~r/\\([0-9a-fA-F]{1,6})\s?/, &1, fn _, hex ->
          <<String.to_integer(hex, 16)::utf8>>
        end)
      )
    end)
  end

  defp render_screen(conn, path) do
    {:ok, view, _html} = live(conn, path)
    render(view)
  end

  defp block_by_family(css, family) do
    Enum.find(font_face_blocks(css), fn block ->
      block_declaration(block, "font-family") == ~s("#{family}")
    end)
  end

  describe "E-14 font faces" do
    test "both stylesheets declare the four families and nothing else" do
      for {label, css} <- css_files() do
        families =
          css |> font_face_blocks() |> Enum.map(&block_declaration(&1, "font-family"))

        assert Enum.sort(families) ==
                 Enum.sort([
                   ~s("Hanken Grotesk"),
                   ~s("Sometype Mono"),
                   ~s("Hanken Grotesk Fallback"),
                   ~s("Sometype Mono Fallback")
                 ]),
               "#{label} stylesheet declares unexpected @font-face families: #{inspect(families)}"
      end
    end

    test "the brand faces swap, carry their weight ranges and load relative hash-pinned files" do
      for {label, css} <- css_files() do
        for {family, weights, file} <- [
              {"Hanken Grotesk", "400 700", "ui.woff2"},
              {"Sometype Mono", "400 500", "mono.woff2"}
            ] do
          block = block_by_family(css, family) || flunk("#{label}: no @font-face for #{family}")

          assert block_declaration(block, "font-display") == "swap", "#{label} #{family}"
          assert block_declaration(block, "font-weight") == weights, "#{label} #{family}"
          assert block_declaration(block, "font-style") == "normal", "#{label} #{family}"

          assert [_, url, ^file, version] = Regex.run(@font_url, block),
                 "#{label} #{family} must load ../fonts/#{file}?v=<sha256> (CSS-relative)"

          assert String.starts_with?(url, "../fonts/")
          assert version == sha256(Path.join(@fonts_dir, file)), "#{label} #{family} ?v= is stale"
        end
      end
    end

    test "the metric-adjusted fallback faces carry the exact override numbers" do
      for {label, css} <- css_files() do
        for {family, local, adjustments} <- [
              {"Hanken Grotesk Fallback",
               "local(\"Arial\"), local(\"Liberation Sans\"), local(\"Arimo\")",
               %{
                 "size-adjust" => "101.7%",
                 "ascent-override" => "98.3%",
                 "descent-override" => "29.8%",
                 "line-gap-override" => "0%"
               }},
              {"Sometype Mono Fallback",
               "local(\"Courier New\"), local(\"Liberation Mono\"), local(\"Cousine\")",
               %{
                 "size-adjust" => "96.7%",
                 "ascent-override" => "95.7%",
                 "descent-override" => "28.5%",
                 "line-gap-override" => "0%"
               }}
            ] do
          block = block_by_family(css, family) || flunk("#{label}: no @font-face for #{family}")

          assert block_declaration(block, "src") == local, "#{label} #{family}"

          for {property, value} <- adjustments do
            assert block_declaration(block, property) == value, "#{label} #{family} #{property}"
          end
        end
      end
    end

    test "the families resolve brand face, metric fallback, then the platform stack" do
      source = File.read!(@app_css)

      assert source =~
               ~s(--font-sans: "Hanken Grotesk", "Hanken Grotesk Fallback", system-ui, sans-serif;)

      assert source =~
               ~s(--font-mono: "Sometype Mono", "Sometype Mono Fallback", ui-monospace, monospace;)

      built = File.read!(@built_css)
      assert built =~ ~s(--font-sans: "Hanken Grotesk", "Hanken Grotesk Fallback")
      assert built =~ ~s(--font-mono: "Sometype Mono", "Sometype Mono Fallback")
    end

    test "the brand's display face is never declared or requested" do
      for {label, css} <- css_files() do
        refute css =~ "Bricolage", "#{label} stylesheet names the display face"
        refute css =~ "display.woff2", "#{label} stylesheet requests the display file"
      end

      # The file stays on disk because the brand pin verifier owns that directory.
      assert File.exists?(Path.join(@fonts_dir, "display.woff2"))
    end

    test "no font URL is root-absolute" do
      for {label, css} <- css_files() do
        urls = ~r/url\(\s*["']?([^"')]+\.woff2[^"')]*)["']?\s*\)/ |> Regex.scan(css)

        assert length(urls) == 2, "#{label} stylesheet must request exactly two font files"

        for [_, url] <- urls do
          refute String.starts_with?(url, "/"), "#{label}: root-absolute font URL #{url}"
          refute url =~ ~r{^[a-z]+://}i, "#{label}: absolute font URL #{url}"
        end
      end
    end
  end

  describe "E-15 font serving" do
    for file <- @font_files do
      test "GET /ops/assets/fonts/#{file}?v=<sha256> is a 200 woff2 with an immutable cache header",
           %{conn: conn} do
        path = Path.join(@fonts_dir, unquote(file))
        version = sha256(path)

        conn = get(conn, "/ops/assets/fonts/#{unquote(file)}?v=#{version}")

        assert conn.status == 200
        assert [content_type] = get_resp_header(conn, "content-type")
        assert String.starts_with?(content_type, "font/woff2"), content_type
        assert [cache_control] = get_resp_header(conn, "cache-control")
        assert cache_control =~ "immutable"
        assert cache_control =~ "max-age=31536000"
        assert :crypto.hash(:sha256, conn.resp_body) |> Base.encode16(case: :lower) == version
      end
    end

    test "the relative font URLs land on <prefix>/assets/fonts at every mount depth" do
      css = File.read!(@built_css)
      urls = Regex.scan(@font_url, css)
      assert length(urls) == 2

      for prefix <- ["/ops", "/admin/search", "/a/b/c"], [_, relative, file, version] <- urls do
        stylesheet = URI.parse("https://host.example#{prefix}/assets/css/app.css")
        resolved = URI.merge(stylesheet, relative)

        assert resolved.path == "#{prefix}/assets/fonts/#{file}"
        assert resolved.query == "v=#{version}"
      end
    end
  end

  describe "E-14 glyph coverage" do
    test "the six screens render only glyphs the fonts carry or the named fallback list names", %{
      conn: conn
    } do
      failures =
        for {screen, path} <- @glyph_screens,
            failure <- glyph_failures(rendered_text(render_screen(conn, path)), screen),
            do: failure

      assert failures == [], Enum.join(failures, "\n")
    end

    test "CSS content strings paint only glyphs the fonts carry or the named fallback list names" do
      strings = css_content_strings(File.read!(@app_css))

      failures = Enum.flat_map(strings, &glyph_failures(&1, "a CSS content string"))
      assert failures == [], Enum.join(failures, "\n")
    end

    test "the content-string reader decodes escapes and ignores look-alike properties" do
      css =
        ~S|a::before { content: "\2500 x"; } .b { justify-content: center; --x-content: "─"; }|

      assert css_content_strings(css) == ["─x"]
    end

    test "a planted box-drawing character fails and the failure names the code point and screen" do
      assert [failure] = glyph_failures("Search health ─ ready", "Search health")
      assert failure =~ "U+2500"
      assert failure =~ "Search health"

      assert glyph_failures("12 min · 3 › ⌘K → … — ×", "a planted allowed string") == []
      assert [up] = glyph_failures("rank ↑", "a planted arrow")
      assert up =~ "U+2191"
    end

    test "the fallback allowlist and the covered set are disjoint and exactly three entries" do
      # If a font refresh adds one of the three glyphs to a subset, its allowlist entry is stale.
      assert Enum.sort(Map.keys(@fallback_allowlist)) == [0x00B7, 0x203A, 0x2318]
      refute Enum.any?(Map.keys(@fallback_allowlist), &MapSet.member?(@covered, &1))
    end
  end

  describe "E-13 brand assets" do
    test "every served brand file exists under its frozen name and equals its pinned source" do
      for {served, source} <- @brand_assets do
        served_path = Path.join(@ops_root, "priv/static/#{served}")
        source_path = Path.join(@repo_root, "brand/#{source}")

        assert File.exists?(served_path), "#{served} must exist under its frozen name"
        assert File.exists?(source_path), "brand/#{source} must exist"

        assert File.read!(served_path) == File.read!(source_path),
               "#{served} must be a byte-identical copy of brand/#{source}"
      end
    end

    test "the ICO holds exactly the 16 and 32 pixel entries" do
      <<0::little-16, 1::little-16, count::little-16, rest::binary>> =
        File.read!(Path.join(@ops_root, "priv/static/favicon.ico"))

      assert count == 2

      entries =
        for index <- 0..(count - 1) do
          <<width, height, _colors, 0, _planes::little-16, _bits::little-16, size::little-32,
            offset::little-32>> = binary_part(rest, index * 16, 16)

          {width, height, size, offset}
        end

      assert entries |> Enum.map(fn {width, height, _, _} -> {width, height} end) |> Enum.sort() ==
               [{16, 16}, {32, 32}]

      # Each entry points at PNG data inside the file.
      file = File.read!(Path.join(@ops_root, "priv/static/favicon.ico"))

      for {_, _, size, offset} <- entries do
        assert binary_part(file, offset, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
        assert offset + size <= byte_size(file)
      end
    end

    test "the shell shows both lockups at 136px wide under the frozen names", %{conn: conn} do
      doc = conn |> render_screen("/ops/help") |> LazyHTML.from_fragment()

      light = LazyHTML.query(doc, "img.ops-wordmark__light")
      dark = LazyHTML.query(doc, "img.ops-wordmark__dark")

      # The shell renders the lockup in more than one place (header, sidebar, drawer); every
      # copy must use the frozen src and the 136px width.
      assert light |> LazyHTML.attribute("src") |> Enum.uniq() ==
               ["/ops/images/scrypath-wordmark.svg"]

      assert dark |> LazyHTML.attribute("src") |> Enum.uniq() ==
               ["/ops/images/scrypath-wordmark-inverse.svg"]

      assert light |> LazyHTML.attribute("width") |> Enum.uniq() == ["136"]
      assert dark |> LazyHTML.attribute("width") |> Enum.uniq() == ["136"]

      css = File.read!(@app_css)
      assert css =~ ~r/\.ops-wordmark\s*\{[^}]*flex:\s*none;[^}]*width:\s*8\.5rem;/s
      assert css =~ ~r/\.ops-wordmark img\s*\{[^}]*height:\s*auto;/s
    end
  end

  describe "E-15 root layout links and font preload" do
    test "standalone HTML links both favicons and preloads the interface font once", %{conn: conn} do
      doc = conn |> get("/ops/help") |> html_response(200) |> LazyHTML.from_document()

      icons = doc |> LazyHTML.query("link[rel=icon]") |> LazyHTML.attributes()

      assert [{"rel", "icon"}, {"href", "/favicon.svg"}, {"type", "image/svg+xml"}] in icons
      assert [{"rel", "icon"}, {"href", "/favicon.ico"}, {"sizes", "32x32"}] in icons

      assert [preload] = doc |> LazyHTML.query("link[rel=preload]") |> LazyHTML.attributes()
      attributes = Map.new(preload)

      version = sha256(Path.join(@fonts_dir, "ui.woff2"))
      assert attributes["href"] == "/assets/fonts/ui.woff2?v=#{version}"
      assert attributes["as"] == "font"
      assert attributes["type"] == "font/woff2"
      assert Map.has_key?(attributes, "crossorigin")
    end

    test "the mounted host layout never preloads a font" do
      host = File.read!(@host_layout)

      refute host =~ ~s(rel="preload")
      # It links the favicons at the mount prefix instead (documented in the README).
      assert host =~ "/admin/search/favicon.svg"
      assert host =~ "/admin/search/favicon.ico"
    end
  end

  # ── Plan 06: icons are control glyphs, nothing loops ─────────────────────────────────────

  @lib_root Path.join(@ops_root, "lib")

  defp lib_sources do
    @lib_root
    |> Path.join("**/*.{ex,heex}")
    |> Path.wildcard()
    |> Enum.map(&{Path.relative_to(&1, @ops_root), File.read!(&1)})
  end

  # Quoted Heroicon names in `source` that are not on the control list. Only a literal that
  # starts with `"hero-` counts, so an id that merely contains the word "hero" is not an icon.
  defp icon_offenders(source) do
    ~r/"(hero-[a-z0-9-]+)/
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(&1 in @control_glyphs))
  end

  # Icons rendered from a variable name cannot be checked by the literal scan, so none may exist.
  defp dynamic_icon_names(source), do: Regex.scan(~r/\bicon\s+name=\{/, source)

  # Every svg in `html` with its ancestors (nearest first) as {tag, attributes}.
  defp svg_chains(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.to_tree() |> collect_svgs([], [])
  end

  defp collect_svgs(nodes, ancestors, acc) when is_list(nodes),
    do: Enum.reduce(nodes, acc, &collect_svgs(&1, ancestors, &2))

  defp collect_svgs({"svg", attrs, _children}, ancestors, acc),
    do: [{Map.new(attrs), ancestors} | acc]

  defp collect_svgs({tag, attrs, children}, ancestors, acc),
    do: collect_svgs(children, [{tag, Map.new(attrs)} | ancestors], acc)

  defp collect_svgs(_text_or_comment, _ancestors, acc), do: acc

  defp classes(attrs), do: String.split(attrs["class"] || "")

  defp owner_matches?({tag, attrs}, {tag, "#" <> id}), do: attrs["id"] == id
  defp owner_matches?({tag, attrs}, {tag, class}), do: class in classes(attrs)
  defp owner_matches?(_control, _owner), do: false

  # A Heroicon is allowed only inside one of the named controls (its nearest button or link).
  defp control_glyph?({_svg, ancestors}) do
    case Enum.find(ancestors, fn {tag, _attrs} -> tag in ["button", "a"] end) do
      nil -> false
      control -> Enum.any?(@control_owners, &owner_matches?(control, &1))
    end
  end

  # A sync-status shape is the other kind of svg: it carries `data-shape` and sits in the status.
  defp status_shape?({svg, ancestors}) do
    Map.has_key?(svg, "data-shape") and
      Enum.any?(ancestors, fn {_tag, attrs} -> "ops-sync-status" in classes(attrs) end)
  end

  defp svg_label({svg, ancestors}) do
    chain =
      ancestors
      |> Enum.take(4)
      |> Enum.map_join(" < ", fn {tag, attrs} ->
        id = if attrs["id"], do: "#" <> attrs["id"], else: ""
        "#{tag}#{id}.#{attrs |> classes() |> Enum.take(2) |> Enum.join(".")}"
      end)

    "svg.#{svg |> classes() |> Enum.join(".")} in #{chain}"
  end

  defp count_in(html, selector),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.count()

  describe "E-10 control glyphs only (source)" do
    test "every quoted Heroicon literal under lib is on the control-glyph list" do
      sources = lib_sources()

      # The scan must see the files it claims to scan, so an empty glob cannot pass.
      assert Enum.any?(sources, fn {file, source} ->
               file =~ "components/layouts.ex" and source =~ ~s("hero-bars-3")
             end)

      offenders =
        for {file, source} <- sources, name <- icon_offenders(source), do: "#{file}: #{name}"

      assert offenders == [],
             "Heroicons outside the control-glyph list (LD-6):\n" <> Enum.join(offenders, "\n")
    end

    test "no icon takes its name from a variable" do
      offenders =
        for {file, source} <- lib_sources(), dynamic_icon_names(source) != [], do: file

      assert offenders == [], "icon name={...} hides a name from the scan: #{inspect(offenders)}"
    end

    test "a planted name outside the list fails the scan, and an exact control name passes" do
      assert icon_offenders(~s(<.icon name="hero-arrow-path" class="size-4" />)) ==
               ["hero-arrow-path"]

      # A longer name that merely starts with a control name is a different icon.
      assert icon_offenders(~s(<.icon name="hero-x-mark-solid" />)) == ["hero-x-mark-solid"]
      assert icon_offenders(~s(icon: "hero-information-circle")) == ["hero-information-circle"]

      for name <- @control_glyphs do
        assert icon_offenders(~s(<.icon name="#{name}" />)) == []
      end

      # A string that only contains the word is not an icon literal.
      assert icon_offenders(~s(id: "ops-empty-hero-heading-1")) == []

      assert dynamic_icon_names(~s(<.icon name={@icon} class="size-5" />)) != []
      assert dynamic_icon_names(~s(<.icon name="hero-x-mark" />)) == []
    end

    test "the control list is exactly the nine LD-6 glyphs" do
      assert Enum.sort(@control_glyphs) ==
               Enum.sort(~w(hero-bars-3 hero-x-mark hero-chevron-down hero-clipboard-document
                            hero-sun-micro hero-moon-micro hero-computer-desktop-micro
                            hero-arrow-top-right-on-square hero-magnifying-glass))
    end
  end

  describe "E-10 control glyphs only (rendered)" do
    for {label, path} <- @glyph_screens do
      test "#{label}: every svg is a control glyph or a sync-status shape", %{conn: conn} do
        html = render_screen(conn, unquote(path))
        chains = svg_chains(html)

        assert chains != [], "#{unquote(label)} renders no svg at all; the check would be vacuous"

        offenders =
          chains
          |> Enum.reject(&(control_glyph?(&1) or status_shape?(&1)))
          |> Enum.map(&svg_label/1)

        assert offenders == [],
               "#{unquote(label)} renders an icon outside a control:\n" <>
                 Enum.join(offenders, "\n")

        # A data-shape svg exists only inside the status component.
        assert count_in(html, "svg[data-shape]") ==
                 count_in(html, ".ops-sync-status svg[data-shape]")
      end

      test "#{label}: nav, counts, refresh, flash and headings carry no icon", %{conn: conn} do
        html = render_screen(conn, unquote(path))

        assert count_in(html, ".ops-primary-nav svg") == 0
        assert count_in(html, ".ops-nav-item__icon") == 0
        assert count_in(html, ".ops-signal-counts svg:not([data-shape])") == 0
        assert count_in(html, ".ops-refresh-button svg") == 0
        assert count_in(html, ".ops-flash .alert > svg") == 0
        assert count_in(html, ".ops-intent-card svg") == 0
        assert count_in(html, ".ops-empty-hero svg") == 0
        assert count_in(html, "h1 svg, h2 svg, h3 svg") == 0
        assert count_in(html, ".ops-help-heading") == 0
      end
    end

    test "the status shapes render on the all-statuses fixture, only inside the status", %{
      conn: conn
    } do
      html = render_screen(conn, "/ops/phase173/health?scenario=all-statuses")

      assert count_in(html, "svg[data-shape]") >= 4

      assert count_in(html, "svg[data-shape]") ==
               count_in(html, ".ops-sync-status svg[data-shape]")
    end

    test "the matcher rejects an icon in a nav item and one inside a plain link" do
      nav =
        ~s(<a class="ops-nav-item"><span class="ops-nav-item__icon"><svg class="size-4"></svg></span></a>)

      plain = ~s(<a href="/x" class="link"><svg class="size-4"></svg></a>)
      help = ~s(<a href="/x" class="ops-help-link"><svg class="size-3.5"></svg></a>)

      assert [chain] = svg_chains(nav)
      refute control_glyph?(chain)
      assert [chain] = svg_chains(plain)
      refute control_glyph?(chain)
      assert [chain] = svg_chains(help)
      assert control_glyph?(chain)

      # A data-shape svg outside the status is not a status shape.
      stray = ~s(<span class="other"><svg data-shape="filled"></svg></span>)
      assert [chain] = svg_chains(stray)
      refute status_shape?(chain)
    end

    test "the Help screen headings carry text only", %{conn: conn} do
      html = render_screen(conn, "/ops/help")

      assert count_in(html, ".ops-help-content h2") >= 5
      assert count_in(html, ".ops-help-content h2 svg, .ops-help-content h3 svg") == 0
      assert count_in(html, ".ops-help-content h2 span") == 0
    end

    test "an intent card, an empty hero and a refresh button render no icon" do
      assigns = %{}

      card =
        rendered_to_string(~H"""
        <OpsUi.ops_intent_card
          title="Try a search"
          summary="Query your schemas."
          route_label="Try a search"
          navigate="/ops/search"
        />
        """)

      hero =
        rendered_to_string(~H"""
        <OpsUi.ops_empty_hero title="No matching documents">Try fewer words.</OpsUi.ops_empty_hero>
        """)

      refresh =
        rendered_to_string(~H"""
        <OpsUi.ops_refresh_button id="r" aria_label="Refresh search health" />
        """)

      for html <- [card, hero, refresh], do: assert(svg_chains(html) == [])
      refute card =~ "Start here"
      refute card =~ "ops-intent-card__icon"
      refute hero =~ "ops-empty-hero__mark"
    end

    test "the flash renders its text and a close button, with no leading icon" do
      for {kind, flash} <- [info: %{"info" => "Saved."}, error: %{"error" => "Did not save."}] do
        html = render_component(&CoreComponents.flash/1, kind: kind, flash: flash)

        assert html =~ "aria-label=\"Close notification\""
        assert count_in(html, ".alert > svg") == 0
        assert [chain] = svg_chains(html)
        assert control_glyph?(chain)
        refute html =~ "opacity-40"
      end
    end
  end

  describe "no infinite animation in source" do
    @infinite_css ~r/\binfinite\b|@keyframes\s+(spin|ops-pulse)\b|\bops-pulse\b/
    @infinite_lib ~r/\binfinite\b|\banimate-(spin|pulse|ping|bounce)\b|\bops-pulse\b/

    test "the source stylesheet never loops, spins or pulses" do
      css = File.read!(@app_css)

      hits = @infinite_css |> Regex.scan(css) |> Enum.map(&hd/1)
      assert hits == [], "infinite iteration, spin or pulse in app.css: #{inspect(hits)}"

      # The built stylesheet also carries daisyUI's own `.progress` and `.skeleton` loops, which no
      # ScrypathOps markup renders (next test), so only the two ops-authored loops are checked here.
      built = File.read!(@built_css)
      refute built =~ ~r/@keyframes\s+(spin|ops-pulse)\b|animation:\s*(spin|ops-pulse)\b/
    end

    test "no template uses a daisyUI loading, skeleton or progress component" do
      looping_class =
        ~r/class="[^"]*(?<![\w-])(skeleton|loading|progress|loading-[a-z]+)(?![\w-])[^"]*"/

      offenders =
        for {file, source} <- lib_sources(),
            [hit | _] <- Regex.scan(looping_class, source),
            do: "#{file}: #{hit}"

      assert offenders == [], Enum.join(offenders, "\n")

      assert Regex.match?(looping_class, ~s(<span class="loading loading-spinner"></span>))
      assert Regex.match?(looping_class, ~s(<div class="skeleton h-4 w-full"></div>))
      refute Regex.match?(looping_class, ~s(<div class="ops-loading ops-loading__bars"></div>))
    end

    test "no screen renders an animate class", %{conn: conn} do
      for {label, path} <- @glyph_screens do
        html = render_screen(conn, path)

        assert count_in(html, "[class*='animate']") == 0,
               "#{label} renders an element whose class contains animate"
      end
    end

    test "lib holds no animated spinner or pulse class, including documentation examples" do
      offenders =
        for {file, source} <- lib_sources(),
            hit <- Regex.scan(@infinite_lib, source),
            do: "#{file}: #{hd(hit)}"

      assert offenders == [], Enum.join(offenders, "\n")
    end

    test "the patterns catch a planted loop in a stylesheet and in a template" do
      assert Regex.match?(@infinite_css, ".x { animation: spin 1s linear infinite; }")
      assert Regex.match?(@infinite_css, "@keyframes spin { to { transform: rotate(1turn) } }")
      assert Regex.match?(@infinite_css, ".x { animation: ops-pulse 1s; }")

      assert Regex.match?(
               @infinite_lib,
               ~s(<.icon name="hero-x-mark" class="motion-safe:animate-spin" />)
             )

      refute Regex.match?(@infinite_css, ".x { animation: ops-fade-in 240ms both; }")
    end
  end

  # ── Plan 09: E-18, durations in lib are tokens ───────────────────────────────────────────

  describe "E-18 durations in lib are brand tokens" do
    # A Tailwind duration utility in `lib/` must be the token form `duration-(--duration-ops-…)`.
    # The lookbehind keeps a `--duration-ops-…` custom property name in prose from reading as a
    # utility.
    @duration_utility ~r/(?<![\w-])duration-(?!\(--duration-ops-(?:instant|quick|base)\))[^\s"'\\]+/
    @retired_duration_literals ~r/(?<![\w-])duration-(?:100|200)\b|\btime:\s*120\b|\banimate-spin\b/
    @js_time ~r/\btime:\s*(\d+)/
    @js_times [80, 160, 240]

    defp duration_offenders(source) do
      utilities = Regex.scan(@duration_utility, source) |> Enum.map(&hd/1)

      times =
        for [hit, ms] <- Regex.scan(@js_time, source),
            String.to_integer(ms) not in @js_times,
            do: hit

      Regex.scan(@retired_duration_literals, source)
      |> Enum.map(&hd/1)
      |> Kernel.++(utilities)
      |> Kernel.++(times)
      |> Enum.uniq()
    end

    test "lib holds no duration-100, duration-200, time: 120 or animate-spin literal" do
      offenders =
        for {file, source} <- lib_sources(),
            hit <- Regex.scan(@retired_duration_literals, source),
            do: "#{file}: #{hd(hit)}"

      assert offenders == [], Enum.join(offenders, "\n")
    end

    test "every Tailwind duration utility and every JS.transition time in lib is a brand token" do
      offenders =
        for {file, source} <- lib_sources(),
            hit <- duration_offenders(source),
            do: "#{file}: #{hit}"

      assert offenders == [], Enum.join(offenders, "\n")
    end

    test "the scan rejects planted literals and accepts the token forms" do
      planted = """
      JS.transition({"transition-opacity duration-100 ease-ops-exit", "a", "b"}, time: 120)
      {"transition-all ease-ops-out duration-200", "a", "b"}
      <div class="transition duration-300 duration-[250ms]">
      JS.hide(to: "#x", time: 90)
      <span class="animate-spin"></span>
      """

      assert duration_offenders(planted) ==
               [
                 "duration-100",
                 "time: 120",
                 "duration-200",
                 "animate-spin",
                 "duration-300",
                 "duration-[250ms]",
                 "time: 90"
               ]

      accepted = """
      {"transition-all ease-ops-exit duration-(--duration-ops-quick)", "a", "b"}
      JS.transition({"transition-opacity duration-(--duration-ops-quick) ease-ops-exit", "a", "b"}, time: 160)
      JS.show(to: "#x", time: 240, transition: {"transition-all duration-(--duration-ops-base)", "a", "b"})
      # the token is --duration-ops-slow in prose, not a utility
      """

      assert duration_offenders(accepted) == []
    end

    test "the JS.transition sites use the quick and base tokens with matching times" do
      core = File.read!(Path.join(@lib_root, "scrypath_ops_web/components/core_components.ex"))
      ui = File.read!(Path.join(@lib_root, "scrypath_ops_web/components/ops_ui.ex"))

      # flash enter: base token, 240ms; flash exit and both modal exits: quick token, 160ms
      assert core =~
               ~r/time: 240,\s*transition:\s*\{"transition-all ease-ops-out duration-\(--duration-ops-base\)"/

      assert core =~
               ~r/time: 160,\s*transition:\s*\{"transition-all ease-ops-exit duration-\(--duration-ops-quick\)"/

      assert length(
               Regex.scan(
                 ~r/"transition-opacity duration-\(--duration-ops-quick\) ease-ops-exit"[^)]*time: 160/s,
                 ui
               )
             ) == 2
    end
  end

  # ── Plan 09: E-12, retired patterns stay retired ─────────────────────────────────────────

  describe "E-12 retired patterns" do
    # The UI-SPEC "Retired Code and Grep Gates" list, one family per entry. Each count is 0 in
    # the scoped files; none of these has an allowlist.
    @retired_patterns [
      {"retired identity family",
       ~r/ops-path|ops-copper|ops-glow|shadow-ops-glow|copper|primary-strong|ops-surface-2|bg-ops-surface-2/},
      {"capital transform", ~r/uppercase|tracking-wide/},
      {"infinite or spinner motion",
       ~r/infinite|animate-spin|animate-pulse|ops-pulse|@keyframes spin|duration-ops-sting|\b1650\b/},
      {"error button or danger variant", ~r/btn-error|variant=\{:danger\}|variant: :danger/},
      {"alpha text utility", ~r/text-base-content\/[0-9]/},
      {"retired rgb triplet", ~r/rgba?\(\s*(?:108|193)\s*,/},
      {"old progress-bar hex", ~r/#29d\b/}
    ]

    # A gradient is allowed only in these rules and only up to these counts. The list can shrink;
    # growing it is a design decision (LD-11), not a test edit.
    @gradient_allowance [{".ops-table-scroll", 4}, {"select.ops-form-control", 2}]

    @scope_paths [
      "scrypath_ops/assets/css/app.css",
      "scrypath_ops/assets/js/app.js",
      "examples/scrypath_ecommerce/assets/js/app.js"
    ]

    # Every problem `text` (the contents of `path`) has, as `{family, path, what}`. Pure: it reads
    # nothing, so the planted cases below run the same code the live scan does.
    defp scan_retired(path, text) do
      pattern_hits =
        for {family, pattern} <- @retired_patterns,
            [hit | _] <- Regex.scan(pattern, text),
            do: {family, path, hit}

      pattern_hits ++ gradient_hits(path, text)
    end

    defp gradient_hits(path, text) do
      if String.ends_with?(path, ".css") do
        css_gradient_hits(path, text)
      else
        for [hit] <- Regex.scan(~r/gradient/, text),
            do: {"gradient outside a stylesheet", path, hit}
      end
    end

    # Count the gradient functions per rule, in comment-free CSS, and judge each rule against the
    # allowance. A rule that is not on the list may hold none.
    defp css_gradient_hits(path, css) do
      comment_free = Regex.replace(~r{/\*.*?\*/}s, css, "")

      counts =
        for [_all, selector, body] <- Regex.scan(~r/([^{};]+)\{([^{}]*)\}/s, comment_free),
            n = length(Regex.scan(~r/gradient\(/, body)),
            n > 0,
            reduce: %{} do
          acc ->
            selector = selector |> String.replace(~r/\s+/, " ") |> String.trim()
            Map.update(acc, selector, n, &(&1 + n))
        end

      for {selector, n} <- Enum.sort(counts),
          problem = gradient_problem(selector, n),
          do: {"gradient outside its allowed rule", path, problem}
    end

    defp gradient_problem(selector, n) do
      case List.keyfind(@gradient_allowance, selector, 0) do
        nil -> "#{selector}: #{n} gradient function(s), none allowed in this rule"
        {_selector, max} when n > max -> "#{selector}: #{n} gradient functions, at most #{max}"
        {_selector, _max} -> nil
      end
    end

    # The files the gate reads: the ops stylesheet and `lib/`, the ops JavaScript (the entry and
    # the `ops_*.js` modules, never `vendor/`) and the ecommerce host's `app.js`.
    defp scoped_files do
      ops_js = Path.wildcard(Path.join(@ops_root, "assets/js/ops_*.js"))
      lib = Path.wildcard(Path.join(@lib_root, "**/*.{ex,heex}"))
      named = Enum.map(@scope_paths, &Path.join(@repo_root, &1))

      Enum.map(named ++ ops_js ++ lib, &{Path.relative_to(&1, @repo_root), &1})
    end

    test "no scoped file holds a retired pattern or a gradient outside its two rules" do
      offenders =
        for {relative, path} <- scoped_files(),
            {family, file, what} <- scan_retired(relative, File.read!(path)),
            do: "#{file}: #{family}: #{what}"

      assert offenders == [], Enum.join(offenders, "\n")
    end

    test "the scope reads the stylesheet, lib, the ops JavaScript and the host app.js, never vendor" do
      relatives = Enum.map(scoped_files(), &elem(&1, 0))

      for needed <- @scope_paths ++ ["scrypath_ops/assets/js/ops_hooks.js"] do
        assert needed in relatives, "#{needed} must be scanned"
      end

      assert Enum.count(relatives, &String.starts_with?(&1, "scrypath_ops/lib/")) >= 20
      assert Enum.count(relatives, &String.starts_with?(&1, "scrypath_ops/assets/js/ops_")) >= 6
      refute Enum.any?(relatives, &String.contains?(&1, "/vendor/"))
    end

    test "a planted occurrence of each retired family fails and names the family and the file" do
      css = "scrypath_ops/assets/css/app.css"
      lib = "scrypath_ops/lib/x.ex"
      js = "scrypath_ops/assets/js/app.js"
      host = "examples/scrypath_ecommerce/assets/js/app.js"

      planted = [
        {"retired identity family", css, ".ops-copper-badge { color: red; }", "ops-copper"},
        {"retired identity family", lib, ~s(class="shadow-ops-glow"), "shadow-ops-glow"},
        {"retired identity family", css, "--ops-surface-2: #fff;", "ops-surface-2"},
        {"retired identity family", css, "--color-primary-strong: red;", "primary-strong"},
        {"capital transform", lib, ~s(class="uppercase"), "uppercase"},
        {"capital transform", lib, ~s(class="tracking-wide"), "tracking-wide"},
        {"infinite or spinner motion", css, ".x { animation: a 1s infinite; }", "infinite"},
        {"infinite or spinner motion", lib, ~s(class="animate-spin"), "animate-spin"},
        {"infinite or spinner motion", lib, ~s(class="animate-pulse"), "animate-pulse"},
        {"infinite or spinner motion", css, "@keyframes spin { }", "@keyframes spin"},
        {"infinite or spinner motion", css, "--x: var(--duration-ops-sting);",
         "duration-ops-sting"},
        {"infinite or spinner motion", css, ".x { --t: 1650; }", "1650"},
        {"error button or danger variant", lib, ~s(class="btn btn-error"), "btn-error"},
        {"error button or danger variant", lib, "<.ops_button variant={:danger}>",
         "variant={:danger}"},
        {"error button or danger variant", lib, "attr :v, default: [variant: :danger]",
         "variant: :danger"},
        {"alpha text utility", lib, ~s(class="text-base-content/70"), "text-base-content/7"},
        {"retired rgb triplet", css, "--x: rgba(108, 99, 255, .2);", "rgba(108,"},
        {"retired rgb triplet", css, "--x: rgb( 193 , 100, 40);", "rgb( 193 ,"},
        {"old progress-bar hex", js, ~S|topbar.config({barColors: {0: "#29d"}})|, "#29d"},
        {"old progress-bar hex", host, ~s(barColors: {0: "#29d"}), "#29d"}
      ]

      for {family, path, text, needle} <- planted do
        hits = scan_retired(path, text)

        assert Enum.any?(hits, fn {f, p, what} -> f == family and p == path and what =~ needle end),
               "a planted #{family} (#{needle}) in #{path} must fail the scan, got #{inspect(hits)}"

        assert scan_retired(path, "#{text}\n.fine { color: var(--color-base-content); }") != []
      end
    end

    test "ordinary text is not a retired pattern" do
      clean = """
      .ops-card { color: var(--ops-text-muted); box-shadow: var(--shadow-ops-overlay); }
      <.ops_button variant={:primary}>Save</.ops_button>
      class="ops-muted text-base-content"
      topbar.config({barColors: {0: primary}})
      """

      assert scan_retired("scrypath_ops/lib/x.ex", clean) == []
    end

    test "a gradient is allowed only in the table scroller and the select chevron, up to their counts" do
      scroll =
        ".ops-table-scroll { background: linear-gradient(a, b), linear-gradient(c, d), radial-gradient(e, f), radial-gradient(g, h); }"

      chevron =
        "select.ops-form-control { background-image: linear-gradient(45deg, a, b), linear-gradient(135deg, c, d); }"

      css = "scrypath_ops/assets/css/app.css"

      assert scan_retired(css, scroll <> "\n" <> chevron) == []

      assert [{"gradient outside its allowed rule", ^css, ".card: 1 gradient function(s)" <> _}] =
               scan_retired(css, ".card { background: linear-gradient(a, b); }")

      assert [{_, ^css, ".ops-table-scroll: 5 gradient functions, at most 4"}] =
               scan_retired(
                 css,
                 String.replace(scroll, "}", "background: linear-gradient(i, j); }")
               )

      assert [{_, ^css, "select.ops-form-control: 3 gradient functions, at most 2"}] =
               scan_retired(
                 css,
                 String.replace(chevron, "}", "background: linear-gradient(i, j); }")
               )

      # a selector that merely contains an allowed name is not the allowed rule
      assert [{_, ^css, ".ops-table-scroll-extra: 1 gradient function(s)" <> _}] =
               scan_retired(css, ".ops-table-scroll-extra { background: linear-gradient(a, b); }")

      # comments that talk about gradients do not count; a gradient in code outside a stylesheet does
      assert scan_retired(css, "/* a linear-gradient(a, b) in prose */ .x { color: red; }") == []

      assert [{"gradient outside a stylesheet", "scrypath_ops/lib/x.ex", "gradient"}] =
               scan_retired("scrypath_ops/lib/x.ex", ~s(class="bg-gradient-to-r"))
    end
  end
end
