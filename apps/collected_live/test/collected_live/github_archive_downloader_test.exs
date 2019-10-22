defmodule CollectedLive.GitHubArchiveDownloaderTest do
  use ExUnit.Case, async: true
  import Mox

  @moduletag timeout: 5_000

  alias CollectedLive.GitHubArchiveDownloader, as: Subject

  defp fixture_path(name) do
    Path.join([__DIR__, "fixtures", name])
  end

  setup_all do
    {:ok, hello_zip: File.read!(fixture_path("hello.zip"))}
  end

  setup :verify_on_exit!

  setup %{hello_zip: hello_zip} do
    CollectedLive.HTTPClient.Mock
    |> expect(:call, fn
      %{url: "http://some.url.org"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: hello_zip}}

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

    test "the 'hello.txt' file is listed from the zip" do
      Subject.use_url("http://some.url.org")
      Process.sleep(10)

      [zip_file] = Subject.result_for_url("http://some.url.org")
      {:zip_file, name, _info, _comment, _offset, _comp_size} = zip_file

      assert to_string(name) == "hello.txt"
    end

    test "file info is returned for 'hello.txt' filename" do
      Subject.use_url("http://some.url.org")
      Process.sleep(10)

      {:file_info, size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _, _} =
        Subject.file_info_for("http://some.url.org", "hello.txt")

      assert size == 6
    end

    test "file content is returned for 'hello.txt' filename" do
      Subject.use_url("http://some.url.org")
      Process.sleep(10)

      data = Subject.file_content_for("http://some.url.org", "hello.txt")

      assert data == """
             hello
             """
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
