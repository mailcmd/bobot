import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :spi_support,
  type: :telegram,
  use_apis: [:spi_support],
  use_libs: [:common],
  config: [
    token: "GhYbFBQVEhISExwjIykvLUEzO00TMBlWQ1ZDVzQvLldDFDkoKVE5Uy41LhgqNw==",
    session_ttl: 3_600_000,
    max_bot_concurrency: 1000,
    expire_message: "La sesión expiro, pero podés volver a contactarnos cuando lo necesites 👋",
    commands_as_message: true
  ] do
  @connections []
  @positions [start: "", loop: "", good_bye: ""]
  @pseudo_blocks []

  hooks(
    start_block: :start,
    start_params_count: 1,
    stop_block: :good_bye,
    fallback_block: :good_bye
  )

  constants([])

  defblock :start, receive: muid do
    call_api :authenticate, params: muid

    case session_value([:authenticate, :user_data]) do
      :error ->
        terminate(
          message:
            "No estás autorizado para usar @SPISupport BOT, envía este ID: <b>#{muid}</b> a los admines"
        )

      user_data ->
        session_store(current_channel: session_value([:authenticate, :current_channel]))
        session_store(group_channel: session_value([:authenticate, :group_channel]))

        call_api :send_message,
          params: [
            user_data[:user],
            session_value(:current_channel),
            session_value(:start_message)
          ]

        unpin_message []
        send_message "<i>GRUPO DE SOPORTE</i>"
        pin_message message_id: session_value(:last_message_id)
        call_block :loop
    end
  end

  defblock :loop do
    await_response store_in: message

    cond do
      match?({:image, _}, message) ->
        {:image, image} = message

        call_api :send_image,
          params: [
            session_value([:authenticate, :user_data, :user]),
            session_value(:current_channel),
            image
          ]

      is_command?(message) ->
        session_store(
          current_channel:
            build_channel(
              message,
              session_value(:group_channel),
              session_value([:authenticate, :user_data, :data, :user, :uid])
            )
        )

        operator_name =
          get_operator_name(
            message,
            session_value([:authenticate, :user_data, :data, :providers])
          )

        send_message "<i>#{String.upcase(operator_name)}</i>"
        pin_message message_id: session_value(:last_message_id)

      true ->
        call_api :send_message,
          params: [
            session_value([:authenticate, :user_data, :user]),
            session_value(:current_channel),
            message
          ]
    end

    call_block :loop
  end

  defblock :good_bye do
    terminate(message: @bot_config[:expire_message])
  end
end