defmodule Bobot.Task do
  use GenServer
  require Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, [])
  end

  @impl true
  def init(_) do
    pid = spawn_link(__MODULE__, :every_minute_tasks, [])
    {:ok, pid}
  end

  @impl true
  def handle_call(_, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(_, state) do
    {:noreply, state}
  end

  ################################################################################################
  ################################################################################################
  ################################################################################################

  def every_minute_tasks() do
    now = Macro.escape(:calendar.local_time())
    Enum.each(:ets.tab2list(:volatile_db), fn row ->
      case row do
        {:task, bot_module, channel, quoted_pattern, quoted_func} ->
          Code.eval_quoted(quote do
            case unquote(now) do
              unquote(quoted_pattern) ->
                require Logger
                func = unquote(quoted_func)
                message = func.(unquote(bot_module), unquote(channel))
                subscribers =
                  :dets.match_object(:static_db, {{:channel, unquote(channel)}, :_})
                  |> Enum.map(fn {_, chat_id} -> chat_id end)
                Logger.log(:info, "[Bobot][Tasks] Sending news for channel '#{unquote(channel)}' to #{inspect subscribers}")
                unquote(bot_module).inform_to_subscribers(unquote(channel), subscribers, message)

              _ ->
                nil
            end
          end)
      end
    end)
    :timer.apply_after(60_000, __MODULE__, :every_minute_tasks, [])
  end
end
