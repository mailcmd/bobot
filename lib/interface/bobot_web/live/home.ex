defmodule BobotWeb.Home do
  use BobotWeb, :live_view
  import BobotWeb.Components

  @doc """
  """

  # @bots_dir Application.compile_env(:bobot, :bots_dir)
  # @active_bots Application.compile_env(:bobot, :telegram_bots, [])

  def mount(_params, _session, socket) do
    {:ok, socket }
  end

end
