defmodule CollectedLiveWeb.UnderstoryLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket

  defmodule State do
    defstruct source: ""

    def change_source(state = %State{}, new_source) when is_binary(new_source) do
      %State{state | source: new_source}
    end
  end

  def mount(%{}, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def render(assigns) do
    state = assigns.state

    # assigns = Map.put(assigns, :cols, col_count)
    # assigns = Map.put(assigns, :rows, max_row + 2)

    ~L"""
    <div class="max-w-xl mx-auto">
      <div class="flex flex-row">
        <%= form_tag "#", phx_change: "text-change", class: "flex-1" %>
          <%= label do %>
            <%= label_text "Define" %>
            <%= textarea(:define, :source,
              value: @state.source,
              phx_hook: "Autofocusing",
              rows: 20,
              class: "block w-full m-1 px-3 py-2 text-base border")
            %>
          <% end %>
        </form>
      </div>
    </div>
    """
  end

  def handle_event("text-change", %{ "define" => %{ "source" => new_source } }, socket = %Socket{ assigns: %{ state: state } }) do
    new_state = State.change_source(state, new_source)
    {:noreply, assign(socket, state: new_state)}
  end

  defp label_text(text) do
    content_tag(:span, text, class: "text-xs font-bold text-gray-500 uppercase tracking-wide")
  end
end
