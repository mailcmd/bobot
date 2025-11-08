defmodule Bobot.DSL.Base.Templates do
  # import Phoenix.Component

  ################################################################################################
  ## SHOWs
  ################################################################################################

  def show(sentency, assigns) do
    Phoenix.Template.render(BobotWeb.Templates, sentency, "html", assigns)
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  def save("defbot", params, _assigns) do
    {:ok, "Bot created succesfully!", %{
      name: String.to_atom(params["name"]),
      type: String.to_atom(params["type"])
    }}
  end

  def save("hooks", params, _assigns) do
    hooks = [
      start_block: String.to_atom(params["start_block"]),
      start_params_count: String.to_integer(params["start_params_count"]),
      stop_block: String.to_atom(params["stop_block"]),
      fallback_block: String.to_atom(params["fallback_block"])
    ]
    {:ok, "Hooks added!", hooks}
  end

  def save("defblock", params, assigns) do
    level = assigns[:current_bot][:current_level] || 0
    name = String.to_atom(params["name"])
    parameters = Bobot.Tools.quote_string(params["params"])
    {:ok, nil, [level, :defblock, [name, parameters]]}
  end

end
