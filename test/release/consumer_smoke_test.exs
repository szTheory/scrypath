defmodule Scrypath.Release.ConsumerSmokeTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject

  test "a clean consumer app compiles the documented use Scrypath path" do
    _version = MixProject.project()[:version]

    flunk("consumer smoke harness not implemented yet")
  end

  test "the smoke dependency stays release-like and never falls back to path deps" do
    version = MixProject.project()[:version]
    tag = "v#{version}"

    deps = consumer_deps("file:///tmp/scrypath-artifact", tag)

    assert deps =~ ~s|{:scrypath, git: "file:///tmp/scrypath-artifact", tag: "#{tag}"}|
    refute deps =~ "path:"
  end

  defp consumer_deps(artifact_git_url, tag) do
    """
    [
      {:ecto, "~> 3.13"},
      {:scrypath, git: "#{artifact_git_url}", tag: "#{tag}"}
    ]
    """
  end
end
