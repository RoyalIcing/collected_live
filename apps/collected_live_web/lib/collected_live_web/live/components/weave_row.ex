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

      {:list, items} ->
        render(:list, Map.merge(assigns, %{items: items}))

      {:checklist, items} ->
        render(:checklist, Map.merge(assigns, %{items: items}))

      {:button, title} ->
        render(:button, Map.merge(assigns, %{title: title}))

      _ ->
        render(:cells, assigns)
    end
  end

  defp label_text(text) do
    content_tag(:span, text, class: "text-xs font-bold text-gray-500 uppercase tracking-wide")
  end

  defp render(:heading, assigns) do
    ~L"""
    <div class="flex flex-row h-18">
      <%= form_tag "#", phx_change: "heading-change", class: "flex-1" %>
        <%= label do %>
          <%= label_text "Heading" %>
          <%= text_input(:heading, "#{@row}", value: @text, id: "weave-heading-#{@row}", phx_hook: "Autofocusing",
          class: "block w-full m-1 px-3 py-2 border")
          %>
        <% end %>
      </form>
    </div>
    """
  end

  defp render(:section, assigns) do
    ~L"""
    <div class="flex flex-row h-18">
      <%= form_tag "#", phx_change: "section-change", class: "flex-1" %>
        <%= label do %>
          <%= label_text "Section" %>
          <%= text_input(:section, "#{@row}",
            value: @identifier,
            id: "weave-section-#{@row}",
            phx_hook: "Autofocusing",
            class: "block w-full m-1 px-3 py-2 border")
          %>
        <% end %>
      </form>
    </div>
    """
  end

  defp render(:list, assigns) do
    ~L"""
    <div class="flex flex-row h-18 overflow-scroll">
      <%= form_tag "#", phx_change: "list-change", class: "flex-1" %>
        <%= label class: "p-1" do %>
          <%= label_text "List" %>
          <%= for item <- @items do %>
            <%= text_input(:list, "#{@row}", value: item, id: "weave-list-#{@row}-n", class: "block w-full my-1 px-3 py-1 text-sm border") %>
          <% end %>
          <%= text_input(:list, "#{@row}", value: "", id: "weave-list-#{@row}-new", class: "block w-full my-1 px-3 py-1 text-sm border") %>
        <% end %>
      </form>
    </div>
    """
  end

  defp render(:checklist, assigns) do
    ~L"""
    <div class="flex flex-row h-18 overflow-scroll">
      <%= form_tag "#", phx_change: "checklist-change", class: "flex-1" %>
        <%= label_text "Checklist" %>
        <%= for item <- @items do %>
          <%= label class: "flex flex-row items-center" do %>
            <%= checkbox(:list, "#{@row}") %>
            <%= text_input(:list, "#{@row}", value: item, id: "weave-list-#{@row}-n", class: "flex-1 ml-2 my-1 px-3 py-1 text-sm border") %>
          <% end %>
        <% end %>
      </form>
    </div>
    """
  end

  defp render(:button, assigns) do
    ~L"""
    <div class="flex flex-row h-18">
      <%= form_tag "#", phx_change: "button-title-change", class: "flex-1" %>
        <%= label do %>
          <%= label_text "Button" %>
          <%= text_input(:button, "#{@row}",
            value: @title,
            id: "weave-button-#{@row}",
            phx_hook: "Autoselecting",
            class: "block w-full m-1 px-3 py-2 border")
          %>
        <% end %>
      </form>
    </div>
    """
  end

  defp render(:cells, assigns) do
    ~L"""
    <div class="flex flex-row">
      <%= for col <- 0..@cols-1 do %>
        <%= live_component @socket, WeaveCell, row: @row, col: col, value: Map.get(@filled, {@row, col}) %>
      <% end %>
    </div>
    """
  end
end
