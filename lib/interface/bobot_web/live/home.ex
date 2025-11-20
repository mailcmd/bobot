defmodule BobotWeb.Home do
  use BobotWeb, :live_view
  import BobotWeb.Components

  @doc """
  """

  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(active_bots: Bobot.Config.get_active_bots())
      |> assign(changed: false)
    }
  end

  ## EVENTS
  def handle_event("bot-state-change", params, socket) do
    active_bots = socket.assigns[:active_bots]
    target = params["_target"] |> hd()
    active_bots =
      case params[target] do
        nil -> List.delete(active_bots, String.to_atom(target))
        _ -> [String.to_atom(target) | active_bots] |> Enum.uniq()
      end

    {:noreply, socket
      |> assign(active_bots: active_bots)
      |> assign(changed: true)
    }
  end

  def handle_event("home-submit", params, socket) do
    now_active_bots = Bobot.Config.get_active_bots()
    new_active_bots = socket.assigns[:active_bots]

    turn_off = :lists.subtract(now_active_bots, new_active_bots)
    turn_on = :lists.subtract(new_active_bots, now_active_bots)



    {:noreply, socket
      |> assign(changed: false)
    }
  end

  def config_to_string(lib) do
    
    """
    defmodule Bobot.Config do
      Module.register_attribute(__MODULE__, :available_bots, persist: true, accumulate: false)
      @available_bots #{inspect BobotWeb.Bots.get_available_bots()}

      Module.register_attribute(__MODULE__, :available_apis, persist: true, accumulate: false)
      @available_apis #{inspect BobotWeb.Bots.get_available_apis()}

      Module.register_attribute(__MODULE__, :available_libs, persist: true, accumulate: false)
      @available_libs #{inspect BobotWeb.Bots.get_available_libs()}

      def get_available_bots(), do: @available_bots
      def get_available_apis(), do: @available_apis
      def get_available_libs(), do: @available_libs

      Module.register_attribute(__MODULE__, :telegram_bots, persist: true, accumulate: false)
      @telegram_bots [:smi]

      # For future updates where I will support Whatsapp, Discord, etc
      # Module.register_attribute(__MODULE__, :whatsapp_bots, persist: true, accumulate: false)
      # @whatsapp_bots []
      # Module.register_attribute(__MODULE__, :discord_bots, persist: true, accumulate: false)
      # @discord_bots []

      def get_active_bots(), do: @telegram_bots # ++ @whatsapp_bots ++ @discord_bots
    end
    """
    |> Code.format_string!()
    |> Enum.join("")
  end
end
