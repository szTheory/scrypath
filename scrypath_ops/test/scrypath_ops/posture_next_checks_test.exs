defmodule ScrypathOps.PostureNextChecksTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Posture

  # The guide lives at the repository root, one level above scrypath_ops/. A path that
  # resolved under scrypath_ops/guides/ silently dropped the CLI hint for every operator.
  @guide Path.expand("../../../guides/operator-mix-tasks.md", __DIR__)

  test "the operator mix guide the posture hint reads exists and documents the status task" do
    assert File.exists?(@guide)
    assert File.read!(@guide) =~ "mix scrypath.status"
  end

  for state <- [:ok, :degraded] do
    test "#{state} next checks include the CLI snapshot hint" do
      checks = Posture.next_checks(unquote(state), "/admin/search")

      assert Enum.any?(checks, &(Map.get(&1, :mix) == "mix scrypath.status"))
    end
  end

  test "missing backend next checks do not claim a CLI snapshot" do
    refute Enum.any?(
             Posture.next_checks(:missing_backend, "/admin/search"),
             &Map.has_key?(&1, :mix)
           )
  end
end
