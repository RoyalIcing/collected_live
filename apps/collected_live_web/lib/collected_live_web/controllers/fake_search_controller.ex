defmodule CollectedLiveWeb.FakeSearchController do
  use CollectedLiveWeb, :controller

  alias CollectedLive.FakeSearch

  def index(conn, _params) do
    items = FakeSearch.list()
    render(conn, "index.html", items: items)
  end
end
