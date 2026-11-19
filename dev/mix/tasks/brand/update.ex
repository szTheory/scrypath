defmodule Mix.Tasks.Brand.Update do
  @moduledoc """
  The only module that touches the network for the brand archive. Without
  arguments it re-downloads the archive and compares it with the pin (read
  only). With a source and the full expected-values set it refreshes the
  committed assets and the pin. Nothing here runs in CI.
  """
  use Mix.Task

  @shortdoc "Re-checks or refreshes the pinned brand assets from the brand archive"

  @source_url "https://sztheory.github.io/scrypath-brand/scrypath-brand.zip"
  @member_prefix "scrypath-brand/"
  @pin_path "brand/brand.pin.json"
  @pin_schema "scrypath.brand-pin.v1"
  @owned_directories ["brand", "scrypath_ops/priv/static/assets/fonts"]
  @fonts_directory "scrypath_ops/priv/static/assets/fonts"

  @max_zip_bytes 8_388_608
  @max_entries 200
  @max_uncompressed_bytes 16_777_216

  @brand_license "Apache-2.0 (per brand.json legal; brand repository has no LICENSE file at ced7c40e)"
  @font_license "OFL-1.1"

  @switches [
    zip: :string,
    url: :string,
    sha256: :string,
    size: :integer,
    entries: :integer,
    uncompressed: :integer,
    commit: :string
  ]
  @refresh_flags [:sha256, :size, :entries, :uncompressed, :commit]

  # {archive member without the prefix, kind, role}. The repo path is derived:
  # fonts and their licenses go beside the ops fonts, everything else under brand/.
  @adopted_rows [
    {"BRAND.md", "doc", "Brand book text: voice, color, type and usage rules"},
    {"brand.json", "data", "Machine-readable brand book"},
    {"tokens.json", "data", "Design tokens: the source for adopted token-map rows"},
    {"assets/README.md", "doc", "Asset folder guide"},
    {"assets/logo/scrypath-lockup-dark.svg", "logo", "Lockup for dark backgrounds"},
    {"assets/logo/scrypath-lockup-light.svg", "logo", "Lockup for light backgrounds"},
    {"assets/logo/scrypath-lockup-one-color-ink.svg", "logo", "One-color ink lockup"},
    {"assets/logo/scrypath-lockup-one-color-pale-ink.svg", "logo", "One-color pale-ink lockup"},
    {"assets/logo/scrypath-symbol-dark.svg", "logo", "Symbol for dark backgrounds"},
    {"assets/logo/scrypath-symbol-light.svg", "logo", "Symbol for light backgrounds"},
    {"assets/logo/scrypath-symbol-one-color-ink.svg", "logo", "One-color ink symbol"},
    {"assets/logo/scrypath-symbol-one-color-pale-ink.svg", "logo", "One-color pale-ink symbol"},
    {"assets/icon/favicon-16-dark.png", "icon", "16 px favicon, dark"},
    {"assets/icon/favicon-16-dark.svg", "icon", "16 px favicon vector, dark"},
    {"assets/icon/favicon-16-light.png", "icon", "16 px favicon, light"},
    {"assets/icon/favicon-16-light.svg", "icon", "16 px favicon vector, light"},
    {"assets/icon/favicon-16-mono.png", "icon", "16 px favicon, mono"},
    {"assets/icon/favicon-16-mono.svg", "icon", "16 px favicon vector, mono"},
    {"assets/icon/favicon-32-dark.png", "icon", "32 px favicon, dark"},
    {"assets/icon/favicon-32-dark.svg", "icon", "32 px favicon vector, dark"},
    {"assets/icon/favicon-32-light.png", "icon", "32 px favicon, light"},
    {"assets/icon/favicon-32-light.svg", "icon", "32 px favicon vector, light"},
    {"assets/icon/favicon-32-mono.png", "icon", "32 px favicon, mono"},
    {"assets/icon/favicon-32-mono.svg", "icon", "32 px favicon vector, mono"},
    {"assets/icon/favicon-48-dark.png", "icon", "48 px favicon, dark"},
    {"assets/icon/favicon-48-light.png", "icon", "48 px favicon, light"},
    {"assets/icon/favicon-48-mono.png", "icon", "48 px favicon, mono"},
    {"assets/icon/favicon-dark.svg", "icon", "Scalable favicon, dark"},
    {"assets/icon/favicon-light.svg", "icon", "Scalable favicon, light"},
    {"assets/icon/favicon.svg", "icon", "Scalable favicon, default"},
    {"assets/icon/favicon.ico", "icon", "Multi-size ICO favicon"},
    {"assets/readme/scrypath-header-dark.svg", "readme-header", "README header, dark"},
    {"assets/readme/scrypath-header-light.svg", "readme-header", "README header, light"},
    {"assets/readme/header-snippet.html", "readme-snippet", "picture fragment for the README"},
    {"assets/avatar/scrypath-avatar-dark.svg", "avatar", "Avatar, dark"},
    {"assets/avatar/scrypath-avatar-light.svg", "avatar", "Avatar, light"},
    {"assets/docs/scrypath-exdoc.css", "stylesheet", "ExDoc stylesheet (has known bugs)"},
    {"assets/social/scrypath-social-card-1280x640.png", "social-card", "Social card"},
    {"assets/fonts/web/display.woff2", "font", "Display face (Bricolage Grotesque)"},
    {"assets/fonts/web/ui.woff2", "font", "UI face (Hanken Grotesk)"},
    {"assets/fonts/web/mono.woff2", "font", "Mono face (Sometype Mono)"},
    {"assets/fonts/OFL-BricolageGrotesque.txt", "license", "OFL text, display face"},
    {"assets/fonts/OFL-HankenGrotesk.txt", "license", "OFL text, UI face"},
    {"assets/fonts/OFL-SometypeMono.txt", "license", "OFL text, mono face"}
  ]

  @adopted Enum.map(@adopted_rows, fn {member, kind, role} ->
             font? = kind in ["font", "license"]

             %{
               path:
                 if(font?,
                   do: Path.join(@fonts_directory, Path.basename(member)),
                   else: Path.join("brand", member)
                 ),
               member: member,
               kind: kind,
               role: role,
               license: if(font?, do: @font_license, else: @brand_license)
             }
           end)

  @impl true
  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: @switches)

    if rest != [] or invalid != [] do
      Mix.raise("brand.update: unexpected arguments: #{Enum.join(args, " ")}")
    end

    root = Path.dirname(Mix.Project.project_file())

    case {opts[:zip], opts[:url]} do
      {nil, nil} -> run_check(root, opts)
      {zip, nil} -> refresh!(root, {:zip, zip}, opts)
      {nil, url} -> refresh!(root, {:url, url}, opts)
      {_zip, _url} -> Mix.raise("brand.update: pass either --zip or --url, not both")
    end
  end

  @doc false
  def adopted_members, do: @adopted

  @doc false
  def owned_directories, do: @owned_directories

  @doc false
  def pin_path, do: @pin_path

  @doc """
  Refuses (raises) unless the archive is exactly the expected one.

  `expected` must carry `:sha256`, `:size`, `:entries` and `:uncompressed`; there
  are no defaults. Caps are checked before the matching pin value, so an
  over-cap archive reaches the cap refusal.
  """
  def verify_archive!(zip_binary, expected) when is_binary(zip_binary) do
    expected = fetch_expected!(expected)
    check_size!(zip_binary, expected.size)
    check_sha256!(zip_binary, expected.sha256)

    with_zip(zip_binary, fn _handle, entries ->
      check_entry_count!(entries, expected.entries)
      check_uncompressed!(entries, expected.uncompressed)
      check_names!(entries)
      check_adopted_members!(entries)
      :ok
    end)
  end

  @doc false
  def extract!(zip_binary, expected) do
    verify_archive!(zip_binary, expected)

    with_zip(zip_binary, fn _handle, entries ->
      located =
        Map.new(entries, fn {name, size, offset, comp} -> {name, {size, offset, comp}} end)

      for entry <- @adopted do
        full_name = @member_prefix <> entry.member
        {declared, offset, comp_size} = Map.fetch!(located, full_name)
        {entry, inflate_member!(zip_binary, full_name, declared, offset, comp_size)}
      end
    end)
  end

  @doc false
  def write!(root, extracted, source_meta) do
    for {entry, bytes} <- extracted do
      unless entry in @adopted do
        refuse!("refusing to write an entry outside the allowlist: #{inspect(entry)}")
      end

      destination = Path.join(root, entry.path)
      File.mkdir_p!(Path.dirname(destination))
      File.write!(destination, bytes)
    end

    pin = build_pin(extracted, source_meta)
    pin_file = Path.join(root, @pin_path)
    File.mkdir_p!(Path.dirname(pin_file))
    File.write!(pin_file, Jason.encode!(pin, pretty: true) <> "\n")
    :ok
  end

  @doc false
  def fetch!(url, req_options \\ []) do
    unless String.starts_with?(url, "https://") do
      Mix.raise("brand.update: only https URLs are accepted: #{url}")
    end

    {:ok, _apps} = Application.ensure_all_started(:req)

    # Req re-runs every request step on each redirect hop, so the scheme check
    # below also refuses an https-to-http downgrade, not only a bad first URL.
    req =
      ([decode_body: false, max_redirects: 3, retry: false, into: &capped_chunk/2] ++
         req_options)
      |> Req.new()
      |> Req.Request.prepend_request_steps(https_only: &require_https/1)

    case Req.get(req, url: url) do
      {:ok, response} -> finish_download!(response)
      {:error, error} -> Mix.raise("brand.update: download failed: #{Exception.message(error)}")
    end
  end

  @doc false
  def check_live!(root, req_options \\ []) do
    expected = expected_from_pin!(root)
    verify_archive!(fetch!(@source_url, req_options), expected)
    Mix.shell().info("brand.update: live archive matches pin")
    :ok
  end

  defp run_check(root, opts) do
    if Enum.any?(@refresh_flags, &Keyword.has_key?(opts, &1)) do
      Mix.raise("brand.update: refresh flags need a source: pass --zip PATH or --url URL")
    end

    check_live!(root)
  end

  @doc false
  def refresh!(root, source, opts) do
    # Validate every flag before touching the file system or the network.
    expected = expected_from_opts!(opts)
    {zip_binary, url} = load_source!(source)
    extracted = extract!(zip_binary, expected)

    write!(root, extracted, %{
      url: url,
      repository_commit: opts[:commit],
      zip_sha256: expected.sha256,
      zip_size: expected.size,
      zip_entries: expected.entries,
      zip_uncompressed_bytes: expected.uncompressed
    })

    Mix.shell().info("brand.update: wrote #{length(extracted)} assets and #{@pin_path}")

    Mix.shell().info(
      "brand.update: change @expected_zip_sha256 in test/mix/tasks/brand_pin_contract_test.exs " <>
        "to #{expected.sha256} in the same PR (two keys: the pin and that constant)"
    )

    :ok
  end

  # A local --zip copy is recorded against the canonical Pages URL.
  defp load_source!({:zip, path}), do: {read_zip!(path), @source_url}
  defp load_source!({:url, url}), do: {fetch!(url), url}

  defp expected_from_opts!(opts) do
    missing = Enum.reject(@refresh_flags, &Keyword.has_key?(opts, &1))

    if missing != [] do
      flags = Enum.map_join(missing, " ", &"--#{&1}")
      Mix.raise("brand.update: refresh requires #{flags}")
    end

    unless opts[:commit] =~ ~r/\A[0-9a-f]{7,40}\z/ do
      Mix.raise("brand.update: --commit must be a lowercase hex commit id")
    end

    %{
      sha256: opts[:sha256],
      size: opts[:size],
      entries: opts[:entries],
      uncompressed: opts[:uncompressed]
    }
  end

  defp expected_from_pin!(root) do
    source =
      root
      |> Path.join(@pin_path)
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("source")

    %{
      sha256: Map.fetch!(source, "zip_sha256"),
      size: Map.fetch!(source, "zip_size"),
      entries: Map.fetch!(source, "zip_entries"),
      uncompressed: Map.fetch!(source, "zip_uncompressed_bytes")
    }
  rescue
    error in [File.Error, Jason.DecodeError, KeyError] ->
      Mix.raise("brand.update: cannot read the pin #{@pin_path}: #{Exception.message(error)}")
  end

  defp fetch_expected!(expected) do
    for key <- [:sha256, :size, :entries, :uncompressed], into: %{} do
      case Map.fetch(expected, key) do
        {:ok, value} -> {key, value}
        :error -> refuse!("expected value #{key} is required")
      end
    end
  end

  defp read_zip!(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :regular, size: size}} when size <= @max_zip_bytes ->
        File.read!(path)

      {:ok, %File.Stat{type: :regular, size: size}} ->
        refuse!("archive size #{size} exceeds cap #{@max_zip_bytes}")

      _other ->
        Mix.raise("brand.update: cannot read a regular archive file at #{path}")
    end
  end

  defp require_https(%Req.Request{url: %URI{scheme: "https"}} = request), do: request

  defp require_https(%Req.Request{} = request) do
    Req.Request.halt(
      request,
      RuntimeError.exception("refusing non-https hop #{URI.to_string(request.url)}")
    )
  end

  # Streaming size cap: count bytes as they arrive and halt once over the cap.
  defp capped_chunk({:data, data}, {request, response}) do
    total = Req.Response.get_private(response, :brand_bytes, 0) + byte_size(data)
    response = Req.Response.put_private(response, :brand_bytes, total)

    if total > @max_zip_bytes do
      {:halt, {request, Req.Response.put_private(response, :brand_over_cap, true)}}
    else
      chunks = Req.Response.get_private(response, :brand_chunks, [])
      {:cont, {request, Req.Response.put_private(response, :brand_chunks, [data | chunks])}}
    end
  end

  defp finish_download!(response) do
    cond do
      Req.Response.get_private(response, :brand_over_cap, false) ->
        seen = Req.Response.get_private(response, :brand_bytes, 0)

        Mix.raise(
          "brand.update: download exceeds cap #{@max_zip_bytes} bytes (halted after #{seen} bytes)"
        )

      response.status != 200 ->
        Mix.raise("brand.update: download failed with HTTP status #{response.status}")

      true ->
        response
        |> Req.Response.get_private(:brand_chunks, [])
        |> Enum.reverse()
        |> IO.iodata_to_binary()
    end
  end

  defp check_size!(zip_binary, expected_size) do
    size = byte_size(zip_binary)

    cond do
      size > @max_zip_bytes ->
        refuse!("archive size #{size} exceeds cap #{@max_zip_bytes}")

      size != expected_size ->
        refuse!("archive size #{size} does not match expected #{expected_size}")

      true ->
        :ok
    end
  end

  defp check_sha256!(zip_binary, expected_sha256) do
    actual = :crypto.hash(:sha256, zip_binary) |> Base.encode16(case: :lower)

    if actual != String.downcase(expected_sha256) do
      refuse!("archive sha256 #{actual} does not match expected #{expected_sha256}")
    end
  end

  defp check_entry_count!(entries, expected_entries) do
    count = length(entries)

    cond do
      count > @max_entries ->
        refuse!("entry count #{count} exceeds cap #{@max_entries}")

      count != expected_entries ->
        refuse!("entry count #{count} does not match expected #{expected_entries}")

      true ->
        :ok
    end
  end

  defp check_uncompressed!(entries, expected_total) do
    total = entries |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    cond do
      total > @max_uncompressed_bytes ->
        refuse!("declared uncompressed total #{total} exceeds cap #{@max_uncompressed_bytes}")

      total != expected_total ->
        refuse!("declared uncompressed total #{total} does not match expected #{expected_total}")

      true ->
        :ok
    end
  end

  defp check_names!(entries) do
    for {name, _size, _offset, _comp} <- entries do
      cond do
        String.starts_with?(name, "/") ->
          refuse!("entry name is absolute: #{inspect(name)}")

        String.contains?(name, "\\") ->
          refuse!("entry name has a backslash: #{inspect(name)}")

        ".." in String.split(name, "/") ->
          refuse!("entry name has a .. segment: #{inspect(name)}")

        true ->
          :ok
      end
    end
  end

  defp check_adopted_members!(entries) do
    names = Enum.map(entries, &elem(&1, 0))

    for entry <- @adopted do
      full_name = @member_prefix <> entry.member

      case Enum.count(names, &(&1 == full_name)) do
        1 -> :ok
        0 -> refuse!("allowlisted member #{full_name} is missing")
        n -> refuse!("allowlisted member #{full_name} appears #{n} times")
      end
    end
  end

  # Opens the archive in memory and yields {name, declared_size, offset,
  # compressed_size} tuples from the central directory. Always closes the handle.
  defp with_zip(zip_binary, fun) do
    case :zip.zip_open(zip_binary, [:memory]) do
      {:ok, handle} ->
        try do
          fun.(handle, list_entries!(handle))
        after
          :zip.zip_close(handle)
        end

      {:error, {:EXIT, _crash}} ->
        refuse!("archive could not be opened: not a readable zip file")

      {:error, reason} ->
        refuse!("archive could not be opened: #{inspect(reason)}")
    end
  end

  defp list_entries!(handle) do
    case :zip.zip_list_dir(handle) do
      {:ok, records} ->
        # zip_file record: {:zip_file, name, file_info, comment, offset, comp_size};
        # file_info element 1 is the declared uncompressed size and offset is the
        # local header position. Every number here is what the archive claims.
        for {:zip_file, name, info, _comment, offset, comp_size} <- records do
          {List.to_string(name), elem(info, 1), offset, comp_size}
        end

      {:error, reason} ->
        refuse!("archive listing failed: #{inspect(reason)}")
    end
  end

  # Reads one member through its local header and inflates it with a byte budget
  # equal to the size the central directory declares (zip-bomb defence). The
  # budget is enforced while inflating, not after: `:zip.zip_get/2` would inflate
  # the whole stream into memory before any size comparison could run. The
  # declared sizes were already summed and capped by `verify_archive!/2`.
  defp inflate_member!(zip_binary, name, declared, offset, comp_size) do
    {method, crc, checked?, data} = local_member!(zip_binary, name, declared, offset, comp_size)

    bytes =
      case method do
        0 when comp_size == declared ->
          data

        0 ->
          refuse!("member #{name} is stored with #{comp_size} bytes, declared #{declared}")

        8 ->
          bounded_inflate!(name, data, declared)

        other ->
          refuse!("member #{name} uses compression method #{other}; only stored and deflate")
      end

    if byte_size(bytes) != declared do
      refuse!("member #{name} extracted #{byte_size(bytes)} bytes, declared #{declared}")
    end

    if checked? and :erlang.crc32(bytes) != crc do
      refuse!("member #{name} fails its CRC-32 check")
    end

    bytes
  end

  # A bit 3 data descriptor moves the sizes and the CRC out of the local header;
  # for those members only the central-directory numbers are available.
  defp local_member!(zip_binary, name, declared, offset, comp_size) do
    with <<_before::binary-size(offset), 0x50, 0x4B, 0x03, 0x04, _version::16-little,
           flags::16-little, method::16-little, _time::16, _date::16, crc::32-little,
           local_comp::32-little, local_size::32-little, name_length::16-little,
           extra_length::16-little, rest::binary>> <- zip_binary,
         <<local_name::binary-size(name_length), _extra::binary-size(extra_length),
           data::binary-size(comp_size), _after::binary>> <- rest do
      descriptor? = Bitwise.band(flags, 0x08) != 0

      cond do
        Bitwise.band(flags, 0x01) != 0 ->
          refuse!("member #{name} is encrypted")

        local_name != name ->
          refuse!("local header of #{name} names a different member")

        not descriptor? and (local_comp != comp_size or local_size != declared) ->
          refuse!("local header of #{name} disagrees with the central directory sizes")

        true ->
          {method, crc, not descriptor?, data}
      end
    else
      _malformed -> refuse!("member #{name} has a malformed local header or truncated data")
    end
  end

  defp bounded_inflate!(name, compressed, limit) do
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z, -15)
      inflate_loop!(z, name, :zlib.safeInflate(z, compressed), [], 0, limit)
    rescue
      error in ErlangError ->
        refuse!("member #{name} is not a valid deflate stream: #{inspect(error.original)}")
    after
      :zlib.close(z)
    end
  end

  # safeInflate returns at most one internal buffer (16 KiB) per call, so memory
  # held at the moment of refusal is the limit plus one buffer.
  defp inflate_loop!(z, name, {status, output}, acc, size, limit) do
    size = size + IO.iodata_length(output)

    if size > limit do
      refuse!("member #{name} inflates past its declared size #{limit}")
    end

    acc = [acc | output]

    case status do
      :finished -> IO.iodata_to_binary(acc)
      :continue -> inflate_loop!(z, name, :zlib.safeInflate(z, []), acc, size, limit)
    end
  end

  defp build_pin(extracted, source_meta) do
    assets =
      extracted
      |> Enum.sort_by(fn {entry, _bytes} -> entry.path end)
      |> Enum.map(fn {entry, bytes} ->
        ordered([
          {"path", entry.path},
          {"source_member", entry.member},
          {"sha256", :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)},
          {"size", byte_size(bytes)},
          {"license", entry.license},
          {"role", entry.role},
          {"kind", entry.kind}
        ])
      end)

    ordered([
      {"schema", @pin_schema},
      {"source",
       ordered([
         {"url", source_meta.url},
         {"repository_commit", source_meta.repository_commit},
         {"zip_sha256", source_meta.zip_sha256},
         {"zip_size", source_meta.zip_size},
         {"zip_entries", source_meta.zip_entries},
         {"zip_uncompressed_bytes", source_meta.zip_uncompressed_bytes},
         {"member_prefix", @member_prefix}
       ])},
      {"owned_directories", @owned_directories},
      {"assets", assets}
    ])
  end

  defp ordered(pairs), do: Jason.OrderedObject.new(pairs)

  defp refuse!(message), do: Mix.raise("brand.update: " <> message)
end
