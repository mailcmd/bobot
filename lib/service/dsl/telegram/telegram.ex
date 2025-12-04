defmodule Bobot.DSL.Telegram do
  @moduledoc false

  defmacro __using__(opts) do
    session_ttl_default = Application.fetch_env!(:bobot, :telegram_bots_defaults)
      |> Keyword.fetch!(:session_ttl)

    config = Keyword.get(opts, :config, [])

    token = Keyword.fetch!(config, :token)
    session_ttl = Keyword.get(config, :session_ttl, session_ttl_default)
    max_bot_concurrency = Keyword.get(config, :max_bot_concurrency, 1_000)

    quote do
      @bots_dir Application.compile_env(:bobot, :bots_dir)
      @apis_dir Application.compile_env(:bobot, :apis_dir)
      @libs_dir Application.compile_env(:bobot, :libs_dir)

      @before_compile unquote(__MODULE__)

      @token unquote(token)
      @session_ttl unquote(session_ttl)
      @max_bot_concurrency unquote(max_bot_concurrency)

      import unquote(__MODULE__)
      import Kernel, except: [send: 2]

      Module.register_attribute(__MODULE__, :bot_channels, persist: true, accumulate: true)

      defcommand "/chsub " <> channel do
        chat_id = var!(assigns)[:chat_id]
        Logger.log(:notice, "[Bobot][Channels] Chat ID #{chat_id} subscribed to channel '#{channel}'")
        Bobot.Utils.channel_subscribe(
          {@bot_name, String.to_atom(channel)},
          chat_id
        )
        send_message "<i>You are now subscribed to the '#{channel}' channel</i>"
      end
      defcommand "/chunsub " <> channel do
        chat_id = var!(assigns)[:chat_id]
        Logger.log(:notice, "[Bobot][Channels] Chat ID #{chat_id} unsubscribed to channel #{channel}")
        Bobot.Utils.channel_unsubscribe(
          {@bot_name, String.to_atom(channel)},
          chat_id
        )
        send_message "<i>You have been removed from the '#{channel}' channel</i>"
      end

      ################################################################################################
      ## Callbacks
      ################################################################################################

      @impl Bobot.Bot
      def inform_to_subscribers(subscribers, message) do
        Enum.each(subscribers, fn chat_id ->
          case message do
            message when is_binary(message) ->
              Telegram.Api.request(@token, "sendMessage", [
                chat_id: chat_id,
                text: message,
                parse_mode: "HTML"
              ])

            %{type: :text, text: text} ->
              Telegram.Api.request(@token, "sendMessage", [
                chat_id: chat_id,
                text: text,
                parse_mode: "HTML"
              ])

            %{type: :image, filename: filename} ->
              case File.read(filename) do
                {:ok, content} ->
                  result = Telegram.Api.request(@token, "sendPhoto",
                    chat_id: chat_id,
                    photo: {:file_content, content, Path.basename(filename)}
                  )

                _ ->
                  :ok
              end

            %{type: :image, url: url} ->
              result = Telegram.Api.request(@token, "sendPhoto",
                chat_id: chat_id,
                photo: url
              )

          end
        end)
      end

      @impl Bobot.Bot
      def launch() do
        case Bobot.Utils.compile_file("#{@bots_dir}/#{@bot_name}.ex") do
          {{:error, message}, _} ->
            Logger.log(:error, "[BOBOT][HOME] There was a problem compiling #{@bots_dir}/#{@bot_name}.ex (#{message})")
          _ ->
            init_channels()
            type = @bot_type
            id = Telegram.Bot.Utils.name(Telegram.Poller.Task, @token)

            Supervisor.start_child(Telegram.Poller,
              {Bobot.Engine.Telegram, @bot_config}
            )
            Supervisor.start_child(Telegram.Poller,
              Supervisor.child_spec({Telegram.Poller.Task, {Bobot.Engine.Telegram, @token, []}}, id: id)
            )
        end
      end

      @impl Bobot.Bot
      def stop() do
        Supervisor.which_children(Telegram.Poller)
          |> Enum.each(fn {id, _, _, _} ->
            if String.contains?("#{id}", @token) do
              Supervisor.terminate_child(Telegram.Poller, id)
              Supervisor.delete_child(Telegram.Poller, id)
            end
          end)
      end

    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def run_command(cmd, var!(sess_id), _) do
        send_message "<i>Unknown command '#{cmd}'</i>"
      end
      def init_channel(nil), do: :ok
    end
  end

  ################################################################################################
  ## UTILS
  ################################################################################################

  def flush() do
    receive do
      _ -> flush()
    after
      10 -> :empty
    end
  end

  ################################################################################################
  ## MACROS
  ################################################################################################

  ## SEND
  defmacro send_message(message) do
    quote do
      result = Telegram.Api.request(@token, "sendMessage",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
        text: unquote(message),
        parse_mode: "HTML"
      )
      msg_id =
        case result do
          {:ok, %{"message_id" => id}} -> id
          _ -> nil
        end

      Bobot.Utils.Assigns.put(var!(sess_id), :last_message_id, msg_id)
      msg_id
    end
  end

  defmacro send_image(url_filename, opts \\ [])
  defmacro send_image("http" <> _ = url, opts) do
    download = opts[:download]
    quote do
      photo =
        if unquote(download) do
          case Bobot.DSL.Base.http_request(unquote(url), return_json: false) do
            {:ok, %Tesla.Env{status: 200, body: content}} ->
              {:file_content, content, Path.basename(unquote(url))}

            error ->
              Logger.log(:error, "[Bobot][Telegram] Error trying to download image (#{inspect error})")
              nil
          end
        else
          unquote(url)
        end

      if photo do
        result = Telegram.Api.request(@token, "sendPhoto",
          chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
          photo: photo
        )
        msg_id =
          case result do
            {:ok, %{"message_id" => id}} -> id
            _ -> nil
          end

        Bobot.Utils.Assigns.put(var!(sess_id), :last_message_id, msg_id)
        msg_id
      else
        Logger.log(:error, "[Bobot][Telegram] Error trying to send image (#{inspect error})")
      end
    end
  end
  defmacro send_image(filename, _) do
    quote do
      case File.read(unquote(filename)) do
        {:ok, content} ->
          result = Telegram.Api.request(@token, "sendPhoto",
            chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
            photo: {:file_content, content, Path.basename(unquote(filename))}
          )
          msg_id =
            case result do
              {:ok, %{"message_id" => id}} -> id
              _ -> nil
            end

          Bobot.Utils.Assigns.put(var!(sess_id), :last_message_id, msg_id)
          msg_id

        error ->
          Logger.log(:error, "[Bobot][Telegram] Error trying to send image (#{inspect error})")
      end
    end
  end

  defmacro send_menu(menu, opts \\ []) do
    message = Keyword.get(opts, :message, "")
    quote do
      menu =
        case unquote(menu) do
          [text | _] when is_binary(text) -> :lists.enumerate(unquote(menu))
          [{_value, _text} | _] = m -> m
        end

      menu = %{
        inline_keyboard: menu |> Enum.map(fn {i, item} -> [ %{text: item, callback_data: "#{i}"} ] end)
      } |> Jason.encode!()

      result = Telegram.Api.request(@token, "sendMessage",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
        text: unquote(message),
        reply_markup: menu,
        parse_mode: "HTML"
      )
      msg_id =
        case result do
          {:ok, %{"message_id" => id}} -> id
          _ -> nil
        end

      Bobot.Utils.Assigns.put(var!(sess_id), :last_message_id, msg_id)
      msg_id
    end
  end

  ## EDIT MESSAGE
  defmacro edit_message(opts \\ []) do
    message = Keyword.get(opts, :message, "")
    msg_id = Keyword.get(opts, :message_id, nil)
    menu = %{inline_keyboard: Keyword.get(opts, :menu, [])} |> Jason.encode!()
    quote do
      Telegram.Api.request(@token, "editMessageText",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Utils.Assigns.get(var!(sess_id), :last_message_id),
        text: unquote(message),
        reply_markup: unquote(menu)
      )
    end
  end

  ## PIN / UNPIN
  defmacro pin_message(opts \\ []) do
    msg_id = Keyword.get(opts, :message_id, nil)
    quote do
      Telegram.Api.request(@token, "pinChatMessage",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Utils.Assigns.get(var!(sess_id), :last_message_id)
      )
    end
  end

  defmacro unpin_message(opts \\ [])
  defmacro unpin_message(:all) do
    quote do
      Telegram.Api.request(@token, "unpinAllChatMessages",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id)
      )
    end
  end

  defmacro unpin_message(opts) do
    msg_id = Keyword.get(opts, :message_id, nil)
    quote do
      Telegram.Api.request(@token, "unpinChatMessage",
        chat_id: Bobot.Utils.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Utils.Assigns.get(var!(sess_id), :last_message_id)
      )
    end
  end

  ## TERMINATE
  defmacro terminate() do
    quote do
      chat_id = Bobot.Utils.Assigns.get(var!(sess_id), :chat_id)
      {_, engine} = get_token_data({:chat, chat_id, :processes})
      Kernel.send(engine, :stop)
      receive do
        # I need to work more here, for now kill se
        :stop ->
          # Also I need remove token data {:chat, <chat_id>, :sess_id} and {:chat, <chat_id>, :processes}
          Bobot.Utils.Assigns.unset(var!(sess_id))
          Process.exit(self(), :kill)
        _ ->
          # Also I need remove token data {:chat, <chat_id>, :sess_id} and {:chat, <chat_id>, :processes}
          Bobot.Utils.Assigns.unset(var!(sess_id))
          Process.exit(self(), :kill)
      end
    end
  end

  defmacro terminate(message: message) do
    quote do
      send_message unquote(message)
      terminate()
    end
  end

  ## USER
  defmacro await_response(opts) do
    variables = Keyword.fetch!(opts, :store_in)
    extract_re  = Keyword.get(opts, :extract_re, nil)
    cast  = Keyword.get(opts, :cast_as, nil)
    quote do
      chat_id = Bobot.Utils.Assigns.get(var!(sess_id), :chat_id)
      {_, engine} = get_token_data({:chat, chat_id, :processes})
      set_token_data({:chat, chat_id, :processes}, {self(), engine})
      flush()
      var!(unquote(variables)) =
        receive do
          :stop ->
            Process.exit(self(), :kill)
            :stop
          :cancel ->
            :cancel
          message ->
            case unquote(extract_re) do
              nil -> message
              regex -> Regex.scan(regex, message) |> hd() |> tl()
            end
        end

      var!(unquote(variables)) =
        if var!(unquote(variables)) in [:stop, :cancel] do
          var!(unquote(variables))
        else
          if unquote(cast) do
            {var!(unquote(variables)), cast} =
              if not is_list(var!(unquote(variables))) do
                {[var!(unquote(variables))], [unquote(cast)]}
              else
                {var!(unquote(variables)), unquote(cast)}
              end
              var!(unquote(variables)) = var!(unquote(variables))
              |> Enum.zip(cast)
              |> Enum.map(fn {val, type} ->
                Bobot.Parser.parse(val, type)
              end)

            if not is_list(unquote(cast)) do
              var!(unquote(variables)) |> hd()
            else
              var!(unquote(variables))
            end
          else
            var!(unquote(variables))
          end
        end
    end
  end

  defmacro await_response(opts, do: block) do
    quote do
      case await_response(unquote(opts)) do
        :cancel ->
          :ok

        # this will never happen for now
        :stop ->
          terminate()

        _ ->
         unquote(block)
      end
    end
  end



  ## SETTINGS
  defmacro set_token_data(key, value) do
    quote do
      # Bobot.Utils.Assigns.get(var!(sess_id), :sessions_db).set_token_data(@token, unquote(key), unquote(value))
      Bobot.Utils.Storage.set_token_data(@token, unquote(key), unquote(value))
    end
  end
  defmacro set_token_data([{key, value}]) do
    quote do
      set_token_data(unquote(key), unquote(value))
    end
  end

  defmacro get_token_data(key) do
    quote do
      # Bobot.Utils.Assigns.get(var!(sess_id), :sessions_db).get_token_data(@token, unquote(key))
      Bobot.Utils.Storage.get_token_data(@token, unquote(key))
    end
  end
  defmacro settings_remove(key) do
    quote do
      # Bobot.Utils.Assigns.get(var!(sess_id), :sessions_db).remove_token(@token, unquote(key))
      Bobot.Utils.Storage.remove_token(@token, unquote(key))
    end
  end


  ###### FOR BACK COMPATIBILITY ######
  defmacro send(message: message) do
    quote do
      send_message(unquote(message))
    end
  end
  defmacro send(message: message, menu: menu) do
    quote do
      send_menu(unquote(menu), message: unquote(message))
    end
  end

end
