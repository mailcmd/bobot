defmodule Bobot.DSL.Base do
  @moduledoc """
  This base module add the following sentencies:

    - bot_config [
        start_block: <start_block>,
        start_params: <vars>,
        stop_block: <stop_block>,
        fallback_block: <fallback_block>
      ]
      [#] Configure the bot's main blocks

    - block [attrs] do ... end
      [#] Define a block and its logic

    - value_of <key> [, <operator>: value]
      [#] With just the key, get the value stored in the current session, plus "<operator>: value"
          eval the expression and return true or false.

    - session_value <key> [, <operator>: value]
      [#] Same as 'value_of'.

    - store <kw_pairs>
      [#] Store in session the keyword pairs. You can access this values witn 'value_of' or
          'session_value'.

    - call_block <block_name> [, params: <params>]
      [#] Jump bot running flow to the block <block_name>

    - call_api <call_id>, params: <params>
      [#] Call the api and the map resulting from the call is added to sessions values.

  """

  ################################################################################################
  ## UTILS
  ################################################################################################


  ################################################################################################
  ## MACROS
  ################################################################################################

  defmacro defbot(name, opts \\ [], do: block) do
    name = name |> to_string() |> Macro.camelize() |> String.to_atom()
    name = {:__aliases__, [alias: false], [:Bobot, :Bot, name]}
    type = Keyword.fetch!(opts, :type)
    config = Keyword.get(opts, :config, [])
    quote do
      defmodule unquote(name) do
        use Bobot.Bot,
          type: unquote(type),
          config: unquote(config)

        unquote(block)
      end
    end
  end

  ## BLOCK
  defmacro hooks(opts \\ []) do
    start = Keyword.fetch!(opts, :start_block)
    params = Keyword.get(opts, :start_params_count, 0)
    params = (for l <- ?a..?z, do: <<l>>)
      |> Enum.take(params)
      |> Enum.map(fn l -> Code.eval_string("{:#{l}, [], nil}") |> elem(0) end)
    params =
      cond do
        length(params) == 0 -> nil
        length(params) == 1 -> hd(params)
        true -> params
      end
    stop = Keyword.get(opts, :stop_block, nil)
    fallback = Keyword.fetch!(opts, :fallback_block)
    quote do
      @fallback_block unquote(fallback)
      def start_bot(unquote(params), var!(sess_id), assigns \\ %{}) do
        Bobot.Bot.Assigns.set_all(var!(sess_id), assigns)
        # try do
          run(unquote(start), unquote(params), var!(sess_id))
          if unquote(stop) do
            run(unquote(stop), nil, var!(sess_id))
          end
          Bobot.Bot.Assigns.unset(var!(sess_id))
        # rescue
        #   error ->
        #     require Logger
        #     Logger.log(:error, "#{inspect error}")
        #     run(unquote(fallback), nil, var!(sess_id))
        # end
      end
    end
  end

  defmacro defblock(name, opts \\ [], do: block) do
    quote do
      block(unquote(name), unquote(opts), do: unquote(block))
    end
  end

  defmacro block(name, opts \\ [], do: block) do
    vars = Keyword.get(opts, :receive, nil)
    quote do
      def run(unquote(name), unquote(vars), var!(sess_id)) do
        unquote(block)
      end
    end
  end

  defmacro call_block(name, opts \\ []) do
    params = Keyword.get(opts, :params, nil)
    quote do
      apply(__MODULE__, :run, [unquote(name), unquote(params), var!(sess_id)])
    end
  end

  ## VALUE_OF / SESSION_VALUE / SESSION_DATA
  defmacro session_data() do
    quote do
      Bobot.Bot.Assigns.get_all(var!(sess_id))
    end
  end
  defmacro value_of(keys) when is_list(keys) do
    quote do
      Bobot.Bot.Assigns.get_in(var!(sess_id), unquote(keys))
    end
  end
  defmacro value_of(key) do
    quote do
      Bobot.Bot.Assigns.get(var!(sess_id), unquote(key))
    end
  end
  defmacro value_of(key, is: val) do
    quote do
      value_of(unquote(key)) == unquote(val)
    end
  end
  defmacro value_of(key, is_not: val) do
    quote do
      value_of(unquote(key)) != unquote(val)
    end
  end
  defmacro value_of(key, contains: val) when is_binary(val) do
    quote do
      String.match?(value_of(unquote(key)), Regex.compile!("#{unquote(val)}"))
    end
  end
  defmacro value_of(key, icontains: val) when is_binary(val) do
    quote do
      String.match?(value_of(unquote(key)), Regex.compile!("#{unquote(val)}", "i"))
    end
  end
  defmacro value_of(key, match: val) do
    quote do
      String.match?(value_of(unquote(key)), unquote(val))
    end
  end
  defmacro session_value(key) do
    quote do
      value_of(unquote(key))
    end
  end
  defmacro session_value(key, opts)do
    quote do
      value_of(unquote(key), unquote(opts))
    end
  end

  ## STORE
  defmacro session_store(values) when is_list(values) or is_map(values) do
    quote do
      Enum.each(unquote(values), fn {key, val} ->
        Bobot.Bot.Assigns.put(var!(sess_id), key, val)
      end)
    end
  end
  defmacro session_store({keys, values}) when is_list(keys) do
    quote do
      Bobot.Bot.Assigns.put_in(var!(sess_id), unquote(keys), unquote(values))
    end
  end

  # API
  defmacro call_api(id, opts \\ []) do
    params = Keyword.get(opts, :params, nil)
    quote do
      api = __MODULE__.__info__(:attributes) |> Keyword.get(:bot_api) |> hd()
      res = api.call(unquote(id), unquote(params))
      new_assigns = Map.merge(Bobot.Bot.Assigns.get_all(var!(sess_id)), res)
      Bobot.Bot.Assigns.set_all(var!(sess_id), new_assigns)
    end
  end

end
