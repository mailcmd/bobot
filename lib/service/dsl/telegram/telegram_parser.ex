defmodule Bobot.DSL.Telegram.Parser do

  def info(:sentencies) do
    [
      {"command", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"await_response", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"terminate", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"send_message", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"send_menu", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"edit_message", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"pin_message", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"unpin_message", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"settings_set", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"settings_get", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: true}},
      {"settings", %{module: Bobot.DSL.Telegram.Templates, type: :telegram, visible: false}}
    ]
  end

  ################################################################################################
  ## Parser
  ################################################################################################
  def parse_sentency([:await_response, opts]) do
    "await_response #{Macro.to_string(opts)}\n"
  end

  # terminate
  def parse_sentency([:terminate, [message: message]]) do
    "terminate message: #{Macro.to_string(message)}\n"
  end

  # send_message
  def parse_sentency([:send_message, message]) do
    "send_message #{Macro.to_string(message)}\n"
  end

end
