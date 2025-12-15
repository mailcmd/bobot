import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :smi,
  type: :telegram,
  use_apis: [:smi],
  use_libs: [],
  config: [
    token:
      "1A14161314121A1919181C2323282D3A24284E5055561B144831584E4E4317511B2C525B41262D4E14582F272B3B",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: "El tiempo de espera se agotó. Empezá de nuevo."
  ] do
  @connections []
  @positions [error: "", start: "", show: "", good_bye: "", fall_back: "", search_user: ""]
  @pseudo_blocks []

  hooks(
    start_block: :start,
    start_params_count: 1,
    stop_block: :good_bye,
    fallback_block: :good_bye
  )

  constants([])

  defchannel :test do
    every {{_, _, _}, {_, min, _}}, when: rem(min, 2) == 0 do
      %{
        type: :text,
        url:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDEqLPkj2upTgSZK7TEIxGlBo42_YojmNFjQ&s",
        text: "CHANNEL #{channel}: ANDAAAAAAAAAA???? #{NaiveDateTime.local_now()}"
      }
    end
  end

  defcommand "/image" do
    send_image "/download/logo-smi.png"
  end

  defblock :start, receive: muid do
    call_api :authenticate, params: muid

    case session_value([:authenticate, :authentication]) do
      :ok ->
        send_message "Bienvenido, decime qué querés buscar..."
        call_block :search_user

      :error ->
        terminate(
          message:
            "No estás autorizado para usar @SMI BOT, envía este ID: <b>#{muid}</b> a los admines"
        )
    end
  end

  defblock :error do
    send_message "Lo siento no encontré nada o algo salió mal 😢"
  end

  defblock :fall_back do
    send_message "Lo siento, tengo que resetearme!"
  end

  defblock :show do
    send_message session_value([:find_user, :data])
  end

  defblock :good_bye do
    terminate(message: @bot_config[:expire_message])
  end

  defblock :search_user do
    await_response store_in: id
    send_message "<i>Estoy pensando, esperá unos segundos...</i>"
    call_api :find_user, params: id
    call_block session_value([:find_user, :result_type])
    call_block :search_user
  end
end