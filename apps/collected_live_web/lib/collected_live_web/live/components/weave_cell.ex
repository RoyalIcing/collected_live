defmodule CollectedLiveWeb.Components.WeaveCell do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  def render(assigns = %{value: {:fill, fill}}) do
    ~L"""
    <svg viewBox="0 0 1 1"
      tabindex="0" onclick="focus()"
      phx-click="slot-click"
      phx-focus="slot-focus"
      phx-blur="slot-blur"
      phx-keyup="slot-keyup"
      phx-value-col="<%= @col %>" phx-value-row="<%= @row %>"
      class="
        block
        w-16 h-16
        m-1 px-2 rounded
        bg-gray-500
        border border-grey-500
        focus:border-blue-500
        focus:outline-none
      "
    >
      <rect width="1" height="1" fill="<%= fill %>" />
    </svg>
    """
  end

  def render(assigns) do
    ~L"""
    <button
      tabindex="0" onclick="focus()"
      phx-click="slot-click"
      phx-focus="slot-focus"
      phx-blur="slot-blur"
      phx-keyup="slot-keyup"
      phx-value-col="<%= @col %>" phx-value-row="<%= @row %>"
      class="
        block
        w-16 h-16
        m-1 px-2 rounded
        border border-grey-500
        focus:border-blue-500
        focus:outline-none
      "
    >
      <%= @value || raw("&nbsp;") %>
    </button>
    """
  end
end
