defmodule WaBotHook do
  def changes(data) do
    case data do
      %{"changes" => e} -> e
      _ -> []
    end
  end

  def entries(data) do
    case data do
      {"entry", e} -> e
      _ -> []
    end
  end

  def msgs(data) do
    case data do
      %{"field" => "messages", "value" => %{"messages" => e}} -> e
      _ -> []
    end
  end

  def get_messages(event) do
    event
    |> Enum.flat_map(&entries(&1))
    |> Enum.flat_map(&changes(&1))
    |> Enum.flat_map(&msgs(&1))
  end
end

defmodule Knowit.WaBot do
  @topic inspect(__MODULE__)

  def subscribe() do
    KnowitWeb.Endpoint.subscribe(@topic)
  end

  def broadcast_msgs(%{"from" => from, "text" => %{"body" => msg}}) do
    :ok = KnowitWeb.Endpoint.broadcast_from(self(), @topic, "msg", %{:msg => msg, :from => from })
  end

  def process_hooked_event(event) do
    event |> WaBotHook.get_messages() |> Enum.map(&broadcast_msgs(&1))
  end
end
