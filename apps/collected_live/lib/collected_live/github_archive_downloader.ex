defmodule CollectedLive.GitHubArchiveDownloader do
  alias CollectedLive.HTTPClient

  @cache_name :github_archive_download_cache

  defp fetch_url(url) do
    IO.puts("fetching url")
    Cachex.put(@cache_name, url, :pending)

    Task.start(fn ->
      result = HTTPClient.get(url)

      case result do
        {:ok, response} -> received_data_for_url(url, response.body)
        _ -> ""
      end
    end)
  end

  defp send_message_for_url(url, message) do
    Registry.dispatch(__MODULE__, url, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end

  defp received_data_for_url(url, data) when byte_size(data) == 0 do
    Cachex.put(@cache_name, url, {:error, :empty})

    send_message_for_url(url, {:failed_download_for_url, url})
  end

  defp received_data_for_url(url, data) when is_binary(data) do
    Cachex.put(@cache_name, url, {:ok, data})

    # Cachex.execute!(@cache_name, fn(cache) ->
    #   {:ok, zip_handle} = :zip.zip_open(data, [:memory])
    #   Cachex.put!(cache, url, {:ok, zip_handle})
    # end)

    send_message_for_url(url, {:completed_download_for_url, url})
  end

  def use_url(url) do
    case status_for_url(url) do
      :not_requested ->
        fetch_url(url)
        :pending

      status ->
        status
    end
  end

  def subscribe_for_url(url) when is_binary(url) do
    {:ok, _} = Registry.register(__MODULE__, url, [])
    :ok
  end

  def unsubscribe_for_url(url) when is_binary(url) do
    Registry.unregister(__MODULE__, url)
    :ok
  end

  def status_for_url(url) do
    case Cachex.get(@cache_name, url) do
      {:ok, nil} -> :not_requested
      {:ok, :pending} -> :pending
      {:ok, {:ok, _zip_files}} -> :completed
      other -> other
    end
  end

  def result_for_url(url) do
    with {:ok, result} <- Cachex.get(@cache_name, url),
         {:ok, data} <- result,
         {:ok, [_comment | zip_files]} = :zip.list_dir(data) do
      zip_files
    else
      _ -> nil
    end
  end

  def file_info_for(url, filename) do
    filename_chars = to_charlist(filename)

    with {:ok, result} <- Cachex.get(@cache_name, url),
         {:ok, data} <- result,
         {:ok, info} <-
           :zip.foldl(
             fn
               ^filename_chars, get_info, _get_binary, _acc -> get_info.()
               _, _, _, acc -> acc
             end,
             nil,
             {'name.zip', data}
           ) do
      info
    else
      _ -> nil
    end
  end

  def file_content_for(url, filename) do
    filename_chars = to_charlist(filename)

    with {:ok, result} <- Cachex.get(@cache_name, url),
         {:ok, data} <- result,
         {:ok, file_data} <-
           :zip.foldl(
             fn
               ^filename_chars, _get_info, get_binary, _acc -> get_binary.()
               _, _, _, acc -> acc
             end,
             nil,
             {'name.zip', data}
           ) do
      file_data
    else
      _ -> nil
    end
  end

  def delete_data_for_url(url) do
    Cachex.del(@cache_name, url)
  end
end