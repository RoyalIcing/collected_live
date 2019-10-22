defmodule CollectedLiveWeb.ZipLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger

  defp display_zip_file(
         {:zip_file, name,
          {:file_info, size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
           _}, _comment, _offset, _comp_size}
       ) do
    %{
      name: name,
      content: "#{name} (#{size} bytes)"
    }
  end

  defp display_zip_file(_), do: nil

  def render(assigns) do
    ~L"""
    <div class="my-2">
      <p><%= @url %></p>

      <%= if @data == nil do %>
        <p>Loading…</p>
      <% else %>
        <p><%= byte_size(@data) %></p>
      <% end %>

      <%= if @zip_files != nil do %>
        <ul>
        <%= for file <- @zip_files do %>
          <%= case display_zip_file(file) do
            nil -> ""
            %{ name: name, content: content } -> content_tag(:li) do
              content_tag(:button, content, "phx-click": "select_zip_file", "phx-value-name": name)
            end
          end %>
        <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  # defp new_uuid do
  #   Ecto.UUID.generate
  # end

  def mount(%{}, socket) do
    # if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    url = "https://github.com/facebook/react/archive/v16.10.2.zip"

    parent = self()

    Task.start(fn ->
      response = HTTPotion.get(url, follow_redirects: true, timeout: 30000)

      data =
        case response do
          %HTTPotion.ErrorResponse{} -> ""
          response -> response.body
        end

      send(parent, {:downloaded_url, data})

      if byte_size(data) > 0 do
        {:ok, [_comment | zip_files]} = :zip.list_dir(data)
        send(parent, {:downloaded_zip_files, zip_files})
      end
    end)

    {:ok, assign(socket, url: url, data: nil, zip_files: nil)}
  end

  def handle_info({:downloaded_url, data}, socket) do
    {:noreply, assign(socket, :data, data)}
  end

  def handle_info({:downloaded_zip_files, zip_files}, socket) do
    {:noreply, assign(socket, :zip_files, zip_files)}
  end

  def handle_event("select_zip_file", %{"name" => name}, socket) do
    {:noreply, assign(socket, selected_zip_file_name: name)}
  end
end
