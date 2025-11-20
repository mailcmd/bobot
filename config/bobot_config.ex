defmodule Bobot.Config do

  Module.register_attribute(__MODULE__, :available_bots, persist: true, accumulate: false)
  @available_bots [:smi, :spi_support, :telegram_test, :telegram_test_x]

  Module.register_attribute(__MODULE__, :available_apis, persist: true, accumulate: false)
  @available_apis [:smi, :spi_support, :test]

  Module.register_attribute(__MODULE__, :available_libs, persist: true, accumulate: false)
  @available_libs [:common]

  def get_available_bots(), do: @available_bots
  def get_available_apis(), do: @available_apis
  def get_available_libs(), do: @available_libs

  Module.register_attribute(__MODULE__, :telegram_bots, persist: true, accumulate: false)
  @telegram_bots [:smi]

  def get_active_bots(), do: @telegram_bots

end
