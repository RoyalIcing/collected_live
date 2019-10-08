defmodule CollectedLiveWeb.SVGLive do
  use Phoenix.LiveView
  require Logger

  @available_logos [
    "atlassian",
    "apple",
    "microsoft",
    "react",
    "typescript",
    "d3",
    "graphql",
    "gopher",
    # "elixir",
    "rust",
    "erlang",
    "aws-s3",
    "cloudflare",
    "google-cloud-run",
    "github",
    "gitlab",
    "bitbucket",
    "firefox",
    "font-awesome",
    "gatsby",
  ]

  @available_colors [
    {nil, "original", %{inactive: "bg-gray-200 border border-gray-300", active: "text-white bg-gray-700 border border-gray-800"}},
    {"black", "black", %{inactive: "bg-gray-400 border border-gray-500", active: "text-white bg-gray-700 border border-gray-800"}},
    {"white", "white", %{inactive: "bg-white border border-gray-300", active: "text-white bg-gray-600 border border-gray-700"}},
    {"#9f7aea", "purple", %{inactive: "bg-purple-300 border border-purple-400", active: "text-white bg-purple-700 border border-purple-800"}},
    {"red", "red", %{inactive: "bg-red-300 border border-red-400", active: "text-white bg-red-700 border border-red-800"}},
    {"orange", "orange", %{inactive: "bg-orange-300 border border-orange-400", active: "text-white bg-orange-700 border border-orange-800"}},
    {"yellow", "yellow", %{inactive: "bg-yellow-300 border border-yellow-400", active: "text-white bg-yellow-700 border border-yellow-800"}},
    {"green", "green", %{inactive: "bg-green-300 border border-green-400", active: "text-white bg-green-700 border border-green-800"}},
    {"lightblue", "light blue", %{inactive: "bg-blue-300 border border-blue-400", active: "text-white bg-blue-700 border border-blue-800"}}
  ]

  def svg_url(assigns) do
    query =
      URI.encode_query(
        case assigns.color do
          nil -> []
          value -> [fill: value]
        end
      )

    Enum.join([
      "https://collected.systems/1/github/gilbarbara/logos/93e29467eea30b2981187822143f45e562662b5c/logos/",
      assigns.logo,
      ".svg",
      case query do
        "" -> ""
        something -> "?" <> something
      end
    ])
  end

  def render(assigns) do
    assigns = Map.put(assigns, :available_colors, @available_colors)
    assigns = Map.put(assigns, :available_logos, @available_logos)

    ~L"""
    <div class="my-2">
      <%= for logo <- @available_logos do %>
        <button phx-click="change_logo" phx-value-name="<%= logo %>" class="
        mb-1 px-2 rounded
        <%= if logo == @logo, do: "text-white bg-gray-700 border border-gray-800", else: "text-black bg-gray-300 border border-gray-400" %>
        "><%= logo %></button>
      <% end %>
    </div>

    <div class="my-2">
      <%= for {color, title, %{active: active, inactive: inactive}} <- @available_colors do %>
        <button phx-click="change_color" phx-value-color="<%= color || "" %>" class="
        px-2 rounded
        <%= if color == @color, do: active, else: inactive %>
        "><%= title %></button>
      <% end %>
    </div>

    <div class="py-4 bg-gray-200">
      <img src="<%= svg_url(%{ logo: @logo, color: @color }) %>" class="block mx-auto">
    </div>
    <pre class="px-2 py-1 text-sm break-words bg-gray-200"><a href="<%= svg_url(%{ logo: @logo, color: @color }) %>" class="hover:underline"><%= svg_url(%{ logo: @logo, color: @color }) %></a></pre>
    """
  end

  # defp new_uuid do
  #   Ecto.UUID.generate
  # end

  def mount(%{}, socket) do
    # if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    {:ok, assign(socket, color: nil, logo: "atlassian")}
  end

  # def handle_info(:update, socket) do
  #   {:noreply, assign(socket, :uuid, new_uuid())}
  # end

  def handle_event("change_color", %{"color" => ""}, socket) do
    {:noreply, assign(socket, color: nil)}
  end

  def handle_event("change_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, color: color)}
  end

  def handle_event("change_logo", %{"name" => name}, socket) do
    {:noreply, assign(socket, logo: name)}
  end
end
