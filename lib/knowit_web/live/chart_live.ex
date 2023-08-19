defmodule KnowitWeb.ChartLive do
  use KnowitWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    schedule_update()
    {:ok,
     socket
     |> assign(transcription: nil, task: nil)
     |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)}
  end

  @impl true
  def handle_event("next", _, socket) do
    schedule_update()
    {:noreply, socket |> push_event("points", %{points: get_points()})}
  end

  @impl true
  def handle_event("noop", %{}, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
  end

  defp handle_progress(:audio, entry, socket) when entry.done? do
    binary =
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        {:ok, File.read!(path)}
      end)

    # We always pre-process audio on the client into a single channel
    audio = Nx.from_binary(binary, :f32)

    task = Task.async(fn -> Nx.Serving.batched_run(Knowit.Serving.AudioToText, audio) end)

    {:noreply, assign(socket, task: task)}
  end

  defp handle_progress(_name, _entry, socket), do: {:noreply, socket}

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.task.ref == ref do
    Process.demonitor(ref, [:flush])
    %{results: [%{text: text}]} = result
    {:noreply, assign(socket, transcription: text, task: nil)}
  end

  @impl true
  def handle_info(_info, socket), do: {:noreply, socket}

  defp schedule_update, do: self() |> Process.send_after(:update, 2000)
  defp get_points, do: 1..7 |> Enum.map(fn _ -> :rand.uniform(100) end)
end
