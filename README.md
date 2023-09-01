# Knowit

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Init DB

For local DB (need to install pgvector and age) use: 

```bash
initdb -D .pg_data/knowit_dev
pg_ctl -D .pg_data/knowit_dev -l logfile start
createuser postgres
createdb knowit_dev
```

Or use remote DB by setting URL using the env var `DATABASE_URL`.

For Fly.IO, set proxy using

```bash
flyctl proxy 15432:5432 -a <db-app>
```

Start server:

```bash
mix phx.server
```

## Adding JS deps

```bash
cd assets/
npm install <PACKAGE_NAME> --save
```

## Building with NIX

Building docker image with nix-shell.

```bash
docker build -f nix.Dockerfile -t test .
```

## References

  * Speech to text: https://github.com/elixir-nx/bumblebee/blob/main/examples/phoenix/speech_to_text.exs#L257
  * NX serving: https://github.com/seanmor5/phoenix_chatgpt_plugin/blob/main/lib/phoenix_chatgpt_plugin/application.ex
  * Using nix-shell to set docker env: https://stackoverflow.com/a/58436890
  * Graph with compound nodes: https://github.com/cytoscape/cytoscape.js/blob/master/documentation/demos/compound-nodes/code.js
  *  

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
