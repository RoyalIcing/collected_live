defmodule CollectedLive.GitHubArchiveDownloader do
  alias CollectedLive.HTTPClient

  @cache_name :github_archive_download_cache

  defp get_url(url) do
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
    {:ok, [_comment | zip_files]} = :zip.list_dir(data)
    Cachex.put(@cache_name, url, {:ok, zip_files})

    send_message_for_url(url, {:completed_download_for_url, url})
  end

  def use_url(url) do
    get_url(url)
    status_for_url(url)
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
      {:ok, :pending} -> :pending
      {:ok, {:ok, _zip_files}} -> :completed
      other -> other
    end
  end

  def delete_data_for_url(url) do
    Cachex.del(@cache_name, url)
  end
end
