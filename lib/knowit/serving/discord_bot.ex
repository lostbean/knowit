defmodule Knowit.Serving.DiscordBot do
  use Nostrum.Consumer
  alias Nostrum.Api
  require Logger

  @topic inspect(__MODULE__)

  def subscribe do
    KnowitWeb.Endpoint.subscribe(@topic)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    Logger.warn("from #{msg.author.username}: #{msg.content}")
    KnowitWeb.Endpoint.broadcast_from(self(), @topic, "msg", msg)

    case msg.content do
      "!sleep" ->
        Api.create_message(msg.channel_id, "Going to sleep...")
        # This won't stop other events from being handled.
        Process.sleep(3000)

      "!ping" ->
        Api.create_message(msg.channel_id, "pyongyang!")

      "!raise" ->
        # This won't crash the entire Consumer.
        raise "No problems here!"

      _ ->
        :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end