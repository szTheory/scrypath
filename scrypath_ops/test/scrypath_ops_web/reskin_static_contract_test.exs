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
  use ScrypathOpsWeb.ConnCase, async: true

  @ops_root Path.expand("../..", __DIR__)
  @app_css Path.join(@ops_root, "assets/css/app.css")
  @built_css Path.join(@ops_root, "priv/static/assets/css/app.css")
  @fonts_dir Path.join(@ops_root, "priv/static/assets/fonts")

  @font_files ~w(ui.woff2 mono.woff2)

  @font_url ~r/url\("(\.\.\/fonts\/([a-z]+\.woff2)\?v=([0-9a-f]{64}))"\)/

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
end
