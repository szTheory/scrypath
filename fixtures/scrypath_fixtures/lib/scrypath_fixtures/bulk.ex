defmodule ScrypathFixtures.Bulk do
  @moduledoc """
  Deterministic bulk records for the ordinary states of the three fictional adopters. The data is
  fictional and for development and tests only: plausible product, shipment and wiki-page records
  built from small word lists written for this project, with no name or id copied from anywhere
  else.

  There is no random source and no dependency. A record is a pure function of `{kind, seed, n}`:

      pick(list, seed, n, tag) = Enum.at(list, :erlang.phash2({seed, n, tag}, length(list)))

  so the same inputs give the same record on every machine and every run. `rows/3` is capped at
  5,000 records: a larger count belongs in a label ("5,000+ shipments"), not in memory.

  ## The golden digest

  `:erlang.phash2/2` is documented as portable, but the project does not rely on that alone. A
  fixed sample (the first 50 records of each kind at seed 196) is hashed with SHA-256 over the
  deterministic external term format, and `golden_digest/0` holds the expected value. The digest is
  over the picked output, so any change to a word list, a pick, a field or the hash itself shows up
  as `{:bulk_digest, got}` from `ScrypathFixtures.Check`.

  Updating the digest is a deliberate act. If an OTP upgrade changes it, print
  `ScrypathFixtures.Bulk.sample/0` before and after (with the old OTP and the new one), read the
  difference, and only then paste the new `sample_digest/0` into `@golden_digest`. Never update it
  just to make the check pass.
  """

  @max_rows 5_000
  @sample_seed 196
  @sample_size 50

  # SHA-256 (lowercase hex) of `:erlang.term_to_binary(sample(), [:deterministic, {:minor_version, 2}])`.
  # Computed once on OTP 28.5; see the moduledoc before changing it.
  @golden_digest "406f51bd66d2d8a669f0bbff11c0b4543f30281dcf31a5b4aae5671339e429c4"

  @product_adjectives ~w(Compact Sturdy Foldable Quiet Portable Stackable Weatherproof Lightweight Reversible Adjustable)
  @product_materials ~w(Walnut Steel Linen Ceramic Bamboo Canvas Copper Oak Felt Glass)
  @product_items ~w(desk-lamp planter shelf kettle backpack cushion stool trivet notebook thermos)
  @product_stores ~w(north-store harbor-store hills-store lake-store)
  @product_statuses ~w(active active active active draft archived)
  @product_prices [799, 1_299, 1_899, 2_499, 3_299, 4_999, 6_450, 8_900]

  @shipment_ports [
    "Rotterdam",
    "Hamburg",
    "Antwerp",
    "Gdansk",
    "Valencia",
    "Genoa",
    "Felixstowe",
    "Le Havre",
    "Piraeus",
    "Gothenburg"
  ]
  @shipment_carriers [
    "Northwind Freight (fictional)",
    "Kestrel Lines (fictional)",
    "Harbor and Pine Logistics (fictional)",
    "Tallow Road Haulage (fictional)",
    "Bluebell Cargo (fictional)"
  ]
  @shipment_statuses ~w(booked picked_up in_transit in_transit in_transit customs delivered)

  @page_topics ~w(Onboarding Runbook Glossary Retrospective Roadmap Handbook Checklist Archive Playbook Standup)
  @page_kinds ~w(notes guide overview index template summary)
  @page_spaces ~w(engineering support operations people)

  @kinds [:product, :shipment, :page]

  @doc "The most records `rows/3` returns."
  @spec max_rows() :: pos_integer()
  def max_rows, do: @max_rows

  @doc """
  One element of `list`, chosen from `{seed, n, tag}`. The same arguments always give the same
  element. `tag` separates fields of one record so they do not all move together.
  """
  @spec pick([term(), ...], integer(), integer(), atom()) :: term()
  def pick([_ | _] = list, seed, n, tag) when is_integer(seed) and is_integer(n) and is_atom(tag),
    do: Enum.at(list, :erlang.phash2({seed, n, tag}, length(list)))

  @doc """
  The `count` records of `kind` (`:product`, `:shipment` or `:page`) for `seed`, numbered from 1.

  Raises `ArgumentError` for a `count` above 5,000 and `FunctionClauseError` for another kind.
  """
  @spec rows(:product | :shipment | :page, integer(), non_neg_integer()) :: [map()]
  def rows(kind, seed, count) when kind in @kinds and is_integer(seed) and is_integer(count) do
    if count < 0 or count > @max_rows do
      raise ArgumentError,
            "Bulk.rows/3 returns 0 to #{@max_rows} records, got #{count}; " <>
              "a bigger set belongs in a label, not in memory"
    end

    for n <- 1..count//1, do: row(kind, seed, n)
  end

  @doc "The one record `rows/3` returns at position `n` (from 1)."
  @spec row(:product | :shipment | :page, integer(), pos_integer()) :: map()
  def row(:product, seed, n) when is_integer(seed) and is_integer(n) and n >= 1 do
    %{
      id: "SPD-#{1_000 + n}",
      title:
        "#{pick(@product_adjectives, seed, n, :adjective)} " <>
          "#{pick(@product_materials, seed, n, :material)} " <>
          "#{@product_items |> pick(seed, n, :item) |> String.replace("-", " ")} (fictional)",
      status: pick(@product_statuses, seed, n, :status),
      storeId: pick(@product_stores, seed, n, :store),
      price_cents: pick(@product_prices, seed, n, :price)
    }
  end

  def row(:shipment, seed, n) when is_integer(seed) and is_integer(n) and n >= 1 do
    origin = pick(@shipment_ports, seed, n, :origin)
    destination = @shipment_ports |> List.delete(origin) |> pick(seed, n, :destination)

    %{
      id: "LSH-#{1_000 + n}",
      reference: "REF-#{1_000 + n}",
      lane: "#{origin} to #{destination}",
      carrier: pick(@shipment_carriers, seed, n, :carrier),
      status: pick(@shipment_statuses, seed, n, :status)
    }
  end

  def row(:page, seed, n) when is_integer(seed) and is_integer(n) and n >= 1 do
    topic = pick(@page_topics, seed, n, :topic)
    kind = pick(@page_kinds, seed, n, :kind)
    space = pick(@page_spaces, seed, n, :space)

    %{
      id: "WKP-#{1_000 + n}",
      title: "#{topic} #{kind} (fictional)",
      slug: String.downcase("#{topic}-#{kind}-#{n}"),
      excerpt: "#{topic} #{kind} for the #{space} space (fictional)",
      space: space
    }
  end

  @doc """
  The fixed sample the golden digest covers: the first 50 records of each kind at seed 196, as a
  keyword list in the order `:product`, `:shipment`, `:page`.
  """
  @spec sample() :: [{:product | :shipment | :page, [map()]}]
  def sample, do: for(kind <- @kinds, do: {kind, rows(kind, @sample_seed, @sample_size)})

  @doc "Lowercase hex SHA-256 of `term` in the deterministic external term format."
  @spec digest(term()) :: String.t()
  def digest(term) do
    :sha256
    |> :crypto.hash(:erlang.term_to_binary(term, [:deterministic, {:minor_version, 2}]))
    |> Base.encode16(case: :lower)
  end

  @doc "The digest of `sample/0` as it is today."
  @spec sample_digest() :: String.t()
  def sample_digest, do: digest(sample())

  @doc "The digest `sample_digest/0` must equal. Updated by hand, never to make a check pass."
  @spec golden_digest() :: String.t()
  def golden_digest, do: @golden_digest
end
