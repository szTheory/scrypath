defmodule ScrypathFixtures.Hostile do
  @moduledoc """
  Named stress strings for the operator UI: right-to-left overrides, invisible characters, two
  spellings of one letter, non-Latin scripts, over-long identifiers and markup. They are for
  development and tests only, and they are never ordinary records: only a stress scenario uses
  them (`ScrypathFixtures.Shopadelic` `:hostile_ids`).

  Every non-ASCII character in this file is an Elixir `\\u{...}` escape and no raw bidirectional
  control, zero-width character or byte-order mark is ever typed into source. The check
  (`ScrypathFixtures.Check`) fails on one anywhere in this project, because such a character can
  make source read differently from what it runs (the "Trojan Source" class).

  Where a string may go is decided by what Meilisearch and Scrypath can actually carry, not by what
  would look dramatic:

    * Meilisearch accepts a document id only if it is made of `a-z A-Z 0-9`, `-` and `_` and is at
      most 511 bytes. Any other id makes the task fail with `invalid_document_id`, and the failed
      task echoes the id exactly as sent. So the invalid-character strings and `id_512/0` appear
      only inside that echo.
    * `id_511/0` and `token_200/0` are valid ids, so they may appear as `document_ids` in a job's
      args.
    * A `missing_document_id` failure echoes the whole document, so markup and non-Latin text can
      appear inside one.
  """

  @doc "A right-to-left override in the middle of a word (U+202E)."
  @spec bidi_override() :: String.t()
  def bidi_override, do: "item\u{202E}2041"

  @doc "Left-to-right, right-to-left and first-strong isolates, each closed (U+2066 to U+2069)."
  @spec bidi_isolates() :: String.t()
  def bidi_isolates, do: "\u{2066}item\u{2069}\u{2067}2041\u{2069}\u{2068}x\u{2069}"

  @doc "A family emoji: four people joined by zero-width joiners (U+200D)."
  @spec zwj_family() :: String.t()
  def zwj_family, do: "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"

  @doc "A zero-width space inside a word (U+200B): invisible, and part of the identifier."
  @spec zero_width_space() :: String.t()
  def zero_width_space, do: "item\u{200B}2041"

  @doc "\"cafe\" with the accent as one precomposed letter (U+00E9)."
  @spec nfc() :: String.t()
  def nfc, do: "caf\u{00E9}"

  @doc "\"cafe\" with the accent as a base letter plus a combining acute (U+0301). Differs from `nfc/0` in bytes, not on screen."
  @spec nfd() :: String.t()
  def nfd, do: "cafe\u{0301}"

  @doc "Four Han characters (a label that means \"cargo label\")."
  @spec cjk() :: String.t()
  def cjk, do: "\u{8D27}\u{7269}\u{6807}\u{7B7E}"

  @doc "Four Arabic letters (the word for \"shipment\"), written right to left."
  @spec arabic() :: String.t()
  def arabic, do: "\u{0634}\u{062D}\u{0646}\u{0629}"

  @doc "A valid document id of exactly 511 bytes: the longest Meilisearch accepts."
  @spec id_511() :: String.t()
  def id_511, do: "SPD-" <> String.duplicate("a", 507)

  @doc "A document id of 512 bytes: one over the limit, so Meilisearch rejects it."
  @spec id_512() :: String.t()
  def id_512, do: "SPD-" <> String.duplicate("a", 508)

  @doc """
  An unbroken 200-character token with no whitespace, hyphen or other place a line may break. Only
  letters and digits, so it is also a valid document id.
  """
  @spec token_200() :: String.t()
  def token_200, do: "SPD2041A" |> String.duplicate(26) |> String.slice(0, 200)

  @doc "Markup as text: a script element with an alert call. It must render as text, never run."
  @spec markup() :: String.t()
  def markup, do: "<script>alert(1)</script>"

  @doc "Every string, as `{name, value}` pairs in the order of the functions above."
  @spec all() :: [{atom(), String.t()}]
  def all do
    [
      bidi_override: bidi_override(),
      bidi_isolates: bidi_isolates(),
      zwj_family: zwj_family(),
      zero_width_space: zero_width_space(),
      nfc: nfc(),
      nfd: nfd(),
      cjk: cjk(),
      arabic: arabic(),
      id_511: id_511(),
      id_512: id_512(),
      token_200: token_200(),
      markup: markup()
    ]
  end
end
