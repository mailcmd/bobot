defmodule BobotWeb.Bots do
  use BobotWeb, :live_view
  import BobotWeb.Components
  import BobotWeb.WebTools

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
        use_apis: [<atoms_list>],
        use_libs: [<atoms_list>],
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
    settings: nil,
    changed: true
  }

  @bots_dir Application.compile_env(:bobot, :bots_dir)
  @active_bots Application.compile_env(:bobot, :telegram_bots, [])

  def mount(_params, _session, socket) do

    {:ok, socket
      |> assign(sentencies: get_sentencies())
      |> assign(bots: get_bots())
      |> assign(active_bots: @active_bots)
      |> assign(modal: %{})
      |> assign(box_status: "maximized")
      |> assign(editor_status_bar: "")
      |> assign(current_bot: nil)
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
        title: "Bot defs..."
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
            case assigns[:current_bot] do
              nil ->
                @blank_bot
                |> put_in([:name], def[:name])
                |> put_in([:settings, :type], def[:type])
                |> put_in([:settings, :use_apis], def[:use_apis])
                |> put_in([:settings, :use_libs], def[:use_libs])
                |> put_in([:settings, :config], [])

              cb ->
                cb
                |> put_in([:name], def[:name])
                |> put_in([:settings, :type], def[:type])
                |> put_in([:settings, :use_apis], def[:use_apis])
                |> put_in([:settings, :use_libs], def[:use_libs])
                |> put_in([:changed], true)
            end


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
            |> update(:current_bot, fn current_bot ->
              current_bot
              |> put_in([:settings, :config], config)
              |> put_in([:changed], true)
            end)

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
            |> update(:current_bot, fn current_bot ->
              current_bot
              |> put_in([:hooks], hooks)
              |> put_in([:changed], true)
            end)

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
          current_bot =
            assigns[:current_bot]
            |> update_in([:blocks], fn blocks -> Map.merge(blocks, block) end)
            |> put_in([:changed], true)

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

  ##############
  ### SELECT BOT
  def handle_event("select-bot", params, socket) do
    name = params["bot_name"] |> String.replace(" *", "") |> String.to_atom()
    {:noreply, socket
      |> assign(current_bot: socket.assigns[:bots][name])
      # |> push_event("js-exec", %{ js: """
      #   block_connect('start', 'addresses_menu');
      #   block_connect('start', 'first_contact');
      # """ })
    }
  end

  ##############
  ### SAVE BOT
  def handle_event("save-bot", _params, socket) do
    current_bot = socket.assigns[:current_bot]
    {result, message, bots, current_bot} =
      case save_bot(current_bot) do
        :ok ->
          bot_name = current_bot[:name]
          current_bot = Map.put(current_bot, :changed, false)
          {:ok, "Bot saved!", put_in(socket.assigns[:bots], [bot_name], current_bot), current_bot}

        {:error, err} ->
          {:error, "There was a problem storing bot (#{err})", socket.assigns[:bots], socket.assigns[:current_bot]}
      end

    {:noreply, socket
      |> update(:bots, fn _ -> bots end)
      |> assign(current_bot: current_bot)
      |> assign(last_result: result)
      |> put_message(message)
    }
  end

  ##############
  ### CLOSE BOT (no ctrl key)
  def handle_event("close-bot", %{"value" => "false"}, socket) do
    if socket.assigns[:current_bot][:changed] do
      {:noreply, socket
        |> assign(last_result: :error)
        |> put_message("You made changes, save them before close or [CTRL+click] to close without save.", 5000)
      }
    else
      handle_event("close-bot", %{"value" => "true"}, socket)
    end

  end
  ##############
  ### CLOSE BOT (with ctrl key)
  def handle_event("close-bot", _params, socket) do
    changed = socket.assigns[:current_bot][:changed]
    {:noreply, socket
      |> assign(last_result: changed && :error || :ok)
      |> put_message(changed && "Changes discarded!" || nil)
      |> assign(current_bot: nil)
    }
  end

  ###############
  ### COMPILE BOT
  def handle_event("compile-bot", _params, socket) do
    {{result, message}, real_errors} =
      Code.with_diagnostics(fn ->
        try do
          socket.assigns[:current_bot]
            |> bot_to_string()
            |> Code.compile_string()
          {:ok, "Bot compiled OK!"}
        rescue
          _ ->
            {:error, "There was a problem compiling the bot!"}
        end
      end)

    case {{result, message}, real_errors} do
      {{:ok, message}, _} ->
        {:noreply, socket
          |> assign(last_result: result)
          |> put_message(message)
        }

      {{:error, message}, real_errors} ->
        error =
          real_errors
          |> Enum.filter(&(&1.severity == :error))
          |> hd()


        error_message = error[:message]
        nline =
          case error[:position] do
            {nline, _} -> nline
            nline -> nline
          end

        text = bot_to_string(socket.assigns[:current_bot])

        {:noreply, socket
          |> assign(last_result: result)
          |> put_message(message)
          |> push_event("js-exec", %{ js: """
            editor_open('Compile error for #{socket.assigns[:current_bot][:name]}', `#{text}`, true);
            editor_set_status_bar('#{error_message}', #{nline}, true);
          """ })
        }

    end
  end

  ###############
  ### VIEW BOT
  def handle_event("view-bot", _params, socket) do
    text = bot_to_string(socket.assigns[:current_bot])

    {:noreply, socket
      |> push_event("js-exec", %{ js: """
        editor_open('#{socket.assigns[:current_bot][:name]}', `#{text}`, true);
      """ })
    }

  end

  ##############
  ### BLOCK MNG
  def handle_event("open-block", params, socket) do
    name = String.to_atom(params["value"])
    block_prms = Macro.to_string(socket.assigns[:current_bot][:blocks][name][:params])
    text = Bobot.Tools.ast_to_source(socket.assigns[:current_bot][:blocks][name][:block])
    {:noreply, socket
      |> assign(current_block: name)
      |> push_event("js-exec", %{ js: """
        editor_open('BLOCK: #{name} #{block_prms}', `#{text}`)
      """ })
    }
  end

  def handle_event("operation-editor", %{"operation" => "cancel", "ctrl" => "true"}, socket) do
    {:noreply, socket
      |> assign(last_result: :ok)
      |> assign(current_block: nil)
      |> push_event("js-exec", %{ js: """
        bobot_editor.close();
      """ })
      |> put_message("Change discarded!")
    }
  end

  def handle_event("operation-editor", %{"operation" => "cancel"} = params, socket) do
    case Bobot.Tools.quote_string(params["block_text"]) do
      {:error, nline, message} ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("ERROR: #{message}", 3500)
          |> push_event("js-exec", %{ js: """
            editor_set_status_bar('ERROR: #{message} (line: #{nline})', #{nline}, true);
          """ })
        }

      ast ->
        new_block =
          ast
          |> Bobot.Tools.ast_to_source()
          |> Code.string_to_quoted()

        case socket.assigns[:current_block] do
          ## If it is a complete bot
          nil ->
            name = socket.assigns[:current_bot][:name]
            original_bot =
              "#{@bots_dir}/#{name}.ex"
              |> Bobot.Tools.ast_from_file()
              |> List.wrap()
              |> Bobot.Tools.ast_to_source()
              |> Code.string_to_quoted()

            {result, message} =
              if original_bot != new_block do
                {:error, "You made changes, save them before close or [CTRL+click] to close without save."}
              else
                {:ok, nil}
              end

            {:noreply, socket
              |> assign(last_result: result)
              |> push_event("js-exec", %{ js: """
                if ('#{result}' == 'ok') bobot_editor.close();
              """ })
              |> put_message(message, 5000)
            }

          ## If it is just a block
          name ->
            original_block =
              socket.assigns[:current_bot][:blocks][name][:block]
              |> Bobot.Tools.ast_to_source()
              |> Code.string_to_quoted()

            {result, block_name, message} =
              if original_block != new_block do
                {:error, name, "You made changes, save them before close or [CTRL+click] to close without save."}
              else
                {:ok, nil, nil}
              end

            {:noreply, socket
              |> assign(last_result: result)
              |> assign(current_block: block_name)
              |> push_event("js-exec", %{ js: """
                if (!!!'#{block_name}') bobot_editor.close();
              """ })
              |> put_message(message, 5000)
            }
        end
    end
  end

  def handle_event("operation-editor", %{"operation" => "commit"} = params, socket) do
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
        case socket.assigns[:current_block] do
          ## If it is a complete bot
          nil ->
            new_bot =
              {:__block__, [],  new_block}
              |> ast_extract_components()
              |> elem(1)
              |> Map.put(:changed, true)

            {:noreply, socket
              |> assign(last_result: :ok)
              |> assign(current_bot: new_bot)
              |> push_event("js-exec", %{ js: """
                if (#{params["ctrl"]}) bobot_editor.close();
              """ })
              |> put_message("Change commited!", 5000)
            }

          ## If it is just a block
          name ->
            {:noreply, socket
              |> update(:current_bot, fn current_bot ->
                current_bot
                  |> put_in([:blocks, name, :block], new_block)
                  |> put_in([:changed], true)
              end)
              |> assign(last_result: :ok)
              |> assign(current_block: params["ctrl"] != "true" && name || nil )
              |> push_event("js-exec", %{ js: """
                if (#{params["ctrl"]}) bobot_editor.close();
              """ })
              |> put_message("Change commited!", 5000)
            }

        end
    end
  end

  ##############
  ### BOT STATUS
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

  ####################
  ### CONFIRMED ACTION

  #[remove_block]
  def handle_event("confirmed-action", %{"action" => "remove_block:" <> name}, socket) do
    block_name = String.to_atom(name)

    {:noreply, socket
      |> update(:current_bot, fn current_bot ->
        current_bot
          |> update_in([:blocks], fn blocks -> Map.delete(blocks, block_name) end)
          |> update_in([:changed], fn _ -> true end)
      end)
      |> push_event("js-exec", %{ js: """
        box_confirm_action.close();
      """ })
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

  defp ast_extract_components(
    {:__block__, [],  [
      {:import, _, [{:__aliases__, _, [:Bobot, :DSL, :Base]}]},
      {:defbot, _,
        [
          name,
          settings,
          [ do: block ]
        ]
      }
    ]}) do

    settings = settings |> Macro.to_string() |> Code.eval_string() |> elem(0)

    {name,
      block
      |> Macro.prewalk(%{name: name, settings: settings}, fn
        {:hooks, _, [hooks]} = node, acc ->
          {
            node,
            put_in(acc, [:hooks], hooks)
          }
        {:defblock, _, [block_name, [do: block]]} = node, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            node,
            acc
              |> Bobot.Tools.put_inx([:blocks, block_name, :params], [])
              |> Bobot.Tools.put_inx([:blocks, block_name, :block], block)
          }
        {:defblock, _, [block_name, params, [do: block]]} = node, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            node,
            acc
              |> Bobot.Tools.put_inx([:blocks, block_name, :params], params)
              |> Bobot.Tools.put_inx([:blocks, block_name, :block], block)
          }
        node, acc ->
          {node, acc}
      end)
      |> elem(1)
    }
  end
  defp ast_extract_components(_), do: []

  def get_sentencies() do
    Bobot.Tools.get_modules(~r/Bobot\.DSL\.(.+?)\.Tools/)
      |> Enum.map(fn mod -> mod.info(:sentencies) end)
      |> List.flatten()
      |> Enum.into(%{})
  end

  defp get_bots() do
    "#{@bots_dir}/*.ex"
    |> Path.wildcard()
    |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
    |> Stream.map(fn ast -> ast_extract_components(ast) end)
    |> Enum.into([])
    |> Enum.filter(fn bot -> bot != [] end)
    |> Enum.into(%{})
  end

  def save_bot(bot) do
    filename = "#{@bots_dir}/#{bot[:name]}.ex"
    # IO.puts bot_to_string(bot)
    save_bot(bot, filename)
  end
  def save_bot(bot, filename), do: File.write(filename, bot_to_string(bot))

  def bot_to_string(bot) do
    except = [:hooks]
    no_parens =
      get_sentencies()
      |> Enum.map(fn {k, _} -> {String.to_atom(k), :*} end)
      |> Enum.filter(fn {k, _} -> k not in except end)
    """
    import Bobot.DSL.Base

    defbot :#{bot[:name]}, [
        type: :#{bot[:settings][:type]},
        use_apis: #{inspect bot[:settings][:use_apis]},
        use_libs: #{inspect bot[:settings][:use_libs]},
        config: #{inspect bot[:settings][:config]}
      ] do

      hooks #{Macro.to_string(bot[:hooks])}

      #{bot_blocks_to_source(bot[:blocks])}
    end
    """
    |> Code.format_string!(locals_without_parens: no_parens)
    |> Enum.join("")
  end

  defp bot_blocks_to_source(blocks) when is_map(blocks) do
     blocks |> Enum.map(fn {n, b} -> Map.put(b, :name, n) end) |> bot_blocks_to_source()
  end
  defp bot_blocks_to_source([]), do: ""
  defp bot_blocks_to_source([block | blocks]) do
    """
    defblock :#{block[:name]}#{block[:params] != [] && ", #{Macro.to_string(block[:params])}" || ""} do
      #{Bobot.Tools.ast_to_source(block[:block])}
    end

    #{bot_blocks_to_source(blocks)}
    """
  end

end
