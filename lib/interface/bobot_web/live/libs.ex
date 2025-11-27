defmodule BobotWeb.Libs do
  use BobotWeb, :live_view
  import BobotWeb.Components
  import BobotWeb.WebTools

  require Bobot.Utils

  Code.ensure_compiled!(Bobot.Config)

  @doc """
  Assigns:
  - libs: %{
    <name>: %{
      name: <name>,
      code: <ast>
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

  - current_lib: nil
  """

  @libs_dir Application.compile_env(:bobot, :libs_dir)

  @blank_lib %{
    name: nil,
    code: nil,
    changed: false
  }

  def mount(params, _session, socket) do

    {:ok, socket
      |> assign(libs: Bobot.Config.get_available_libs())
      |> assign(modal: %{})
      |> assign(editor_status_bar: "")
      |> assign(current_lib: nil)
      |> Bobot.Utils.pipe_if(
          params["target"] != nil,
            do: assign(current_lib: params["target"] |> String.to_atom() |> load_lib())
        )
    }
  end

  ################################################################################################
  ## SHOWs
  ################################################################################################

  ## Specific SHOW for defbot
  def handle_event("show:deflib", _params, socket) do
    {:noreply, socket
      |> open_modal(%{
        template: %{module: Elixir.Bobot.DSL.Base.Templates, sentency: "deflib"},
        title: "New Lib..."
      })
    }
  end

  ################################################################################################
  ## SAVEs
  ################################################################################################

  ## Specific SAVE for new_bot
  def handle_event("save:deflib", params, socket) do
    assigns = socket.assigns
    {result, message, def} = apply(Bobot.DSL.Base.Templates, :save, ["deflib", params, assigns])

    socket =
      case result do
        :ok ->
          current_lib =
            @blank_lib
            |> put_in([:name], def[:name])

          socket
            |> assign(current_lib: current_lib)
            |> assign(libs: Map.put(assigns[:libs], def[:name], def[:name]))

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
  def handle_event("select-lib", params, socket) do
    name = params["lib_name"] |> String.replace(" *", "") |> String.to_atom()
    {:noreply, socket
      |> assign(current_lib: load_lib(name))
    }
  end

  ###############
  ### VIEW LIB
  def handle_event("view-lib", _params, socket) do
    text = lib_to_string(socket.assigns[:current_lib])

    {:noreply, socket
      |> push_event("js-exec", %{ js: """
        editor_open('#{socket.assigns[:current_lib][:name]}', `#{text}`, false);
      """ })
    }

  end

  ##############
  ### SAVE LIB
  def handle_event("save-lib", _params, socket) do
    current_lib = socket.assigns[:current_lib]
    with :ok <- save_lib(current_lib),
         {:ok, message} <- compile_lib(current_lib[:name]) do

      {:noreply, socket
        |> update(:current_lib, fn ca -> put_in(ca, [:changed], false) end)
        |> assign(last_result: :ok)
        |> put_message(message)
      }

    else
      {{:error, message}, %{message: error_message, nline: nline}} ->
        text = lib_to_string(current_lib)

        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message(message)
          |> push_event("js-exec", %{ js: """
            editor_open('Compile error for #{current_lib[:name]}', `#{text}`, true);
            editor_set_status_bar('#{error_message}', #{nline}, true);
          """ })
        }

      _ ->
        {:noreply, socket
          |> assign(last_result: :error)
          |> put_message("There was a problem storing the Lib!")
        }
    end
  end

  ##############
  ### CLOSE LIB (no ctrl key)
  def handle_event("close-lib", %{"value" => "false"}, socket) do
    if socket.assigns[:current_lib][:changed] do
      {:noreply, socket
        |> assign(last_result: :error)
        |> put_message("You made changes, save them before close or [CTRL+click] to close without save.", 5000)
      }
    else
      handle_event("close-lib", %{"value" => "true"}, socket)
    end

  end
  ##############
  ### CLOSE LIB (with ctrl key)
  def handle_event("close-lib", _params, socket) do
    changed = socket.assigns[:current_lib][:changed]
    {:noreply, socket
      |> assign(last_result: changed && :error || :ok)
      |> put_message(changed && "Changes discarded!" || nil)
      |> assign(current_lib: nil)
    }
  end

  ###############
  ### COMPILE LIB
  def handle_event("compile-lib", _params, socket) do
    {{result, message}, real_errors} =
      Code.with_diagnostics(fn ->
        try do
          socket.assigns[:current_lib]
            |> lib_to_string()
            |> Code.compile_string()
          {:ok, "LIB compiled OK!"}
        rescue
          _ ->
            {:error, "There was a problem compiling the LIB!"}
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

        text = lib_to_string(socket.assigns[:current_lib])

        {:noreply, socket
          |> assign(last_result: result)
          |> put_message(message)
          |> push_event("js-exec", %{ js: """
            editor_open('Compile error for #{socket.assigns[:current_lib][:name]}', `#{text}`, true);
            editor_set_status_bar('#{error_message}', #{nline}, true);
          """ })
        }
    end
  end

  ##############
  ### BLOCK MNG
  def handle_event("operation-editor", %{"operation" => "cancel", "ctrl" => "true"}, socket) do
    {:noreply, socket
      |> assign(last_result: :ok)
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
        [
          {:import, _, [{:__aliases__, [alias: false], [:Bobot, :DSL, :Base]}]},
          {:deflib, _, [ _, [ do: new_lib ] ] }
        ] = ast

        original_lib = socket.assigns[:current_lib][:code]

        {result, message} =
          if not Bobot.Utils.ast_equals(original_lib, new_lib) do
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

      new_lib ->
        new_lib =
          {:__block__, [],  new_lib}
          |> ast_extract_components()
          |> elem(1)
          # |> Map.put(:changed, true)

        ## I save and compile the bot
        handle_event("save-lib", %{}, socket
          |> assign(current_lib: new_lib)
        )
    end
  end

  ####################
  ### CONFIRMED ACTION


  ################################################################################################
  ## Handle info
  ################################################################################################

  def handle_info(:clear_message, socket) do
    {:noreply, clear_message(socket)}
  end

  ################################################################################################
  ## Private tools
  ################################################################################################

  defp load_lib(name) do
    "#{@libs_dir}/#{name}.ex"
    |> Bobot.Utils.ast_from_file()
    |> ast_extract_components()
    |> elem(1)
  end

  defp save_lib(lib) do
    filename = "#{@libs_dir}/#{lib[:name]}.ex"
    save_lib(lib, filename)
  end
  defp save_lib(lib, filename), do: File.write(filename, lib_to_string(lib))

  defp lib_to_string(lib) do
    """
    import Bobot.DSL.Base

    deflib :#{lib[:name]} do ## WARNING: You MUST not touch the 'deflib ...' line!!!
      #{Bobot.Utils.ast_to_source([lib[:code]], parentheses: :keep)}
    end
    """
    |> Code.format_string!()
    |> Enum.join("")
  end

  defp compile_lib(name) do
    filename = "#{@libs_dir}/#{name}.ex"
    case Bobot.Utils.compile_file(filename) do
      {:ok, _} ->
        {:ok, "Lib compiled OK!"}

      {{:error, error}, error_data} ->
        {{:error, "There was a problem compiling the Lib (#{error})"}, error_data}
    end
  end


  ################################################################################################
  ## Public tools
  ################################################################################################

  def ast_extract_components(
    {:__block__, [],  [
      {:import, _, [{:__aliases__, _, [:Bobot, :DSL, :Base]}]},
      {:deflib, _,
        [
          name,
          [ do: block ]
        ]
      }
    ]}) do

    {name, %{name: name, code: block} }
  end
  def ast_extract_components(_), do: []
end
