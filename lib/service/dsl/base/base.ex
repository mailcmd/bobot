defmodule Bobot.DSL.Base do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import Bobot.DSL.Base

      def init_channels() do
        bot_channels = :attributes
          |> __MODULE__.__info__()
          |> Keyword.get(:bot_channels, [])
          |> Enum.map(fn {c, _} -> c end)
        Enum.each(bot_channels, fn channel ->
          init_channel(channel)
        end)
        :ok
      end
    end
  end


  ################################################################################################
  ## UTILS
  ################################################################################################

  def try_apis([], _, _), do: %{error: :api_call_not_found}
  def try_apis([api | apis], id, params) do
    try do
      api = String.to_existing_atom("Elixir.Bobot.API.#{api |> to_string() |> Macro.camelize()}")
      api.call(id, params)
    rescue
      _ ->
       try_apis(apis, id, params)
    end    
  end


  ################################################################################################
  ## MACROS BOT
  ################################################################################################

  defmacro defbot(name, opts \\ [], do: block) do
    name = name |> to_string() |> Macro.camelize() |> String.to_atom()
    name = {:__aliases__, [alias: false], [:Bobot, :Bot, name]}
    type = Keyword.fetch!(opts, :type)
    config = Keyword.get(opts, :config, [])
    use_apis = Keyword.get(opts, :use_apis, [])
    use_libs = Keyword.get(opts, :use_libs, [])
    quote do
      defmodule unquote(name) do
        use Bobot.Bot,
          type: unquote(type),
          use_apis: unquote(use_apis),
          use_libs: unquote(use_libs),
          config: unquote(config)
        unquote(block)
      end
    end
  end

  defmacro hooks(opts \\ []) do
    start = Keyword.get(opts, :start_block)
    params = Keyword.get(opts, :start_params_count, 0)
    params = (for l <- ?a..?z, do: <<l>>)
      |> Enum.take(params)
      |> Enum.map(fn l -> Code.eval_string("{:#{l}, [], nil}") |> elem(0) end)
    params =
      cond do
        length(params) == 0 -> {:_, [], nil}
        length(params) == 1 -> hd(params)
        true -> params
      end
    stop = Keyword.get(opts, :stop_block)
    fallback = Keyword.get(opts, :fallback_block)
    quote do
      @fallback_block unquote(fallback)
      def start_bot(unquote(params) = prms, var!(sess_id), assigns \\ %{}) do
        Bobot.Utils.Assigns.set_all(var!(sess_id), assigns)
        try do
          run(unquote(start), prms, var!(sess_id))
          if unquote(stop) do
            run(unquote(stop), nil, var!(sess_id))
          end
          Bobot.Utils.Assigns.unset(var!(sess_id))
        rescue
          error ->
            require Logger
            Logger.log(:error, "#{inspect error}")
            run(unquote(fallback), nil, var!(sess_id))
            Bobot.Utils.Assigns.unset(var!(sess_id))
        end
      end
    end
  end

  defmacro constants(keywords) do
    for {k, v} <- keywords do
      quote do
        Module.register_attribute(__MODULE__, unquote(k), persist: true, accumulate: false)
        Module.put_attribute(__MODULE__, unquote(k), unquote(v))
      end
    end
  end

  ## BLOCK
  defmacro defblock(name, opts \\ [], do: block) do
    vars = Keyword.get(opts, :receive, {:_, [], nil})
    quote do
      def run(unquote(name), unquote(vars), var!(sess_id)) do
        unquote(block)
        catch
          value -> value
      end
    end
  end

  ## COMMAND
  defmacro defcommand(command, do: block) do
    quote do
      def run_command(unquote(command), var!(sess_id), var!(assigns)) do
        unquote(block)
        catch
          value -> value
      end
    end
  end

  ## CHANNEL
  defmacro defchannel(channel, opts \\ [], do: block) do
    description = Keyword.get(opts, :description, "")
    quote do
      @bot_channels {unquote(channel), unquote(description)}
      def init_channel(unquote(channel) = var!(channel_name)) do
        unquote(block)
      end
    end
  end

  ################################################################################################
  ################################################################################################
  defmacro call_block(name, opts \\ []) do
    params = Keyword.get(opts, :params, nil)
    quote do
      apply(__MODULE__, :run, [unquote(name), unquote(params), var!(sess_id)])
    end
  end

  ## BREAK
  defmacro break(returning: value) do
    quote do
      throw(unquote(value))
    end
  end

  defmacro break() do
    quote do
      break(returning: nil)
    end
  end

  ## VALUE_OF / SESSION_VALUE / SESSION_DATA
  defmacro session_data() do
    quote do
      Bobot.Utils.Assigns.get_all(var!(sess_id))
    end
  end
  defmacro session_value(keys) when is_list(keys) do
    quote do
      Bobot.Utils.Assigns.get_in(var!(sess_id), unquote(keys))
    end
  end
  defmacro session_value(key) do
    quote do
      Bobot.Utils.Assigns.get(var!(sess_id), unquote(key))
    end
  end
  defmacro session_value(key, is: val) do
    quote do
      session_value(unquote(key)) == unquote(val)
    end
  end
  defmacro session_value(key, is_not: val) do
    quote do
      session_value(unquote(key)) != unquote(val)
    end
  end
  defmacro session_value(key, contains: val) when is_binary(val) do
    quote do
      String.match?(session_value(unquote(key)), Regex.compile!("#{unquote(val)}"))
    end
  end
  defmacro session_value(key, icontains: val) when is_binary(val) do
    quote do
      String.match?(session_value(unquote(key)), Regex.compile!("#{unquote(val)}", "i"))
    end
  end
  defmacro session_value(key, match: val) do
    quote do
      String.match?(session_value(unquote(key)), unquote(val))
    end
  end

  ## Just for backward compatibility
  defmacro value_of(key) do
    quote do
      session_value(unquote(key))
    end
  end
  defmacro value_of(key, opts)do
    quote do
      session_value(unquote(key), unquote(opts))
    end
  end

  ## STORE
  defmacro session_store(keys, values) when is_list(keys) do
    quote do
      Bobot.Utils.Assigns.put_in(var!(sess_id), unquote(keys), unquote(values))
    end
  end
  defmacro session_store(values) when is_list(values) or is_map(values) do
    quote do
      Enum.each(unquote(values), fn {key, val} ->
        Bobot.Utils.Assigns.put(var!(sess_id), key, val)
      end)
    end
  end
  defmacro session_store({keys, values}) when is_list(keys) do
    quote do
      session_store(unquote(keys), unquote(values))
    end
  end

  # API
  defmacro call_api(id, opts \\ []) do
    params = Keyword.get(opts, :params, nil)
    quote do
      apis = __MODULE__.__info__(:attributes) |> Keyword.get(:bot_apis)
      res = try_apis(apis, unquote(id), unquote(params))
      Bobot.Utils.Assigns.put_in(var!(sess_id), [unquote(id)], res)
    end
  end

  # HTTP
  defmacro call_http(url, opts \\ []) do
    store_key = Keyword.fetch!(opts, :store_in)
    quote do
      res = Bobot.Utils.http_request(unquote(url), unquote(opts))
      Bobot.Utils.Assigns.put_in(var!(sess_id), [unquote(store_key)], res)
    end
  end

  # EVERY
  defmacro every(pattern, opts \\ [], do: block) do
    pattern = Macro.escape(pattern)
    func = Macro.escape(quote do
      fn (var!(module), var!(channel)) ->
        Code.eval_quoted(unquote(Macro.escape(block)), [module: var!(module), channel: var!(channel)]) |> elem(0)
      end
    end)
    guard = Keyword.get(opts, :when, nil)
    if guard != nil do
      guard = Macro.escape(guard)
      quote do
        Bobot.Task.add_task(@bot_name, var!(channel_name), unquote(pattern), unquote(guard), unquote(func))
      end
    else
      quote do
        Bobot.Task.add_task(@bot_name, var!(channel_name), unquote(pattern), unquote(func))
      end
    end
  end

  ################################################################################################
  ## MACROS API
  ################################################################################################

  defmacro defapi(name, do: block) do
    name = name |> to_string() |> Macro.camelize() |> String.to_atom()
    name = {:__aliases__, [alias: false], [:Bobot, :API, name]}
    quote do
      defmodule unquote(name) do
        use Bobot.API
        require Logger

        unquote(block)
      end
    end
  end

  defmacro defcall(name, do: block) do
    quote do
      @impl true
      def call(unquote(name), nil) do
        unquote(block)
      end
    end
  end

  defmacro defcall(name, vars, do: block) do
    quote do
      @impl true
      def call(unquote(name), unquote(vars)) do
        unquote(block)
      end
    end
  end

  defmacro defcall(name, vars, [when: expr], do: block) do
    quote do
      @impl true
      def call(unquote(name), unquote(vars)) when unquote(expr) do
        unquote(block)
      end
    end
  end


  ################################################################################################
  ## MACROS LIB
  ################################################################################################

  defmacro deflib(name, do: block) do
    name = name |> to_string() |> Macro.camelize() |> String.to_atom()
    name = {:__aliases__, [alias: false], [:Bobot, :Lib, name]}
    quote do
      defmodule unquote(name) do
        unquote(block)
      end
    end
  end
end
