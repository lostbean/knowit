defmodule Knowit.Repo do
  use Ecto.Repo,
    otp_app: :knowit,
    adapter: Ecto.Adapters.Postgres
end
