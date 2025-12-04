defmodule Bobot.Task do
  use GenServer
  require Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  @impl true
  def init(_) do
    pid = spawn_link(fn ->
      # At start wait 5secs because it is necesary inititialize
      :timer.sleep(5_000)
      apply(__MODULE__, :every_minute_tasks, [])
    end)
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

  def add_task(bot_name, channel, quoted_pattern, quoted_func) do
    :ets.insert(:volatile_db, {:task, bot_name, channel, quoted_pattern, quoted_func})
  end
  def add_task(bot_name, channel, quoted_pattern, quoted_guard, quoted_func) do
    :ets.insert(:volatile_db, {:task, bot_name, channel, quoted_pattern, quoted_guard, quoted_func})
  end

  def every_minute_tasks() do
    now = Macro.escape(:calendar.local_time())
    every_minute_tasks_h(:ets.tab2list(:volatile_db), now)
    :timer.apply_after(60_000, __MODULE__, :every_minute_tasks, [])
  end

  defp every_minute_tasks_h([], _), do: :ok

  # task without guard
  defp every_minute_tasks_h([{:task, bot_name, channel, quoted_pattern, quoted_func} | tasks], now) do
    Code.eval_quoted(quote do
      case unquote(now) do
        unquote(quoted_pattern) ->
          # Get channel subscribers from db
          subscribers = Bobot.Utils.get_channel_subscribers({unquote(bot_name), unquote(channel)})

          # If there are not subs it is not worth run the task
          if length(subscribers) > 0 do
            require Logger
            # Run the 'every' function and save the result as message
            func = unquote(quoted_func)
            message =
              try do
                func.(unquote(bot_name), unquote(channel))
              rescue
                _ -> "ERROR running task!"
              end

            Logger.log(:info, "[Bobot][Tasks] Sending news for channel '#{unquote(channel)}' to #{inspect subscribers}")
            Bobot.Utils.get_bot_module(unquote(bot_name)).inform_to_subscribers(subscribers, message)
          end

        _ ->
          nil
      end
    end)

    every_minute_tasks_h(tasks, now)
  end

  # task with guard
  defp every_minute_tasks_h([{:task, bot_name, channel, quoted_pattern, quoted_guard, quoted_func} | tasks], now) do
    Code.eval_quoted(quote do
      case unquote(now) do
        unquote(quoted_pattern) when (unquote(quoted_guard)) ->
          # Get channel subscribers from db
          subscribers = Bobot.Utils.get_channel_subscribers({unquote(bot_name), unquote(channel)})

          # If there are not subs it is not worth run the task
          if length(subscribers) > 0 do
            require Logger
            # Run the 'every' function and save the result as message
            func = unquote(quoted_func)
            message =
              try do
                func.(unquote(bot_name), unquote(channel))
              rescue
                _ -> "ERROR running task!"
              end

            Logger.log(:info,
              "[Bobot][Tasks] Sending news for channel '#{unquote(channel)}' to #{inspect subscribers}"
            )
            Bobot.Utils.get_bot_module(unquote(bot_name)).inform_to_subscribers(subscribers, message)
          end

        _ ->
          nil
      end
    end)

    every_minute_tasks_h(tasks, now)
  end

end
