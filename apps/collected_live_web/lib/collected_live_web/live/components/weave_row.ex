defmodule CollectedLiveWeb.Components.WeaveRow do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  alias CollectedLiveWeb.Components.WeaveCell

  def render(assigns) do
    first = Map.get(assigns.filled, {0, assigns.row})

    case first do
      {:heading, text} ->
        assigns = Map.put(assigns, :text, text)
        render(:heading, assigns)
      _ ->
        render(:cells, assigns)
    end
  end

  def render(:heading, assigns) do
    ~L"""
    <div class="flex flex-row">
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

  def render(:cells, assigns) do
    ~L"""
    <div class="flex flex-row">
      <%= for col <- 0..@cols-1 do %>
        <%= live_component @socket, WeaveCell, col: col, row: @row, value: Map.get(@filled, {col, @row}) %>
      <% end %>
    </div>
    """
  end
end
