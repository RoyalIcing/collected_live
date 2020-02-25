defmodule CollectedLiveWeb.ShapedLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket
  alias CollectedLive.HTTPClient

  @heroicons_sha "2abb8143c5cf89633d38565b2df44a392bd3d2fd"

  defp heroicons_svg_url(group, name) do
    "https://cdn.jsdelivr.net/gh/refactoringui/heroicons@#{@heroicons_sha}/src/#{group}/#{name}.svg"
  end

  defmodule State do
    defstruct size: 24, base_color: "black", cells: %{}

    def make_arrow_24() do
      vertical_stem =
        for y <- 4..21 do
          for x <- 12..13 do
            {{x, y}, :whole}
          end
        end

      diagonals =
        for offset <- 0..6 do
          [
            # Left
            {{5 + offset, 15 + offset}, {:diagonal, :ne}},
            {{5 + offset, 14 + offset}, :whole},
            {{5 + offset, 13 + offset}, :whole},
            {{6 + offset, 13 + offset}, {:diagonal, :sw}},
            # Right
            {{20 - offset, 15 + offset}, {:diagonal, :nw}},
            {{20 - offset, 14 + offset}, :whole},
            {{20 - offset, 13 + offset}, :whole},
            {{19 - offset, 13 + offset}, {:diagonal, :se}}
          ]
        end

      caps = [
        {{12, 3}, {:diagonal, :se, arc: true}},
        {{13, 3}, {:diagonal, :sw, arc: true}},
        {{12, 22}, {:diagonal, :ne, we: true}},
        {{13, 22}, {:diagonal, :nw, we: true}}
      ]

      pairs = [diagonals, vertical_stem, caps] |> List.flatten()
      cells = Map.new(pairs)

      %State{
        size: 24,
        cells: cells
      }
    end

    def at_x_y(state = %State{}, x, y) do
      Map.get(state.cells, {x, y})
    end

    def assign_row_col(state = %State{}, row, col, value) do
      cells = Map.put(state.cells, {row, col}, value)
      %State{state | cells: cells}
    end
  end

  def mount(%{}, socket) do
    state = State.make_arrow_24()

    {:ok, assign(socket, state: state)}
  end

  defp fill_at_x_y(state = %State{}, x, y) do
    cell = State.at_x_y(state, x, y)

    case cell do
      :whole -> state.base_color
      _ -> "transparent"
    end
  end

  defp render_x_y(state = %State{}, x, y) do
    state |> State.at_x_y(x, y) |> render_x_y(state, x, y)
  end

  defp render_x_y(:whole, state = %State{}, x, y) do
    content_tag(:rect, "",
      x: x - 1,
      y: y - 1,
      width: 1,
      height: 1,
      fill: state.base_color
    )
  end

  defmodule Diagonal do
    defstruct direction: :ne, we: false, arc: false

    def from_tuple({:diagonal, direction, options}) do
      %Diagonal{
        direction: direction,
        we: Keyword.get(options, :we, false),
        arc: Keyword.get(options, :arc, false)
      }
    end

    def to_svg_element(%Diagonal{direction: :ne, we: we}, x, y, fill) do
      case we do
        false ->
          content_tag(:polygon, "",
            points: "#{x - 1},#{y - 1} #{x},#{y - 1} #{x},#{y}",
            fill: fill
          )

        true ->
          content_tag(:path, "",
            d: "M#{x - 1},#{y - 1} q0.5,0.5 1,0.5 l0,-0.5",
            fill: fill
          )
      end
    end

    def to_svg_element(%Diagonal{direction: :nw, we: we}, x, y, fill) do
      case we do
        false ->
          content_tag(:polygon, "",
            points: "#{x - 1},#{y - 1} #{x - 1},#{y} #{x},#{y - 1}",
            fill: fill
          )

        true ->
          content_tag(:path, "",
            d: "M#{x},#{y - 1} q-0.5,0.5 -1,0.5 l0,-0.5",
            fill: fill
          )
      end
    end

    def to_svg_element(%Diagonal{direction: :sw, arc: arc}, x, y, fill) do
      case arc do
        false ->
          content_tag(:polygon, "",
            points: "#{x - 1},#{y - 1} #{x},#{y} #{x - 1},#{y}",
            fill: fill
          )

        true ->
          content_tag(:path, "",
            d: "M#{x - 1},#{y - 1} Q#{x},#{y - 1} #{x},#{y} L#{x - 1},#{y}",
            fill: fill
          )
      end
    end

    def to_svg_element(%Diagonal{direction: :se, arc: arc}, x, y, fill) do
      case arc do
        false ->
          content_tag(:polygon, "",
            points: "#{x},#{y} #{x - 1},#{y} #{x},#{y - 1}",
            fill: fill
          )

        true ->
          content_tag(:path, "",
            d: "M#{x},#{y - 1} Q#{x - 1},#{y - 1} #{x - 1},#{y} L#{x},#{y}",
            fill: fill
          )
      end
    end
  end

  defp render_x_y({:diagonal, direction}, state = %State{}, x, y),
    do: render_x_y({:diagonal, direction, []}, state, x, y)

  defp render_x_y({:diagonal, _direction, _options} = tuple, state = %State{}, x, y) do
    tuple
    |> Diagonal.from_tuple()
    |> Diagonal.to_svg_element(x, y, state.base_color)
  end

  defp render_x_y(_, _state = %State{}, x, y) do
    content_tag(:rect, "",
      x: x - 1,
      y: y - 1,
      width: 1,
      height: 1,
      fill: "transparent"
    )
  end

  def render(assigns) do
    max_x = assigns.state.size + 1
    max_y = assigns.state.size + 1

    ~L"""
    <div class="max-w-4xl mx-auto text-center">
      <div class="relative mb-4">
        <img
          src="<%= heroicons_svg_url("solid-sm", "sm-arrow-down") %>"
          alt=""
          width="800"
          class="top-0"
          style="border: 2px solid black"
        >
        <svg
          width="800" height="800" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
          class="absolute z-10 top-0"
        >
          <%= for x <- 1..24 do %>
            <%= for y <- 1..24 do %>
              <rect
                x="<%= x - 1 %>"
                y="<%= y - 1 %>"
                width="1"
                height="1"
                fill="transparent"
                stroke="#ddd"
                stroke-width="0.05"
              />
            <% end %>
          <% end %>
        </svg>
      </div>

      <svg
        height="800" viewBox="0 0 <%= @state.size + 100 %> <%= @state.size %>"
        xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
      >
        <g id="grid">
          <%= for x <- 1..max_x do %>
            <%= for y <- 1..max_y do %>
              <rect
                x="<%= x - 1 %>"
                y="<%= y - 1 %>"
                width="1"
                height="1"
                fill="transparent"
                stroke="#ddd"
                stroke-width="0.05"
              />
            <% end %>
          <% end %>
        </g>

        <g id="main">
          <%= for x <- 1..max_x do %>
            <%= for y <- 1..max_y do %>
              <%= render_x_y(@state, x, y) %>
            <% end %>
          <% end %>
        </g>

        <use xlink:href="#main" transform="translate(<%= @state.size + 1 %> 0) scale(0.25 0.25)" />
      </svg>
    </div>
    """
  end
end
