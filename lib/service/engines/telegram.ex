defmodule Bobot.Engine.Telegram do

  use Telegram.ChatBot
  require Logger

  @log_prefix "[Engine][Telegram]"

  defmodule Storage do
    use Agent

    def start_link(name: name) do
      Agent.start_link(fn -> %{} end, name: name)
    end
    def start_link(_) do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def set_token_data(token, key, value) do
      Agent.update(__MODULE__, fn status -> put_in(status, [{token, key}], value) end)
    end
    def get_token_data(token, key) do
      Agent.get(__MODULE__, fn status -> Map.get(status, {token, key}) end)
    end
    def remove_token_data(token, key) do
      Agent.get(__MODULE__, fn status -> Map.delete(status, {token, key}) end)
    end
  end

  ################################################################################################
  ## Public API
  ################################################################################################

  ################################################################################################
  ## Utils
  ################################################################################################

  defp random_id() do
    chars = Range.to_list(?a..?z) ++ Range.to_list(?0..?9) ++ [?_]
    (for _ <- 1..10, do: Enum.random(chars)) |> to_string()
  end

  ################################################################################################
  ## Events
  ################################################################################################

  @impl Telegram.ChatBot
  def init(chat, token) do

    assigns = chat.metadata.chat
      # |> put_in([:sessions_db], Storage)
      |> put_in([:token], token)
      |> Map.delete("id")
      |> put_in([:chat_id], chat.id)
      |> put_in([:start_message], get_in(chat.update, ["message", "text"]))
      |> Enum.map(fn
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
        {k, v} -> {k, v}
      end)
      |> Enum.into(%{})

    sess_id = random_id()

    # If IT IS NOT a command run start_bot
    if Storage.get_token_data(token, :commands_as_message) or not match?([%{"type" => "bot_command"}], get_in(chat.update, ["message", "entities"])) do
      module = Storage.get_token_data(token, :module)
      pid =
        if module do
          spawn(fn ->
            module.start_bot(chat.id, sess_id, assigns)
          end)
        else
          nil
        end

      if pid == nil do
        {:error, :not_initiated_yet}
      else
        Storage.set_token_data(token, chat.id, {pid, self()})
        Storage.set_token_data(token, :sess_id, sess_id)
        Logger.log(:notice, "#{@log_prefix} Initializing chat with #{assigns[:first_name]} (chat_id: #{assigns[:chat_id]})")
        {:ok, chat.id, Storage.get_token_data(token, :session_ttl)}
      end
    # If it is a command (handle_update will manage the command)
    else
      Storage.set_token_data(token, :sess_id, sess_id)
      Logger.log(:notice, "#{@log_prefix} Initializing command from #{assigns[:first_name]} (chat_id: #{assigns[:chat_id]})")
      {:ok, chat.id, Storage.get_token_data(token, :session_ttl)}
    end

  end

  @impl Telegram.ChatBot
  ###########
  ## COMMANDS
  def handle_update(%{"message" => %{"text" => command, "chat" => %{"id" => chat_id}, "entities" => [%{"type" => "bot_command"}], }} = update, token, chat_id)
      when byte_size(command) > 0 do
    Logger.log(:notice, "#{@log_prefix} Received command: #{command}")
    # If commands must not be processed trait it as simple text
    if Storage.get_token_data(token, :commands_as_message) do
      handle_update(%{"message" => %{"text" => command, "chat" => %{"id" => chat_id}}}, token, chat_id)
    # If not, process command
    else
      module = Storage.get_token_data(token, :module)
      assigns = get_in(update, ["message", "chat"])
        # |> put_in([:sessions_db], Storage)
        |> put_in([:token], token)
        |> put_in([:chat_id], chat_id)
        |> Enum.map(fn
          {k, v} when is_binary(k) -> {String.to_atom(k), v}
          {k, v} -> {k, v}
        end)
        |> Enum.into(%{})

      sess_id = Storage.get_token_data(token, :sess_id)
      Bobot.Bot.Assigns.set_all(sess_id, assigns)
      pid = spawn(fn ->
        module.run_command(command, sess_id, assigns)
      end)
      Storage.set_token_data(token, chat_id, {pid, self()})
    end
    {:ok, chat_id, Storage.get_token_data(token, :session_ttl)}
  end

  ###########
  ## MESSAGES
  def handle_update(%{"message" => %{"text" => text, "chat" => %{"id" => chat_id}}}, token, chat_id)
    when byte_size(text) > 0 do
    pid =
      case Storage.get_token_data(token, chat_id) do
        {pid, _} -> pid
        _ -> nil
      end
    if not is_nil(pid) do
      send(pid, text)
      {:ok, chat_id, not Process.alive?(pid) && 1 || Storage.get_token_data(token, :session_ttl)}
    else
      {:ok, chat_id, 1}
    end
  end

  ###########
  ## IMAGES
  def handle_update(%{"message" => %{"document" => %{"file_id" => file_id, "mime_type" => _mime_type}, "chat" => %{"id" => chat_id}}}, token, chat_id) do
    pid =
      with {:ok, %{"file_path" => file_path}} <- Telegram.Api.request(token, "getFile", file_id: file_id),
          {:ok, %Tesla.Env{body: body}} <- Tesla.get("https://api.telegram.org/file/bot#{token}/#{file_path}") do

        image = "," <> Base.encode64(body)
        pid =
          case Storage.get_token_data(token, chat_id) do
            {pid, _} -> pid
            _ -> nil
          end
        if not is_nil(pid), do: send(pid, {:image, image})
        pid
      else
        _ ->
          Logger.log(:error, "#{@log_prefix} Error retrieving image (#{file_id})")
          nil
      end

      # {:ok, chat_id, Storage.get_token_data(token, :session_ttl)}
    if not is_nil(pid) do
      {:ok, chat_id, not Process.alive?(pid) && 1 || Storage.get_token_data(token, :session_ttl)}
    else
      {:ok, chat_id, 1}
    end
  end

  ###########
  ## PHOTO
  def handle_update(%{"message" => %{"photo" => photos, "chat" => %{"id" => chat_id}}}, token, chat_id) do
    [%{"file_id" => file_id} | _] = Enum.reverse(photos)
    handle_update(%{"message" => %{"document" => %{"file_id" => file_id, "mime_type" => ""}, "chat" => %{"id" => chat_id}}}, token, chat_id)
  end

  ###########
  ## BUTTONS
  def handle_update(%{"callback_query" => %{ "data" => text, "message" =>  %{"chat" => %{"id" => chat_id}}}}, token, chat_id)
    when byte_size(text) > 0 do
    pid =
      case Storage.get_token_data(token, chat_id) do
        {pid, _} -> pid
        _ -> nil
      end
    if not is_nil(pid) do
      send(pid, text)
      {:ok, chat_id, not Process.alive?(pid) && 1 || Storage.get_token_data(token, :session_ttl)}
    else
      {:ok, chat_id, 1}
    end
  end

  ###########
  ## VOICE
  def handle_update(%{"message" => %{"message_id" => message_id, "voice" => _voice}}, token, chat_id) do
    Logger.log(:notice, "#{@log_prefix} Received voice!")
    Telegram.Api.request(token, "deleteMessage",
      chat_id: chat_id,
      message_id: message_id
    )
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      text: "<i>¡No están permitidos los mensajes de voz!</i>",
      parse_mode: "HTML"
    )
    {:ok, chat_id, Storage.get_token_data(token, :session_ttl)}
  end

  ###########
  ## UNKNOWN
  def handle_update(update, token, chat_id) do
    Logger.log(:warning, "#{@log_prefix} unknow getUpdate() message: #{inspect update}")
    {:ok, chat_id, Storage.get_token_data(token, :session_ttl)}
  end

  @impl Telegram.ChatBot
  def handle_info(:stop, token, chat_id, _state) do
    {pid, _} = Storage.get_token_data(token, chat_id)
    send(pid, :stop)
    Storage.remove_token_data(token, chat_id)
    Logger.log(:notice, "#{@log_prefix} Stopping chat (chat_id: #{chat_id})")
    {:stop, chat_id}
  end

  @impl Telegram.ChatBot
  def handle_timeout(token, chat_id, chat_id) do
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      text: Storage.get_token_data(token, :expire_message)
    )
    handle_info(:stop, token, chat_id, nil)
    super(token, chat_id, chat_id)
  end

end
