defmodule KnowitWeb.WaWebhookController do
  use KnowitWeb, :controller
  alias Plug.Conn
  alias Knowit.WaBot
  require Logger

  def hook(conn, params) do
    WaBot.process_hooked_event(params)

    conn
    |> Conn.send_resp(:ok, "")
  end

  def link_hook(conn, %{
        "hub.challenge" => challenge,
        "hub.mode" => "subscribe",
        "hub.verify_token" => token
      }) do
    Logger.warning(token)
    Logger.warning(challenge)

    conn
    |> Conn.send_resp(:ok, challenge)
  end
end
