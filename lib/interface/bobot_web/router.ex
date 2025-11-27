defmodule BobotWeb.Router do
  use BobotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BobotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BobotWeb do
    pipe_through :browser

    # get "/", PageController, :home
    # get "/bots", PageController, :bots
    # get "/apis", PageController, :apis
    # get "/libs", PageController, :libs

    live_session :main do
      live "/", Home
      live "/bots", Bots
      live "/apis", Apis
      live "/libs", Libs
      live "/*nouse", Home
    end

  end

  # Other scopes may use custom stacks.
  # scope "/api", BobotWeb do
  #   pipe_through :api
  # end
end
