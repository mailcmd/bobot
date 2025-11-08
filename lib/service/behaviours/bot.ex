defmodule Bobot.Bot do
  defmacro __using__(opts) do
    name = "#{__CALLER__.module}"
      |> String.split(".")
      |> Enum.reverse()
      |> hd()

      type = opts
      |> Keyword.fetch!(:type)
      |> to_string()
      |> Macro.camelize()

    type_module = String.to_atom("Elixir.Bobot.DSL.#{type}")
    Code.ensure_compiled!(type_module)

    config = Keyword.get(opts, :config, [])
    api = Keyword.get(config, :use_api)

    quote do
      @after_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :bot_name, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_config, persist: true, accumulate: false)
      Module.register_attribute(__MODULE__, :bot_api, persist: true, accumulate: false)
      @bot_name unquote(name)
      @bot_config unquote(config)
      @bot_api unquote(api)

      import Bobot.DSL.Base
      use unquote(type_module), config: unquote(config)
      import Bobot.Tools
    end
  end

  defmacro __after_compile__(_env, _) do
    quote do
      def run_command(cmd, _), do: IO.inspect(cmd, label: "FALLBACK")
    end
  end
end
