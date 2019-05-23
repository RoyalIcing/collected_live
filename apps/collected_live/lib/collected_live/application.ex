defmodule CollectedLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # {Cachex, [:content_cache, []]}
      # Supervisor.child_spec({Cachex, {:content_cache, []}}, id: :content_cache)
      %{
        id: :content_cache,
        start: {Cachex, :start_link, [:content_cache, []]}
      }
      # CollectedLive.Worker
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: CollectedLive.Supervisor)
  end
end
