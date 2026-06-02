defmodule ScrypathEcommerceWeb.Layouts do
  @moduledoc false

  use ScrypathEcommerceWeb, :html

  attr(:flash, :map, default: %{})
  attr(:inner_content, :any, required: true)
  attr(:conn, :any, default: nil)

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>Scrypath Ecommerce</title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <link
          :if={ops_admin_path?(@conn)}
          phx-track-static
          rel="stylesheet"
          href="/admin/search/assets/css/app.css"
        />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
        </script>
      </head>
      <body class="scrypath-demo">
        <.flash_group flash={@flash} />
        {@inner_content}
      </body>
    </html>
    """
  end

  defp ops_admin_path?(%Plug.Conn{request_path: path}) when is_binary(path) do
    String.starts_with?(path, "/admin/search")
  end

  defp ops_admin_path?(_), do: false
end
