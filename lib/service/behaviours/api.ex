defmodule Bobot.API do
  defmacro __using__(_opts) do
    quote do
      @behaviour Bobot.API
    end
  end

  @callback call(call_id::atom(), call_args::any()) :: map()
end
