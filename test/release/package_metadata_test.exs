defmodule Scrypath.Release.PackageMetadataTest do
  use ExUnit.Case, async: true

  alias Scrypath.MixProject

  test "project metadata exposes public package trust signals" do
    project = MixProject.project()

    assert project[:homepage_url] == "https://github.com/szTheory/scrypath"
    assert project[:source_url] == "https://github.com/szTheory/scrypath"
    assert project[:source_ref] == "v#{project[:version]}"
  end

  test "project directly requires telemetry and the approved Req range" do
    dependencies = MixProject.project()[:deps]

    dependency = fn app ->
      Enum.find_value(dependencies, fn
        {^app, requirement} -> {app, requirement, []}
        {^app, requirement, opts} -> {app, requirement, opts}
        _other -> nil
      end)
    end

    assert {:telemetry, "~> 1.0", telemetry_opts} = dependency.(:telemetry)
    refute Keyword.get(telemetry_opts, :optional, false)

    assert {:req, "~> 0.6.1 or ~> 0.7", req_opts} = dependency.(:req)
    refute Keyword.get(req_opts, :optional, false)

    assert {:oban, "~> 2.21", oban_opts} = dependency.(:oban)
    assert Keyword.get(oban_opts, :optional, false)
  end

  test "package metadata exposes links and release docs" do
    project = MixProject.project()
    package = project[:package]
    version = project[:version]
    source_ref = project[:source_ref]

    assert package[:licenses] == ["Apache-2.0"]
    assert "LICENSE" in package[:files]
    assert "SECURITY.md" in package[:files]
    assert "docs/releasing.md" in package[:files]
    refute "docs" in package[:files]

    assert package[:links] == %{
             "GitHub" => "https://github.com/szTheory/scrypath",
             "HexDocs" => "https://hexdocs.pm/scrypath/#{version}",
             "Changelog" =>
               "https://github.com/szTheory/scrypath/blob/#{source_ref}/CHANGELOG.md",
             "Guides" => "https://hexdocs.pm/scrypath/#{version}/readme.html"
           }
  end

  test "package file allowlist only targets root library surfaces" do
    package_files = MixProject.project()[:package][:files]

    assert "lib" in package_files
    assert "mix.exs" in package_files
    assert "README.md" in package_files
    assert "CHANGELOG.md" in package_files
    assert "guides" in package_files
    assert "docs/releasing.md" in package_files

    refute "scrypath_ops" in package_files
    refute "examples" in package_files
    refute "website" in package_files
    refute ".planning" in package_files
    refute "node_modules" in package_files
    refute "playwright-report" in package_files
    refute "test-results" in package_files
    refute "dev" in package_files
  end

  test "every root docs file is covered by the package allowlist" do
    package_files = MixProject.project()[:package][:files]

    root_docs =
      "docs/**/*"
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)

    assert root_docs != []

    for doc <- root_docs do
      assert doc in package_files,
             "#{doc} is checked by release parity but missing from package.files"
    end
  end

  test "docs metadata keeps release guide and version-aware source links" do
    project = MixProject.project()
    docs = project[:docs]

    assert docs[:source_url] == project[:source_url]
    assert docs[:source_ref] == project[:source_ref]
    assert "CONTRIBUTING.md" in docs[:extras]
    assert "docs/releasing.md" in docs[:extras]
    assert "guides/operator-mix-tasks.md" in docs[:extras]
    assert "docs/operator-support.md" in docs[:extras]
    assert "docs/search-backend-sre.md" in docs[:extras]
    assert "guides/overview.md" in docs[:extras]
    assert "guides/per-query-tuning-pipeline.md" in docs[:extras]
    assert "guides/telemetry.md" in docs[:extras]
    assert "guides/drift-recovery.md" in docs[:extras]

    assert docs[:groups_for_extras][:Operations] == [
             "ARCHITECTURE.md",
             "guides/drift-recovery.md",
             "guides/meilisearch-operations.md",
             "guides/operator-mix-tasks.md",
             "guides/relevance-tuning.md",
             "guides/per-query-tuning-pipeline.md",
             "guides/telemetry.md",
             "guides/sync-modes-and-visibility.md"
           ]

    assert docs[:groups_for_extras][:Maintainers] == [
             "CONTRIBUTING.md",
             "docs/releasing.md",
             "docs/operator-support.md",
             "docs/search-backend-sre.md",
             "docs/local-demo-docker-dx.md"
           ]
  end

  # ExDoc copies `logo` and `favicon` with `File.copy!/2`, which raises when the file is missing, and
  # a Hex consumer who runs `mix docs` on the unpacked tarball has no brand/ directory. So they are
  # listed only when the files exist. A subprocess evaluates the real mix.exs from a temporary
  # directory: changing the working directory of the test VM would race every other async test.
  test "docs config lists the logo and favicon only when the brand files exist" do
    elixir = System.find_executable("elixir") || flunk("elixir is not on the PATH")

    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath-mixexs-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)
    File.cp!("mix.exs", Path.join(dir, "mix.exs"))

    brand_files = [
      "brand/assets/logo/scrypath-symbol-light.svg",
      "brand/assets/icon/favicon-light.svg"
    ]

    probe = ~S"""
    Mix.start()
    Code.require_file("mix.exs")
    docs = Scrypath.MixProject.project()[:docs]
    IO.write(inspect(docs |> Keyword.take([:logo, :favicon]) |> Enum.sort()))
    """

    assert {"[]", 0} = System.cmd(elixir, ["-e", probe], cd: dir)

    for file <- brand_files do
      File.mkdir_p!(Path.dirname(Path.join(dir, file)))
      File.cp!(file, Path.join(dir, file))
    end

    assert {listed, 0} = System.cmd(elixir, ["-e", probe], cd: dir)

    assert listed ==
             inspect(
               favicon: "brand/assets/icon/favicon-light.svg",
               logo: "brand/assets/logo/scrypath-symbol-light.svg"
             )
  end
end

defmodule Scrypath.Release.BuiltDocsBrandTest do
  # Built-docs brand contract (BDOC-01, BDOC-02). It adds no gate: it runs in `core`, because this
  # file carries no tags, and inside `mix verify.package`, which runs the same file.
  #
  # One real docs build runs in `setup_all`. The output goes to `System.tmp_dir!()`, never to the
  # ExUnit per-test temporary-directory tag: that tag writes under the repository, where the
  # retired-identity deny-list scan reads untracked files. The retired directory name is built at
  # runtime, so this source never holds the literal.
  use ExUnit.Case, async: true

  alias Scrypath.MixProject

  @generator ~s(<meta name="generator" content="ExDoc v)
  @pinned_css "brand/assets/docs/scrypath-exdoc.css"
  @docs_css "dev/docs/scrypath-exdoc.css"
  # Rules the docs-owned stylesheet adds to the pinned rules, in file order. The derivation test
  # compares the whole file with the pin plus exactly these, so nothing else can be added silently.
  #
  # Contrast rule: ExDoc's own colors for these token classes were tuned for ExDoc's near-white code
  # background. On the brand code background (#F0E9E6) the operator, entity, label and delimiter
  # colors measure about 4:1 in light mode, and ExDoc's dark lexer-error pair is 2.3:1. They take the
  # brand text color instead (15.1:1 in light, 16.9:1 in dark). The contrast test below measures it.
  @contrast_classes ~w(o ni nl dl err)
  @contrast_rule @contrast_classes
                 |> Enum.flat_map(&["body .makeup .#{&1}", "body.dark .makeup .#{&1}"])
                 |> Enum.join(",")
                 |> Kernel.<>("{color:var(--scrypath-doc-text)}")
  # Logo rule: ExDoc takes a single logo, so dark mode swaps in the dark symbol.
  @dark_logo_rule ~S|body.dark .sidebar-projectImage img{content:url("../brand/assets/logo/scrypath-symbol-dark.svg")}|
  @additional_rules [@contrast_rule, @dark_logo_rule]
  # Token role to its custom property suffix, and the token classes each role colors, as in the book.
  @code_roles %{
    "background" => "--scrypath-doc-bg",
    "text" => "--scrypath-doc-text",
    "comment" => "--scrypath-doc-comment",
    "keyword" => "--scrypath-doc-keyword",
    "string" => "--scrypath-doc-string",
    "atom" => "--scrypath-doc-atom"
  }
  @class_roles %{
    "keyword" => ~w(k kd kn kp kr kt ow),
    "string" => ~w(s s1 s2 sa sb sc sd se sh si sx sr sl),
    "atom" => ~w(ss na no m mb mf mh mi mo il),
    "comment" => ~w(c c1 cm cs ch cp cpf),
    "text" => ~w(nf fm nc nn)
  }
  @exdoc_css "dist/html-elixir-"
  # WCAG AA for normal text. The measure uses the same sRGB formula as examples/scrypath_ecommerce/contrast-checker.mjs.
  @aa_ratio 4.5
  # The only named colors ExDoc's token rules use (`gh` and `gu`); anything else must be a hex value.
  @named_colors %{"navy" => "#000080", "purple" => "#800080"}
  @docs_link ~s(<link rel="stylesheet" href="assets/scrypath-exdoc.css">)
  @header_dark "brand/assets/readme/scrypath-header-dark.svg"
  @header_light "brand/assets/readme/scrypath-header-light.svg"
  @snippet "brand/assets/readme/header-snippet.html"
  # ExDoc's head template always loads `docs_config.js`, an optional file the hosting site supplies
  # for the version dropdown (the ExDoc docs call it optional). A local build never contains it, so
  # this one name is exempt from the resolution check. Nothing else is: the test asserts that the
  # unresolved references equal exactly this name.
  @host_supplied_ref "docs_config.js"
  # Binary build outputs are skipped in the text scans: they are not text and cannot name a path.
  @binary_exts ~w(.woff .woff2 .png .ico .jpg .jpeg .gif .webp)

  setup_all do
    # `System.unique_integer/1` is unique only inside one VM, and separate OS processes started the
    # same way draw near-identical values, so the process id keeps two overlapping runs apart.
    out =
      Path.join(
        System.tmp_dir!(),
        "scrypath-docs-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(out) end)

    ExUnit.CaptureIO.capture_io(fn ->
      Mix.Tasks.Docs.run(["--output", out, "--warnings-as-errors"])
    end)

    %{out: out}
  end

  test "readme.html carries the brand header paths, mirrored into the build", %{out: out} do
    readme = File.read!(Path.join(out, "readme.html"))

    assert readme =~ ~s(srcset="#{@header_dark}")
    assert readme =~ ~s(src="#{@header_light}")
  end

  test "every local image and script reference on every ExDoc page resolves inside the build", %{
    out: out
  } do
    pages = generated_pages(out)
    assert pages != [], "no ExDoc-generated page found in #{out}"

    refs =
      for page <- pages, ref <- local_refs(File.read!(page)) do
        {page, ref}
      end

    assert refs != [], "no local src or srcset reference found on any generated page"

    unexpected =
      for {page, ref} <- refs,
          ref != @host_supplied_ref,
          not resolves?(out, page, ref),
          do: {rel(out, page), ref}

    assert unexpected == []
  end

  test "README.md header paths are committed files and no README image points at the Pages site" do
    readme = File.read!("README.md")
    refs = local_refs(readme)

    assert @header_dark in refs
    assert @header_light in refs

    for ref <- refs do
      assert String.starts_with?(ref, "brand/assets/readme/"),
             "README reference #{ref} is outside brand/assets/readme/"

      assert File.regular?(ref), "README reference #{ref} is not a regular file"
      assert committed?(ref), "README reference #{ref} is not committed"
    end

    for value <- html_attribute_values(readme, ["src", "srcset"]) do
      refute value =~ "github.io", "README image points at the Pages site: #{value}"
    end
  end

  test "no text file in the build, and no epub entry, names the retired brand directory", %{
    out: out
  } do
    files =
      out |> Path.join("**/*") |> Path.wildcard(match_dot: true) |> Enum.filter(&File.regular?/1)

    # `.build.epub` is ExDoc's plain-text build manifest, not a zip: it stays in the text scan.
    {epubs, others} = Enum.split_with(files, &epub_archive?/1)
    assert epubs != [], "no epub in the build"

    for file <- others, not binary?(file) do
      refute File.read!(file) =~ retired_dir(), "#{rel(out, file)} names the retired directory"
    end

    for epub <- epubs do
      {:ok, entries} = :zip.extract(String.to_charlist(epub), [:memory])
      assert entries != []

      for {name, content} <- entries, not binary?(List.to_string(name)) do
        refute content =~ retired_dir(),
               "#{List.to_string(name)} in the epub names the retired directory"
      end
    end
  end

  test "README.md, PRODUCT.md and every docs extra are free of the retired brand directory name" do
    for file <- ["README.md", "PRODUCT.md" | MixProject.project()[:docs][:extras]] do
      refute File.read!(file) =~ retired_dir(), "#{file} names the retired directory"
    end
  end

  test "docs/releasing.md records the README header and HexDocs brand mechanics" do
    releasing = File.read!("docs/releasing.md")

    for anchor <- [
          "### README header and HexDocs brand assets",
          "brand/assets/readme",
          "raw.githubusercontent.com",
          "dev/docs/scrypath-exdoc.css",
          "brand/assets/docs/scrypath-exdoc.css"
        ] do
      assert releasing =~ anchor, "docs/releasing.md is missing #{inspect(anchor)}"
    end

    refute releasing =~ retired_dir()
  end

  test "the only non-ExDoc html with an unresolved local reference is the mirrored pinned snippet",
       %{out: out} do
    generated = MapSet.new(generated_pages(out))

    unresolved =
      out
      |> Path.join("**/*.html")
      |> Path.wildcard()
      |> Enum.reject(&MapSet.member?(generated, &1))
      |> Enum.filter(fn page ->
        page |> File.read!() |> local_refs() |> Enum.any?(&(not resolves?(out, page, &1)))
      end)
      |> Enum.map(&rel(out, &1))

    assert unresolved == [@snippet]
  end

  test "every content page links the favicon and the docs-owned stylesheet after ExDoc's CSS", %{
    out: out
  } do
    pages = generated_pages(out)
    content = content_pages(pages)
    redirects = pages -- content

    assert length(content) >= 50
    assert Path.join(out, "readme.html") in content

    for page <- content do
      html = File.read!(page)
      {exdoc_at, _} = :binary.match(html, @exdoc_css)

      assert html =~ ~s(<link rel="icon" href="assets/favicon.svg"),
             "#{rel(out, page)} has no brand favicon link"

      case :binary.match(html, @docs_link) do
        {docs_at, _} ->
          assert docs_at > exdoc_at, "#{rel(out, page)} links the docs stylesheet before ExDoc's"

        :nomatch ->
          flunk("#{rel(out, page)} does not link the docs-owned stylesheet")
      end
    end

    assert File.read!(Path.join(out, "readme.html")) =~ ~s(src="assets/logo.svg")

    # The exclusion cannot silently grow: the only generator-marked pages without ExDoc's
    # stylesheet are the meta-refresh redirects, and every refresh page is one of them.
    refresh = Enum.filter(pages, &(File.read!(&1) =~ ~s(http-equiv="refresh")))
    assert redirects != []
    assert Enum.sort(redirects) == Enum.sort(refresh)
  end

  test "the built favicon, logo and stylesheet are byte-equal to their sources", %{out: out} do
    assert File.read!(Path.join(out, "assets/favicon.svg")) ==
             File.read!("brand/assets/icon/favicon-light.svg")

    assert File.read!(Path.join(out, "assets/logo.svg")) ==
             File.read!("brand/assets/logo/scrypath-symbol-light.svg")

    assert File.read!(Path.join(out, "assets/scrypath-exdoc.css")) ==
             File.read!("dev/docs/scrypath-exdoc.css")
  end

  test "every url() in the docs-owned stylesheet resolves in the build to its pinned source", %{
    out: out
  } do
    urls =
      "dev/docs/scrypath-exdoc.css"
      |> File.read!()
      |> then(&Regex.scan(~r/url\(\s*["']?([^"')]+?)["']?\s*\)/, &1, capture: :all_but_first))
      |> List.flatten()

    assert urls != [], "the stylesheet has no url() to check"

    for url <- urls do
      built = Path.expand(url, Path.join(out, "assets"))
      source = Path.relative_to(built, out)

      assert String.starts_with?(source, "brand/assets/logo/"),
             "#{url} does not resolve into the mirrored brand logo directory"

      assert File.regular?(built), "#{url} does not resolve to a file in the build"
      assert File.read!(built) == File.read!(source), "#{url} differs from its pinned source"
    end
  end

  test "the head hook links the stylesheet for html only and stays private" do
    hook = MixProject.project()[:docs][:before_closing_head_tag]

    assert hook.(:html) == @docs_link
    assert hook.(:epub) == ""
    refute function_exported?(MixProject, :before_closing_head_tag, 1)
  end

  # Code-block colors are proven here by rule assertions, not pixels: the docs-owned stylesheet is
  # the pinned one with two fixes, its colors equal the brand tokens, and its selectors outrank
  # ExDoc's own code rules by computed specificity. A rendered browser check stays advisory.
  test "the docs-owned stylesheet has no operating-system dark block and no media rule" do
    raw = File.read!(@docs_css)

    refute raw =~ "prefers-color-scheme"
    refute raw =~ "@media"
  end

  test "every color or background rule is written once for body and once for body.dark" do
    painted = Enum.filter(docs_rules(), fn {_selectors, decls} -> paints?(decls) end)
    assert painted != []

    for {selectors, _decls} <- painted do
      by_base =
        selectors |> Enum.map(&split_body_prefix/1) |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))

      for {base, prefixes} <- by_base do
        assert Enum.sort(prefixes) == ["body ", "body.dark "],
               "#{base} is not written once for body and once for body.dark"
      end
    end
  end

  test "the docs-owned rules equal the rules derived from the pinned file plus the additional rules" do
    assert docs_rules() ==
             derive_docs_rules(File.read!(@pinned_css)) ++
               Enum.flat_map(@additional_rules, &parse_rules/1)
  end

  test "the code colors equal the brand tokens, light on :root and dark on body.dark" do
    root = custom_properties(docs_rules(), ":root")
    dark = custom_properties(docs_rules(), "body.dark")

    assert map_size(root) == map_size(@code_roles)
    assert map_size(dark) == map_size(@code_roles)

    for {role, property} <- @code_roles do
      assert String.downcase(root[property]) == token_hex(role, "light"), "#{role} light"
      assert String.downcase(dark[property]) == token_hex(role, "dark"), "#{role} dark"
    end
  end

  test "each token class maps to its color property, in both themes" do
    pinned =
      for {role, classes} <- @class_roles, class <- classes, into: %{} do
        {class, "var(--scrypath-doc-#{role})"}
      end

    # The contrast classes are the one named addition. They must stay disjoint from the pinned
    # classes, so the addition can never hide a changed mapping of a class the book colors.
    assert MapSet.disjoint?(MapSet.new(Map.keys(pinned)), MapSet.new(@contrast_classes))
    expected = Map.merge(pinned, Map.new(@contrast_classes, &{&1, "var(--scrypath-doc-text)"}))

    for prefix <- ["body .makeup .", "body.dark .makeup ."] do
      actual =
        for {selectors, decls} <- docs_rules(),
            selector <- selectors,
            String.starts_with?(selector, prefix),
            into: %{} do
          {String.replace_prefix(selector, prefix, ""), String.replace(decls, ~r/^color:|;$/, "")}
        end

      assert actual == expected,
             "classes under #{prefix} do not map as in the pinned file plus the contrast rule"
    end
  end

  test "the docs-owned selectors outrank ExDoc's competing code rules", %{out: out} do
    [exdoc_css] = Path.wildcard(Path.join(out, "dist/html-elixir-*.css"))
    exdoc = File.read!(exdoc_css)

    # The bug the stylesheet fixes must still exist in this ExDoc version. If ExDoc drops these
    # rules, re-check whether the docs-owned stylesheet still needs the body prefixes.
    assert exdoc =~ ".dark .makeup .kd"
    assert exdoc =~ ".dark .makeup{"
    assert exdoc =~ ".content-inner code{"

    selectors = Enum.flat_map(docs_rules(), fn {selectors, _decls} -> selectors end)
    assert "body.dark pre code.makeup" in selectors

    token_classes = Enum.filter(selectors, &String.contains?(&1, ".makeup ."))

    for selector <- token_classes do
      competing =
        if String.starts_with?(selector, "body.dark "),
          do: ".dark .makeup .kd",
          else: ".makeup .kd"

      assert specificity(selector) > specificity(competing),
             "#{selector} does not outrank #{competing}"
    end

    # The dark selector must beat ExDoc's dark text rule, the light one its light rule; both must
    # beat the inline-code background rule.
    for {selector, themed} <- [
          {"body.dark pre code.makeup", ".dark .makeup"},
          {"body pre code.makeup", ".makeup"}
        ] do
      assert selector in selectors

      for competing <- [themed, ".content-inner code"] do
        assert specificity(selector) > specificity(competing),
               "#{selector} does not outrank #{competing}"
      end
    end
  end

  # Contrast of the code colors that are left after the pinned rules. The pinned book colors only
  # some token classes, and ExDoc keeps its own color for every other class it paints, tuned for
  # ExDoc's near-white code background. For every token class that occurs in a built code block, plus
  # the classes the contrast rule recolors, this resolves the color the browser applies in each theme
  # from the built ExDoc CSS and the built docs-owned stylesheet, and requires AA against the code
  # background (or against the class's own background when ExDoc sets one).
  test "every token class used in the built docs has AA contrast on the code background, in both themes",
       %{out: out} do
    used = used_token_classes(out)

    for class <- ["k", "o", "p", "s"],
        do: assert(class in used, "no .#{class} token span found in any built code block")

    exdoc = exdoc_rules(out)
    docs = built_docs_rules(out)

    failures =
      for theme <- [:light, :dark],
          class <- Enum.uniq(used ++ @contrast_classes),
          {fg, bg, ratio} = token_contrast(class, theme, exdoc, docs),
          ratio < @aa_ratio,
          do: "#{theme} .#{class}: #{fg} on #{bg} is #{Float.round(ratio, 2)}:1"

    assert failures == [], "token colors below #{@aa_ratio}:1:\n" <> Enum.join(failures, "\n")
  end

  # Planted failure: the same check, run against the docs-owned stylesheet without its contrast
  # rule, must fail for the classes the rule exists for. This proves the check is able to fail.
  test "the contrast check fails when the contrast rule is missing", %{out: out} do
    exdoc = exdoc_rules(out)
    docs = built_docs_rules(out)

    planted =
      Enum.reject(docs, fn {selectors, _decls} -> "body .makeup .o" in selectors end)

    assert length(planted) == length(docs) - 1

    for {theme, class} <- [light: "o", light: "ni", light: "nl", light: "dl", dark: "err"] do
      {_fg, _bg, without} = token_contrast(class, theme, exdoc, planted)
      {_fg, _bg, with_rule} = token_contrast(class, theme, exdoc, docs)

      assert without < @aa_ratio, "#{theme} .#{class} is #{without}:1 without the rule"
      assert with_rule >= @aa_ratio, "#{theme} .#{class} is #{with_rule}:1 with the rule"
    end

    # The measure itself: black on white is 21:1, and the brand pair is the one the guide quotes.
    assert_in_delta contrast_ratio("#000000", "#ffffff"), 21.0, 0.001
    assert_in_delta contrast_ratio("#1e1220", "#f0e9e6"), 15.06, 0.01
  end

  defp docs_rules, do: @docs_css |> File.read!() |> strip_comments() |> parse_rules()

  defp exdoc_rules(out) do
    [css] = Path.wildcard(Path.join(out, "dist/html-elixir-*.css"))
    css |> File.read!() |> strip_comments() |> parse_rules()
  end

  defp built_docs_rules(out) do
    out
    |> Path.join("assets/scrypath-exdoc.css")
    |> File.read!()
    |> strip_comments()
    |> parse_rules()
  end

  # Every class on a token span inside a highlighted code block of any generated page.
  defp used_token_classes(out) do
    for page <- generated_pages(out),
        [block] <-
          Regex.scan(~r{<code class="makeup[^"]*"[^>]*>(.*?)</code>}s, File.read!(page),
            capture: :all_but_first
          ),
        [classes] <- Regex.scan(~r/<span class="([^"]+)"/, block, capture: :all_but_first),
        class <- String.split(classes),
        uniq: true,
        do: class
  end

  # {foreground, background, ratio} of a token span in a highlighted code block, in one theme.
  # The browser applies every rule whose selector matches, property by property, in ascending
  # specificity (ExDoc's sheet loads first, so it loses ties). A property no rule sets is inherited
  # from the docs-owned `pre code.makeup` rule: the brand text color and the brand code background.
  # Dark mode matches the light selectors too, because ExDoc's `.dark` rules sit on top of them.
  defp token_contrast(class, theme, exdoc, docs) do
    vars = cascade(docs, theme_selectors(theme, [":root"], ["body.dark"]))

    block =
      cascade(
        docs,
        theme_selectors(theme, ["body pre code.makeup"], ["body.dark pre code.makeup"])
      )

    token =
      cascade(
        exdoc ++ docs,
        theme_selectors(
          theme,
          [".makeup .#{class}", "body .makeup .#{class}"],
          [".dark .makeup .#{class}", "body.dark .makeup .#{class}"]
        )
      )

    fg = color_hex(token["color"] || block["color"], vars)
    bg = color_hex(token["background-color"] || block["background"], vars)
    {fg, bg, contrast_ratio(fg, bg)}
  end

  # The selector spellings that apply in a theme: the light ones always, the dark ones in dark only.
  defp theme_selectors(theme, light, dark), do: if(theme == :dark, do: light ++ dark, else: light)

  defp cascade(rules, selectors) do
    rules
    |> Enum.flat_map(fn {rule_selectors, decls} ->
      for selector <- rule_selectors, selector in selectors, do: {specificity(selector), decls}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.flat_map(&declarations(elem(&1, 1)))
    |> Map.new()
  end

  defp color_hex("var(" <> rest, vars) do
    rest |> String.trim_trailing(")") |> then(&Map.fetch!(vars, &1)) |> color_hex(vars)
  end

  defp color_hex("#" <> hex, _vars) when byte_size(hex) == 3,
    do: "#" <> Enum.map_join(String.graphemes(hex), &(&1 <> &1))

  defp color_hex("#" <> hex, _vars) when byte_size(hex) == 6, do: "#" <> hex

  defp color_hex(name, _vars) do
    Map.get(@named_colors, name) || flunk("cannot read the color #{inspect(name)}")
  end

  defp contrast_ratio(fg, bg) do
    [hi, lo] = Enum.sort([luminance(fg), luminance(bg)], :desc)
    (hi + 0.05) / (lo + 0.05)
  end

  defp luminance("#" <> hex) do
    [r, g, b] =
      for <<channel::binary-size(2) <- hex>> do
        channel |> String.to_integer(16) |> Kernel./(255) |> linear()
      end

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp linear(channel) when channel <= 0.04045, do: channel / 12.92
  defp linear(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)

  defp strip_comments(css), do: Regex.replace(~r{/\*.*?\*/}s, css, "")

  # Flat rules only: `selector,selector{declarations}`, whitespace normalized.
  defp parse_rules(css) do
    for [_whole, selectors, decls] <- Regex.scan(~r/([^{}]+)\{([^{}]*)\}/, css) do
      {selectors |> String.split(",") |> Enum.map(&String.trim/1),
       decls |> String.replace(~r/\s+/, " ") |> String.trim()}
    end
  end

  # The derivation of the docs-owned file from the pin: drop every media block that follows the
  # operating-system color setting, keep custom-property rules, and write every other rule's
  # selectors once for `body ` and once for `body.dark `.
  defp derive_docs_rules(pinned) do
    pinned
    |> strip_comments()
    |> then(
      &Regex.replace(
        ~r/@media[^{]*prefers-color-scheme[^{]*\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}/,
        &1,
        ""
      )
    )
    |> parse_rules()
    |> Enum.map(fn {selectors, decls} ->
      if custom_only?(decls) do
        {selectors, decls}
      else
        {for(s <- selectors, prefix <- ["body ", "body.dark "], do: prefix <> s), decls}
      end
    end)
  end

  defp declarations(decls) do
    for declaration <- String.split(decls, ";", trim: true),
        [property, value] = String.split(declaration, ":", parts: 2),
        do: {String.trim(property), String.trim(value)}
  end

  defp custom_only?(decls),
    do: Enum.all?(declarations(decls), &String.starts_with?(elem(&1, 0), "--"))

  defp paints?(decls) do
    Enum.any?(declarations(decls), &(elem(&1, 0) in ["color", "background", "background-color"]))
  end

  defp custom_properties(rules, selector) do
    [decls] = for {[^selector], decls} <- rules, do: decls
    Map.new(declarations(decls))
  end

  defp split_body_prefix("body.dark " <> base), do: {"body.dark ", base}
  defp split_body_prefix("body " <> base), do: {"body ", base}
  defp split_body_prefix(other), do: flunk("selector #{inspect(other)} has no body prefix")

  defp token_hex(role, theme) do
    "brand/tokens.json"
    |> File.read!()
    |> Jason.decode!()
    |> get_in(["color", "code", "#{role}-#{theme}", "$value", "hex"])
    |> String.downcase()
  end

  # Specificity of a descendant-only selector as {ids, classes, elements}; tuples compare
  # left to right, which is how CSS ranks them.
  defp specificity(selector) do
    selector
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reduce({0, 0, 0}, fn compound, {ids, classes, elements} ->
      {ids + count(~r/#[\w-]+/, compound), classes + count(~r/\.[\w-]+/, compound),
       elements + count(~r/^[a-zA-Z][\w-]*/, compound)}
    end)
  end

  defp count(regex, string), do: regex |> Regex.scan(string) |> length()

  defp content_pages(pages), do: Enum.filter(pages, &(File.read!(&1) =~ @exdoc_css))

  defp retired_dir, do: "brand" <> "book/"

  defp rel(out, path), do: Path.relative_to(path, out)

  defp epub_archive?(path) do
    String.ends_with?(path, ".epub") and not String.starts_with?(Path.basename(path), ".")
  end

  defp binary?(path), do: Path.extname(path) in @binary_exts

  defp generated_pages(out) do
    out
    |> Path.join("**/*.html")
    |> Path.wildcard()
    |> Enum.filter(&(File.read!(&1) =~ @generator))
  end

  defp html_attribute_values(html, names) do
    for name <- names,
        [value] <- Regex.scan(~r/\s#{name}="([^"]*)"/, html, capture: :all_but_first),
        do: value
  end

  # Every `src` value and every comma-separated `srcset` candidate (its first whitespace token)
  # that names a local file, without any query or fragment suffix.
  defp local_refs(html) do
    srcs = html_attribute_values(html, ["src"])

    candidates =
      for value <- html_attribute_values(html, ["srcset"]),
          candidate <- String.split(value, ","),
          token = candidate |> String.trim() |> String.split(~r/\s+/, parts: 2) |> hd(),
          do: token

    (srcs ++ candidates)
    |> Enum.reject(&(&1 == "" or external?(&1)))
    |> Enum.map(&(&1 |> String.split(["?", "#"], parts: 2) |> hd()))
    |> Enum.reject(&(&1 == ""))
  end

  defp external?(ref) do
    String.starts_with?(ref, ["http://", "https://", "//", "data:", "mailto:", "#"])
  end

  defp resolves?(out, page, ref) do
    path = Path.expand(ref, Path.dirname(page))
    String.starts_with?(path, out <> "/") and File.regular?(path)
  end

  defp committed?(path) do
    match?(
      {_, 0},
      System.cmd("git", ["ls-files", "--error-unmatch", "--", path], stderr_to_stdout: true)
    )
  end
end
