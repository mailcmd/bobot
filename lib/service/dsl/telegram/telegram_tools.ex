defmodule Bobot.DSL.Telegram.Tools do

  def info(:sentencies) do
    [
      {"command", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"await_response", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"terminate", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"send_message", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"send_menu", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"edit_message", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"pin_message", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"unpin_message", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"settings_set", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"settings_get", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }},
      {"settings", %{
        template: Bobot.DSL.Telegram.Templates,
        tools: Bobot.DSL.Telegram.Tools,
        type: :telegram
      }}
    ]
  end

  ################################################################################################
  ## Parser
  ################################################################################################
  def parse_sentency(line) do
    Bobot.DSL.Base.Tools.parse_sentency(line)
  end

end
