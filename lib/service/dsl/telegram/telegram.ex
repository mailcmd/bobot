defmodule Bobot.DSL.Telegram do
  @moduledoc """
  This module add the following sentencies:

    - command <pattern> do ... end
      [#] When receive a command compare with <pattern> and if there is match run do ... end block.

    - send_message <message>

    - send_menu <menu>, [message: <message>]



  """

  defmacro __using__(opts) do
    session_ttl_default = Application.fetch_env!(:bobot, :telegram_bots_defaults)
      |> Keyword.fetch!(:session_ttl)

    config = Keyword.get(opts, :config, [])

    token = Keyword.fetch!(config, :token)
    session_ttl = Keyword.get(config, :session_ttl, session_ttl_default)
    max_bot_concurrency = Keyword.get(config, :max_bot_concurrency, 1_000)

    quote do
      @token unquote(token)
      @session_ttl unquote(session_ttl)
      @max_bot_concurrency unquote(max_bot_concurrency)

      import unquote(__MODULE__)
      import Kernel, except: [send: 2]
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

  ## SETTINGS
  defmacro settings_set(key, value) do
    quote do
      Bobot.Bot.Assigns.get(var!(sess_id), :sessions_db).set_token_data(@token, unquote(key), unquote(value))
    end
  end
  defmacro settings_set([{key, value}]) do
    quote do
      settings_set(unquote(key), unquote(value))
    end
  end

  defmacro settings_get(key) do
    quote do
      Bobot.Bot.Assigns.get(var!(sess_id), :sessions_db).get_token_data(@token, unquote(key))
    end
  end
  defmacro settings_remove(key) do
    quote do
      Bobot.Bot.Assigns.get(var!(sess_id), :sessions_db).remove_token(@token, unquote(key))
    end
  end

  ## COMMAND
  defmacro defcommand(command, do: block) do
    quote do
      def run_command(unquote(command), var!(sess_id), assigns) do
        {pid, _engine} = settings_get(Bobot.Bot.Assigns.get(var!(sess_id), :chat_id))
        Kernel.send(pid, :cancel)
        unquote(block)
      end
    end
  end

  ## SEND
  defmacro send_message(message) do
    quote do
      result = Telegram.Api.request(@token, "sendMessage",
        chat_id: Bobot.Bot.Assigns.get(var!(sess_id), :chat_id),
        text: unquote(message),
        parse_mode: "HTML"
      )
      msg_id =
        case result do
          {:ok, %{"message_id" => id}} -> id
          _ -> nil
        end

      Bobot.Bot.Assigns.put(var!(sess_id), :last_message_id, msg_id)
      msg_id
    end
  end

  defmacro send_menu(menu, opts \\ []) do
    message = Keyword.get(opts, :message, "")
    quote do
      menu = %{
        inline_keyboard: unquote(menu)
          |> :lists.enumerate()
          |> Enum.map(fn {i, item} -> [ %{text: item, callback_data: "#{i}"} ] end)
      } |> Jason.encode!()

      result = Telegram.Api.request(@token, "sendMessage",
        chat_id: Bobot.Bot.Assigns.get(var!(sess_id), :chat_id),
        text: unquote(message),
        reply_markup: menu,
        parse_mode: "HTML"
      )
      msg_id =
        case result do
          {:ok, %{"message_id" => id}} -> id
          _ -> nil
        end

      Bobot.Bot.Assigns.put(var!(sess_id), :last_message_id, msg_id)
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
        chat_id: Bobot.Bot.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Bot.Assigns.get(var!(sess_id), :last_message_id),
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
        chat_id: Bobot.Bot.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Bot.Assigns.get(var!(sess_id), :last_message_id)
      )
    end
  end

  defmacro unpin_message(opts \\ []) do
    msg_id = Keyword.get(opts, :message_id, nil)
    quote do
      Telegram.Api.request(@token, "pinChatMessage",
        chat_id: Bobot.Bot.Assigns.get(var!(sess_id), :chat_id),
        message_id: unquote(msg_id)|| Bobot.Bot.Assigns.get(var!(sess_id), :last_message_id)
      )
    end
  end

  ## TERMINATE
  defmacro terminate(message: message) do
    quote do
      send_message unquote(message)
      terminate()
    end
  end

  defmacro terminate() do
    quote do
      {_, pid} = settings_get(Bobot.Bot.Assigns.get(var!(sess_id), :chat_id))
      Kernel.send(pid, :stop)
      receive do
        :stop -> Process.exit(self(), :kill)
        _ -> Process.exit(self(), :kill)
      end
    end
  end

  ## USER
  defmacro await_response(opts) do
    variables = Keyword.fetch!(opts, :store_in)
    extract_re  = Keyword.get(opts, :extract_re, nil)
    cast  = Keyword.get(opts, :cast_as, nil)
    quote do
      {pid, engine} = settings_get(Bobot.Bot.Assigns.get(var!(sess_id), :chat_id))
      settings_set(Bobot.Bot.Assigns.get(var!(sess_id), :chat_id), {self(), engine})
      flush()
      var!(unquote(variables)) =
        receive do
          :stop ->
            Process.exit(self(), :kill)
          :cancel ->
            call_block @fallback_block
          message ->
            case unquote(extract_re) do
              nil -> message
              regex -> Regex.scan(regex, message) |> hd() |> tl()
            end
        end

      var!(unquote(variables)) =
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
