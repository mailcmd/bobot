defmodule BobotWeb.Apis do
  use BobotWeb, :live_view
  import BobotWeb.Components
  import BobotWeb.WebTools

  @doc """
  Assigns:
  - apis: %{
    <name>: %{
      name: <name>,
      calls: %{
        <name>: %{
          params: <ast>,
          code: <ast>
        }
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

  - current_api: nil
  """

  @apis_dir Application.compile_env(:bobot, :apis_dir)

  @blank_api %{
    name: nil,
    apis: nil,
    changed: true
  }

  def mount(_params, _session, socket) do

    {:ok, socket
      |> assign(apis: get_apis())
      |> assign(modal: %{})
      |> assign(editor_status_bar: "")
      |> assign(current_api: nil)
      |> assign(current_call: nil)
    }
  end

  ################################################################################################
  ## SHOWs
  ################################################################################################

  ## Specific SHOW for defbot
  def handle_event("show:defapi", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "defapi"},
        title: "New API..."
      })
    }
  end

  ## Specific SHOW for defblock
  def handle_event("show:defcall", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "defcall"},
        title: "API call"
      })
    }
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  ## Specific SAVE for new_bot
  def handle_event("save:defapi", params, socket) do
    assigns = socket.assigns
    {result, message, def} = apply(Bobot.DSL.Base.Templates, :save, ["defapi", params, assigns])

    socket =
      case result do
        :ok ->
          current_api =
            @blank_api
            |> put_in([:name], def[:name])

          socket
            |> assign(current_api: current_api)
            |> assign(apis: Map.put(assigns[:apis], def[:name], current_api))

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
  def handle_event("save:defcall", params, socket) do
    assigns = socket.assigns
    {result, message, call} = apply(Bobot.DSL.Base.Templates, :save, ["defcall", params, assigns])

    socket =
      case result do
        :ok ->
          current_api =
            assigns[:current_api]
            |> update_in([:calls], fn calls -> Map.merge(calls, call) end)
            |> put_in([:changed], true)

          socket
            |> assign(current_api: current_api)

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
  def handle_event("select-api", params, socket) do
    name = params["api_name"] |> String.replace(" *", "") |> String.to_atom()
    {:noreply, socket
      |> assign(current_api: socket.assigns[:apis][name])
    }
  end

  ##############
  ### SAVE BOT
  def handle_event("save-api", _params, socket) do
    current_api = socket.assigns[:current_api]
    {result, message, apis, current_api} =
      case save_api(current_api) do
        :ok ->
          api_name = current_api[:name]
          current_api = Map.put(current_api, :changed, false)
          {:ok, "API saved!", put_in(socket.assigns[:apis], [api_name], current_api), current_api}

        {:error, err} ->
          {:error, "There was a problem storing API (#{err})", socket.assigns[:apis], socket.assigns[:current_api]}
      end

    {:noreply, socket
      |> update(:apis, fn _ -> apis end)
      |> assign(current_api: current_api)
      |> assign(last_result: result)
      |> put_message(message)
    }
  end

  ##############
  ### CLOSE API (no ctrl key)
  def handle_event("close-api", %{"value" => "false"}, socket) do
    if socket.assigns[:current_api][:changed] do
      {:noreply, socket
        |> assign(last_result: :error)
        |> put_message("You made changes, save them before close or [CTRL+click] to close without save.", 5000)
      }
    else
      handle_event("close-api", %{"value" => "true"}, socket)
    end

  end
  ##############
  ### CLOSE API (with ctrl key)
  def handle_event("close-api", _params, socket) do
    changed = socket.assigns[:current_api][:changed]
    {:noreply, socket
      |> assign(last_result: changed && :error || :ok)
      |> put_message(changed && "Changes discarded!" || nil)
      |> assign(current_api: nil)
    }
  end

  ###############
  ### COMPILE API
  def handle_event("compile-api", _params, socket) do
    {{result, message}, real_errors} =
      Code.with_diagnostics(fn ->
        try do
          socket.assigns[:current_api]
            |> api_to_string()
            |> Code.compile_string()
          {:ok, "API compiled OK!"}
        rescue
          _ ->
            {:error, "There was a problem compiling the API!"}
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

        text = api_to_string(socket.assigns[:current_api])

        {:noreply, socket
          |> assign(last_result: result)
          |> put_message(message)
          |> push_event("js-exec", %{ js: """
            editor_open('Compile error for #{socket.assigns[:current_api][:name]}', `#{text}`, true);
            editor_set_status_bar('#{error_message}', #{nline}, true);
          """ })
        }
    end
  end

  ###############
  ### VIEW API
  def handle_event("view-api", _params, socket) do
    text = api_to_string(socket.assigns[:current_api])

    {:noreply, socket
      |> push_event("js-exec", %{ js: """
        editor_open('#{socket.assigns[:current_api][:name]}', `#{text}`, true);
      """ })
    }

  end

  ##############
  ### BLOCK MNG
  def handle_event("open-call", params, socket) do
    name = String.to_atom(params["value"])
    call_prms = Macro.to_string(socket.assigns[:current_api][:calls][name][:params])
    text = Bobot.Tools.ast_to_source(socket.assigns[:current_api][:calls][name][:code])
    {:noreply, socket
      |> assign(current_call: name)
      |> push_event("js-exec", %{ js: """
        editor_open('CALL: #{name} #{call_prms}', `#{text}`)
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
        new_call =
          ast
          |> Bobot.Tools.ast_to_source()
          |> Code.string_to_quoted()

        case socket.assigns[:current_call] do
          ## If it is a complete api
          nil ->
            name = socket.assigns[:current_api][:name]
            original_api =
              "#{@apis_dir}/#{name}.ex"
              |> Bobot.Tools.ast_from_file()
              |> List.wrap()
              |> Bobot.Tools.ast_to_source()
              |> Code.string_to_quoted()

            {result, message} =
              if original_api != new_call do
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

          ## If it is just a call
          name ->
            original_call =
              socket.assigns[:current_api][:calls][name][:code]
              |> Bobot.Tools.ast_to_source()
              |> Code.string_to_quoted()

            {result, call_name, message} =
              if original_call != new_call do
                {:error, name, "You made changes, save them before close or [CTRL+click] to close without save."}
              else
                {:ok, nil, nil}
              end

            {:noreply, socket
              |> assign(last_result: result)
              |> assign(current_call: call_name)
              |> push_event("js-exec", %{ js: """
                if (!!!'#{call_name}') bobot_editor.close();
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

      new_call ->
        case socket.assigns[:current_call] do
          ## If it is a complete api
          nil ->
            new_api =
              {:__block__, [],  new_call}
              |> ast_extract_components()
              |> elem(1)
              |> Map.put(:changed, true)

            {:noreply, socket
              |> assign(last_result: :ok)
              |> assign(current_api: new_api)
              |> push_event("js-exec", %{ js: """
                if (#{params["ctrl"]}) bobot_editor.close();
              """ })
              |> put_message("Change commited!", 5000)
            }

          ## If it is just a call
          name ->
            {:noreply, socket
              |> update(:current_api, fn current_api ->
                current_api
                  |> put_in([:calls, name, :code], new_call)
                  |> put_in([:changed], true)
              end)
              |> assign(last_result: :ok)
              |> assign(current_call: params["ctrl"] != "true" && name || nil )
              |> push_event("js-exec", %{ js: """
                if (#{params["ctrl"]}) bobot_editor.close();
              """ })
              |> put_message("Change commited!", 5000)
            }

        end
    end
  end

  ####################
  ### CONFIRMED ACTION

  #[remove_block]
  def handle_event("confirmed-action", %{"action" => "remove_call:" <> name}, socket) do
    call_name = String.to_atom(name)

    {:noreply, socket
      |> update(:current_api, fn current_api ->
        current_api
          |> update_in([:calls], fn calls -> Map.delete(calls, call_name) end)
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
      {:defapi, _,
        [
          name,
          [ do: block ]
        ]
      }
    ]}) do

    {name,
      block
      |> Macro.prewalk(%{name: name}, fn
        {:defcall, _, [call_name, [do: block]]} = node, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            node,
            acc
              |> Bobot.Tools.put_inx([:calls, call_name, :params], [])
              |> Bobot.Tools.put_inx([:calls, call_name, :code], block)
          }
        {:defcall, _, [call_name, params, [do: block]]} = node, acc ->
          block =
            case block do
              {:__block__, _, block} -> block
              block -> [block]
            end
          {
            node,
            acc
              |> Bobot.Tools.put_inx([:calls, call_name, :params], params)
              |> Bobot.Tools.put_inx([:calls, call_name, :code], block)
          }
        node, acc ->
          {node, acc}
      end)
      |> elem(1)
    }
  end
  defp ast_extract_components(_), do: []

  defp get_apis() do
    "#{@apis_dir}/*.ex"
    |> Path.wildcard()
    |> Stream.map(fn filename -> Bobot.Tools.ast_from_file(filename) end)
    |> Stream.map(fn ast -> ast_extract_components(ast) end)
    |> Enum.into([])
    |> Enum.filter(fn api -> api != [] end)
    |> Enum.into(%{})
  end

  def save_api(api) do
    filename = "#{@apis_dir}/#{api[:name]}.ex"
    save_api(api, filename)
  end
  def save_api(api, filename), do: File.write(filename, api_to_string(api))

  def api_to_string(api) do
    """
    import Bobot.DSL.Base

    defapi :#{api[:name]} do
      #{api_calls_to_source(api[:calls])}
    end
    """
    |> Code.format_string!()
    |> Enum.join("")
  end

  defp api_calls_to_source(calls) when is_map(calls) do
     calls |> Enum.map(fn {n, c} -> Map.put(c, :name, n) end) |> api_calls_to_source()
  end
  defp api_calls_to_source([]), do: ""
  defp api_calls_to_source([call | calls]) do
    """
    defcall :#{call[:name]}#{call[:params] != [] && ", #{Macro.to_string(call[:params])}" || ""} do
      #{Bobot.Tools.ast_to_source(call[:code])}
    end

    #{api_calls_to_source(calls)}
    """
  end

end
