import Bobot.DSL.Base

defbot :smi, [
    type: :telegram,
    config: [
      token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
      session_ttl: 300 * 1_000,
      max_bot_concurrency: 1_000,
      expire_message: "El tiempo de espera se agotó. Empezá de nuevo.",
      use_api: Bobot.API.SMI
    ]
  ] do

  hooks [
    start_block: :start,
    start_params_count: 1,
    stop_block: :good_bye,
    fallback_block: :good_bye
  ]

  ## START
  block :start, receive: muid do
    call_api :authenticate, params: muid
    case session_value(:authentication) do
      :error ->
        terminate message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"
      _ ->
        send message: "Bienvenido, decime qué querés buscar..."
        call_block :loop
    end
  end

  ## MAIN LOOP
  block :loop do
    await_response store_in: id
    send message: "<i>Estoy pensando, esperá unos segundos...</i>"
    call_api :find_user, params: id
    call_block value_of(:result_type)
    call_block :loop
  end

  block :ftth do
    send message: value_of(:data)
  end

  block :docsis do
    send message: value_of(:data)
  end

  block :error do
    send message: "Lo siento no encontré nada o algo salió mal 😢"
  end

  block :good_bye do
    terminate message: @bot_config[:expire_message]
  end

end

#   bot_config [
#     start_block: :start,
#     start_params: phone,
#     stop_block: :good_bye,
#     fallback_block: :good_bye
#   ]

#   ## COMMANDS

#   command "/test" do
#     call_block :test, params: value_of(:chat_id)
#   end

#   command "/stop" do
#     call_block :good_bye
#   end

#   block :test, receive: chat_id do
#     send_message "Este es el chat_id #{chat_id}, escribí algo..."
#     await_response store_in: message
#     send_message "Tu mensaje es #{message}"
#     call_block :test, params: chat_id
#   end

#   ## START
#   block :start, receive: muid do
#     call_api :authenticate, params: muid
#     case session_value(:authentication) do
#       :error ->
#         terminate message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"
#       _ ->
#         send message: "Bienvenido, decime qué querés buscar..."
#         call_block :loop
#     end
#   end

#   ## MAIN LOOP
#   block :loop do
#     await_response store_in: id
#     send message: "<i>Estoy pensando, esperá unos segundos...</i>"
#     call_api :find_user, params: id
#     call_block value_of(:result_type)
#     call_block :loop
#   end

#   block :ftth do
#     send message: value_of(:data)
#   end

#   block :docsis do
#     send message: value_of(:data)
#   end

#   block :error do
#     send message: "Lo siento no encontré nada o algo salió mal 😢"
#   end

#   block :good_bye do
#     terminate message: @bot_config[:expire_message]
#   end

# end
