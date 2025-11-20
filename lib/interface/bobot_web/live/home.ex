defmodule BobotWeb.Home do
  use BobotWeb, :live_view
  import BobotWeb.Components
  import BobotWeb.WebTools

  require Logger

  Code.ensure_compiled!(Bobot.Config)

  @bots_dir Application.compile_env(:bobot, :bots_dir)
  @apis_dir Application.compile_env(:bobot, :apis_dir)
  @libs_dir Application.compile_env(:bobot, :libs_dir)

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

  def handle_event("home-submit", _params, socket) do
    now_active_bots = Bobot.Config.get_active_bots()
    new_active_bots = socket.assigns[:active_bots]

    turn_off = :lists.subtract(now_active_bots, new_active_bots)
    turn_on = :lists.subtract(new_active_bots, now_active_bots)

    filename = save_config(new_active_bots)

    {{result, message}, real_errors} =
      Code.with_diagnostics(fn ->
        try do
          Code.compile_file(filename)
          {:ok, "Config commited OK!"}
        rescue
          error ->
            {:error, "There was a problem commiting the config! (#{inspect error})"}
        end
      end)

    if result == :error do
      error =
        real_errors
        |> Enum.filter(&(&1.severity == :error))
        |> hd()
        |> Map.get(:message)
      Logger.log(:error, "[Bobot][Home] ERROR: #{error}")
    end

    {:noreply, socket
      |> assign(last_result: result)
      |> assign(changed: result != :ok)
      |> put_message(message)
    }
  end

  ################################################################################################
  ## Private tools
  ################################################################################################

  defp save_config(active_bots), do: save_config(active_bots, "config/bobot_config.ex")
  defp save_config(active_bots, filename) do
    File.write(filename, config_to_string(active_bots))
    filename
  end

  defp config_to_string(active_bots) do
    telegram_bots =
      active_bots
      |> Enum.filter(fn name ->
        BobotWeb.Bots.load_bot(name)[:settings][:type] == :telegram
      end)

    """
    defmodule Bobot.Config do
      def get_available_bots() do
        "#{@bots_dir}/*.ex"
        |> Path.wildcard()
        |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
        |> Stream.map(fn ast -> BobotWeb.Bots.ast_extract_components(ast) end)
        |> Enum.into([])
        |> Enum.filter(fn bot -> bot != [] end)
        |> Enum.map(fn {name, _} -> name end)
      end

      def get_available_apis() do
        "#{@apis_dir}/*.ex"
        |> Path.wildcard()
        |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
        |> Stream.map(fn ast -> BobotWeb.Apis.ast_extract_components(ast) end)
        |> Enum.into([])
        |> Enum.filter(fn api -> api != [] end)
        |> Enum.map(fn {name, _} -> name end)
      end

      def get_available_libs() do
        "#{@libs_dir}/*.ex"
        |> Path.wildcard()
        |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
        |> Stream.map(fn ast -> BobotWeb.Libs.ast_extract_components(ast) end)
        |> Enum.into([])
        |> Enum.filter(fn lib -> lib != [] end)
        |> Enum.map(fn {name, _} -> name end)
      end



      Module.register_attribute(__MODULE__, :telegram_bots, persist: true, accumulate: false)
      @telegram_bots #{inspect telegram_bots}

      ## For future updates where I will support Whatsapp, Discord, etc
      ## Module.register_attribute(__MODULE__, :whatsapp_bots, persist: true, accumulate: false)
      ## @whatsapp_bots []
      ## Module.register_attribute(__MODULE__, :discord_bots, persist: true, accumulate: false)
      ## @discord_bots []

      def get_active_bots(), do: @telegram_bots # ++ @whatsapp_bots ++ @discord_bots
    end
    """
    |> Code.format_string!()
    |> Enum.join("")
  end
end
