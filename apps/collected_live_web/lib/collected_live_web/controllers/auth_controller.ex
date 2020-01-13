defmodule CollectedLiveWeb.AuthController do
  use CollectedLiveWeb, :controller

  plug Ueberauth
  # alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    render(conn, "request.html")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn
        |> put_flash(:info, "Successfully authenticated. #{Kernel.inspect(auth)}")
        |> redirect(to: "/")

    # case UserFromAuth.find_or_create(auth) do
    #   {:ok, user} ->
    #     conn
    #     |> put_flash(:info, "Successfully authenticated.")
    #     |> put_session(:current_user, user)
    #     |> configure_session(renew: true)
    #     |> redirect(to: "/")
    #   {:error, reason} ->
    #     conn
    #     |> put_flash(:error, reason)
    #     |> redirect(to: "/")
    # end
  end
end
