defmodule CollectedLiveWeb.WeaveLive do
  use CollectedLiveWeb, :live_view
  require Logger

  defmodule State do
    defstruct filled: %{}, focused: nil

    def max_row(state = %State{}) do
      default = fn -> {{nil, 0}, nil} end
      {{_col, row}, _value} = Enum.max_by(state.filled, fn({{_col, row}, _value}) -> row end, default)
      row
    end
  end

  alias CollectedLiveWeb.Components

  @cols 9

  def render(assigns) do
    state = assigns.state
    max_row = State.max_row(state)

    assigns = Map.put(assigns, :cols, @cols)
    assigns = Map.put(assigns, :rows, max_row + 2)
    # assigns = Map.put(assigns, :available_colors, @available_colors)

    ~L"""
    <div class="my-2">
      <%= for row <- 0..@rows-1 do %>
        <%= live_component @socket, Components.WeaveRow, cols: @cols, row: row, filled: @state.filled %>
      <% end %>
    </div>
    """
  end

  def mount(%{}, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  defp slot_payload(%{"col" => col_s, "row" => row_s}) do
    col = col_s |> String.to_integer
    row = row_s |> String.to_integer
    %{col: col, row: row}
  end

  def handle_event("slot-click", _payload, socket) do
    {:noreply, socket}
  end

  def handle_event("slot-focus", payload, socket) do
    %{col: col, row: row} = slot_payload(payload)

    state = socket.assigns.state
    state = %State{state | focused: {col, row}}

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("slot-blur", _payload, socket) do
    state = socket.assigns.state
    state = %State{state | focused: nil}

    {:noreply, assign(socket, state: state)}
  end

  defp slot_value_for_key("#") do
    {:heading, ""}
  end

  defp slot_value_for_key("1") do
    {:fill, "black"}
  end

  defp slot_value_for_key("+") do
    {:math, "1 + 1"}
  end

  def handle_event("slot-keyup", %{"key" => key}, socket) when key in ["#", "1", "+"] do
    state = socket.assigns.state
    filled = case state.focused do
      {col, row} -> Map.put(state.filled, {col, row}, slot_value_for_key(key))
      nil -> state.filled
    end

    state = %State{state | filled: filled}
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("slot-keyup", _, socket) do
    {:noreply, socket}
  end

  def handle_event("heading-change", %{"heading" => heading_changes}, socket) do
    state = socket.assigns.state
    filled = Enum.reduce(heading_changes, state.filled, fn {row_s, value}, filled ->
      row = row_s |> String.to_integer
      Map.put(filled, {0, row}, {:heading, value})
    end)

    state = %State{state | filled: filled}
    {:noreply, assign(socket, state: state)}
  end
end
