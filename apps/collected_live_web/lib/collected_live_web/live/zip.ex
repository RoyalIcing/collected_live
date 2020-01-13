defmodule CollectedLiveWeb.ZipLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  alias CollectedLive.GitHubArchiveDownloader
  alias CollectedLive.Content.Archive

  @default_params %{"owner" => "facebook", "repo" => "react", "release" => "v16.11.0"}

  defp pluralize(count, thing) when is_integer(count) and is_binary(thing) do
    "#{count} #{Inflex.inflect(thing, count)}"
  end

  defp present_zip_file(
         {:zip_file, name,
          {:file_info, _size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
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

  defp get_name_extension(filename) do
    parts = String.split(filename, ".")
    List.last(parts)
  end

  defp display_file_content(filename, content) do
    extension = get_name_extension(filename)

    content_tag(:pre, class: "break-words p-1") do
      CollectedLive.SyntaxHighlighter.highlight(extension, content)
    end
  end

  def render(assigns) do
    ~L"""
    <div class="h-screen flex flex-col">
      <p class="px-2 py-2 text-center text-xl font-bold text-gray-900 bg-gray-500"><%= @url %></p>
      <div class="flex flex-row text-sm min-h-full">
        <div class="flex flex-col w-1/4 bg-gray-800 text-white">
          <%= if @archive == nil do %>
            <p class="italic p-1">Loading…</p>
          <% end %>
          <%= if @archive != nil do %>
            <% filtered_files = Archive.Zip.filtered_zip_files(
              @archive,
              %{name_containing: @file_name_filter, content_containing: @contents_filter}
            ) %>

            <div class="pl-2 pr-2 shadow-lg">
              <%= f = form_for :file_filtering, "#", [phx_change: :filter_files, class: "pt-2 pb-2"] %>
                <%= text_input f, :file_name_filter, placeholder: "Filter names", class: "block w-full px-2 py-1 rounded-sm bg-gray-900", phx_debounce: "250", value: @file_name_filter %>
                <%= text_input f, :contents_filter, placeholder: "Search code", class: "mt-2 block w-full px-2 py-1 rounded-sm bg-gray-900", phx_debounce: "250", value: @contents_filter %>
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
            <%= display_file_content(@selected_file_name, @selected_file_content) %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{}, socket) do
    {:ok,
     assign(socket,
       url: "",
       archive: nil,
       file_name_filter: "",
       contents_filter: "",
       selected_file_name: nil,
       selected_file_info: nil,
       selected_file_content: nil
     )}
  end

  def handle_params(
        params = %{"owner" => owner, "repo" => repo, "release" => release},
        _uri,
        socket
      ) do
    url = "https://github.com/#{owner}/#{repo}/archive/#{release}.zip"

    zip_archive = GitHubArchiveDownloader.result_for_url(url)

    GitHubArchiveDownloader.subscribe_for_url(url)
    GitHubArchiveDownloader.use_url(url)

    file_name_filter = Map.get(params, "file_name_filter", "")
    contents_filter = Map.get(params, "contents_filter", "")

    {:noreply,
     assign(socket,
       url: url,
       params: params,
       archive: zip_archive,
       file_name_filter: file_name_filter,
       contents_filter: contents_filter,
       selected_file_name: nil,
       selected_file_info: nil,
       selected_file_content: nil
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     live_redirect(
       socket,
       to:
         CollectedLiveWeb.Router.Helpers.live_path(
           socket,
           __MODULE__,
           @default_params["owner"],
           @default_params["repo"],
           @default_params["release"]
         )
     )}
  end

  def handle_info({:completed_download_for_url, url}, socket) do
    archive = GitHubArchiveDownloader.result_for_url(url)
    {:noreply, assign(socket, :archive, archive)}
  end

  def handle_event("select_zip_file", %{"name" => name}, socket) do
    archive = socket.assigns[:archive]
    file_info = Archive.Zip.info_for_file_named(archive, name)
    file_content = Archive.Zip.content_for_file_named(archive, name)

    {:noreply,
     assign(socket,
       selected_file_name: name,
       selected_file_info: file_info,
       selected_file_content: file_content
     )}
  end

  def handle_event(
        "filter_files",
        %{
          "file_filtering" => %{
            "file_name_filter" => file_name_filter,
            "contents_filter" => contents_filter
          }
        },
        socket
      ) do
    {:noreply,
     live_redirect(
       socket,
       to:
         CollectedLiveWeb.Router.Helpers.live_path(
           socket,
           __MODULE__,
           socket.assigns.params["owner"],
           socket.assigns.params["repo"],
           socket.assigns.params["release"],
           %{file_name_filter: file_name_filter, contents_filter: contents_filter}
         )
     )}
  end
end
