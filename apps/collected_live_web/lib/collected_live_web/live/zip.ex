defmodule CollectedLiveWeb.ZipLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  alias CollectedLive.GitHubArchiveDownloader

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

  defp display_file_bytes(
         {:file_info, size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
          _}
       ),
       do: "#{size} bytes"

  def render(assigns) do
    ~L"""
    <div class="my-2">
      <p class="text-xl font-bold mb-4"><%= @url %></p>

      <%= if @zip_files == nil do %>
        <p>Loading…</p>
      <% end %>

      <div class="flex flex-row h-screen text-sm">
        <div class="w-1/4 overflow-scroll text-left">
          <%= if @zip_files != nil do %>
            <ul>
            <%= for file <- @zip_files do %>
              <%= case display_zip_file(file) do
                nil -> ""
                %{ name: name, content: content } -> content_tag(:li) do
                  content_tag(:button, content, "phx-click": "select_zip_file", "phx-value-name": name, class: "text-left")
                end
              end %>
            <% end %>
            </ul>
          <% end %>
        </div>
        <div class="w-3/4 pl-2 overflow-scroll">
          <%= if @selected_file_info != nil do %>
            <p><%= display_file_bytes(@selected_file_info) %></p>
          <% end %>

          <%= if @selected_file_content != nil do %>
            <pre class="break-words"><%= @selected_file_content %></pre>
          <% end %>
        </div>
      </div>

    </div>
    """
  end

  # defp new_uuid do
  #   Ecto.UUID.generate
  # end

  def mount(%{}, socket) do
    # if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    url = "https://github.com/facebook/react/archive/v16.10.2.zip"

    zip_files = GitHubArchiveDownloader.result_for_url(url)

    GitHubArchiveDownloader.subscribe_for_url(url)
    GitHubArchiveDownloader.use_url(url)

    # parent = self()

    # Task.start(fn ->
    #   response = HTTPotion.get(url, follow_redirects: true, timeout: 30000)

    #   data =
    #     case response do
    #       %HTTPotion.ErrorResponse{} -> ""
    #       response -> response.body
    #     end

    #   send(parent, {:downloaded_url, data})

    #   if byte_size(data) > 0 do
    #     {:ok, [_comment | zip_files]} = :zip.list_dir(data)
    #     send(parent, {:downloaded_zip_files, zip_files})
    #   end
    # end)

    {:ok,
     assign(socket,
       url: url,
       zip_files: zip_files,
       selected_file_name: nil,
       selected_file_info: nil,
       selected_file_content: nil
     )}
  end

  def handle_info({:completed_download_for_url, url}, socket) do
    zip_files = GitHubArchiveDownloader.result_for_url(url)
    {:noreply, assign(socket, :zip_files, zip_files)}
  end

  # def handle_info({:downloaded_url, data}, socket) do
  #   {:noreply, assign(socket, :data, data)}
  # end

  # def handle_info({:downloaded_zip_files, zip_files}, socket) do
  #   {:noreply, assign(socket, :zip_files, zip_files)}
  # end

  def handle_event("select_zip_file", %{"name" => name}, socket) do
    url = socket.assigns[:url]
    file_info = GitHubArchiveDownloader.file_info_for(url, name)
    file_content = GitHubArchiveDownloader.file_content_for(url, name)

    {:noreply,
     assign(socket,
       selected_file_name: name,
       selected_file_info: file_info,
       selected_file_content: file_content
     )}
  end
end
