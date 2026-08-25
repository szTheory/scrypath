defmodule ScrypathOps.SwooshApiClientReqTest do
  use ExUnit.Case, async: true

  test "initializes and posts Swoosh-owned request options through Req.Test" do
    stub = Module.concat(__MODULE__, PostStub)
    url = "https://mail.example.test/v1/messages"
    body = "to=operator%40example.test&subject=ScrypathOps"

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/v1/messages"
      assert conn.host == "mail.example.test"
      assert conn.query_params == %{"trace" => "forwarded-146"}
      assert Plug.Conn.get_req_header(conn, "x-provider-token") == ["token-146"]
      assert Plug.Conn.get_req_header(conn, "x-client-option") == ["forwarded-146"]
      assert Plug.Conn.get_req_header(conn, "user-agent") == ["swoosh/#{Swoosh.version()}"]
      assert Plug.Conn.get_req_header(conn, "x-conflicting-client-option") == []

      assert {:ok, ^body, conn} = Plug.Conn.read_body(conn)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, ~s({"accepted":true}))
    end)

    email = %Swoosh.Email{
      private: %{
        client_options: [
          plug: {Req.Test, stub},
          retry: false,
          headers: [{"x-conflicting-client-option", "ignored"}],
          body: "ignored body",
          decode_body: true,
          params: [trace: "forwarded-146"]
        ]
      }
    }

    assert :ok = Swoosh.ApiClient.Req.init()

    assert {:ok, 200, response_headers, ~s({"accepted":true})} =
             Swoosh.ApiClient.Req.post(
               url,
               [{"x-provider-token", "token-146"}, {"x-client-option", "forwarded-146"}],
               body,
               email
             )

    assert {"content-type", "application/json; charset=utf-8"} in response_headers
  end

  test "propagates Req transport errors without changing the wrapper shape" do
    stub = Module.concat(__MODULE__, TransportErrorStub)

    Req.Test.stub(stub, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    email = %Swoosh.Email{private: %{client_options: [plug: {Req.Test, stub}, retry: false]}}

    assert {:error, %Req.TransportError{reason: :timeout}} =
             Swoosh.ApiClient.Req.post(
               "https://mail.example.test/v1/messages",
               [{"x-provider-token", "token-146"}],
               "timeout body",
               email
             )
  end
end
