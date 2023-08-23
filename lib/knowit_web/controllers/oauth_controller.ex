defmodule KnowitWeb.OAuthController do
  use KnowitWeb, :controller

  def start_oauth(conn, _params) do
    redirect(conn, external: Knowit.OAuthClient.authorize_url())
  end

  def callback(conn, %{"code" => code}) do
    client = Knowit.OAuthClient.handle_callback(%{code: code})
    resource = OAuth2.Client.get!(client, "/api/v6/users/@me").body |> Jason.decode!
    redirect(conn, to: "/interview")
  end
end
