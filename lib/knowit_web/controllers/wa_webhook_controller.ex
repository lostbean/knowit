defmodule KnowitWeb.WaWebhookController do
  use KnowitWeb, :controller
  alias Plug.Conn
  require Logger

  def hook(conn, params) do
    Logger.warn(params)
    conn
      |> Conn.send_resp(:ok, "")
  end

  def link_hook(conn, %{ " hub.challenge" => challenge, " hub.mode" => "subscribe", " hub.verify_token" => token}) do
    Logger.warn(token)
    Logger.warn(challenge)
    conn
      |> Conn.send_resp(:ok, challenge)
  end

end
