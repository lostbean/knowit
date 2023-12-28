defmodule KnowitWeb.AudioToTextLive do
  use KnowitWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(transcription: nil, transcription_task: nil, graph_task: nil, graph: nil)
     |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)}
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

    transcription_task =
      Task.async(fn -> Nx.Serving.batched_run(Knowit.Serving.AudioToText, audio) end)

    {:noreply, assign(socket, transcription_task: transcription_task)}
  end

  defp handle_progress(_name, _entry, socket), do: {:noreply, socket}

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.transcription_task.ref == ref do
    Process.demonitor(ref, [:flush])
    %{results: [%{text: text}]} = result

    Logger.warning("transcription: #{text}")
    graph_task = Task.async(fn -> Knowit.Serving.OpenAI.extract_knowledge_graph(text) end)

    {:noreply,
     assign(socket, transcription: text, transcription_task: nil, graph_task: graph_task)}
  end

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.graph_task.ref == ref do
    Process.demonitor(ref, [:flush])
    kg = result |> Enum.map(&Enum.join(&1, " <> "))
    Logger.warning("graph:\n#{kg |> Enum.join("\n")}")
    {:noreply, assign(socket, graph: kg, graph_task: nil)}
  end

  @impl true
  def handle_info(_info, socket), do: {:noreply, socket}
end
