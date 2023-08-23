defmodule Knowit.OAuthClient do
  require Logger

  defp client do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.AuthCode,
      authorize_url: "/oauth2/authorize",
      token_url: "/api/oauth2/token",
      site: "https://discord.com",
      client_id: Application.get_env(:knowit, __MODULE__)[:client_id],
      client_secret: Application.get_env(:knowit, __MODULE__)[:client_secret],
      redirect_uri: Application.get_env(:knowit, __MODULE__)[:external_hostname] <> "/auth/callback"
    )
  end

  def authorize_url() do
    scopes =
      [
        "identify"
      ]
      |> Enum.join(" ")

    OAuth2.Client.authorize_url!(client(), scope: scopes)
  end

  def handle_callback(params) do
    case OAuth2.Client.get_token(client(), code: params.code) do
      {:ok, token_client} ->
        %{
          token_client
          | token: OAuth2.AccessToken.new(Jason.decode!(token_client.token.access_token))
        }

      {:error, reason} ->
        Logger.error("OAuth2 token retrieval error: #{reason}")
    end
  end
end
