defmodule CollectedLiveWeb.WeaveLive do
  use CollectedLiveWeb, :live_view
  require Logger

  defmodule State do
    defstruct filled: %{}, focused: nil

    def max_row(state = %State{}) do
      default = fn -> {{0, nil}, nil} end
      {{row, _col}, _value} = Enum.max_by(state.filled, fn({{row, _col}, _value}) -> row end, default)
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

  defp slot_payload(%{"row" => row_s, "col" => col_s}) do
    row = row_s |> String.to_integer
    col = col_s |> String.to_integer
    %{row: row, col: col}
  end

  def handle_event("slot-click", _payload, socket) do
    {:noreply, socket}
  end

  def handle_event("slot-focus", payload, socket) do
    %{row: row, col: col} = slot_payload(payload)

    state = socket.assigns.state
    state = %State{state | focused: {row, col}}

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
      {row, col} -> Map.put(state.filled, {row, col}, slot_value_for_key(key))
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
      Map.put(filled, {row, 0}, {:heading, value})
    end)

    state = %State{state | filled: filled}
    {:noreply, assign(socket, state: state)}
  end
end
