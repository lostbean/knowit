defmodule Knowit.Serving.OpenAI do
  # use Task

  # def start_link(arg) do
  #   Task.start_link(__MODULE__, :run, [arg])
  # end

  def extract_knowledge_graph(content) do
    # chat_completion with standard config
    {:ok, res} =
      OpenAI.chat_completion(
        model: "gpt-3.5-turbo",
        temperature: 0.2,
        messages: [
          %{
            role: "system",
            content:
              """
              You are a knowledge graph specialist. Your objective \
              is to extract RDF triples from the text using properties \
              and types defined in Schema.org . Make the output simple \
              and only list the triples as JSON lists.
              """
          },
          # %{role: "assistant", content: "[[John, drives, Tesla], [Tesla, has color, green], [John, has grilfriend, Ana]]"},
          %{role: "user", content: content}
        ]
      )

    Enum.map(res.choices, & &1["message"]["content"])
    |> Enum.flat_map(&String.split(&1, "\n"))
    |> Enum.join()
    |> Jason.decode!()
  end

  def interview_questions() do
    {:ok, res} =
      OpenAI.chat_completion(
        model: "gpt-3.5-turbo",
        messages: [
          %{role: "system", content: "Your a repoter"},
          %{role: "user", content: "Make 5 objective questions to know me better"}
        ]
      )

    Enum.map(res.choices, & &1["message"]["content"]) |> Enum.flat_map(&String.split(&1, "\n"))
  end
end
