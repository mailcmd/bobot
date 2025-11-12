import Bobot.DSL.Base

defbot :spi_support, [
    type: :telegram,
    config: [
      token: "8492230001:AAGMK_QYk1N7tatauRMLua2WFGoWqLSL6HU",
      session_ttl: 3600 * 1_000,
      max_bot_concurrency: 1_000,
      expire_message: "La sesión expiro, pero podés volver a contactarnos cuando lo necesites 👋",
      use_api: Bobot.API.SPISupport,
      commands_as_message: true
    ]
  ] do

  hooks [
    start_block: :start,
    start_params: muid,
    stop_block: :good_bye,
    fallback_block: :good_bye
  ]

  ## COMMANDS


  ## BLOCKS
  defblock :start, receive: muid do
    call_api :authenticate, params: muid
    case value_of(:user_data) do
      :error ->
        terminate message: "No estás autorizado para usar @SPISupport BOT, envía este ID: <b>#{muid}</b> a los admines"
      _ ->
        call_api :send_message, params: [
          value_of([:user_data, :user]),
          value_of(:current_channel),
          value_of(:start_message)
        ]
        unpin_message []
        send_message "<i>GRUPO DE SOPORTE</i>"
        pin_message message_id: value_of(:last_message_id)
        call_block :loop
    end
  end

  defblock :loop do
    await_response store_in: message
    cond do
      # is image
      match?({:image, _}, message) ->
        {:image, image} = message
        call_api :send_image, params: [
          value_of([:user_data, :user]),
          value_of(:current_channel),
          image
        ]

      # is channel change
      is_command?(message) ->
        session_store [
          current_channel: build_channel(
            message,
            value_of(:group_channel),
            value_of([:user_data, :data, :user, :uid])
          )
        ]
        operator_name = get_operator_name(message, value_of([:user_data, :data, :providers]))
        send_message "<i>#{String.upcase(operator_name)}</i>"
        pin_message message_id: value_of(:last_message_id)

      # is text
      true ->
        call_api :send_message, params: [
          value_of([:user_data, :user]),
          value_of(:current_channel),
          message
        ]
    end
    call_block :loop
  end

  defblock :good_bye do
    terminate message: @bot_config[:expire_message]
  end

  ## LIBRARY
  def is_command?([47 | _]), do: true
  def is_command?([_ | _]), do: false
  def is_command?(text), do: is_command?(String.to_charlist(text))

  def build_channel("/group", group_channel, _uid), do: group_channel
  def build_channel(text, _group_channel, uid) do
    text
      |> String.replace("/", "")
      |> String.replace("_", "#")
      |> Kernel.<>(",#{uid}")
  end

  def get_operator_name("/group", _providers), do: "grupo de soporte"
  def get_operator_name(text, providers) do
    uid = String.replace(text, "/chat_", "")
    Enum.find(providers, fn pvd -> pvd[:uid] == uid end)[:name]
  end

end
