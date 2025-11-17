defmodule Bobot.DSL.Base.Tools do

  def info(:sentencies) do
    [
      {"defbot", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: false
      }},
      {"hooks", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"defblock", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"call_block", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"call_api", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"case", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"pattern", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }},
      {"defapi", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: false
      }},
      {"defcall", %{
        template: Bobot.DSL.Base.Templates,
        tools: Bobot.DSL.Base.Tools,
        type: :base,
        visible: true
      }}
    ]
  end

  ################################################################################################
  ## Parser
  ################################################################################################

  def parse_sentency([level, :case, [params]]) do
    "#{String.duplicate(" ", (level-1)*2)}case #{Macro.to_string(params)} do"
  end
  def parse_sentency([level, :pattern, [params]]) do
    "#{String.duplicate(" ", (level-1)*2)}#{Macro.to_string(params)} -> "
  end
  def parse_sentency([level, sentency, params]) do
    params =
      params
      |> Enum.map(&Macro.to_string/1)
      |> Enum.join(", ")
    "#{String.duplicate(" ", (level-1)*2)}#{sentency} #{params}\n"
  end

end
