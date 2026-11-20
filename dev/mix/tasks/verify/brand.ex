defmodule Mix.Tasks.Verify.Brand do
  # A real moduledoc (not `false`): the tooling-boundary test in
  # test/release/package_contents_test.exs pins which Verify* modules are hidden
  # from `mix help`, and this verifier is meant to stay discoverable.
  @moduledoc """
  Offline, merge-blocking check that the committed brand assets are exactly the
  pinned ones. It never touches the network; the online re-download check lives
  only in the brand update task.

  This task can only trust `brand/brand.pin.json`: a change that edits an asset
  and its pin entry together passes it. The contract test
  (`test/mix/tasks/brand_pin_contract_test.exs`) owns two constants that the pin
  must match, the archive hash and a digest of the per-asset hashes, so that
  change needs a second, reviewed edit in a different file. See
  `Mix.Tasks.Brand.Update` for the trade-off.
  """
  use Mix.Task

  @shortdoc "Verifies the committed brand assets against brand/brand.pin.json (offline)"

  alias Mix.Tasks.Brand.Update

  @pin_schema "scrypath.brand-pin.v1"
  @allowed_extensions ~w(.md .json .svg .png .ico .css .html .woff2 .txt)
  @max_total_bytes 400_000
  @scanned_extensions ~w(.svg .css .html)
  @fragment_only_extensions ~w(.svg .css)
  @hex64 ~r/\A[0-9a-f]{64}\z/

  # Active content refused in vendored SVG, CSS and HTML (T-186-04). This is a
  # deny-list, so every pattern is a flat regex without nested quantifiers (linear
  # time on adversarial whitespace; `\s*["']?\s*` is avoided because the two
  # whitespace runs split quadratically) and runs over the decoded text twice: as
  # written and with CSS escapes resolved, so `@\69mport` is seen. The vendored
  # files are plain (SVG uses `svg` and `path` only), so a refresh that needs any
  # of this is a decision for a maintainer, not something to scan around.
  @active_content [
    {~r/<script/i, "script element"},
    {~r/j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i, "javascript: URL"},
    {~r/[\s\/"']on[a-z]+\s*=/i, "event handler attribute"},
    {~r/<foreignobject/i, "foreignObject element"},
    {~r/<iframe/i, "iframe element"},
    {~r/@import/i, "@import rule"},
    {~r/url\([\s"']*(?:http|\/\/)/i, "remote url()"},
    {~r/(?:xlink:)?(?:href|src|srcset)\s*=[\s"']*(?:http|\/\/)/i, "remote href"},
    {~r/<\s*(?:set|animate(?:transform|motion)?)\b/i, "SMIL animation element"},
    {~r/[(="']\s*data\s*:/i, "data: URI"},
    {~r/&#|&(?:colon|tab|newline|sol|bsol|lpar|rpar);/i, "character reference"}
  ]

  # SVG and CSS here carry no external references at all, so a reference must point
  # inside the file. (HTML is exempt: the README snippet links its sibling files.)
  @fragment_only [
    {~r/(?:xlink:)?href\s*=[\s"']*[^#\s"'>]/i, "reference outside the file"},
    {~r/url\([\s"']*[^#\s"')]/i, "reference outside the file"}
  ]

  @impl true
  def run([]) do
    root = Path.dirname(Mix.Project.project_file())
    {count, bytes} = verify_tree!(root)
    Mix.shell().info("verify.brand: ok (#{count} assets, #{bytes} bytes)")
  end

  def run(args),
    do: Mix.raise("verify.brand does not accept arguments: #{Enum.join(args, " ")}")

  @doc false
  def check!(root) do
    verify_tree!(root)
    :ok
  end

  defp verify_tree!(root) do
    pin = read_pin!(root)
    assets = pin_assets!(pin)

    Enum.each(assets, &check_pinned_path!/1)
    check_total_size!(assets)
    check_allowlist!(assets)
    Enum.each(assets, &check_asset!(root, &1))
    check_closed_directories!(root, assets)

    {length(assets), assets |> Enum.map(& &1["size"]) |> Enum.sum()}
  end

  defp read_pin!(root) do
    path = Update.pin_path()

    with {:ok, contents} <- File.read(Path.join(root, path)),
         {:ok, %{} = pin} <- Jason.decode(contents) do
      validate_pin_header!(pin, path)
      pin
    else
      _error -> fail!("pin unreadable", path)
    end
  end

  defp validate_pin_header!(pin, path) do
    zip_sha256 = get_in(pin, ["source", "zip_sha256"])

    cond do
      pin["schema"] != @pin_schema ->
        fail!("pin schema invalid", path)

      not (is_binary(zip_sha256) and zip_sha256 =~ @hex64) ->
        fail!("pin zip sha256 invalid", path)

      pin["owned_directories"] != Update.owned_directories() ->
        fail!("pin owned directories differ", path)

      true ->
        :ok
    end
  end

  defp pin_assets!(pin) do
    case pin["assets"] do
      [_ | _] = assets ->
        Enum.each(assets, &check_asset_shape!/1)
        assets

      _other ->
        fail!("pin assets invalid", Update.pin_path())
    end
  end

  defp check_asset_shape!(%{"path" => path, "sha256" => sha256, "size" => size})
       when is_binary(path) and is_binary(sha256) and is_integer(size) and size >= 0 do
    if sha256 =~ @hex64, do: :ok, else: fail!("pin asset sha256 invalid", path)
  end

  defp check_asset_shape!(asset), do: fail!("pin asset entry invalid", inspect(asset))

  defp check_pinned_path!(%{"path" => path}) do
    owned? = Enum.any?(Update.owned_directories(), &String.starts_with?(path, &1 <> "/"))
    segments = Path.split(path)

    cond do
      Path.type(path) != :relative or ".." in segments or String.contains?(path, "\\") ->
        fail!("path escapes the owned directories", path)

      not owned? ->
        fail!("path is outside the owned directories", path)

      String.downcase(Path.extname(path)) not in @allowed_extensions ->
        fail!("extension not allowed", path)

      true ->
        :ok
    end
  end

  defp check_total_size!(assets) do
    total = assets |> Enum.map(& &1["size"]) |> Enum.sum()

    if total > @max_total_bytes do
      fail!("total size over ceiling", "#{total} > #{@max_total_bytes}")
    end
  end

  defp check_allowlist!(assets) do
    pinned = assets |> Enum.map(& &1["path"]) |> Enum.sort()
    adopted = Update.adopted_members() |> Enum.map(& &1.path) |> Enum.sort()

    if pinned != adopted do
      differing = (pinned -- adopted) ++ (adopted -- pinned)
      fail!("pinned paths differ from the adopted allowlist", Enum.join(differing, ", "))
    end
  end

  defp check_asset!(root, %{"path" => path, "size" => size, "sha256" => sha256}) do
    full = Path.join(root, path)

    case File.lstat(full) do
      {:ok, %File.Stat{type: :regular}} -> :ok
      {:ok, %File.Stat{type: :symlink}} -> fail!("symlink refused", path)
      {:ok, _other} -> fail!("not a regular file", path)
      {:error, _reason} -> fail!("missing pinned file", path)
    end

    contents = File.read!(full)

    if byte_size(contents) != size, do: fail!("size mismatch", path)
    if hex_sha256(contents) != sha256, do: fail!("sha256 mismatch", path)
    check_active_content!(path, contents)
  end

  defp check_active_content!(path, contents) do
    extension = String.downcase(Path.extname(path))

    if extension in @scanned_extensions do
      text = decode_text!(path, contents)
      variants = Enum.uniq([text, css_unescape(text)])

      patterns =
        if extension in @fragment_only_extensions,
          do: @active_content ++ @fragment_only,
          else: @active_content

      for {pattern, label} <- patterns, variant <- variants, Regex.match?(pattern, variant) do
        fail!("active content (#{label})", path)
      end
    end

    :ok
  end

  # The byte-level patterns cannot see inside UTF-16 or UTF-32, so a BOM-marked
  # file is decoded first. Anything that still cannot be read as UTF-8 text (a NUL
  # byte, a BOM-less wide encoding, invalid bytes) is refused rather than skipped.
  defp decode_text!(path, contents) do
    text = strip_bom!(path, contents)

    cond do
      String.contains?(text, <<0>>) -> fail!("content cannot be scanned (NUL byte)", path)
      not String.valid?(text) -> fail!("content cannot be scanned (not valid UTF-8)", path)
      true -> text
    end
  end

  defp strip_bom!(path, <<0xFF, 0xFE, 0, 0, rest::binary>>),
    do: decode_wide!(rest, {:utf32, :little}, path)

  defp strip_bom!(path, <<0, 0, 0xFE, 0xFF, rest::binary>>),
    do: decode_wide!(rest, {:utf32, :big}, path)

  defp strip_bom!(path, <<0xFF, 0xFE, rest::binary>>),
    do: decode_wide!(rest, {:utf16, :little}, path)

  defp strip_bom!(path, <<0xFE, 0xFF, rest::binary>>),
    do: decode_wide!(rest, {:utf16, :big}, path)

  defp strip_bom!(_path, <<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp strip_bom!(_path, contents), do: contents

  defp decode_wide!(bytes, encoding, path) do
    case :unicode.characters_to_binary(bytes, encoding, :utf8) do
      text when is_binary(text) -> text
      _error -> fail!("content cannot be scanned (invalid #{elem(encoding, 0)})", path)
    end
  end

  # CSS lets any character be written as a backslash escape (`\69` is `i`).
  defp css_unescape(text) do
    Regex.replace(~r/\\([0-9a-fA-F]{1,6})[ \t\n\r\f]?|\\(.)/su, text, fn
      _match, hex, "" -> codepoint(String.to_integer(hex, 16))
      _match, "", character -> character
    end)
  end

  defp codepoint(value) when value in 0..0xD7FF or value in 0xE000..0x10FFFF, do: <<value::utf8>>
  defp codepoint(_value), do: "\uFFFD"

  defp check_closed_directories!(root, assets) do
    allowed = MapSet.new([Update.pin_path() | Enum.map(assets, & &1["path"])])

    for directory <- Update.owned_directories(),
        found <- list_files!(root, directory),
        not MapSet.member?(allowed, found) do
      fail!("unpinned file", found)
    end

    :ok
  end

  # Recursive listing with dotfiles included; a symlink anywhere is refused.
  defp list_files!(root, relative) do
    full = Path.join(root, relative)

    case File.lstat(full) do
      {:ok, %File.Stat{type: :directory}} -> list_children!(root, relative, full)
      {:ok, %File.Stat{type: :symlink}} -> fail!("symlink refused", relative)
      {:ok, %File.Stat{type: :regular}} -> [relative]
      {:ok, _other} -> [relative]
      {:error, :enoent} -> []
      {:error, _reason} -> fail!("unreadable", relative)
    end
  end

  defp list_children!(root, relative, full) do
    case File.ls(full) do
      {:ok, names} ->
        names |> Enum.sort() |> Enum.flat_map(&list_files!(root, Path.join(relative, &1)))

      {:error, _reason} ->
        fail!("unreadable", relative)
    end
  end

  defp hex_sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)

  @spec fail!(String.t(), String.t()) :: no_return()
  defp fail!(reason, path), do: Mix.raise("verify.brand: #{reason}: #{path}")
end
