defmodule ScrypathOps.Catalog.Stories.Primitives.OpsButton do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_button/1
  def container, do: :iframe

  # Three variants: `:default` (outline), `:primary` (the one Plum button per scope) and `:ghost`.
  # A static render cannot hover, so the hover variations set `data-ops-state="hover"`, which the
  # stylesheet treats as `:hover`. Disabled is the real `disabled` attribute; it is one variation
  # because default and primary share one disabled look.
  def variations do
    [
      %Variation{id: :default, slots: ["Retry"]},
      %Variation{id: :default_hover, attributes: %{"data-ops-state": "hover"}, slots: ["Retry"]},
      %Variation{id: :primary, attributes: %{variant: :primary}, slots: ["Retry failed work"]},
      %Variation{
        id: :primary_hover,
        attributes: %{variant: :primary, "data-ops-state": "hover"},
        slots: ["Retry failed work"]
      },
      %Variation{
        id: :disabled,
        description:
          "Disabled looks the same for default and primary: the outline, muted text, no Plum fill.",
        attributes: %{variant: :primary, disabled: true},
        slots: ["Retry failed work"]
      },
      %Variation{id: :ghost, attributes: %{variant: :ghost}, slots: ["Dismiss"]}
    ]
  end
end
