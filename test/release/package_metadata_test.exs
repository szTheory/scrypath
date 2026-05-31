defmodule Scrypath.Release.PackageMetadataTest do
  use ExUnit.Case, async: true

  alias Scrypath.MixProject

  test "project metadata exposes public package trust signals" do
    project = MixProject.project()

    assert project[:homepage_url] == "https://github.com/szTheory/scrypath"
    assert project[:source_url] == "https://github.com/szTheory/scrypath"
    assert project[:source_ref] == "v#{project[:version]}"
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
    assert "guides/drift-recovery.md" in docs[:extras]

    assert docs[:groups_for_extras][:Operations] == [
             "ARCHITECTURE.md",
             "guides/drift-recovery.md",
             "guides/meilisearch-operations.md",
             "guides/operator-mix-tasks.md",
             "guides/relevance-tuning.md",
             "guides/per-query-tuning-pipeline.md",
             "guides/sync-modes-and-visibility.md"
           ]

    assert docs[:groups_for_extras][:Maintainers] == [
             "CONTRIBUTING.md",
             "docs/releasing.md",
             "docs/operator-support.md",
             "docs/search-backend-sre.md"
           ]
  end
end
