defmodule Knowit.Serving.OpenAI do
  # use Task

  # def start_link(arg) do
  #   Task.start_link(__MODULE__, :run, [arg])
  # end

  def run(_arg) do
    OpenAI.chat_completion(
      model: "gpt-3.5-turbo",
      messages: [
        %{role: "system", content: "Your a repoter"},
        %{role: "user", content: "Make 5 objective questions to know me better"}
        # %{role: "assistant", content: "[[John, drives, Tesla], [Tesla, has color, green], [John, has grilfriend, Ana]]"},
        # %{role: "user", content: "Tesla Inc (Tesla) is an automotive and energy company. It designs, develops, manufactures, sells, and leases electric vehicles, energy generation, and storage systems. The company produces and sells the Model Y, Model 3, Model X, Model S, Cybertruck, Tesla Semi, and Tesla Roadster vehicles."},
      ]
    )
  end
end
