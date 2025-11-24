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

  @http_default_opts [
    method: :get,
    auth: :none,
    post_data: %{}
  ]

  def http_request(url, opts \\ []) do
    opts = Keyword.merge(@http_default_opts, opts)

    url = url
      |> URI.encode()
      |> URI.encode(&(&1 != ?#))

    client =
      case opts[:auth] do
        :none ->
          []
        :basic ->
          [ {Tesla.Middleware.BasicAuth, %{username: opts[:username], password: opts[:password]}} ]
      end
      ++
      case opts[:method] do
        :post -> [
            {Tesla.Middleware.FormUrlencoded,
              encode: &Plug.Conn.Query.encode/1,
              decode: &Plug.Conn.Query.decode/1
            }
          ]

        _ -> []
      end

    result =
      case opts[:method] do
        :get -> Tesla.get(Tesla.client(client), url)
        :post -> Tesla.post(Tesla.client(client), url, opts[:post_data])
      end

    with  {:ok, %Tesla.Env{body: body}} <- result,
          {:ok, json} <- Jason.decode(body, keys: :atoms) do
      json
    else
      error -> %{error: error}
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
        try do
          run(unquote(start), unquote(params), var!(sess_id))
          if unquote(stop) do
            run(unquote(stop), nil, var!(sess_id))
          end
          Bobot.Bot.Assigns.unset(var!(sess_id))
        rescue
          error ->
            require Logger
            Logger.log(:error, "#{inspect error}")
            run(unquote(fallback), nil, var!(sess_id))
        end
      end
    end
  end

  defmacro defblock(name, opts \\ [], do: block) do
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
      apis = __MODULE__.__info__(:attributes) |> Keyword.get(:bot_apis)
      res = try_apis(apis, unquote(id), unquote(params))
      Bobot.Bot.Assigns.put_in(var!(sess_id), [unquote(id)], res)
    end
  end

  # HTTP
  defmacro call_http(url, opts \\ []) do
    store_key = Keyword.fetch!(opts, :store_in)
    quote do
      res = http_request(unquote(url), unquote(opts))
      Bobot.Bot.Assigns.put_in(var!(sess_id), [unquote(store_key)], res)
    end
  end

  # EVERY
  defmacro every(pattern, do: block) do
    pattern = Macro.escape(pattern)
    func = Macro.escape(quote do
      fn (var!(module), var!(channel)) ->
        Code.eval_quoted(unquote(Macro.escape(block)), [module: var!(module), channel: var!(channel)]) |> elem(0)
      end
    end)
    quote do
      Bobot.Tools.task_every_add(__MODULE__, var!(channel_name), unquote(pattern), unquote(func))
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

  # defmacro defcall(name, vars \\ [], do: block) do

  #   quote do
  #     @impl true
  #     def call(unquote(name), unquote(vars)) when unquote(guards_expr) do
  #       unquote(block)
  #     end
  #   end
  # end


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
