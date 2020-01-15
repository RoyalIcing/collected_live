defmodule CollectedLiveWeb.WeaveController do
  use CollectedLiveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
