defmodule ScrypathOpsWeb.OpsUiTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias ScrypathOpsWeb.OpsUi

  test "uses full-precision boundaries for relative age and absolute UTC" do
    reference = ~U[2026-10-06 12:00:00Z]

    for {seconds, expected} <- [
          {59, "just now"},
          {60, "1 min ago"},
          {3_599, "59 mins ago"},
          {3_600, "1 hr ago"},
          {86_399, "23 hrs ago"},
          {86_400, "1 day ago"},
          {604_799, "6 days ago"},
          {604_800, "Sep 29, 2026 at 12:00 UTC"}
        ] do
      datetime = DateTime.add(reference, -seconds, :second)
      html = render_time(datetime, reference)
      assert html =~ expected, "expected #{seconds}s old value to render #{expected}"
    end

    future = DateTime.add(reference, 1, :microsecond)
    future_html = render_time(future, reference)
    assert future_html =~ "After this check"
    assert future_html =~ "Oct 06, 2026 at 12:00 UTC"
    assert future_html =~ "2026-10-06T12:00:00.000001Z"
  end

  test "shows distinct no-success, missing-time, and unavailable meanings without copy controls" do
    reference = %{observed_at: ~U[2026-10-06 12:00:00Z]}

    for empty <- ["No success observed", "Success time not observed", "Not observed"] do
      html =
        render_component(&OpsUi.ops_time/1, time_assigns(nil, reference, empty: empty))

      assert html =~ empty
      refute html =~ "<details"
      refute html =~ "ops-time__copy"
    end

    unavailable =
      render_component(
        &OpsUi.ops_time/1,
        time_assigns(nil, reference, empty: "Not observed", unavailable_reason: ":timeout")
      )

    assert unavailable =~ ":timeout"
  end

  test "discloses unchanged source ISO and its UTC equivalent" do
    source_iso = "2026-10-04T13:02:05.123456-04:00"
    {:ok, datetime, _offset} = DateTime.from_iso8601(source_iso)
    html = render_time(datetime, ~U[2026-10-06 17:18:42.318Z], source_iso: source_iso)

    assert html =~ source_iso
    assert html =~ "2026-10-04T17:02:05.123456Z"
    assert html =~ "<summary>Exact timestamp</summary>"
  end

  defp render_time(datetime, reference, extra \\ []) do
    render_component(
      &OpsUi.ops_time/1,
      time_assigns(datetime, %{observed_at: reference}, extra)
    )
  end

  defp time_assigns(datetime, reference, extra) do
    Map.merge(
      %{
        dt: datetime,
        label: "Last success",
        copy: false,
        source_iso: nil,
        reference: reference,
        empty: "No success observed",
        unavailable_reason: nil,
        class: nil
      },
      Map.new(extra)
    )
  end
end
