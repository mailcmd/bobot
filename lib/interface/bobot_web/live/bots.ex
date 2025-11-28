defmodule BobotWeb.Bots do
  use BobotWeb, :live_view
  import BobotWeb.Components
  import BobotWeb.WebTools

  require Bobot.Utils

  Code.ensure_compiled!(Bobot.Config)

  @doc """
  Assigns:
  - sentencies: %{
    "defbot" => %{module: <module>, type: <type>, visible: <boolean>},
    ...
  }

  - bots: %{
    <name>: <name>
    ...
  }

  - modal: %{
      title: <string>,
      template: %{
        module: <module>,
        sentency: <string>
      }
    }

  - current_bot: %{
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
    }
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

  def mount(params, _session, socket) do

    {:ok, socket
      |> assign(sentencies: get_sentencies())
      |> assign(bots: Bobot.Config.get_available_bots())
      |> assign(active_bots: Bobot.Config.get_active_bots())
      |> assign(modal: %{})
      |> assign(box_status: "maximized")
      |> assign(editor_status_bar: "")
      |> assign(current_bot: nil)
      |> Bobot.Utils.pipe_if(
          params["target"] != nil,
            do: assign(current_bot: params["target"] |> String.to_atom() |> load_bot())
        )
      |> assign(current_block: nil)
      |> push_event("js-exec", %{ js: """
        bobot_editor.close();
        interact('span.defblock').draggable({
          listeners: {
            start (event) {
              if (!event.target.position) event.target.position = {x: 0, y: 0};
            },
            move (event) {
              event.target.position.x += event.dx;
              event.target.position.y += event.dy;

              event.target.style.transform =
                `translate(${event.target.position.x}px, ${event.target.position.y}px)`;

              if (event.target.lines) {
                event.target.lines.forEach( line => line.position() );
              }
            },
          }
        });
      """ })
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
                |> put_in([:settings], [])
                |> put_in([:settings, :type], def[:type])
                |> put_in([:settings, :use_apis], def[:use_apis])
                |> put_in([:settings, :use_libs], def[:use_libs])
                |> put_in([:settings, :config], [])
                |> put_in([:blocks], [])

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

        :error ->
          socket
      end

    {:noreply, socket
      |> update(:bots, fn bots -> [def[:name] | bots] |> Enum.uniq() end)
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
            |> update_in([:blocks], fn blocks -> blocks ++ [block] end)
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
      |> assign(current_bot: load_bot(name))
    }
  end

  ###############
  ### VIEW BOT
  def handle_event("edit-bot", _params, socket) do
    text = bot_to_string(socket.assigns[:current_bot])

    {:noreply, socket
      |> push_event("js-exec", %{ js: """
        editor_open('#{socket.assigns[:current_bot][:name]}', `#{text}`, false);
      """ })
    }

  end

  ########################
  ### SAVE AND COMPILE BOT
  def handle_event("save-bot", _params, socket) do
    current_bot = socket.assigns[:current_bot]

    with :ok <- save_bot(current_bot),
         {:ok, message} <- compile_bot(current_bot[:name]),
         :ok <- Bobot.Utils.get_bot_module(current_bot[:name]).init_channels() do

      text = bot_to_string(current_bot)
      {:noreply, socket
        |> update(:current_bot, fn cb -> put_in(cb, [:changed], false) end)
        |> assign(last_result: :ok)
        |> put_message(message)
        |> push_event("js-exec", %{ js: """
          let {row, column} = editor.getCursorPositionScreen();
          editor_set_text(`#{text}`);
          editor_gotoline([row + 1, column])
          editor_set_status_bar('');
          editor.focus();
        """ })
  }
    else
      {{:error, message}, %{message: error_message, nline: nline}} ->
        text = bot_to_string(current_bot)

        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message(message)
          |> push_event("js-exec", %{ js: """
            editor_open('Compile error for #{current_bot[:name]}', `#{text}`, false);
            editor_set_status_bar('ERROR: #{error_message}', #{nline}, true);
          """ })
        }

      _ ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("There was a problem storing BOT!")
        }
    end
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


  ##############
  ### BLOCK MNG
  def handle_event("open-block", params, socket) do
    name = String.to_atom(params["value"])
    block_prms = Macro.to_string(socket.assigns[:current_bot][:blocks][name][:params])
    block = find_block(socket.assigns[:current_bot], name)
    text = Bobot.Utils.ast_to_source(block[:block])
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
    case Bobot.Utils.quote_string(params["block_text"]) do
      {:error, nline, message} ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("ERROR: #{message}", 3500)
          |> push_event("js-exec", %{ js: """
            editor_set_status_bar('ERROR: #{message} (line: #{nline})', #{nline}, true);
          """ })
        }

      ast ->
        case socket.assigns[:current_block] do
          ## If it is a complete bot
          nil ->
            new_block = ast

            current_bot = socket.assigns[:current_bot]
            original_bot =
              current_bot
              |> bot_to_string()
              |> Bobot.Utils.quote_string()

            {result, message} =
              if not Bobot.Utils.ast_equals(original_bot, new_block) do
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
            new_block = ast
            original_block = find_block(socket.assigns[:current_bot], name)[:block]

            {result, block_name, message} =
              if not Bobot.Utils.ast_equals(original_block, new_block) do
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
    case Bobot.Utils.quote_string(params["block_text"]) do
      {:error, nline, message} ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("ERROR: #{message}", 3500)
          |> push_event("js-exec", %{ js: """
            editor_set_status_bar('ERROR: #{message} (line: #{nline})');
            editor_gotoline(#{nline}, true);
          """ })
        }

      new_ast ->
        case socket.assigns[:current_block] do
          ## If it is a complete bot
          nil ->
            new_bot =
              {:__block__, [],  new_ast}
              |> ast_extract_components()
              |> elem(1)
              |> Map.put(:changed, true)

            if new_bot[:unknown] != nil do
              {:noreply, socket
                |> assign(last_result: :error)
                |> put_message("ERROR: You MUST NOT put code out of a block!!", 3500)
                |> push_event("js-exec", %{ js: """
                  editor_set_status_bar('ERROR: #{new_bot[:unknown] |> hd() |> Macro.to_string()} is out of a block!!');
                """ })
              }
            else
              ## All ok then I save and compile the bot
              handle_event("save-bot", %{}, socket
                |> assign(current_bot: new_bot)
              )
            end

          ## If it is just a block
          name ->
            {:noreply, socket
              |> update(:current_bot, fn current_bot ->
                current_bot
                  |> update_in([:blocks], fn blocks ->
                    index = find_block_index(current_bot, name)
                    new_block = current_bot
                      |> find_block(name)
                      |> put_in([:block], new_ast)
                    List.replace_at(blocks, index, new_block)
                  end)
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

  defp save_bot(bot) do
    filename = "#{@bots_dir}/#{bot[:name]}.ex"
    save_bot(bot, filename)
  end
  defp save_bot(bot, filename), do: File.write(filename, bot_to_string(bot))

  defp find_block(bot, name) do
    Enum.find(bot[:blocks], fn blk -> blk[:name] == name end)
  end

  defp find_block_index(bot, name) do
    Enum.find_index(bot[:blocks], fn blk -> blk[:name] == name end)
  end

  defp bot_to_string(bot) do

    except = [:hooks, :terminate, :break]
    no_parens =
      get_sentencies()
      |> Enum.map(fn {k, _} -> {String.to_atom(k), :*} end)
      |> Enum.filter(fn {k, _} -> k not in except end)

    """
    import Bobot.DSL.Base

    defbot :#{bot[:name]}, [ ## WARNING: You MUST not touch the 'defbot ...' line!!!
        type: :#{bot[:settings][:type]},
        use_apis: #{inspect bot[:settings][:use_apis]},
        use_libs: #{inspect bot[:settings][:use_libs]},
        config: #{inspect bot[:settings][:config]}
      ] do

      hooks #{Macro.to_string(bot[:hooks])}

      constants #{Macro.to_string(bot[:constants] || [])}

      #{bot_channels_to_source(bot[:channels], no_parens: no_parens)}

      #{bot_commands_to_source(bot[:commands], no_parens: no_parens)}

      #{bot_blocks_to_source(bot[:blocks], no_parens: no_parens)}
    end
    """
    |> Code.format_string!(locals_without_parens: no_parens)
    |> Enum.join("")
  end

  defp bot_blocks_to_source([{_,_}|_] = blocks, no_parens) do
     blocks |> Enum.map(fn {_, b} -> b end) |> bot_blocks_to_source(no_parens)
  end
  defp bot_blocks_to_source(nil, _), do: ""
  defp bot_blocks_to_source([], _), do: ""
  defp bot_blocks_to_source([block | blocks], no_parens) do
    """
    defblock :#{block[:name]}#{block[:params] != [] && ", #{Macro.to_string(block[:params])}" || ""} do
      #{Bobot.Utils.ast_to_source(block[:block], no_parens)}
    end

    #{bot_blocks_to_source(blocks, no_parens)}
    """
  end

  defp bot_commands_to_source(commands, no_parens) when is_map(commands) do
     commands |> Enum.into([]) |> bot_commands_to_source(no_parens)
  end
  defp bot_commands_to_source(nil, _), do: ""
  defp bot_commands_to_source([], _), do: ""
  defp bot_commands_to_source([{command, block} | commands], no_parens) do
    """
    defcommand #{Macro.to_string(command)} do
      #{Bobot.Utils.ast_to_source(block, no_parens)}
    end

    #{bot_commands_to_source(commands, no_parens)}
    """
  end

  defp bot_channels_to_source(channels, no_parens) when is_map(channels) do
    channels |> Enum.into([]) |> bot_channels_to_source(no_parens)
 end
 defp bot_channels_to_source(nil, _), do: ""
 defp bot_channels_to_source([], _), do: ""
 defp bot_channels_to_source([{channel, block} | channels], no_parens) do
   """
   defchannel #{Macro.to_string(channel)} do
     #{Bobot.Utils.ast_to_source(block, no_parens)}
   end

   #{bot_channels_to_source(channels, no_parens)}
   """
 end

 defp compile_bot(name) do
    filename = file_name(name)
    case Bobot.Utils.compile_file(filename) do
      {:ok, _} ->
        {:ok, "Bot compiled OK!"}

      {{:error, error}, error_data} ->
        {{:error, "There was a problem compiling the BOT (#{error})"}, error_data}
    end
  end

  defp file_name(name) do
    "#{@bots_dir}/#{name}.ex"
  end

  ################################################################################################
  ## Public tools
  ################################################################################################

  def ast_extract_components(
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
        {:hooks, _, [hooks]}, acc ->
          {
            [], #node,
            put_in(acc, [:hooks], hooks)
          }

        {:constants, _, [constants]}, acc ->
          {
            [], #node,
            put_in(acc, [:constants], constants)
          }

        {:defblock, _, [block_name, [do: block]]}, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            [], #node,
            acc
              |> update_in([:blocks], fn
                nil -> [%{
                    params: [],
                    block: block,
                    name: block_name
                  }]
                blks ->
                  blks ++ [ %{
                    params: [],
                    block: block,
                    name: block_name
                  } ]
              end)
          }

        {:defblock, _, [block_name, params, [do: block]]}, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            [], #node,
            acc
              |> update_in([:blocks], fn
                nil -> [%{
                    params: params,
                    block: block,
                    name: block_name
                  }]
                blks ->
                  blks ++ [ %{
                    params: params,
                    block: block,
                    name: block_name
                  }]
              end)
          }

        {:defcommand, _, [command, [do: block]]}, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            [], #node,
            acc
              |> Bobot.Utils.put_inx([:commands, command], block)
          }

          {:defchannel, _, [channel, [do: block]]}, acc ->
            block =
              case block do
                {:__block__, _, block} -> block
                block -> [block]
              end
            {
              [], #node,
              acc
                |> Bobot.Utils.put_inx([:channels, channel], block)
            }

          {:__block__, _, _}, %{hooks: _hooks} = acc ->
          {[], acc}

        {:__block__, _, _}, %{blocks: _blocks} = acc ->
          {[], acc}

        {:__block__, _, _} = node, acc ->
          {node, acc}

        node, acc -> # {node, acc}
          {
            node,
            acc
              |> update_in([:unknown], fn
                nil -> [node]
                unknown -> Enum.reverse([node | unknown])
              end)
          }
      end)
      |> elem(1)
      |> update_in([:blocks], fn
        nil -> []
        blocks -> blocks
      end)
    }
  end
  def ast_extract_components(_), do: []

  def get_sentencies() do
    Bobot.Utils.get_modules(~r/Bobot\.DSL\.(.+?)\.Tools/)
      |> Enum.map(fn mod -> mod.info(:sentencies) end)
      |> List.flatten()
      |> Enum.into(%{})
  end

  def load_bot(name) do
    name
    |> file_name()
    |> Bobot.Utils.ast_from_file()
    |> ast_extract_components()
    |> elem(1)
  end

end
