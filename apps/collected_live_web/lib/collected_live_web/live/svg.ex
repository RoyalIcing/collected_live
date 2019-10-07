defmodule CollectedLiveWeb.SVGLive do
  use Phoenix.LiveView
  require Logger

  @available_logos [
    "atlassian",
    "apple",
    "microsoft",
    "react",
    "typescript",
    "elixir",
    "rust",
    "erlang",
    "aws-s3",
    "cloudflare",
    "google-cloud-run",
    "github",
    "gitlab",
    "bitbucket",
  ]

  @available_colors [
    {"black", "bg-gray-400"},
    {"red", "bg-red-300"},
    {"orange", "bg-orange-300"},
    {"blue", "bg-blue-300"},
  ]

  def render(assigns) do
    assigns = Map.put(assigns, :available_colors, @available_colors)
    assigns = Map.put(assigns, :available_logos, @available_logos)

    ~L"""
    UUID: <%= @uuid %>

    <div>
      <img src="https://collected.systems/1/github/gilbarbara/logos/93e29467eea30b2981187822143f45e562662b5c/logos/<%= @logo %>.svg?fill=<%= @color %>">
    </div>
    <pre class="break-words">https://collected.systems/1/github/gilbarbara/logos/93e29467eea30b2981187822143f45e562662b5c/logos/<%= @logo %>.svg?fill=<%= @color %></pre>

    <div class="my-2">
      <%= for name <- @available_logos do %>
        <button phx-click="change_logo" phx-value-name="<%= name %>" class="px-2 rounded bg-gray-300"><%= name %></button>
      <% end %>
    </div>

    <div class="my-2">
      <%= for {color, class} <- @available_colors do %>
        <button phx-click="change_color" phx-value-color="<%= color %>" class="px-2 rounded <%= class %>"><%= color %></button>
      <% end %>
    </div>
    """
  end

  defp new_uuid do
    Ecto.UUID.generate
  end

  def mount(%{}, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    {:ok, assign(socket, uuid: new_uuid(), color: "red", logo: "atlassian")}
  end

  def handle_info(:update, socket) do
    {:noreply, assign(socket, :uuid, new_uuid())}
  end

  def handle_event("change_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, color: color)}
  end

  def handle_event("change_logo", %{"name" => name}, socket) do
    {:noreply, assign(socket, logo: name)}
  end
end
