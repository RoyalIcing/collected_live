FROM gcr.io/gcp-elixir/runtime/builder

RUN apt-get update -y \
    && apt-get install -y -q clang clang-tools llvm cargo \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_*

RUN asdf plugin-update erlang \
    && asdf install erlang 22.0.4 \
    && asdf global erlang 22.0.4

RUN asdf plugin-update elixir \
    && asdf install elixir 1.8.2 \
    && asdf global elixir 1.8.2 \
    && mix local.hex --force \
    && mix local.rebar --force

COPY . /app/

RUN mix do deps.get, deps.compile, compile
