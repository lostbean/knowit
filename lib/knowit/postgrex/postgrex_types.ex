Postgrex.Types.define(
  Knowit.Postgrex.PostgrexTypes,
  [Knowit.Postgrex.AgeType, Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(),
  [])
