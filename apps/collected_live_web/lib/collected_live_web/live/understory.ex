defmodule CollectedLiveWeb.UnderstoryLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket

  defmodule State do
    @default_source """
    @navigation Primary
    - @link Features
    - @link Pricing
    - @link Sign in
    - @link Join

    @textbox Email
    [value] jane@example.org
    .block w-full px-1
    .bg-white border

    @button Sign in
    .px-2 py-1
    .bg-blue-500
    """

    defstruct source: @default_source,
              preview: :elements

    defp line_endings_to_line_feed(source) when is_binary(source) do
      source |> String.replace(~r/\r\n/, "\n")
    end

    def change_source(state = %State{}, new_source) when is_binary(new_source) do
      %State{state | source: line_endings_to_line_feed(new_source)}
    end

    def change_preview_to_elements(state = %State{}) do
      %State{state | preview: :elements}
    end

    def change_preview_to_html(state = %State{}) do
      %State{state | preview: :html}
    end
  end

  defmodule Parser do
    defmodule Block do
      defstruct type: :unknown,
                children: [],
                list_items: [],
                class: "",
                attributes: [],
                errors: []

      def from_lines(["@link " <> text | tail]) do
        %__MODULE__{
          type: :link,
          children: [text],
          attributes: [href: "#"]
        }
        |> parse_options(tail)
      end

      def from_lines(["@link" | tail]) do
        %__MODULE__{
          type: :link,
          children: ["Link"],
          attributes: [href: "#"]
        }
        |> parse_options(tail)
      end

      def from_lines(["@textbox " <> rest | tail]) do
        %__MODULE__{
          type: :textbox,
          children: [rest |> String.trim()]
        }
        |> parse_options(tail)
      end

      def from_lines(["@textbox" | tail]) do
        %__MODULE__{
          type: :textbox
        }
        |> parse_options(tail)
      end

      def from_lines(["@checkbox " <> rest | tail]) do
        %__MODULE__{
          type: :checkbox,
          children: [rest |> String.trim()]
        }
        |> parse_options(tail)
      end

      def from_lines(["@checkbox" | tail]) do
        %__MODULE__{
          type: :checkbox
        }
        |> parse_options(tail)
      end

      def from_lines(["@button " <> title | tail]) do
        %__MODULE__{
          type: :button,
          children: [title]
        }
        |> parse_options(tail)
      end

      def from_lines(["@button" | tail]) do
        %__MODULE__{
          type: :button,
          children: ["Button"]
        }
        |> parse_options(tail)
      end

      def from_lines(["@navigation " <> label | tail]) do
        %__MODULE__{
          type: :navigation,
          attributes: ["aria-label": label]
        }
        |> parse_options(tail)
      end

      def from_lines(["@navigation" | tail]) do
        %__MODULE__{
          type: :navigation
        }
        |> parse_options(tail)
      end

      def from_lines(["@" <> unknown_role]) do
        %__MODULE__{
          type: :unknown,
          errors: [
            case unknown_role do
              "" -> "Missing role"
              s -> "Unknown role: #{s}"
            end
          ]
        }
      end

      def from_lines([text | tail]) do
        %__MODULE__{
          type: :text,
          children: [text]
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

      defp add_list_item(block = %__MODULE__{list_items: list_items}, raw_item) do
        parsed_item = from_lines([raw_item])
        %__MODULE__{block | list_items: list_items ++ [parsed_item]}
      end

      defp add_attribute(block = %__MODULE__{attributes: attributes}, name, value) do
        %__MODULE__{block | attributes: attributes ++ [{name, value}]}
      end

      defp parse_options(block, lines) do
        Enum.reduce(lines, block, fn
          "." <> class_name, block ->
            add_class_name(block, class_name)

          "-" <> content, block ->
            add_list_item(block, content |> String.trim_leading())

          "[" <> attr, block ->
            case Regex.run(~r/(.+)\]\s*(.*)/, attr) do
              [_, name, ""] -> add_attribute(block, name, true)
              [_, name, value] -> add_attribute(block, name, value)
              _ -> block
            end

          _item, block ->
            block
        end)
      end
    end

    defp convert_line_endings_to_line_feed(source) when is_binary(source) do
      source |> String.replace(~r/\r\n/, "\n")
    end

    def parse_string(source) when is_binary(source) do
      # source |> String.split("\n") |> parse_lines()
      source
      |> convert_line_endings_to_line_feed
      |> String.split(~r{\n\n+}, trim: true)
      |> Enum.map(&parse_block_string/1)
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

    @new_line raw("\n")

    defp always_space([""]), do: [raw("&nbsp;")]
    defp always_space(items), do: items

    defp tidy_attributes(attributes, class) do
      case class do
        "" -> attributes
        s -> attributes ++ [class: s]
      end
    end

    defp present_block(%Block{
           type: :link,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:a, always_space(children), tidy_attributes(attributes, class))
    end

    defp present_block(%Block{
           type: :text,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:span, always_space(children), tidy_attributes(attributes, class))
    end

    defp present_block(%Block{
           type: :textbox,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:label, [
        content_tag(:span, children),
        tag(:input, tidy_attributes(attributes, class) ++ [type: "text"])
      ])
    end

    defp present_block(%Block{
           type: :checkbox,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:label, [
        tag(:input, tidy_attributes(attributes, class) ++ [type: "checkbox"]),
        content_tag(:span, children)
      ])
    end

    defp present_block(%Block{
           type: :button,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:button, always_space(children), tidy_attributes(attributes, class))
    end

    defp present_block(%Block{
           type: :navigation,
           list_items: list_items,
           attributes: attributes,
           class: class
         }) do
      presented_list_items =
        list_items
        |> Enum.map(fn item ->
          [content_tag(:li, item |> present_block()), @new_line]
        end)

      content_tag(:nav, tidy_attributes(attributes, class)) do
        [
          @new_line,
          content_tag(:ul, [@new_line, presented_list_items]),
          @new_line
        ]
      end
    end

    defp present_block(%Block{errors: errors}) do
      content_tag(:div, errors, class: "italic")
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

  defp present_source(source, :html) do
    elements = source |> Parser.parse_string() |> Preview.present()

    html_source =
      elements
      |> Enum.map(fn element -> element |> html_escape() |> safe_to_string() end)
      |> Enum.join("\n\n")
      |> html_escape()

    content_tag(:pre, html_source, class: "text-sm whitespace-pre-wrap")
  end

  def render(assigns) do
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
          <div>
            <%= label_text "Preview" %>
            <%= form_tag "#", phx_change: "preview-mode-change", class: "inline-block" %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "elements", checked: @state.preview == :elements) %>
                Elements
              <% end %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "html", checked: @state.preview == :html) %>
                HTML
              <% end %>
            </form>
          </div>
          <div class="bg-gray-200 border border-l-0 p-4 var:underline-hovered-links">
            <%= @state.source |> present_source(@state.preview) %>
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

  def handle_event(
        "preview-mode-change",
        %{"preview" => %{"preview_mode" => new_preview_mode}},
        socket = %Socket{assigns: %{state: state}}
      ) do
    new_state =
      case new_preview_mode do
        "elements" -> State.change_preview_to_elements(state)
        "html" -> State.change_preview_to_html(state)
        _ -> state
      end

    {:noreply, assign(socket, state: new_state)}
  end

  defp label_text(text) do
    content_tag(:span, text, class: "text-xs font-bold text-gray-500 uppercase tracking-wide")
  end
end
