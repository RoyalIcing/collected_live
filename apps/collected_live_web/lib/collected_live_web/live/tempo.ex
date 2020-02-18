defmodule CollectedLiveWeb.TempoLive do
  use CollectedLiveWeb, :live_view
  use Phoenix.HTML
  require Logger
  alias Phoenix.LiveView.Socket
  alias CollectedLive.HTTPClient

  @update_every_seconds 2000

  defmodule State do
    defstruct history: []

    def add_timing(state = %State{history: history}, name, latency) do
      new_history = history ++ [{name, latency}]
      new_history = Enum.take(new_history, -20)
      %State{state | history: new_history}
    end
  end

  def mount(%{}, socket) do
    if connected?(socket), do: :timer.send_interval(@update_every_seconds, self(), :update)

    state = %State{}

    {:ok, assign(socket, state: state)}
  end

  def handle_info({:measured, source, ms}, socket = %Socket{assigns: %{state: state}}) do
    new_state = state |> State.add_timing(source, ms)
    {:noreply, assign(socket, :state, new_state)}
  end

  defp measure_request_to(url) do
    start_ms = System.system_time(:millisecond)

    {:ok, _response} = HTTPClient.get(url)

    end_ms = System.system_time(:millisecond)
    ms = end_ms - start_ms
    ms
  end

  def handle_info(:update, socket) do
    receiver = self()

    Task.start(fn ->
      ms =
        measure_request_to(
          "https://collected.systems/1/github/gilbarbara/logos/93e29467eea30b2981187822143f45e562662b5c/logos/atlassian.svg"
        )

      send(receiver, {:measured, :collected_systems, ms})
    end)

    Task.start(fn ->
      ms = measure_request_to("https://collected-193006.appspot.com/")
      send(receiver, {:measured, :collected_appspot, ms})
    end)

    {:noreply, socket}
  end

  defmodule SyntaxHighlight do
    @theme "Sourcegraph"
    @timeout 3000

    def to_html(code) do
      task =
        Task.async(fn ->
          try do
            {:ok, syntax_highlight(code)}
          catch
            error ->
              IO.inspect(error, label: "syntect_error 1")
              :error

            error, arg ->
              IO.inspect({error, arg}, label: "syntect_error 2")
              :error
          end
        end)

      result =
        case Task.yield(task, @timeout) || Task.shutdown(task) do
          {:ok, result} ->
            result

          :error ->
            Logger.error("Failed to highlight")
            nil

          nil ->
            Logger.warn("Failed to highlight in #{@timeout}ms")
            nil
        end

      case result do
        {:ok, result} -> result
        _ -> nil
      end
    end

    defp get_syntect_server_url do
      "http://0.0.0.0:9237/"
    end

    defp get_syntect_server_url do
      CollectedLiveWeb.Endpoint.config(:royal_icing)
      |> Keyword.fetch!(:syntax_highlighter)
      |> Keyword.fetch!(:url)
    end

    defp syntax_highlight(code) do
      request_body =
        Jason.encode!(%{
          "filepath" => "test.js",
          "theme" => @theme,
          "code" => code
        })

      {:ok, response} =
        HTTPClient.post(get_syntect_server_url(), request_body,
          headers: [{"content-type", "application/json"}]
        )

      json_response = Jason.decode!(response.body)
      Map.fetch!(json_response, "data")
    end
  end

  def render(assigns) do
    ~L"""
    <div class="max-w-3xl mx-auto">
      <div class="flex flex-row">
        <div class="flex flex-row flex-grow">
          <dl class="grid grid-cols-2 col-gap-4 row-gap-2">
          <%= for {source, latency} <- Enum.reverse(@state.history) do %>
            <dt class="font-bold"><%= source %></dt>
            <dd class=""><%= latency %>ms</dd>
          <% end %>
          </dl>
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
