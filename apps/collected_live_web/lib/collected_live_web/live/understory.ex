defmodule CollectedLiveWeb.UnderstoryLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket

  defmodule State do
    @default_source """
    @textbox jane@example.org
    .block w-full px-1
    .bg-white border

    @button Sign in
    .px-2 py-1
    .bg-blue-500
    """

    defstruct source: @default_source

    def change_source(state = %State{}, new_source) when is_binary(new_source) do
      %State{state | source: new_source}
    end
  end

  defmodule Parser do
    defmodule Block do
      defstruct type: :unknown, children: "", class: "", attributes: []

      def from_lines(["@textbox " <> rest | tail]) do
        %__MODULE__{
          type: :textbox,
          attributes: [
            value: rest |> String.trim()
          ]
        }
        |> parse_options(tail)
      end

      def from_lines(["@textbox" | tail]) do
        %__MODULE__{
          type: :textbox
        }
        |> parse_options(tail)
      end

      def from_lines(["@button " <> rest | tail]) do
        %__MODULE__{
          type: :button,
          children: rest
        }
        |> parse_options(tail)
      end

      def from_lines(["@button" | tail]) do
        %__MODULE__{
          type: :button,
          children: "Button"
        }
        |> parse_options(tail)
      end

      def from_lines(_lines) do
        %__MODULE__{}
      end

      defp add_class_name(block = %__MODULE__{class: ""}, class_name) do
        %__MODULE__{block | class: class_name}
      end

      defp add_class_name(block = %__MODULE__{class: class}, class_name) do
        %__MODULE__{block | class: "#{class} #{class_name}"}
      end

      defp parse_options(block, lines) do
        Enum.reduce(lines, block, fn
          "." <> class_name, block ->
            add_class_name(block, class_name) |> IO.inspect(label: "class found")

          _item, block ->
            block
        end)
        |> IO.inspect(label: "parse_options")
      end
    end

    def parse_string(source) when is_binary(source) do
      # source |> String.split("\n") |> parse_lines()
      source |> String.split(~r{\n\n+}, trim: true) |> Enum.map(&parse_block_string/1)
    end

    def parse_block_string(source) when is_binary(source) do
      source |> String.split("\n", trim: true) |> Block.from_lines()
    end
  end

  defmodule Preview do
    alias Parser.Block

    def present(blocks) do
      # blocks |> Enum.map(&Preview.present_block/1)
      blocks |> Enum.map(fn block -> present_block(block) end)
    end

    defp present_block(%Block{type: :textbox, class: class, attributes: attributes}) do
      tag(:input, attributes ++ [type: "text", class: class])
    end

    defp present_block(%Block{type: :button, class: class, children: children}) do
      content_tag(:button, children, class: class)
    end

    defp present_block(_) do
      content_tag(:div, "")
    end
  end

  def mount(%{}, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  defp present_source(source, :elements) do
    source
    |> Parser.parse_string()
    |> Preview.present()
    |> Enum.map(fn el -> content_tag(:div, el, class: "py-2") end)
  end

  defp present_source(source, :html_source) do
    elements = source |> Parser.parse_string() |> Preview.present()

    html_source =
      elements
      |> Enum.map(fn element -> element |> html_escape() |> safe_to_string() end)
      |> Enum.join("\n\n")
      |> html_escape()

    content_tag(:pre, html_source, class: "text-sm whitespace-pre-wrap")
  end

  def render(assigns) do
    state = assigns.state

    # assigns = Map.put(assigns, :cols, col_count)
    # assigns = Map.put(assigns, :rows, max_row + 2)

    ~L"""
    <div class="max-w-3xl mx-auto">
      <div class="flex flex-row">
        <div class="flex flex-row flex-grow">
          <%= form_tag "#", phx_change: "text-change", class: "flex-1" %>
            <%= label do %>
              <%= label_text "Define" %>
              <%= textarea(:define, :source,
                value: @state.source,
                phx_hook: "Autofocusing",
                rows: 20,
                class: "block w-full px-3 py-2 font-mono text-base border")
              %>
            <% end %>
          </form>
        </div>
        <div class="w-1/2">
          <%= label_text "Preview" %>
          <div class="bg-gray-200 border border-l-0 p-4">
          <%= @state.source |> present_source(:elements) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event(
        "text-change",
        %{"define" => %{"source" => new_source}},
        socket = %Socket{assigns: %{state: state}}
      ) do
    new_state = State.change_source(state, new_source)
    {:noreply, assign(socket, state: new_state)}
  end

  defp label_text(text) do
    content_tag(:span, text, class: "text-xs font-bold text-gray-500 uppercase tracking-wide")
  end
end
