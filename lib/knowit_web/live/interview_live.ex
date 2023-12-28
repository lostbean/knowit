defmodule KnowitWeb.InterviewLive do
  alias Knowit.DB
  use KnowitWeb, :live_view
  require Logger
  alias Knowit.Serving.DiscordBot
  alias Knowit.WaBot
  alias Knowit.Accounts
  alias Knowit.KnowitIndex

  @discord_topic inspect(DiscordBot)
  @wa_topic inspect(WaBot)

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    DiscordBot.subscribe()
    WaBot.subscribe()
    send(self(), :list_experiment_sets)
    send(self(), :select_latest_set)

    {:ok,
     assign(socket,
       current_user: user,
       experiment_sets: [],
       transcription: nil,
       transcription_task: nil,
       graph_task: nil,
       graph: nil,
       notification: nil,
       selected_set_id: nil
     )
     |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)}
  end

  @impl true
  def mount(_params, _session, socket) do
    redirect(socket, to: "/users/log_in")
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
      Logger.warning(input)
      graph_task = extractTriples(input)
      {:noreply, assign(socket, graph_task: graph_task)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_set", %{"set-id" => set_id}, socket) do
    {:noreply, assign_selected_set_id_to_socket(socket, set_id)}
  end

  def handle_event("add_new_set", _input, socket) do
    Knowit.DB.new_experiment_set("new knowledge", socket.assigns.current_user)
    send(self(), :list_experiment_sets)
    send(self(), :select_latest_set)
    {:noreply, socket}
  end

  def handle_event(
        "rename_experiment_set",
        %{"rename_set_id" => set_id, "rename_to" => text},
        socket
      ) do
    Knowit.DB.rename_experiment_set(text, socket.assigns.current_user, set_id)
    send(self(), :list_experiment_sets)
    {:noreply, socket}
  end

  def handle_event("delete_experiment_set", %{"value" => set_id}, socket) do
    Knowit.DB.delete_experiment_set(socket.assigns.current_user, set_id)
    send(self(), :list_experiment_sets)
    send(self(), :select_latest_set)
    {:noreply, socket}
  end

  def handle_event(event, _input, socket) do
    Logger.warning("UNHANDLED EVENT: #{event}")
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
    {:noreply, assign(socket, transcription: text, transcription_task: nil)}
  end

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.graph_task.ref == ref do
    Process.demonitor(ref, [:flush])

    triples_text = result |> Enum.map(&Enum.join(&1, " <> "))
    Logger.warning("graph:\n#{triples_text |> Enum.join("\n")}")

    saveTriples(result, socket.assigns.current_user, socket.assigns.selected_set_id)

    {:noreply,
     assign(
       socket,
       graph: triples_text,
       graph_task: nil
     )
     |> push_event("add_points", %{points: genCytoscapeData(result)})}
  end

  @impl true
  def handle_info(%{topic: @wa_topic, event: "msg", payload: payload}, socket) do
    if String.length(payload.msg) > 0 do
      Logger.warning("extracting triples from #{payload.from}: #{payload.msg}")
      graph_task = extractTriples(payload.msg)
      {:noreply, assign(socket, graph_task: graph_task)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{topic: @discord_topic, event: "msg", payload: msg}, socket) do
    if String.length(msg.content) > 0 do
      Logger.warning("extracting triples from #{msg.author.username}: #{msg.content}")
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
  def handle_info(:select_latest_set, socket) do
    lastest_set = DB.latest_updated_experiment_set(socket.assigns.current_user)
    set_id_str = if lastest_set, do: "#{lastest_set.id}", else: nil
    {:noreply, assign_selected_set_id_to_socket(socket, set_id_str)}
  end

  @impl true
  def handle_info(:list_experiment_sets, socket) do
    sets = Knowit.DB.list_experiment_sets(socket.assigns.current_user)
    {:noreply, assign(socket, experiment_sets: sets)}
  end

  @impl true
  def handle_info(_info, socket) do
    Logger.warning("UNHANDLED INFO")
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

  def assign_selected_set_id_to_socket(socket, set_id) do
    triples = KnowitIndex.list_experiment(socket.assigns.current_user, set_id)

    socket
    |> assign(selected_set_id: set_id)
    |> push_event("reset_points", %{points: genCytoscapeData(triples)})
  end

  def saveTriples(triples, user, set_id) do
    options = [restart: :transient, max_restarts: 2]

    Task.Supervisor.async_nolink(
      Knowit.TaskSupervisor,
      fn ->
        set = DB.get_experiment_set(user, set_id)
        triples |> Enum.map(&KnowitIndex.insert_triple(&1, set))
      end,
      options
    )
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

  defp live_card(assigns) do
    ~H"""
    <button
      class="card block align-middle text-align-center translate-x-6"
      phx-click="delete_experiment_set"
      value={@experiment_set.id}
    >
      <img src="/images/trashcan.svg" class="w-4 h-5" />
    </button>
    <div
      class={
        if @selected,
          do: "card block m-2 p-2 btn-primary-selected translate-x-6 duration-300",
          else: "card block m-2 p-2 btn-primary z-0"
      }
      phx-click={
        if @selected,
          do: "noop",
          else: "select_set"
      }
      phx-value-set-id={@experiment_set.id}
    >
      <div class="card-content">
        <p
          id={"experiment_set_name_#{@experiment_set.id}"}
          class="w-fit"
          phx-hook="auto_submit"
          value-rename-set-id={@experiment_set.id}
          value-original={@experiment_set.name}
          contenteditable={
            if @selected,
              do: "true",
              else: "false"
          }
        ><%= @experiment_set.name %></p>
        <p class="text-xs"><%= @experiment_set.updated_at %></p>
      </div>
    </div>
    """
  end
end
