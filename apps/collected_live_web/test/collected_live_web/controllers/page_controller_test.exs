defmodule CollectedLiveWeb.PageControllerTest do
  use CollectedLiveWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Collected.Live"
  end
end
