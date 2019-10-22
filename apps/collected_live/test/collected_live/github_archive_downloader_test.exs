defmodule CollectedLive.GitHubArchiveDownloaderTest do
  use ExUnit.Case, async: true
  import Mox

  alias CollectedLive.GitHubArchiveDownloader, as: Subject

  defp fixture_path(name) do
    Path.join([__DIR__, "fixtures", name])
  end

  defp readme_md_zip_contents do
    File.read!(fixture_path("README.md.zip"))
  end

  setup :verify_on_exit!
  setup do
    CollectedLive.HTTPClient.Mock
    |> expect(:call, fn
      %{url: "http://some.url.org"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: readme_md_zip_contents()}}

      %{url: "http://empty.url.org"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: ""}}
    end)

    :ok
  end

  describe "use_url()" do
    test "it initially has pending status" do
      Subject.use_url("http://some.url.org")
      assert :pending == Subject.status_for_url("http://some.url.org")

      Process.sleep(10)
    end

    test "it eventually has completed status" do
      Subject.use_url("http://some.url.org")
      Process.sleep(10)
      assert :completed == Subject.status_for_url("http://some.url.org")
    end

    test "it sends completed message to self" do
      Subject.subscribe_for_url("http://some.url.org")
      Subject.use_url("http://some.url.org")

      assert_receive {:completed_download_for_url, "http://some.url.org"}, 100

      Subject.unsubscribe_for_url("http://some.url.org")
    end

    test "empty result sends failed message to self" do
      Subject.subscribe_for_url("http://empty.url.org")
      Subject.use_url("http://empty.url.org")

      assert_receive {:failed_download_for_url, "http://empty.url.org"}, 100

      Subject.unsubscribe_for_url("http://empty.url.org")
    end
  end
end
