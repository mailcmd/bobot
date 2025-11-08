defmodule Bobot.DSL.Base.Parser do

  def info(:sentencies) do
    [
      {"defbot", %{module: Bobot.DSL.Base.Templates, type: :base, visible: false}},
      {"hooks", %{module: Bobot.DSL.Base.Templates, type: :base, visible: true}},
      {"defblock", %{module: Bobot.DSL.Base.Templates, type: :base, visible: true}},
      {"call_block", %{module: Bobot.DSL.Base.Templates, type: :base, visible: true}},
      {"call_api", %{module: Bobot.DSL.Base.Templates, type: :base, visible: true}},
      {"case", %{module: Bobot.DSL.Base.Templates, type: :base, visible: true}}
    ]
  end

  ################################################################################################
  ## Parser
  ################################################################################################
  def parse(sentencies) do
    sentencies
      |> parse_h()
      |> format
  end
  defp parse_h(sentencies, accum \\ "")
  defp parse_h([], accum), do: accum
  defp parse_h([ part | rest], accum) do
    accum = "#{accum}#{parse_sentency(part)}"
    parse_h(rest, accum)
  end

  # bot_config
  def parse_sentency([:hooks, opts]) when is_list(opts) do
    opts = opts
      |> Enum.map(fn {k, v} -> "#{k}: #{Macro.to_string(v)}" end)
      |> Enum.join(",\n")
    "hooks [\n#{opts}\n]\n\n"
  end

  # block
  def parse_sentency([:block, name, [receive: variables], block]) when is_list(block) do
    "block :#{name}, receive: #{Macro.to_string(variables)} do\n#{parse_h(block)}end\n"
  end
  def parse_sentency([:block, name, block]) when is_list(block) do
    "block :#{name} do\n#{parse_h(block)}end\n"
  end

  # call_api
  def parse_sentency([:call_api, call_id, [params: params]]) do
    "call_api :#{call_id}, params: #{Macro.to_string(params)}\n"
  end

  # call_block
  def parse_sentency([:call_block, block_id, [params: params]]) do
    "call_block :#{block_id}, params: #{Macro.to_string(params)}\n"
  end
  def parse_sentency([:call_block, block_id]) do
    "call_block :#{block_id}\n"
  end

  # case
  def parse_sentency([:case, value, patterns]) do
    """
    case #{Macro.to_string(value)} do
      #{parse_case_h(patterns)}end
    """
  end

  # fallback
  def parse_sentency(sentency) do
    parse_sentency_module(get_extra_parsers(), sentency)
  end

  defp parse_sentency_module([], sentency) do
    raise "ERROR: Unkonw sentency '#{inspect hd(sentency)}'"
  end
  defp parse_sentency_module([module | rest], sentency) do
    try do
      apply(module, :parse_sentency, [sentency])
    rescue
      _ -> parse_sentency_module(rest, sentency)
    end
  end

  # Helpers
  defp parse_case_h([]), do: ""
  defp parse_case_h([[pattern, block] | rest]) do
    "#{Macro.to_string(pattern)} ->\n#{parse_h(block)}" <> parse_case_h(rest)
  end

  ################################################################################################
  ## Formatter
  ################################################################################################

  def format(string) do
    string
      |> Code.format_string!(line_length: 150, migrate: true)
      |> IO.iodata_to_binary()
      |> String.replace(~r/[\(\)]/, " ")
  end


  ################################################################################################
  ## Save to file
  ################################################################################################

  def to_file(string, filename) when is_binary(string) do
    File.write(filename, string)
  end
  def to_file(sentencies, filename) when is_list(sentencies) do
    sentencies
      |> parse()
      |> to_file(filename)
  end

  ################################################################################################
  ## Private tools
  ################################################################################################

  defp get_extra_parsers() do
    Bobot.Tools.get_modules(~r/^Elixir\.Bobot\.DSL\.[^\.]+\.Parser/)
    # re = "^Elixir\\.Bobot\\.DSL\\.[^\\.]+\\.Parser" |> String.replace(".", "\.", global: true) |> Regex.compile!()
    # :application.get_key(:bobot, :modules)
    #   |> elem(1)
    #   |> Enum.map( &(to_string(&1)) )
    #   |> Enum.filter( &(String.match?(&1, re) and &1 != "Elixir.Bobot.DSL.Base.Parser") )
    #   |> Enum.map( &(String.to_existing_atom(&1)) )
  end

end
