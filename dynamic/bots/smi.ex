import Bobot.DSL.Base

## WARNING: You MUST not touch the 'defbot ...' line!!!
defbot :smi,
  type: :telegram,
  use_apis: [:smi],
  use_libs: [],
  config: [
    token: "8241208776:AAHz1-OjK94w_L0RIuIDoReuaZnJX0IWSXI",
    session_ttl: 300_000,
    max_bot_concurrency: 1000,
    expire_message: "El tiempo de espera se agotó. Empezá de nuevo."
  ] do
  @positions [
    error: "translate(774.4px, 441.6px)",
    start: "translate(420.8px, 37.6px)",
    loop: "translate(548.8px, 39.2px)",
    show: "translate(291.2px, 340px)",
    good_bye: "translate(13.6px, 101.6px)",
    fall_back: "translate(52px, 72px)"
  ]
  @connections [
    ["start", "loop"],
    ["loop", "show"],
    ["loop", "error"],
    ["error", "loop"],
    ["show", "loop"]
  ]
  @pseudo_blocks [[:q455566, "Tipo de usuario?", nil]]

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
        call_block :loop

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

  defblock :loop do
    await_response store_in: id
    send_message "<i>Estoy pensando, esperá unos segundos...</i>"
    call_api :find_user, params: id
    call_block session_value([:find_user, :result_type])
    call_block :loop
  end
end
