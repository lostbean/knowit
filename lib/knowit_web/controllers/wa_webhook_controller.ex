defmodule KnowitWeb.WaWebhookController do
  use KnowitWeb, :controller
  alias Plug.Conn
  require Logger

  def hook(conn, params) do
    Logger.warn(params)
    conn
      |> Conn.send_resp(:ok, "")
  end
end
