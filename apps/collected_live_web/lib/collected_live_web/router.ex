defmodule CollectedLiveWeb.Router do
  use CollectedLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CollectedLiveWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/text", TextController do
      get "/text/plain", TextController, :show_text_plain, as: :plain
      get "/text/css", TextController, :show_text_css, as: :css

    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CollectedLiveWeb do
  #   pipe_through :api
  # end
end
