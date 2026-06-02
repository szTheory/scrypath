defmodule ScrypathEcommerceWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint ScrypathEcommerceWeb.Endpoint

      use ScrypathEcommerceWeb, :verified_routes

      import Phoenix.ConnTest
      import Plug.Conn
      import ScrypathEcommerceWeb.ConnCase
    end
  end

  setup tags do
    ScrypathEcommerce.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
