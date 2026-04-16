defmodule Scrypath.Release.PackageMetadataTest do
  use ExUnit.Case, async: true

  alias Scrypath.MixProject

  test "project metadata exposes public package trust signals" do
    project = MixProject.project()

    assert project[:homepage_url] == "https://github.com/jon/scrypath"
    assert project[:source_url] == "https://github.com/jon/scrypath"
    assert project[:source_ref] == "v#{project[:version]}"
  end

  test "package metadata exposes links and release docs" do
    package = MixProject.project()[:package]

    assert package[:licenses] == ["Apache-2.0"]
    assert "docs" in package[:files]

    assert package[:links] == %{
             "GitHub" => "https://github.com/jon/scrypath",
             "HexDocs" => "https://hexdocs.pm/scrypath",
             "Changelog" => "https://github.com/jon/scrypath/blob/main/CHANGELOG.md",
             "Guides" => "https://hexdocs.pm/scrypath/readme.html"
           }
  end

  test "docs metadata keeps release guide and version-aware source links" do
    project = MixProject.project()
    docs = project[:docs]

    assert docs[:source_url] == project[:source_url]
    assert docs[:source_ref] == project[:source_ref]
    assert "docs/releasing.md" in docs[:extras]
    assert docs[:groups_for_extras][:Maintainers] == ["docs/releasing.md"]
  end
end
