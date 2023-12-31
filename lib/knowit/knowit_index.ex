defmodule Knowit.KnowitIndex do
  import Ecto.Query
  alias Knowit.DB.{ExperimentSet, SemanticIndex}
  alias Knowit.Repo
  import Pgvector.Ecto.Query

  def normalizeAndSplit(text) do
    String.split(text, ~r'(?<=[a-z])(?=[A-Z])|[ _-]+')
    |> Enum.map(&String.downcase/1)
  end

  def insert_into_graph([origin, link, target], %ExperimentSet{} = experiment_set) do
    set_id = experiment_set.id
    link_label = String.replace(link, ~r/[\W_]+/, "")

    query_str = """
    SELECT *
    FROM cypher('knowit_graph', $$
      MERGE (a:node {set_id:#{set_id}, value:'#{origin}'})
      MERGE (b:node {set_id:#{set_id}, value:'#{target}'})
      MERGE (a)-[link:#{link_label} {set_id:#{set_id}, value:'#{link}'}]->(b)
      RETURN id(a), id(link), id(b)
    $$) as (a agtype, link agtype, b agtype);
    """

    {:ok, %Postgrex.Result{:rows => rows}} = Repo.query(query_str, [])
    rows
  end

  defp semanticIndex(text, obj_id) do
    %{embedding: %Nx.Tensor{} = embedding} =
      Nx.Serving.batched_run(Knowit.Serving.TextToVec, text)

    %SemanticIndex{embedding: embedding, content: text, graph_id: obj_id}
    |> SemanticIndex.changeset()
    |> Repo.insert(on_conflict: :nothing)
  end

  def insert_triple([origin_raw, link_raw, target_raw], %ExperimentSet{} = experiment_set) do
    origin = normalizeAndSplit(origin_raw) |> Enum.join(" ")
    link = normalizeAndSplit(link_raw) |> Enum.join(" ")
    target = normalizeAndSplit(target_raw) |> Enum.join(" ")

    [[origin_id, link_id, target_id] = triple_ids] =
      insert_into_graph([origin, link, target], experiment_set)

    # TODO: Fix NX batched_run to run concurrently:
    # Task.await_many([
    #   Task.async(fn -> semanticIndex(origin, origin_id) end),
    #   Task.async(fn -> semanticIndex(link, link_id) end),
    #   Task.async(fn -> semanticIndex(target, target_id) end)
    # ])
    semanticIndex(origin, origin_id)
    semanticIndex(link, link_id)
    semanticIndex(target, target_id)

    triple_ids
  end

  defmacro exists_frag() do
    arguments = [
      """
      SELECT *
      FROM cypher('knowit_graph', $$
        MATCH (a)-[link]->(b)
        RETURN a.value, link.value, b.value, a.set_id
      $$) as (origin agtype, link agtype, target agtype, set_id agtype)
      """
    ]

    quote do: fragment(unquote_splicing(arguments))
  end

  def list_experiment(user, set_id) do
    if is_nil(set_id) do
      []
    else
      from(e in exists_frag(),
        join: s in ExperimentSet,
        on: s.id == e.set_id,
        where: s.id == ^set_id,
        where: s.user_id == ^user.id,
        select: [e.origin, e.link, e.target],
        preload: []
      )
      |> Repo.all()
    end
  end

  def searchSemanticRelevantGraphEntries(text) do
    %{embedding: %Nx.Tensor{} = embedding} =
      Nx.Serving.batched_run(Knowit.Serving.TextToVec, text)

    Repo.all(
      from i in SemanticIndex,
        select: %{content: i.content, graph_id: i.graph_id},
        order_by: cosine_distance(i.embedding, ^embedding),
        limit: 5
    )
  end

  def searchRelevantGraphEntries(hints) do
    query_str = Enum.join(hints, " | ")

    from(
      f in SemanticIndex,
      cross_join: q in fragment("to_tsquery('english', ?)", ^query_str),
      where: fragment("to_tsvector('english', ?) @@ ?", f.content, q),
      order_by: [
        desc: fragment("ts_rank_cd(to_tsvector('english', ?), ?)", f.content, q)
      ],
      limit: 5,
      select: %{graph_id: f.graph_id}
    )
    |> Repo.all()
  end

  def findRelevantData(ids) do
    id_list = Enum.join(ids, ",")

    query_str = """
    SELECT *
    FROM cypher('knowit_graph', $$
      MATCH path = (a:node)-[*]->(b:node)
      WHERE id(a) in [#{id_list}] and id(b) in [#{id_list}]
      RETURN a, b, COLLECT(DISTINCT path) AS paths
    $$) as (a agtype, b agtype, path agtype);
    """

    {:ok, %Postgrex.Result{:rows => rows}} = Repo.query(query_str, [])
    rows
  end

  def findRelevantDataPGR(ids) do
    id_list = Enum.join(ids, ",")

    # run dijkstra on the permutation of the keywords and re-join nodes and edges
    # the return need to be exploded (unnest) due mixed type (agtype[]) in Postgrex.Types
    query_str = """
    WITH D AS (
        SELECT * FROM pgr_dijkstra(
        'SELECT * FROM cypher(''knowit_graph'', $$ MATCH (n)-[v]->(m) RETURN id(v), id(n), id(m), 1.0 $$) as (id bigint, source bigint, target bigint, cost float)',
        ARRAY[#{id_list}],
        ARRAY[#{id_list}],
        directed := true
        )
    ), N AS (
        SELECT * FROM cypher('knowit_graph', $$
            MATCH (n)
            RETURN id(n), n $$
        ) as (id bigint, node agtype)
    ), E AS (
        SELECT * FROM cypher('knowit_graph', $$
            MATCH ()-[e]-()
            RETURN id(e), e $$
        ) as (id bigint, edge agtype)
    ), D_AGE AS (
        SELECT
            D.seq,
            D.path_seq,
            D.start_vid,
            D.end_vid,
            N.node,
            E.edge,
            D.cost,
            D.agg_cost
        FROM D JOIN N ON N.id = D.node JOIN E ON E.id = D.edge
    )
    SELECT start_vid, end_vid, unnest(flatMap(ARRAY[node, edge])) AS path FROM D_AGE GROUP BY start_vid, end_vid;
    """

    {:ok, %Postgrex.Result{:rows => rows}} = Repo.query(query_str, [])
    rows
  end

  def findRelatedDataFromKeywords(keywords) do
    keywords
    |> searchRelevantGraphEntries()
    |> Enum.map(& &1.graph_id)
    |> findRelevantDataPGR()
  end
end
