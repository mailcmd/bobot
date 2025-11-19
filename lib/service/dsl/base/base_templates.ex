defmodule Bobot.DSL.Base.Templates do
  # import Phoenix.Component

  ################################################################################################
  ## SHOWs
  ################################################################################################

  def show(sentency, assigns) do
    Phoenix.Template.render(BobotWeb.DSLTemplates, sentency, "html", assigns)
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  def save("defbot", params, assigns) do
    name = String.to_atom(params["name"])
    cond do
      # New BOT
      (assigns[:bots] == nil and get_in(assigns[:bots], [name]) == nil)
      or
      # Edit BOT
      assigns[:bots] != nil ->
        {:ok, "Bot defined succesfully!", %{
          name: String.to_atom(params["name"]),
          type: String.to_atom(params["type"]),
          use_apis: (params["use_apis"] || "")
            |> String.split(",", trim: true)
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_atom/1),
          use_libs: (params["use_libs"] || "")
            |> String.split(",", trim: true)
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_atom/1)
        }}

      true ->
        {:error, "Already exists a bot with this name!", nil}
    end
  end

  def save("defapi", params, assigns) do
    name = String.to_atom(params["name"])
    case get_in(assigns[:bots], [name]) do
      nil ->
        {:ok, "API created succesfully!", %{
          name: String.to_atom(params["name"])
        }}

      _ ->
        {:error, "Already exists an API with this name!", nil}
    end
  end

  def save("deflib", params, assigns) do
    name = String.to_atom(params["name"])
    case get_in(assigns[:bots], [name]) do
      nil ->
        {:ok, "LIB created succesfully!", %{
          name: String.to_atom(params["name"])
        }}

      _ ->
        {:error, "Already exists a LIB with this name!", nil}
    end
  end

  def save("hooks", params, _assigns) do
    hooks = [
      start_block: String.to_atom(params["start_block"]),
      start_params_count: String.to_integer(params["start_params_count"]),
      stop_block: String.to_atom(params["stop_block"]),
      fallback_block: String.to_atom(params["fallback_block"])
    ]
    {:ok, "Hooks set!", hooks}
  end

  def save("defblock", params, assigns) do
    name = String.to_atom(params["name"])
    case get_in(assigns[:current_bot], [:body, name]) do
      nil ->
        prms =
          case String.trim(params["params"]) do
            "" -> []
            prm -> "[receive: #{prm}]" |> Code.string_to_quoted() |> elem(1)
          end

        {:ok, nil, %{
          name => %{
            params: prms,
            block: []
          }
        }}
      _ ->
        {:error, "Already exists a block with this name!", nil}
    end
  end

  def save("defcall", params, assigns) do
    name = String.to_atom(params["name"])
    case get_in(assigns[:current_api], [:calls, name]) do
      nil ->
        prms =
          case String.trim(params["params"]) do
            "" -> []
            prm -> "[#{prm}]" |> Code.string_to_quoted() |> elem(1)
          end

        {:ok, nil, %{
          name => %{
            params: prms,
            call: []
          }
        }}
      _ ->
        {:error, "Already exists a block with this name!", nil}
    end
  end
end
