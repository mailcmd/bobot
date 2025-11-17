defmodule BobotWeb.PageController do
  use BobotWeb, :controller
  use Gettext, backend: BobotWeb.Gettext
  import Phoenix.LiveView.Controller

  def home(conn, _params) do
    live_render(conn, BobotWeb.Home, layout: false, session: %{})
  end

  def bots(conn, _params) do
    live_render(conn, BobotWeb.Bots, layout: false, session: %{})
  end

  def apis(conn, _params) do
    live_render(conn, BobotWeb.Apis, layout: false, session: %{})
  end
end
