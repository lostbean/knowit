# syntax = docker/dockerfile:1.2
 
# Nix builder
FROM nixos/nix:latest AS builder

# Copy our source and setup our working dir.
WORKDIR /app

ENV LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

COPY mix.exs mix.lock ./
COPY config config
COPY priv priv
COPY lib lib
COPY assets assets
COPY rel rel
COPY rel rel
COPY shell.nix .

RUN nix-env -f shell.nix -i -A nativeBuildInputs

# set build ENV
ENV MIX_ENV="prod"
ENV BUMBLEBEE_CACHE_DIR=/app/.bumblebee
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# and install node (support JS asset install -- https://community.fly.io/t/elixir-alpinejs-on-fly-fail-to-install/5542/21)
RUN npm install --prefix assets/
# compile assets
RUN mix assets.deploy

RUN mix release

ENV DATABASE_URL="ecto://postgres:postgres@localhost.test/ecto_simple"
ENV SECRET_KEY_BASE="xxxxxx"
RUN mix run -e 'Knowit.Serving.AudioToText.serving()' || echo 'Failed'

# # Final image is based on scratch. We copy a bunch of Nix dependencies
# # but they're fully self-contained so we don't need Nix anymore.
FROM scratch

WORKDIR /app

ENV MIX_ENV="prod"
ENV BUMBLEBEE_CACHE_DIR=/app/.bumblebee
ENV BUMBLEBEE_OFFLINE=true

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/knowit ./
COPY --from=builder --chown=nobody:root ${BUMBLEBEE_CACHE_DIR} ${BUMBLEBEE_CACHE_DIR}

CMD ["/app/bin/server"]