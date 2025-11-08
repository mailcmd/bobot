defmodule BobotWeb.Home do
  use BobotWeb, :live_view
  import BobotWeb.Components

  @doc """
  Assigns:
  - sentencies: %{
    "defbot" => %{module: <module>, type: <type>, visible: <boolean>},
    ...
  }

  - bots: ...

  - modal: %{
      title: <string>,
      template: %{
        module: <module>,
        sentency: <string>
      }
    }

  - current_bot: %{
      definition: %{name: <atom>, type: <atom>},
      config: [],
      hooks: [],
      body: [],
      current_line: 0,
      current_level: 0,
      current_ope: "put"
    }


  """
  def mount(_params, _session, socket) do

    {:ok, socket
      |> assign(sentencies: get_sentencies())
      |> assign(bots: %{})
      |> assign(modal: %{})
      |> assign(current_bot: %{
        definition: %{},
        config: [],
        hooks: [],
        body: [],
        current_line: 0,
        current_level: 0,
        current_ope: "put"
      })
    }
  end

  ################################################################################################
  ## SHOWs
  ################################################################################################

  ## Specific SHOW for settings
  def handle_event("show:settings", _params, socket) do
    type = socket.assigns[:current_bot][:definition][:type] |> to_string() |> Macro.camelize()
    module = "Elixir.Bobot.DSL.#{type}.Templates"
    {:noreply, socket
      |> open_modal(%{
        template: %{module: String.to_existing_atom(module), sentency: "settings"},
        title: "Configure bot"
      })
    }
  end

  ## Specific SHOW for hooks
  def handle_event("show:hooks", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "hooks"},
        title: "Set hooks"
      })
    }
  end

  ## Generic SHOWs
  ## title can carry "<title>[:<line>:<level>:<ope>]"
  def handle_event("show:" <> sentency, %{"value" => "modal:" <> title}, socket) do
    assigns = socket.assigns

    [title | rest] = String.split(title, ":")
    {line, level, ope} =
      case rest do
        [] -> {
            get_in(assigns, [:current_bot, :current_line]),
            get_in(assigns, [:current_bot, :current_level]),
            "put"
          }

        [line, level, ope] -> {
            parse_integer(line, get_in(assigns, [:current_bot, :current_line])),
            parse_integer(level, get_in(assigns, [:current_bot, :current_level])),
            ope
          }
      end

    current_bot = %{assigns[:current_bot] |
      current_level: level,
      current_line: line,
      current_ope: ope
    }

    {:noreply, socket
      |> assign(current_bot: current_bot)
      |> assign(editing_line: get_editing_line(current_bot))
      |> open_modal(%{
        template: %{module: Bobot.DSL.Base.Templates, sentency: sentency},
        title: title
      })
    }
  end

  def handle_event("show:" <> _sentency, _params, socket) do
    {:noreply, socket
      # |> open_modal(%{
      #   template: %{module: Bobot.DSL.Base.Templates, sentency: "defbot"},
      #   title: "New bot..."
      # })
    }
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  ## Specific SAVE for new_bot
  def handle_event("save:defbot", params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies]["defbot"][:module]
    {result, message, def} = apply(module, :save, ["defbot", params, assigns])

    socket =
      case result do
        :ok ->
          socket
            |> assign(current_bot: %{assigns[:current_bot] | definition: def})
            |> assign(bots: Map.put(assigns[:bots], def[:name], def[:name]))

        :error ->
          socket
      end

    {:noreply, socket
      |> assign(last_result: result)
      |> close_modal()
      |> put_message(message)
    }
  end

  ## Specific SAVE for settings
  def handle_event("save:settings", params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies]["settings"][:module]
    {result, message, config} = apply(module, :save, ["settings", params, assigns])

    socket =
      case result do
        :ok ->
          socket
            |> assign(current_bot: put_in(assigns[:current_bot], [:config], config))

        :error ->
          socket
      end

    {:noreply, socket
      |> assign(last_result: result)
      |> close_modal()
      |> put_message(message)
    }
  end

  ## Specific SAVE for hooks
  def handle_event("save:hooks", params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies]["hooks"][:module]
    {result, message, hooks} = apply(module, :save, ["hooks", params, assigns])

    socket =
      case result do
        :ok ->
          socket
            |> assign(current_bot: put_in(assigns[:current_bot], [:hooks], hooks))

        :error ->
          socket
      end

    {:noreply, socket
      |> assign(last_result: result)
      |> close_modal()
      |> put_message(message)
    }
  end

  ## Generic SAVE
  def handle_event("save:" <> sentency, params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies][sentency][:module]
    {result, message, line} = apply(module, :save, [sentency, params, assigns])

    socket =
      case result do
        :ok ->
          current_line = get_in(assigns, [:current_bot, :current_line])
          body = assigns[:current_bot][:body]
          current_bot = assigns[:current_bot]
            |> update_in([:body], fn body ->
              cond do
                length(body) == 0 ->
                  List.insert_at(body, current_line, line)

                params["ope"] == "put" ->
                  List.insert_at(body, current_line + 1, line)

                params["ope"] == "update" ->
                  List.update_at(body, current_line, fn _ -> line end)

                true ->
                  List.insert_at(body, current_line + 1, line)
              end
            end)
            |> update_in([:current_line], fn _ ->
              cond do
                length(body) == 0 ->
                  current_line + 1

                params["ope"] == "put" ->
                  current_line + 1

                params["ope"] == "update" ->
                  current_line

                true ->
                  current_line + 1
              end
            end)

          socket
            |> assign(current_bot: current_bot)

        :error ->
          socket
      end

    {:noreply, socket
      |> assign(last_result: result)
      |> close_modal()
      |> put_message(message)
    }
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  ################################################################################################
  ## Handle info
  ################################################################################################

  def handle_info(:clear_message, socket) do
    {:noreply, clear_message(socket) |> IO.inspect}
  end

  ################################################################################################
  ## Private tools
  ################################################################################################

  defp put_message(socket, message, timeout \\ 3500)
  defp put_message(socket, nil, _), do: socket
  defp put_message(socket, message, timeout) do
    result_ok = socket.assigns[:last_result] == :ok
    socket
      |> put_flash(result_ok && :info || :error, message)
      |> push_event("js-exec", %{ js: """
        setTimeout(()=>document.querySelectorAll('#flash-group > div').forEach(d=>d.style.display='none'), #{timeout})
      """ })
  end

  defp clear_message(socket) do
    clear_flash(socket)
  end

  defp open_modal(socket, map) do
    socket
      |> assign(modal: map)
      |> push_event("js-exec", %{ js: """
        modal.showModal();
      """ })
  end
  defp close_modal(socket) do
    socket
      |> assign(modal: %{})
  end

  defp get_sentencies() do
    Bobot.Tools.get_modules(~r/Bobot\.DSL\.(.+?)\.Parser/)
      |> Enum.map(fn mod -> mod.info(:sentencies) end)
      |> List.flatten()
      |> Enum.into(%{})
  end

  defp get_editing_line(%{body: body, current_ope: ope})
    when length(body) == 0 or ope == "put"
  do
    %{
      level: 0,
      sentency: nil,
      params: "[[]]"
    }
  end
  defp get_editing_line(current_bot) do
    [level, sentency, params] = Enum.at(current_bot[:body], current_bot[:current_line] || 0)
    %{
      level: level,
      sentency: sentency,
      params: Macro.to_string(params)
    }
  end

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      :error -> default
      {val, _} -> val
    end
  end
  defp parse_integer(_, default), do: default

end
