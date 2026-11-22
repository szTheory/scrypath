defmodule Scrypath.Release.PackageMetadataTest do
  use ExUnit.Case, async: true

  alias Scrypath.MixProject

  @fixtures_tree "fixtures/scrypath_fixtures"

  # The HexDocs sidebar contract (DOCS-01): six job-named groups in this order, each listing its pages
  # in this order. ExDoc names a group by its keyword key, sorts groups by the keyword order, and
  # sorts the pages inside a group by their position in `extras`. It warns about none of the mistakes
  # `docs_group_problems/3` looks for: an extra in no group, in two groups, or a group entry that
  # names no extra all build clean, so these tests are the only guard.
  @sidebar_groups [
    {"Getting started",
     [
       "README.md",
       "guides/golden-path.md",
       "guides/getting-started.md",
       "guides/overview.md",
       "guides/meilisearch-concepts.md"
     ]},
    {"Guides by task",
     [
       "guides/jtbd-and-user-flows.md",
       "guides/request-edge-search.md",
       "guides/composing-real-app-search.md",
       "guides/related-data-and-reindexing.md",
       "guides/multitenancy.md",
       "guides/common-mistakes.md"
     ]},
    {"Phoenix",
     [
       "guides/phoenix-walkthrough.md",
       "guides/phoenix-contexts.md",
       "guides/phoenix-controllers-and-json.md",
       "guides/phoenix-liveview.md",
       "guides/faceted-search-with-phoenix-liveview.md",
       "guides/multi-index-search.md"
     ]},
    {"Operate and recover",
     [
       "guides/sync-modes-and-visibility.md",
       "guides/drift-recovery.md",
       "guides/meilisearch-operations.md",
       "guides/operator-mix-tasks.md",
       "guides/relevance-tuning.md",
       "guides/per-query-tuning-pipeline.md",
       "guides/telemetry.md",
       "ARCHITECTURE.md"
     ]},
    {"Project policy",
     [
       "guides/support-and-compatibility.md",
       "guides/scope-and-reopen-policy.md",
       "guides/outside-adopter-intake.md"
     ]},
    {"Maintainers",
     [
       "CONTRIBUTING.md",
       "docs/releasing.md",
       "docs/operator-support.md",
       "docs/search-backend-sre.md",
       "docs/local-demo-docker-dx.md"
     ]}
  ]
  # The first sidebar group is the short start page list; a longer one stops being a start list.
  @first_group_cap 5

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
    refute "fixtures" in package_files
    refute "storybook" in package_files
  end

  # fixtures/ never ships (ADR 0002). The literal refutes above go vacuous if the directory is
  # renamed or an entry such as "." pulls it in, so this test first proves the tree exists (the
  # positive control) and then that no `files:` entry reaches it. `package_contents_test` needs no
  # change for the new top-level directory: its `allowed_top_level` is derived from the first
  # segments of `files:`, so `fixtures` can never be allowed (v1.49 Phase 196 research N8).
  test "the fixtures project exists and no package entry reaches it" do
    assert File.dir?("fixtures/scrypath_fixtures"),
           "fixtures/scrypath_fixtures is gone: update @fixtures_tree and the package_files refutes"

    assert fixtures_reaching_entries(MixProject.project()[:package][:files]) == []
  end

  test "fixtures_reaching_entries/1 names exactly the entry that reaches the fixtures tree" do
    real_files = MixProject.project()[:package][:files]
    assert fixtures_reaching_entries(real_files) == []

    for offending <- [
          ".",
          "fixtures",
          "fixtures/",
          "fixtures/scrypath_fixtures",
          "fixtures/scrypath_fixtures/lib",
          "fix*"
        ] do
      assert fixtures_reaching_entries(real_files ++ [offending]) == [offending],
             "expected #{inspect(offending)} to be reported as reaching #{@fixtures_tree}"
    end

    # Near misses stay clean, so the check cannot pass by flagging every entry.
    assert fixtures_reaching_entries(["fixtures_notes.md", "fixturesx", "lib/fixtures"]) == []
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

    # The old `Operations` group is now `"Operate and recover"`: the same eight pages. List order is
    # pinned by the extras-order test below, because it does not drive rendering; the members do.
    assert Enum.sort(docs[:groups_for_extras][:"Operate and recover"]) == [
             "ARCHITECTURE.md",
             "guides/drift-recovery.md",
             "guides/meilisearch-operations.md",
             "guides/operator-mix-tasks.md",
             "guides/per-query-tuning-pipeline.md",
             "guides/relevance-tuning.md",
             "guides/sync-modes-and-visibility.md",
             "guides/telemetry.md"
           ]

    assert docs[:groups_for_extras][:Maintainers] == [
             "CONTRIBUTING.md",
             "docs/releasing.md",
             "docs/operator-support.md",
             "docs/search-backend-sre.md",
             "docs/local-demo-docker-dx.md"
           ]
  end

  test "the sidebar groups are the six job-named groups in order" do
    groups = docs_groups()

    # The one place the count "six" is pinned; the tests below derive from `@sidebar_groups`.
    assert length(@sidebar_groups) == 6
    assert Enum.map(groups, &elem(&1, 0)) == Enum.map(@sidebar_groups, &elem(&1, 0))

    for {{name, members}, {name, expected}} <- Enum.zip(groups, @sidebar_groups) do
      assert members == expected, "group #{inspect(name)} lists the wrong pages"
    end
  end

  test "every docs extra is in exactly one sidebar group" do
    docs = MixProject.project()[:docs]
    groups = docs_groups()

    assert docs_group_problems(docs[:extras], groups, @first_group_cap) == []

    # Floors, so a config read that stopped seeing the real lists cannot pass an empty check. The
    # group count and the first group come from `@sidebar_groups`, which the test above pins to the
    # config, so adding or moving a guide is one edit there and in mix.exs.
    assert length(docs[:extras]) >= 33
    assert length(groups) == length(@sidebar_groups)

    assert [{"Getting started", expected_first} | _] = @sidebar_groups
    assert {"Getting started", first_group} = hd(groups)
    assert first_group == expected_first
    assert first_group != []

    assert length(first_group) <= @first_group_cap
  end

  # ExDoc keeps the `extras` order inside a group, so a group list that disagrees with `extras`
  # would claim a sidebar order the build does not render.
  test "each group lists its pages in extras order" do
    extras = MixProject.project()[:docs][:extras]

    for {name, members} <- docs_groups() do
      assert Enum.filter(extras, &(&1 in members)) == members,
             "group #{inspect(name)} lists its pages in a different order than `extras`"
    end
  end

  test "the group check reports a missing, duplicated, dangling or oversized-first-group entry" do
    extras = ["README.md", "guides/a.md", "guides/b.md", "guides/c.md"]
    groups = [One: ["README.md", "guides/a.md"], Two: ["guides/b.md", "guides/c.md"]]

    # Control: the keyword shape ExDoc reads, atom keys included, is clean.
    assert docs_group_problems(extras, groups, 5) == []

    # An extra in no group.
    assert docs_group_problems(extras, [One: groups[:One], Two: ["guides/b.md"]], 5) ==
             [{:missing_from_groups, "guides/c.md"}]

    # A path in two groups.
    assert docs_group_problems(
             extras,
             [One: groups[:One], Two: ["guides/a.md", "guides/b.md", "guides/c.md"]],
             5
           ) == [{:in_several_groups, "guides/a.md"}]

    # A group entry that names no extra.
    assert docs_group_problems(
             extras,
             [One: groups[:One], Two: groups[:Two] ++ ["guides/gone.md"]],
             5
           ) == [{:dangling_member, "guides/gone.md"}]

    # A first group over the cap.
    six = for n <- 1..6, do: "guides/p#{n}.md"
    assert docs_group_problems(six, [First: six], 5) == [{:first_group_too_long, {"First", 6}}]
    assert docs_group_problems(six, [First: six], 6) == []

    # A member that is not a path (a regex pattern); the built-sidebar test covers real patterns.
    pattern = ~r/guides\/x/

    assert docs_group_problems(extras, [One: groups[:One], Two: groups[:Two] ++ [pattern]], 5) ==
             [{:non_string_member, {"Two", pattern}}]

    # Two members swapped against the `extras` order.
    assert docs_group_problems(
             extras,
             [One: groups[:One], Two: ["guides/c.md", "guides/b.md"]],
             5
           ) ==
             [
               {:extras_order,
                {"Two", ["guides/b.md", "guides/c.md"], ["guides/c.md", "guides/b.md"]}}
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

  # The `files:` entries that reach the fixtures tree: "." (the whole repository), the tree itself,
  # a parent directory of it ("fixtures", "fixtures/"), something below it, or a glob that expands
  # to any of those. `[]` is a package that keeps the fixtures project out.
  defp fixtures_reaching_entries(entries), do: Enum.filter(entries, &reaches_fixtures?/1)

  defp reaches_fixtures?(entry) do
    entry = entry |> String.trim_trailing("/")

    cond do
      entry == "." ->
        true

      String.contains?(entry, ["*", "?", "[", "{"]) ->
        entry |> Path.wildcard() |> Enum.any?(&reaches_fixtures?/1)

      true ->
        entry == @fixtures_tree or String.starts_with?(@fixtures_tree, entry <> "/") or
          String.starts_with?(entry, @fixtures_tree <> "/")
    end
  end

  # The configured groups as `{name, members}` with the name as a string, which is how ExDoc reads
  # a keyword key (`to_string/1`).
  defp docs_groups do
    for {name, members} <- MixProject.project()[:docs][:groups_for_extras],
        do: {to_string(name), members}
  end

  # The mistakes ExDoc builds clean around in a `groups_for_extras` config, as `{kind, detail}`.
  # `[]` is a clean config. Each mistake is reported once, under its own kind:
  #
  #   * `:missing_from_groups` - an extra no group lists (it would render under an unnamed group)
  #   * `:in_several_groups`   - a path two groups list (the first group wins, silently)
  #   * `:dangling_member`     - a group entry that is not an extra (silently ignored)
  #   * `:first_group_too_long`- the first group has more than `first_group_cap` entries
  #   * `:non_string_member`   - a group entry that is not a path string, such as a regex; the
  #     built-sidebar test covers real patterns, this check reads paths only
  #   * `:extras_order`        - a group's list differs from the order `extras` gives its pages,
  #     which is the order ExDoc renders them in
  defp docs_group_problems(extras, groups, first_group_cap) do
    groups = for {name, members} <- groups, do: {to_string(name), members}
    paths = for {_name, members} <- groups, member <- members, is_binary(member), do: member
    counts = Enum.frequencies(paths)

    for(extra <- extras, not is_map_key(counts, extra), do: {:missing_from_groups, extra}) ++
      for(path <- Enum.uniq(paths), counts[path] > 1, do: {:in_several_groups, path}) ++
      for(path <- Enum.uniq(paths), path not in extras, do: {:dangling_member, path}) ++
      first_group_problem(groups, first_group_cap) ++
      for(
        {name, members} <- groups,
        member <- members,
        not is_binary(member),
        do: {:non_string_member, {name, member}}
      ) ++
      Enum.flat_map(groups, fn {name, members} -> group_order_problem(extras, name, members) end)
  end

  defp first_group_problem([{name, members} | _], cap) when length(members) > cap,
    do: [{:first_group_too_long, {name, length(members)}}]

  defp first_group_problem(_groups, _cap), do: []

  # Compares only the entries that are real extras, so a dangling or non-path entry is reported once,
  # under its own kind, and not again as an order problem.
  defp group_order_problem(extras, name, members) do
    listed = members |> Enum.filter(&(is_binary(&1) and &1 in extras)) |> Enum.uniq()
    rendered = Enum.filter(extras, &(&1 in listed))

    if rendered == listed, do: [], else: [{:extras_order, {name, rendered, listed}}]
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
  # The README header uses absolute, commit-pinned raw URLs: hex.pm renders the README through
  # readme.hex.pm, which only serves tarball files for relative paths, and `brand/` is not packaged.
  @header_pin "8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1"
  @header_base "https://raw.githubusercontent.com/szTheory/scrypath/#{@header_pin}/"
  @header_dark_path "brand/assets/readme/scrypath-header-dark.svg"
  @header_light_path "brand/assets/readme/scrypath-header-light.svg"
  @header_dark @header_base <> @header_dark_path
  @header_light @header_base <> @header_light_path
  @snippet "brand/assets/readme/header-snippet.html"
  # ExDoc's head template always loads `docs_config.js`, an optional file the hosting site supplies
  # for the version dropdown (the ExDoc docs call it optional). A local build never contains it, so
  # this one name is exempt from the resolution check. Nothing else is: the test asserts that the
  # unresolved references equal exactly this name.
  @host_supplied_ref "docs_config.js"
  # Binary build outputs are skipped in the text scans: they are not text and cannot name a path.
  @binary_exts ~w(.woff .woff2 .png .ico .jpg .jpeg .gif .webp)
  # Link scan (TRUTH-03). A href that leaves the build is not checked here: web links, protocol
  # relative links, mail links and data URIs. Nothing else is skipped, and there is no ignore list.
  # The one web link that is checked is an unversioned HexDocs link to one of this project's own
  # pages, `@own_docs_href`: the README links every guide that way, and a rename of a function or a
  # heading would leave its fragment dead with nothing else noticing.
  @external_href ~r{^(?:https?:|//|mailto:|data:)}i
  @own_docs_href ~r{^https://hexdocs\.pm/scrypath/([^/]+\.html(?:[?#].*)?)$}
  # The author content of an extras page: ExDoc renders the markdown inside
  # `<main class="content page-extra" id="main" data-type="extras">`, so everything before it
  # (head, sidebar) and after it (footer) is chrome and is never scanned. Module pages carry
  # `data-type="modules"` and legitimately link to themselves (ExDoc autolinks a module name
  # inside its own docs), so they are out of scope.
  @extras_region ~r{<main\b[^>]*\bdata-type="extras"[^>]*>(.*?)</main>}s
  # An `<a>` tag's href. `<link>` tags (stylesheets, icons) are not `<a>` tags.
  @anchor_href ~r{<a\s(?:[^>]*\s)?href="([^"]*)"}
  # Non-vacuity floor for the built-docs link scan: the number of `<a>` hrefs read from the author
  # content of the extras pages (1,360 on the build when this was set). Lower it only with a
  # reason, never to make a scan that stopped reading ExDoc's markup pass.
  @min_author_hrefs 500

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

  test "readme.html carries the commit-pinned brand header URLs", %{out: out} do
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

  # TRUTH-03. `mix docs --warnings-as-errors` passes while an extras page links a repository file
  # the build never wrote, or an anchor that does not exist, so the build's own output is scanned.
  # The scan reads the one build made in `setup_all`; it starts no second docs run.
  test "extras pages have no self-link, unresolved link or dead anchor", %{out: out} do
    pages = extras_pages(out)
    missing = missing_extra_pages(MixProject.project()[:docs][:extras], pages)
    assert missing == [], "no built extras page for: #{Enum.join(missing, ", ")}"

    scanned = for page <- pages, do: {page, File.read!(Path.join(out, page))}
    hrefs = Enum.sum(for {_page, html} <- scanned, do: length(author_hrefs(html)))

    # The build reads about 1,360 hrefs today; a floor of one would pass a markup change that
    # left a single match, so this one sits well under the real count and well over a stray hit.
    assert hrefs > @min_author_hrefs, "the href scan went vacuous: #{hrefs} hrefs"

    # The README links its guides by absolute HexDocs URL (7 own-docs links on the build when this
    # was set, 2 with a fragment), so the own-docs read must see some.
    own_docs =
      for {_page, html} <- scanned,
          href <- author_hrefs(html),
          Regex.match?(@own_docs_href, href),
          do: href

    assert length(own_docs) >= 4,
           "the own-docs HexDocs link check went vacuous: #{length(own_docs)} links"

    problems = Enum.flat_map(scanned, fn {page, html} -> link_problems(out, page, html) end)

    assert problems == [],
           "#{length(problems)} broken link(s) in the built extras pages:\n" <>
             Enum.map_join(problems, "\n", fn {page, href, kind} ->
               "  #{page} -> #{href} (#{inspect(kind)})"
             end)
  end

  test "a configured extra with no built page is reported by name" do
    extras = ["README.md", "guides/golden-path.md", "docs/releasing.md", "CONTRIBUTING.md"]

    # `404.html` and `api-reference.html` carry the extras marker too, so a page count cannot
    # tell a missing extra from these two.
    pages = [
      "readme.html",
      "golden-path.html",
      "contributing.html",
      "404.html",
      "api-reference.html"
    ]

    assert missing_extra_pages(extras, pages) == ["docs/releasing.md"]
    assert missing_extra_pages(extras, ["404.html" | pages]) == ["docs/releasing.md"]
    assert missing_extra_pages(extras, ["releasing.html" | pages]) == []
  end

  test "the link scan reports a planted self-link, unresolved link and dead anchor", %{out: out} do
    readme = File.read!(Path.join(out, "readme.html"))
    golden = File.read!(Path.join(out, "golden-path.html"))
    [_, real_anchor] = Regex.run(~r/<h2 id="([^"]+)"/, golden)

    planted = fn href -> plant(out, "readme.html", readme, href) end

    # The three kinds, planted inside the scanned region.
    assert planted.("readme.html") == [{"readme.html", "readme.html", :self_link}]
    assert planted.("no-such-page.html") == [{"readme.html", "no-such-page.html", :unresolved}]

    assert planted.("golden-path.html#no-such-anchor") ==
             [{"readme.html", "golden-path.html#no-such-anchor", :dead_anchor}]

    # A link that leaves the build is unresolved and is never opened.
    assert planted.("../readme.html") == [{"readme.html", "../readme.html", :unresolved}]

    # Controls: another page, a real anchor and a web link are not problems.
    assert planted.("golden-path.html") == []
    assert planted.("golden-path.html##{real_anchor}") == []
    assert planted.("https://example.com/missing") == []

    # An unversioned HexDocs link to this project's own pages is read as the page in the build,
    # so its fragment and its page are checked too; another project's page is not.
    own = "https://hexdocs.pm/scrypath/"

    assert planted.(own <> "golden-path.html#no-such-anchor") ==
             [{"readme.html", own <> "golden-path.html#no-such-anchor", :dead_anchor}]

    assert planted.(own <> "no-such-page.html") ==
             [{"readme.html", own <> "no-such-page.html", :unresolved}]

    assert planted.(own <> "readme.html") == [{"readme.html", own <> "readme.html", :self_link}]
    assert planted.(own <> "golden-path.html") == []
    assert planted.(own <> "golden-path.html##{real_anchor}") == []
    assert planted.("https://hexdocs.pm/other/golden-path.html#no-such-anchor") == []

    # The same self-link after `</main>` is chrome, outside the scanned region.
    [content, chrome] = String.split(readme, "</main>", parts: 2)
    outside = content <> "</main>" <> ~s(<a href="readme.html">x</a>) <> chrome

    assert link_problems(out, "readme.html", outside) -- link_problems(out, "readme.html", readme) ==
             []

    # A `<link>` tag is not an `<a>` tag.
    assert plant(out, "readme.html", readme, "no-such.css", "link") == []

    # A page without the extras region is a failure to scan, not a pass.
    assert_raise ExUnit.AssertionError, fn ->
      link_problems(out, "readme.html", "<main data-type=\"modules\"></main>")
    end
  end

  # DOCS-01. ExDoc builds clean with an extra in no group, in two groups, or with a group entry that
  # names no extra, so the sidebar it actually rendered is read from the build `setup_all` made. This
  # starts no second docs run.
  test "the built sidebar renders every extra under its configured group in order", %{out: out} do
    docs = MixProject.project()[:docs]
    groups = for {name, members} <- docs[:groups_for_extras], do: {to_string(name), members}
    entries = built_sidebar_extras(out)

    assert sidebar_group_problems(entries, groups) == []

    # Floors, so a payload parse that stopped reading ExDoc's output fails instead of passing empty.
    assert length(entries) >= length(docs[:extras])
    rendered_groups = entries |> Enum.map(& &1["group"]) |> Enum.uniq()

    for {name, _members} <- groups do
      assert name in rendered_groups, "the built sidebar has no group #{inspect(name)}"
    end

    start_ids = for %{"group" => "Getting started", "id" => id} <- entries, do: id
    assert Enum.take(start_ids, 2) == ["readme", "golden-path"]
  end

  test "the sidebar check reports an ungrouped, misgrouped, misordered or unrendered extra" do
    groups = [
      {"Start", ["README.md", "guides/golden-path.md", "guides/getting-started.md"]},
      {"Phoenix", ["guides/phoenix-walkthrough.md"]}
    ]

    entries = [
      %{"id" => "api-reference", "group" => ""},
      %{"id" => "readme", "group" => "Start"},
      %{"id" => "golden-path", "group" => "Start"},
      %{"id" => "getting-started", "group" => "Start"},
      %{"id" => "phoenix-walkthrough", "group" => "Phoenix"}
    ]

    # Control: the API reference is the one page ExDoc leaves without a group.
    assert sidebar_group_problems(entries, groups) == []

    golden = %{"id" => "golden-path", "group" => "Start"}

    replace_golden = fn replacement ->
      Enum.map(entries, &if(&1 == golden, do: replacement, else: &1))
    end

    # An extra moved to the unnamed group.
    assert sidebar_group_problems(replace_golden.(%{golden | "group" => ""}), groups) ==
             [{:ungrouped, "golden-path"}]

    # An extra under another configured group.
    assert sidebar_group_problems(replace_golden.(%{golden | "group" => "Phoenix"}), groups) ==
             [{:wrong_group, "golden-path", "Phoenix", "Start"}]

    # An extra the build did not render.
    assert sidebar_group_problems(List.delete(entries, golden), groups) ==
             [{:unrendered, "golden-path"}]

    # Two extras swapped inside a group.
    [api, readme, golden, started, phoenix] = entries

    assert sidebar_group_problems([api, readme, started, golden, phoenix], groups) ==
             [
               {:order, "Start", ["readme", "getting-started", "golden-path"],
                ["readme", "golden-path", "getting-started"]}
             ]
  end

  test "README.md header uses commit-pinned raw URLs whose bytes match the committed files" do
    readme = File.read!("README.md")

    values = html_attribute_values(readme, ["src", "srcset"])
    assert @header_dark in values
    assert @header_light in values

    for value <- values do
      refute value =~ "github.io", "README image points at the Pages site: #{value}"

      assert value =~
               ~r/^https:\/\/raw\.githubusercontent\.com\/szTheory\/scrypath\/[0-9a-f]{40}\/brand\/assets\/readme\//,
             "README image #{value} is not a commit-pinned raw URL under brand/assets/readme/"
    end

    # The pinned commit must be on this history, and the bytes at that commit must equal the files
    # the repository ships now, so a brand update that changes a header also has to move the pin.
    # A shallow checkout (the `package` job) may not contain the commit; the full-history jobs
    # (`core`, `repository-contracts`) still run these checks. A full clone must always have it.
    present? =
      match?(
        {_, 0},
        System.cmd("git", ["cat-file", "-e", "#{@header_pin}^{commit}"], stderr_to_stdout: true)
      )

    {shallow, 0} = System.cmd("git", ["rev-parse", "--is-shallow-repository"])

    if present? or String.trim(shallow) != "true" do
      assert match?(
               {_, 0},
               System.cmd("git", ["merge-base", "--is-ancestor", @header_pin, "HEAD"],
                 stderr_to_stdout: true
               )
             ),
             "README header pin #{@header_pin} is not an ancestor of HEAD"

      for path <- [@header_dark_path, @header_light_path] do
        {pinned, 0} = System.cmd("git", ["show", "#{@header_pin}:#{path}"])
        assert pinned == File.read!(path), "#{path} differs from its bytes at #{@header_pin}"
      end
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

  # Extras pages of the build, as paths relative to it. A page is an extras page when it says so.
  defp extras_pages(out) do
    out
    |> Path.join("**/*.html")
    |> Path.wildcard()
    |> Enum.filter(&(File.read!(&1) =~ ~s(data-type="extras")))
    |> Enum.map(&rel(out, &1))
    |> Enum.sort()
  end

  # The configured extras that have no built page of their own. ExDoc names the page after the
  # file's base name, lowercased.
  defp missing_extra_pages(extras, pages) do
    Enum.reject(extras, fn extra ->
      ((extra |> Path.basename(Path.extname(extra)) |> String.downcase()) <> ".html") in pages
    end)
  end

  # The author content of an extras page. A page that says it is an extras page but has no such
  # region is a failure to scan, never a pass.
  defp author_content(html) do
    case Regex.run(@extras_region, html, capture: :all_but_first) do
      [content] -> content
      nil -> flunk("the page has no `<main ... data-type=\"extras\">` region to scan")
    end
  end

  defp author_hrefs(html) do
    @anchor_href |> Regex.scan(author_content(html), capture: :all_but_first) |> List.flatten()
  end

  # Link problems of one extras page, as `{page, href, kind}`. `page` is the file name relative to
  # the build, `html` its text (the page itself is not read from disk, so a caller can scan a
  # changed copy). Kinds: `:self_link` (a link to the page itself, no fragment), `:unresolved` (the
  # target is not a file in the build, or leaves the build), `:dead_anchor` (the target page has no
  # element with the fragment as its id).
  defp link_problems(out, page, html) do
    for href <- author_hrefs(html),
        target = build_target(href),
        kind = href_problem(out, page, html, target),
        do: {page, href, kind}
  end

  # What a href means inside the build, or nil when it leaves the build and is not checked. An
  # own-docs HexDocs link (`https://hexdocs.pm/scrypath/<page>.html#<fragment>`) is read as the
  # page of that name in this build. HexDocs serves the last published version, so this holds the
  # link to the pages about to be published: a fragment on a function or heading added since the
  # last release is found here and would only be dead on HexDocs until the release.
  defp build_target(href) do
    case Regex.run(@own_docs_href, href, capture: :all_but_first) do
      [local] -> local
      nil -> if Regex.match?(@external_href, href), do: nil, else: href
    end
  end

  defp href_problem(out, page, html, href) do
    {path, fragment} = split_href(href)
    here = Path.join(out, page)
    target = if path == "", do: here, else: Path.expand(path, Path.dirname(here))

    cond do
      not String.starts_with?(target, out <> "/") -> :unresolved
      not File.regular?(target) -> :unresolved
      target == here and fragment == "" -> :self_link
      fragment != "" and not anchor?(page_text(target, here, html), fragment) -> :dead_anchor
      true -> nil
    end
  end

  defp split_href(href) do
    [before_fragment | fragment] = String.split(href, "#", parts: 2)
    {before_fragment |> String.split("?", parts: 2) |> hd(), List.first(fragment, "")}
  end

  # The page being scanned is read from the caller's text, any other page from the build.
  defp page_text(here, here, html), do: html
  defp page_text(target, _here, _html), do: File.read!(target)

  defp anchor?(html, fragment), do: Regex.match?(~r/\sid="#{Regex.escape(fragment)}"/, html)

  # The problems a snippet adds to a page: the problems of the page with the snippet inserted just
  # before `</main>` (inside the scanned region), less the problems the page already has.
  defp plant(out, page, html, href, tag \\ "a") do
    snippet =
      case tag do
        "a" -> ~s(<a href="#{href}">x</a>)
        "link" -> ~s(<link rel="stylesheet" href="#{href}">)
      end

    [content, chrome] = String.split(html, "</main>", parts: 2)
    planted = content <> snippet <> "</main>" <> chrome
    link_problems(out, page, planted) -- link_problems(out, page, html)
  end

  # The `"extras"` list of the sidebar payload ExDoc wrote, in payload order: one map per page with
  # `"id"`, `"title"` and `"group"`. The file is `dist/sidebar_items-<hash>.js`, which holds
  # `sidebarNodes=` followed by JSON.
  defp built_sidebar_extras(out) do
    with [file] <- Path.wildcard(Path.join(out, "dist/sidebar_items-*.js")),
         [_head, json] <- file |> File.read!() |> String.split("sidebarNodes=", parts: 2) do
      json
      |> String.trim()
      |> String.trim_trailing(";")
      |> Jason.decode!()
      |> Map.fetch!("extras")
    else
      other ->
        flunk(
          "expected exactly one readable dist/sidebar_items-*.js in the build, got " <>
            inspect(other, limit: 3, printable_limit: 80)
        )
    end
  end

  # An extra's id in the sidebar and in its page name: the file name without `.md`, runs of
  # non-word characters turned into `-`, trimmed and downcased (`ExDoc.Utils.text_to_id/1`).
  defp extra_id(path) do
    path
    |> Path.basename(".md")
    |> String.replace(~r/\W+/u, "-")
    |> String.trim("-")
    |> String.downcase()
  end

  # The problems between the sidebar ExDoc rendered (`entries`, from `built_sidebar_extras/1`) and
  # the configured groups, as tuples. Each problem is reported once, under its own kind:
  #
  #   * `{:unrendered, id}`              - a configured extra has no sidebar entry
  #   * `{:ungrouped, id}`               - an entry sits in the unnamed group; only the API
  #     reference may
  #   * `{:wrong_group, id, got, want}`  - an entry sits under another named group
  #   * `{:order, group, got_ids, want_ids}` - the ids of a group, in payload order, differ from the
  #     configured order (compared over the ids the group actually rendered, so a missing or
  #     misgrouped extra is not reported twice)
  #
  # Path members only: the config-shape test rejects any other member.
  defp sidebar_group_problems(entries, groups) do
    groups = for {name, members} <- groups, do: {to_string(name), members}
    rendered = Map.new(entries, &{&1["id"], &1["group"]})

    configured =
      for {group, members} <- groups,
          path <- members,
          is_binary(path),
          do: {group, extra_id(path)}

    for({_group, id} <- configured, not is_map_key(rendered, id), do: {:unrendered, id}) ++
      for(
        %{"id" => id, "group" => ""} <- entries,
        id != "api-reference",
        do: {:ungrouped, id}
      ) ++
      for(
        {group, id} <- configured,
        got = rendered[id],
        got not in ["", group],
        do: {:wrong_group, id, got, group}
      ) ++
      Enum.flat_map(groups, fn {group, members} ->
        sidebar_order_problem(entries, group, members)
      end)
  end

  defp sidebar_order_problem(entries, group, members) do
    configured = for member <- members, is_binary(member), do: extra_id(member)
    got = for %{"id" => id, "group" => ^group} <- entries, id in configured, do: id
    want = Enum.filter(configured, &(&1 in got))

    if got == want, do: [], else: [{:order, group, got, want}]
  end
end
