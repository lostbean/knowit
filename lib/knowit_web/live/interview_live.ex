defmodule KnowitWeb.InterviewLive do
  use KnowitWeb, :live_view
  require Logger
  alias Knowit.Serving.DiscordBot

  @topic inspect(DiscordBot)

  @impl true
  def mount(_params, _session, socket) do
    DiscordBot.subscribe()

    {:ok,
     socket
     |> assign(
       transcription: nil,
       transcription_task: nil,
       graph_task: nil,
       graph: nil,
       notification: nil
     )
     |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)}
  end

  @impl true
  def handle_event("noop", %{}, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
  end

  @impl true
  def handle_event("text_input", input, socket) do
    if String.length(input) > 0 do
      Logger.warn(input)
      graph_task = extractTriples(input)
      {:noreply, assign(socket, graph_task: graph_task)}
    else
      {:noreply, socket}
    end
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
    Logger.warn("transcription: #{text}")
    {:noreply, assign(socket, transcription: text, transcription_task: nil)}
  end

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.graph_task.ref == ref do
    Process.demonitor(ref, [:flush])
    triples_text = result |> Enum.map(&Enum.join(&1, " <> "))
    Logger.warn("graph:\n#{triples_text |> Enum.join("\n")}")

    {:noreply,
     assign(
       socket,
       graph: triples_text,
       graph_task: nil
     )
     |> push_event("add_points", %{points: genCytoscapeData(result)})}
  end

  @impl true
  def handle_info(%{topic: @topic, event: "msg", payload: msg}, socket) do
    if String.length(msg.content) > 0 do
      Logger.warn("extracting triples from #{msg.author.username}: #{msg.content}")
      graph_task = extractTriples(msg.content)
      {:noreply, assign(socket, graph_task: graph_task)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, {%Jason.DecodeError{data: reason}, _}}, socket)
      when socket.assigns.graph_task.ref == ref do
    IO.inspect(reason)
    send(self(), :schedule_clear_flash)
    {:noreply, assign(socket, notification: reason)}
  end

  @impl true
  def handle_info(:schedule_clear_flash, socket) do
    :timer.sleep(5000)
    {:noreply, assign(socket, notification: nil)}
  end

  @impl true
  def handle_info(_info, socket) do
    {:noreply, socket}
  end

  def genCytoscapeData(triples) do
    nodes = triples |> Enum.flat_map(fn [a, _, c] -> [a, c] end) |> Enum.map(&%{data: %{id: &1}})

    edges =
      triples
      |> Enum.flat_map(fn [a, b, c] ->
        [%{data: %{id: a <> b <> c, source: a, target: c, type: b}}]
      end)

    %{
      nodes: nodes,
      edges: edges
    }
  end

  def extractTriples(text) do
    options = [restart: :transient, max_restarts: 2]

    Task.Supervisor.async_nolink(
      Knowit.TaskSupervisor,
      fn ->
        Knowit.Serving.OpenAI.extract_knowledge_graph(text)
      end,
      options
    )
  end
end
