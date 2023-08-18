defmodule KnowitWeb.GraphLive do
  use KnowitWeb, :live_view
  @impl true
  def mount(_params, _session, socket) do
    schedule_update()
    {:ok, socket}
  end

  @impl true
  def handle_event("loadGraph", _, socket) do
    schedule_update()
    {:noreply, socket |> push_event("add_points", %{points: get_points()})}
  end

  defp schedule_update, do: self() |> Process.send_after(:update, 2000)

  defp get_points,
    do: %{
      nodes: [
        %{data: %{id: "a", parent: "b"}},
        %{data: %{id: "b"}},
        %{data: %{id: "c", parent: "b"}},
        %{data: %{id: "d"}},
        %{data: %{id: "e"}},
        %{data: %{id: "f", parent: "e"}}
      ],
      edges: [
        %{data: %{id: "ad", source: "a", target: "d"}},
        %{data: %{id: "eb", source: "e", target: "b"}}
      ]
    }
end
