defmodule CollectedLiveWeb.UnderstoryLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket

  defmodule State do
    @default_source """
    @navigation Primary
    - @heading ACME
    - @link Features
    - @link Pricing
    - @link Sign in
    - @link Join

    @heading Sign into ACME

    @textbox Email
    [value] jane@example.org

    @checkbox Remember me
    [checked]

    @button Sign in

    @radiogroup Choose
    - First
    - Second
    - Third
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

    def change_preview_to_docs(state = %State{}) do
      %State{state | preview: :docs}
    end

    def change_preview_to_jest(state = %State{}) do
      %State{state | preview: :jest}
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

      def from_lines(["@heading " <> text | tail]) do
        %__MODULE__{
          type: :heading,
          children: [text]
        }
        |> parse_options(tail)
      end

      def from_lines(["@heading" | tail]), do: from_lines(["@heading ?" | tail])

      def from_lines(["@link " <> text | tail]) do
        %__MODULE__{
          type: :link,
          children: [text],
          attributes: [href: "#"]
        }
        |> parse_options(tail)
      end

      def from_lines(["@link" | tail]), do: from_lines(["@link ?" | tail])

      def from_lines(["@textbox " <> rest | tail]) do
        %__MODULE__{
          type: :textbox,
          children: [rest |> String.trim()]
        }
        |> parse_options(tail)
      end

      def from_lines(["@textbox" | tail]), do: from_lines(["@textbox " | tail])

      def from_lines(["@checkbox " <> label | tail]) do
        %__MODULE__{
          type: :checkbox,
          children: [label |> String.trim()]
        }
        |> parse_options(tail)
      end

      def from_lines(["@checkbox" | tail]), do: from_lines(["@checkbox " | tail])

      def from_lines(["@button " <> title | tail]) do
        %__MODULE__{
          type: :button,
          children: [title]
        }
        |> parse_options(tail)
      end

      def from_lines(["@button" | tail]), do: from_lines(["@button ?" | tail])

      def from_lines(["@navigation " <> label | tail]) do
        %__MODULE__{
          type: :navigation,
          attributes: [{"aria-label", label}]
        }
        |> parse_options(tail)
      end

      def from_lines(["@navigation" | tail]), do: from_lines(["@navigation " | tail])

      def from_lines(["@radiogroup " <> label | tail]) do
        %__MODULE__{
          type: :radiogroup,
          attributes: [role: "radiogroup"],
          children: [label |> String.trim()]
        }
        |> parse_options(tail, list_mode: :text)
      end

      def from_lines(["@radiogroup" | tail]), do: from_lines(["@radiogroup " | tail])

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

      defp add_list_item(block = %__MODULE__{list_items: list_items}, :parse, item) do
        parsed_item = from_lines([item])
        %__MODULE__{block | list_items: list_items ++ [parsed_item]}
      end

      defp add_list_item(block = %__MODULE__{list_items: list_items}, :text, item) do
        %__MODULE__{block | list_items: list_items ++ [item]}
      end

      defp add_attribute(block = %__MODULE__{attributes: attributes}, name, value) do
        %__MODULE__{block | attributes: attributes ++ [{name, value}]}
      end

      defp parse_options(block, lines, options \\ []) do
        list_mode = Keyword.get(options, :list_mode, :parse)

        Enum.reduce(lines, block, fn
          "." <> class_name, block ->
            add_class_name(block, class_name)

          "-" <> content, block ->
            add_list_item(block, list_mode, content |> String.trim_leading())

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
           type: :heading,
           children: children,
           attributes: attributes,
           class: class
         }) do
      content_tag(:h2, always_space(children), tidy_attributes(attributes, class))
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
          [
            content_tag(:li, item |> present_block()),
            @new_line
          ]
        end)

      content_tag(:nav, tidy_attributes(attributes, class)) do
        [
          @new_line,
          content_tag(:ul, [@new_line, presented_list_items]),
          @new_line
        ]
      end
    end

    defp present_block(%Block{
           type: :radiogroup,
           children: children,
           list_items: list_items,
           attributes: attributes,
           class: class
         }) do
      presented_list_items =
        list_items
        |> Enum.map(fn choice_label ->
          [
            content_tag(:label, [
              tag(:input, type: "radio"),
              content_tag(:span, choice_label)
            ]),
            @new_line
          ]
        end)

      content_tag(:div, tidy_attributes(attributes, class)) do
        [
          @new_line,
          content_tag(:h3, [children]),
          @new_line,
          presented_list_items
        ]
      end
    end

    defp present_block(%Block{errors: errors}) do
      content_tag(:div, errors, class: "italic")
    end
  end

  defmodule JestGenerator do
    alias Parser.Block

    def present(blocks) do
      test_source =
        blocks
        |> Enum.map(&present_block/1)
        |> Enum.join("\n\n")
        |> String.replace("\t", "  ")

      content_tag(:pre, test_source, class: "text-xs whitespace-pre-wrap")
    end

    defp present_block(%Block{
           type: :heading,
           children: children,
           attributes: attributes,
           class: class
         }) do
      text = children |> Enum.join("")

      [
        "it ('has \"#{text}\" heading', () => {",
        "\tconst { getAllByRole, getByText } = subject();",
        "\texpect(getAllByRole('heading')).toContain(",
        "\t\tgetByText('#{text}')",
        "\t);",
        "});"
      ]
      |> Enum.join("\n")
    end

    defp present_block(%Block{
           type: :textbox,
           children: children,
           attributes: attributes,
           class: class
         }) do
      text = children |> Enum.join("")

      [
        "it ('has \"#{text}\" textbox', () => {",
        "\tconst { getAllByRole, getByLabelText } = subject();",
        "\texpect(getAllByRole('textbox')).toContain(",
        "\t\tgetByLabelText('#{text}')",
        "\t);",
        "});"
      ]
      |> Enum.join("\n")
    end

    defp present_block(%Block{
           type: :checkbox,
           children: children,
           attributes: attributes,
           class: class
         }) do
      text = children |> Enum.join("")

      [
        "it ('has \"#{text}\" checkbox', () => {",
        "\tconst { getAllByRole, getByLabelText } = subject();",
        "\texpect(getAllByRole('checkbox')).toContain(",
        "\t\tgetByLabelText('#{text}')",
        "\t);",
        "});"
      ]
      |> Enum.join("\n")
    end

    defp present_block(%Block{
           type: :button,
           children: children,
           attributes: attributes,
           class: class
         }) do
      text = children |> Enum.join("")

      [
        "it ('has \"#{text}\" button', () => {",
        "\tconst { getAllByRole, getByText } = subject();",
        "\texpect(getAllByRole('button')).toContain(",
        "\t\getByText('#{text}')",
        "\t);",
        "});"
      ]
      |> Enum.join("\n")
    end

    defp present_block(%Block{
           type: :navigation,
           children: children,
           attributes: attributes,
           class: class
         }) do
          IO.inspect(attributes, label: "ATTRS")
      ariaLabel =
        Enum.find_value(attributes, fn
          {"aria-label", value} -> value
          _ -> nil
        end)

      [
        "describe ('#{ariaLabel} navigation', () => {",
        "\tit ('is present', () => {",
        "\t\tconst { getAllByRole } = subject();",
        "\t\texpect(getAllByRole('navigation').map(el => el.getAttribute('aria-label')))",
        "\t\t.toContain('#{ariaLabel}')",
        "\t\t);",
        "\t});",
        "});"
      ]
      |> Enum.join("\n")
    end

    defp present_block(%Block{type: :text}), do: ""

    defp present_block(%Block{type: type, errors: []}) do
      "// Unknown block type: #{type}"
    end

    defp present_block(%Block{errors: errors}) do
      "// Errors: #{errors}"
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

  defp source_to_markdown(source) do
    source
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.replace(~r/^([-]\s)?(@\w+)/, "\\1`\\2`")
      |> String.replace(~r/^(\[\w+\])/, "`\\1`")
      |> String.replace(~r/$/, "  ")
    end)
    |> Enum.join("\n")
  end

  defp present_source(source, :docs) do
    {:ok, html, _} = source |> source_to_markdown() |> Earmark.as_html()

    content_tag(
      :div,
      [
        raw(html)
      ],
      class: "UnderstoryPreviewDocs"
    )
  end

  defp present_source(source, :jest) do
    blocks = source |> Parser.parse_string()

    content_tag(
      :div,
      [
        JestGenerator.present(blocks)
      ],
      class: "text-sm"
    )
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
              <div class="mb-4">
                <%= label_text "Define" %>
                <%= content_tag(:button, "Make Markdown", class: "text-sm mx-1 px-1 text-orange-900 bg-orange-300 border border-orange-400 rounded") %>
              </div>
              <%= textarea(:define, :source,
                value: @state.source,
                phx_hook: "Autofocusing",
                rows: 30,
                class: "block w-full px-3 py-2 font-sans text-base border")
              %>
            <% end %>
          </form>
        </div>
        <div class="w-1/2">
          <div>
            <%= label_text "Preview" %>
            <%= form_tag "#", phx_change: "preview-mode-change", class: "inline-block mb-4" %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "elements", checked: @state.preview == :elements, class: "mr-1") %>Interactive
              <% end %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "html", checked: @state.preview == :html, class: "mr-1") %>HTML
              <% end %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "docs", checked: @state.preview == :docs, class: "mr-1") %>Docs
              <% end %>
              <%= label(class: "text-sm px-1") do %>
                <%= radio_button(:preview, :preview_mode, "jest", checked: @state.preview == :jest, class: "mr-1") %>Jest
              <% end %>
            </form>
          </div>
          <div class="UnderstoryPreview bg-gray-200 border border-l-0 @link:hover:underline">
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
        "docs" -> State.change_preview_to_docs(state)
        "jest" -> State.change_preview_to_jest(state)
        _ -> state
      end

    {:noreply, assign(socket, state: new_state)}
  end

  defp label_text(text) do
    content_tag(:span, text, class: "text-xs font-bold text-gray-500 uppercase tracking-wide")
  end
end
