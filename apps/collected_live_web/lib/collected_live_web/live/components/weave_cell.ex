defmodule CollectedLiveWeb.Components.WeaveCell do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  def render(assigns = %{value: {:fill, fill}}) do
    ~L"""
    <svg viewBox="0 0 1 1"
      tabindex="0" onclick="focus()"
      width="4.5rem" height="4.5rem"
      phx-click="slot-click"
      phx-focus="slot-focus"
      phx-blur="slot-blur"
      phx-keyup="slot-keyup"
      phx-value-col="<%= @col %>" phx-value-row="<%= @row %>"
      class="
        block
        border border-white
        focus:border-blue-500
        focus:outline-none
      "
    >
      <rect width="1" height="1" fill="<%= fill %>" />
    </svg>
    """
  end

  def render(assigns = %{value: {:fill, 2, 2, {a, b, c, d}}}) do
    at = fn
      0 -> a
      1 -> b
      2 -> c
      3 -> d
    end

    ~L"""
    <div
      class="flex flex-row flex-wrap" style="width: 4.5rem; height: 4.5rem;">
      <%= for index <- 0..3 do %>
        <svg viewBox="0 0 1 1"
          tabindex="0" onclick="focus()"
          width="2.25rem" height="2.25rem"
          tabindex="0" onclick="focus()"
          phx-click="slot-click"
          phx-focus="slot-focus"
          phx-blur="slot-blur"
          phx-keyup="slot-keyup"
          phx-value-col="<%= @col %>" phx-value-row="<%= @row %>"
          phx-value-subindex="<%= index %>"
          class="
            block
            bg-gray-500
            border border-white
            focus:border-blue-500
            focus:outline-none
          "
        >
          <rect width="1" height="1" fill="<%= at.(index) %>" />
        </svg>
      <% end %>
    </div>
    """
  end

  def render(assigns = %{value: {:math, equation}}) do
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
          focus:border-blue-500
          focus:outline-none
        "
    >
      <svg viewBox="0 0 32 32"
        class="
          block
          w-16 h-16
          m-1 px-2 rounded
          bg-blue-200
          border border-grey-500
        "
      >
        <text x="16" y="20" text-anchor="middle" class="text-xs"><%= equation %></text>
      </svg>
    </button>
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
        text-gray-400
        border border-grey-500
        focus:border-blue-500
        focus:outline-none
      "
    >
      <%= @value || "·" %>
    </button>
    """
  end
end
