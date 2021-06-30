defmodule CollectedLiveWeb.CodeSearchController do
  use CollectedLiveWeb, :controller

  def index(conn, %{"owner" => owner, "repo" => repo, "release" => release}) do
    url = "https://github.com/#{owner}/#{repo}/archive/#{release}.zip"
    render(conn, "index.html", %{url: url, owner: owner, repo: repo, release: release})
  end

  def index(conn, _params) do
    index(conn, %{"owner" => "facebook", "repo" => "react", "release" => "v17.0.2"})
  end
end
