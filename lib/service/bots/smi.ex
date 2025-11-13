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
  defblock :start, receive: muid do
    call_api :authenticate, params: muid
    case session_value(:authentication) do
      :error ->
        terminate message: "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"
      _ ->
        send_message "Bienvenido, decime qué querés buscar..."
        call_block :loop
    end
  end

  ## MAIN LOOP
  defblock :loop do
    await_response store_in: id
    send_message "<i>Estoy pensando, esperá unos segundos...</i>"
    call_api :find_user, params: id
    call_block value_of(:result_type)
    call_block :loop
  end

  defblock :ftth do
    send_message value_of(:data)
  end

  defblock :docsis do
    send_message value_of(:data)
  end

  defblock :error do
    send_message "Lo siento no encontré nada o algo salió mal 😢"
  end

  defblock :good_bye do
    terminate message: @bot_config[:expire_message]
  end

end
