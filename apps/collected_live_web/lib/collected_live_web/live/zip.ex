defmodule CollectedLiveWeb.ZipLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  alias CollectedLive.GitHubArchiveDownloader

  defp pluralize(count, thing) when is_integer(count) and is_binary(thing) do
    "#{count} #{Inflex.inflect(thing, count)}"
  end

  defp include_zip_file?(
         {:zip_file, name,
          {:file_info, _size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _,
           _, _}, _comment, _offset, _comp_size},
         file_name_filter
       )
       when is_binary(file_name_filter) do
    if String.length(file_name_filter) > 2 do
      String.contains?(to_string(name), file_name_filter)
    else
      true
    end
  end

  defp include_zip_file?(
         {:zip_file, _, {:file_info, _, _, _, _, _, _, _, _, _, _, _, _, _}, _, _, _},
         file_name_filter
       )
       when is_binary(file_name_filter) do
    false
  end

  defp present_zip_file(
         {:zip_file, name,
          {:file_info, size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
           _}, _comment, _offset, _comp_size}
       ) do
    %{
      name: to_string(name),
      content: "#{name}"
    }
  end

  defp present_zip_file(_), do: nil

  defp display_file_bytes(
         {:file_info, size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
          _}
       ),
       do: "#{size} bytes"

  def render(assigns) do
    ~L"""
    <div class="h-screen flex flex-col">
      <p class="px-2 py-2 text-center text-xl font-bold text-gray-900 bg-gray-500"><%= @url %></p>
      <div class="flex flex-row text-sm min-h-full">
        <div class="flex flex-col w-1/4 bg-gray-800 text-white">
          <%= if @zip_files == nil do %>
            <p class="italic p-1">Loading…</p>
          <% end %>
          <%= if @zip_files != nil do %>
            <% filtered_files = Enum.filter(@zip_files, fn (file) -> include_zip_file?(file, @file_name_filter) end) %>

            <div class="pl-2 pr-2 shadow-lg">
              <%= f = form_for :files_list, "#", [phx_change: :change_files_list, class: "pt-2 pb-2"] %>
                <%= text_input f, :file_name_filter, placeholder: "Filter names", class: "block w-full px-2 py-1 rounded-sm bg-gray-900" %>
              </form>

              <p class="text-center text-xs pb-1"><%= pluralize(Enum.count(filtered_files), "file") %></p>
            </div>

            <div class="overflow-scroll">
              <ul class="pt-1">
              <%= for file <- filtered_files do %>
                <%= case present_zip_file(file) do
                  nil -> ""
                  %{ name: name, content: content } -> content_tag(:li) do
                    content_tag( :button, content, phx_click: "select_zip_file", phx_value_name: name,
                    class: "w-full text-left pl-2 pr-2 pb-1
                    focus:text-gray-900
                    #{if name == @selected_file_name, do: "text-gray-900 bg-white focus:bg-white", else: "focus:bg-gray-200"}
                    ")
                  end
                end %>
              <% end %>
              </ul>
            </div>
          <% end %>
        </div>
        <div class="w-3/4 pl-2 overflow-scroll bg-gray-900 text-white">
          <%= if @selected_file_info != nil do %>
            <p><%= display_file_bytes(@selected_file_info) %></p>
          <% end %>

          <%= if @selected_file_content != nil do %>
            <pre class="break-words p-1"><%= @selected_file_content %></pre>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{url: url}, socket) do
    zip_files = GitHubArchiveDownloader.result_for_url(url)

    GitHubArchiveDownloader.subscribe_for_url(url)
    GitHubArchiveDownloader.use_url(url)

    {:ok,
     assign(socket,
       url: url,
       zip_files: zip_files,
       file_name_filter: "",
       selected_file_name: nil,
       selected_file_info: nil,
       selected_file_content: nil
     )}
  end

  def handle_info({:completed_download_for_url, url}, socket) do
    zip_files = GitHubArchiveDownloader.result_for_url(url)
    {:noreply, assign(socket, :zip_files, zip_files)}
  end

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

  def handle_event(
        "change_files_list",
        %{"files_list" => %{"file_name_filter" => file_name_filter}},
        socket
      ) do
    {:noreply, assign(socket, file_name_filter: file_name_filter)}
  end
end
