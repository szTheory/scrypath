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
  # The one rule the docs-owned stylesheet adds to the pinned rules: ExDoc takes a single logo,
  # so dark mode swaps in the dark symbol.
  @dark_logo_rule ~S|body.dark .sidebar-projectImage img{content:url("../brand/assets/logo/scrypath-symbol-dark.svg")}|
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
    out = Path.join(System.tmp_dir!(), "scrypath-docs-#{System.unique_integer([:positive])}")
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

  test "the docs-owned rules equal the rules derived from the pinned file plus the dark-logo rule" do
    assert docs_rules() ==
             derive_docs_rules(File.read!(@pinned_css)) ++ parse_rules(@dark_logo_rule)
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
    expected =
      for {role, classes} <- @class_roles, class <- classes, into: %{} do
        {class, "var(--scrypath-doc-#{role})"}
      end

    for prefix <- ["body .makeup .", "body.dark .makeup ."] do
      actual =
        for {selectors, decls} <- docs_rules(),
            selector <- selectors,
            String.starts_with?(selector, prefix),
            into: %{} do
          {String.replace_prefix(selector, prefix, ""), String.replace(decls, ~r/^color:|;$/, "")}
        end

      assert actual == expected, "classes under #{prefix} do not map as in the pinned file"
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

  defp docs_rules, do: @docs_css |> File.read!() |> strip_comments() |> parse_rules()

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
