defmodule Knowit.Serving.AudioToText do
  @moduledoc """
  Audio to text transcription.

  Can be replaced with another open source model from HuggingFace
  or an API-based model such as OpenAI or Cohere.

  Note that even for external API-based models, it might still
  benefit to wrap the model in an Nx.Serving in order to get automatic
  batching. It's more efficient to send overlapping concurrent requests
  to the API at once rather than one at a time. Nx.Serving offers
  this functionality out of the box.
  """

  @doc """
  Whisper serving implementation.
  """
  def serving(opts \\ []) do

    batch_size = opts[:batch_size] || 10

    {:ok, model_info} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

    Bumblebee.Audio.speech_to_text(model_info, featurizer, tokenizer, generation_config,
      compile: [batch_size: batch_size],
      defn_options: [compiler: EXLA]
    )
  end
end
