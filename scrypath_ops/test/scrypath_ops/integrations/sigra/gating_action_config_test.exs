defmodule ScrypathOps.Integrations.Sigra.GatingActionConfigTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Integrations.Sigra.Gating

  @reserved_prefixes ~w(auth. session. mfa. oauth. api. account. sigra.)

  test "__action_config__/0 stays on scrypath.ops.* and avoids reserved prefixes" do
    action_config = Gating.__action_config__()
    prefixes = Map.values(action_config)

    assert Enum.all?(prefixes, &String.starts_with?(&1, "scrypath.ops."))
    assert prefixes == Enum.uniq(prefixes)
    assert MapSet.disjoint?(MapSet.new(prefixes), MapSet.new(@reserved_prefixes))
  end
end
