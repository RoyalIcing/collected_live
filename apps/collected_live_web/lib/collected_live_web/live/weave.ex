defmodule CollectedLiveWeb.WeaveLive do
  use CollectedLiveWeb, :live_view
  require Logger

  defmodule State do
    defstruct filled: %{}, focused: nil

    def at_row_col(state = %State{}, row, col) do
      Map.get(state.filled, {row, col})
    end

    def assign_row_col(state = %State{}, row, col, value) do
      filled = Map.put(state.filled, {row, col}, value)
      %State{state | filled: filled}
    end

    def col_count(_state = %State{}) do
      7
    end

    def max_row(state = %State{}) do
      default = fn -> {{0, nil}, nil} end

      {{row, _col}, _value} =
        Enum.max_by(state.filled, fn {{row, _col}, _value} -> row end, default)

      row
    end
  end

  alias CollectedLiveWeb.Components

  def render(assigns) do
    state = assigns.state
    max_row = State.max_row(state)
    col_count = State.col_count(state)

    assigns = Map.put(assigns, :cols, col_count)
    assigns = Map.put(assigns, :rows, max_row + 2)
    # assigns = Map.put(assigns, :available_colors, @available_colors)

    ~L"""
    <div class="flex flex-row justify-center">
      <div class="my-2">
        <%= for row <- 0..@rows-1 do %>
          <div class="flex flex-row relative pl-6 pr-6 ml-4">
            <div class="self-center absolute left-0 font-mono"><%= row + 1 %></div>
            <div class="flex-1">
              <%= live_component @socket, Components.WeaveRow, cols: @cols, row: row, filled: @state.filled %>
            </div>
          </div>
        <% end %>
      </div>
      <div class="w-64 text-white bg-black">
        Preview
      </div>
    </div>
    """
  end

  def mount(%{}, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  defp slot_payload(%{"row" => row_s, "col" => col_s}) do
    row = row_s |> String.to_integer()
    col = col_s |> String.to_integer()
    %{row: row, col: col}
  end

  @empty_fill "#e2e8fd"

  defp flip_fill("black"), do: @empty_fill
  defp flip_fill(_), do: "black"

  def handle_event(
        "slot-click",
        %{"row" => row_s, "col" => col_s, "subindex" => subindex_s},
        socket
      ) do
    row = row_s |> String.to_integer()
    col = col_s |> String.to_integer()
    subindex = subindex_s |> String.to_integer()

    state = socket.assigns.state
    value = State.at_row_col(state, row, col)

    value =
      case value do
        {:fill, 2, 2, {a, b, c, d}} ->
          fills =
            case subindex do
              0 -> {flip_fill(a), b, c, d}
              1 -> {a, flip_fill(b), c, d}
              2 -> {a, b, flip_fill(c), d}
              3 -> {a, b, c, flip_fill(d)}
            end

          {:fill, 2, 2, fills}

        existing ->
          existing
      end

    state = State.assign_row_col(state, row, col, value)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "slot-click",
        %{"row" => row_s, "col" => col_s},
        socket
      ) do
    row = row_s |> String.to_integer()
    col = col_s |> String.to_integer()

    state = socket.assigns.state
    value = State.at_row_col(state, row, col)

    value =
      case value do
        {:fill, fill} ->
          {:fill, flip_fill(fill)}

        existing ->
          existing
      end

    state = State.assign_row_col(state, row, col, value)
    {:noreply, assign(socket, state: state)}
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

  @valid_keys ["#", "@", "-", "%", "x", "(", "1", "2", "+"]

  defp slot_value_for_key("#") do
    {:heading, ""}
  end

  defp slot_value_for_key("@") do
    {:section, ""}
  end

  defp slot_value_for_key("-") do
    {:list, ["First", "Second"]}
  end

  defp slot_value_for_key("%") do
    {:link, ""}
  end

  defp slot_value_for_key("x") do
    {:checklist, ["First", "Second"]}
  end

  defp slot_value_for_key("(") do
    {:button, ["Action"]}
  end

  defp slot_value_for_key("1") do
    {:fill, @empty_fill}
  end

  defp slot_value_for_key("2") do
    {:fill, 2, 2, {@empty_fill, @empty_fill, @empty_fill, @empty_fill}}
  end

  defp slot_value_for_key("+") do
    {:math, "1 + 1"}
  end

  defp convert_slot_sibling_for_key("1", existing = {:fill, fill}) do
    existing
  end

  defp convert_slot_sibling_for_key("1", _) do
    {:fill, @empty_fill}
  end

  defp convert_slot_sibling_for_key("2", existing = {:fill, 2, 2, fills}) do
    existing
  end

  defp convert_slot_sibling_for_key("2", {:fill, fill}) do
    {:fill, 2, 2, {fill, fill, fill, fill}}
  end

  defp convert_slot_sibling_for_key("2", _) do
    {:fill, 2, 2, {@empty_fill, @empty_fill, @empty_fill, @empty_fill}}
  end

  defp convert_slot_sibling_for_key(_, existing) do
    existing
  end

  def handle_event("slot-keyup", %{"key" => key}, socket) when key in @valid_keys do
    state = socket.assigns.state
    col_count = State.col_count(state)

    filled =
      case state.focused do
        {focused_row, focused_col} ->
          Enum.reduce(0..(col_count - 1), state.filled, fn
            ^focused_col, filled ->
              Map.put(filled, {focused_row, focused_col}, slot_value_for_key(key))

            col, filled ->
              Map.put(
                filled,
                {focused_row, col},
                convert_slot_sibling_for_key(key, State.at_row_col(state, focused_row, col))
              )
          end)

        # updated = Map.put(state.filled, {row, col}, slot_value_for_key(key))
        # Map.new(updated, fn
        #   {{^row, ^col}, slot} ->
        #     {{row, col}, slot}
        #   {{^row, other_col}, slot} ->
        #     {{row, other_col}, convert_slot_sibling_for_key(key, slot)}
        #   existing ->
        #     existing
        # end)
        nil ->
          state.filled
      end

    state = %State{state | filled: filled}
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("slot-keyup", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "heading-change",
        %{"heading" => heading_changes},
        socket = %{assigns: assigns}
      ) do
    state =
      Enum.reduce(heading_changes, assigns.state, fn {row_s, value}, state ->
        row = row_s |> String.to_integer()
        State.assign_row_col(state, row, 0, {:heading, value})
      end)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "section-change",
        %{"section" => section_changes},
        socket = %{assigns: assigns}
      ) do
    state =
      Enum.reduce(section_changes, assigns.state, fn {row_s, value}, state ->
        row = row_s |> String.to_integer()
        State.assign_row_col(state, row, 0, {:section, value})
      end)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "link-change",
        %{"link" => link_changes},
        socket = %{assigns: assigns}
      ) do
    state =
      Enum.reduce(link_changes, assigns.state, fn {row_s, value}, state ->
        row = row_s |> String.to_integer()
        State.assign_row_col(state, row, 0, {:link, value})
      end)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "button-title-change",
        %{"button" => button_changes},
        socket = %{assigns: assigns}
      ) do
    state =
      Enum.reduce(button_changes, assigns.state, fn {row_s, value}, state ->
        row = row_s |> String.to_integer()
        State.assign_row_col(state, row, 0, {:button, value})
      end)

    {:noreply, assign(socket, state: state)}
  end
end
