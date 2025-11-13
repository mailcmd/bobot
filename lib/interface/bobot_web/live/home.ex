defmodule BobotWeb.Home do
  use BobotWeb, :live_view
  import BobotWeb.Components

  @doc """
  Assigns:
  - sentencies: %{
    "defbot" => %{module: <module>, type: <type>, visible: <boolean>},
    ...
  }

  - bots: %{
    <name>: %{
      name: <name>,
      blocks: %{
        <block_name>: %{
          params: <ast>,
          block: <ast>
        },
        ...
      },
      hooks: [ <kwlist> ],
      settings: %{
        type: <type>,
        config: [ <kwlist> ]
      }
    },
    ...
  }

  - modal: %{
      title: <string>,
      template: %{
        module: <module>,
        sentency: <string>
      }
    }

  - current_bot: nil
  - box_status: "maximized"
  """

  @blank_bot %{
    name: nil,
    blocks: nil,
    hooks: [],
    settings: nil
  }

  def mount(_params, _session, socket) do

    {:ok, socket
      |> assign(sentencies: get_sentencies())
      |> assign(bots: get_bots())
      |> assign(modal: %{})
      |> assign(box_status: "maximized")
      |> assign(editor_status_bar: "")
      |> assign(current_bot: get_bots()[:smi])
      |> assign(current_block: nil)
    }
  end

  ################################################################################################
  ## SHOWs
  ################################################################################################

  ## Specific SHOW for defbot
  def handle_event("show:defbot", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "defbot"},
        title: "New bot..."
      })
    }
  end

  ## Specific SHOW for settings
  def handle_event("show:settings", _params, socket) do
    type = socket.assigns[:current_bot][:settings][:type] |> to_string() |> Macro.camelize()
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

  ## Specific SHOW for defblock
  def handle_event("show:defblock", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "defblock"},
        title: "Bot block"
      })
    }
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  ## Specific SAVE for new_bot
  def handle_event("save:defbot", params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies]["defbot"][:template]
    {result, message, def} = apply(module, :save, ["defbot", params, assigns])

    socket =
      case result do
        :ok ->
          current_bot =
            @blank_bot
            |> put_in([:name], def[:name])
            |> put_in([:settings, :type], def[:type])
            |> put_in([:settings, :config], [])

          socket
            |> assign(current_bot: current_bot)
            |> assign(bots: Map.put(assigns[:bots], def[:name], current_bot))

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
    module = assigns[:sentencies]["settings"][:template]
    {result, message, config} = apply(module, :save, ["settings", params, assigns])

    socket =
      case result do
        :ok ->
          socket
            |> assign(current_bot: put_in(assigns[:current_bot], [:settings, :config], config))

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
    module = assigns[:sentencies]["hooks"][:template]
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

  ## Specific SAVE for defblock
  def handle_event("save:defblock", params, socket) do
    assigns = socket.assigns
    module = assigns[:sentencies]["defblock"][:template]
    {result, message, block} = apply(module, :save, ["defblock", params, assigns])

    socket =
      case result do
        :ok ->
          current_bot = update_in(assigns[:current_bot], [:blocks], fn blocks ->
            Map.merge(blocks, block)
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

  ################################################################################################
  ## Misc events
  ################################################################################################
  def handle_event("select-bot", params, socket) do
    name = String.to_atom(params["bot_name"])
    {:noreply, socket
      |> assign(current_bot: socket.assigns[:bots][name])
    }
  end

  def handle_event("open-block", params, socket) do
    name = String.to_atom(params["value"])
    block_prms = Macro.to_string(socket.assigns[:current_bot][:blocks][name][:params])
    text = Bobot.Tools.ast_to_source(socket.assigns[:current_bot][:blocks][name][:block])
    {:noreply, socket
      |> assign(current_block: name)
      |> push_event("js-exec", %{ js: """
        editor_set_text(`#{text}`);
        editor_set_title('BLOCK: #{name} #{block_prms}');
        block_editor.showModal();
        editor.selection.clearSelection();
      """ })
    }
  end

  def handle_event("operation-block", %{"operation" => "cancel", "ctrl" => "true"}, socket) do
    {:noreply, socket
      |> assign(last_result: :ok)
      |> assign(current_block: nil)
      |> push_event("js-exec", %{ js: """
        block_editor.close();
      """ })
      |> put_message("Change discarded!")
    }
  end

  def handle_event("operation-block", %{"operation" => "cancel"} = params, socket) do
    case Bobot.Tools.quote_string(params["block_text"]) do
      {:error, nline, message} ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("ERROR: #{message}", 3500)
          |> push_event("js-exec", %{ js: """
            editor_set_status_bar('ERROR: #{message} (line: #{nline})');
            editor_gotoline(#{nline}, true);
          """ })
        }

      ast ->
        new_block = Bobot.Tools.ast_to_source(ast)
        name = socket.assigns[:current_block]
        original_block = Bobot.Tools.ast_to_source(socket.assigns[:current_bot][:blocks][name][:block])

        {result, block_name, message} =
          if original_block != new_block do
            {:error, name, "You made changes, save them before close or CTRL + click to close without save."}
          else
            {:ok, nil, nil}
          end

        {:noreply, socket
          |> assign(last_result: result)
          |> assign(current_block: block_name)
          |> push_event("js-exec", %{ js: """
            if (!!!'#{block_name}') block_editor.close();
          """ })
          |> put_message(message, 5000)
        }
    end
  end

  def handle_event("operation-block", %{"operation" => "commit"} = params, socket) do
    case Bobot.Tools.quote_string(params["block_text"]) do
      {:error, nline, message} ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("ERROR: #{message}", 3500)
          |> push_event("js-exec", %{ js: """
            editor_set_status_bar('ERROR: #{message} (line: #{nline})');
            editor_gotoline(#{nline}, true);
          """ })
        }

      new_block ->
        name = socket.assigns[:current_block]
        {:noreply, socket
          |> update(:current_bot, fn current_bot ->
            put_in(current_bot, [:blocks, name, :block], new_block)
          end)
          |> assign(last_result: :ok)
          |> push_event("js-exec", %{ js: """
            if (#{params["ctrl"]}) block_editor.close();
          """ })
          |> put_message("Change commited!", 5000)
        }
    end
  end

  def handle_event("maximize-box-status", _params, socket) do
    {:noreply, socket
      |> assign(box_status: "maximized")
    }
  end
  def handle_event("minimize-box-status", _params, socket) do
    {:noreply, socket
      |> assign(box_status: "minimized cursor-pointer")
    }
  end

  ################################################################################################
  ## Handle info
  ################################################################################################

  def handle_info(:clear_message, socket) do
    {:noreply, clear_message(socket)}
  end

  ################################################################################################
  ## Private tools
  ################################################################################################

  defp put_message(socket, message, timeout \\ 3500)
  defp put_message(socket, nil, _), do: socket
  defp put_message(socket, message, timeout) do
    result_ok = socket.assigns[:last_result] == :ok
    socket
      |> push_event("js-exec", %{ js: """
        clearTimeout(window.flash_timeout)
      """ })
      |> clear_flash()
      |> put_flash(result_ok && :info || :error, message)
      |> push_event("js-exec", %{ js: """
        window.flash_timeout = setTimeout(()=>document.querySelectorAll('#flash-group > div').forEach(d=>d.style.display='none'), #{timeout})
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
    Bobot.Tools.get_modules(~r/Bobot\.DSL\.(.+?)\.Tools/)
      |> Enum.map(fn mod -> mod.info(:sentencies) end)
      |> List.flatten()
      |> Enum.into(%{})
  end

  def get_bots() do
    "lib/service/bots/*.ex"
    |> Path.wildcard()
    |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
    |> Stream.map(fn ast -> Bobot.Tools.ast_extract_components(ast) end)
    |> Enum.into([])
    |> Enum.filter(fn bot -> bot != [] end)
    |> Enum.into(%{})
  end

end
