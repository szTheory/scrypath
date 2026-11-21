defmodule Scrypath.ReadmeContractTest do
  # Deliberately untagged: README and owner-map drift fails the default `mix test` and the
  # `core` lane, following the backfill_contract_docs_test precedent. Plain file reads only (no
  # network, no docs build). Phase 192 Plan 04 adds the README tests to this module.
  use ExUnit.Case, async: true

  @owner_map ".planning/reference/CLAIM-OWNER-MAP.md"

  @required_claims ~w(
    what-it-is
    fit
    non-fit
    install-line
    sync-modes
    support-policy
    operator-ui-status
  )

  # The whole Owner cell, after trimming and removing surrounding backticks: exactly one owner.
  @owner_cell ~r/\A(README|website|retired|guide:[a-z0-9-]+|doc:[A-Za-z0-9_.\/-]+)\z/

  # One Pinned-by entry: backticked repo path, the word `has`, backticked token.
  @entry ~r/\A`([^`]+)`\s+has\s+`([^`]+)`\z/

  describe "claim owner map" do
    test "the claim owner map names exactly one owning surface for each required claim" do
      rows = owner_rows()
      extras = Scrypath.MixProject.project()[:docs][:extras]

      assert length(rows) >= 30,
             "the owner map has only #{length(rows)} rows; the table parse may have gone vacuous"

      ids = Enum.map(rows, & &1.id)
      assert ids == Enum.uniq(ids), "duplicate claim ids: #{inspect(ids -- Enum.uniq(ids))}"

      for id <- @required_claims do
        assert Enum.count(rows, &(&1.id == id)) == 1,
               "required claim #{id} must appear exactly once in the owner map"
      end

      for row <- rows do
        owner = String.trim(row.owner, "`")

        assert Regex.match?(@owner_cell, owner),
               "claim #{row.id}: owner cell #{inspect(row.owner)} must name exactly one owner " <>
                 "(README, guide:<slug>, doc:<path>, website or retired)"

        case owner do
          "guide:" <> slug ->
            assert "guides/#{slug}.md" in extras,
                   "claim #{row.id}: guide:#{slug} is not a docs extra in mix.exs"

          "doc:" <> path ->
            assert File.regular?(path), "claim #{row.id}: doc:#{path} does not exist"

          _other ->
            :ok
        end
      end

      assert String.contains?(section(File.read!(@owner_map), "## README budget"), "800"),
             "the README budget section does not record the 800-word cap"
    end

    test "every owner-map Pinned-by token is present in its named file" do
      for row <- owner_rows() do
        owner = String.trim(row.owner, "`")

        if owner == "retired" do
          assert Regex.match?(~r/\Areason:\s*\S/, row.pinned_by),
                 "claim #{row.id}: a retired row needs `reason:` and a reason in Pinned by"
        else
          entries = parse_entries(row)

          assert entries != [],
                 "claim #{row.id}: a non-retired row needs at least one Pinned-by entry"

          own = owner_file(owner)

          if own do
            assert Enum.any?(entries, fn {path, _token} -> path == own end),
                   "claim #{row.id}: no Pinned-by entry names the owner's own file #{own}"
          end

          for {path, token} <- entries do
            assert File.regular?(path),
                   "claim #{row.id}: Pinned-by path #{path} does not exist"

            assert String.contains?(File.read!(path), token),
                   "claim #{row.id}: #{path} no longer contains #{inspect(token)}"
          end
        end
      end
    end
  end

  # One map per table row: the seven cells by name, backticks on the id removed.
  defp owner_rows do
    @owner_map
    |> File.read!()
    |> section("## Owner map")
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "|"))
    |> Enum.map(&split_row/1)
    |> Enum.reject(fn [id | _] -> id == "Claim id" or Regex.match?(~r/\A[-: ]+\z/, id) end)
    |> Enum.map(fn cells ->
      assert length(cells) == 7,
             "owner-map row has #{length(cells)} cells, expected 7: #{inspect(cells)}"

      [id, claim, owner, readme, hexdocs, website, pinned_by] = cells

      %{
        id: String.trim(id, "`"),
        claim: claim,
        owner: owner,
        readme: readme,
        hexdocs: hexdocs,
        website: website,
        pinned_by: pinned_by
      }
    end)
  end

  defp split_row(line) do
    line
    |> String.trim()
    |> String.trim_leading("|")
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  defp parse_entries(row) do
    row.pinned_by
    |> String.split("; ")
    |> Enum.map(fn entry ->
      case Regex.run(@entry, String.trim(entry)) do
        [_all, path, token] ->
          {path, token}

        nil ->
          flunk("claim #{row.id}: Pinned-by entry #{inspect(entry)} must be `path` has `token`")
      end
    end)
  end

  defp owner_file("README"), do: "README.md"
  defp owner_file("guide:" <> slug), do: "guides/#{slug}.md"
  defp owner_file("doc:" <> path), do: path
  defp owner_file(_other), do: nil

  # Text between a level-2 heading and the next level-2 heading.
  defp section(text, heading) do
    case String.split(text, "\n" <> heading <> "\n", parts: 2) do
      [_before, rest] ->
        rest |> String.split(~r/^## /m, parts: 2) |> hd()

      _missing ->
        flunk("#{@owner_map} has no #{inspect(heading)} section")
    end
  end
end
