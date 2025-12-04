defmodule Bobot.Bot do
  defmacro __using__(opts) do
    name = "#{__CALLER__.module}"
      |> String.split(".")
      |> Enum.reverse()
      |> hd()

    bot_type = Keyword.fetch!(opts, :type)

    type = bot_type
      |> to_string()
      |> Macro.camelize()

    type_module = String.to_atom("Elixir.Bobot.DSL.#{type}")
    Code.ensure_compiled!(type_module)

    apis = Keyword.get(opts, :use_apis) || []
    libs = Keyword.get(opts, :use_libs) || []

    import_libs = Enum.map(libs, fn module ->
      module = String.to_atom("Elixir.Bobot.Lib.#{module |> to_string() |> Macro.camelize()}")
      Code.ensure_compiled!(module)
      quote do
        import unquote(module)
      end
    end)

    config = Keyword.get(opts, :config, [])

    quote do
      Module.register_attribute(__MODULE__, :bot_name, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_type, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_config, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_apis, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_libs, persist: true, accumulate: false)

      @bot_name unquote(name) |> Macro.underscore() |> String.to_atom()
      @bot_type unquote(bot_type)
      @bot_config unquote(config)
      @bot_apis unquote(apis)
      @bot_libs unquote(libs)

      Module.register_attribute(__MODULE__, :positions, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :connections, persist: true, accumulate: false)

      require Logger

      use unquote(type_module), config: unquote(config)
      use Bobot.DSL.Base
      import Bobot.Utils

      unquote(import_libs)

      @behaviour Bobot.Bot
    end
  end

  @callback inform_to_subscribers(subs::list(), message::(String.t | map()))
    :: any()

  @callback launch() :: any()
  @callback stop() :: any()
end
