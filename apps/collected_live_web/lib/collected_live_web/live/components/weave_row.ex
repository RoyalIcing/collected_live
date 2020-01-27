defmodule CollectedLiveWeb.Components.WeaveRow do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  alias CollectedLiveWeb.Components.WeaveCell

  def render(assigns) do
    first = Map.get(assigns.filled, {assigns.row, 0})

    case first do
      {:heading, text} ->
        render(:heading, Map.merge(assigns, %{text: text}))
      {:section, identifier} ->
        render(:section, Map.merge(assigns, %{identifier: identifier}))
      _ ->
        render(:cells, assigns)
    end
  end

  def render(:heading, assigns) do
    ~L"""
    <div class="flex flex-row h-18">
      <%= form_tag "#", phx_change: "heading-change", class: "flex-1" %>
        <%= label do %>
          <span class="text-xs text-gray-600 uppercase">Heading</span>
          <%= text_input(:heading, "#{@row}", value: @text, id: "weave-heading-#{@row}", phx_hook: "Autofocusing",
          class: "block w-full m-1 px-3 py-2 border")
          %>
        <% end %>
      </form>
    </div>
    """
  end

  def render(:section, assigns) do
    ~L"""
    <div class="flex flex-row h-18">
      <%= form_tag "#", phx_change: "section-change", class: "flex-1" %>
        <%= label do %>
          <span class="text-xs text-gray-600 uppercase">Section</span>
          <%= text_input(:section, "#{@row}", value: @identifier, id: "weave-section-#{@row}", phx_hook: "Autofocusing",
          class: "block w-full m-1 px-3 py-2 border")
          %>
        <% end %>
      </form>
    </div>
    """
  end

  def render(:cells, assigns) do
    ~L"""
    <div class="flex flex-row">
      <%= for col <- 0..@cols-1 do %>
        <%= live_component @socket, WeaveCell, row: @row, col: col, value: Map.get(@filled, {@row, col}) %>
      <% end %>
    </div>
    """
  end
end
