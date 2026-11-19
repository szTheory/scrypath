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
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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
              {"Hanken Grotesk Fallback", "local(\"Arial\")",
               %{
                 "size-adjust" => "101.7%",
                 "ascent-override" => "98.3%",
                 "descent-override" => "29.8%",
                 "line-gap-override" => "0%"
               }},
              {"Sometype Mono Fallback", "local(\"Courier New\")",
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
end
